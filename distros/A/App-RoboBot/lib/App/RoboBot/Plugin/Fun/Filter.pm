package App::RoboBot::Plugin::Fun::Filter;
$App::RoboBot::Plugin::Fun::Filter::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

use FileHandle;
use IPC::Open2;

extends 'App::RoboBot::Plugin';

has '+name' => (
    default => 'Fun::Filter',
);

has '+description' => (
    default => 'Provides various text translation and munging filters. Mostly humorous.',
);

has '+commands' => (
    default => sub {
        my %h = map { $_ => { method      => 'filter_text',
                        description => 'Filters input argument text through the ' . $_ . ' program.',
                        usage       => '<text>' }
          } qw( b1ff chef cockney eleet fudd nethackify newspeak pirate scottish scramble uniencode );
        return \%h;
    },
);

has 'filter_paths' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

sub filter_text {
    my ($self, $message, $filter, $rpl, @args) = @_;

    return unless exists $self->commands->{$filter};

    my $prog = $self->find_filter($message, $filter);
    return unless defined $prog;

    my $pid = open2(my $rfh, my $wfh, $prog) || return;
    print $wfh join("\n", @args) . "\n";
    close($wfh);

    my $filtered = join("\n", <$rfh>);
    $filtered =~ s{[\n\r]+}{\n}ogs;
    $filtered =~ s{(^\s+|\s+$)}{}ogs;

    return split(/\n/o, $filtered);
}

sub find_filter {
    my ($self, $message, $filter) = @_;

    return $self->filter_paths->{$filter} if exists $self->filter_paths->{$filter};

    return undef unless $filter =~ m{^[A-Za-z0-9]+$}o;

    unless (-x "/usr/games/$filter") {
        $message->response->raise(sprintf('The filter %s appears to not be installed on this machine.', $filter));
        return undef;
    }

    $self->filter_paths->{$filter} = "/usr/games/$filter";
    return "/usr/games/$filter";
}

__PACKAGE__->meta->make_immutable;

1;
