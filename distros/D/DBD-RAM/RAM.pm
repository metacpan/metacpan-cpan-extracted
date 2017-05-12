#########################################################################
#
#   DBD::RAM - a DBI driver for files and data structures
#
#   This module is copyright (c), 2000 by Jeff Zucker
#   All rights reserved.
#
#   This is free software.  You may distribute it under
#   the same terms as Perl itself as specified in the
#   Perl README file.
#
#   WARNING: no warranty of any kind is implied.
#
#   To learn more: enter "perldoc DBD::RAM" at the command prompt,
#   or search in this file for =head1 and read the text below it
#
#########################################################################

package DBD::RAM;

use strict;
require DBD::File;
require SQL::Statement;
require SQL::Eval;
use IO::File;

use vars qw($VERSION $err $errstr $sqlstate $drh $ramdata);

$VERSION = '0.07';

$err       = 0;        # holds error code   for DBI::err
$errstr    = "";       # holds error string for DBI::errstr
$sqlstate  = "";       # holds SQL state for    DBI::state
$drh       = undef;    # holds driver handle once initialized

sub driver {
    return $drh if $drh;        # already created - return same one
    my($class, $attr) = @_;
    $class .= "::dr";
    $drh = DBI::_new_drh($class, {
        'Name'    => 'RAM',
        'Version' => $VERSION,
        'Err'     => \$DBD::RAM::err,
        'Errstr'  => \$DBD::RAM::errstr,
        'State'   => \$DBD::RAM::sqlstate,
        'Attribution' => 'DBD::RAM by Jeff Zucker',
    });
    return $drh;
}

package DBD::RAM::dr; # ====== DRIVER ======

$DBD::RAM::dr::imp_data_size = 0;

@DBD::RAM::dr::ISA = qw(DBD::File::dr);

sub connect {
    my($drh, $dbname, $user, $auth, $attr)= @_;
    my $dbh = DBI::_new_dbh($drh, {
        Name         => $dbname,
        USER         => $user,
        CURRENT_USER => $user,
    });
    # PARSE EXTRA STRINGS IN DSN HERE
    # Process attributes from the DSN; we assume ODBC syntax
    # here, that is, the DSN looks like var1=val1;...;varN=valN
    my $var;
    foreach $var (split(/;/, $dbname)) {
        if ($var =~ /(.*?)=(.*)/) {
            my $key = $1;
            my $val = $2;
            $dbh->STORE($key, $val);
        }
    }
    $dbh->STORE('f_dir','./') if !$dbh->{f_dir};
#    use Data::Dumper; die Dumper $DBD::RAM::ramdata if $DBD::RAM::ramdata;
    $dbh;
}

sub data_sources {}

sub disconnect_all{  $DBD::RAM::ramdata = {};}

sub DESTROY { $DBD::RAM::ramdata = {};}


package DBD::RAM::db; # ====== DATABASE ======

$DBD::RAM::db::imp_data_size = 0;

@DBD::RAM::db::ISA = qw(DBD::File::db);

sub disconnect{ $DBD::RAM::ramdata = {};}

# DRIVER PRIVATE METHODS

sub clear {
    my $dbh   = shift;
    my $tname = shift;
    my $r = $DBD::RAM::ramdata;
    if ( $tname && $r->{$tname} ) {
       delete $r->{$tname} if $tname && $r->{$tname};
    }
    else {
      $DBD::RAM::ramdata = {};
    }

}

sub dump {
   my $dbh = shift;
   my $sql = shift;
   my $txt;
   my $sth = $dbh->prepare($sql) or die $dbh->errstr;
#   use Data::Dumper; $Data::Dumper::Indent=0; print Dumper $sth;
   $sth->execute  or die $sth->errstr;
   my @col_names = @{$sth->{NAME}};
   $txt .= "<";
   for (@col_names) {
           $txt .=  "$_,";
   }
   $txt =~ s/,$//;
   $txt .= ">\n";
   while (my @row = $sth->fetchrow_array) {
       for (@row) {
           $_ ||= '';
           s/^\s*//;
           s/\s*$//;
           $txt .=  "[$_] ";
       }
       $txt .= "\n";
   }
   return $txt;
}

sub get_catalog {
    my $self  = shift;
    my $tname = shift || '';
    my $catalog = $DBD::RAM::ramdata->{catalog}{$tname} || {};
    $catalog->{f_type}    ||= '';
    $catalog->{r_type}    ||= $catalog->{f_type};
    $catalog->{f_name}    ||= '';
    $catalog->{pattern}   ||= '';
    $catalog->{col_names} ||= '';
    $catalog->{eol} ||= "\n";
    return $catalog;
}

sub catalog {
    my $dbh = shift;
    my $table_info = shift;
    if (!$table_info) {
        my @tables = (keys %{$DBD::RAM::ramdata->{catalog}} );
        my @all_tables;
        for (@tables) {
            push @all_tables,[
                $_,
                $DBD::RAM::ramdata->{catalog}{$_}{f_type},
                $DBD::RAM::ramdata->{catalog}{$_}{f_name},
                $DBD::RAM::ramdata->{catalog}{$_}{pattern},
                $DBD::RAM::ramdata->{catalog}{$_}{sep_char},
                $DBD::RAM::ramdata->{catalog}{$_}{eol},
                $DBD::RAM::ramdata->{catalog}{$_}{col_names},
                $DBD::RAM::ramdata->{catalog}{$_}{read_sub},
                $DBD::RAM::ramdata->{catalog}{$_}{write_sub}];
        }
        return @all_tables;
    }
    for (@{$table_info}) {
        my($table_name,$f_type,$f_name,$hash);
        if (ref $_ eq 'ARRAY') {
  	    ($table_name,$f_type,$f_name,$hash) = @{$_};
        }
        if (ref $_ eq 'HASH') {
  	    $table_name = $_->{table_name}  || die "catlog() requires a table_name";
  	    $f_type     = $_->{data_type}   || 'CSV';
  	    $f_name     = $_->{file_source} || '';
            $hash = $_;
        }
        $hash->{r_type} = $f_type;
        if ($f_type eq 'FIXED') { $f_type = 'FIX'; }
        if ($f_type eq 'PIPE'){
            $hash->{sep_char}='\s*\|\s*';
            $hash->{wsep_char}='|';
            $f_type = 'CSV';
        }
        if ($f_type eq 'TAB' ){
            $hash->{sep_char}="\t";
            $f_type = 'CSV';
        }
        if ($f_type eq 'INI' ){
            $hash->{sep_char}='=';
        }
        $DBD::RAM::ramdata->{catalog}{$table_name}{f_type} = uc $f_type || '';
        $DBD::RAM::ramdata->{catalog}{$table_name}{f_name} = $f_name    || '';
        if ($hash) {
	    for(keys %{$hash}) {
               next if /table_name/;
               next if /data_type/;
               next if /file_source/;
               $DBD::RAM::ramdata->{catalog}{$table_name}{$_}=$hash->{$_};
 	    }
	}
        $DBD::RAM::ramdata->{catalog}{$table_name}{eol} ||= "\n";
    }
}

sub get_table_name {
    my $dbh = shift;
    my @tables = (keys %{$DBD::RAM::ramdata} );
    if (!$tables[0]) { return 'table1';  }
    my $next=0;
    for my $table(@tables) {
        if ($table =~ /^table(\d+)/ ) {
            $next = $1 if $1 > $next;
        }
    }
    $next++;
    return("table$next");
}

sub export() {
    my $dbh    = shift;
    my $args   = shift || die "No arguments for export()\n";
    my $msg = "export() requires ";
    my $sql    = $args->{data_source} || die $msg . '{data_source => $}';
    my $f_name = $args->{data_target} || die 'export requires {data_target => $f}';
    my $f_type = $args->{data_type} || die 'export requires {data_type => $d}';
    if ($f_type eq 'XML') { return &export_xml($dbh,$args); }
    my $temp_table = 'temp__';
    $dbh->func( [[$temp_table,$f_type,$f_name,$args]],'catalog');
    my $sth1 = $dbh->prepare($sql);
    $sth1->execute or die $DBI::errstr;
    my @col_names = @{$sth1->{NAME}};
    my $sth2 = &prep_insert( $dbh, $temp_table, @col_names );
    while (my @row = $sth1->fetchrow_array) {
        $sth2->execute(@row);
    }
    delete $DBD::RAM::ramdata->{catalog}{$temp_table};
}

sub export_xml() {
    my $dbh    = shift;
    my $args   = shift;
    my $msg = "Export to XML requires ";
    my $sql    = $args->{data_source}       || die $msg . '{data_source => $}';
    my $f_name = $args->{data_target} || die $msg . '{data_target => $f}';
    my $f_type = $args->{data_type} || die $msg . '{data_type => $d}';
    my $record_tag = $args->{record_tag} || die $msg . '{record_tag => $r}';
    my $header = $args->{header} || '';
    my($head,$item,$foot) = &prep_xml_export($header,$record_tag);
    $f_name = $dbh->{f_dir} . '/' .$f_name;
    $f_name =~ s#//#/#g;
    open(O,">$f_name") || die "Couldn't write to $f_name: $!\n";
    print O $head, "\n";
    my $sth = $dbh->prepare($sql);
    $sth->execute;
    my @col_names = @{$sth->{NAME}};
    while (my @row = $sth->fetchrow_array) {
        print O "<$item>\n";
        my $i=0;
        for (@row) {
            next unless $row[$i];
            print O "   <$col_names[$i]>";
            print O "$row[$i]";
            print O "</$col_names[$i]>\n";
            $i++;
	}
        print O "</$item>\n\n";
    }
    print O $foot;
    close O || die "Couldn't write to $f_name: $!\n";
}

