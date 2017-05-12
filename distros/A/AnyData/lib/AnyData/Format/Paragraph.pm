#########################################################
package AnyData::Format::Paragraph;
#########################################################
# copyright (c) 2000, Jeff Zucker <jeff@vpservices.com>
#########################################################

=head1 NAME

AnyData::Format::Paragraph - tiedhash & DBI/SQL access to vertical files

=head1 SYNOPSIS

 use AnyData;
 my $table = adHash( 'Paragraph', $filename,'r',$flags );
 while (my $row = each %$table) {
    print $row->{name},"\n" if $row->{country} =~ /us|mx|ca/;
 }
 # ... other tied hash operations

 OR

 use DBI
 my $dbh = DBI->connect('dbi:AnyData:');
 $dbh->func('table1','Paragraph', $filename,$flags,'ad_catalog');
 my $hits = $dbh->selectall_arrayref( qq{
     SELECT name FROM table1 WHERE country = 'us'
 });
 # ... other DBI/SQL operations

=head1 DESCRIPTION

This is a plug-in format parser for the AnyData and DBD::AnyData modules.

It handles "vertical" files in which the record name occurs on a line by itself followed by records on lines by themselves, e.g.

 Photoslop
 /My Photos/
 .jpg, .gif, .psd

 Nutscrape
 /htdocs/
 .html, .htm

Please refer to the documentation for AnyData.pm and DBD::AnyData.pm
for further details.

=head1 AUTHOR & COPYRIGHT

copyright 2000, Jeff Zucker <jeff@vpservices.com>
all rights reserved

=cut

use strict;
use warnings;

use AnyData;
use AnyData::Format::CSV;
use vars qw/@ISA $VERSION/;
@ISA = qw(AnyData::Format::CSV);

$VERSION = '0.12';

sub new {
    my $class = shift;
    my $flags = shift || {};
    my $f = $flags->{record_sep} || '';
    #print "<$f>";
    $flags->{field_sep}  = "\n";
    $flags->{record_sep} = "\n\n";
    #print "[",$flags->{record_sep},"]";
    my $self  = AnyData::Format::CSV::->new( $flags );
    return bless $self, $class;
}

sub write_fields  {
    my($self,@fields) = @_;
    @fields = map {$_ || ''} @fields;
    return join("\n",@fields) . $self->{record_sep};
}

sub read_fields {
    my $self = shift;
    my $str  = shift || return undef;
    return undef unless $str;
    my @fields = split /\n/, $str;
    @fields = map{s/\s+$//; $_}@fields;
    die "Couldn't parse line '$str'\n" unless defined $fields[0];
    return( @fields );
}



