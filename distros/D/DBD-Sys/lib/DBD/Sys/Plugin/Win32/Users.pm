package DBD::Sys::Plugin::Win32::Users;

use strict;
use warnings;

use vars qw($VERSION @colNames);

use base qw(DBD::Sys::Table);
my $haveWin32pwent = 0;
eval {
    require Win32::pwent;
    $haveWin32pwent = 1;
};

$VERSION  = "0.102";
@colNames = qw(username passwd uid gid quota comment gcos dir shell expire);

=pod

=head1 NAME

DBD::Sys::Plugin::Win32::Users - provides a table containing the operating system users

=head1 SYNOPSIS

  $users = $dbh->selectall_hashref("select * from pwent", "username");

=head1 DESCRIPTION

This module provides the table I<pwent> filled the data from the user
information got from L<Win32::pwent>. Currently this contains only the
users known by the Windows LAN Manager, but hopefully it will be extended
to cover Active Directory users, soon.

=head2 COLUMNS

=head3 username

Name of the user in this row how he/she authenticates himself/herself to
the system.

=head3 passwd

Encrypted password of the user - usually empty for current LANMAN functions.

=head3 uid

Numerical user id

=head3 gid

Numerical group id of the users primary group

=head3 quota

Quota, when supported by this system and set

=head3 comment

Comment, when set

=head3 gcos

General information about the user

=head3 dir

Users home directory

=head3 shell

Users default login shell

=head3 expire

Account expiration time, when available

=head1 METHODS

=head2 get_table_name

Returns 'pwent'.

=cut

sub get_table_name() { return 'pwent'; }

=head2 get_col_names

Returns the column names of the table as named in L</Columns>

=cut

sub get_col_names() { @colNames }

=head2 collect_data

Retrieves the data from the password database and put it into fetchable rows.

=cut

sub collect_data()
{
    my @data;

    if ($haveWin32pwent)
    {
        Win32::pwent::endpwent();    # ensure we're starting fresh ...
        while ( my ( $name, $passwd, $uid, $gid, $quota, $comment, $gcos, $dir, $shell, $expire ) =
                Win32::pwent::getpwent() )
        {
            push( @data,
                  [ $name, $passwd, $uid, $gid, $quota, $comment, $gcos, $dir, $shell, $expire ] );
        }
        Win32::pwent::endpwent();
    }

    return \@data;
}

=head1 PREREQUISITES

The module C<Win32::pwent> is required to provide data for the
table.

=head1 AUTHOR

    Jens Rehsack			Alexander Breibach
    CPAN ID: REHSACK
    rehsack@cpan.org			alexander.breibach@googlemail.com
    http://www.rehsack.de/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SUPPORT

Free support can be requested via regular CPAN bug-tracking system. There is
no guaranteed reaction time or solution time, but it's always tried to give
accept or reject a reported ticket within a week. It depends on business load.
That doesn't mean that ticket via rt aren't handles as soon as possible,
that means that soon depends on how much I have to do.

Business and commercial support should be acquired from the authors via
preferred freelancer agencies.

=cut

1;

