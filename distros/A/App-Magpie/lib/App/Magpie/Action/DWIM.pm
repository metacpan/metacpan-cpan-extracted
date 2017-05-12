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

package App::Magpie::Action::DWIM;
# ABSTRACT: dwim command implementation
$App::Magpie::Action::DWIM::VERSION = '2.010';
use File::pushd;
use Moose;
use Parallel::ForkManager;

use App::Magpie::Action::Checkout;
use App::Magpie::Action::Old;
use App::Magpie::Action::Update;

with 'App::Magpie::Role::Logging';



sub run {
    my ($self, $directory) = @_;
    
    my @sets = App::Magpie::Action::Old->new->run;
    my ($normal) = grep { $_->name eq "normal" } @sets;
    if ( not defined $normal ) {
        $self->log( "no package to update" );
        return;
    }
    my @modules = $normal->all_modules;

    my $pm = Parallel::ForkManager->new(5);
    my @failed;
    $pm->run_on_finish( sub {
            my ($pid, $rv, $id, $signal, $core, $data) = @_;
            push @failed, $id if $rv;
            print $data;
        } );

    # loop around the modules
    my %seen;
    foreach my $module (@modules) {
        my $pkg = ( $module->packages )[0];
        my $modname = $module->name;
        my $pkgname = $pkg->name;
        next if $seen{$pkgname}++; # do not try to update a pkg more than once

        # forks and returns the pid for the child:
        my $pid = $pm->start($pkgname) and next;

        $self->log( "updating " . $modname
            . " from " .  $module->oldver
            . " to "   . $module->newver
            . " in "   . $pkgname );

        # check out the package
        my $pkgdir = App::Magpie::Action::Checkout->new->run( $pkg->name, $directory );
        my $old = pushd( $pkgdir );

        # update the package
        eval { App::Magpie::Action::Update->new->run; };
        my $rv = $@ ? 1 : 0;
        $pm->finish( $rv ); # Terminates the child process
    }
    $pm->wait_all_children;
    $self->log( "error while updating: $_" ) for sort @failed;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Magpie::Action::DWIM - dwim command implementation

=head1 VERSION

version 2.010

=head1 SYNOPSIS

    my $dwim = App::Magpie::Action::DWIM->new;
    $dwim->run;

=head1 DESCRIPTION

This module implements the C<dwim> action. It's in a module of its own
to be able to be C<require>-d without loading all other actions.

=head1 METHODS

=head2 run

    $dwim->run;

Update Mageia packages of Perl modules with a new version available on
CPAN.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
