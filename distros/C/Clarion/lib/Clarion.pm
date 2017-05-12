package Clarion;

use 5.006;
use strict;
use warnings;

use FileHandle;

our $VERSION = '1.02';

=head1 NAME

Clarion - Perl module for reading CLARION 2.1 data files

=head1 DESCRIPTION

This is a perl module to access CLARION 2.1 files.
At the moment only read access to the files is implemented.
"Encrypted" (owned) files are processed transparently,
there is no need to specify the password of a file.

=head1 SYNOPSIS

	use Clarion;

	my $dbh=new Clarion "customer.dat";

	print $dbh->file_struct;

	for ( 1 .. $dbh->last_record ) {
    		my $r=$dbh->get_record_hash($_);
		next if $r->{_DELETED};
	    	print $r->{CODE}." ".$r->{NAME}." ".$r->{PHONE}."\n";
	}

	$dbh->close();

=head1 METHODS

=over 4

=cut

sub FILLOCK { 0x01; }	# file is locked
sub FILOWN  { 0x02; }	# file is owned
sub FILCRYP { 0x04; }	# records are encrypted
sub FILMEMO { 0x08; }	# memo file exists
sub FILCOMP { 0x10; }	# file is compressed
sub FILRCLM { 0x20; }	# reclaim deleted records
sub FILREAD { 0x40; }	# file is read only
sub FILCRET { 0x80; }	# file may be created

sub RECNEW  { 0x01; }	# bit 0 - new record
sub RECOLD  { 0x02; }	# bit 1 - old record
sub RECREV  { 0x04; }	# bit 2 - revised record
sub RECDEL  { 0x10; }	# bit 4 - deleted record
sub RECHLD  { 0x40; }	# bit 6 - record held

=item $h=new Clarion ["file.dat" [, 1]]

Create object for reading Clarion file. If file name is specified then
associate the DAT file with the object. "Encrypted" files are processed 
transparently, you do not need to specify the password of a file.

If the third argument (skipMemo) specified, memo field will not be 
processed at all.

=cut

sub new {
 my $self={};
 bless $self, shift;

 $self->open(@_) if @_;
 return $self;
}

=item $h->close

Close all open file handles.

=cut

sub close {
 my $self=shift;
 if($self->{fh}) {
  $self->{fh}->close();
  delete $self->{fh};
 }
 if($self->{fhMemo}) {
  $self->{fhMemo}->close();
  delete $self->{fhMemo};
 }
}

sub DESTROY {
 shift->close;
}

=item $h->open('file.dat' [, 1])

Read and parse header of Clarion file. 

If second argument given, skip processing of memo field.

=cut

