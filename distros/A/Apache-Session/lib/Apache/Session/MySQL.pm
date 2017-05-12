#############################################################################
#
# Apache::Session::MySQL
# Apache persistent user sessions in a MySQL database
# Copyright(c) 1998, 1999, 2000 Jeffrey William Baker (jwbaker@acm.org)
# Distribute under the Perl License
#
############################################################################

package Apache::Session::MySQL;

use strict;
use vars qw(@ISA $VERSION);

$VERSION = '1.01';
@ISA = qw(Apache::Session);

use Apache::Session;
use Apache::Session::Lock::MySQL;
use Apache::Session::Store::MySQL;
use Apache::Session::Generate::MD5;
use Apache::Session::Serialize::Storable;

sub populate {
    my $self = shift;

    $self->{object_store} = new Apache::Session::Store::MySQL $self;
    $self->{lock_manager} = new Apache::Session::Lock::MySQL $self;
    $self->{generate}     = \&Apache::Session::Generate::MD5::generate;
    $self->{validate}     = \&Apache::Session::Generate::MD5::validate;
    $self->{serialize}    = \&Apache::Session::Serialize::Storable::serialize;
    $self->{unserialize}  = \&Apache::Session::Serialize::Storable::unserialize;

    return $self;
}

1;


=pod

=head1 NAME

Apache::Session::MySQL - An implementation of Apache::Session

=head1 SYNOPSIS

 use Apache::Session::MySQL;

 #if you want Apache::Session to open new DB handles:

 tie %hash, 'Apache::Session::MySQL', $id, {
    DataSource => 'dbi:mysql:sessions',
    UserName   => $db_user,
    Password   => $db_pass,
    LockDataSource => 'dbi:mysql:sessions',
    LockUserName   => $db_user,
    LockPassword   => $db_pass
 };

 #or, if your handles are already opened:

 tie %hash, 'Apache::Session::MySQL', $id, {
    Handle     => $dbh,
    LockHandle => $dbh
 };

=head1 DESCRIPTION

This module is an implementation of Apache::Session.  It uses the MySQL backing
store and the MySQL locking scheme.  See the example, and the documentation for
Apache::Session::Store::MySQL and Apache::Session::Lock::MySQL for more
details.

=head1 AUTHOR

This module was written by Jeffrey William Baker <jwbaker@acm.org>.

=head1 SEE ALSO

L<Apache::Session::File>, L<Apache::Session::Flex>,
L<Apache::Session::DB_File>, L<Apache::Session::Postgres>, L<Apache::Session>
