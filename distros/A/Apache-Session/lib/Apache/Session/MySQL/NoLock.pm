#############################################################################
#
# Apache::Session::MySQL::NoLock
# Apache persistent user sessions in a MySQL database without locking
# Copyright(c) 2010 Tomas (t0m) Doran (bobtfish@bobtfish.net)
# Distribute under the Perl License
#
############################################################################

package Apache::Session::MySQL::NoLock;

use strict;
use vars qw(@ISA $VERSION);

$VERSION = '0.01';
@ISA = qw(Apache::Session);

use Apache::Session;
use Apache::Session::Lock::Null;
use Apache::Session::Store::MySQL;
use Apache::Session::Generate::MD5;
use Apache::Session::Serialize::Storable;

sub populate {
    my $self = shift;

    $self->{object_store} = new Apache::Session::Store::MySQL $self;
    $self->{lock_manager} = new Apache::Session::Lock::Null $self;
    $self->{generate}     = \&Apache::Session::Generate::MD5::generate;
    $self->{validate}     = \&Apache::Session::Generate::MD5::validate;
    $self->{serialize}    = \&Apache::Session::Serialize::Storable::serialize;
    $self->{unserialize}  = \&Apache::Session::Serialize::Storable::unserialize;

    return $self;
}

1;

=pod

=head1 NAME

Apache::Session::MySQL::NoLock - An implementation of Apache::Session::MySQL without locking

=head1 SYNOPSIS

 use Apache::Session::MySQL::NoLock;

 #if you want Apache::Session to open new DB handles:

 tie %hash, 'Apache::Session::MySQL::NoLock', $id, {
    DataSource => 'dbi:mysql:sessions',
    UserName => $db_user,
    Password => $db_pass,
 };

 #or, if your handles are already opened:

 tie %hash, 'Apache::Session::MySQL::NoLock', $id, {
    Handle => $dbh,
 };

 To configure the non-locking session store in RT (what I use this module for),
 put the following into your C<RT_SiteConfig.pm> module:

    Set($WebSessionClass , 'Apache::Session::MySQL::NoLock');

=head1 DESCRIPTION

This module is an implementation of Apache::Session. It uses the MySQL backing
store and the Null locking scheme. See the example, and the documentation for
Apache::Session::Store::MySQL for more details.

=head1 WARNING

This module explicitly B<DOES NOT DO ANY LOCKING>. This can cause your session
data to be overwritten or stale data to be read by subsequent requests.

This B<CAN CAUSE LARGE PROBLEMS IN YOUR APPLICATION>.

=head1 AUTHOR

This module was written by Tomas Doran <bobtfish@bobtfish.net>.

=head1 SEE ALSO

L<Apache::Session::MySQL>, L<Apache::Session::Flex>,
L<Apache::Session>

=cut


