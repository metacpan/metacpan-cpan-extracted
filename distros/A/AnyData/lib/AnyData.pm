##################################################################
package AnyData;
###################################################################
#
#   This module is copyright (c), 2000 by Jeff Zucker
#   All rights reserved.
#
###################################################################
use strict;
use warnings;
require Exporter;
use AnyData::Storage::TiedHash;
use vars qw( @ISA @EXPORT $VERSION );
@ISA = qw(Exporter);
@EXPORT = qw(  adConvert adTie adRows adColumn adExport adDump adNames adFormats);
#@EXPORT = qw(  ad_fields adTable adErr adArray);

$VERSION = '0.12';

sub new {
   my $class   = shift;
   my $format  = shift;
   my $flags   = shift || {};
   my $del_marker = "\0";
   $format = 'CSV' if $format eq 'ARRAY';
   my $parser_name = 'AnyData/Format/' . $format . '.pm';
   eval { require $parser_name; };
   die "Error Opening File-Parser: $@" if $@;
   $parser_name =~ s#/#::#g;
   $parser_name =~ s#\.pm$##g;
    my $col_names = $flags->{col_names} || undef;
    if ($col_names) {
        my @cols;
        @cols = ref $col_names eq 'ARRAY'
          ? @$col_names
          : split ',',$col_names;
        $flags->{col_names} = \@cols;
   }
   $flags->{del_marker} = $del_marker;
   $flags->{records}   ||= $flags->{data};
   $flags->{field_sep} ||= $flags->{sep_char}   ||= $flags->{ad_sep_char};
   $flags->{quote}     ||= $flags->{quote_char} ||= $flags->{ad_quote_char};
   $flags->{escape}    ||= $flags->{escape_char}||= $flags->{ad_escape_char};
   $flags->{record_sep}||= $flags->{eol}        ||= $flags->{ad_eol};
   # $flags->{skip_first_row}
   my $parser    = $parser_name->new ($flags);
   if ($parser->{col_names} && !$col_names) {
        my @cols;
        @cols = ref $parser->{col_names} eq 'ARRAY'
          ? @{$parser->{col_names}}
          : split ',',$parser->{col_names};
        $flags->{col_names} = \@cols;
        $parser->{col_names} = \@cols;
   }
   my $storage_name = $flags->{storage}
                   || $parser->storage_type()
                   || 'File';
   $storage_name = "AnyData/Storage/$storage_name.pm";
   eval { require $storage_name; };
   die "Error Opening Storage Module: $@" if $@;
   $storage_name =~ s#/#::#g;
   $storage_name =~ s#\.pm$##g;
   my $storage   = new $storage_name({del_marker=>$del_marker,%$flags});
   if ($storage_name =~ 'PassThru') {
       $storage->{parser} = $parser;
       $parser->{del_marker} = "\0";
       $parser->{url} = $flags->{file} 
                      if $flags->{file} and $flags->{file} =~ /http:|ftp:/;
   }
   my $self = {
       storage => $storage,
       parser  => $parser,
   };
   return( bless($self,$class) );
}

sub adFormats {
    my @formats;
    for my $dir(@INC) {
        my $format_dir = "$dir/AnyData/Format";
        if ( -d $format_dir ) {
            local *D;
            opendir(D,$format_dir);
            @formats = grep {/\.pm$/} readdir(D);
            last;
        }
    }
    unshift @formats,'ARRAY';
    @formats = map {s/^(.*)\.pm$/$1/;$_} @formats;
    return @formats;
}

sub export {
    my $self=shift;
    my $fh   = $self->{storage}->{fh};
    my $mode = $self->{storage}->{open_mode} || 'r';
#    if ( $self->{parser}->{export_on_close}
#      && $self->{storage}->{fh}
#      && $mode ne 'r'
#     ){
      return $self->{parser}->export( $self->{storage}, @_ );
#    }
}
sub DESTROY {
    my $self=shift;
#    $self->export;
    $self->zpack;
    #print "AD DESTROYED ";
}
##########################################
# DBD STUFF
##########################################
# required only for DBD-AnyData
##########################################
sub prep_dbd_table {
    my $self       = shift;
    my $tname      = shift;
    my $createMode = shift;
    my $col_names;
    my $col_nums;
    my $first_row_pos;
    if (!$createMode) {
        $col_names     = $self->{storage}->get_col_names($self->{parser});
        $col_nums      = $self->{storage}->set_col_nums();
        $first_row_pos = $self->{storage}->{first_row_pos};
    }
    die "ERROR: No Column Names!:", $self->{storage}->{open_mode}
     if (!$col_names || !scalar @$col_names) 
     && 'ru' =~ $self->{storage}->{open_mode}
     && !$createMode eq 'o';
    my $table = {
        NAME          => $tname,
        DATA          => [],
        CURRENT_ROW   => 0,
        col_names     => $col_names,
        col_nums      => $col_nums,
        first_row_pos => $first_row_pos,
        fh            => $self->{storage}->get_file_handle,
        file          => $self->{storage}->get_file_name,
        ad            => $self,
    };
    #use Data::Dumper; print Dumper $table;
    return $table;
}
sub fetch_row   {
    my $self   = shift;
    my $requested_cols = shift || [];
    my $rec;
    if ( $self->{parser}->{skip_pattern} ) {
        my $found;
        while (!$found) {
            $rec = $self->{storage}->file2str($self->{parser},$requested_cols);
            last if !defined $rec;
            next if $rec =~ $self->{parser}->{skip_pattern};
            last;
	}
    }
    else {
        $rec = $self->{storage}->file2str($self->{parser},$requested_cols);
    }
    return $rec if ref $rec eq 'ARRAY';
    return unless $rec;
    my @fields = $self->{parser}->read_fields($rec);
    return undef if scalar @fields == 1 and !defined $fields[0];
    return \@fields;
}
sub fetch_rowNEW   {
    my $self   = shift;
    my $requested_cols = shift || [];
    my $rec    = $self->{storage}->file2str($self->{parser},$requested_cols);
    my @fields;
    if (ref $rec eq 'ARRAY') {
        @fields = @$rec;
    } 
    else {
        return unless defined $rec;
        my @fields = $self->{parser}->read_fields($rec);
        return undef if scalar @fields == 1 and !defined $fields[0];
    }
    if ( my $subs = $self->{parser}->{read_sub} ) {
        for (@$subs) {
            my($col,$sub) =  @$_;
            next unless defined $col;
            my $col_num = $self->{storage}->{col_nums}->{$col};
            next unless defined $col_num;
            $fields[$col_num] = &$sub($fields[$col_num]);
	}
      }
    return \@fields;
}
sub push_names {
    my $self = shift;
    my $col_names = shift || undef;
    #print "Can't find column names!" unless scalar @$col_names;
    $self->{storage}->print_col_names( $self->{parser}, $col_names )
         unless $self->{parser}->{col_names} && $self->parser_type ne 'XML';
    #    $self->set_col_nums;
    $self->{parser}->{key} ||= $col_names->[0];
    #use Data::Dumper; print Dumper $self; exit;
}
sub drop           { shift->{storage}->drop(@_); }
sub truncate       { shift->{storage}->truncate(@_) }

