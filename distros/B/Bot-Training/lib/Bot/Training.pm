package Bot::Training;
our $AUTHORITY = 'cpan:AVAR';
$Bot::Training::VERSION = '0.06';
use 5.010;
use autodie qw(open close);
use Class::Load;
use Moose;
use Module::Pluggable (
    search_path => [ 'Bot::Training' ],
    except      => [ 'Bot::Training::Plugin' ],
);
use List::Util qw< first >;
use namespace::clean -except => [ qw< meta plugins > ];

with 'MooseX::Getopt::Dashes';

has help => (
    traits        => [ qw/ Getopt / ],
    cmd_aliases   => 'h',
    cmd_flag      => 'help',
    isa           => 'Bool',
    is            => 'ro',
    default       => 0,
    documentation => 'This help message',
);

has _go_version => (
    traits        => [ qw/ Getopt / ],
    cmd_aliases   => 'v',
    cmd_flag      => 'version',
    documentation => 'Print version and exit',
    isa           => 'Bool',
    is            => 'ro',
);

has _go_list => (
    traits        => [ qw/ Getopt / ],
    cmd_aliases   => 'l',
    cmd_flag      => 'list',
    documentation => 'List the known Bot::Training files. Install Task::Bot::Training to get them all',
    isa           => 'Bool',
    is            => 'ro',
);

has _go_file => (
    traits        => [ qw/ Getopt / ],
    cmd_aliases   => 'f',
    cmd_flag      => 'file',
    documentation => 'The file to retrieve. Matched case-insensitively against Bot::Training plugins',
    isa           => 'Str',
    is            => 'ro',
);

sub _new_class {
    my ($self, $class) = @_;

    my $pkg;
    if ($class =~ m[^\+(?<custom_plugin>.+)$]) {
        $pkg = $+{custom_plugin};
    } else {
        # Be fuzzy about includes, e.g. Training::Test, Test or test is OK
        $pkg = first { / : $class /ix }
               sort { length $a <=> length $b }
               $self->plugins;

        unless ($pkg) {
            local $" = ', ';
            my @plugins = $self->plugins;
            die "Couldn't find a class name matching '$class' in plugins '@plugins'";
        }
    }

    Class::Load::load_class($pkg);

    return $pkg->new;
}

sub file {
    my ($self, $fuzzy) = @_;

    return $self->_new_class($fuzzy);

}

sub run {
    my ($self) = @_;

    if ($self->_go_version) {
        # Munging strictness because we don't have a version from a
        # Git checkout. Dist::Zilla provides it.
        no strict 'vars';
        my $version = $VERSION // 'dev-git';

        say "bot-training $version";
        return;
    }

    if ($self->_go_list) {
        my @plugins = $self->plugins;
        if (@plugins) {
            say for @plugins;
        } else {
            say "No plugins loaded. Install Task::Bot::Training";
            return 1;
        }
    }
    
    if ($self->_go_file) {
        my $trn = $self->file( $self->_go_file );;
        open my $fh, "<", $trn->file;
        print while <$fh>;
        close $fh;
    }

}

# --i--do-not-exist
sub _getopt_spec_exception { goto &_getopt_full_usage }

# --help
sub print_usage_text {
    my ($self, $usage, $plain_str) = @_;

    # If called from _getopt_spec_exception we get "Unknown option: foo"
    my $warning = ref $usage eq 'ARRAY' ? $usage->[0] : undef;

    my ($use, $options) = do {
        # $plain_str under _getopt_spec_exception
        my $out = $plain_str // $usage->text;

        # The default getopt order sucks, use reverse sort order
        my @out = split /^/, $out;
        chomp @out;
        my $opt = join "\n", sort { $b cmp $a } @out[1 .. $#out];
        ($out[0], $opt);
    };
    my $synopsis = do {
        require Pod::Usage;
        my $out;
        open my $fh, '>', \$out;

        no warnings 'once';

        my $hailo = File::Spec->catfile($Hailo::Command::HERE_MOMMY, 'hailo');
        # Try not to fail on Win32 or other odd systems which might have hailo.pl not hailo
        $hailo = ((glob("$hailo*"))[0]) unless -f $hailo;
        Pod::Usage::pod2usage(
            -input => $hailo,
            -sections => 'SYNOPSIS',
            -output   => $fh,
            -exitval  => 'noexit',
        );
        close $fh;

        $out =~ s/\n+$//s;
        $out =~ s/^Usage:/examples:/;

        $out;
    };

    # Unknown option provided
    print $warning if $warning;

    print <<"USAGE";
$use
$options
USAGE

    say "\n", $synopsis;

    exit 1;
}

__PACKAGE__->meta->make_immutable;

=encoding utf8

=head1 NAME

Bot::Training - Plain text training material for bots like L<Hailo> and L<AI::MegaHAL>

=head1 SYNOPSIS

    use Bot::Training;
    use File::Slurp qw< slurp >;

    my $bt = Bot::Training->new;

    # Plugins I know about. Install Task::Bot::Training for more:
    my @plugins = $bt->plugins

    # Get the plugin object of a .trn file (which is just a plain text
    # file). These all work just as well:
    my $hal = $bt->file('megahal');
    my $hal = $bt->file('MegaHAL');
    my $hal = $bt->file('Bot::Training::MegaHAL');

    # Get all lines in the file with File::Slurp:
    my @test = split /\n/, slurp($hal->file);

=head1 DESCRIPTION

Markov bots like L<Hailo> and L<AI::MegaHAL> are fun. But to get them
working you either need to train them on existing training material or
make your own.

This module provides a pluggable way to install already existing
training files via the CPAN. It also comes with a command-line
interface called C<bot-training>.

=head1 AUTHOR

E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
