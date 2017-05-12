#############################################################################
#
# Apache::Session::DB_File
# A wrapper class
# Copyright(c) 2000 Jeffrey William Baker (jwbaker@acm.org)
# Distribute under the Perl License
#
############################################################################

package Apache::Session::DB_File;

use strict;
use vars qw(@ISA $VERSION);

$VERSION = '1.01';
@ISA = qw(Apache::Session);

use Apache::Session;
use Apache::Session::Lock::File;
use Apache::Session::Store::DB_File;
use Apache::Session::Generate::MD5;
use Apache::Session::Serialize::Storable;

sub populate {
    my $self = shift;

    $self->{object_store} = Apache::Session::Store::DB_File->new($self);
    $self->{lock_manager} = Apache::Session::Lock::File->new($self);
    $self->{generate}     = \&Apache::Session::Generate::MD5::generate;
    $self->{validate}     = \&Apache::Session::Generate::MD5::validate;
    $self->{serialize}    = \&Apache::Session::Serialize::Storable::serialize;
    $self->{unserialize}  = \&Apache::Session::Serialize::Storable::unserialize;

    return $self;
}

1;

=pod

=head1 NAME

Apache::Session::DB_File - An implementation of Apache::Session

=head1 SYNOPSIS

 use Apache::Session::DB_File;

 tie %hash, 'Apache::Session::DB_File', $id, {
    FileName      => 'sessions.db',
    LockDirectory => '/var/lock/sessions',
 };

=head1 DESCRIPTION

This module is an implementation of Apache::Session.  It uses the DB_File
backing store and the File locking scheme.  You must specify the filename of
the database file and the directory for locking in arguments to the constructor.
See the example, and the documentation for Apache::Session::Store::DB_File and
Apache::Session::Lock::File.

=head1 AUTHOR

This module was written by Jeffrey William Baker <jwbaker@acm.org>.

=head1 SEE ALSO

L<Apache::Session::File>, L<Apache::Session::Flex>,
L<Apache::Session::MySQL>, L<Apache::Session::Postgres>, L<Apache::Session>