##################################################################
# END OF DBD STUFF
##################################################################

##################################################################
# REQUIRED BY BOTH DBD AND TIEDHASH
##################################################################
sub push_row {
    my $self = shift;
    die "ERROR: No Column Names!" unless scalar @{$self->col_names};
    my $requested_cols = [];
    my @row = @_;
    if (ref($row[0]) eq 'ARRAY') {
        $requested_cols = shift @row;
    }
    my $rec = $self->{parser}->write_fields(@row) or return undef;
    return $self->{storage}->push_row( $rec, $self->{parser}, $requested_cols);
}
sub push_rowNEW {
    my $self = shift;
    #print "PUSHING... ";
    die "ERROR: No Column Names!" unless scalar @{$self->col_names};
    my $requested_cols = [];
    my @row = @_;
    use Data::Dumper;
    #print "PUSHING ", Dumper \@row;
    if (ref($row[0]) eq 'ARRAY') {
        $requested_cols = shift @row;
    }
    my $rec = $self->{parser}->write_fields(@row) or return undef;
    return $self->{storage}->push_row( $rec, $self->{parser}, $requested_cols);
}
sub seek              { shift->{storage}->seek(@_); }
sub seek_first_record { 
    my $self=shift;
    $self->{storage}->seek_first_record($self->{parser});
}
sub col_names    {
    my $self = shift;
    my $c = $self->{storage}->{col_names};
    $c = $self->{parser}->{col_names} unless (ref $c eq 'ARRAY') and scalar @$c;
    $c ||= [];
}
sub is_url {
    my $file = shift;
    return $file if $file and $file =~ m"^http://|ftp://";
}

sub adTable {
    ###########################################################
    # Patch from Wes Hardaker
    ###########################################################
    # my($formatref,$file,$read_mode,$lockMode,$othflags)=@_;
    my($formatref,$file,$read_mode,$lockMode,$othflags,$tname)=@_;
    ###########################################################
    #use Data::Dumper; print Dumper \@_;
    my($format,$flags);
    $file ||= '';
    my $url = is_url($file);
    $flags = {};
    $othflags ||= {};
    if ( ref $formatref eq 'HASH' or $othflags->{data}) {
        $format = 'Base';
	$flags = $othflags;
        if (ref $formatref eq 'HASH') {
            %$flags  = (%$formatref,%$othflags);
	} 
   } 
   else {
      ($format,$flags) = split_params($formatref);
      $othflags ||= {};
      %$flags = (%$flags,%$othflags);
    }
    if ( $flags->{cols} ) {
        $flags->{col_names} = $flags->{cols};
        delete $flags->{cols};
    }
    if (ref($file) eq 'ARRAY') {
      if ($format eq 'Mp3' or $format eq 'FileSys') {
	 $flags->{dirs} = $file;
      } 
      else {
         $flags->{recs} = join '',@$file;
         $flags->{recs} = $file if $format =~ /ARRAY/i;
         $flags->{storage} = 'RAM' unless $format eq 'XML';
         $read_mode = 'u';
      }
    }
    else {
        $flags->{file} = $file;
    }
    if ($format ne 'XML' and ($format eq 'Base' or $url) ) {
        my $x;
        $flags->{storage} = 'RAM';
        delete $flags->{recs};
        my $ad = AnyData->new( $format, $flags);
        $format eq 'Base'
            ? $ad->open_table( $file )
            : $ad->open_table( $file,  'r',
                               $ad->{storage}->get_remote_data($file)
                             );
        return $ad;
    }
    my $ad = AnyData->new( $format, $flags);
    my $createMode = 0;
    $createMode = $read_mode if defined $lockMode;
    $read_mode   = 'c' if $createMode  and $lockMode;
    $read_mode   = 'u' if !$createMode and $lockMode;
    $read_mode ||= 'r';
    $ad->{parser}->{keep_first_line} = 1 
         if $flags->{col_names} and 'ru' =~ /$read_mode/;
    #####################################################
    # Patch from Wes Hardaker
    #####################################################
    # $ad->open_table( $file, $read_mode );
##    $ad->open_table( $file, $read_mode, $tname );
    $ad->open_table( $file, $read_mode, $tname );
#    use Data::Dumper; my $x = $ad; delete $x->{parser}->{twig}; delete $x->{parser}->{record_tag}; delete $x->{parser}->{current_element}; print Dumper $x;
    #####################################################
    return $ad;
}

sub open_table     {
    my $self = shift;
    $self->{storage}->open_table( $self->{parser}, @_ );
    my $col_names = $self->col_names();
    $self->{parser}->{key} ||= '';
    $self->{parser}->{key} ||= $col_names->[0] if $col_names->[0];
}
##################################################################


##################################################################
# TIEDHASH STUFF
##################################################################
sub key_col          { shift->{parser}->{key} }

