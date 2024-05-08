package Data::Trace;

=head1 NAME

Data::Trace - Trace when a data structure gets updated.

=cut

use 5.006;
use strict;
use warnings;

use FindBin();
use lib $FindBin::RealBin;

use Data::Tie::Watch;    # Tie::Watch copy.
use Data::DPath;         # All refs in a struct.
use Carp();
use parent  qw( Exporter );
use feature qw( say );

our @EXPORT  = qw( Trace );
our $VERSION = '0.18';

=head1 SYNOPSIS

    use Data::Trace;

    my $data = {a => [0, {complex => 1}]};
    sub BadCall{ $data->{a}[0] = 1 }
    Trace($data);
    BadCall();  # Shows strack trace of where data was changed.

=cut

=head1 DESCRIPTION

This module provides a convienient way to find out
when a data structure has been updated.

It is a debugging/tracing aid for complex systems to identify unintentional
alteration to data structures which should be treated as read-only.

Probably can also create a variable as read-only in Moose and see where
its been changed, but this module is without Moose support.

=cut

=head1 SUBROUTINES/METHODS

=head2 Trace

 Trace( \$scalar );
 Trace( \@array );
 Trace( \@hash );
 Trace( $complex_data );

=cut

sub Trace {
    __PACKAGE__->_TieNodes( @_ );
}

sub _TieNodes {
    my ( $class, $data, @args ) = @_;

    if ( not ref $data ) {
        die "Error: data must be a reference!";
    }

    my @refs    = grep { ref } Data::DPath->match( $data, "//" );
    my %watches = $class->_BuildWatcherMethods();
    my @nodes;

    for my $ref ( @refs ) {
        push @nodes,
          Data::Tie::Watch->new(
            -variable => $ref,
            %watches,
            @args,
          );
    }

    @nodes;
}

sub _BuildWatcherMethods {
    my ( $class ) = @_;
    my %args;

    for my $name ( $class->_DefineMethodNames() ) {
        my $method = ucfirst $name;
        $args{"-$name"} = sub {
            my ( $_self, @_args ) = @_;
            my $_args =
              join ", ",
              map { defined() ? qq("$_") : "undef" } @_args;
            __PACKAGE__->_Trace( "\U$name\E( $_args ):" );
            $_self->$method( @_args );
        };
    }

    %args;
}

sub _DefineMethodNames {
    qw(
      store
      clear
      delete
      extend
      pop
      push
      shift
      splice
      unshift
    );
}

sub _Trace {
    my ( $class, $message ) = @_;
    $message //= '';

    local $Carp::MaxArgNums = -1;

    say "";
    say $message;

    say for map { "\t$_" }
      grep {
        !m{
                ^ \s* (?:
                      Class::MOP
                    | [\w_:]+ :: _wrapped_ \w+
                    | $class
                    | Data::Tie::Watch::callback
                    | Mojolicious
                    | Mojo
                    | Try::Tiny
                    | eval
                ) \b

                |

                (?:
                      Try/Tiny
                    | Mojolicious
                    | Mojolicious/Controller
                )
                \.pm \s+ line

            }x
      }
      map { s/ ^ \s+ //xr }
      split /\n/,
      Carp::longmess( $class );
}

=head1 AUTHOR

Tim Potapov, C<< <tim.potapov at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/poti1/data-trace/issues>.

Currently only detect C<STORE> operations.
Expand this to also detect C<PUSH>, C<POP>, C<DELETE>, etc.

=head1 TODO

Consider adding an option to have a warn message anytime a structure is FETCHed.

=head1 SUPPORT

You can find documentation for this module
with the perldoc command.

    perldoc Data::Trace

You can also look for information at:

L<https://metacpan.org/pod/Data::Trace>

L<https://github.com/poti1/data-trace>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Tim Potapov.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

"\x{1f42a}\x{1f977}"
