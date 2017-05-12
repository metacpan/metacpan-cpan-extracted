#########################################################
package AnyData::Format::Ini;
#########################################################
# copyright (c) 2000, Jeff Zucker <jeff@vpservices.com>
# all rights reserved
#########################################################

=head1 NAME

 AnyData::Format::Ini - tiedhash & DBI/SQL access to ini files

=head1 SYNOPSIS

 use AnyData;
 my $table = adHash( 'Ini', $filename,'r',$flags );
 while (my $row = each %$table) {
     print $row->{name},"\n" if $row->{country} =~ /us|mx|ca/;
 }
 # ... other tied hash operations

 OR

 use DBI
 my $dbh = DBI->connect('dbi:AnyData:');
 $dbh->func('table1','Init', $filename,$flags,'ad_catalog');
 my $hits = $dbh->selectall_arrayref( qq{
     SELECT name FROM table1 WHERE country = 'us'
 });
 # ... other DBI/SQL operations

=head1 DESCRIPTION

This is a parser for simple name=value style Ini files.  Soon it will also handle files with sections.

Please refer to the documentation for AnyData.pm and DBD::AnyData.pm
for further details.

=head1 AUTHOR & COPYRIGHT

copyright 2000, Jeff Zucker <jeff@vpservices.com>
all rights reserved

=cut

use AnyData::Format::CSV;
use strict;
use warnings;
use vars qw/@ISA $VERSION/;
@ISA = qw(AnyData::Format::CSV);

$VERSION = '0.12';


sub new {
    my $class = shift;
    my $flags = shift || {};
    $flags->{field_sep} ||= '=';
    my $self  = AnyData::Format::CSV::->new( $flags );
    return bless $self, $class;
}

sub write_fields  {
    my($self,$key,$value) = @_;
    return undef unless $key;
    $value ||= '';
    return "$key = $value" . $self->{record_sep};
}

sub read_fields {
    my $self = shift;
    my $str  = shift || return undef;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    return undef unless $str;
    my @fields = $str =~ /^([^=]*?)\s*=\s*(.*)/;
    die "Couldn't parse line '$str'\n" unless defined $fields[0];
    return( @fields );
}