sub fetchrow_hashref {
    my $self = shift;
    my $rec = $self->get_undeleted_record or return undef;
    my  @fields = ref $rec eq 'ARRAY'
            ? @$rec
            : $self->{parser}->read_fields($rec);
    my $col_names = $self->col_names();
    return undef unless scalar @fields;
    return undef if scalar @fields == 1 and !defined $fields[0];
    my $rowhash;
    @{$rowhash}{@$col_names} = @fields;
    return ( $rowhash );
}
sub get_undeleted_record {
    my $self = shift;
    my $rec;
    my $found=0;
    return $self->fetch_row if $self->parser_type eq 'XML';
    while (!$found) {
        my $test = $rec    = $self->{storage}->file2str($self->{parser});
        return  if !defined $rec;
        next if $self->{storage}->is_deleted($self->{parser});
        next if $self->{parser}->{skip_pattern} 
            and $rec =~ $self->{parser}->{skip_pattern};
        last;
    }
    return $rec;
#    return $rec if ref $rec eq 'ARRAY';
#    return unless $rec;
#    my @fields = $self->{parser}->read_fields($rec);
#    return undef if scalar @fields == 1 and !defined $fields[0];
#    return \@fields;
}
sub update_single_row {
    my $self     = shift;
    my $oldrow   = shift;
    my $newvals  = shift;
    my @colnames = @{ $self->col_names };
    my @newrow;
    my $requested_cols = [];
    for my $i(0..$#colnames) {
        push @$requested_cols, $colnames[$i] if defined $newvals->{$colnames[$i]};
        $newrow[$i] = $newvals->{$colnames[$i]};
        $newrow[$i] = $oldrow->{$colnames[$i]} unless defined $newrow[$i];
    }
    unshift @newrow, $requested_cols;
    $self->{storage}->seek(0,2);
    $self->push_row( @newrow );
    return \@newrow;
}
sub update_multiple_rows {
    my $self   = shift;
    my $key    = shift;
    my $values = shift;
    $self->seek_first_record;
    my @rows_to_update;
    while (my $row = $self->fetchrow_hashref) {
        next unless $self->match($row,$key);
        $self->{parser}->{has_update_function}
            ? $self->update_single_row($row,$values)
            : $self->delete_single_row();
        $self->{parser}->{has_update_function}
            ? push @rows_to_update,1
            : push @rows_to_update,$row;
    }
    if (!$self->{parser}->{has_update_function}) {
        for (@rows_to_update) {
           $self->update_single_row($_,$values);
	 }
    }
    return scalar @rows_to_update;
}
sub match {
    my($self,$row,$key) = @_;
    if ( ref $key ne 'HASH') {
        return 0 if !$row->{$self->key_col}
                 or  $row->{$self->key_col} ne $key;
        return 1;
    }
    my $found = 0;
    while (my($col,$re)=each %$key) {
        next unless defined $row->{$col} and is_matched($row->{$col},$re);
        $found++;
    }
    return 1 if $found == scalar keys %$key;
}
sub is_matched {
    my($str,$re)=@_;
    if (ref $re eq 'Regexp') {
        return $str =~ /$re/ ? 1 : 0;
    }
    my($op,$val);
    
    if ( $re and $re =~/^(\S*)\s+(.*)/ ) {
        $op  = $1;
        $val = $2;
    }
    elsif ($re) {
        return $str =~ /$re/ ? 1 : 0;
    }
    else {
        return $str eq '' ? 1 : 0;
    }
    my $numop = '< > == != <= >=';
    my $chrop = 'lt gt eq ne le ge';
    if (!($numop =~ /$op/) and !($chrop =~ /$op/)) {
        return $str =~ /$re/ ? 1 : 0;
    }
    if ($op eq '<' ) { return $str <  $val; }
    if ($op eq '>' ) { return $str >  $val; }
    if ($op eq '==') { return $str == $val; }
    if ($op eq '!=') { return $str != $val; }
    if ($op eq '<=') { return $str <= $val; }
    if ($op eq '>=') { return $str >= $val; }
    if ($op eq 'lt') { return $str lt $val; }
    if ($op eq 'gt') { return $str gt $val; }
    if ($op eq 'eq') { return $str eq $val; }
    if ($op eq 'ne') { return $str ne $val; }
    if ($op eq 'le') { return $str le $val; }
    if ($op eq 'ge') { return $str ge $val; }
}
sub delete_single_row {
    my $self = shift;
#    my $curpos = $self->{storage}->get_pos;
    $self->{storage}->delete_record($self->{parser});
#    $self->{storage}->go_pos($curpos);
    $self->{needs_packing}++;
}
sub delete_multiple_rows {
    my $self   = shift;
    my $key    = shift;
    $self->seek_first_record;
    my $rows_deleted =0;
    while (my $row = $self->fetchrow_hashref) {
        next unless $self->match($row,$key);
        $self->delete_single_row;
        $rows_deleted++;
    }
    return $rows_deleted;
}

sub adNames { @{ shift->{__colnames}} }

sub adDump {
    my $table = shift;
    my $pat   = shift;
    die "No table defined" unless $table;
    my $ad = tied(%$table)->{ad};
    my @cols = @{ $ad->col_names };
    print "<",join(":", @cols), ">\n";
    while (my $row = each %$table) {
        my @row  = map {defined $row->{$_} ? $row->{$_} : ''} @cols;
        for (@row) { print "[$_]"; }
        print  "\n";
    }
}

sub adRows {
    my $thash = shift;
    my %keys  = @_;
    my $obj   = tied(%$thash);
    return $obj->adRows(\%keys);
}
sub adColumn {
    my $thash  = shift;
    my $column = shift;
    my $flags = shift;
    my $obj    = tied(%$thash);
    return $obj->adColumn($column, $flags);
}
sub adArray {
    my($format,$data)=@_;
    my $t = adTie( $format, $data );
    my $t1 = tied(%$t);
    my $ad = $t1->{ad};
    my $arrayref = $ad->{storage}->{records};
    unshift @$arrayref, $ad->{storage}->{col_names};
    return $arrayref;
}
##################################################################
# END OF TIEDHASH STUFF
##################################################################
sub parser_type {
    my $type = ref shift->{parser};
    $type =~ s/AnyData::Format::(.*)/$1/;
    return $type;
}
sub zpack {
    my $self = shift;
    return if $self->{storage}->{no_pack};
    return if (ref $self->{storage} ) !~ /File$/;

#    return unless $self->{needs_packing};
#    $self->{needs_packing} = 0;
    return unless scalar(keys %{ $self->{storage}->{deleted} } );
    $self->{needs_packing} = 0;
    #    my @callA = caller 2;
    #    my @callB = caller 3;
    #    return if $callA[3] =~ /DBD/;
    #    return if $callB[3] and $callB[3] =~ /SQL::Statement/;
    #    return if $self->{parser}->{export_on_close};
    #print "PACKING";
    my $bak_file = $self->{storage}->get_file_name . '.bak';
    my $bak = adTable( 'Text', $bak_file, 'o' );
    my $bak_fh = $bak->{storage}->get_file_handle;
    my $fh     = $self->{storage}->get_file_handle;
    die "Can't pack to backup $!" unless $fh and $bak_fh;
    # $self->seek_first_record;
    $fh->seek(0,0) || die $!;
    #$bak_fh->seek(0,0) || die $!;
#    while (my $line = $self->get_record) {
#        next if $self->is_deleted($line);
    while (my $line = $self->get_undeleted_record) {
        my $tmpstr = $bak->{parser}->write_fields($line)
                   . $self->{parser}->{record_sep};
        $bak_fh->write($tmpstr,length $tmpstr);
    }
    $fh->seek(0,0);
    $fh->truncate(0) || die $!;
    $bak->seek_first_record;
    while (<$bak_fh>) {
        $fh->write($_,length $_);
    }
    $fh->close;
    $bak_fh->close;
    $self->{doing_pack} = 0;
    undef $self->{storage}->{deleted};
}

