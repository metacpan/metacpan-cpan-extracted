#########################################################################
#   DBD::AnyData - a DBI driver for files and data structures
#
#   This module is copyright (c), 2001 by Jeff Zucker
#   All rights reserved.
#
#   This is free software.  You may distribute it under
#   the same terms as Perl itself as specified in the
#   Perl README file.
#
#   WARNING: no warranty of any kind is implied.
#
#   To learn more: enter "perldoc DBD::AnyData" at the command prompt,
#   or search in this file for =head1 and read the text below it
#
#########################################################################

package DBD::AnyData;

use strict;
use warnings;

use AnyData;
require DBI::DBD::SqlEngine;
use base qw(DBI::DBD::SqlEngine);
require SQL::Statement;
require SQL::Eval;

use vars qw($VERSION $err $errstr $sqlstate $drh $methods_already_installed);

$VERSION = '0.110';

$err      = 0;        # holds error code   for DBI::err
$errstr   = "";       # holds error string for DBI::errstr
$sqlstate = "";       # holds SQL state for    DBI::state
$drh      = undef;    # holds driver handle once initialized

sub driver
{
    my ( $class, $attr ) = @_;
    return $drh if $drh;    # already created - return same one
    $drh = $class->SUPER::driver(
                                  {
                                    'Name'        => 'AnyData',
                                    'Version'     => $VERSION,
                                    'Err'         => \$DBD::AnyData::err,
                                    'Errstr'      => \$DBD::AnyData::errstr,
                                    'State'       => \$DBD::AnyData::sqlstate,
                                    'Attribution' => 'DBD::AnyData by Jens Rehsack',
                                  }
                                );

    unless ( $methods_already_installed++ )
    {
        DBD::AnyData::db->install_method('ad_import');
        DBD::AnyData::db->install_method('ad_catalog');
        DBD::AnyData::db->install_method('ad_convert');
        DBD::AnyData::db->install_method('ad_export');
        DBD::AnyData::db->install_method('ad_clear');
        DBD::AnyData::db->install_method('ad_dump');
    }

    return $drh;
}

sub CLONE
{
    undef $drh;
}

package DBD::AnyData::dr;    # ====== DRIVER ======

use strict;
use warnings;

use vars qw($imp_data_size);

$DBD::AnyData::dr::imp_data_size = 0;
@DBD::AnyData::dr::ISA           = qw(DBI::DBD::SqlEngine::dr);

sub disconnect_all
{
    shift->{ad_tables} = {};
}

sub DESTROY
{
    shift->{ad_tables} = {};
}

package DBD::AnyData::db;    # ====== DATABASE ======

use strict;
use warnings;

use vars qw($imp_data_size);

require Cwd;
require File::Spec;

$DBD::AnyData::db::imp_data_size = 0;
@DBD::AnyData::db::ISA           = qw(DBI::DBD::SqlEngine::db);

sub init_default_attributes
{
    my $dbh = shift;

    # must be done first, because setting flags implicitly calls $dbdname::db->STORE
    $dbh->SUPER::init_default_attributes();

    $dbh->{f_dir} = Cwd::abs_path( File::Spec->curdir() );

    return $dbh;
}

sub set_versions
{
    my $this = $_[0];
    $this->{ad_version} = $DBD::AnyData::VERSION;
    return $this->SUPER::set_versions();
}

sub disconnect
{
    my $dbh = $_[0];
    $dbh->SUPER::disconnect();
    $dbh->{ad_tables} = {};
    $dbh->STORE( 'Active', 0 );
    return 1;
}

sub validate_STORE_attr
{
    my ( $dbh, $attrib, $value ) = @_;

    if ( $attrib eq "f_dir" )
    {
        -d $value
          or return $dbh->set_err( $DBI::stderr, "No such directory '$value'" );
        File::Spec->file_name_is_absolute($value)
          or $value = Cwd::abs_path($value);
    }

    return $dbh->SUPER::validate_STORE_attr( $attrib, $value );
}

sub get_ad_versions
{
    my ( $dbh, $table ) = @_;

    my $dver;
    my $eval_str;
    $eval_str = sprintf( '$dver = $%s::VERSION', "AnyData" );
    eval $eval_str;
    my $dtype = "AnyData";
    $dtype .= ' (' . $dver . ')' if $dver;

    return sprintf( "%s using %s", $dbh->{ad_version}, $dtype );
}
#
# DRIVER PRIVATE METHODS
#

sub ad_mod_catalog
{
    my ( $self, $tname, $key, $value ) = @_;
    $self->{ad_tables}->{$tname}->{$key} = $value;
}

sub ad_clear
{
    my $self  = shift;
    my $tname = shift;
    if ( $tname eq 'all' or $tname eq '' )
    {
        $self->{ad_tables} = {};
    }
    else
    {
        delete $self->{ad_tables}->{$tname};
    }
}

sub ad_get_catalog
{
    my $self  = shift;
    my $tname = shift;
    #################################################################
    # Patch from Wes Hardaker
    #################################################################
    if ($tname)
    {
        return $self->{ad_tables}->{$tname}
          if ( $self->{ad_tables}->{$tname} );
        return $self->{ad_tables}->{__default};
    }
    #################################################################
    return $self->{ad_tables};
}

sub ad_export
{
    my $dbh        = shift;
    my $table_name = shift;
    my $format     = shift;
    my $file_name  = shift;
    my $flags      = shift;
    my $data;
    my $catalog = $dbh->func( $table_name, 'ad_get_catalog' );
    #use Data::Dumper; print Dumper $catalog;
    if ( $catalog->{format} && 'XML HTMLtable' =~ /$catalog->{format}/ )
    {
        #use Data::Dumper; print "!",Dumper $catalog; exit;
        my $sth = $dbh->prepare("SELECT 1 FROM $table_name") or die DBI->errstr;
        $sth->execute;    #  or die DBI->errstr;
###z       return $catalog->{ad}->export($format,$file_name,$flags) if 'XML HTMLtable' =~ /$format/;
        return $catalog->{ad}->export( $file_name, $flags ) if 'XML HTMLtable' =~ /$format/;
        $data = $dbh->selectall_arrayref("SELECT * FROM $table_name");
        #my $sth = $dbh->prepare("SELECT * FROM $table_name");
        #$sth->execute;
        #unshift @$data, $sth->{NAME};
    }
    else
    {
        #z      $data = $dbh->func($table_name,'ad_get_catalog')->{records};
        my $sth = $dbh->prepare("SELECT * FROM $table_name WHERE 1=0");
        $sth->execute;
        $data = $catalog->{ad}->{storage}->{records};
    }
    $data = $dbh->selectall_arrayref("SELECT * FROM $table_name")
      if $format =~ /XML|HTMLtable/;
    #use Data::Dumper;
    #die Dumper $data;
    # print Dumper $dbh->func( $table_name,'ad_get_catalog');

    my $newcols = $dbh->func( $table_name, 'ad_get_catalog' )->{ad}->{storage}->{col_names};
    unshift @$data, $newcols if $newcols;
    return AnyData::adConvert( 'Base', $data, $format, $file_name, undef, $flags );
    #    return AnyData::adExport({},$format,$data,$file_name,undef,$flags);
}

