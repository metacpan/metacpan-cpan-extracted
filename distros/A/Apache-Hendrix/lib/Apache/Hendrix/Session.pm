package Apache::Hendrix::Session;

# $Id$

use v5.10.0;
use warnings;
use strict;
use Apache2::Request;
use Apache::Hendrix;
use Carp;
use Module::Load;
use Moose;
use MooseX::ClassAttribute;
use MooseX::FollowPBP;
use TryCatch;
use version; our $VERSION = qv(0.1.0);

class_has 'options' => (
    isa     => 'HashRef',
    is      => 'rw',
    default => sub {
        {
            Directory     => '/tmp/sessions',
            LockDirectory => '/tmp/sessions/lock',
        };
    },
    lazy => 1,
);
class_has 'type' => (
    isa     => 'Str',
    is      => 'rw',
    default => sub {
        my ($self) = @_;
        my $default = 'Apache::Session::File';
	load $default;
	return $default;
    },
);

Moose::Exporter->setup_import_methods( as_is => [ 'session_start', 'session_type', 'session_options' ] );

sub session_type {
    my ($type) = @_;
    __PACKAGE__->type($type) if $type;
    load $type;
    return __PACKAGE__->type();
}

sub session_options {
    my ($options) = @_;
    __PACKAGE__->options($options) if $options;
    return __PACKAGE__->options();
}

sub session_start {
    my $r = Apache::Hendrix->request;

    # Extract old session ID.  If not found we create a new one below
    my $id;
    if ( $r->headers_in->get('Cookie') =~ m/SESSION_ID=(\w*)/ ) {
        $id = $1;
    }

    my %session;
    try {
	tie %session, __PACKAGE__->type, $id, __PACKAGE__->options;
    } catch ($e) {
	if ($e =~ /Object does not exist in the data store/) {
	    tie %session, __PACKAGE__->type, undef, __PACKAGE__->options;
	}
	else {
	    croak $e;
	}
    }

    # Might be a new session, so lets give them their cookie back
    my $session_cookie = "SESSION_ID=$session{_session_id};";
    $r->headers_out->set( 'Set-Cookie' => $session_cookie );
    return \%session;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Apache::Hendrix::Session - Provide helper functions for Hendrix apps

=head1 SYNOPSIS

use Apache::Hendrix::Session;

get '/' => sub {
    my $session_vars = start_session();
    ....

}

=head1 DETAILS

By default Apache::Hendrix::Session uses a file store in /tmp.  This
is not very secure and should be customized to your needs.  You can
tell it to use any session tool that Apache::Session supports.  See
Configuration, below.

=head1 CONFIGURATION


=over

=head2 MySQL

session_type('Apache::Session::MySQL');

session_options( {
        DataSource     => 'dbi:mysql:sessions',    #these arguments are
        UserName       => 'MyUser',            #required when using
        Password       => '123456',                #MySQL.pm
        LockDataSource => 'dbi:mysql:sessions',
        LockUserName   => 'MyLockUser',
        LockPassword   => '654321',
    },
);

=head2 Session Table Structure

CREATE TABLE `sessions` (
  `id` char(32) NOT NULL,
  `a_session` text,
  PRIMARY KEY (`id`)
)

=head2 File

session_type('Apache::Session::File');

session_options( {
         Directory     => '/tmp/sessions',
         LockDirectory => '/tmp/sessions/lock',
     },
)

=head2 File System Layout

 mkdir -p /tmp/sessions/lock

 sudo chown -R www-data.www.data /tmp/sessions

=back


=head1 REQUIRED LIBS

=over

=item Apache2::Request;

=item Apache::Hendrix;

=item Module::Load;

=item Moose;

=item MooseX::ClassAttribute;

=item MooseX::FollowPBP;

=back

=head1 REVISION HISTORY

=item 0.1.0 - Initial concept

=head1 AUTHOR

=over

=item Zack Allison

=back

=cut