##########################################################
#  FUNCTION CALL INTERFACE
##########################################################
sub adTie {
    my($format,$file,$read_mode,$flags)=@_;
    my $data;
    if (ref $file eq 'ARRAY' && !$read_mode ) { $read_mode = 'u'; }
    # ARRAY only {data=>[]};
    if (scalar @_ == 1){
        $read_mode = 'o';
        tie %$data,
            'AnyData::Storage::TiedHash',
            adTable($format),
            $read_mode;
        return $data;
    }
    tie %$data,
        'AnyData::Storage::TiedHash',
        adTable($format,$file,$read_mode,undef,$flags),
        $read_mode;
    return $data;
}
sub adErr {
    my $hash = shift;
    my $t = tied(%$hash);
    my $errstr = $t->{ad}->{parser}->{errstr}
        || $t->{ad}->{storage}->{errstr};
    print $errstr if $errstr;
    return $errstr;
}
sub adExport {
    my $tiedhash  = shift;
    my($tformat,$tfile,$tflags)=@_;
    my $ad = tied(%$tiedhash)->{ad};
    my $sformat = ref $ad->{parser};
    $sformat =~ s/AnyData::Format:://;
    $tformat ||= $sformat;
    if ($tformat eq $sformat and $tformat eq 'XML') {
      return $ad->{parser}->export($ad->{storage},$tfile,$tflags);
    }
    return adConvert('adHash',$ad,$tformat,$tfile,undef,$tflags);
}
sub adConvert {
    my( $source_format, $source_data,
        $target_format,$target_file_name,
        $source_flags,$target_flags    )=@_;

    my $target_type = 'STRING';
       $target_type = 'FILE'  if defined $target_file_name;
       $target_type = 'ARRAY' if $target_format eq 'ARRAY';

    my $data_type = 'AD-OBJECT';
       $data_type = 'ARRAY'  if  ref $source_data eq 'ARRAY'
                            and  ref $source_data->[0] eq 'ARRAY';

    # INIT SOURCE OBJECT
    my $source_ad;
    if ($source_format eq 'adHash') {
        $source_ad = $source_data;
        undef $source_data;
    } 
    else {
        $source_format = 'CSV' if $source_format =~ /ARRAY/i;
        $source_ad = adTable(
             $source_format,$source_data,'r',undef,$source_flags
        );
    }

    # GET COLUMN NAMES
    my @cols;
    if ( $data_type eq 'ARRAY') {
        @cols = @{ shift @{ $source_data  } };
    }
    else {
        @cols = @{ $source_ad->col_names };
    }


    # insert storable here
    if ('XML HTMLtable' =~ /$target_format/) {
        $target_flags->{col_names} = join ',',@cols;
        my $target_ad = adTable(
            $target_format,$target_file_name,'o',undef,$target_flags
        );
        if ($data_type eq 'ARRAY' ) {
             for my $row(@$source_data) {
                 my @fields=$source_ad->str2ary($row);
                 $target_ad->push_row( $source_ad->str2ary(\@fields) );
             }
             unshift @$source_data, \@cols;
             return $target_ad->export($target_file_name);
        }
        $source_ad->seek_first_record;
        while (my $row = $source_ad->get_undeleted_record) {
            $target_ad->push_row( $source_ad->str2ary($row) );
        }
        return $target_ad->export($target_file_name);
    }

    my($target_ad,$fh);
    ### INIT TARGET OBJECT
    if ($target_type eq 'FILE') {
        $target_ad = adTable(
            $target_format,$target_file_name,'c',undef,$target_flags
        );
        $fh = $target_ad->{storage}->get_file_handle;
    }
    elsif ($target_type eq 'STRING') {
        $target_ad = AnyData->new( $target_format,$target_flags);
    }

    my($str,$aryref);
    ### GET COLUMN NAMES
    if ( !$target_ad->{parser}->{no_col_print} ) {
        if ($target_type eq 'ARRAY') {
            push @$aryref, \@cols;
        }
        else {
        $str = $target_ad->{parser}->write_fields(@cols);
        $str =~ s/ /,/g if $target_format eq 'Fixed';
        if ($target_type eq 'FILE') {
            $fh->write($str,length $str);
	}
        if ($target_type eq 'STRING') {
            $str = $target_ad->{parser}->write_fields(@cols);
	}
	}
    }

    # GET DATA
    if ($data_type eq 'ARRAY') {
      for my $row(@$source_data) {
        my @fields = $source_ad->str2ary($row);
        my $tmpstr = $target_ad->{parser}->write_fields(@fields);
        # print $tmpstr if $check;
        $fh->write($tmpstr,length $tmpstr) if $target_type eq 'FILE';
        $str .=  $tmpstr if $target_type eq 'STRING';
      }
      unshift @$source_data, \@cols;
      return $str if $target_format ne 'ARRAY';
      return $aryref;
    }
    $source_ad->seek_first_record; # unless $source_format eq 'XML';
    while (my $row = $source_ad->get_undeleted_record) {
        if ($target_format eq 'ARRAY') {
            push @$aryref,$row if $target_format eq 'ARRAY';
            next;
        }
        my @fields = $source_ad->str2ary($row);
        my $tmpstr = $target_ad->{parser}->write_fields(@fields);
        $str .= $target_type eq 'FILE'
           ? $fh->write($tmpstr,length $tmpstr)
           : $tmpstr;
    }
    return $str if $target_format ne 'ARRAY';
    return $aryref;
}

