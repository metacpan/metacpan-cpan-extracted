#############################################################################
#
# Apache::Session::Browseable::SQLite
# Apache persistent user sessions in a SQLite database
# Copyright(c) 2013-2017 Xavier Guimard <x.guimard@free.fr>
# Inspired by Apache::Session::Postgres
# (copyright(c) 1998, 1999, 2000 Jeffrey William Baker (jwbaker@acm.org))
# Distribute under the Perl License
#
############################################################################

package Apache::Session::Browseable::SQLite;

use strict;

use Apache::Session;
use Apache::Session::Lock::Null;
use Apache::Session::Browseable::Store::SQLite;
use Apache::Session::Generate::SHA256;
use Apache::Session::Serialize::JSON;
use Apache::Session::Browseable::DBI;

our $VERSION = '1.2.2';
our @ISA     = qw(Apache::Session::Browseable::DBI Apache::Session);

sub populate {
    my $self = shift;

    $self->{object_store} =
      new Apache::Session::Browseable::Store::SQLite $self;
    $self->{lock_manager} = new Apache::Session::Lock::Null $self;
    $self->{generate}     = \&Apache::Session::Generate::SHA256::generate;
    $self->{validate}     = \&Apache::Session::Generate::SHA256::validate;
    $self->{serialize}    = \&Apache::Session::Serialize::JSON::serialize;
    $self->{unserialize}  = \&Apache::Session::Serialize::JSON::unserialize;

    return $self;
}

1;

=pod

=head1 NAME

Apache::Session::Browseable::SQLite - An implementation of Apache::Session

=head1 SYNOPSIS

 use Apache::Session::Browseable::SQLite;

 #if you want Apache::Session to open new DB handles:

 tie %hash, 'Apache::Session::Browseable::SQLite', $id, {
    DataSource => 'dbi:Pg:dbname=sessions',
    UserName   => $db_user,
    Password   => $db_pass,
    Commit     => 1
 };

 #or, if your handles are already opened:

 tie %hash, 'Apache::Session::Browseable::SQLite', $id, {
    Handle => $dbh,
    Commit => 1
 };

L<Apache::Session::Browseable> function are also available

=head1 DESCRIPTION

This module is an implementation of Apache::Session.  It uses the SQLite
backing store and no locking.  See the example, and the documentation for
Apache::Session::Browseable::Store::SQLite for more details.

=head1 USAGE

The special Apache::Session argument for this module is Commit.  You MUST
provide the Commit argument, which instructs this module to either commit
the transaction when it is finished, or to simply do nothing.  This feature
is provided so that this module will not have adverse interactions with your
local transaction policy, nor your local database handle caching policy.  The
argument is mandatory in order to make you think about this problem.

=head1 AUTHOR

This module was written by Xavier Guimard <x.guimard@free.fr> using
Apache::Session::Postgres from Jeffrey William Baker as example.

=head1 SEE ALSO

L<Apache::Session::Browseable>
