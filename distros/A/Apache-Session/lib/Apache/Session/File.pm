#############################################################################
#
# Apache::Session::File
# Apache persistent user sessions in the filesystem
# Copyright(c) 1998, 1999, 2000 Jeffrey William Baker (jwbaker@acm.org)
# Distribute under the Perl License
#
############################################################################

package Apache::Session::File;

use strict;
use vars qw(@ISA $VERSION);

$VERSION = '1.54';
@ISA = qw(Apache::Session);

use Apache::Session;
use Apache::Session::Lock::File;
use Apache::Session::Store::File;
use Apache::Session::Generate::MD5;
use Apache::Session::Serialize::Storable;

sub populate {
    my $self = shift;

    $self->{object_store} = Apache::Session::Store::File->new($self);
    $self->{lock_manager} = Apache::Session::Lock::File->new($self);
    $self->{generate}     = \&Apache::Session::Generate::MD5::generate;
    $self->{validate}     = \&Apache::Session::Generate::MD5::validate;
    $self->{serialize}    = \&Apache::Session::Serialize::Storable::serialize;
    $self->{unserialize}  = \&Apache::Session::Serialize::Storable::unserialize;

    return $self;
}

sub DESTROY {
    my $self = shift;
    
    $self->save;
    $self->{object_store}->close;
    $self->release_all_locks;
}

1;


=pod

=head1 NAME

Apache::Session::File - An implementation of Apache::Session

=head1 SYNOPSIS

 use Apache::Session::File;

 tie %hash, 'Apache::Session::File', $id, {
    Directory => '/tmp/sessions',
    LockDirectory   => '/var/lock/sessions',
 };

=head1 DESCRIPTION

This module is an implementation of Apache::Session.  It uses the File backing
store and the File locking scheme.  You must specify the directory for the
object store and the directory for locking in arguments to the constructor. See
the example, and the documentation for Apache::Session::Store::File and
Apache::Session::Lock::File.

=head1 AUTHOR

This module was written by Jeffrey William Baker <jwbaker@acm.org>.

=head1 SEE ALSO

L<Apache::Session::DB_File>, L<Apache::Session::Flex>,
L<Apache::Session::MySQL>, L<Apache::Session::Postgres>, L<Apache::Session>
