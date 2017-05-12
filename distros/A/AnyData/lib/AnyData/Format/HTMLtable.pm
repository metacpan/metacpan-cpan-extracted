######################################################################
package AnyData::Format::HTMLtable;
######################################################################
# by Jeff Zucker <jeff@vpservices.com>
# copyright 2000 all rights reserved
######################################################################

=head1 NAME

HTMLtable - tied hash and DBI/SQL access to HTML tables

=head1 SYNOPSIS

 use AnyData;
 my $table = adHash( 'HTMLtable', $filename );
 while (my $row = each %$table) {
    print $row->{name},"\n" if $row->{country} =~ /us|mx|ca/;
 }
 # ... other tied hash operations

 OR

 use DBI
 my $dbh = DBI->connect('dbi:AnyData:');
 $dbh->func('table1','HTMLtable', $filename,'ad_catalog');
 my $hits = $dbh->selectall_arrayref( qq{
     SELECT name FROM table1 WHERE country = 'us'
 });
 # ... other DBI/SQL operations


=head1 DESCRIPTION

This module allows one to treat the data contained in an HTML table as
a tied hash (using AnyData.pm) or as a DBI/SQL accessible database
(using DBD::AnyData.pm).  Both the tiedhash and DBI interfaces allow
one to read, modify, and create HTML tables from perl data or from local or
remote files.

The module requires that CGI, HTML::Parser and HTML::TableExtract are installed.

When reading the HTML table, this module is essentially just a pass
through to Matt Sisk's excellent HTML::TableExtract module.

If no flags are specified in the adTie() or ad_catalog() calls, then TableExtract is called with depth=0 and count=0, in other words it finds the first row of the first table and treats that as the column names for the entire table.  If a flag for 'cols' (column names) is specified in the adTie() or ad_catalog() calls, that list of column names is passed to TableExtract as a headers parameter.  If the user specifies flags for headers, depth, or count, those are passed directly to TableExtract.

When exporting to an HTMLtable, you may pass flags to specify properties
 of the whole table (table_flags), the top row containing the column names
 (top_row_flags), and the data rows (data_row_flags).  These flags follow
 the syntax of CGI.pm table constructors, e.g.:

 print adExport( $table, 'HTMLtable', {
     table_flags    => {Border=>3,bgColor=>'blue'};
     top_row_flags  => {bgColor=>'red'};
     data_row_flags => {valign='top'};
 });

 The table_flags will default to {Border=>1,bgColor=>'white'} if none
 are specified.

 The top_row_flags will default to {bgColor=>'#c0c0c0'} if none are 
 specified;

 The data_row_flags will be empty if none are specified.

 In other words, if no flags are specified the table will print out with
 a border of 1, the column headings in gray, and the data rows in white.

 CAUTION: This module will *not* preserve anything in the html file except
 the selected table so if your file contains more than the selected table,
 you will want to use adTie() or $dbh->func(...,'ad_import') to read the 
table and then adExport() or $dbh->func(...,'ad_export') to write
 the table to a different file.  When using the HTMLtable format, this is the
 only way to preserve changes to the data, the adTie() command will *not*
 write to a file.

=head1 AUTHOR & COPYRIGHT

copyright 2000, Jeff Zucker <jeff@vpservices.com>
all rights reserved

=cut

use strict;
use warnings;
use AnyData::Format::Base;
use AnyData::Storage::File;
use vars qw( @ISA $VERSION);
@AnyData::Format::HTMLtable::ISA = qw( AnyData::Format::Base );

$VERSION = '0.12';

sub new {
    my $class = shift;
    my $self  = shift ||  {};
    $self->{export_on_close} = 1;
    $self->{slurp_mode} = 1;
    return bless $self, $class;
}

sub storage_type { 'RAM'; }

sub import {
    my $self = shift;
    my $data = shift;
    my $storage = shift;
    return $self->get_data($data,$self->{col_names});
}
sub get_data {
    my $self = shift;
    my $str       = shift or return undef;
    my $col_names = shift;
    require HTML::TableExtract;
    my $count   = $self->{count} || 0;
    my $depth   = $self->{depth} || 0;
    my $headers = $self->{headers} || $self->{col_names} || undef;
    my %flags;
    if (defined $count or defined $depth or defined $headers) {
        $flags{count} = $count if defined $count;
        $flags{depth} = $depth if defined $depth;
        $flags{headers} = $headers if defined $headers;
    }
    else {
        %flags = $col_names
            ? ( headers => $col_names )
            : (count=>$count,depth=>$depth);
    }
    my $te = new HTML::TableExtract(
         %flags
    );
    $te->parse($str);
    my $table;
    @$table = $te->rows;
    $self->{col_names} = shift @$table if !$col_names;
    return $table, $self->{col_names};
}

sub export {
    #print "EXPORTING!";
    my $self      = shift;
    my $storage   = shift;
    my $col_names = $storage->{col_names};
    my $table     = $storage->{records};
    #use Data::Dumper; print Dumper $table; print "###"; exit;
    my $fh        = $storage->{fh};
    use CGI;
    my $table_flags = shift || {Border=>1,bgColor=>'white'};
    my $top_row_flags = shift || {bgColor=>'#c0c0c0'};
    my $data_row_flags = shift || {};
    @$table = map {
        my $row = $_;
        @$row = map { $_ || '&nbsp;' } @$row;
        $row;
    } @$table;
    my $str = 
        CGI::table(
            $table_flags,
            CGI::Tr( $top_row_flags, CGI::th($col_names) ),
            map CGI::Tr( $data_row_flags, CGI::td($_) ), @$table
        );
    $fh->write($str,length $str) if $fh;
    return $str;
}

sub exportOLD {
    my $self      = shift;
    my $table     = shift;
    my $col_names = shift;
    use CGI;
    my $table_flags = shift || {Border=>1,bgColor=>'white'};
    my $top_row_flags = shift || {bgColor=>'#c0c0c0'};
    my $data_row_flags = shift || {};
    return
        CGI::table(
            $table_flags,
            CGI::Tr( $top_row_flags, CGI::th($col_names) ),
            map CGI::Tr( $data_row_flags, CGI::td($_) ), @$table
        );
}
1;