sub prep_xml_export {
    my $header     = shift || qq{<?xml version="1.0" ?>\n};
    my $record_tag = shift;
    my @tag_starts   = split ' ', $record_tag;
    my $terminal_tag = pop @tag_starts;
    my @tag_ends   = map("</$_>\n",reverse @tag_starts);
    @tag_starts = map("<$_>\n",@tag_starts);
    for (@tag_starts) { $header .= $_; }
    #print "   <$terminal_tag>\n";
    my $footer;
    for (@tag_ends) { $footer .= $_; }
    return($header,$terminal_tag,$footer);
}

sub convert() {
    my $dbh   = shift;
    my $specs = shift;
    my $source_type   = $specs->{source_type}   || '';
    my $source_file   = $specs->{source_file}   || '';
    my $source_params = $specs->{source_params} || '';
    my $target_type   = $specs->{target_type}   || '';
    my $target_file   = $specs->{target_file}   || '';
    my $temp_table    = 'temp__';
    my($dbh2,$sth1);
    $dbh->func( [
        ["${temp_table}2",$target_type,$target_file,$source_params],
    ],'catalog');
    if ($source_type eq 'DBI' ) {
        my @con_ary = @{$source_params->{connection_ary}};
        my $table = $source_params->{table};
        $dbh2 = DBI->connect( @con_ary );
        $sth1 = $dbh2->prepare("SELECT * FROM $table");
    }
    else {
        $dbh->func( [
            ["${temp_table}1",$source_type,$source_file,$source_params],
        ],'catalog');
        $sth1 = $dbh->prepare("SELECT * FROM ${temp_table}1");
    }
    $sth1->execute;
    my @col_names = @{$sth1->{NAME}};
    my $sth2 = &prep_insert( $dbh, "${temp_table}2", @col_names );
    while (my @row = $sth1->fetchrow_array) {
        $sth2->execute(@row);
    }
    if ($source_type eq 'DBI' ) { $dbh2->disconnect; }
}


sub import() {
    my $dbh   = shift;
    my $specs = shift;
    my $data  = shift;
    if ($specs && ! $data ) {
        if (ref $specs eq 'ARRAY' ) {
            $data = $specs; $specs = {};
        }
        else {
	    $data = [];
	}
    }
    if (ref $specs ne 'HASH') {
        die 'First argument to "import" must be a hashref.';
    }
    if (ref $data ne 'ARRAY') {
        die 'Second argument to "import" must be an arrayref.';
    }
    my $data_type  = uc $specs->{data_type}  || 'CSV';
    my $table_name = $specs->{table_name} || $dbh->func('get_table_name');
    my $col_names  = $specs->{col_names}  || '';
    my $pattern    = $specs->{pattern}    || '';
    my $read_sub   = $specs->{read_sub}     || '';
    my $write_sub   = $specs->{write_sub}     || '';
    my $data_source   = $specs->{data_source}     || '';
    my $file_source   = $specs->{file_source}     || '';
    my $remote_source = $specs->{remote_source}     || '';
    my $sep_char = $specs->{sep_char}     || '';
    my $eol = $specs->{eol}     || "\n";
    $DBD::RAM::ramdata->{catalog}{$table_name}->{r_type} = $data_type;
    if ($data_type eq 'FIXED'){ $data_type = 'FIX'; }
    if ($data_type eq 'PIPE') { $sep_char = '\s*\|\s*'; $data_type = 'CSV'; }
    if ($data_type eq 'TAB' ) { $sep_char = "\t"; $data_type = 'CSV'; }
    $DBD::RAM::ramdata->{catalog}{$table_name}->{sep_char} = $sep_char if $sep_char;
    $DBD::RAM::ramdata->{catalog}{$table_name}->{eol}      = $eol      if $eol;
    $DBD::RAM::ramdata->{catalog}{$table_name}->{pattern}  = $pattern  if $pattern;
    $DBD::RAM::ramdata->{catalog}{$table_name}->{read_sub}  = $read_sub if $read_sub;
    $DBD::RAM::ramdata->{catalog}{$table_name}->{write_sub}  = $write_sub if $write_sub;
    if ($data_type eq 'MP3' ) {
        $data_type = 'FIX';
        $col_names = 'file_name,song_name,artist,album,year,comment,genre',
        $pattern   = 'A255 A30 A30 A30 A4 A30 A50',
        $DBD::RAM::ramdata->{catalog}{$table_name}->{pattern} = $pattern;
        $data      = &get_music_library( $specs )
    }
    if ($data_type eq 'XML' ) {
        $data = $dbh->func( $specs, $table_name, 'get_xml_db' );
        return 1;
    }
    ####################################################################
    # DATA SOURCE
    ####################################################################
    #
    # DATA FROM REMOTE FILE
    #
    if ($remote_source) {
        $data = $dbh->func($remote_source,'get_remote_data') or return undef;
        $data = [split("\n",$data)]; # turn string into arrayref
    }
    #
    # DATA FROM LOCAL FILE
    #
    if ($file_source) {
        $data = &get_file_data($dbh,$file_source);
        $data = [split("\n",$data)]; # turn string into arrayref
    }
    #
    # DATA FROM DATA STRUCTURE
    #
    if ($data_source) {
        $data = $data_source;
    }
    my @col_names;
    if ($data_type eq 'DBI' ) {
        @col_names = @{$data->{NAME}};
        my $sth_new = &prep_insert( $dbh, $table_name, @col_names );
        while (my @datarow = $data->fetchrow_array) {
            $sth_new->execute(@datarow);
        }
        die "No data in table $table_name!" 
           unless $DBD::RAM::ramdata->{$table_name}->{DATA};
        return 1;
    }
    ####################################################################
    # GET COLUMN NAMES
    ####################################################################
    if (!ref $data) { my @tmp = split ( /$eol/m, $data ); $data = \@tmp; }
    my $first_line;
    if ($col_names eq 'first_line'
      && $data_type ne 'HASH' ) { $first_line = shift @{$data}; }
    else                        { $first_line = @{$data}->[0];  }
    @col_names = $dbh->func(
        $table_name,$data_type,$col_names,$first_line,
    'get_column_names');
    ####################################################################
    # CREATE TABLE & PREPARE INSERT STATEMENT
    ####################################################################
    my $sth = &prep_insert( $dbh, $table_name, @col_names );

    ####################################################################
    # INSERT DATA INTO TABLE
    ####################################################################
    if ('CSV FIX INI ARRAY HASH USR' =~ /$data_type/ ) {
        for ( @{$data} ) {
            my @datarow;
            if ( $data_type eq 'HASH')  {
                my %rowhash = %{$_};
                for (@col_names) {
                    my $val = $rowhash{$_} || '';
                    push @datarow, $val;
                }
            }
            else {
                @datarow = $dbh->func($_,$table_name,$data_type,'read_fields');
            }
            $sth->execute(@datarow);
        }
    }
    die "No data in table $table_name!" unless $DBD::RAM::ramdata->{$table_name}->{DATA};
    $DBD::RAM::ramdata->{$table_name}->{data_type} = $data_type;
    $DBD::RAM::ramdata->{$table_name}->{pattern}   = $pattern;
    $DBD::RAM::ramdata->{$table_name}->{read_sub}  = $read_sub;
    $DBD::RAM::ramdata->{$table_name}->{write_sub} = $write_sub;
    return 1;
}

####################################################################
# COLUMN NAMES
####################################################################
sub get_column_names {
    my($dbh,$table_name,$data_type,$col_names,$first_line) = @_;
    my $catalog = $DBD::RAM::ramdata->{catalog}{$table_name};
    my $pattern = $catalog->{pattern} || '';
    my $read_sub =  $catalog->{read_sub} || '';
    my($colstr,@col_names,$num_params);
    $colstr = '';
    #
    # COLUMN NAMES FROM FIRST LINE OF DATA
    #
    if ( $col_names eq 'first_line' && $data_type ne 'HASH' ) {
        @col_names = $dbh->func(
                $first_line,$table_name,$data_type,'read_fields');
        $num_params = scalar @col_names;
    }
    #
    # COLUMN NAMES FROM USER-SUPPLIED LIST
    #
    if ( $col_names && $col_names ne 'first_line' ) {
        $col_names  =~ s/\s+//g;
        @col_names  = split /,/,$col_names;
        $num_params = scalar @col_names;
    }
    #
    # AUTOMATICALLY ASSIGNED COLUMN NAMES
    #
    if ( $data_type eq 'HASH' && !$num_params ) {
        @col_names = keys %{$first_line};
        $num_params = scalar @col_names;
    }
    if ( !$num_params ) {
        if ( $data_type eq 'INI' ) {
            $num_params = 2;
	}
        if ( $data_type eq 'FIX' ) {
            my @x = split /\s+/,$pattern;
            $num_params = scalar @x;
	}
        if ( $data_type eq 'CSV' or $data_type eq 'USR' ) {
            my @colAry = $dbh->func(
                $first_line,$table_name,$data_type,'read_fields');
            $num_params = scalar @colAry;
	}
        $num_params = scalar @{ $first_line } if
            !$num_params && ref $first_line eq 'ARRAY';
        die "Couldn't find column names!" if !$num_params;
        for ( 1 .. $num_params ) { push(@col_names,"col$_"); }
    }
    return @col_names;
}

sub prep_insert {
    my( $dbh, $table_name, @col_names ) = @_;
    my($colstr,$num_params);
    for ( @col_names ) { $colstr .= $_ . ' TEXT,'; }
    $colstr =~ s/,$//;
    my $create_stmt = "CREATE TABLE $table_name ($colstr)";
    my $param_str = (join ",", ("?") x @col_names);
    my $insert_stmt = "INSERT INTO $table_name VALUES ($param_str)";
    $dbh->do($create_stmt);
    my $sth = $dbh->prepare($insert_stmt);
}