sub ad_convert
{
    my $dbh    = shift;
    my $format = shift;
    if ( $format eq 'DBI' )
    {
        my $data      = shift;
        my $newformat = shift;
        die "table_name required to convert DBI"
          unless $_[1] and $_[1]->{table_name};
        my $table_name = $_[1]->{table_name};
        $dbh->func( $table_name, 'DBI', $data, 'ad_import' );
        my $rv = $dbh->func( $table_name, $newformat, 'ad_export' );
        $dbh->func( $table_name, 'ad_clear' );
        return $rv;
    }
    return AnyData::adConvert( $format, @_ );
}

sub ad_import
{
    my $dbh = shift;
    my ( $table_name, $format, $file_name, $flags ) = @_;
    $format = 'CSV' if $format eq 'ARRAY';
    my $old_catalog = $dbh->func( $table_name, 'ad_get_catalog' );
    my $old_columns;
    my $old_records;
    if ($old_catalog)
    {
        my $sth = $dbh->prepare("SELECT * FROM $table_name");
        $sth->execute;
        $old_records = $sth->fetchall_arrayref;
        $old_columns = $sth->{NAME};
    }
    my $sql = $flags->{sql} || "SELECT * FROM $table_name";
    #    die $sql;
    my @params = $flags->{params} || ();
    if ( 'XML HTMLtable' =~ /$format/ )
    {
        $dbh->func( $table_name, $format, $file_name, $flags, 'ad_catalog' );
        my $sth = $dbh->prepare("SELECT * FROM $table_name WHERE 1=0");
        $sth->execute;
        $sth->finish;
        return unless $old_catalog;
    }
    elsif ( ref($file_name) )
    {
        $flags->{recs}    = $file_name;
        $flags->{storage} = 'RAM';
        #$flags->{col_names} =$old_columns if $old_columns;
        $dbh->func( $table_name, $format, '', $flags, 'ad_catalog' );
    }
    else
    {
        $dbh->func( $table_name, $format, $file_name, $flags, 'ad_catalog' );
        #$dbh->func(@_,'ad_catalog');
    }
    my $dbh2 = $dbh;
    $dbh2 = $file_name if $format eq 'DBI';
    my $sth = $dbh2->prepare($sql) or die DBI->errstr;
    #    die "$sql";
    $sth->execute(@params) or die DBI->errstr;
    my $cols = $sth->{NAME} or die DBI->errstr;
    #    die @$cols;
    my $records;
    if ($old_records)
    {
        my $colstr = join ',',      @$old_columns;
        my $cr     = join " TEXT,", @$old_columns;
        $cr = "CREATE TABLE temp__ ($cr TEXT)";
        $dbh->do($cr) or die DBI->errstr;
        while ( my $row = $sth->fetchrow_hashref )
        {
            my $old_row;
            if ( $flags->{lookup_key} )
            {
                my $lookup = $flags->{lookup_key} || $sth->{NAME}->[0];
                my $val    = $row->{$lookup}      || next;
                my $oldsth = $dbh->prepare(
                    qq{
                     SELECT * FROM temp__ WHERE $lookup = '$val'
                 }
                                          );
                $oldsth->execute;
                $old_row = $oldsth->fetchrow_hashref;
                my @tmp = $dbh->selectrow_array("SELECT * FROM temp__ WHERE $lookup = $val");
                my $dup;

                for my $x (@tmp)
                {
                    if ( !defined $x )
                    {
                        $dup++;
                        last;
                    }
                }
                if ($dup)
                {
                    #print "@tmp";
                    $dbh->do("DELETE FROM temp__ WHERE $lookup = $val")
                      or die DBI->errstr;
                }
            }
            my @params;
            for (@$old_columns)
            {
                my $newval = $row->{$_};
                $newval ||= $old_row->{$_};
                push @params, $newval;
            }
            my $paramStr = ( join ",", ("?") x @$old_columns );
            my $ins_sql = "INSERT INTO temp__ ($colstr) VALUES ($paramStr)";
            $dbh->do( $ins_sql, undef, @params ) or die DBI->errstr;
        }
        $records ||= $dbh->selectall_arrayref($sql);
    }
    else
    {
        $records = $sth->fetchall_arrayref;
    }
    $cols = $old_columns if $old_columns;
    unshift @$records, $cols unless $flags->{col_names};
    $dbh2->disconnect if $format eq 'DBI' and !$flags->{keep_connection};
    $file_name = '' if ref($file_name) eq 'ARRAY';
    delete $flags->{recs};
    delete $flags->{storage};
    delete $flags->{format};
    #$flags = {} if 'XML HTMLtable' =~ /$format/;
    if ( 'XML HTMLtable' =~ /$format/ )
    {
        delete $flags->{ad};
        $flags->{file_name} = '';
    }
    # use Data::Dumper; print Dumper $flags;
    $flags->{records} ||= $records;
    $dbh->func( $table_name, 'ad_clear' );
    $dbh->func( $table_name, 'Base', $file_name, $flags, 'ad_catalog' );
    my $firstrow = {};
    return unless $records->[1];
    @{$firstrow}{@$cols} = @{ $records->[1] };
    return $firstrow;
}

sub ad_catalog
{
    my $dbh   = shift;
    my @specs = @_;
    my $table_info =
      ( ref $specs[0] ) eq 'ARRAY'
      ? shift @specs
      : [ \@specs ];
    for my $one_table ( @{$table_info} )
    {
        my ( $table_name, $format, $file_name, $flags );
        if ( ref $one_table eq 'ARRAY' )
        {
            ( $table_name, $format, $file_name, $flags ) = @{$one_table};
            $flags = {} unless $flags;
            $flags->{table_name} = $table_name;
            if ( ref $format eq 'HASH' )
            {
                $flags->{data} = $format->{data};
                $format = 'Base';
            }
            $flags->{format}    = $format;
            $flags->{file_name} = $file_name;
        }
        if ( ref $one_table eq 'HASH' )
        {
            $flags = $one_table;
        }
        die "ERROR: ad_catalog requires a table name!"
          unless $flags->{table_name};
        $table_name = $flags->{table_name};
        $flags->{format}    ||= 'Base';
        $flags->{file_name} ||= '';
        $flags->{eol}       ||= "\n";
        $flags->{f_dir}     ||= $dbh->{f_dir};
        $dbh->{ad_tables}->{$table_name} = $flags;
    }
}

