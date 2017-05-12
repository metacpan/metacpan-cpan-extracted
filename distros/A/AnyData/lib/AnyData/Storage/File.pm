package AnyData::Storage::File;
use strict;
use warnings;
use IO::File;
use Fcntl qw(:flock);
use File::Basename;
use constant HAS_FLOCK => eval { flock STDOUT, 0; 1 };
use constant HAS_FILE_SPEC => eval { require File::Spec };
use vars qw($DEBUG);
$DEBUG = 0;


sub new {
    my $class = shift;
    my $self  = shift || {};
    #$self->{f_dir} ||= './';
    return bless $self, $class;
}

sub seek_first_record {
    my $self = shift;
    my $fh   = $self->{fh};
    my $start = $self->{first_row_pos};
    $start
        ? $fh->seek($start,0) || die $!
        : $fh->seek(0,0) || die $!;
}
sub get_pos { return shift->{fh}->tell }
sub go_pos  { my($s,$pos)=@_; $s->{fh}->seek($pos,0); }
my $open_table_re =
    HAS_FILE_SPEC ?
    sprintf('(?:%s|%s|%s)',
	    quotemeta(File::Spec->curdir()),
	    quotemeta(File::Spec->updir()),
	    quotemeta(File::Spec->rootdir()))
    : '(?:\.?\.)?\/';


sub open_local_file {
    my( $self,$file, $open_mode ) = @_;
    my $dir = $self->{f_dir} || './';
    my($fname,$path) = fileparse($file);
    my($foo2,$os_cur_dir) = fileparse('');
    my $haspath = 1 if $path and $path ne $os_cur_dir;
    if (!$haspath && $file !~ /^$open_table_re/o) {
	$file = HAS_FILE_SPEC
                ? File::Spec->catfile($dir, $file)
		: $dir . "/$file";
    }
    my $fh;
    $open_mode ||= 'r';
    my %valid_mode = (
    r  => q/read       read an existing file, fail if already exists/,
    u  => q/update     read & modify an existing file, fail if already exists/,
    c  => q/create     create a new file, fail if it already exists/,
    o  => q/overwrite  create a new file, overwrite if it already exists/,
    );
    my %mode = (
       r   => O_RDONLY,
       u   => O_RDWR,
       c   => O_CREAT | O_RDWR | O_EXCL,
       o   => O_CREAT | O_RDWR | O_TRUNC
    );
    my $help = qq(
       r  if file exists, get shared lock
       u  if file exists, get exclusive lock
       c  if file doesn't exist, get exclusive lock
       o  truncate if file exists, else create; get exclusive lock
    );
    if ( !$valid_mode{$open_mode} ) {
        print "\nBad open_mode '$open_mode'\nValid modes are :\n";

        for ('r','u','c','o'){
        print "   $_ = $valid_mode{$_}\n";
      }
        exit;
    }
    if ($open_mode eq 'c') {
	if (-f $file) {
	    die "Cannot create '$file': Already exists";
	}
    }
    if ($open_mode =~ /[co]/ ) {
	if (!($fh = IO::File->new( $file, $mode{$open_mode} ))) {
	    die "Cannot open '$file': $!";
	}
	if (!$fh->seek(0, 0)) {
	    die " Error while seeking back: $!";
	}
    }
    if ($open_mode =~ /[ru]/) {
	die "Cannot read file '$file': doesn't exist!" unless -f $file;
	if (!($fh = IO::File->new($file, $mode{$open_mode}))) {
	    die " Cannot open '$file': $!";
	}
    }
    binmode($fh);
    $fh->autoflush(1);
    if ( HAS_FLOCK ) {
	if ( $open_mode eq 'r') {
	    if (!flock($fh, LOCK_SH)) {
		die "Cannot obtain shared lock on '$file': $!";
	    }
	} else {
	    if (!flock($fh, LOCK_EX)) {
		die " Cannot obtain exclusive lock on '$file': $!";
	    }
	}
    }
    print "OPENING $file, mode = '$open_mode'\n" if $DEBUG;
    return( $file, $fh, $open_mode) if wantarray;
    return( $fh );
}

sub print_col_names {
    my($self,$parser,$col_names) = @_;
    my $fields = $col_names || $self->{col_names} || $parser->{col_names};
    return undef unless scalar @$fields;
    $self->{col_names} = $fields;
    return $fields if $parser->{keep_first_line};
    my $first_line = $self->get_record();
    my $fh         = $self->{fh};
    $self->seek_first_record;

    my $end = $parser->{record_sep} || "\n";
    my $colStr =  $parser->write_fields(@$fields);
    $colStr = join( ',',@$fields) . $end if ref($parser) =~ /Fixed/;
    $fh->write($colStr,length $colStr);
    $self->{first_row_pos} = $fh->tell();
}

