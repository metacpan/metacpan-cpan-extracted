#
# This file is part of App-Magpie
#
# This software is copyright (c) 2011 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.012;
use strict;
use warnings;

package App::Magpie::Action::Checkout;
# ABSTRACT: checkout command implementation
$App::Magpie::Action::Checkout::VERSION = '2.010';
use File::pushd;
use Moose;
use Path::Tiny;

use App::Magpie::URPM;

with 'App::Magpie::Role::Logging';
with 'App::Magpie::Role::RunningCommand';



sub run {
    my ($self, $pkg, $directory) = @_;

    # check if argument is a perl module or a mageia rpm name
    if ( not _pkg_exist_in_svn($pkg) ) {
        $self->log( "$pkg doesn't exist, looking if it's a perl module" );
        my $urpm = App::Magpie::URPM->instance;
        my ($realpkg) = map { $_->name } $urpm->packages_providing( $pkg );
        $self->log_fatal( "$pkg doesn't exist and isn't a perl module, aborting" )
            unless $realpkg && _pkg_exist_in_svn( $realpkg );
        $self->log( "$pkg is a module provided by $realpkg" );
        $pkg = $realpkg;
    }

    # check out the package, or update the local checkout
    my $dir    = defined($directory) ? path( $directory ) : path(".");
    my $pkgdir = $dir->child( $pkg );
    $dir->mkpath unless -d $dir;
    $self->log( "checking out $pkg in $pkgdir" );

    if ( -d $pkgdir ) {
        $self->log( "package already checked out, refreshing checkout");
        my $old = pushd( $pkgdir );
        $self->run_command( "mgarepo up" );
    } else {
        my $old = pushd( $dir );
        $self->run_command( "mgarepo co $pkg" );
    }

    return $pkgdir;
}


# -- private subs

#
#   my $bool = _pkg_exist_in_svn( $pkg );
#
# return true if $pkg is a real package in cauldron.
#
sub _pkg_exist_in_svn {
    my $pkg = shift;
    my $svn = "svn+ssh://svn.mageia.org/svn/packages/cauldron";
    return system( "svn ls $svn/$pkg >/dev/null 2>&1" ) == 0;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Magpie::Action::Checkout - checkout command implementation

=head1 VERSION

version 2.010

=head1 SYNOPSIS

    my $checkout = App::Magpie::Action::Checkout->new;
    $checkout->run( $pkg );

=head1 DESCRIPTION

This module implements the C<checkout> action. It's in a module of its
own to be able to be C<require>-d without loading all other actions.

=head1 METHODS

=head2 run

    my $pkgdir = $checkout->run( $pkg [, $directory] );

Check out C<$pkg> under C<$directory> (or current directory if no
directory specified). Refresh the checkout if it already exists.

Return the directory in which the checkout is located.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
