#########################################################
package AnyData::Format::Tab;
#########################################################
# copyright (c) 2000, Jeff Zucker <jeff@vpservices.com>
# all rights reserved
#########################################################

=head1 NAME

AnyData::Format::Tab - tiedhash & DBI/SQL access to Tab delimited files

=head1 SYNOPSIS

 use AnyData;
 my $table = adHash( 'Tab', $filename,'r',$flags );
 while (my $row = each %$table) {
     print $row->{name},"\n" if $row->{country} =~ /us|mx|ca/;
 }
 # ... other tied hash operations

 OR

 use DBI
 my $dbh = DBI->connect('dbi:AnyData:');
 $dbh->func('table1','Tab', $filename,$flags,'ad_catalog');
 my $hits = $dbh->selectall_arrayref( qq{
     SELECT name FROM table1 WHERE country = 'us'
 });
 # ... other DBI/SQL operations

=head1 DESCRIPTION

This is a plug-in format parser for the AnyData and DBD::AnyData modules. It will read column names from the first row of the file, or accept names passed by the user.  In addition to column names, the user may set other options as follows:

  col_names   : a tab separated list of column names
  eol         : the end of record mark, \n by default
  quote_char  : the character used to quote fields " by default
  escape_char : the character used to escape the quote char, " by default

If you are using this with DBD::AnyData, put ad_ in front of the flags, e.g.
ad_eol.

Please refer to the documentation for AnyData.pm and DBD::AnyData.pm
for further details.

=head1 AUTHOR & COPYRIGHT

copyright 2000, Jeff Zucker <jeff@vpservices.com>
all rights reserved

=cut

use strict;
use warnings;
use AnyData::Format::CSV;
use vars qw( @ISA $VERSION );
@AnyData::Format::Tab::ISA = qw( AnyData::Format::CSV );

$VERSION = '0.12';

sub new {
    my $class = shift;
    my $flags = shift || {};
    $flags->{field_sep} ||= qq(\t);
    my $self  = AnyData::Format::CSV::->new(
        $flags
    );
    return bless $self, $class;
}
1;