sub get_col_names {
    my($self,$parser) = @_;
    my @fields = ();
    if ($parser->{keep_first_line}) {
        my $cols = $parser->{col_names};
        return undef unless $cols;
        return $cols if ref $cols eq 'ARRAY';
        @fields = split ',',$cols;
#die "@fields";
        return scalar @fields
           ? \@fields
           : undef;
    } 
    my $fh         = $self->{fh};
    $fh->seek(0,0) if $fh;
    my $first_line = $self->get_record($parser);
#print $first_line;
    if ( $first_line ) {
        @fields = ref($parser) =~ /Fixed/
            ? split /,/,$first_line
            : $parser->read_fields($first_line);
    }
#    my @fields = $first_line
#         ? $parser->read_fields($first_line)
#        : ();
#print "<$_>" for @fields; print "\n";
    return "CAN'T FIND COLUMN NAMES ON FIRST LINE OF '"
         . $self->{file}
         . "' : '@fields'" if "@fields" =~ /[^ a-zA-Z0-9_]/;
    $parser->{col_names}   = \@fields;
    $self->{col_names}     = \@fields;
    $self->{col_nums}      = $self->set_col_nums;
    $self->{first_row_pos} = $fh->tell();
    return( \@fields);
}
sub open_table {
    my( $self, $parser, $file, $open_mode ) = @_;
   my($newfile, $fh);
    $file ||= '';
    if ( $file =~ m'http://|ftp://' ) {
#       die "wrong storage!";
     $newfile = $file;
    }
    else {
     ($newfile,$fh) = 
       $self->open_local_file($file,$open_mode) if $file && !(ref $file);
      
    }
    $newfile ||= $file;
    #die AnyData::dump($parser);
    my $col_names = $parser->{col_names}  || '';
#    my @array = split(/,/,$col_names);

        my @array;
        @array = ref $col_names eq 'ARRAY'
          ? @$col_names
          : split ',',$col_names;

    my $pos = $fh->tell() if $fh;
    my %table = (
	file => $newfile,
	open_mode => $open_mode,
	fh => $fh,
	col_nums => {},
	col_names => \@array,
	first_row_pos => $pos
    );
    for my $key(keys %table) {
        $self->{$key}=$table{$key};
    }
    my $skip = $parser->init_parser($self);
    if (!$skip && defined $newfile) {
        $open_mode =~ /[co]/
            ? $self->print_col_names($parser)
            : $self->get_col_names($parser);
    }
    $self->{col_nums} = $self->set_col_nums();
    # use Data::Dumper; die Dumper $self;
}
sub get_file_handle    { return shift->{fh} }
sub get_file_name      { return shift->{file} }
sub get_file_open_mode { return shift->{open_mode} }

sub file2str { return shift->get_record(@_) }
sub get_record {
    my($self,$parser)=@_;
    local $/ =  $parser->{record_sep} || "\n";
    my $fh =  $self->{fh} ;
    my $record = $fh->getline || return undef;
    $record =~ s/\015$//g;
    $record =~ s/\012$//g;
    return $record;
}

sub set_col_nums {
    my $self = shift;
    my $col_names = $self->{col_names};
    return {} unless $col_names;
    my $col_nums={}; my $i=0;
    for (@$col_names) { 
        next unless $_;
        $col_nums->{$col_names->[$i]} = $i;
        $i++;
    }
    return $col_nums;
}

sub truncate {
    my $self = shift;
    if (!$self->{fh}->truncate($self->{fh}->tell())) {
        die "Error while truncating " . $self->{file} . ": $!";
     }
}

sub drop ($) {
    my($self) = @_;
    # We have to close the file before unlinking it: Some OS'es will
    # refuse the unlink otherwise.
    $self->{'fh'}->close() || die $!;
    unlink($self->{'file'}) || die $!;
    return 1;
}
sub close{ shift->{'fh'}->close() || die $!; }

sub push_row {
    my $self  = shift;
    my $rec   = shift;
    my $fh = $self->{fh};
    #####!!!! DON'T USE THIS ####    $fh->seek(0,2) or die $!;
    $fh->write($rec,length $rec)
         || die "Couldn't write to file: $!\n";
}

sub delete_record {
    my $self  = shift;
    my $parser  = shift || {};
    my $fh = $self->{fh};
    my $travel =  length($parser->{record_sep}) || 0;
    my $pos = $fh->tell - $travel;
    $self->{deleted}->{$pos}++;
}
sub is_deleted {
    my $self  = shift;
    my $parser  = shift || {};
    my $fh = $self->{fh};
    my $travel =  length($parser->{record_sep}) || 0;
    my $pos = $fh->tell - $travel;
    return $self->{deleted}->{$pos};
}
sub seek {
    my($self, $pos, $whence) = @_;
    if ($whence == 0  &&  $pos == 0) {
        $pos = $self->{first_row_pos};
    } elsif ($whence != 2  ||  $pos != 0) {
        die "Illegal seek position: pos = $pos, whence = $whence";
    }
    if (!$self->{fh}->seek($pos, $whence)) {
        die "Error while seeking in " . $self->{'file'} . ": $!";
    }
    #print "<$pos-$whence>";
}

sub DESTROY {
  my $self = shift;
  my $fh = $self->{fh};
  print "CLOSING ", $self->get_file_name, "\n" if $fh && $DEBUG;
  $fh->close if $fh;
}
__END__
