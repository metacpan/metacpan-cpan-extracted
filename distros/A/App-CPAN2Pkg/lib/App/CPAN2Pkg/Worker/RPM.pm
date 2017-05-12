#
# This file is part of App-CPAN2Pkg
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package App::CPAN2Pkg::Worker::RPM;
# ABSTRACT: worker specialized in rpm distributions
$App::CPAN2Pkg::Worker::RPM::VERSION = '3.004';
use Moose;
use MooseX::ClassAttribute;
use MooseX::Has::Sugar;
use MooseX::POE;
use Path::Class;
use Readonly;

use App::CPAN2Pkg::Lock;

extends 'App::CPAN2Pkg::Worker';

Readonly my $K => $poe_kernel;


# -- class attributes


class_has rpmlock => ( ro, isa=>'App::CPAN2Pkg::Lock', default=>sub{ App::CPAN2Pkg::Lock->new } );


# -- attributes


has srpm => ( rw, isa=>'Path::Class::File' );
has rpm  => ( rw, isa=>'Path::Class::File' );
has pkgname => ( rw, isa=>'Str', lazy_build );


# -- initialization

sub _build_pkgname {
    my $self = shift;
    my $pkgname = $self->srpm->basename;
    $pkgname =~ s/-\d.*$//;
    return $pkgname;
}


# -- cpan2pkg logic implementation

{   # _install_from_upstream_result
    override _install_from_upstream_result => sub {
        my $self = shift;
        $self->rpmlock->release;
        super();
    };
}

{   # _cpanplus_create_package_result
    override _cpanplus_create_package_result => sub {
        my ($self, $status, $output) = @_[OBJECT, ARG0 .. $#_ ];
        my $module  = $self->module;
        my $modname = $module->name;

        # check whether the package has been built correctly.
        my ($rpm, $srpm);
        $rpm  = $1 if $output =~ /rpm created successfully: (.*\.rpm)/;
        $srpm = $1 if $output =~ /srpm available: (.*\.src.rpm)/;

        # detecting error cannot be done on $status - sigh.
        if ( not ( $rpm && $srpm ) ) {
            $module->local->set_status( "error" );
            $K->post( main => module_state => $module );
            $K->post( main => log_result => $modname => "Error during package creation" );
            return;
        }

        # logging result
        $K->post( main => log_result => $modname => "Package built successfully" );
        $K->post( main => log_result => $modname => "SRPM: $srpm" );
        $K->post( main => log_result => $modname => "RPM:  $rpm" );

        # storing path to packages
        $self->set_srpm( file($srpm) );
        $self->set_rpm ( file($rpm) );

        $self->yield( "local_install_from_package" );
    };
}

{   # local_install_from_package
    override local_install_from_package => sub {
        super();
        $K->yield( get_rpm_lock => "_local_install_from_package_with_rpm_lock" );
    };

    event _local_install_from_package_with_rpm_lock => sub {
        my $self = shift;
        my $rpm = $self->rpm;
        my $cmd = "sudo rpm -Uv --force $rpm";
        $self->run_command( $cmd => "_local_install_from_package_result" );
    };

    override _local_install_from_package_result => sub {
        my $self = shift;
        $self->rpmlock->release;
        super();
    };
}


# -- events


event get_rpm_lock => sub {
    my ($self, $event) = @_[OBJECT, ARG0];
    my $module  = $self->module;
    my $modname = $module->name;
    my $rpmlock = $self->rpmlock;

    # check whether there's another rpm transaction
    if ( ! $rpmlock->is_available ) {
        my $owner   = $rpmlock->owner;
        my $comment = "waiting for rpm lock... (owned by $owner)";
        $K->post( main => log_comment => $modname => $comment );
        $K->delay( get_rpm_lock => 5, $event );
        return;
    }

    # rpm lock available, grab it
    $rpmlock->get( $modname );
    $self->yield( $event );
};


no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

App::CPAN2Pkg::Worker::RPM - worker specialized in rpm distributions

=head1 VERSION

version 3.004

=head1 DESCRIPTION

This class implements a worker specific to RPM-based distributions. It
inherits from L<App::CPAN2Pkg::Worker>.

=head1 CLASS ATTRIBUTES

=head2 rpmlock

A lock (L<App::CPAN2Pkg::Lock> object) to prevent more than one rpm
installation at a time.

=head1 ATTRIBUTES

=head2 srpm

Path to the source RPM of the module built with C<cpan2dist>.

=head2 rpm

Path to the RPM of the module built with C<cpan2dist>.

=head2 pkgname

The name of the package created.

=head1 EVENTS

=head2 get_rpm_lock

    get_rpm_lock( $event )

Try to get a hold on RPM lock. Fire C<$event> if lock was grabbed
successfully, otherwise wait 5 seconds before trying again.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