sub open {
 my ($self, $fileName, $skipMemo)=@_;

 my $fh=new FileHandle $fileName
	or die("Cannot open '$fileName': $!\n");
 binmode($fh);
 $self->{fh}=$fh;

 # Read file signature & header
 my ($filesig, $sfatr)=unpack('a2 S', $self->readData(4, 'header'));
 die "Not a Clarion 2.1 file '$fileName'!\n" 	if $filesig ne 'C3';
 $self->{name}=$fileName;
 $self->{sfatr}=$sfatr;
 my $header=$self->readData(2*9+31+9*4-4, 'header');
 
 # File is encrypted?
 if($sfatr & FILOWN) {	
# Looking for key; 4 variants exist
  $self->{Key}=[unpack('x8  CX2C', $header)];	# numdels, high word
#  $self->{Key}=[unpack('x68 CX2C', $header)];	# reserved, low word
#  $self->{Key}=[unpack('x70 CX2C', $header)];	# reserved, high word
#  $self->{Key}=[unpack('x68 CC', $header)];	# reserved, middle word
  $header=$self->decrypt($header);
 }

 # Parse header itself
 my @X=unpack('C L L S S S S L L L L A12 A12 A3 A3 S S L L L S', $header);
 foreach my $f(qw(numbkeys numrecs numdels numflds numpics nummars reclen offset
	logeof logbof freerec recname memnam filpre recpre memolen memowid
	reserved chgtime chgdate reserved2)) {
  $self->{header}{$f}=shift @X;
 }
 
 # Read field descriptions & build record template
 $self->{fields}=[];
 $self->{decimal_fields}=[];
 $self->{record}{unpack}='';
 $self->{record}{No}=0;
 for(my $i=0; $i<$self->{header}{numflds}; $i++) {
  @X=unpack('C A16 S S C C S S', $self->readData(3+16+2*4, 'field descriptor', 1));
  my $fd={};
  foreach my $f(qw(fldtype fldname foffset length decsig decdec arrnum picnum)) {
   $fd->{$f}=shift @X;
  }
  push @{$self->{fields}}, $fd;
  push @{$self->{decimal_fields}}, $fd	if 8==$fd->{fldtype};
  my $n=$fd->{fldname};
  $n=~s/^.+?://;
  $fd->{Name}=$n;
  $self->{field_map}{$n}=$fd->{No}=$i;
  my $c=qw(a l d A A C s G)[$fd->{fldtype}];
  $c='a'	unless $c;
  $c.=$fd->{length}	if uc($c)eq 'A';
  $c='a'.$fd->{length}.' X'.$fd->{length}.' '	if 'G' eq $c;
  $self->{record}{unpack}.=$c.' ';
 }

 # Read key descriptions
 $self->{keys}=[];
 for(my $i=$self->{header}{numbkeys}; $i>0; $i--) {
  @X=unpack('C A16 C C', $self->readData(1+16+1+1, 'key descriptor', 1));
  my $kd={};
  foreach my $f(qw(numcomps keynams comptype complen)) {
   $kd->{$f}=shift @X;
  }
  push @{$self->{keys}}, $kd;

  # Read key parts
  $kd->{parts}=[];
  for(my $j=$kd->{numcomps}; $j>0; $j--) {
   @X=unpack('C S S C', $self->readData(1+2+2+1, 'key element', 1));
   my $kp={};
   foreach my $f(qw(fldtype fldnum elmoff elmlen)) {
    $kp->{$f}=shift @X;
   }
   push @{$kd->{parts}}, $kp;
  }
 }

 return	if defined($skipMemo) or !($sfatr & FILMEMO);
 # Reading memo...
 $fileName=~s/\.[^\.\\\/]*$//;
 $fileName.='.mem';
 $fh=new FileHandle $fileName
	or die("Cannot open memo '$fileName': $!\n");
 binmode($fh);
 $self->{fhMemo}=$fh;

 # Read memo file signature
 read($fh, $filesig, 2);
 die "Not a Clarion 2.1 memo '$fileName'!\n" 	if $filesig ne 'M3';
 my $m={
  isMemo=>1,
  No=>scalar @{$self->{fields}},
  Name=>$self->{header}{memnam},
  fldname=>$self->{header}{memnam}.':'.$self->{header}{filpre},
  length=>$self->{header}{memolen},
 };
 push @{$self->{fields}}, $m;
 $self->{field_map}{$m->{Name}}=$m->{No};
}

=item $n=$dbh->last_record;

Returns the number of records in the database file.

=cut

sub last_record {
 return shift->{header}{numrecs};
}

=item $n=$dbh->bof;

Returns the physical number of first logical record.

=cut

sub bof {
 return shift->{header}{logbof};
}

=item $n=$dbh->eof;

Returns the physical number of last logical record.

=cut

sub eof {
 return shift->{header}{logeof};
}

# Internal function to read a record

sub readRecord {
 my ($self, $n)=@_;
 $n||=$self->{record}{No}+1;
 return	if $n<1 or $n>$self->{header}{numrecs};
 $self->{record}{data}=[];
 $self->{record}{No}=$n;
 seek($self->{fh}, $self->{header}{offset}+$self->{header}{reclen}*($n-1), 0);

 ($self->{record}{rhd}, $self->{record}{rptr})=unpack('C L', $self->readData(5, 'record'));
 my @Data=unpack($self->{record}{unpack},
  $self->readData($self->{header}{reclen}-5, 'record', $self->{sfatr} & FILCRYP));

 # Convert decimal() fields, if any
 foreach my $f(@{$self->{decimal_fields}}) {
  $Data[$f->{No}]=unpackBCD($Data[$f->{No}], $f->{decsig}, $f->{decdec});
 }
 $self->{record}{data}=\@Data;

 return 1	unless $self->{fhMemo};

# Read memo...
 my $memo;
 $n=($self->{record}{rhd} & RECDEL)? 0 : $self->{record}{rptr};
 while($n) {
  seek($self->{fhMemo}, ($n-1)*256+6, 0);
  $n=unpack('L', $self->readMemo(4));
  my $m=$self->readMemo(252);
  $m=$self->decrypt($m)	if $self->{sfatr} & FILCRYP;
  $memo=''	unless defined($memo);
  $memo.=$m;
 }
 $memo=~s/( +|\00+)\z//	if $memo;
 push @Data, $memo;

 return 1;
}

=item @r=$dbh->get_record([ $n [, @fields]]);

Returns a list of data (field values) from the specified record.
The first parameter in the call is the number of the physical
record. If you do not specify any other parameters, all fields are
returned in the same order as they appear in the file. You can also
put list of field names after the record number and then only those
will be returned. The first value of the returned list is always the
logical (0 or not 0) value saying whether the record is deleted or not.

If first argument is omited (or undef) then reads next record from file.

=cut

sub get_record {
 my ($self, $n, @fields)=@_;

 $self->readRecord($n)	or return;

 return ($self->{record}{rhd} & RECDEL, @{$self->{record}{data}})	
	unless @fields;

 return
	$self->{record}{rhd} & RECDEL, 
	map($self->{record}{data}[$self->{field_map}{$_}], @fields);
}