sub get_remote_data {
    my $dbh = shift;
    my $remote_source = shift;
    undef $@;
    eval{ require 'LWP/UserAgent.pm'; };
    die "LWP module not found! $@" if $@;
    my $ua   = new LWP::UserAgent;
    my $req  = new HTTP::Request GET => $remote_source;
    my $res  = $ua->request($req);
    die "[$remote_source] : " . $res->message if !$res->is_success;
    my $data = $res->content;
    return $data;
}

sub get_file_data {
    my $dbh         = shift;
    my $file_source = shift;
    $file_source = $dbh->{f_dir} . '/' .$file_source;
    $file_source =~ s#//#/#g;
    open(I,$file_source) || die "[$file_source]: $!\n";
    local $/ = undef;
    my $data = <I>;
    close(I)  || die "$file_source: $!\n";
    return $data;
}

sub get_xml_db {
# Hat tip to Randal Schwartz for the XML/LWP stuff
    my($dbh,$specs,$table_name) = @_;
    my $remote_source = $specs->{remote_source} || '';
    my $file_source   = $specs->{file_source} || '';
    my $data_source   = $specs->{data_source} || '';
    my $record_tag    = $specs->{record_tag} || '';
    my $col_tags      = $specs->{col_tags} || '';
    my $fold_col      = $specs->{fold_col} || '';
    my $col_mapping   = $specs->{col_mapping} || '';
    my $col_names     = $specs->{col_names} || '';
    my $read_sub      = $specs->{read_sub} || '';
    my $attr          = $specs->{attr}      || '';
    my $data;
    my @columns;
    if (ref $col_names ne 'ARRAY') { $col_names = [split ',',$col_names]; }
    for ( @{$col_names} ) {
      if ($_ =~ /^\[(.*)\]$/ ) {
         my @newCols = split ',', $1;
         for (@newCols) { push @columns, $_; }
      }
      else {
	   push @columns, $_;
      }
    }
    my $colstr;
    for ( @columns ) { $colstr .= $_ . ' TEXT,'; }
    $colstr =~ s/,$//;
    my $sql = "CREATE TABLE $table_name ($colstr)";
    $dbh->do($sql) || die DBI::errstr, " : $sql";
    $DBD::RAM::ramdata->{$table_name}->{data_type} = 'XML';
    if ($remote_source){$data = $dbh->func($remote_source,'get_remote_data') or die; }
    if ($file_source)   { $data = &get_file_data($dbh,$file_source); }
    if ($data_source)   { $data = $data_source; }
    die "No file or data source supplied!" unless $data;
    my $insert = $dbh->prepare("INSERT INTO $table_name (".
                              (join ", ", @columns).
                              ") VALUES (".
                              (join ",", ("?") x @columns).")");
    My_XML_Parser::doParse($data, $insert, $record_tag,
                           $col_names, $col_mapping,$fold_col,$attr,$read_sub);
    #use Data::Dumper; print Dumper $DBD::RAM::ramdata; exit;
}

sub read_fields {
    my $dbh   = shift;
    my $str   = shift;
    my $tname = shift;
    my $type  = uc shift;
    my $catalog = $dbh->func($tname,'get_catalog');
    if ($type eq 'ARRAY') {
        return @{$str};
    }
    chomp $str;
    if ($type eq 'CSV') {
        my $sep_char = $catalog->{sep_char} || ',';
        #my @fields =  Text::ParseWords::parse_line( $sep_char, 0, $str );
        my @fields =  &csv2ary( $sep_char, $str );
        return @fields;
    }
    if ($type eq 'USR') {
        my $read_sub = $catalog->{read_sub} || die "USR Type requires read_sub routine!\n";
        return &$read_sub($str);
    }
    if ($type eq 'FIX') {
	return unpack $catalog->{pattern}, $str;
    }
    if ($type eq 'INI') {
      if ( $str =~ /^([^=]+)=(.*)/ ) {
          my @fields = ($1,$2);
          return @fields;
      }
    }
    if ($type eq 'XML') {
      my @fields;
      $str =~ s#<[^>]*>([^<]*)<[^>]*>#
                my $x = $1 || '';
                push @fields, $x;
               #ge;
      return @fields;
    }
    return ();
}

sub ary2csv {
    my($field_sep,$record_sep,@ary)=@_;
    my $field_rsep = quotemeta($field_sep);
    my $str='';
    for (@ary) {
        $_ = '' if !defined $_;
        if ($field_sep eq ',') {
            s/"/""/g;
            s/^(.*)$/"$1"/s if /,/ or /\n/s or /"/;
	}
        $str .= $_ . $field_sep;
    }
    $str =~ s/$field_rsep$/$record_sep/;
    return $str;
}

sub csv2ary {
    my($field_sep,$str)=@_;
    # chomp $str;
    #$str =~ s/[\015\012]//g;
    $str =~ tr/\015\012//d;
    if ($field_sep ne ',') {
        #$field_sep = quotemeta($field_sep); LEFT UP TO USER TO DO
        return split($field_sep, $str);
    }
    $str =~ s/""/\\"/g;
    my @new = ();
    push(@new, $+ ) while $str =~ m{
         "([^\"\\]*(?:\\.[^\"\\]*)*)"$field_sep?
       | ([^$field_sep]+)$field_sep?
       | $field_sep
     }gx;
     push(@new, undef) if substr($str,-1,1) eq $field_sep;
     @new = map {my $x=$_; $x = '' if !defined $x; $x =~ s/\\"/"/g; $x;} @new;
     return @new;
}