sub ad_dump
{
    my $dbh = shift;
    my $sql = shift;
    if ( !$sql )
    {
        require Data::Dumper;
        $Data::Dumper::Indent = 1;
        return Data::Dumper::Dumper $dbh->func('ad_get_catalog');
    }
    my $txt;
    my $sth = $dbh->prepare($sql) or die $dbh->errstr;
    $sth->execute or die $sth->errstr;
    my @col_names = @{ $sth->{NAME} };
    $txt .= "<$_> " for @col_names;
    $txt .= "\n";
    while ( my @row = $sth->fetchrow_array )
    {
        for (@row)
        {
            $_ ||= '';
            s/^\s*//;
            s/\s*$//;
            $txt .= "[$_] ";
        }
        $txt .= "\n";
    }
    return $txt;
}

# END OF DRIVER PRIVATE METHODS

sub get_avail_tables
{
    my $dbh = $_[0];

    my @tables = $dbh->SUPER::get_avail_tables();

    my $catalog = $dbh->func( '', 'ad_get_catalog' );
    if ($catalog)
    {
        for ( keys %{$catalog} )
        {
            push( @tables, [ undef, undef, $_, "TABLE", "AnyData" ] );
        }
    }

    return @tables;
}

sub DESTROY
{
    my $dbh = shift;
    $dbh->{ad_tables} = {};
    $dbh->STORE( 'Active', 0 );
}

package DBD::AnyData::st;    # ====== STATEMENT ======

use strict;
use warnings;

use vars qw($imp_data_size);

$DBD::AnyData::st::imp_data_size = 0;
@DBD::AnyData::st::ISA           = qw(DBI::DBD::SqlEngine::st);

# sub DESTROY ($) { undef; }

# sub finish ($) {}

package DBD::AnyData::Statement;

use strict;
use warnings;

@DBD::AnyData::Statement::ISA = qw(DBI::DBD::SqlEngine::Statement);

sub open_table ($$$$$)
{
    my ( $self, $data, $tname, $createMode, $lockMode ) = @_;
    my $dbh = $data->{Database};
    my $catalog = $dbh->func( $tname, 'ad_get_catalog' );
    if ( !$catalog )
    {
        $dbh->func( [ [ $tname, 'Base', '' ] ], 'ad_catalog' );
        $catalog    = $dbh->func( $tname, 'ad_get_catalog' );
        $createMode = 'o';
        $lockMode   = undef;
    }
    my $format = $catalog->{format};
    my $file   = $catalog->{file_name};
    my $ad     = $catalog->{ad}
      #################################################################
      # Patch from Wes Hardaker
      #################################################################
      #    || AnyData::adTable( $format, $file, $createMode, $lockMode,
      #                         $catalog );
      || AnyData::adTable( $format, $file, $createMode, $lockMode, $catalog, $tname );
    #print join("\n", $format,@$file,$createMode), "\n";
    #use Data::Dumper; print Dumper $catalog;
    #################################################################
    my $table = $ad->prep_dbd_table( $tname, $createMode );
    my $cols = $table->{col_names};
    if ( $cols and ref $cols ne 'ARRAY' )
    {
        #$dbh->DBI::set_err(99, "\n  $cols\n ");
        print "\n  $cols\n ";
        exit;
    }
    if (    'Base XML HTMLtable' =~ /$catalog->{format}/
         or $file =~ /http:|ftp:/
         or ref($file) eq 'ARRAY' )
    {
        $ad->seek_first_record();
        $dbh->func( $tname, 'ad', $ad, 'ad_mod_catalog' );
    }

    return DBD::AnyData::Table->new($table);
}

package DBD::AnyData::Table;

use strict;
use warnings;

use Params::Util qw(_HASH0);

@DBD::AnyData::Table::ISA = qw(DBI::DBD::SqlEngine::Table);

sub new
{
    my ( $proto, $attr ) = @_;
    $attr->{col_names} = $attr->{ad}->{storage}->{col_names};
    $attr->{col_nums}  = $attr->{ad}->{storage}->{col_nums};
    delete $attr->{col_nums} unless ( defined( $attr->{col_nums} ) and defined( _HASH0( $attr->{col_nums} ) ) );
    return $proto->SUPER::new($attr);
}

sub trim
{
    my $x = $_[0];
    $x =~ s/^\s+//;
    $x =~ s/\s+$//;
    return $x;
}

sub fetch_row ($$$)
{
    my ( $self, $data, $row ) = @_;
    my $requested_cols = $data->{sql_stmt}->{NAME};
    my $dbh            = $data->{Database};
    my $fields         = $self->{ad}->fetch_row($requested_cols);
    if ( $dbh->{ChopBlanks} )
    {
        @$fields = map( $_ = &trim($_), @$fields );
    }
    $self->{row} = $fields;
    return $self->{row};
}

sub push_names ($$$)
{
    my ( $self, $data, $names ) = @_;
    #print @$names;
    $self->{ad}->push_names($names);
}

sub push_row ($$$)
{
    my ( $self, $data, $fields ) = @_;
    my $requested_cols = [];
    my @rc             = $data->{sql_stmt}->columns();
    push @$requested_cols, $_->{column} for @rc;
    unshift @$fields, $requested_cols;
    $self->{ad}->push_row(@$fields);
    1;
}

sub seek ($$$$)
{
    my ( $self, $data, $pos, $whence ) = @_;
    $self->{ad}->seek( $pos, $whence );
}

sub drop ($$)
{
    my ( $self, $data ) = @_;
    return $self->{ad}->drop();
}

sub truncate ($$)
{
    my ( $self, $data ) = @_;
    $self->{ad}->truncate($data);
}

sub DESTROY
{
    # wierd: this is needed to close file handle ???
    my $self = shift;
    #print "CLOSING" if $self->{ad}->{storage}->{fh};
    my $fh = $self->{ad}->{storage}->{fh} or return;
    $self->{ad}->DESTROY;
    undef $self->{ad}->{storage}->{fh};
}

=head1 NAME

DBD::AnyData - DBI access to XML, CSV and other formats

=head1 SYNOPSIS

 use DBI;
 my $dbh = DBI->connect('dbi:AnyData(RaiseError=>1):');
 $dbh->func( 'trains', 'CSV', '/users/joe/cars.csv', 'ad_catalog');
 $dbh->func( 'bikes',  'XML', [$xml_str],            'ad_import');
 $dbh->func( 'cars',   'DBI', $mysql_dbh,            'ad_import');
 #
 # ... DBI/SQL methods to access/modify the tables 'cars','bikes','trains'
 #
 print $dbh->func( 'cars', 'HTMLtable', 'ad_export');

 or

 use DBI;
 my $dbh = DBI->connect('dbi:AnyData(RaiseError=>1):');
 $dbh->func( 'Pipe', 'data.pipe', 'XML', 'data.xml', 'ad_convert');

 or

 (many combinations of a dozen other data formats, see below)