=item $r=$dbh->get_record_hash([ $n [, @fields]]);

Returns reference to hash containing field values indexed by field names. 
The name of the deleted flag is C<_DELETED>. The first parameter in the call 
is the number of the physical record (can be omited to read next record if
avaialable). If you do not specify any other parameters, all fields are returned.
You can also put list of field names after the record number and then only those
will be returned.

=cut

sub get_record_hash {
 my ($self, $n, @fields)=@_;

 $self->readRecord($n) or return;

 my %res= @fields ?
	map(($_, $self->{record}{data}[$self->{field_map}{$_}]), @fields) :
	map(($_->{Name}, $self->{record}{data}[$_->{No}]), @{$self->{fields}});
 
 $res{_DELETED}=$self->{record}{rhd} & RECDEL;
 return \%res;
}

=item $struct = $dbh->file_struct;

This returns CLARION file structure as a string.

=cut

sub file_struct {
 my $self=shift;

 my $res=$self->{name};
 $res=~s/\.dat$//i;
 $res=~s/^.*[\/\\]//;
 $res=uc($res);

 $res.="\tFILE,NAME('$res'),PRE('$self->{header}{filpre}')";

 $res.=",OWNER('???')"	if $self->{sfatr} & FILOWN;
 $res.=",ENCRYPT"		if $self->{sfatr} & FILCRYP;
 $res.=",CREATE"		if $self->{sfatr} & FILCRET;
 $res.=",RECLAIM"		if $self->{sfatr} & FILRCLM;
 $res.=",PROTECT"		if $self->{sfatr} & FILREAD;
 $res.="\n$self->{header}{memnam}\tMEMO($self->{header}{memolen})"
 				if $self->{sfatr} & FILMEMO;

 $res.="\n$self->{header}{recname}\tRECORD\n";
 
 for my $f(@{$self->{fields}}) {
  next	if $f->{isMemo};
  $res.=$f->{Name}."\t";
  my $t=qw(? LONG REAL . . BYTE SHORT . DECIMAL)[$f->{fldtype}];
  if(!$t or '?' eq $t) {
   $t='UNKNOWN TYPE';
   $res.='!';
  }
  if('.' eq $t){
   $res.="STRING($f->{length})";
   $res.="\t!GROUP"		if 7==$f->{fldtype};
  } else {
   $res.=$t;
   $res.="(".($f->{decsig}+$f->{decdec}).",$f->{decdec})"
				if 8==$f->{fldtype};
  }
  $res.="\n";
 }
 return $res."\t. .\n";
}

# Clarion "decryption"

sub decrypt {
 my ($self, $str)=@_;
 return $str	unless defined($self->{Key});
 my $res='';
 do{
  my($c1, $c2)=unpack('C2', $str);
  defined($c2)	or return $res.$str;
  $res.=pack('C2', $c1^$self->{Key}[0], $c2^$self->{Key}[1]);
  $str=unpack('x2 a*', $str);
 }while(1);
}

sub readData {
 my ($self, $len, $what, $decrypt)=@_;
 my $rc=read($self->{fh}, my $buf, $len)||0;
 die "Read error Clarion file ($what) ($rc bytes read instead of $len)!\n"
	if $rc!=$len;
 return $decrypt? $self->decrypt($buf) : $buf;
}

sub readMemo {
 my ($self, $len)=@_;
 my $rc=read($self->{fhMemo}, my $buf, $len)||0;
 die "Read error Clarion memo ($rc bytes read instead of $len)!\n"
	if $rc!=$len;
 return $buf;
}

# Convert BCD to string

sub unpackBCD {
 my ($bcd, $decsig, $decdec)=@_;
 $bcd=unpack('H*', $bcd);

 my $sign=substr($bcd, 0, 1) eq '0' ? '' : '-';
 $bcd=substr($bcd, 1);
 $bcd=~s/\D/9/g	and
    warn "Incorrect DECIMAL value!\n";
 
 my $sig=substr($bcd, 0, $decsig);
 $sig=~s/^0+//;
 $sig='0'	if !length($sig);

 my $dec=substr($bcd, $decsig, $decdec);
 $dec=~s/0+$//;
 $sig.='.'	if length($dec);

 return $sign.$sig.$dec;
}

1;
__END__

=back

=head1 BUGS

Tested only on x86 processors. Should fail on another architecture.

=head1 AUTHOR

Stas Ukolov <ukoloff@cpan.org>

Ilya Chelpanov <ilya@macro.ru>, http://i72.narod.ru or http://i72.by.ru

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

Clarion data files and indexes description at http://i72.by.ru.

ODBC driver for Clarion .tps-files (read/write) at http://dein.h11.ru/

=cut