#    if ('Storable' =~ /$target_format/) {
#        $target_flags->{col_names} = join ',',@cols;
#        $target_ad = adTable(
#            $target_format,$target_file_name,'c',undef,$target_flags
#        );
#        if (ref $source_data && !$data) {
#            for my $row(@$source_data) {
#                push @$data,$row;
#            }
#        }
#        elsif (!$data) {
#            $source_ad->seek_first_record;
#            while (my $row = $source_ad->fetch_row) {
#                push @$data, $row;
#           }
#	}
#        unshift @$data, \@cols;
#        return $target_ad->{parser}->export($data,$target_file_name);
#  }

sub str2ary {
    my($ad,$row) = @_;
    return @$row if ref $row eq 'ARRAY';
    return $ad->{parser}->read_fields($row);
}
sub ad_string {
    my($formatref,@fields) = @_;
    my($format,$flags) = split_params($formatref);
# &dump($formatref); print "<$format>"; &dump($flags) if $flags;
    #$formatref =~ s/(.*)/$1/;
    my $ad = AnyData->new( $format, $flags );
    return $ad->{parser}->write_fields(@fields);
#    return $ad->write_fields(@fields);
}

sub ad_fields {
    my($formatref,$str,$flags) = @_;
#    my($format,$flags) = split_params($formatref);
#    my $ad = AnyData::new( $format, $flags );
    my $ad = AnyData->new( $formatref, $flags );
    return $ad->{parser}->read_fields($str);
}

sub ad_convert_str {
    my($source_formatref,$target_formatref,$str) = @_;
    my($source_format,$source_flags) = split_params($source_formatref);
    my($target_format,$target_flags) = split_params($target_formatref);
    my $source_ad = AnyData->new( $source_format,$source_flags);
    my $target_ad = AnyData->new( $target_format,$target_flags);
    my @fields = $source_ad->read_fields($str);
    return $target_ad->write_fields( @fields );
}

#########################################################
# UTILITY METHODS
#########################################################
#
# For all methods that have $format as a parameter,
# $format can be either a string name of a format e.g. 'CSV'
# or a hashref of the format and flags for that format e.g.
# { format => 'FixedWidth', pattern=>'A1 A3 A2' }
#
# given this parameter, this method returns $format and $flags
# setting $flags to {} if none are given
#
sub split_params {
    my $source_formatref = shift;
    my $source_flags = {};
    my $source_format  = $source_formatref;
    if (ref $source_formatref eq 'HASH') {
      while (my($k,$v)=each %$source_formatref) {
           ($source_format,$source_flags) = ($k,$v);
      }
    }
    #use Data::Dumper;
    return( $source_format, $source_flags);
}
sub dump {
    my $var = shift;
    my $name = ref($var);
    #use Data::Dumper;
    $Data::Dumper::Indent = 1;
    $Data::Dumper::Useqq  = 0;
    print Data::Dumper->new([$var],[$name])->Dump();
}

###########################################################################
# START OF DOCUMENTATION
###########################################################################

=pod

=head1 NAME

AnyData - (DEPRECATED) easy access to data in many formats

=head1 SYNOPSIS

 use AnyData;
 my $table = adTie( 'CSV','my_db.csv','o',            # create a table
                 {col_names=>'name,country,sex'}
               );
 $table->{Sue} = {country=>'de',sex=>'f'};         # insert a row
 delete $table->{Tom};                             # delete a single row
 $str  = $table->{Sue}->{country};                 # select a single value
 while ( my $row = each %$table ) {                # loop through table
   print $row->{name} if $row->{sex} eq 'f';
 }
 $rows = $table->{{age=>'> 25'}};                  # select multiple rows
 delete $table->{{country=>qr/us|mx|ca/}};         # delete multiple rows
 $table->{{country=>'Nz'}}={country=>'nz'};        # update multiple rows
 my $num = adRows( $table, age=>'< 25' );          # count matching rows
 my @names = adNames( $table );                    # get column names
 my @cars = adColumn( $table, 'cars' );            # group a column
 my @formats = adFormats();                        # list available parsers
 adExport( $table, $format, $file, $flags );       # save in specified format
 print adExport( $table, $format, $flags );        # print to screen in format
 print adDump($table);                             # dump table to screen
 undef $table;                                     # close the table

 #adConvert( $format1, $file1, $format2, $file2 );  # convert btwn formats
 #print adConvert( $format1, $file1, $format2 );    # convert to screen

=head1 DESCRIPTION

The rather wacky idea behind this module and its sister module
DBD::AnyData is that any data, regardless of source or format should
be accessible and modifiable with the same simple set of methods.
This module provides a multidimensional tied hash interface to data
in a dozen different formats. The DBD::AnyData module adds a DBI/SQL
interface for those same formats.

Both modules provide built-in protections including appropriate
flocking() for all I/O and (in most cases) record-at-a-time access to
files rather than slurping of entire files.

Currently supported formats include general format flat files (CSV,
Fixed Length, etc.), specific formats (passwd files, httpd logs,
etc.), and a variety of other kinds of formats (XML, Mp3, HTML
tables).  The number of supported formats will continue to grow
rapidly since there is an open API making it easy for any author to
create additional format parsers which can be plugged in to AnyData
itself and thereby be accessible by either the tiedhash or DBI/SQL
interface.

=head1 PREREQUISITES

The AnyData.pm module itself is pure Perl and does not depend on
anything other than modules that come standard with Perl.  Some
formats and some advanced features require additional modules: to use
the remote ftp/http features, you must have the LWP bundle installed;
to use the XML format, you must have XML::Parser and XML::Twig installed;
to use the HTMLtable format for reading, you must have HTML::Parser and
HTML::TableExtract installed but you can use the HTMLtable for writing
with just the standard CGI module.  To use DBI/SQL commands, you must have
DBI, DBD::AnyData, SQL::Statement and DBD::File installed.

=head1 USAGE

The AnyData module imports eight methods (functions):

=for test ignore

  adTie()     -- create a new table or open an existing table
  adExport()  -- save an existing table in a specified format
  adConvert() -- convert data in one format into another format
  adFormats() -- list available formats
  adNames()   -- get the column names of a table
  adRows()    -- get the number of rows in a table or query
  adDump()    -- display the data formatted as an array of rows
  adColumn()  -- group values in a single column

The adTie() command returns a special tied hash.  The tied hash can
then be used to access and/or modify data.  See below for details

