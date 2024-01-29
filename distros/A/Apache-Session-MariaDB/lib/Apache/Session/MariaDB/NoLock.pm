package Apache::Session::MariaDB::NoLock;

use strict;
use warnings;

use base 'Apache::Session';

use Apache::Session;
use Apache::Session::Lock::Null;
use Apache::Session::Store::MariaDB;
use Apache::Session::Generate::MD5;
use Apache::Session::Serialize::Storable;

sub populate {
    my $self = shift;

    $self->{object_store} = Apache::Session::Store::MariaDB->new($self);
    $self->{lock_manager} = Apache::Session::Lock::Null->new($self);
    $self->{generate}     = \&Apache::Session::Generate::MD5::generate;
    $self->{validate}     = \&Apache::Session::Generate::MD5::validate;
    $self->{serialize}    = \&Apache::Session::Serialize::Storable::serialize;
    $self->{unserialize}  = \&Apache::Session::Serialize::Storable::unserialize;

    return $self;
}

1;

=pod

=head1 NAME

Apache::Session::MariaDB::NoLock - An implementation of Apache::Session::MariaDB without locking

=head1 SYNOPSIS

 use Apache::Session::MariaDB::NoLock;

 #if you want Apache::Session to open new DB handles:

 tie %hash, 'Apache::Session::MariaDB::NoLock', $id, {
    DataSource => 'dbi:MariaDB:sessions',
    UserName => $db_user,
    Password => $db_pass,
 };

 #or, if your handles are already opened:

 tie %hash, 'Apache::Session::MariaDB::NoLock', $id, {
    Handle => $dbh,
 };

 To configure the non-locking session store in RT (what I use this module for),
 put the following into your C<RT_SiteConfig.pm> module:

    Set($WebSessionClass , 'Apache::Session::MariaDB::NoLock');

=head1 DESCRIPTION

This module is an implementation of Apache::Session. It uses the MariaDB backing
store and the Null locking scheme. See the example, and the documentation for
Apache::Session::Store::MariaDB for more details.

=head1 WARNING

This module explicitly B<DOES NOT DO ANY LOCKING>. This can cause your session
data to be overwritten or stale data to be read by subsequent requests.

This B<CAN CAUSE LARGE PROBLEMS IN YOUR APPLICATION>.

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

Tomas Doran E<lt>bobtfish@bobtfish.net<gt>

=head1 SEE ALSO

L<Apache::Session::MariaDB>, L<Apache::Session::Flex>,
L<Apache::Session>

=cut