=head1 DESCRIPTION

The DBD::AnyData module provides a DBI/SQL interface to data in many
formats and from many sources.

Currently supported formats include general format flatfiles (CSV, Fixed
Length, Tab or Pipe "delimited", etc.), specific formats (passwd files,
web logs, etc.), a variety of other kinds of formats (XML, Mp3, HTML
tables), and, for some operations, any DBI accessible database.  The
number of supported formats will continue to grow rapidly since there
is an open API making it easy for any author to create additional format
parsers which can be plugged in to AnyData.

Data in these various formats can come from local files, from remote files,
or from perl data structures such as strings and arrays.

Regardless of the format or source of the data, it may be accessed and/or
modified using all standard DBI methods and a subset of SQL syntax.

In addition to standard database access to files, the module also supports
in-memory tables which allow you to create temporary views; to combine data
from a number of sources; to quickly prototype database systems; and to
display or save the data in any of the supported formats (e.g. to display
data in a CSV file as an HTML table).  These in-memory tables can be
created from any combination of DBI databases or files of any format.
They may also be created from perl data structures which means it's
possible to quickly prototype a database system without any file access
or rdbms backend.

The module also supports converting files between any of the supported
formats (e.g. save selected data from MySQL or Oracle to an XML file).

Here a just a few examples of the capabilities:

    # SELECT DATA FROM A PASSWD FILE
    #
    $dbh->func( 'users', 'Passwd', '/etc/passwd', 'ad_catalog');
    my $sth = $dbh->prepare("SELECT username,homedir,GID FROM users');

    # INSERT A NEW ROW INTO A CSV FILE
    #
    $dbh->func( 'cars', 'CSV', 'cars.csv', 'ad_catalog');
    $dbh->do("INSERT INTO cars VALUES ('Honda','Odyssey')");

    # READ A REMOTE XML FILE AND PRINT IT AS AN HTML TABLE
    #
    print $dbh->func( 'XML', $url, 'HTMLtable', 'ad_convert');

    # CONVERT A MYSQL DATABASE INTO XML AND SAVE IT IN A NEW FILE
    #
    $dbh->func( 'DBI', $mysql_dbh, 'XML', 'data.xml', 'ad_convert');

    # CREATE AND ACCESS A VIEW CONTAINING DATA FROM AN ORACLE DATABASE
    # AND A TAB DELIMITED FILE
    #
    $dbh->func( 'combo', 'DBI', $oracle_dbh, 'ad_import');
    $dbh->func( 'combo', 'Tab', 'data.tab', 'ad_import');
    my $sth = $dbh->prepare("SELECT * FROM combo");


=head1 INSTALLATION 

To use DBD::AnyData you will need to install these modules, 
all available from CPAN and most available from activeState.

  * DBI
  * DBI::DBD::SqlEngine
  * SQL::Statement
  * AnyData
  * DBD::AnyData

Note: DBI::DBD::SqlEngine is part of the DBI distribution

Some advanced features require additional modules:

=over 4

=item remote file access

requires L<LWP> (the libwww bundle)

=item XML access

requires L<XML::Parser> and L<XML::Twig>

=item HTML table

access requires L<HTML::Parser> and L<HTML::TableExtract>

=item HTML table writing

requires L<CGI>

=back

AnyData and DBD::AnyData themselves can either be installed via cpan,
cpanplus or cpanminus, using the distributed Build.PL manually with

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

or by copying the AnyData.pm file manually to it's right place within
your perl library path.

=head1 QUICK START

=head2 The Basics

=over 1

=item There are four main steps in using DBD::AnyData in a script:

 1. Specify that you want to use the DBI module
 2. Create a database handle
 3. Specify the tables, files, and formats you want
 4. Use DBI/SQL commands to access and/or modify the data

Steps #1, #2, and #3 can be as little as a single line of code each.

Steps #3 and #4 can be omitted in some situations, see the sections
below on "Working with In-Memory Data" and "Converting Data"

=item Step #1 : Specify that you want to use the DBI module

This step is always the same: just put this at the top of your script:

  use DBI;

=item Step #2 Create a Database Handle

This step can vary slightly depending on your needs but is usually this:

  my $dbh = DBI->connect('dbi:AnyData(RaiseError=>1):');

See the section below on "Connection Options" for other forms of
connecting.  See the section below on "Using Multiple Databases" for
cases in which you may be creating more than one database handle.

=item Step #3 : Specify the tables, files, and formats

This step makes use of one of several methods unique to DBD::AnyData.
These methods use the database handle created in step #2 to make a
func() call and specify the name of the method as the last parameter.
For example the 'ad_catalog' method would be called like this:

  $dbh->func( ..., 'ad_catalog')

The ad_catalog() method takes three required parameters and one
optional parameter:

  # $table  = the name you will use to refer to the table in SQL commands
  # $format = the format of the data ('XML', 'CSV', 'Fixed', etc.)
  # $file   = the name of a local or remote file holding the data
  # $flags  = an optional hash of flags required by some data formats
  $dbh->func( $table, $format, $file, $flags, 'ad_catalog')

  # For example:
  $dbh->func( 'cars', 'XML', 'cars.xml', 'ad_catalog' )

This specifies that the table name 'cars' will be used to
access XML data stored in the file 'cars.xml'.

Once you have issued a catalog command, you can use the name $table
in SQL commands to access or modify the data in $file.  The catalog
only needs to be specified once for a table/file/format combination
and can then be used for an unlimited number of processing commands.

=item Step #4 : Use DBI/SQL commands to access and/or modify data

DBD::AnyData supports all standard DBI methods and a subset of SQL
syntax. See the section below "SQL Syntax" for a description of the
supported SQL commands.  See the DBI documentation for detailed
description of DBI commands.

The do() method can be used to create or drop a table and insert, delete,
or update rows:

  $dbh->do("CREATE TABLE ... )
  $dbh->do("DROP TABLE ... )
  $dbh->do("INSERT INTO ... )
  $dbh->do("UPDATE ... )
  $dbh->do("DELETE ... )

A combination of the prepare(), execute(), and fetch() methods can be
used to access data:

  my $sth = $dbh->prepare("SELECT * FROM cars WHERE make = 'Honda'");
  $sth->execute();
  while (my $row = $sth->fetchrow_hashref){
      print $row->{model};
  }

=item Putting it all together

This is the complete script needed to access data stored in
CSV format in a file called "cars.csv".  It prints all data
from the "make" and "model" columns of the database.

  # specifies that you will use the DBI module.
  use DBI;
  # creates a database handle
  my $dbh = DBI->connect('dbi:AnyData(RaiseError=>1):');
  # specifies the table, format, and file holding the data
  $dbh->func( 'cars', 'CSV', 'cars.csv' 'ad_catalog');
  # through 8 use DBI and SQL to access data in the file
  my $sth = $dbh->prepare("SELECT make, model FROM cars");
  $sth->execute();
  while (my $row = $sth->fetch) {
      print "@$row\n";
  }

=back

=head2 Customizing table structure

DBD::AnyData uses a number of defaults when it decides how to read data
from a database and in many cases these defaults are all you will need.
However, depending on the format and database you are using, you may need
to specify other features such as column names, record separators, etc.

You can specify this additional information in the $flags parameter of the
ad_catalog and other DBD::AnyData methods.  $flags is always a reference
to a hash, i.e. one or more key value pairs joined with a =>, separated by
commas, and delimited by curly braces:

  $flags = { key1 => value1, key2 => value2 ... }

  # or in the method call:
  $dbh->func( $table, $format, $file, { key1=>,val1 ... }, 'ad_catalog');

=over 2

=item Column Names

Some formats have pre-defined column names:

    Passwd  username
            passwd
            UID
            GID
            fullname
            homedir
            shell

    Weblog  remotehost
            usernname
            authuser
            date
            request
            status
            bytes
            referer
            client

    Mp3     song
            artist
            album
            year
            genre
            filename
            filesize

Column names for the other formats can either be specified in the database
itself or supplied by you in the $flags parameter.

If the column names are specified in the database, they are taken from
the first record in the database. For example in a CSV (Comma
Separated Values) file or a Fixed Length file, the default is to treat
the first line of the table as the list of column names.  In an
HTMLtable file, the default is to look for the first <tr> in the first
table.  In an XML file, the default is to use the names of all
attributes and all CDATA and PCDATA elements contained within the first
non-initial tag.

In most cases, this first record that defines the column names is in
the same format as the rest of the table e.g. a CSV string in a CSV
file, a tab delimited string in a Tab delimited file, etc.  The one
exception to this is that in a Fixed Length file the first row of the
file can contain a *comma-separated* list of column names, not a fixed
length list.  HTMLtable and XML also use other flags to select the
column names (e.g. the number of the table or the depth in the tree to
examine).  Please see the documentation for these formats for further
details of how defaults are selected.

For most formats, if the column names are not contained in the first
record in the file, then you can specify them as a comma separated
list in the $flags parameter, for example:

  $dbh->func(
      'cars',
      'Tab',
      'data.tab',
      { col_names => 'make,model,year' },
  'ad_catalog')

=back

=head1 SUPPORTED FORMATS

=head2 CSV, Tab, Pipe, Ini, Paragraph

=head2 Fixed

Fixed Length format files (where each column is a specified length)
are unique in several respects.  First, as mentioned above, if you
wish to include the column names in the file itself, they should be on
the first line of the file as a *comma separated* string.

Secondly, there is a mandatory flag called 'pattern' that you must use
whenever you use the Fixed length format.  This flag specifies the
widths of the columns.  It uses the standard Perl pack/unpack syntax
to specify the pattern.  See the Perl documentation for those commands
for further details.  In most cases simply using a capital 'A'
followed by the length of the field suffices:

  { pattern => 'A10 A12 A4' }

This specifies that the table contains three fields with widths of 10,
12, and 14 characters.

=head2 XML

=head2 HTMLtable

=head2 DBI

DBD::AnyData supports importing any DBI database into memory and can
also convert any DBI database into any of the other AnyData formats.

Use the format name 'DBI', and instead of a filename, pass the
ad_import call a connection in whatever database you are using, and
specify a SQL SELECT statement:

  my $dbh = DBI->connect('dbi:AnyData:(RaiseError=>1)');
  $dbh->func(
      'table1',
      'DBI',
      DBI->connect('dbi:mysql:database=test:(RaiseError=>1)'),
      {sql=>"SELECT make, model FROM cars WHERE make = 'honda'"},
  'ad_import');

That snippet imports a view from a MySQL database (selecting only the
named columns and the selected rows) into an AnyData in-memory table.
It can then be queried and/or modified in memory and then either
displayed or stored to a file in some other format such as XML.

You may also use a bind_parameters form for the SQL call by passing an
additional flag with an arrayref of the parameters:

  {
      sql     => "SELECT make,model FROM CARS WHERE make = ?"
      params  => ['honda']
  }

To convert from a DBI accessible database such as ORACLE or MySQL to
one of the AnyData formats such as XML you must also include a flag
with the table_name within the database:

  my $dbh = DBI->connect('dbi:AnyData:(RaiseError=>1)');
  $dbh->func(
      'DBI',
      DBI->connect('dbi:mysql:database=test:(RaiseError=>1)'),
      'XML',
      'cars.xml',
      {table_name=>'cars'},
  'ad_convert');

Or to print out the same data as an HTML table without storing it:

  my $dbh = DBI->connect('dbi:AnyData:(RaiseError=>1)');
  print $dbh->func(
      'DBI',
      DBI->connect('dbi:mysql:database=test:(RaiseError=>1)'),
      'HTMLtable',
      undef,
      {table_name=>'cars'},
  'ad_convert');

The ad_convert() method works on the entire database. If you need to
convert only a selected portion of the databse, use ad_import() with
a SELECT clause and then ad_export() it to the new format.

The ad_import method by default closes the connection for the imported
database.  If you need to continue using the handle for the other datbase,
pass the flag {keep_connection=>1}:

  my $dbh       = DBI->connect('dbi:AnyData:(RaiseError=>1)');
  my $mysql_dbh = DBI->connect('dbi:mysql:database=test:(RaiseError=>1)'),
  $dbh->func(
      'cars',
      'DBI',
      $mysql_dbh,
      { keep_connection=>1 },
  'ad_import');
  #...
  $mysql_dbh->disconnect;

=head2 Passwd, Weblog, Mp3

=head2 Other Formats

DBD::AnyData supports an open API that allows other authors to build support
for other formats. This means that the list of supported formats will
continually grow. At the moment Wes Hardaker is working on
AnyData::Format::SNMP and Earl Cahill is working on
AnyData::Format::Storable. Anyone who is interested in working on a new
format module, please open a ticket with an appropriate patch or
write to dbi-dev@perl.org.

=head1 FURTHER DETAILS

=head2 Converting between formats

The $dbh->func(...,'ad_convert') method provides a one-step way to
convert between any of the data formats supported by DBD::AnyData.
For example: read a CSV file and save it as an XML file or vice versa.
See the section below on "convert" for details.  See the section on
"Working with other DBI databases" for information on converting data
from ORACLE, or MySQL or almost any other database into XML, CSV, or
any of the DBD::AnyData formats.

=head2 Using remote files

You can import remote files accessible by FTP or HTTP directly into a
DBD::AnyData in memory database using 'ad_import' or you can use ad_convert
to print the remote files as strings or save them to a local file.  
If the $file parameter of ad_import or ad_convert starts with "ftp" or
"http", DBD::AnyData will call LWP behind the scenes and fetch the file.

This will fetch the remote file, parse its XML, and provide you with
an in-memory table which you can query with DBI/SQL or save to a local
file:

  $dbh->func(
      'news',
      'XML',
      'http://www.somewhere.org/files/news.xml',
  'ad_import');

This will fetch the remote file, parse its XML, and print it out
as an HTML table:

  print $dbh->func(
      'XML',
      'http://www.somewhere.org/files/news.xml',
      'HTMLtable',
  'ad_convert');

If the remote file requires authorization, you can include values for
"user" and "pass" in the $flags parameter:

  $dbh->func(
      'news',
      'XML',
      'http://www.somewhere.org/news.xml',
      { user => 'fred', passwd => 'x9y77d' },
  'ad_import');

=head2 Working with in-memory tables

In addition to normal file storage databases, DBD::AnyData supports
databases that are stored and modified in-memory. You may either simply
query the databases and then close them, or you can use the ad_export
method to display data to the screen or save it to a file.  There are a
variety of reasons you might want to work with in-memory databases,
including:

=over 4

=item Prototyping

quickly create a database from a string, an array, or the DATA section of
a script without needing any file access or rdbms.

=item Creating Views

pull selected columns and selected rows from an ORACLE or MySQL database
en masse and work with them in memory rather than having to use the full
database.

=item Combining Data from multiple formats

create a single in-memory table by importing selected columns and rows
from e.g. an XML file, an Oracle database, and a CSV file.

=item Rollback/Commit

You can make multiple changes to the in-memory database and then,
depending on the sucess or failure of those changes either commit by using
export to save the changes to disk or skip export which effectively rolls
back the database to its state before the import.

=back

In-memory tables may be modified with DBI/SQL commands and can then be
either printed to the screen or saved as a file in any of the AnyData
formats. (see the ad_export method below)

In-memory tables may be created in several ways:

 1. Create and populate the table from one or more local or remote files
 2. Create and populate the table from a string
 3. Create and populate the table from an array
 4. Use DBI/SQL commands to create & populate the table

=over 4

=item Creating in-memory tables from local or remote files

You can create an in-memory table from a string in a specified format,
Note: the string should be enclosed in square brackets.

This reads a CSV file into an in-memory table.  Further access and
modification takes place in-memory without further file access unless
you specifically use ad_export to save the table to a file.

  # CREATE A TABLE FROM A LOCAL FILE
  $dbh->func( 'test2', 'CSV', $filename, 'ad_import');

  # CREATE A TABLE FROM A REMOTE FILE
  $dbh->func( 'test2', 'CSV', $url, 'ad_import');

See the section on "Remote File Access" for further details of using
remote Files.

=item Creating an in-memory table from Strings

You can create an in-memory table from a string in a specified format,
Note: the string should be enclosed in square brackets.

This example creates an in-memory table from a CSV string:

  # CREATE A TABLE FROM A CSV STRING
  $dbh->func( 'test2', 'CSV',
       ["id,phrase\n1,foo\n2,bar"],
  'ad_import');

=item Creating an in-memory table from the DATA section of a script

Perl has the really cool feature that if you put text after the
marker __END__, you can access that text as if it were from a
file using the DATA array.  This can be great for quick prototyping.

For example this is a complete script to build and access a small
table and print out "Just Another Perl Hacker":

  use DBI;
  my $dbh=DBI->connect('dbi:AnyData(RaiseError=>1):');
  $dbh->func( 'test', 'XML',  [<DATA>],  'ad_import');
  print $dbh->selectcol_arrayref(qq{
      SELECT phrase FROM test WHERE id = 2
  })->[0];
  __END__
  <phrases>
      <phrase id="1">Hello World!</phrase>
      <phrase id="2">Just Another Perl Hacker!</phrase>
  </phrases>

The same idea can be used with DATA sections of any size in any of
the supported formats.

=item Creating an in-memory table from Arrays

In-memory tables may also be created from arrays.  Or, more technically,
from references to arrays.  The array should consist of rows which are 
themselves references to arrays of the row values.  The first row should 
be column names.

For example:

 # CREATE A TABLE FROM AN ARRAY
 $dbh->func( 'test3', 'ARRAY',
             [
                ['id','phrase'],
                [1,'foo'],
                [2,'bar']
             ],
 'ad_import');

=item Creating an in-memory table from DBI/SQL commands

If you do not use ad_catalog or ad_import to associate a table
name with a file, then the table will be an in-memory table, so
you can just start right out by using it in DBI/SQL commands:

  # CREATE & POPULATE A TABLE FROM DBI/SQL COMMANDS
  use DBI;
  my $dbh = DBI->connect('dbi:AnyData(RaiseError=>1):');
  $dbh->do("CREATE TABLE test (id TEXT,phrase TEXT)");
  $dbh->do("INSERT INTO test VALUES (1,'foo')");
  $dbh->do("INSERT INTO test VALUES (2,'bar')");
  $dbh->do("UPDATE test SET phrase='baz' WHERE id = '2'");
  $dbh->do("DELETE FROM test WHERE id = '1'");

=back

=head2 Using Multiple Databases, Simulating Joins

You may access any number of databases within a single script and can mix
and match from the various data formats.

For example, this creates two in-memory tables from two different data
formats

  $dbh->func( 'classes', 'CSV', 'classes.csv' 'ad_import');
  $dbh->func( 'profs',   'XML', 'profs.xml',  'ad_import');

You can also import columns from several different formats into a single
table.  For example this imports data from an XML file, a CSV file and a
Pipe delimited file into a single in-memory database.  Note that the
$table parameter is the same in each call so the data from each import
will be appended into that one table.

  $dbh->func( 'test', 'XML',  [$xmlStr],  'ad_import');
  $dbh->func( 'test', 'CSV',  [$csvStr],  'ad_import');
  $dbh->func( 'test', 'Pipe', [$pipeStr], 'ad_import');

When you import more than one table into a single table like this, the
resulting table will be a cross join unless you supply a lookup_key flag.
If a lookup_key is supplied, then a the resulting table will be a full
outer join on that key column.  This feature is experimental for the time
being but should work as expected unless there are columns other than the
key column with the same names in the various tables.  You can specify
that the joined table will only contain certain columns by creating a
blank empty table before doing the imports.  You can specify only certain
rows with the sql flag.  For example:

  $dbh->func('test','ARRAY',[],{col_names=>'foo,bar'baz'}, 'ad_import');
  $dbh->func('test','XML',$file1,{lookup_key=>'baz'},'ad_import');
  $dbh->func('test','CSV',$file1,{lookup_key=>'baz'},'ad_import');

DBD::AnyData does not currently support using multiple tables in a
single SQL statement.  However it does support using multiple tables
and querying them separately with different SQL statements.  This
means you can simulate joins by creating two statement handles and
using the values from the first handle as a lookup key for the second
handle.  Like this:

  $dbh->func( 'classes', 'CSV', 'classes.csv' 'ad_import');
  $dbh->func( 'profs',   'XML', 'profs.xml',  'ad_import');
  my $classes_sth = $dbh->prepare( "SELECT pid,title FROM classes" );
  my $profs_sth   = $dbh->prepare( "SELECT name FROM profs WHERE pid = ?" );
  $classes_sth->execute;
  while (my($pid,$class_title) = $classes_sth->fetchrow_array) {
      $profs_sth->execute($pid);
      my $row = $profs_sth->fetchrow_arrayref;
      my $prof_name = $row ? $row->[0] : '';
      print "$class_title : $prof_name\n";
  }

  # That will produce the same results as:
  SELECT classes.title,profs.name FROM classes,profs WHERE pid = pid

=head1 REFERENCE

=head2 Overview of DBD::AnyData Methods

DBD::AnyData makes use of five methods not found in other drivers:


=over 12

=item ad_catalog

specifies a file to be used for DBI/SQL continuous file access 

=item ad_import

imports data into an in-memory table

=item ad_export

exports data from an in-memory table to a file

=item ad_clear

clears an in-memory table (deletes it from memory)

=item ad_convert

converts data from one format to another and either saves it in a new file
or returns it as a string

=back

These methods are called using DBI func(), for example:

  $dbh->func( $table, $format, 'ad_export');

  # Here are the parameters for the various methods:
  $dbh->func( $table, $format, $file, $flags, 'ad_catalog');
  $dbh->func( $table, $format, $data, $flags, 'ad_import');

  $dbh->func( $source_format, $source_data,
              $target_format, $target_file,
              $source_flags,  $target_flags,
  'ad_convert');

  $dbh->func( $table, $format, $file, $flags, 'ad_export');
  $dbh->func( $table, 'ad_clear' );
     
  # $table is a valid SQL table name
  # $format is one of the AnyData formats ('XML','CSV',etc.)
  # $file is a valid file name (relative or absolute) on the local computer
  # $flags is a hashref containing key/value pairs, e.g.
  { col_names => 'make,model,year', pattern => 'A10 A12 A4' }

  # $data is one of:
  # * a valid file name (relative or absolute) on the local computer
  # * a valid absolute FTP or HTTP URL
  # * an arrayref containing arrayrefs of rows with column names first
  #     [
  #       ['make','model'],
  #       ['Honda','Odyssy'],
  #       ['Ford','Suburban'],
  #     ]

  # * an arrayref containing a string in a specified format
  #     CSV  :  ["id,phrase\n1,foo\n2,bar"]
  #     Pipe :  ["id|phrase\n1|foo\n2|bar"]

  # * a reference to the DATA section of a file
  #      [<DATA>]

  # * a DBI Database handle
  #      DBI->connect('dbi:mysql:database=...)

The ad_catalog method is the standard way to treat files as databases.
Each time you access data, it is read from the file and each time you
modify data, it is written to the file. The entire file is never read
en masse into memory unless you explicitly request it.

The ad_import method can import data from local or remote files, 
from any other DBI accessible database, from perl data structures such
as arrays and strings. You may import an entire table or only the columns
and rows you specify. If the data is imported from a file, all of the
data you select is read into memory when you call ad_import so this should
not be done with selections larger than will fit in your memory. :-).
All accessing and modification is done in memory. If you want to save the
results of any changes, you will need to call ad_export explicitly.  

Not all formats and data sources will work with all methods. Here is a
summary of what will work.  "all sources" includes local files, remote
files, any DBI accessible database, perl arrayrefs, perl strings.

 Import From   all formats, all sources
 Convert From  all formats, all sources
 Convert To    all formats except DBI, local files, arrays or strings only
 Export To     all formats except DBI, local files, arrays or strings only
 Catalog       all formats except DBI, XML, HTMLtable, Mp3, ARRAY,
               local files only

=head2 connect

The DBI->connect call 

=head2 ad_catalog

 PURPOSE:

    Creates an association betweeen a table name, a data format, and a file.

 SYNTAX:

     $dbh->func( $table, $format, $file, $flags, 'ad_catalog' )

 PARAMETERS:

     $table  = the name of the table to be used in SQL commands

     $format = an AnyData format ('XML','CSV', etc.)

     $file   = the name of a local file (either full path or relative)

     $flags  = a optional hashref of column names or other values

 EXAMPLE:

    This specifies that any DBI/SQL statements to the table
    'cars' will access and/or modify XML data in the file 
    '/users/me/data.xml'

       $dbh->func( 'cars', 'XML', '/usrs/me/data.xml', 'ad_catalog' )

 REMARKS:

    The format may be any AnyData format *except* DBI, XML, HTMLtable,
    and MP3.

=head2 ad_import

 PURPOSE:

     Imports data from any source and any format into an in-memory table.

 SYNTAX:

     $dbh->func( $table, $format, $data_source, $flags, 'ad_import' )

 PARAMETERS:

     $table       = the name of the table to be used in SQL commands

     $format      = an AnyData format ('XML','CSV', etc.)

     $data_source = $file_name
                 or $url
                 or [$string]
                 or [<DATA>]
                 or $reference_to_an array of arrays
                 or $DBI_database_handle

     (See section "Data Sources" for more specifics of $data_source)

 EXAMPLES:

     $dbh->func( 'cars', 'XML', '/usrs/me/data.xml', 'ad_import' )

     For further examples, see sections on "In-Memory Tables",
     "Remote Files", "DBI databases".


=head2 ad_export

 PURPOSE:

     Converts an in-memory table into a specified format and either saves
     it to a file or returns it as a string.

 SYNTAX:

     $dbh->func( $table, $format, $file, $flags, 'ad_export' )

     OR

     my $string = $dbh->func( $table, $format, $flags, 'ad_export' )

 PARAMETERS:

     $table  = the name of the in-memory table to export

     $format = an AnyData format ('XML','CSV', etc.)

     $file   = the name of a local file (either full path or relative)

 EXAMPLES:

     Save a table as an XML file:

        $dbh->func( 'cars', 'XML', '/usrs/me/data.xml', 'ad_export' )

     Print a table as an HTML table

         print $dbh->func( 'cars', 'HTMLtable', 'ad_export' )

=head2 ad_convert

 PURPOSE:

     Converts data from one format into another and either returns it
     as a string in the new format or saves it to a file in the new
     format.

 SYNTAX:

   my $str = $dbh->func(
       $source_format,
       $data_source
       $target_format,
       $source_flags,
       $target_flags,
   'ad_convert' );

   OR

   $dbh->func(
       $source_format,
       $data_source
       $target_format,
       $target_file,
       $source_flags,
       $target_flags,
   'ad_convert' );

 PARAMETERS:

     $source_format = AnyData format ('XML','CSV', etc.) of the source db

     $target_format = AnyData format ('XML','CSV', etc.) of the target db

     $target_file  = name of file to store converted data in

     $data_source = $file_name
                 or $url
                 or [$string]
                 or [<DATA>]
                 or $reference_to_an array of arrays
                 or $DBI_database_handle

     (See section "Data Sources" for more specifics of $data_source)

 EXAMPLES:

 # CONVERT A CSV FILE TO AN XML FILE
 #
 $dbh->func( 'CSV', 'data.csv', 'XML', 'data.xml', 'ad_convert');

 # CONVERT AN ARRAYREF TO AN HTML TABLE AND PRINT IT
 #
 print $dbh->func( 'ARRAY', $aryref, 'HTMLtable', 'ad_convert');

 # CONVERT AN ARRAYREF TO XML AND SAVE IT IN A FILE
 #
 $dbh->func( 'ARRAY', $aryref, 'XML', 'data.xml', 'ad_convert');

 # CONVERT A SELECTION FROM A MySQL DATABASE TO XML
 # AND SAVE IT IN A FILE
 #
 $dbh->func(
     'DBI',
     $mysql_dbh,
     'XML',
     'data.xml',
     {sql=>"SELECT make,model FROM CARS where year > 1996"}
 'ad_convert');

 REMARKS

 The format 'DBI' (any DBI accessible database) may be used as the
 source of a conversion, but not as the target of a conversion.

 The format 'ARRAY' may be used to indicate that the source of the
 conversion is a reference to an array.  Or that the result of the
 conversion should be returned as an array reference.  (See above, 
 working with in-memory database for information on the structure of
 the array reference).


=head2 Data Sources

 The ad_import and ad_convert methods can take data from many
 sources, including local files, remote files, strings, arrays,
 any DBI accessible database, the DATA section of a script.

 The $data_source parameter to ad_import and ad_convert will
 vary depending on the specific data source, see below.

 Local Files

     A string containing the name of a local file.  It may either
     be a full path, or a path or file relative to the currently
     defined f_dir (see ?);

     e.g. '/users/me/data.xml'

 Remote Files

     A string containing the url of the data.  Must start with
     'ftp://' or 'http://'

     e.g. 'http://www.somewhere.org/misc/news.xml'

 Arrays of Arrays

     A reference to an array of data.  Each row of the data is
     a reference to an array of values.  The first row is the
     column names. E.G.:

        [
          ['make','model'],
          ['Honda','Odyssy'],
          ['Ford','Suburban'],
        ]

  Strings

     A string in the specified format including all field and record
     separators.  The string should be the only row in an array reference
     (i.e. it should be enclosed in square brackets)

     e.g. a CSV string

         ["id,phrase\n1,foo\n2,bar"]

     or in Pipe Delimited string

         ["id|phrase\n1|foo\n2|bar"]

  The DATA section of a file

      A reference to the array obtained from the lines after 
      __END__ in a script.

         [<DATA>]

  DBI Databases

      A database handle for a specified rdbms.

      DBI->connect('dbi:mysql:database=...)


=head2 ad_clear

 PURPOSE:

     Clears an in-memory table (deletes it from memory)

 SYNTAX:

     $dbh->func( $table, 'ad_clear' )

 PARAMETERS:

     $table  = the name of the in-memory table to clear

 REMARKS:

 In-memory tables will be deleted from memory automatically when the
 database handle used to create them goes out of scope.  They will also
 be deleted if you call $dbh->disconnect() on the database handle
 used to create them.  The ad_clear method is a way to free up memory
 if you intend to keep using the database handle but no longer need a
 given table.  As with other (all?) Perl memory operations, this frees
 memory for the remainder of your perl script to use but does not decrease
 the total amount of system memory used by the script.

=head2 SQL Syntax

 Currently only a limited subset of SQL commands are supported.
 Only a single table may be used in each command.  This means
 That there are *no joins*, but see the section above on simulating
 joins.  In coming months additional SQL capabilities will be added,
 so keep your eyes out for ANNOUNCE message on usenet or the dbi-users
 mailing list (see below "Getting More Help").

 Here is a brief synopsis, please see the documentation for
 SQL::Statement for a more complete description of these commands.

       CREATE  TABLE $table
                     ( $col1 $type1, ..., $colN $typeN,
                     [ PRIMARY KEY ($col1, ... $colM) ] )

        DROP  TABLE  $table

        INSERT  INTO $table
                     [ ( $col1, ..., $colN ) ]
                     VALUES ( $val1, ... $valN )

        DELETE  FROM $table
                     [ WHERE $wclause ]

             UPDATE  $table
                     SET $col1 = $val1, ... $colN = $valN
                     [ WHERE $wclause ]

  SELECT  [DISTINCT] $col1, ... $colN
                     FROM $table
                     [ WHERE $wclause ] 
                     [ ORDER BY $ocol1 [ASC|DESC], ... $ocolM [ASC|DESC] ]

           $wclause  [NOT] $col $op $val|$col
                     [ AND|OR $wclause2 ... AND|OR $wclauseN ]

                $op  = |  <> |  < | > | <= | >= 
                     | IS NULL | IS NOT NULL | LIKE | CLIKE

 The "CLIKE" operator works exactly like "LIKE" but is case insensitive.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-dbd-anydata at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBD-AnyData>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc DBD::AnyData

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBD-AnyData>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBD-AnyData>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBD-AnyData>

=item * Search CPAN

L<http://search.cpan.org/dist/DBD-AnyData/>

=back

=head1 ACKNOWLEDGEMENTS

Many people have contributed ideas and code, found bugs, and generally
been supportive including Tom Lowery, Andy Duncan, Randal Schwartz, Michel
Rodriguez, Wes Hardraker, Bob Starr, Earl Cahill, Bryan Fife, Matt Sisk,
Matthew Wickline, Wolfgang Weisseberg.  Thanks to Jochen Weidmann for
DBD::File and SQL::Statement and of course Tim Bunce and Alligator
Descartes for DBI and its documentation.

=head1 AUTHOR & COPYRIGHT

Copyright 2000, Jeff Zucker <jeff@vpservices.com>

Copyright 2010, Jens Rehsack <rehsack@cpan.org>

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

All rights reserved

=cut

1;    # End of DBD::AnyData