With the exception of the XML, HTMLtable, and ARRAY formats, the
adTie() command saves all modifications of the data directly to file
as they are made.  With XML and HTMLtable, you must make your
modifications in memory and then explicitly save them to file with
adExport().

=head2 adTie()

 my $table = adTie( $format, $data, $open_mode, $flags );

The adTie() command creates a reference to a multidimensional tied hash. In its simplest form, it simply reads a file in a specified format into the tied hash:

 my $table = adTie( $format, $file );

$format is the name of any supported format 'CSV','Fixed','Passwd', etc.
$file is the name of a relative or absolute path to a local file

e.g. 
     my $table = adTie( 'CSV', '/usr/me/myfile.csv' );

this creates a tied hash called $table by reading data in the
CSV (comma separated values) format from the file 'myfile.csv'.

The hash reference resulting from adTie() can be accessed and modified as follows:

 use AnyData;
 my $table = adTie( $format, $file );
 $table->{$key}->{$column};                       # select a value
 $table->{$key} = {$col1=>$val1,$col2=>$val2...}; # update a row
 delete $table->{$key};                           # delete a row
 while(my $row = each %$table) {                  # loop through rows
   print $row->{$col1} if $row->{$col2} ne 'baz';
 }

The thing returned by adTie ($table in the example) is not an object,
it is a reference to a tied hash. This means that hash operations
such as exists, values, keys, may be used, keeping in mind that this
is a *reference* to a tied hash so the syntax would be

    for( keys %$table ) {...}
    for( values %$table ) {...}

Also keep in mind that if the table is really large, you probably do
not want to use keys and values because they create arrays in memory
containing data from every row in the table.  Instead use 'each' as
shown above since that cycles through the file one record at a time
and never puts the entire table into memory.

It is also possible to use more advanced searching on the hash, see "Multiple Row Operations" below.

In addition to the simple adTie($format,$file), there are other ways to specify additional information in the adTie() command.  The full syntax is:

 my $table = adTie( $format, $data, $open_mode, $flags );

 The $data parameter allows you to read data from remote files accessible by
 http or ftp, see "Using Remote Files" below.  It also allows you to treat
 strings and arrays as data sources without needing a file at all, see
 "Working with Strings and Arrays" below.

The optional $mode parameter defaults to 'r' if none is supplied or must be
one of

 'r' read      # read only access
 'u' update    # read/write access
 'c' create    # create a new file unless it already exists
 'o' overwrite # create a new file, overwriting any that already exist

The $flags parameter allows you to specify additional information such as column names.  See the sections in "Further Details" below.

With the exception of the XML, HTMLtable, and ARRAY formats, the
adTie() command saves all modifications of the data directly to file
as they are made.  With XML and HTMLtable, you must make your
modifications in memory and then explicitly save them to file with
adExport().

=head2 adConvert()

 adConvert( $format1, $data1, $format2, $file2, $flags1, $flags2 );

 or

 print adConvert( $format1, $data1, $format2, undef, $flags1, $flags2 );

 or

 my $aryref = adConvert( $format1, $data1, 'ARRAY', undef, $flags1 );

 This method converts data in any supported format into any other supported
 format.  The resulting data may either be saved to a file (if $file2 is
 supplied as a parameter) or sent back as  a string to e.g. print the data
 to the screen in the new format (if no $file2 is supplied), or sent back
 as an array reference if $format2 is 'ARRAY'.

 Some examples:

   # convert a CSV file into an XML file
   #
   adConvert('CSV','foo.csv','XML','foo.xml');

   # convert a CSV file into an HTML table and print it to the screen
   #
   print adConvert('CSV','foo.csv','HTMLtable');

   # convert an XML string into a CSV file
   #
   adConvert('XML', ["<x><motto id='perl'>TIMTOWTDI</motto></x>"],
             'CSV','foo.csv'
            );

   # convert an array reference into an XML file
   #
   adConvert('ARRAY', [['id','motto'],['perl','TIMTOWTDI']],
             'XML','foo.xml'
            );

   # convert an XML file into an array reference
   #
   my $aryref = adConvert('XML','foo.xml','ARRAY');

 See section below "Using strings and arrays" for details.

