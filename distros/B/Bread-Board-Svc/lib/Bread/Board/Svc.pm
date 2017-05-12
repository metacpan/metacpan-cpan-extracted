package Bread::Board::Svc;
$Bread::Board::Svc::VERSION = '0.02';
use strict;
use warnings;

# ABSTRACT: shortcuts for Bread::Board::service function


use Exporter 'import';
use Carp qw(confess);
use Types::Standard
    qw(Ref ArrayRef ScalarRef Str Maybe HashRef CodeRef Any Tuple);

use List::Util qw(pairmap );

our @EXPORT_OK = qw(svc svc_singleton);

# with reference to arrayref the parameters are passed positional
# svc($name, $class, [ \@deps ], $block)
my $pos_deps_type = ScalarRef [ArrayRef];
my $deps_type = ArrayRef | HashRef | $pos_deps_type;

my $params_type
    = Tuple [ Str, Str, $deps_type, CodeRef ]   # $name, $class, $deps, $block
    | Tuple [ Str, Str, $deps_type ]            # $name, $class, $deps,
    | Tuple [ Str, $deps_type, CodeRef ]        # $name, $deps, $block
    ;

# same as service returns literal
my $svc_params_type = $params_type | Tuple [ Str, Any ];
my $svc_singleton_params_type = $params_type;

sub svc {
    confess "svc: invalid args: " . join( ', ', map {"'$_'"} @_ )
        if !$svc_params_type->( [@_] );

    return _svc( 0, @_ );
}

sub svc_singleton {
    confess "svc_singleton: invalid args: " . join( ', ', map {"'$_'"} @_ )
        if !$svc_singleton_params_type->check( [@_] );
    return _svc( 1, @_ );
}

sub _svc {
    my ( $singleton, $name, @args ) = @_;

    # leads to Bread::Board::Service::Literal
    return Bread::Board::service( $name => $args[0] ) if @args == 1;

    my $class = !ref $args[0] ? shift @args : ();
    my $deps  = shift @args;
    my $body  = shift @args;

    my $build = sub {
        return Bread::Board::service(
            $name,
            ( $singleton ? ( lifecycle => 'Singleton' ) : () ),
            ( $class     ? ( class     => $class )      : () ), @_
        );
    };
    if ( $pos_deps_type->check($deps) ) {

        # positional dependencies passed like \ [  path1, path2 ]
        my $i            = 0;
        my @dependencies = map { ( "p" . ++$i => $_ ); } @{$$deps};
        my @pnames       = pairmap {$a} @dependencies;

        return $build->(
            dependencies => +{@dependencies},
            block        => sub {
                my $s    = shift;
                my @args = @{ $s->params }{@pnames};
                return $body
                    ? $body->( $class ? $s->class : (), @args )
                    : $s->class->new(@args);
            }
        );
    }

    # named dependencies, parameters are interpolated
    # key => value, ...  instead of \%params
    return $build->(
        dependencies => $deps,
        (   $body
            ? ( block => sub {
                    my $s = shift;
                    $body->( $class ? $s->class : (), %{ $s->params } );
                }
                )
            : ()
        ),
    );
}

1;

# vim: expandtab:shiftwidth=4:tabstop=4:softtabstop=0:textwidth=78:

__END__

=pod

=encoding UTF-8

=head1 NAME

Bread::Board::Svc - shortcuts for Bread::Board::service function

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use Bread::Board::Svc qw(svc svc_singleton);

    # instead of 
    service router => (
        class        => 'Router::Pygmy',
        dependencies => ['routes'],
    );

    # you can write positionally
    svc 'router', 'Router::Pygmy', ['routes'];

    # instead of
    service app_data => (
        dependencies => ['app_home'],
        block        => sub {
            my $s = shift;
            my $p = $s->params;
            dir( $p->{app_home}, 'var' );
        }
    );

    # you can write
    svc app_data => ( \['app_home'], sub { dir( shift(), 'var' ) } );

    # or
    svc 'app_data', \['app_home'], sub { dir( shift(), 'var' ) };

=head1 DESCRIPTION

This module provides shortcut for Bread::Board::Service with positional
params.

=head1 EXPORTED FUNCTIONS

All functions are exported on demand.

=over 4

=item B<svc($name, @args)>

Creates service by calling Bread::Board::service internally.

=item B<svc_singleton($name, @args)>

Same as C<< svc >> but adds C<< lifecycle => 'Singleton' >> to Bread::Board::service params.

=back

The argument combinations are:

=over 4

=item B<svc($name, $class, $deps, $body)>

=item B<svc($name, $class, $deps)>

=item B<svc($name, $deps, $body)>

=item B<svc($name, $value)>

This combination just passes args to Bread::Board::service.

=back

When the service is about to be resolved, then C<< $body >> subroutine is called. 
The arguments are C<< $class >> (if present) and the list of resolved dependencies.

If C<< $deps >> is a hashref or an arrayref, it has same meaning as for dependencies
and resolved dependencies are passed as << $key => $value >>.
If C<< $deps >> is a reference to an arrayref (C<< \ [ $path1, $path2, ... ] >> ), 
then only the dependency values are passed to block, without the names (the
names are constructed artificially).

If C<< $body >> is ommitted then the constructor of C<< $class >> is called
(see Bread::Board::ConstructorInjection).

It should be noted that C<< $class >> is loaded lazily (before first resolution).

=head1 AUTHOR

Roman Daniel <roman@daniel.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Roman Daniel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
