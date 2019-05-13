package App::jl;
use strict;
use warnings;
use JSON qw//;
use Sub::Data::Recursive;
use Getopt::Long qw/GetOptionsFromArray/;

our $VERSION = '0.06';

my $MAX_DEPTH = 10;

sub new {
    my $class = shift;
    my @argv  = @_;

    my $opt = $class->_parse_opt(@argv);

    bless {
        _opt  => $opt,
        _json => JSON->new->utf8->pretty(!$opt->{no_pretty})->canonical(1),
    }, $class;
}

sub opt {
    my ($self, $key) = @_;

    return $self->{_opt}{$key};
}

sub run {
    my ($self) = @_;

    while (my $orig_line = <STDIN>) {
        if ($orig_line !~ m!^[\[\{]!) {
            print $orig_line;
            next;
        }
        print $self->process($orig_line);
    }
}

sub process {
    my ($self, $line) = @_;

    my $decoded = eval {
        $self->{_json}->decode($line);
    };
    if ($@) {
        return $line;
    }
    else {
        Sub::Data::Recursive->invoke(\&_split => $decoded) if $self->opt('x');
        $self->{_depth} = $self->opt('depth');
        $self->_recursive_decode_json($decoded);
        return $self->{_json}->encode($decoded);
    }
}

sub _split {
    my $line = $_[0];

    if ($line =~ m![\t\r\n]!) {
        chomp $line;
        my @elements = split /[\t\r\n]/, $line;
        $_[0] = \@elements;
    }
}

sub _recursive_decode_json {
    my ($self, $hash) = @_;

    Sub::Data::Recursive->invoke(sub {
        if ($self->{_depth} > 0) {
            my $orig = $_[0];
            my $decoded = eval {
                $self->{_json}->decode($orig);
            };
            if (!$@) {
                $self->{_depth}--;
                $_[0] = $decoded;
                $self->_recursive_decode_json($_[0]); # recursive calling
            }
        }
    } => $hash);
}

sub _parse_opt {
    my ($class, @argv) = @_;

    my $opt = {};

    GetOptionsFromArray(
        \@argv,
        'depth=s'   => \$opt->{depth},
        'no-pretty' => \$opt->{no_pretty},
        'x'         => \$opt->{x},
        'h|help'    => sub {
            $class->_show_usage(1);
        },
        'v|version' => sub {
            print "$0 $VERSION\n";
            exit 1;
        },
    ) or $class->_show_usage(2);

    $opt->{depth} ||= $MAX_DEPTH;

    return $opt;
}

sub _show_usage {
    my ($class, $exitval) = @_;

    require Pod::Usage;
    Pod::Usage::pod2usage(-exitval => $exitval);
}

1;

__END__

=encoding UTF-8

=head1 NAME

App::jl - Recursive JSON decoder


=head1 SYNOPSIS

    use App::jl;


=head1 DESCRIPTION

App::jl is recursive JSON decoder. This module can decode JSON in JSON.

See L<jl> for CLI to view logs.


=head1 METHODS

=head2 new

constructor

=head2 opt

getter of optional values

=head2 run

The main routine

=head2 process

The parser of the line


=head1 REPOSITORY

=begin html

<a href="http://travis-ci.org/bayashi/App-jl"><img src="https://secure.travis-ci.org/bayashi/App-jl.png?_t=1557473289"/></a> <a href="https://coveralls.io/r/bayashi/App-jl"><img src="https://coveralls.io/repos/bayashi/App-jl/badge.png?_t=1557473289&branch=master"/></a>

=end html

App::jl is hosted on github: L<http://github.com/bayashi/App-jl>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<jl>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
