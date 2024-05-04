package Data::Trace;

use 5.006;
use strict;
use warnings;

use FindBin();
use lib $FindBin::RealBin;

use Data::Tie::Watch;    # Tie::Watch copy.
use Data::DPath;         # All refs in a struct.
use Carp();
use Storable();
use feature qw( say );

our @TIED_NODES;

=head1 NAME

Data::Trace - Trace when a data structure gets updated.

=cut

our $VERSION = '0.15';

=head1 SYNOPSIS

    use Data::Trace;

    my $data = {a => [0, {complex => 1}]};
    sub BadCall{ $data->{a}[0] = 1 }
    Data::Trace->Trace($data);
    BadCall();  # Shows strack trace of where data was changed.

=head1 DESCRIPTION

This module provides a convienient way to find out
when a data structure has been updated.

It is a debugging/tracing aid for complex systems to identify unintentional
alteration to data structures which should be treated as read-only.

Probably can also create a variable as read-only in Moose and see where
its been changed, but this module is without Moose support.

=head1 SUBROUTINES/METHODS

=cut

sub import {
    my $orig = \&Storable::dclone;

    no warnings "redefine";

    *Storable::dclone = sub ($) {
        my @nodes = __PACKAGE__->_UnTieNodes();
        my $data  = $orig->( @_ );
        __PACKAGE__->_TieNodes( \@nodes );

        $data;
    };
}

=head2 Trace

 Data::Trace->Trace( \$scalar );
 Data::Trace->Trace( \@array );
 Data::Trace->Trace( \@hash );
 Data::Trace->Trace( $complex_data );

=cut

sub Trace {
    shift->_TieNodes( @_ );
}

sub _TieNodes {
    my ( $self, $data ) = @_;

    if ( not ref $data ) {
        die "Error: data must be a reference!";
    }

    @TIED_NODES = grep { ref } Data::DPath->match( $data, "//" );

    my %args = $self->_DefineWatchArgs();

    for my $node ( @TIED_NODES ) {
        $node = Data::Tie::Watch->new(
            -variable => $node,
            %args,
        );
    }

    \@TIED_NODES;
}

sub _UnTieNodes {
    my ( $self ) = @_;
    return if not @TIED_NODES;

    for my $node ( @TIED_NODES ) {
        $node->Unwatch();
    }

    splice @TIED_NODES;
}

sub _DefineWatchArgs {
    my @methods = qw(
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

    my %args;

    for my $name ( @methods ) {
        $args{"-$name"} = sub {
            my ( $_self, @_args ) = @_;
            my $method = ucfirst $name;
            __PACKAGE__->_Trace( "\U$name\Eing here" );
            $_self->$method( @_args );
        };
    }

    %args;
}

sub _Trace {
    my ( $class, $message ) = @_;
    $message //= '';

    $Carp::MaxArgNums = -1;

    say for "$message:", map { "\t$_" }
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
      map { s/^\s+//r }
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

You can find documentation for this module with the perldoc command.

    perldoc Data::Trace


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Tim Potapov.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Data::Trace
