#########################################################################
package AnyData::Storage::RAM;
#########################################################################
#
#   This module is copyright (c), 2000 by Jeff Zucker
#   All rights reserved.
#
#########################################################################

use strict;
use warnings;

use vars qw($VERSION $DEBUG);

$VERSION = '0.12';

$DEBUG   = 1;
use Data::Dumper;
use AnyData::Storage::File;

sub new {
    my $class = shift;
    my $self  = shift || {};
    return bless $self, $class;
}

########
# MOVE set_col_nums and open_table to Storage/Base.pm
#
# ALSO make DBD::AnyData::Statement and DBD::Table simple @ISA for AnyData 

sub set_col_nums {
    my $self = shift;
    my $col_names = $self->{col_names};
    return {} unless $col_names ;
    return {} unless ref $col_names eq 'ARRAY';
    return {} unless scalar @$col_names;
    my $col_nums={}; my $i=0;
    for (@$col_names) { next unless $_; $col_nums->{$_} = $i; $i++; }
    #use Data::Dumper; die Dumper $col_names;
    $self->{col_nums}=$col_nums;
    return $col_nums;
}
sub open_table {
    my( $self, $parser, $file, $read_mode, $data ) = @_;
    $data = $self->{recs} if $self->{recs};
    #$data ||= $parser->{recs};
    #$data = $file if ref $file eq 'ARRAY' and !$data;
 #use Data::Dumper; print Dumper $data;
#print ref $parser;

    my $rec_sep = $parser->{record_sep};# || "\n";
    my $table_ary = [];
    my $col_names = $parser->{col_names} || $self->{col_names};
    my $cols_supplied = $col_names;
    my $url = $file if $file =~ m"^http://|^ftp://";
    $self->{open_mode} = $read_mode || 'r';

    my $data_type;
    $data_type='ARY-ARY' if ref $data eq 'ARRAY' and ref $data->[0] eq 'ARRAY';
    $data_type='ARY-HSH' if ref $data eq 'ARRAY' and ref $data->[0] eq 'HASH';
    $data_type='ARY-STR' if ref $data eq 'ARRAY' and !$data_type;
    $data_type ||= 'STR';
    # print "[$data_type]" . ref $data if $data;
    # MP3 and ARRAY
    if ( $self->{records} && !$data )  {
         $table_ary = $self->{records};
         $col_names ||= shift @$table_ary;
    }

    # REMOTE
    elsif ( $data ) {
      if ($parser->{slurp_mode}) {
        ($table_ary,$col_names) = $parser->import($data,$self);
        shift @$table_ary if (ref $parser) =~ /HTMLtable/ && $url && $cols_supplied;
      }
      else {
        if ($data_type eq 'ARY-STR') {
              $data = join '', @$data;
	  }
        if ($data_type eq 'ARY-ARY') {
            $table_ary = $data;
        }
        elsif ($data_type eq 'ARY-HSH') {
            print "IMPORT OF HASHES NOT YET IMPLEMENTED!\n"; exit;
	}
        else {
            $data =~ s/\015$//gsm;  # ^M = CR from DOS
    	    #use Data::Dumper; print Dumper $data;
            my @tmp = split  /$rec_sep/, $data;
	    #use Data::Dumper; print ref $parser, Dumper \@tmp;
            if ((ref $parser) =~ /Fixed/ && (!$col_names or !scalar @$col_names)) {
                my $colstr = shift @tmp;
                # $colstr =~ s/\015$//g;  # ^M = CR from DOS
                @$col_names = split ',',$colstr;
	    }
            if ((ref $parser) =~ /Paragraph/) {
                my $colstr = shift @tmp;
                @$col_names = $parser->read_fields($colstr);
                #print "@$col_names";
	    }
            for my $line( @tmp ) {
                #        for (split  /$rec_sep/, $data) {
                #            s/\015$//g;  # ^M = CR from DOS
                next if $parser->{skip_pattern} and $line =~ $parser->{skip_pattern};
                my @row = $parser->read_fields($line);
                #print $_;
                #use Data::Dumper; print Dumper \@row;
###z MOD
 #               next unless scalar @row;
 #               push @$table_ary, \@row;
                 push @$table_ary, \@row
#                    unless $parser->{skip_mark}
#                       and $row[0] eq $parser->{skip_mark};
#
            }
        }
        if ((ref $parser) !~ /Fixed|Paragraph/ 
          && !$parser->{keep_first_line}
          && !$parser->{col_names}
           ) {
           $col_names = shift @$table_ary;
	 }
        #use Data::Dumper; die Dumper $table_ary;
      }
    }
#    if ($file and !(ref $file eq 'ARRAY') and $file !~ m'^http://|ftp://' and !(scalar @$table_ary) ) {
    if ((ref $parser) !~ /XML/ ) {
        my $size = scalar @$table_ary if defined $table_ary;
        if ($file and !(ref $file eq 'ARRAY') and !$size ) {
            if ($file =~ m'^http://|ftp://') {
                # ($table_ary,$col_names) =
                # $self->get_remote_data($file,$parser);
            }
            else {
                ($table_ary,$col_names) =
                    $self->get_local_data($file,$parser,$read_mode);
	    }
        }
    }
    my @array = @$col_names if ref $col_names eq 'ARRAY';
    #print "@array" if @array;
    if ($col_names && scalar @array == 0 ) {
         @array = (ref $parser =~ /Fixed/)
             ? split ',', $col_names
             : $parser->read_fields($col_names);
    }
    my $col_nums;
    $col_nums = $self->set_col_nums() if $col_names;
    my %table = (
        index => 0,
	file => $file,
	records => $table_ary,
	col_nums => $col_nums,
	col_names => \@array,
    );
    for my $key(keys %table) {
        $self->{$key}=$table{$key};
    }
    #use Data::Dumper; print Dumper $self; exit;
    #use Data::Dumper; print Dumper $table_ary;
    #use Data::Dumper; print Dumper $self->{records} if (ref $parser) =~ /Weblog/;
}
sub close { my $s = shift; undef $s }

