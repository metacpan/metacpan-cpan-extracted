######################################################################
package AnyData::Format::Passwd;
######################################################################
#
# copyright 2000 by Jeff Zucker <jeff@vpservices.com>
# all rights reserved
#
######################################################################

=head1 NAME

Passwd - tied hash and DBI access to passwd files

=head1 SYNOPSIS

 use AnyData;
 my $users = adTie( 'Passwd', '/etc/passwd' );
 print $users->{jdoe}->{homedir};
 # ... other tied hash operations

 OR

 use DBI
 my $dbh = DBI->connect('dbi:AnyData:');
 $dbh->func('users','Passwd','/etc/passwd','ad_catalog');
 my $g7 = $dbh->selectall_arrayref( qq{
     SELECT username, homedir FROM users WHERE GID = '7'
 });
 # ... other DBI/SQL operations

=head1 DESCRIPTION

This module provides a tied hash interface and a DBI/SQL interface to passwd files.  Simply specify the format as 'Passwd' and give the name of the file and the modules will build a hash table with the column names

 username
 passwd
 UID
 GID
 fullname
 homedir
 shell

The username field is treated as a key column.

This module is a submodule of the AnyData.pm and DBD::AnyData.pm modules.  Refer to their documentation for further details.

=head1 AUTHOR & COPYRIGHT

copyright 2000, Jeff Zucker <jeff@vpservices.com>
all rights reserved

=cut

use strict;
use warnings;
use AnyData::Format::CSV;
use vars qw( @ISA $VERSION);
@AnyData::Format::Passwd::ISA = qw( AnyData::Format::CSV );

$VERSION = '0.12';

sub new {
    my $class = shift;
    my $flags = shift || {};
    $flags->{field_sep} = q(:);
    $flags->{col_names} = 'username,passwd,UID,GID,fullname,homedir,shell';
    $flags->{key}       = 'username';
    $flags->{keep_first_line} = 1;
    my $self  = AnyData::Format::CSV::->new(
        $flags
    );
    return bless $self, $class;
}
1;