=head2 adExport()

 adExport( $table, $format, $file, $flags );

 or

 print adExport( $table, $format );

 or

 my $aryref = adExport( $table, 'ARRAY' );

 This method converts an existing tied hash into another format and/or
 saves the tied hash as a file in the specified format.

 Some examples:

   all assume a previous call to my $table= adTie(...);

   # export table to an XML file
   #
   adExport($table','XML','foo.xml');

   # export table to an HTML string and print it to the screen
   #
   print adExport($table,'HTMLtable');

   # export the table to an array reference
   #
   my $aryref = adExport($table,'ARRAY');

 See section below "Using strings and arrays" for details.

=head2 adNames()

 my $table = adTie(...);
 my @column_names = adNames($table);

This method returns an array of the column names for the specified table.

=head2 adRows()

 my $table = adTie(...);
 adRows( $table, %search_hash );

This method takes an AnyData tied hash created with adTie() and
counts the rows in the table that match the search hash.

For example, this snippet returns a count of the rows in the
file that contain the specified page in the request column

  my $hits = adTie( 'Weblog', 'access.log');
  print adRows( $hits , request => 'mypage.html' );

The search hash may contain multiple search criteria, see the
section on multiple row operations below.

If the search_hash is omitted, it returns a count of all rows.

=head2 adColumn()

 my @col_vals = adColumn( $table, $column_name, $distinct_flag );

This method returns an array of values taken from the specified column.
If there is a distinct_flag parameter, duplicates will be eliminated
from the list.

For example, this snippet returns a unique list of the values in
the 'player' column of the table.

  my $game = adTie( 'Pipe','games.db' );
  my @players  = adColumn( $game, 'player', 1 );

=head2 adDump()

  my $table = adTie(...);
  print adDump($table);

This method prints the raw data in the table.  Column names are printed inside angle brackets and separated by colons on the first line, then each row is printed as a list of values inside square brackets.

=head2 adFormats()

  print "$_\n for adFormats();

This method shows the available format parsers, e.g. 'CSV', 'XML', etc.  It looks in your @INC for the .../AnyData/Format directory and prints the names of format parsing files there.  If the parser requires further modules (e.g. XML requires XML::Parser) and you do not have the additional modules installed, the format will not work even if listed by this command.  Otherwise, all formats should work as described in this documentation.

=head1 FURTHER DETAILS

=head2 Column Names

Column names may be assigned in three ways:

 * pre  -- The format parser preassigns column
           names (e.g. Passwd files automatically have
           columns named 'username', 'homedir', 'GID', etc.).

 * user -- The user specifies the column names as a comma
           separated string associated with the key 'cols':

           my $table = adTie( $format,
                              $file,
                              $mode,
                              {cols=>'name,age,gender'}
                            );

 * auto -- If there is no preassigned list of column names
           and none defined by the user, the first line of
           the file is treated as a list of column names;
           the line is parsed according to the specific
           format (e.g. CSV column names are a comma-separated
           list, Tab column names are a tab separated list);

When creating a new file in a format that does not preassign
column names, the user *must* manually assign them as shown above.

Some formats have special rules for assigning column names (XML,Fixed,HTMLtable), see the sections below on those formats.

=head2 Key Columns

The AnyData modules support tables that have a single key column that
uniquely identifies each row as well as tables that do not have such
keys.  For tables where there is a unique key, that key may be assigned
in three ways:

 * pre --  The format parser automatically preassigns the
           key column name e.g. Passwd files automatically
           have 'username' as the key column.

 * user -- The user specifies the key column name:

           my $table = adTie( $format,
                              $file,
                              $mode,
                              {key=>'country'}
                            );

 * auto    If there is no preassigned key column and the user
           does not define one, the first column becomes the
           default key column

=head2 Format Specific Details

 For full details, see the documentation for AnyData::Format::Foo
 where Foo is any of the formats listed in the adFormats() command
 e.g. 'CSV', 'XML', etc.

 Included below are only some of the more important details of the
 specific parsers.

=over

=item Fixed Format

When using the Fixed format for fixed length records you
must always specify a pattern indicating the lengths of the fields.
This should be a string as would be passed to the unpack() function
to unpack the records in your Fixed length definition:

 my $t = adTie( 'Fixed', $file, 'r', {pattern=>'A3 A7 A9'} );

If you want the column names to appear on the first line of a Fixed
file, they should be in comma-separated format, not in Fixed format.
This is different from other formats which use their own format to
display the column names on the first line.  This is necessary because
the name of the column might be longer than the length of the column.

=item XML Format

 The XML format does not allow you to specify column names as a flag,
 rather you specify a "record_tag" and the column names are determined
 from the contents of the tag.  If no record_tag is specified, the
 record tag will be assumed to be the first child of the root of the
 XML tree.  That child and its structure will be determined from the
 DTD if there is one, or from the first occurring record if there is
 no DTD.

For simple XML, no flags are necessary:

 <table>
    <row row_id="1"><name>Joe</name><location>Seattle</location></row>
    <row row_id="2"><name>Sue</name><location>Portland</location></row>
 </table>

The record_tag will default to the first child, namely "row".  The column
names will be generated from the attributes of the record tag and all of
the tags included under the record tag, so the column names in this
example will be "row_id","name","location".

If the record_tag is not the first child, you will need to specify it.  For example:

 <db>
   <table table_id="1">
     <row row_id="1"><name>Joe</name><location>Seattle</location></row>
     <row row_id="2"><name>Sue</name><location>Portland</location></row>
   </table>
   <table table_id="2">
     <row row_id="1"><name>Bob</name><location>Boise</location></row>
     <row row_id="2"><name>Bev</name><location>Billings</location></row>
   </table>
 </db>

In this case you will need to specify "row" as the record_tag since it is not the first child of the tree.  The column names will be generated from the attributes of row's parent (if the parent is not the root), from row's attributes
and sub tags, i.e. "table_id","row_id","name","location".

When exporting XML, you can specify a DTD to control the output.  For example, if you import a table from CSV or from an Array, you can output as XML and specify which of the columns become tags and which become attributes and also specify the nesting of the tags in your DTD.

The XML format parser is built on top of Michel Rodriguez's excellent XML::Twig which is itself based on XML::Parser.  Parameters to either of those modules may be passed in the flags for adTie() and the other commands including the "prettyPrint" flag to specify how the output XML is displayed and things like ProtocolEncoding.  ProtocolEncoding defaults to 'ISO-8859-1', all other flags keep the defaults of XML::Twig and XML::Parser.  See the documentation of those modules for details;

 CAUTION: Unlike other formats, the XML format does not save changes to
 the file as they are entered, but only saves the changes when you explicitly
 request them to be saved with the adExport() command.

=item HTMLtable Format

 This format is based on Matt Sisk's excelletn HTML::TableExtract.

 It can be used to read an existing table from an html page, or to
 create a new HTML table from any data source.

 You may control which table in an HTML page is used with the column_names,
 depth and count flags.

 If a column_names flag is passed, the first table that contains those names
 as the cells in a row will be selected.

 If depth and or count parameters are passed, it will look for tables as
 specified in the HTML::TableExtract documentation.

 If none of column_names, depth, or count flags are passed, the first table
 encountered in the file will be the table selected and its first row will
 be used to determine the column names for the table.

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
 you will want to use adTie() to read the table and then adExport() to write
 the table to a different file.  When using the HTMLtable format, this is the
 only way to preserve changes to the data, the adTie() command will *not*
 write to a file.

=back

=head2 Multiple Row Operations

The AnyData hash returned by adTie() may use either single values as keys, or a reference to a hash of comparisons as a key.  If the key to the hash is a single value, the hash operates on a single row but if the key to the hash is itself a hash reference, the hash operates on a group of rows.

 my $num_deleted = delete $table->{Sue};

This example deletes a single row where the key column has the value 'Sue'.  If multiple rows have the value 'Sue' in that column, only the first is deleted.  It uses a simple string as a key, therefore it operates on only a single row.

 my $num_deleted = delete $table->{ {name=>'Sue'} };

This example deletes all rows where the column 'name' is equal to 'Sue'.  It uses a hashref as a key and therefore operates on multiple rows.

The hashref used in this example is a single column comparison but the hashref could also include multiple column comparisons.  This deletes all rows where the the values listed for the country, gender, and age columns are equal to those specified:

  my $num_deleted = delete $table->{{ country => 'us',
                                       gender => 'm',
                                          age => '25'
                                   }}


In addition to simple strings, the values may be specified as regular expressions or as numeric or alphabetic comparisons.  This will delete all North American males under the age of 25:

  my $num_deleted = delete $table->{{ country => qr/mx|us|ca/,
                                      gender  => 'm',
                                      age     => '< 25'
                                   }}

If numeric or alphabetic comparisons are used, they should be a string with the comparison operator separated from the value by a space, e.g. '> 4' or 'lt b'.

This kind of search hashref can be used not only to delete multiple rows, but also to update rows.  In fact you *must* use a hashref key in order to update your table.  Updating is the only operation that can not be done with a single string key.

The search hashref can be used with a select statement, in which case it returns a reference to an array of rows matching the criteria:

 my $male_players = $table->{{gender=>'m'}};
 for my $player( @$male_players ) { print $player->{name},"\n" }

This should be used with caution with a large table since it gathers all of the selected rows into an array in memory.  Again, 'each' is a much better way for large tables.  This accomplishes the same thing as the example above, but without ever pulling more than a row into memory at a time:

 while( my $row= each %$table ) {
   print $row->{name}, "\n" if $row->{gender}=>'m';
 }

Search criteria for multiple rows can also be used with the adRows() function:

  my $num_of_women = adRows( $table, gender => 'w' );

That does *not* pull the entire table into memory, it counts the rows a record at a time.

=head2 Using Remote Files

If the first file parameter of adTie() or adConvert() begins with "http://" or "ftp://", the file is treated as a remote URL and the LWP module is called behind the scenes to fetch the file.  If the files are in an area that requires authentication, that may be supplied in the $flags parameter.

For example:

  # read a remote file and access it via a tied hash
  #
  my $table = adTie( 'XML', 'http://www.foo.edu/bar.xml' );

  # same with username/password
  #
  my $table = ( 'XML', 'ftp://www.foo.edu/pub/bar.xml', 'r'
                { user => 'me', pass => 'x7dy4'
              );

  # read a remote file, convert it to an HTML table, and print it
  #
  print adConvert( 'XML', 'ftp://www.foo.edu/pub/bar.xml', 'HTMLtable' );

=head2 Using Strings and Arrays

Strings and arrays may be used as either the source of data input or as the target of data output.  Strings should be passed as the only element of an array reference (in other words, inside square brackets).  Arrays should be a reference to an array whose first element is a reference to an array of column names and whose succeeding elements are references to arrays of row values.

For example:

  my $table = adTie( 'XML', ["<x><motto id='perl'>TIMTOWTDI</motto></x>"] );

  This uses the XML format to parse the supplied string and returns a tied
  hash to the resulting table.


  my $table = adTie( 'ARRAY', [['id','motto'],['perl','TIMTOWTDI']] );

  This uses the column names "id" and "motto" and the supplied row values
  and returns a tied hash to the resulting table.

It is also possible to use an empty array to create a new empty tied hash in any format, for example:

  my $table = adTie('XML',[],'c');

  creates a new empty tied hash;

See adConvert() and adExport() for further examples of using strings and arrays.

=head2 Ties, Flocks, I/O, and Atomicity

AnyData provides flocking which works under the limitations of flock -- that it only works if other processes accessing the files are also using flock and only on platforms that support flock.  See the flock() man page for details.

Here is what the user supplied open modes actually do:

 r = read only  (LOCK_SH)  O_RDONLY
 u = update     (LOCK_EX)  O_RDWR
 c = create     (LOCK_EX)  O_CREAT | O_RDWR | O_EXCL
 o = overwrite  (LOCK_EX)  O_CREAT | O_RDWR | O_TRUNC

When you use something like "my $table = adTie(...)", it opens
the file with a lock and leaves the file and lock open until
1) the hash variable ($table) goes out of scope or 2) the
hash is undefined (e.g. "undef $table") or 3) the hash is
re-assigned to another tie.  In all cases the file is closed
and the lock released.

