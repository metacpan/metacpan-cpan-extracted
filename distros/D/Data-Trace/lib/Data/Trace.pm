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
our $VERSION = '1.06';

=head1 SYNOPSIS

Variable change trace:

    use Data::Trace;

    my $data = {a => [0, {complex => 1}]};

    sub BadCall{ $data->{a}[0] = 1 }

    Trace($data);

    BadCall();  # Shows stack trace of where data was changed.

Stack trace:

    use Data::Trace;
    Trace();    # 1 level.
    Trace(5);   # 5 levels.

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

Watch a reference for changes:

 Trace( \$scalar, @OPTIONS );
 Trace( \@array , @OPTIONS );
 Trace( \@hash , @OPTIONS );
 Trace( $complex_data , @OPTIONS );

Just a stack trace with no watching:

 Trace( @OPTIONS );

Options:

 -clone => 0,    # Disable auto tying after a Storable dclone.

 -var => REF,    # Variable to watch.
 REF             # Same as passing a reference.

 -levels => NUM  # How many scope levels to show.
 NUM             # Same as passing a decimal.

 -raw => 1,      # Include Internal call like Moose,
                 # and Class::MOP in a trace.
 -NUM            # Same as passing negative number.

 -message => STR # Message to use for a normal (non-
                 # tie stack trace).
 STR             # Same as passing anything else.

 -methods => STR   # Monitors only specific methods.
 -methods => [STR] #

=cut

sub Trace {
    my %args   = __PACKAGE__->_ProcessArgs( @_ );
    my $method = $args{-var} ? "_TieNodes" : "_Trace";
    __PACKAGE__->$method( %args );
}

=head2 _ProcessArgs

    Allows calling Trace like:
    Trace() and Trace(-levels => 1) to
    mean the same.

=cut

sub _ProcessArgs {
    my ( $class, @raw_args ) = @_;
    my %args;

    while ( my $arg = shift @raw_args ) {
        if ( $arg =~ / ^ - [a-zA-Z_-] /x ) {
            $args{$arg} = shift @raw_args;
        }
        elsif ( ref $arg ) {
            $args{-var} = $arg;
        }
        elsif ( $arg =~ / ^ (-)? (\d+) $ /x ) {
            $args{-levels} = "$2";
            $args{-raw}    = 1 if $1;
        }
        else {
            $args{-message} = $arg;
        }
    }

    $args{-levels}  //= ( $args{-var} ? 3 : 1 );
    $args{-message} //= "HERE:";
    $args{-raw}     //= 0;

    # Normalize methods and check if valid.
    my $methods = $args{-methods} //= [];
    if ( !ref( $methods ) ) {
        $methods = $args{-methods} = [$methods];
    }
    my %valid_methods =
      map { $_ => 1 } $class->_get_valid_methods();
    @$methods =
      grep { $valid_methods{$_} }
      map { lc } @$methods;

    %args;
}

sub _get_valid_methods {
    qw(
      clear
      delete
      destroy
      exists
      extend
      fetch
      fetchsize
      pop
      push
      shift
      splice
      store
      storesize
      unshift
      firstkey
      nextkey
    );
}

sub _TieNodes {
    my ( $class, %args ) = @_;

    my $var = delete $args{-var} // '';
    if ( not ref $var ) {
        die "Error: trace data must be a reference!";
    }

    my @refs    = grep { ref } Data::DPath->match( $var, "//" );
    my %watches = $class->_BuildWatcherMethods( %args );
    my @nodes;

    for my $ref ( @refs ) {
        push @nodes,
          Data::Tie::Watch->new(
            -variable => $ref,
            %watches,
            %args,
          );
    }

    @nodes;
}

sub _BuildWatcherMethods {
    my ( $class, %args ) = @_;
    my %watches;

    my @methods = $class->_DefineMethodNames();
    if ( @{ $args{-methods} } ) {
        @methods = @{ $args{-methods} };
    }

    for my $name ( @methods ) {
        my $method = ucfirst $name;

        $watches{"-$name"} = sub {

            # Process arguments.
            my ( $_self, @_args ) = @_;
            my $_args =
              join ", ",
              map { defined() ? qq("$_") : "undef" } @_args;

            # Stack trace.
            $class->_Trace( %args, -message => "\U$name\E( $_args ):" );

            # Run actual method/operation.
            $_self->$method( @_args );
        };
    }

    %watches;
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
    my ( $class, %args ) = @_;
    my @lines;
    my $counter;
    my @trace = $class->_TraceRaw();
    if ( not $args{-raw} ) {
        @trace = $class->_FilterOutInternals( @trace );
    }

    # Collect a max amount of lines.
    for my $line ( @trace ) {
        push @lines, $line;
        last if ++$counter >= $args{-levels};
    }

    my ( $first, @rest ) = @lines;

    # Prepend the message.
    # and prefix to additional lines.
    require Time::Moment;
    my $time = Time::Moment->now->strftime( "%Y/%m/%d-%T%3f" );
    @lines = ( "[$time] $args{-message} $first", map { " |- $_" } @rest, );

    # Add an extra line for visibility.
    unshift @lines, "" if @lines > 1;

    # Return the output.
    my $output = join "\n", @lines;
    return $output if defined wantarray;

    # Or send to STDOUT.
    say $output;
}

sub _TraceRaw {
    my ( $class ) = @_;

    local $Carp::MaxArgNums = -1;

    map { s/ ^ \s+ //xr }
      split /\n/,
      Carp::longmess( $class );
}

sub _FilterOutInternals {
    my ( $class, @trace_lines ) = @_;

    # Stack trace while ignoring specific packages.
    grep {
        !m{

            ^ \s* (?:
                  $class
                | [\w_:]+ :: _wrapped_ \w+
                | Data::Tie::Watch::callback
                | Mojolicious
                | Class::MOP
                | Try::Tiny
                | Mojo
                | eval
            ) \b

            |

            (?:
                  Mojolicious/Controller
                | Mojolicious
                | Try/Tiny
            )
            \.pm \s+ line

        }x
    } @trace_lines;
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
