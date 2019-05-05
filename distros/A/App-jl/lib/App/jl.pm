package App::jl;
use strict;
use warnings;
use JSON qw/decode_json to_json/;
use Sub::Data::Recursive;
use Getopt::Long qw/GetOptionsFromArray/;

our $VERSION = '0.04';

my $MAX_DEPTH = 10;

sub new {
    my $class = shift;
    my @argv  = @_;

    bless {
        _opt => $class->_parse_opt(@argv),
    }, $class;
}

sub opt {
    my ($self, $key) = @_;

    return $self->{_opt}{$key};
}

sub run {
    my ($self) = @_;

    while (my $orig_line = <STDIN>) {
        print $self->process($orig_line);
    }
}

sub process {
    my ($self, $line) = @_;

    my $decoded;
    eval {
        $decoded = decode_json($line);
    };
    if ($@) {
        return $line;
    }
    else {
        $self->{_depth} = $self->opt('depth');
        $self->_recursive_decode_json($decoded);
        return to_json($decoded, {pretty => !$self->opt('no_pretty')});
    }
}

sub _recursive_decode_json {
    my ($self, $hash) = @_;

    Sub::Data::Recursive->invoke(
        sub {
            my $line = $_[0];

            if ($self->{_depth} > 0) {
                my $h;
                eval {
                    $h = decode_json($line);
                };
                if (!$@) {
                    $self->{_depth}--;
                    $_[0] = $h;
                    $self->_recursive_decode_json($_[0]);
                }
            }
        },
        $hash
    );
}

sub _parse_opt {
    my ($class, @argv) = @_;

    my $opt = {};

    GetOptionsFromArray(
        \@argv,
        'depth=s'   => \$opt->{depth},
        'no-pretty' => \$opt->{no_pretty},
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

<a href="http://travis-ci.org/bayashi/App-jl"><img src="https://secure.travis-ci.org/bayashi/App-jl.png?_t=1557029628"/></a> <a href="https://coveralls.io/r/bayashi/App-jl"><img src="https://coveralls.io/repos/bayashi/App-jl/badge.png?_t=1557029628&branch=master"/></a>

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
