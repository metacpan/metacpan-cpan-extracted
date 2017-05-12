#########################################################
package AnyData::Format::Fixed;
#########################################################
# copyright (c) 2000, Jeff Zucker <jeff@vpservices.com>
#########################################################

=head1 NAME

 AnyData::Format::Fixed - tiedhash & DBI/SQL access to Fixed length data

=head1 SYNOPSIS

 use AnyData;
 my $table = adHash( 'Fixed', $filename,'r',{pattern=>'A20 A2'} );
 while (my $row = each %$table) {
     print $row->{name},"\n" if $row->{country} =~ /us|mx|ca/;
 }
 # ... other tied hash operations

 OR

 use DBI
 my $dbh = DBI->connect('dbi:AnyData:');
 $dbh->func('table1','Fixed', $filename, {pattern=>'A20 A2'},'ad_catalog');
 my $hits = $dbh->selectall_arrayref( qq{
     SELECT name FROM table1 WHERE country = 'us'
 });
 # ... other DBI/SQL operations

=head1 DESCRIPTION

This is a parser for fixed length record files.  You must specify an unpack pattern listing the widths of the fields e.g. {pattern=>'A3 A7 A20'}.  You can either supply the column names or let the module get them for you from the first line of the file.  In either case, they should be a comma separated string.

Refer to L<http://perldoc.perl.org/functions/pack.html> for the formatting of the pattern.

Please refer to the documentation for AnyData.pm and DBD::AnyData.pm
for further details.

=head1 AUTHOR & COPYRIGHT

copyright 2000, Jeff Zucker <jeff@vpservices.com>
all rights reserved

=cut

use strict;
use warnings;
use AnyData::Format::Base;
use vars qw( @ISA $VERSION);
@AnyData::Format::Fixed::ISA = qw( AnyData::Format::Base );

$VERSION = '0.12';

sub read_fields {
    my $self = shift;
    my $str  = shift;
    if (!$self->{pattern}) {
      print "NO UNPACK PATTERN SPECIFIED!"; exit;
    } 
    my @fields = unpack $self->{pattern}, $str;
    if ($self->{trim}) {
        @fields = map {s/^\s+//; s/\s+$//; $_} @fields;
    }
    return @fields;
}

sub write_fields {
    my $self   = shift;
    my @fields = @_;
    my $fieldNum =0;
    my $patternStr = $self->{pattern} || '';
    $patternStr =~ s/[a-zA-Z]//gi;
    my @fieldLengths = split /\s+/, $patternStr;
    my $fieldStr = '';
    for(@fields) {
        next unless defined $_;
        # PAD OR TRUNCATE DATA TO FIT WITHIN FIELD LENGTHS
        my $oldLen = length $_ || 0;
        my $newLen =  $fieldLengths[$fieldNum] || 0;
        if ($oldLen < $newLen) { $_ = sprintf "%-${newLen}s",$_; }
        if ($oldLen > $newLen) { $_ = substr $_, 0, $newLen; }
        $fieldNum++;
        $fieldStr .= $_;
    }
    $fieldStr .= $self->{record_sep};
#print "<$fieldStr>";
    return $fieldStr;
}
1;