sub get_remote_data {
    my $self   = shift;
    my $file   = shift;
    my $parser = shift;
    $ENV = {} unless defined $ENV;
    $^W = 0;
    undef $@;
    my $user = $self->{user} || $self->{username};
    my $pass = $self->{pass} || $self->{password};
    eval{ require 'LWP/UserAgent.pm'; };
#    eval{ require 'File/DosGlob.pm'; };
    die "LWP module not found! $@" if $@;
    my $ua   = LWP::UserAgent->new;
    my $req  = HTTP::Request->new(GET => $file);
    $req->authorization_basic($user, $pass) if $user and $pass;
    my $res  = $ua->request($req);
    die "[$file] : " . $res->message if !$res->is_success;
    $^W = 1;
    return $res->content;
#    return $parser->get_data($res->content,$self->{col_names});
}
sub export {
    my $self   = shift;
    my $parser = shift;
    print "##";
    return unless $parser->{export_on_close} && $self->{open_mode} ne 'r';
#    return $parser->export( $self->{records}, $self->{col_names}, $self->{deleted} );
    #$self->{file_manager}->str2file($str);
}

sub DESTROY {
   #shift->export;
   #print "DESTROY";
}

sub get_local_data {
    my $self      = shift;
    my $file      = shift;
    my $parser    = shift;
    my $open_mode = shift || 'r';
    my $adf  = AnyData::Storage::File->new;
#    $adf->open_table($parser,$file,'r');
 my $fh   = $adf->open_local_file($file,$open_mode);
#print Dumper $file,$adf; exit;
    $self->{file_manager} = $adf;
    $self->{fh} = $fh;
    #use Data::Dumper; print Dumper $self;
#    my $fh = $adf->{fh};
    return([],$self->{col_names}) if 'co' =~ /$open_mode/;
#    if ((ref $parser) =~ /HTML/) {
#      print "[[$file]]";
#      for (<$fh>) { print;  }
#    }
    local $/ = undef;
    my $str = <$fh>;
#    $fh->close;
#print $str if (ref $parser) =~ /HTML/;
    return $self->{col_names} unless $str;
    return $parser->get_data($str,$self->{col_names});
}
sub dump {
    my $self = shift;
    print
       "\nTotal Rows  = ", scalar @{ $self->{records} },
       "\nCurrent Row = ", $self->{index},
       "\nData        = ", Dumper $self->{records},
    ;
}

