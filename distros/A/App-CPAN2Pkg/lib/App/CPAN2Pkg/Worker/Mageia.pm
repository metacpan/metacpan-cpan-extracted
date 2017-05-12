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

package App::CPAN2Pkg::Worker::Mageia;
# ABSTRACT: worker dedicated to Mageia distribution
$App::CPAN2Pkg::Worker::Mageia::VERSION = '3.004';
use HTML::TreeBuilder;
use HTTP::Request;
use Moose;
use MooseX::ClassAttribute;
use MooseX::Has::Sugar;
use MooseX::POE;
use POE;
use POE::Component::Client::HTTP;
use Readonly;

extends 'App::CPAN2Pkg::Worker::RPM';

Readonly my $K => $poe_kernel;

# -- class attribute

class_has _urpm_ok => (
    rw,
    traits  => ['Counter'],
    isa     => 'Int',
    default => 2,
    handles => {
        _urpm_release => "inc",
        _urpm_grab    => "dec",
    },
);
class_has cpanplus_lock => ( ro, isa=>'App::CPAN2Pkg::Lock', default=>sub{ App::CPAN2Pkg::Lock->new } );


class_has _ua => ( ro, isa=>'Str', builder=>"_build__ua" );

sub _build__ua {
    my $ua = "mageia-bswait";
    POE::Component::Client::HTTP->spawn( Alias => $ua );
    return $ua;
}


# -- public methods

override cpan2dist_flavour => sub { "CPANPLUS::Dist::Mageia" };


# -- cpan2pkg logic implementation

{   # check_upstream_availability
    override check_upstream_availability => sub {
        my $self = shift;
        my $modname = $self->module->name;
        $K->post( main => log_step    => $modname => "Checking if module is packaged upstream");
        $K->post( main => log_comment => $modname => "waiting for semaphore before running urpm");
        $K->yield( "_check_upstream_availability_wait4lock" );
    };

    event _check_upstream_availability_wait4lock => sub {
        my $self = shift;
        if ( $self->_urpm_ok ) {
            $self->_urpm_grab;
            $K->yield( "_check_upstream_availability_lock_acquired" );
            return;
        }
        $K->delay( _check_upstream_availability_wait4lock => 0.1 );
    };

    event _check_upstream_availability_lock_acquired => sub {
        my $self = shift;
        my $modname = $self->module->name;
        $K->post( main => log_comment => $modname => "urpm semaphore acquired");
        my $cmd = "urpmq --whatprovides 'perl($modname)'";
        $self->run_command( $cmd => "_check_upstream_availability_done" );
    };

    event _check_upstream_availability_done => sub {
        my ($self, @args) = @_[OBJECT, ARG0 .. $#_];
        my $modname = $self->module->name;
        $self->_urpm_release;
        $K->post( main => log_comment => $modname => "urpm semaphore released");
        $K->yield( _check_upstream_availability_result => @args );
    };
}

{   # install_from_upstream
    override install_from_upstream => sub {
        super();
        $K->yield( get_rpm_lock => "_install_from_upstream_with_rpm_lock" );
    };

    #
    # _install_from_upstream_with_rpm_lock( )
    #
    # really install module from distribution, now that we have a lock
    # on rpm operations.
    #
    event _install_from_upstream_with_rpm_lock => sub {
        my $self = shift;
        my $modname = $self->module->name;
        my $cmd = "sudo urpmi --auto 'perl($modname)'";
        $self->run_command( $cmd => "_install_from_upstream_result" );
    };
}

{ # upstream_import_package
    override upstream_import_package => sub {
        super();
        my $self = shift;
        my $srpm = $self->srpm;
        my $cmd = "mgarepo import $srpm";
        $self->run_command( $cmd => "_upstream_import_package_result" );
    };
}

{ # upstream_build_package
    override upstream_build_package => sub {
        super();
        my $self = shift;
        my $pkgname = $self->pkgname;
        my $cmd = "mgarepo submit $pkgname";
        $self->run_command( $cmd => "_upstream_build_package_result" );
    };

    override _upstream_build_wait => sub {
        my $self = shift;
        $self->yield( "_upstream_build_wait_request" );
    };

    event _upstream_build_wait_request => sub {
        my $self = shift;
        my $pkgname = $self->pkgname;
        my $url = "http://pkgsubmit.mageia.org/?package=$pkgname&last";
        my $request = HTTP::Request->new(HEAD => $url);
        $K->post( $self->_ua => request => _upstream_build_wait_answer => $request );
    };

    event _upstream_build_wait_answer => sub {
        my ($self, $requests, $answers) = @_[OBJECT, ARG0, ARG1];
        my $answer = $answers->[0];
        my $status = $answer->header( 'x-bs-package-status' ) // "?";
        my $modname = $self->module->name;
        if ($status eq "uploaded") {
            # nice, we finally made it!
            my $min = 1;
            $K->post( main => log_comment => $modname =>
                "module successfully built, waiting $min minutes to index it" );
            # wait some time to be sure package has been indexed
            $K->delay( _upstream_build_package_ready => $min * 60 );
        }
        elsif ($status eq "failure" ) {
            my $url = "http://pkgsubmit.mageia.org/";
            $self->yield( _upstream_build_package_failed => $url );
        }
        else {
            # no definitive result, wait a bit before checking again
            $K->post( main => log_comment => $modname =>
                "still not ready (current status: $status), waiting 1 more minute" );
            $K->delay( _upstream_build_wait_request => 60 );
        }

    };
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

App::CPAN2Pkg::Worker::Mageia - worker dedicated to Mageia distribution

=head1 VERSION

version 3.004

=head1 DESCRIPTION

This class implements Mageia specificities that a general worker doesn't
know how to handle. It inherits from L<App::CPAN2Pkg::Worker::RPM>.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