sub write_fields {
    my($dbh,$fields,$tname,$type) = @_;
    my $catalog = $dbh->func($tname,'get_catalog');
    my $sep = $catalog->{sep_char} || ',';
    my $wsep = $catalog->{wsep_char} || $sep;
    my $fieldNum =0;
    my $fieldStr = $catalog->{pattern} || '';
    $fieldStr =~ s/a//gi;
    my @fieldLengths = split / /, $fieldStr;
    $fieldStr = '';
    if( $catalog->{f_type} eq 'USR' ) {
        my $write_sub = $catalog->{write_sub} || die "Requires write_sub!\n";
        my $fieldStr = &$write_sub(@{$fields});
        return $fieldStr;
    }
    if( $catalog->{f_type} eq 'XML' ) {
        my @col_names = split ',',$catalog->{col_names};
        my $count =0;
        for (@col_names) {
            $fieldStr .= "<$_>$fields->[$count]</$_>";
            $count++;
	}
        return $fieldStr;
    }
    for(@$fields) {
        # PAD OR TRUNCATE DATA TO FIT WITHIN FIELD LENGTHS
        if( $catalog->{f_type} eq 'FIX' ) {
            my $oldLen = length $_;
            my $newLen =  $fieldLengths[$fieldNum];
            if ($oldLen < $newLen) { $_ = sprintf "%-${newLen}s",$_; }
  	    if ($oldLen > $newLen) { $_ = substr $_, 0, $newLen; }
            $fieldNum++;
        }
        my $newCol = $_;
        if( $catalog->{f_type} eq 'CSV' ) {
             if ($newCol =~ /$sep/ ) {
                 $newCol =~ s/\042/\\\042/go;
                 $newCol = qq{"$newCol"};
	     }
             $fieldStr .= $newCol . $wsep;
        }
        else { $fieldStr .= $newCol; 	}
        if( $catalog->{f_type} eq 'INI' ) { $fieldStr .= '='; }
    }
    if( $catalog->{f_type} eq 'CSV' ) { $fieldStr =~ s/$sep$//; }
    if( $catalog->{f_type} eq 'INI' ) { $fieldStr =~ s/=$//; }
    return $fieldStr;
}

sub get_music_library {
    my $specs = shift;
    my @dirs = @{$specs->{dirs}};
    my @db;
    for my $dir(@dirs) {
        my @files = get_music_dir( $dir );
        for my $fname(@files) {
            push @db, &get_mp3_tag($fname)
        }
    }
    return \@db;
}

sub get_music_dir {
    my $dir  = shift;
    opendir(D,$dir) || print "$dir: $!\n";
    return '' if $!;
    my @files = grep /mp3$/i, readdir D;
    @files = map ( $_ = $dir . $_, @files);
    closedir(D) || print "Couldn't read '$dir':$!";
    return @files;
}

sub get_mp3_tag {
    my($file)   = shift;
    open(I,$file) || return '';
    binmode I;
    local $/ = '';
    seek I, -128, 2;
    my $str = <I> || '';
    return '' if !($str =~ /^TAG/);
    $file = sprintf("%-255s",$file);
    $str =~ s/^TAG(.*)/$file$1/;
    my $genre = $str;
    $genre =~ s/^.*(.)$/$1/g;
    $str =~ s/(.)$//g;
    $genre = unpack( 'C', $genre );
my @genres =("Blues", "Classic Rock", "Country", "Dance", "Disco", "Funk", "Grunge", "Hip-Hop", "Jazz", "Metal", "New Age", "Oldies", "Other", "Pop", "R&B", "Rap", "Reggae", "Rock", "Techno", "Industrial", "Alternative", "Ska", "Death Metal", "Pranks", "Soundtrack", "Eurotechno", "Ambient", "Trip-Hop", "Vocal", "Jazz+Funk", "Fusion", "Trance", "Classical", "Instrumental", "Acid", "House", "Game", "Sound Clip", "Gospel", "Noise", "Alternative Rock", "Bass", "Soul", "Punk", "Space", "Meditative", "Instrumental Pop", "Instrumental Rock", "Ethnic", "Gothic", "Darkwave", "Techno-Industrial", "Electronic", "Pop-Folk", "Eurodance", "Dream", "Southern Rock", "Comedy", "Cult", "Gangsta", "Top 40", "Christian Rap", "Pop/Funk", "Jungle", "Native American", "Cabaret", "New Wave", "Psychadelic", "Rave", "Show Tunes", "Trailer", "Lo-Fi", "Tribal", "Acid Punk", "Acid Jazz", "Polka", "Retro", "Musical", "Rock & Roll", "Hard Rock", "Folk", "Folk/Rock", "National Folk", "Swing", "Fast-Fusion", "Bebop", "Latin", "Revival", "Celtic", "Bluegrass", "Avantgarde", "Gothic Rock", "Progressive Rock", "Psychedelic Rock", "Symphonic Rock", "Slow Rock", "Big Band", "Chorus", "Easy Listening", "Acoustic", "Humour", "Speech", "Chanson", "Opera", "Chamber Music", "Sonata", "Symphony", "Booty Bass", "Primus", "Porn Groove", "Satire", "Slow Jam", "Club", "Tango", "Samba", "Folklore", "Ballad", "Power Ballad", "Rhytmic Soul", "Freestyle", "Duet", "Punk Rock", "Drum Solo", "Acapella", "Euro-House", "Dance Hall", "Goa", "Drum & Bass", "Club-House", "Hardcore", "Terror", "Indie", "BritPop", "Negerpunk", "Polsk Punk", "Beat", "Christian Gangsta Rap", "Heavy Metal", "Black Metal", "Crossover", "Contemporary Christian", "Christian Rock", "Unknown");
    $genre = $genres[$genre] || '';
    $str .= $genre . "\n";
    return $str;
}


# END OF DRIVER PRIVATE METHODS

sub table_info ($) {
	my($dbh) = @_;
        my @tables;
        for (keys %{$DBD::RAM::ramdata} ) {
             push(@tables, [undef, undef, $_, "TABLE", undef]);
	}
        my $names = ['TABLE_QUALIFIER', 'TABLE_OWNER', 'TABLE_NAME',
                     'TABLE_TYPE', 'REMARKS'];
 	my $dbh2 = $dbh->{'csv_sponge_driver'};
	if (!$dbh2) {
	    $dbh2 = $dbh->{'csv_sponge_driver'} = DBI->connect("DBI:Sponge:");
	    if (!$dbh2) {
	        DBI::set_err($dbh, 1, $DBI::errstr);
		return undef;
	    }
	}

	# Temporary kludge: DBD::Sponge dies if @tables is empty. :-(
	return undef if !@tables;

	my $sth = $dbh2->prepare("TABLE_INFO", { 'rows' => \@tables,
						 'NAMES' => $names });
	if (!$sth) {
	    DBI::set_err($dbh, 1, $dbh2->errstr());
	}
	$sth;
}

sub DESTROY { $DBD::RAM::ramdata = {};}

package DBD::RAM::st; # ====== STATEMENT ======

$DBD::RAM::st::imp_data_size = 0;
@DBD::RAM::st::ISA = qw(DBD::File::st);


package DBD::RAM::Statement;

#@DBD::RAM::Statement::ISA = qw(SQL::Statement);
@DBD::RAM::Statement::ISA = qw(SQL::Statement DBD::File::Statement);
#@DBD::RAM::Statement::ISA = qw(DBD::File::Statement);

sub open_table ($$$$$) {
    my($self, $data, $tname, $createMode, $lockMode) = @_;
    my($table);
    my $dbh     = $data->{Database};
    my $catalog = $dbh->func($tname,'get_catalog');
    my $ftype   = $catalog->{f_type} || '';
    if( !$catalog->{f_type} || $catalog->{f_type} eq 'RAM' ) {
        if ($createMode && !($DBD::RAM::ramdata->{$tname}) ) {
  	    if (exists($data->{$tname})) {
	        die "A table $tname already exists";
	    }
	    $table = $data->{$tname} = { 'DATA' => [],
				         'CURRENT_ROW' => 0,
				         'NAME' => $tname,
                                       };
	    bless($table, ref($self) . "::Table");
            $DBD::RAM::ramdata->{$tname} = $table;
            return $table;
        }
        else {
   	    $table = $DBD::RAM::ramdata->{$tname};
            die "No such table $tname" unless $table;
            $table->{'CURRENT_ROW'} = 0;
            return $table;
        }
    }
    else {
        my $file_name = $catalog->{f_name} || $tname;
        $table = $self->SUPER::open_table(
            $data, $file_name, $createMode, $lockMode
        );
        my $fh = $table->{'fh'};
        my $col_names = $catalog->{col_names} || '';
        my @col_names = ();
        if (!$createMode) {
            my $first_line = $fh->getline || '';
            #$first_line =~ s/[\015\012]//g;
            $first_line =~ tr/\015\012//d;
            @col_names = $dbh->func(
                $tname,$ftype,$col_names,$first_line,
            'get_column_names');
	}
        if ($col_names eq 'first_line' && !$createMode) {
            $table->{first_row_pos} = $fh->tell();
        }
        else {
	  seek $fh,0,0;
	}
        my $count = 0;
        my %col_nums;
        for (@col_names) { next unless $_; $col_nums{$_} = $count; $count++; }
        $table->{col_names} = \@col_names;
        $table->{col_nums}  = \%col_nums;
        $table->{'CURRENT_ROW'} = 0;
        $table->{NAME} = $tname;
        $table;
    }
}

package DBD::RAM::Statement::Table;

@DBD::RAM::Statement::Table::ISA = qw(DBD::RAM::Table);

package DBD::RAM::Table;

@DBD::RAM::Table::ISA = qw(SQL::Eval::Table);
#@DBD::RAM::Statement::Table::ISA = qw(SQL::Eval::Table DBD::File::Table);
#@DBD::RAM::Statement::Table::ISA = qw(DBD::File::Table);

##################################
# fetch_row()
# CALLED WITH "SELECT ... FETCH"
##################################
sub fetch_row ($$$) {
    my($self, $data, $row) = @_;
    my $dbh     = $data->{Database};
    my $tname   = $self->{NAME};
    my $catalog = $dbh->func($tname,'get_catalog');
    if( !$catalog->{f_type} || $catalog->{f_type} eq 'RAM' ) {
        my($currentRow) = $self->{'CURRENT_ROW'};
        if ($currentRow >= @{$self->{'DATA'}}) {
            return undef;
        }
        $self->{'CURRENT_ROW'} = $currentRow+1;
        $self->{'row'} = $self->{'DATA'}->[$currentRow];
        return $self->{row};
    }
    else {
        my $fields;
        if (exists($self->{cached_row})) {
  	    $fields = delete($self->{cached_row});
        } else {
	    local $/ = $catalog->{eol} || "\n";
	    #$fields = $csv->getline($self->{'fh'});
	    my $fh =  $self->{'fh'} ;
            my $line = $fh->getline || return undef;
            chomp $line;
            @$fields = $dbh->func($line,$tname,$catalog->{f_type},'read_fields');
	    # @$fields = unpack $dbh->{pattern}, $line;
            if ( $dbh->{ChopBlanks} ) {
                @$fields = map($_=&trim($_),@$fields);
	    }
	    if (!$fields ) {
	      die "Error while reading file " . $self->{'file'} . ": $!" if $!;
 	      return undef;
 	    }
        }
        $self->{row} = (@$fields ? $fields : undef);
    }
    return $self->{row};
}

sub trim { my $x=shift; $x =~ s/^\s+//; $x =~ s/\s+$//; $x; }

##############################
# push_names()
# CALLED WITH "CREATE TABLE"
##############################
sub push_names ($$$) {
    my($self, $data, $names) = @_;
    my $dbh     = $data->{Database};
    my $tname   = $self->{NAME};
    my $catalog = $dbh->func($tname,'get_catalog');
    if( !$catalog->{f_type} || $catalog->{f_type} eq 'RAM' ) {
        $self->{'col_names'} = $names;
        my($colNums) = {};
        for (my $i = 0;  $i < @$names;  $i++) {
  	    $colNums->{$names->[$i]} = $i;
        }
        $self->{'col_nums'} = $colNums;
    }
    elsif(!$catalog->{col_names}) {
        my $fh =  $self->{'fh'} ;
        my $colStr=$dbh->func($names,$tname,$catalog->{f_type},'write_fields');
        $colStr .= $catalog->{eol};
        $fh->print($colStr);
    }
}

################################
# push_rows()
# CALLED WITH "INSERT" & UPDATE
################################
sub push_row ($$$) {
    my($self, $data, $fields) = @_;
    my $dbh     = $data->{Database};
    my $tname   = $self->{NAME};
    my $catalog = $dbh->func($tname,'get_catalog');
    if( !$catalog->{f_type} || $catalog->{f_type} eq 'RAM' ) {
        my($currentRow) = $self->{'CURRENT_ROW'};
        $self->{'CURRENT_ROW'} = $currentRow+1;
        $self->{'DATA'}->[$currentRow] = $fields;
        return 1;
    }
    my $fh = $self->{'fh'};
    #
    #  Remove undef from the right end of the fields, so that at least
    #  in these cases undef is returned from FetchRow
    #
    while (@$fields  &&  !defined($fields->[$#$fields])) {
	pop @$fields;
    }
    my $fieldStr=$dbh->func($fields,$tname,$catalog->{f_type},'write_fields');
    $fh->print($fieldStr,$catalog->{eol});
    1;
}

sub seek ($$$$) {
    my($self, $data, $pos, $whence) = @_;
    my $dbh     = $data->{Database};
    my $tname   = $self->{NAME};
    my $catalog = $dbh->func($tname,'get_catalog');
    if( $catalog->{f_type} && $catalog->{f_type} ne 'RAM' ) {
        return DBD::File::Table::seek(
            $self, $data, $pos, $whence
        );
      }
    my($currentRow) = $self->{'CURRENT_ROW'};
    if ($whence == 0) {
	$currentRow = $pos;
    } elsif ($whence == 1) {
	$currentRow += $pos;
    } elsif ($whence == 2) {
	$currentRow = @{$self->{'DATA'}} + $pos;
    } else {
	die $self . "->seek: Illegal whence argument ($whence)";
    }
    if ($currentRow < 0) {
	die "Illegal row number: $currentRow";
    }
    $self->{'CURRENT_ROW'} = $currentRow;
}


sub drop ($$) {
    my($self, $data) = @_;
    my $dbh     = $data->{Database};
    my $tname   = $self->{NAME};
    my $catalog = $dbh->func($tname,'get_catalog');
    if( !$catalog->{f_type} || $catalog->{f_type} eq 'RAM' ) {
        my $table_name = $self->{NAME} || return;
        delete $DBD::RAM::ramdata->{$table_name}
               if $DBD::RAM::ramdata->{$table_name};
        delete $data->{$table_name}
               if $data->{$table_name};
        return 1;
    }
    return DBD::File::Table::drop( $self, $data );
}

##################################
# truncate()
# CALLED WITH "DELETE" & "UPDATE"
##################################
sub truncate ($$) {
    my($self, $data) = @_;
    my $dbh     = $data->{Database};
    my $tname   = $self->{NAME};
    my $catalog = $dbh->func($tname,'get_catalog');
    if( !$catalog->{f_type} || $catalog->{f_type} eq 'RAM' ) {
        $#{$self->{'DATA'}} = $self->{'CURRENT_ROW'} - 1;
        return 1;
    }
    return DBD::File::Table::truncate( $self, $data );
}

package My_XML_Parser;
  my @state;
  my %one_group_data;
  my $insert_handle;
  my $record_tag;
  my @columns;
  my %column_mapping;
  my $multi_field_count;
  my $fold_col;
  my $fold;
  my $fold_name;
  my %folds;
  my $read_sub;

  sub doParse {
    my $data = shift;
    $insert_handle = shift;
    $record_tag = shift;
    my $col_names = shift;
    my $col_map = shift || '';
    $fold_col = shift || {};
    my $attributes = shift || {};
    $read_sub = shift || '';
    if ($read_sub eq 'latin1' && !$attributes->{ProtocolEncoding} ) {
        $read_sub = \&utf8_to_latin1;
        $attributes->{ProtocolEncoding} = 'ISO-8859-1';
    } 
    @columns = @{$col_names};
    if ($col_map) { %column_mapping = %{$col_map}; }
    else {%column_mapping = map{ $_ => $_ } @columns; }
    undef $@;
    eval{ require 'XML/Parser.pm' };
    die "XML::Parser module not found! $@" if $@;
    XML::Parser->new( Style => 'Stream', %{$attributes} )->parse($data);
  }

  sub StartTag {
    my ($parser, $type) = @_;
    my %attrs = %_;
    push @state, $type;
    if ("@state" eq $record_tag) {
      %one_group_data = ();
      $multi_field_count = 0;
      while (my($k,$v)=each %folds) {
          $one_group_data{$k} = $v if $v;
      }
    }
    for (keys %{$fold_col}) {
        my $state = "@state";
        next unless $_ =~ /^$state\^*/;
        my $fold_tag = $fold_col->{$_} if $fold_col && $fold_col->{$_};
        if ( $fold_tag ) {
            $fold_name = $column_mapping{$fold_tag} if  $column_mapping{$fold_tag};
            $fold_name ||= $fold_tag;
            $fold = $attrs{$fold_tag} ||  '';
            $folds{$fold_name} = $fold;
    }
    }
    for (keys %attrs) {
        my $place = $column_mapping{$_};
        if (defined $place) {
          $one_group_data{$place} .= " " if $one_group_data{$place};
          $one_group_data{$place} .= &check_read( $attrs{$_} );
        }
    }
  }

  sub EndTag {
    my ($parser, $type) = @_;
    my $tag = "@state";
    $tag =~ s/^$record_tag\s*//;
    my $column = $column_mapping{$tag};
    if (ref $column eq 'ARRAY') {
        $multi_field_count++;
    }
    if ("@state" eq $record_tag) {
      $insert_handle->execute(@one_group_data{@columns});
    }
    pop @state;
  }

  sub Text {
    my $tag = "@state";
    $tag =~ s/^$record_tag\s*//;
    my $column = $column_mapping{$tag};
    if (ref $column eq 'ARRAY') {
        $one_group_data{$column->[$multi_field_count]} .= &check_read($_);
        return;
    }
    if (defined $column) {
      $one_group_data{$column} .= " " if $one_group_data{$column};
      $one_group_data{$column} .= &check_read($_);
    }
  }

  sub check_read {
      my $x = shift;
      $read_sub
         ? return &$read_sub($x)
         : return $x;
  }

  sub utf8_to_latin1 {
    local $_ = shift;
     s/([\xC0-\xDF])([\x80-\xBF])
      /chr(ord($1)<<6&0xC0|ord($2)&0x3F)
      /egx;
    return $_;
  }

############################################################################
1;
__END__


=head1 NAME

DBD::RAM - a DBI driver for files and data structures

=head1 SYNOPSIS

 use DBI;
 my $dbh = DBI->connect('DBI:RAM:','usr','pwd',{RaiseError=>1});
 $dbh->func({
    table_name  => 'my_phrases',
    col_names   => 'id,phrase',
    data_type   => 'PIPE',
    data_source => [<DATA>],
 }, 'import' );
 print $dbh->selectcol_arrayref(qq[
   SELECT phrase FROM my_phrases WHERE id = 1
 ])->[0];
 __END__
 1 | Hello, New World
 2 | Some other Phrase

This sample creates a database table from data, uses SQL to make a
selection from the database and prints out the results.  While this
table is in-memory only and uses pipe "delimited" formating, many
other options are available including local and remote file access and
many different data formats.


=head1 DESCRIPTION

DBD::RAM allows you to import almost any type of Perl data
structure into an in-memory table and then use DBI and SQL
to access and modify it.  It also allows direct access to
almost any kind of file, supporting SQL manipulation
of the file without converting the file out of its native
format.

The module allows you to prototype a database without having an rdbms
system or other database engine and can operate either with or without
creating or reading disk files.  If you do use disk files, they may,
in most cases, either be local files or any remote file accessible via
HTTP or FTP.

=head1 OVERVIEW

This modules allows you to work with a variety of data formats and to
treat them like standard DBI/SQL accessible databases.  Currently
supported formats include:

  FORMATS:

    XML    Extended Markup Language (XML)
    FIXED  fixed-width records
    INI    name=value pairs
    PIPE   pipe "delimited" text
    TAB    tab "delimited" text
    CSV    Comma Separated Values or other "delimited" text
    MP3    MP3 music binary files
    ARRAY  Perl array
    HASH   Perl associative array
    DBI    DBI database connection
    USR    user defined formats

The data you use may come form several kinds of sources: 

  SOURCES

    DATA         Perl data structures: strings, arrays, hashes
    LOCAL FILE   a file stored on your local computer hard disk
    REMOTE FILE  a remote file accessible via HTTP or FTP

If you modify the data in a table, the modifications may be stored in
several ways.  The storage can be temporary, i.e. in memory only with
no disk storage.  Or several modifications can be done in memory and
then stored to disk once at the end of the processing.  Or
modifications can be stored to disk continuously, similarly to the way
other DBDs operate.

  STORAGE

    RAM          in-memory processing only, no storage
    ONE-TIME     processed in memory, stored to disk on command
    CONTINUOUS   all modifications stored to disk as they occur

Here is a summary of the SOURCES, FORMATS, and STORAGE capabilities of
DBD::RAM. (x = currently supported, - = notsupported, * = support in
progress)

                                        FORMAT
                    CSV PIPE TAB FIXED INI XML MP3 ARRAY HASH DBI USR
INPUT
  array/hash/string  x    x   x    x    x   x   -    x     x   -   x
  local file         x    x   x    x    x   x   x    -     -   x   x
  remote file        x    x   x    x    x   x   *    -     -   *   x
OUTPUT
  ram table          x    x   x    x    x   x   x    x     x   x   x
  file (1-time)      x    x   x    x    x   x   -    -     -   *   *
  file (continuous)  x    x   x    x    x   *   -    -     -   x   *

Please note that any ram table, regardless of original source can be
stored in any of the supported file output formats.  So, for example,
a table of MP3 information could be stored as a CSV file, the "-" in
the MP3 column only indicates that the information from the MP3 table
can not (for obvious reasons) be written back to an MP3 file.

=head1 INSTALLATION & PREREQUISITES

This module should work on any any platform that DBI works on.

You don't need an external SQL engine or a running server, or a
compiler.  All you need are Perl itself and installed versions of DBI
and SQL::Statement. If you do not also have DBD::CSV installed you
will need to either install it, or simply copy File.pm into your DBD
directory.

You can either use the standard makefile method, or just copy RAM.pm
into your DBD directory.

Some features require installation of extra modules.  If you wish to
work with the XML format, you will need to install XML::Parser.  If
you wish to use the ability to work with remote files, you will need
to install the LWP (libnet) modules.  Other features of DBD::RAM work
fine without these additional modules.

=head1 SQL & DBI

This module, like other DBD database drivers, works with the DBI
methods listed in DBI.pm and its documentation.  Please see the DBI
documentation for details of methods such as connecting, preparing,
executing, and fetching data.  Currently only a limited subset of SQL
commands are supported.  Here is a brief synopsis, please see the
documentation for SQL::Statement for a more comple description of
these commands.

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


=head1 WORKING WITH FILES & TABLES: 

This module supports working with both in-memory and disk-based databases.  In order to allow quick testing and prototyping, the default behavior is for tables to be created in-memory from in-memory data but it is easy to change this behavior so that tables can also be created, manipulated, and stored on disk or so that there is a combination of in-memory and disk-based manipulation.  

There are three methods unique to the DBD::RAM module to allow you to specify which mode of operation you use for each table or operation:

 1) import()  imports data either from memory or from a file into an 
              in-memory table

 2) export()  exports data from an in-memory table to a file regardless of
              the original source of the data

 3) catalog() sets up an association between a file name and a table name
               such that all operations on the table are done continuously
               on the file

With the import() method, standard DBI/SQL commands like select,
update, delete, etc. apply only to the data that is in-memory.  If you
want to save the modifications to a file, you must explcitly call
export() after making the changes.

On the other hand, the catalog() method sets up an association between
a file and a tablename such that all DBI/SQL commands operate on the
file continuously without needing to explicitly call export().  This
method of operation is similar to other DBD drivers.

Here is a rough diagram of how the three methods operate:

   disk -> import() -> RAM

                       select
                       update
                       delete
                       insert
                       (multiple times)

   disk <- export() <- RAM

   catlog()
   disk <-> select
   disk <-> update
   disk <-> delete
   disk <-> insert   

Regardless of which method is chosen,  the same set of DBI and SQL commands may be applied to all tables.

See below for details of import(), export() and catalog() and for
specifics of naming files and directories.

=head2 Creating in-memory tables from data and files: import()

In-memory tables may be created using standard CREATE/INSERT
statements, or using the DBD::RAM specific import method:

    $dbh->func( $args, 'import' );

The $args parameter is a hashref which can contain several keys, most
of which are optional and/or which contain common defaults.

These keys can either be specified or left to default behaviour:

  table_name   string: name of the table
   col_names   string: column names for the table
   data_type   string: format of the data (e.g. XML, CSV...)

The table_name key to the import() method is either a string, or if 
it is omitted, a default table name will be automatically supplied, 
starting at table1, then table2, etc.

     table_name => 'my_test_db',

  OR simply omit the table_names key

If the col_names key to the import() method is omitted, the column
names will be automatically supplied, starting at col1, then col2,
etc.  If the col_names key is the string 'first_line', the column
names will be taken from the first line of the data.  If the col_names
key is a comma separated list of column names, those will be taken (in
order) as the names of the columns.

      col_names => 'first_line',

  OR  col_names => 'name,address,phone',

  OR  simply omit the col_names key

If table_name or col_names are specified, they must comply with SQL
naming rules for identifiers: start with an alphabetic character;
contain nothing but alphabetic characters, numbers, and/or
underscores; be less than 128 characters long; not be the same as a
SQL reserved keyword.  If the table refers to a file that has a period
in its name (e.g. my_data.csv), this can be handled with the catalog()
method, see below.

The table_name and col_names, if specified, *are* case sensititive, so
that "my_test_db" is not the same as "my_TEST_db".

The data_type key to the import() method specifies the format of the
data as already described above in the general description.  It must
be one of:

    data_type => 'CSV',
    data_type => 'TAB',
    data_type => 'PIPE',
    data_type => 'INI',
    data_type => 'FIXED',
    data_type => 'XML',
    data_type => 'MP3',
    data_type => 'DBI',
    data_type => 'USR',
    data_type => 'ARRAY',
    data_type => 'HASH',

  OR simply omit the data_type key

If no data_type key is supplied, the default format CSV will be used.

The import() keys must specify a source of the data for the table,
which can be any of:

    file_source   string: name of local file to get data from
  remote_source   string: url of remote file to get data from
    data_source   string or arrayref: the actual data

The file_source key is the name of local file.  It's location will be
taken to be relative to the f_dir specified in the database
connection, see the connect() method above.  Whether or not the file
name is case sensitive depends on the operating system the script is
running on e.g. on Windows case is ignored and on UNIX it is not
ignored.  For maximum portability, it is safest to assume that case
matters.

    file_source => 'my_test_db.csv'

The remote_source key is a URL (Uniform Resource Locator) to a file
located on some other computer.  It may be any kind of URL that is
supported by the LWP module includding http and FTP.  If username and
password are required, they can be included in the URL.

     remote_source => 'http://myhost.com/mypath/myfile.myext'

  OR remote_source => 'ftp://user:password@myhost.com/mypath/myfile.myext'

The data_source key to the import() tag contains the actual data for
the table.  in cases where the data comes from the Perl script itself,
rather than from a file.  The method of specifying the data_source
depends entirely on the format of the data_type.  For example with
data_type of XML or CSV, the data_source is a string in XML or CSV
format but with data_type ARRAY, the data_source is a reference to an
array of arrayrefs.  See below under each data_type for details.

The following keys to the import() method apply only to specific data
formats, see the sections on the specific formats (listed in parens)
for details:

        pattern   (FIXED only)
       sep_char   (CSV only)
            eol   (CSV only)
       read_sub   (USR and XML only)
           attr   (XML only)
     record_tag   (XML only)
       fold_col   (XML only)
    col_mapping   (XML only)
           dirs   (MP3 only)


=head2 Saving in-memory tables to disk: export()

The export() method creates a file from an in-memory table.  It takes
a very similar set of keys as does the import() method.  The data_type
key specifies the format of the file to be created (CSV, PIPE, TAB,
XML, FIXED-WIDTH, etc.).  The same set of specifiers available for the
import method for these various formats are also available
(e.g. sep_char to set the field separator for CSV files, or pattern to
set the fixed-width pattern).

The data_source key for the export() method is a SQL select statement
in relation to whatever in-memory table is chosen to export.  The
data_target key specifies the name of the file to put the results in.
Here is an example:

        $dbh->func( {
            data_source => 'SELECT * FROM table1',
            data_target => 'my_db.fix',
            data_type => 'FIXED',
            pattern   => 'A2 A19',
        },'export' );
               
That statement creates a fixed-width record database file called
"my_db.fix" and puts the entire contents of table1 into the file using
the specified field widths and whatever column names alread exist in
table1.

See specific data formats below for details related to the export() method.  

=head2 Continuous file access: catalog()

The catalog() method creates an association between a specific table
name, a specific data type, and a specific file name.  You can create
those associations for several files at once.  The parameter to the
catalog() method is a reference to an array of arrayrefs.  Each of the
arrayrefs should contain a table name, a data type, and a file name
and can optionally inlcude other paramtets specific to specific data
types.  Here is an example:

    $dbh->func([
        [ 'my_csv_table', 'CSV',   'test_db.csv'  ],
     ],'catalog');

This example creates an association to a CSV file.  Once the catalog()
statement has been issued, any DBI/SQL commands relating to
"my_csv_table" will operate on the file "test_db.csv".  If the command
is a SELECT statement, the file witll be opened and searched.  If the
command is an INSERT statement, the file will be opened and the new
data row(s) inserted and saved into the file.

One can also pass additional information such as column names,
fixed-width patterns, field and record separators to the export
method().  See the import() information above for the meanings of
these additional parameters.  They should be passed as a hashref:

    $dbh->func([
        [ 'table1', 'FIXED', 'test_db.fix',{pattern => 'A2 A19'} ],
        [ 'table2', 'INI',   'test_db.ini',{col_names => 'id,phrase,name' ],
     ],'catalog');

In future releases, users will be able to store catalogs in files for permanent associations between files and data types.

=head2 Specifying file and directory names

All filenames are relative to a user-specified file directory: f_dir.
The f_dir parameter may be set in the connect statement:

      my $dbh=DBI->connect("dbi:RAM:f_dir=/mypath/to-files/" ...

The f_dir parameter may also be set or reset anywhere in the program
after the database connection:

     $dbh->{f_dir} = '/mypath/to-files'

If the f_dir parameter is not set explicitly, it defaults to "./"
which will be wherever your script thinks it is running from (which,
depending on server setup may or may not be the physical location of
your script so use this only if you know what you are doing).

All filenames are relative to the f_dir directory.  It is not possible
to use an absolute path to a file.

WARNING: no taint checking is performed on the filename or f_dir, this
is the responsiblity of the programmer.  Since the filename is
relative to the f_dir directory, a filename starting with "../" will
lead to files above or outside of the f_dir directory so you should
exclude those from filenames if the filenames come from user input.

=head2 Using defaults for quick testing & prototyping

If no table_name is specified, a numbered table name will be supplied
(table1, or if that exists table2, etc.).  The same also applies to
column names (col1, col2, etc.).  If no data_type is supplied, CSV
will be assumed. If the entire hashref parameter to import is missing
and an arrayref of data is supplied instead, then defaults for all
values will be used, the source will be defaulted to data and the
contents of the array will be treated as the data source.  For CSV
file, a field separator of comma and a record separator of newline are
the default. Thus, assuming there are no already exiting in-memory
tables, the two statements below have the same effect:

    $dbh->func( [<DATA>], 'import' );

    $dbh->func({
        table_name  => 'table1',
        data_type   => 'CSV',
        col_names   => 'col1,col2',
        sep_char    => ',',
        eol         => "\n",
        data_source => [<DATA>],
    },'import' );

It is also possible to rely on some of the defaults, but not all of
them.  For example:

    $dbh->func({
        data_type   => 'PIPE',
        file_source => 'my_db.pipe',
    },'import' );

=head1 DATA FORMATS

=head2 CSV / PIPE / TAB / INI (Comma,Pipe,Tab,INI & other "delimited" formats)

DBD::RAM can import CSV (Comma Separated Values) from strings, from
local files, or from remote files into database tables and export
tables from any source to CSV files.  It can also store and update CSV
files continuously similarly to the way other DBD drivers operate.

If you wish to use remote CSV files, you also need the LWP module
installed. It is available from www.activestate.com for windows, and
from www.cpan.org for other platforms.

CSV is the format of files commonly exported by such programs as
Excel, Access, and FileMakerPro.  Typically newlines separate records
and commas separate fields.  Commas may also be included inside fields
if the field itself is surrounded by quotation marks.  Quotation marks
may be included in fields by doubling them.  Although some types of
CSV formats allow newlines inside fields, DBD::RAM does not currently
support that.  If you need that feature, you should use DBD::CSV.

Here are some typical CSV fields:

   hello,1,"testing, ""george"", 1,2,3",junk

Note that numbers and strings that don't contain commas do not need
quotation marks around them.  That line would be parsed into four
fields:

	hello
        1
        testing, "george", 1,2,3
        junk

To import that string of CSV into a DBD::RAM table:

  $dbh->func({ 
      data_source => qq[hello,1,"testing, ""george"", 1,2,3",junk]
  },'import');

Of if one wanted to continuously update a file similarly to the way
DBD::CSV works:

  $dbh->func([ 'table1', 'CSV',  'my_test.csv' ],'catalog');


Or if that string and others like it were in a local file called
'my_test.csv':

  $dbh->func({ file_source => 'my_test.csv' },'import');

Or if that string and others like it were in a remote file at a known
URL:

  $dbh->func({ remote_source => 'http://www.foo.edu/my_test.csv' },'import');

Note that these forms all use default behaviour since CSV is the
default data_type.  These methods also use the default table_name
(table1,table2,etc.) and default column_names (col1,col2, etc.).  The
same functions can specify a table_name and can either specify a list
of column names or specify that the column names should be taken from
the first line of data:

  $dbh->func({ 
      file_source => 'my_test.csv',
       table_name => 'my_table',
        col_names => 'name,phone,address',
   },'import');

It is also possible to define other field separators (e.g. a
semicolon) with the "sep_char" key and define other record separators
with the "eol" key.  For example:

   sep_char => ';',
   eol      => '~',

Adding those to the import() hash would define data that has a
semicolon between every field and a tilde between every record.

For convenience shortcuts have been provided for PIPE and TAB
separators. The data_type "PIPE" indicates a separator of the pipe
character '|' which may optionally have blank spaces before or afer
it.  The TAB data_type indicates fields that are separated by tabs.
In both cases newlines remain the default record separator unless
specifically set to something else.

Another shortcut is the INI data_type.  This expects to see data in
name=value pairs like this:

	resolution = 640x480
        colors     = 256

Currently the INI type does not support sections within the .ini file,
but that will change in future releases of this module.

The PIPE, TAB, and INI formats all behave like the CSV format.
Defaults may be used for assigning column names from the first line of
data, in which case the column names should be separated by the
appropriate symbol (e.g. col1|col2 for PIPE, and col1=col2 for INI,
and column names separated by tabs for TAB).

In the examples above using data_source the data was a string with
newlines separating the records.  It is also possible to use an
reference to an array of lines as the data_source.  This makes it
easy to use the DATA segment of a script or to import an array from
some other part of a script:

    $dbh->func({ data_source => [<DATA>] },'import' );

=head2 ARRAYS & HASHES

DBD::RAM can import data directly from references to arrays of
arrayrefs and references to arrays of hashrefs.  This allows you to
easily import data from some other portion of a perl script into a
database format and either save it to disk or simply manipulate it in
memory.

    $dbh->func({
        data_type   => 'ARRAY',
        data_source =>  [
           ['1','CSV:Hello New World!'],
           ['2','CSV:Cool!']
        ],
    },'import');

    $dbh->func({
        data_type   => 'HASH',
        data_source => [
            {id=>1,phrase=>'Hello new world!'},
            {id=>2,phrase=>'Junkity Junkity Junk'},
        ],
    },'import');


=head2 FIXED-WIDTH RECORDS

Fixed-width records (also called fixed-length records) do not use
character patterns to separate fields, rather they use a preset number
of characters in each field to determine where one field begins and
another ends.  DBD::RAM can import fixed-width records from strings,
arrayrefs, local files, and remote files and can export data from any
source to fixed-width record fields.  The module also allows
continuous disk-based updating of fixed-width format files similarly
to other DBDs.

The fixed-width format behaves exactly like the CSV formats mentioned
above with the exception that the data_type is "FIXED" and that one
must supply a pattern key to describe the width of the fields.  The
pattern should be in Perl unpack format e.g. "A2 A7 A14" would
indicate a table with three columns with widths of 2,7,14 characters.
When data is inserted or updated, it will be truncated or padded to
fill exactly the amount of space alloted to each field.

 $dbh->func({ 
     table_name => 'phrases',
     col_names  => 'id,phrase',
     data_type  => 'FIXED',
     pattern    => 'A1 A20',
     data_source => [ '1Hello new world!    ',
                      '2Junkity Junkity Junk',
                    ],
  },'import' );


=head2 XML

DBD::RAM can import XML (Extended Markup Language) from strings, from
local files, or from remote files into database tables and export
tables from any source to XML files.

You must have XML::Parser installed in order to use the XML feature of
DBD::RAM.  If you wish to use remote XML files, you also need the LWP
module installed.  Both are available from www.activestate.com for
windows, and from www.cpan.org for other platforms.

Support is provided for information in tag attributes and tag text and
for multiple levels of nested tags.  There are several options on how
to treat tag names that occur multiple times in a single record
including a variety of relationships between XML tags and database
columns: one-to-one, one-to-many, and many-to-one.  Tag attributes can
be made to apply to multiple records nested within the tag.  There is
also support for alternate character encodings and other XML::Parser
parameter attributes.

See below for details.

=over 4

=item XML Import

 To start with a very simple example, consider this XML string:

  <staff>
      <person name='Joe' title='bottle washer'/>
      <person name='Tom' title='flunky'/>
      <person name='Bev' title='chief cook'/>
      <person name='Sue' title='head honcho'/>
  </staff>

Assuming you have that XML structure in a variable $str, you can
import it into a DBD::RAM table like this:

  $dbh->func({
      data_source => $str
      data_type   => 'XML',
      record_tag  => 'staff person',
      col_names   => 'name,title'
  },'import');

Which would produce this SQL/DBI accessible table:

  name | title
  -----+--------------
  Joe  | bottle washer
  Tom  | flunky
  Bev  | chief cook
  Sue  | head honcho

If the XML data is in a local or remote file, rather than a string,
simply change the "data_source" to "file_source" (for local files) or
"remote_source" (for remote files) an everything else mentioned in
this section works the same as if the data was imported from a string.

Notice that the "record_tag" is a space separated list of all of the
tags that enclose the fields you want to capture starting at the
highest level with the <staff> tag.  In this example there is only one
level of nesting, but there could be many levels of nesting in actual
practice.

DBD::RAM can treat both text and tag attributes as fields. So the
following three records could produce the same database row:

      <person name='Tom' title='flunky'/>

      <person name='Tom'> 
         <title>flunky</title>
      </person>

      <person>
        <name>Tom</name>
        <title>flunky</title>
      </person>

The database column names should be specified as a comma-separated
string, in the order you want them to appear in the database:

       col_names => 'name,state,year'

If you want the database column names to be the same as the XML tag
names you do not need to do anything further.

NOTE: you *must* speficy the column names for XML data, you can not
rely on automatic default column names (col1,col2,etc.) or on reading
the column names from the "first line" of the data as you can with
most other data types.


=item Alternate relationships between XML tags & database columns

If you want the database column names to be different from the XML tag
names, you need to add a col_mapping parameter which should be a hash
with the XML tag as the key and the database column as the value:

       col_mapping => {
           name  => 'Member_Name',
           state => 'Location',
           year =>  'Year',
       }

       ('name' is the XML tag, 'Member_Name' is the database column)

If a given tag occurs more than once in an XML record, it can be
mapped onto a single column name (in which case all of the values for
it will be concatenated with spaces into the single column), or it can
be mapped onto an array of column names (in which case each succeeding
instance of the tag will be entered into the succeeding column in the
array).

For example, given this XML snippet:

  <person name='Joe' state='OR'>
      <year>1998</year>
      <year>1999</year>
  </person>
  <person name='Sally' state='WA'>
      <year>1998</year>
      <year>1999</year>
      <year>2000</year>
  </person>

This column mapping:

  col_mapping => {
      name  => 'Member_Name',
      state => 'Location',
      year =>  ['Year1','Year2','Year3'],
  }

Would produce this table:

  Member_Name | Location | Year1 | Year2 | Year3
  ------------+----------+-------+-------+------
  Joe         | OR       | 1998  | 1999  |
  Sally       | WA       | 1998  | 1999  | 2000

And this column mapping:

  col_mapping => {
      name  => 'Member_Name',
      state => 'Location',
      year =>  'Year',
  }

Would produce this table:

  Member_Name | Location | Year
  ------------+----------+----------------
  Joe         | OR       | 1998 1999
  Sally       | WA       | 1998 1999 2000

It is also possible to map several differnt tags into a single column,
e.g:

  <person name='Joe' state='OR'>
    <year1>1998</year1>
    <year2>1999</year2>
  </person>
  <person name='Sally' state='WA'>
     <year1>1998</year1>
     <year2>1999</year2>
     <year3>2000</year3>
  </person>

  col_mapping => {
      name  => 'Member_Name',
      state => 'Location',
      year1 => 'Year',
      year2 => 'Year',
      year3 => 'Year',
  }

  Member_Name | Location | Year
  ------------+----------+----------------
  Joe         | OR       | 1998 1999
  Sally       | WA       | 1998 1999 2000

=item Nested attributes that apply to multiple records

It is also possible to use nested record attributes to create column
values that apply to multiple records.  Consider the following XML:

  <staff>
    <office location='Portland'>
      <person name='Joe'>
      <person name='Tom'/>
    </office>
    <office location='Seattle'>
      <person name='Bev'/>
      <person name='Sue'/>
    </office>
  </staff>

One might like to associate the office location with all of the staff
members in that office. This is how that would be done:

    record_tag  => 'staff office person',
    col_names   => 'location,name',
    fold_col    => { 'staff office' => 'location' },

That fold-col specification in the import() method would "fold in"
the attribute for location and apply it to all records nested within
the office tag and produce the following table:

   location | name
   ---------+-----
   Portland | Joe
   Portland | Tom
   Seattle  | Bev
   Seattle  | Sue

You may use several levels of folded columns, for example, to capture
both the office location and title in this XML:

  <staff>
    <office location='Portland'>
      <title id='manager'>
        <person name='Joe'/>
      </title>
      <title id='flunky'>
        <person name='Tom'/>
      </title>
    </office>
    <office location='Seattle'>
      <title id='flunky'>
        <person name='Bev'/>
        <person name='Sue'/>
      </title>
    </office>
  </staff>

You would use this fold_col key:

    fold_col => { 'staff office'       => 'location',
                  'staff office title' => 'id',
                },

And obtain this table:

  location | title   | name
  ---------+---------+-----
  Portland | manager | Joe
  Portland | flunky  | Tom
  Seattle  | flunky  | Bev
  Seattle  | flunky  | Sue

If you need to grab more than one attribute from a single tag, you
need to put one or more carets (^) on the end of the fold_col key.
For example:

   <office type='branch' location='Portland' manager='Sue'> ...</office>

   fold_col => { 'office'   => 'branch',
                 'office^'  => 'location',
                 'office^^' => 'manager',

=item Character Encoding and Unicode issues

The attr key can be used to pass extra information to XML::Parser when
it imports a database.  For example, if the XML file contains latin-1
characters, one might like to pass the parser an encoding protocol
like this:

   attr => {ProtocolEncoding => 'ISO-8859-1'},

Attributes passed in this manner are passed straight to the
XML::Parser.

Since the results of XML::Parser are returned as UTF-8, one might also
like to translate from UTF-8 to something else when the data is
entered into the database.  This can be done by passing a pointer to a
subroutine in the read_sub key. For example:

    read_sub    => \&utf8_to_latin1,

For this to work, there would need to be a subroutine utf8_to_latin1
in the main module that takes a UTF8 string as input and returns a
latin-1 string as output.  Similar routines can be used to translate
the UTF8 characters into any other character encoding.

Apologies for being Euro-centric, but I have included a short-cut for
Latin-1.  One can omit the attr key and instead of passing a pointer
to a subroutine in the read_sub key, if one simply puts the string
"latin1", the module will automatically perform ISO-8859-1 protocol
encoding on reading the XML file and automatically translate from
UTF-8 to Latin-1 as the values are inserted in the database, that is
to say, a shortcut for the two keys mentioned above.


=item Other features of XML import

* Tags, attributes, and text that are not specifically referred to in
the import() parameters are ignored when creating the database table.

* If a column name is listed that is not mapped onto a tag that occurs
in the XML source, a column will be created in the database for that
name and it will be given a default value of NULL for each record
created.

=item XML Export

Any DBD::RAM table, regardless of its original source or its original
format, can be exported to an XML file.

The export() parameters are the same as for other types of export() --
see the above for details.  Additionally there are some export
parameters specific to XML files which are the same as the import()
parameters for XML files mentioned above.  The col_names parameter is
required, as is the record_tag parameter.  Additionally one may
optionally pass a header and/or a footer parameter which will be
material that goes above and below the records in the file.  If no
header is passed, a default header consisting of

   <?xml version="1.0" ?>

will be created at the top of the file.  

Given a datbase like this:

   location | name
   ---------+-----
   Portland | Joe
   Seattle  | Sue

And an export() call like this:

  $dbh->func({
      data_type   => 'XML',
      data_target => 'test_db.new.xml',
      data_source => 'SELECT * FROM table1',
      record_tag  => 'staff person',
      col_names   => 'name,location',
  },'export');

Would produce a file called 'test_db.xml' containing text like this:

  <?xml version="1.0" ?>
  <staff>
  <office>
  <person>
    <name>Joe</name>
    <location>Portland</location>
  </person>
  <person>
    <name>Sue</name>
    <location>Seattle</location>
  </person>
  </office>
  </staff>

The module does not currently support exporting tag attributes or
"folding out" nested column information, but those are planned for
future releases.

back

=head2 USER-DEFINED DATA STRUCTURES

DBD::RAM can be extended to handle almost any type of structured
information with the USR data type.  With this data type, you define a
subroutine that parses your data and pass that to the import() command
and the module will use that routine to create a database from your
data.  The routine can be as simple or as complex as you like.  It
must accept a string and return an array with the fields of the array
in the same order as the columns in your database.  Here is a simple
example that works with data separated by double tildes.  In reality,
you could just do this with the bulit-in CSV type, but here is how you
could recreate it with the USR type:

 $dbh->func({
      data_type   => 'USR',
      data_source => "1~~2~~3\n4~~5~~6\n",
      read_sub    => sub { split /~~/,shift },
 },'import' );

That would build a table with two rows of three fields each.  The
first row would contain the values 1,2,3 and the second row would
contain the values 4,5,6.

Here is a more complex example that handles a simplified address book.
It assumes that your data is a series of addresses separated by blank
lines and that the address has the name on the first line, the street
on the second line and the town, state, and zipcode on the third line.
(Apologies to those in countries that don't have states or zipcodes in
this format).  Here is an example of the kind of data it would handle:

    Fred Bloggs
    123 Somewhere Lane
    Sometown OR 97215

    Joe Blow
    567 Anywhere Street
    OtherTown WA 98006

Note that the end-of-line separator (eol) has been changed to be a
blank line rather than a simple newline and that the parsing routine
is more than a simple line by line parser, it splits the third line
into three fields for town, state, and zip.

  $dbh->func({
    data_type   => 'USR',
    data_source => join('',<DATA>),
    col_names   => 'name,street,town,state,zip',
    eol         => '^\s*\n',
    read_sub    => sub {
        my($name,$street,$stuff) = split "\n", $_[0];
        my @ary   = split ' ',$stuff;
        my $zip   = $ary[-1];
        my $state = $ary[-2];
        my $town  = $stuff;
        $town =~ s/^(.*)\s+$state\s+$zip$/$1/;
        return($name,$street,$town,$state,$zip);
      },
    },'import');

  Given the data above, this routine would create a table like this:

  name        | street              | town      | state | zip
  ------------+---------------------+-----------+-------+------
  Fred Bloggs | 123 Somewhere Lane  | Sometown  | OR    | 97215
  Joe Blow    | 567 Anywhere Street | OtherTown | WA    | 98006

These are just samples, the possiblities are fairly unlimited.

PLEASE NOTE: If you develop generally useful parser routines that
others might also be able to use, send them to me and I can
encorporate them into the DBD itself (with proper credit, of course).

=head2 DBI DATABASE RECORDS

You can import information from any other DBI accessible database with
the data_type set to 'DBI' in the import() method.  First connect to
the other database via DBI and get a database handle for it separate
from the database handle for DBD::RAM.  Then do a prepare and execute
to get a statement handle for a SELECT statement into that database.
Then pass the statement handle to the DBD::RAM import() method as the
data_source.  This will perform the fetch and insert the fetched
fields and records into the DBD::RAM table.  After the import()
statement, you can then close the database connection to the other
database if you are not going to be using it for anything else.

Here's an example using DBD::mysql --

 use DBI;
 my $dbh_ram   = DBI->connect('dbi:RAM:','','',{RaiseError=>1});
 my $dbh_mysql = DBI->connect('dbi:mysql:test','','',{RaiseError=>1});
 my $sth_mysql = $dbh_mysql->prepare("SELECT * FROM cars");
 $sth_mysql->execute;
 $dbh_ram->func({
     data_type   => 'DBI',
     data_source => $sth_mysql,
 },'import' );
 $dbh_mysql->disconnect;

=head2 MP3 MUSIC FILES

Most mp3 (mpeg three) music files contain a header describing the song
name, artist, and other information about the music.  This shortcut
will collect all of the header information in all mp3 files in a group
of directories and turn it into a searchable database:


 $dbh->func(
     { data_type => 'MP3', dirs => $dirlist }, 'import'
 );

 $dirlist should be a reference to an array of absolute paths to
 directories containing mp3 files.  Each file in those directories
 will become a record containing the fields:  file_name, song_name,
 artist, album, year, comment,genre. The fields will be filled
 in automatically from the ID3v1x header information in the mp3 file
 itself, assuming, of course, that the mp3 file contains a
 valid ID3v1x header.

=head1 USING MULTIPLE TABLES

A single script can create as many tables as your RAM will support and
you can have multiple statement handles open to the tables
simultaneously. This allows you to simulate joins and multi-table
operations by iterating over several statement handles at once.  You
can also mix and match databases of different formats, for example
gathering user info from .ini and .config files in many different
formats and putting them all into a single table.


=head1 TO DO

Lots of stuff.  Allow users to specify a file where catalog
information is stored so that one could record file types once and
thereafter automatically open the files with the correct data type. A
convert() function to go from one format to another. Support for a
variety of other easily parsed formats such as Mail files, web logs,
and for various DBM formats.  Support for HTML files with the
directory considered as a table, each HTML file considered as a record
and the filename, <TITLE> tag, and <BODY> tags considered as fields.
More robust SQL (coming when I update Statement.pm) including RLIKE (a
regex-based LIKE), joins, alter table, typed fields?, authorization
mechanisms?  transactions?  Allow remote exports (e.g. with LWP
POST/PUT).

Let me know what else...

=head1 AUTHOR

Jeff Zucker <jeff@vpservices.com>

Copyright (c) 2000 Jeff Zucker. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself as specified in the Perl README file.

No warranty of any kind is implied, use at your own risk.

=head1 SEE ALSO

 DBI, SQL::Statement, DBD::File

=cut
