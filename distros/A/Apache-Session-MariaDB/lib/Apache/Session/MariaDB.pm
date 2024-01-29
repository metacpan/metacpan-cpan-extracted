package Apache::Session::MariaDB;

use strict;
use warnings;

use base 'Apache::Session';

our $VERSION = '0.01';

use Apache::Session;
use Apache::Session::Lock::MariaDB;
use Apache::Session::Store::MariaDB;
use Apache::Session::Generate::MD5;
use Apache::Session::Serialize::Storable;

sub populate {
    my $self = shift;

    $self->{object_store} = new Apache::Session::Store::MariaDB $self;
    $self->{lock_manager} = new Apache::Session::Lock::MariaDB $self;
    $self->{generate}     = \&Apache::Session::Generate::MD5::generate;
    $self->{validate}     = \&Apache::Session::Generate::MD5::validate;
    $self->{serialize}    = \&Apache::Session::Serialize::Storable::serialize;
    $self->{unserialize}  = \&Apache::Session::Serialize::Storable::unserialize;

    return $self;
}

1;


=pod

=head1 NAME

Apache::Session::MariaDB - An implementation of Apache::Session using MariaDB

=head1 SYNOPSIS

 use Apache::Session::MariaDB;

 #if you want Apache::Session to open new DB handles:

 tie %hash, 'Apache::Session::MariaDB', $id, {
    DataSource => 'dbi:MariaDB:sessions',
    UserName   => $db_user,
    Password   => $db_pass,
    LockDataSource => 'dbi:MariaDB:sessions',
    LockUserName   => $db_user,
    LockPassword   => $db_pass
 };

 #or, if your handles are already opened:

 tie %hash, 'Apache::Session::MariaDB', $id, {
    Handle     => $dbh,
    LockHandle => $dbh
 };

=head1 DESCRIPTION

This module is an implementation of Apache::Session. It uses the
MariaDB backing store and the MariaDB locking scheme. See the example,
and the documentation for Apache::Session::Store::MariaDB and
Apache::Session::Lock::MariaDB for more details.

It's based on L<Apache::Session::MySQL> but uses L<DBD::MariaDB> instead
of L<DBD::mysql>. The initial reason to create this new module is that
L<DBD::MariaDB> requires to explicitly indicate C<a_session> column as
binary in L<DBI>'s bind_param calls, which is different from L<DBD::mysql>
and thus L<Apache::Session::MySQL> doesn't support it.

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

Jeffrey William Baker E<lt>jwbaker@acm.orgE<gt>

Tomas Doran E<lt>bobtfish@bobtfish.net<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2024, Best Practical Solutions LLC.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Apache::Session::MySQL>, L<Apache::Session::File>, L<Apache::Session::Flex>,
L<Apache::Session::DB_File>, L<Apache::Session::Postgres>, L<Apache::Session>