If adTie is called without creating a tied hash variable, the file
is closed and the lock released immediately after the call to adTie.

 For example:  print adTie('XML','foo.xml')->{main_office}->{phone}.

 That obtains a shared lock, opens the file, retrieves the one value
 requested, closes the file and releases the lock.

These two examples accomplish the same thing but the first example
opens the file once, does all of the deletions, keeping the exclusive
lock in place until they are all done, then closes the
file.  The second example opens and closes the file three times,
once for each deletion and releases the exclusive lock between each
deletion:

 1. my $t = adTie('Pipe','games.db','u');
    delete $t->{"user$_"} for (0..3);
    undef $t; # closes file and releases lock

 2. delete adTie('Pipe','games.db','u')->{"user$_"} for (0..3);
    # no undef needed since no hash variable created

=head2 Deletions and Packing

In order to save time and to prevent having to do writes anywhere except at the end of the file, deletions and updates are *not* done at the time of issuing a delete command.  Rather when the user does a delete, the position of the deleted record is stored in a hash and when the file is saved to disk, the deletions are only then physically removed by packing the entire database.  Updates are done by inserting the new record at the end of the file and marking the old record for deletion.  In the normal course of events, all of this should be transparent and you'll never need to worry about it.  However, if your server goes down after you've made updates or deletions but before you've saved the file, then the deleted rows will remain in the database and for updates there will be duplicate rows -- the old non updated row and the new updated row.  If you are worried about this kind of event, then use atomic deletes and updates as shown in the section above.  There's still a very small possibility of a crash in between the deletion and the save, but in this case it should impact at most a single row.  (BIG thanks to Matthew Wickline for suggestions on handling deletes)

=head1 MORE HELP

See the README file and the test.pl included with the module
for further examples.

See the AnyData/Format/*.pm PODs for further details of specific
formats.

For further support, please use comp.lang.perl.modules

=head1 ACKNOWLEDGEMENTS

Special thanks to Andy Duncan, Tom Lowery, Randal Schwartz, Michel Rodriguez, Jochen Wiedmann, Tim Bunce, Alligator Descartes, Mathew Persico, Chris Nandor, Malcom Cook and to many others on the DBI mailing lists and the clp* newsgroups.

=head1 AUTHOR & COPYRIGHT

 Jeff Zucker <jeff@vpservices.com>

 This module is copyright (c), 2000 by Jeff Zucker.
 Some changes (c) 2012 Sven Dowideit L<mailto:SvenDowideit@fosiki.com>
 It may be freely distributed under the same terms as Perl itself.

=cut

################################
# END OF AnyData
################################
1;