sub col_names { shift->{col_names} }
sub get_col_names {
    my $self=shift;
    my $parser=shift;
    my $c = $self->{col_names} || $parser->{col_names};
#print "###@$c";
#return $c;
#    if (!scalar @$c and $self->{data}) {
#        $c = shift @{$self->{data}};
#    }
#    return $c;
}
sub get_file_handle {''}
sub get_file_name {''}

sub seek_first_record { shift->{index}=0 }

sub get_pos { my $s=shift; $s->{CUR}= $s->{index}}
sub go_pos {my $s=shift;$s->{index}=$s->{CUR}}

sub is_deleted { my $s=shift; return $s->{deleted}->{$s->{index}-1} };

sub delete_record {
    my $self = shift;
#    $self->{records}->[ $self->{index}-1 ]->[-1] = $self->{del_marker};
    $self->{deleted}->{ $self->{index}-1 }++;
}

##################################
# fetch_row()
##################################
sub get_record {
    my($self,$parser) = @_;
    my $currentRow = $self->{index};
    return undef unless $self->{records} ;
    return undef if $currentRow >= @{ $self->{records} };
    $self->{index} = $currentRow+1;
    $self->get_pos($self->{index});
    #print  @{ $self->{records}->[ $currentRow ] };
    return $self->{records}->[ $currentRow ];
}
*file2str = \&get_record;


*write_fields = \&push_row;
####################################
# push_row()
####################################
sub push_row {
    my($self, $fields, $parser) = @_;
    if (! ref $fields) {
        $fields =~ s/\012$//;
        #chomp $fields;
        my @rec = $parser->read_fields($fields);
        $fields = \@rec;
    }

#use Data::Dumper; print Dumper $fields;
    my $currentRow = $self->{index};
    $self->{index} = $currentRow+1;
    $self->{records}->[$currentRow] = $fields;
    return 1;
}

##################################
# truncate()
##################################
sub truncate {
    my $self = shift;
    return splice @{$self->{records}}, $self->{index},1;
}

#####################################
# push_names()
#####################################
sub print_col_names {
    my($self, $parser, $names) = @_;
    $self->{col_names} = $names;
    $self->{parser}->{col_names} = $names;
    my($col_nums) = {};
    for (my $i = 0;  $i < @$names;  $i++) {
        $col_nums->{$names->[$i]} = $i;
    }
    $self->{col_nums} = $col_nums;
}

sub drop  {1;}
sub close_table {1;}

sub seek {
    my($self, $pos, $whence) = @_;
    return unless defined $self->{records};
    my($currentRow) = $self->{index};
    if ($whence == 0) {
        $currentRow = $pos;
    } elsif ($whence == 1) {
        $currentRow += $pos;
    } elsif ($whence == 2) {
        $currentRow = @{$self->{records}} + $pos;
    } else {
        die $self . "->seek: Illegal whence argument ($whence)";
    }
    if ($currentRow < 0) {
        die "Illegal row number: $currentRow";
    }
    $self->{index} = $currentRow;
}


############################################################################
1;
__END__
sub str2file {
    my($self,$rec)=@_;
    my @c = caller 3; 
    if ($c[3] =~ /DELETE/ or $c[3] =~ /UPDATE/) {
        $self->delete_record($rec);
        return undef if $c[3] =~ /DELETE/;
    } 
   push @{ $self->{table} }, $rec;
#    $self->{index}++;
    return $rec;
}

sub delete_record{my $self=shift;use Data::Dumper; print Dumper @_}

sub close {1;}

sub seek {
    my($self,$pos,$whence) = @_;
    if ($pos == 0 && $whence == 0) {
        $self->{index}=0;
        return $self->{index};
    }
    if ($pos == 0 && $whence == 2) {
        return $self->{index};
    }
}
sub truncate {}#use Data::Dumper; print Dumper \@_;}

1;
__END__

