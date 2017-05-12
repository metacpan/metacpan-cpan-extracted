use Class::Struct;

struct( Keydesc => [ 
		k_flags 	=> '$', 
		k_nparts 	=> '$', 
		k_part 		=> '@' 
	]);

struct( Dictinfo => [
		di_nkeys	=> '$',
		di_recsize	=> '$',
		di_idxsize	=> '$',
		di_nrecords	=> '$'
	]);

package CIsam;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	AUDGETNAME
	AUDHEADSIZE
	AUDINFO
	AUDSETNAME
	AUDSTART
	AUDSTOP
	CHARTYPE
	DECIMALTYPE
	DOUBLETYPE
	FLOATTYPE
	INTTYPE
	LONGTYPE
	MINTTYPE
	MLONGTYPE
	STRINGTYPE
	ISAUTOLOCK
	ISCLOSED
	ISCURR
	ISD1
	ISD2
	ISDD
	ISDESC
	ISDUPS
	ISEQUAL
	ISEXCLLOCK
	ISFIRST
	ISFIXLEN
	ISGREAT
	ISGTEQ
	ISINOUT
	ISINPUT
	ISLAST
	ISLCKW
	ISLOCK
	ISMANULOCK
	ISMASKED
	ISNEXT
	ISNOCARE
	ISNODUPS
	ISNOLOG
	ISOUTPUT
	ISPREV
	ISRDONLY
	ISSYNCWR
	ISTRANS
	ISVARCMP
	ISVARLEN
	ISWAIT
);

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined CIsam macro $constname";
	}
    }
    no strict 'refs';
    *$AUTOLOAD = sub { $val };
    goto &$AUTOLOAD;
}

$VERSION='1.0';
bootstrap CIsam $VERSION;

# Preloaded methods go here.

#---------------------------------------
# CIsam->iserrno or CIsam->iserrno(value)
#---------------------------------------

sub iserrno
{
   @_ == 1 or @_ == 2 or croak 'usage: CIsam->iserrno or CIsam->iserrno(INTVAL)';
   my $this = shift;
   my $value = shift;
   if (defined($value)) {
      iserrno_put($value);
      }
   else {
      return iserrno_get();
   }
}

#---------------------------------------
# CIsam->isrecnum or CIsam->isrecnum(value)
#---------------------------------------

sub isrecnum
{
   @_ == 1 or @_ == 2 or croak 'usage: CIsam->isrecnum or CIsam->isrecnum(LONGVAL)';
   my $this = shift;
   my $value = shift;
   if (defined($value)) {
      isrecnum_put($value);
      }
   else {
      return isrecnum_get();
   }
}

#---------------------------------------
# CIsam->isreclen or CIsam->isreclen(value)
#---------------------------------------

sub isreclen
{
   @_ == 1 or @_ == 2 or croak 'usage: CIsam->isreclen or CIsam->isreclen(INTVAL)';
   my $this = shift;
   my $value = shift;
   if (defined($value)) {
      isreclen_put($value);
      }
   else {
      return isreclen_get();
   }
}

#---------------------------------------
# CIsam->iserrio or CIsam->iserrio(value)
#---------------------------------------

sub iserrio
{
   @_ == 1 or @_ == 2 or croak 'usage: CIsam->iserrio or CIsam->iserrio(INTVAL)';
   my $this = shift;
   my $value = shift;
   if (defined($value)) {
      iserrio_put($value);
      }
   else {
      return iserrio_get();
   }
}

#---------------------------------------
# $fd->fd
#---------------------------------------

sub fd
{
   @_ == 1 or croak 'usage: $fd->fd';
   my $this = shift;
   return $this->{fd};
}

#---------------------------------------
# $CIsam->lddbl
#---------------------------------------

sub lddbl
{
   @_ == 2 or croak 'usage: $CIsam->lddbl';
   my $this = shift;
   my $val = shift;
   my $ret=lddbl1($val);
   return $ret;
}

#---------------------------------------
# $CIsam->ldint
#---------------------------------------

sub ldint
{
   @_ == 2 or croak 'usage: $CIsam->stint';
   my $this = shift;
   my $val = shift;
   return ldint1($val);
}

#---------------------------------------
# $CIsam->stdbl
#---------------------------------------

sub stdbl
{
   @_ == 3 or croak 'usage: $CIsam->stdbl';
   my $this = shift;
   my $val = shift;
   my $length_of_field = shift;
   my @byte_array = stdbl1($val, $length_of_field);
   return @byte_array;
}

#---------------------------------------
# $CIsam->stint
#---------------------------------------

sub stint
{
   @_ == 3 or croak 'usage: $CIsam->stint';
   my $this = shift;
   my $val = shift;
   my $length_of_field = shift;
   my @byte_array = stint1($val, $length_of_field);
   return @byte_array;
}

#---------------------------------------
# $CIsam->stlong
#---------------------------------------

sub stlong
{
   @_ == 3 or croak 'usage: $CIsam->stlong';
   my $this = shift;
   my $val = shift;
   my $length_of_field = shift;
   my @byte_array = stlong1($val, $length_of_field);
   return @byte_array;
}

#---------------------------------------
# $CIsam->ldlong
#---------------------------------------

sub ldlong
{
   @_ == 2 or croak 'usage: $CIsam->stlong';
   my $this = shift;
   my $val = shift;
   return ldlong1($val);
}

#---------------------------------------
# $CIsam->stfloat
#---------------------------------------

sub stfloat
{
   @_ == 3 or croak 'usage: $CIsam->stfloat';
   my $this = shift;
   my $val = shift;
   my $length_of_field = shift;
   my @byte_array = stfloat1($val, $length_of_field);
   return @byte_array;
}

#---------------------------------------
# $CIsam->ldfloat
#---------------------------------------

sub ldfloat
{
   @_ == 2 or croak 'usage: $CIsam->ldfloat';
   my $this = shift;
   my $val = shift;
   return ldfloat1($val);
}

#---------------------------------------
# $fd->name
#---------------------------------------

sub name
{
   @_ == 1 or croak 'usage: $fd->name';
   my $this = shift;
   return $this->{name};
}

#---------------------------------------
# $fd->isaddindex(kd)
#---------------------------------------

sub isaddindex
{
   @_ == 2 or croak 'usage: $fd->isaddindex(KEYDESC)';
   my $this = shift;
   my $kd = shift;
   my @param=();
   push(@param, $this->fd);
   push(@param, $kd->k_flags);
   push(@param, $kd->k_nparts);
 
   for my $ind (0..$kd->k_nparts-1) {
     for my $j (0..2) {
       push(@param, $kd->k_part($ind)->[$j])
     }
   }
 
   #required by Informix C-Isam 4.00
   #$this->isclose() or die("ERROR: isaddindex: couldn't close DB"); 
   #$this->isopen($this->{name}, &ISINOUT + &ISMANULOCK) or die("ERROR: isaddindex: couldn't open DB");

   my $status = isaddindex1( @param );

   #$this->isclose() or die("ERROR: isaddindex: couldn't close DB");
   #$this->isopen($this->{name}, &ISINOUT + &ISMANULOCK) or die("ERROR: isaddindex: couldn't open DB");

   return ($status >= 0);
}

#---------------------------------------
# $fd->isaudit(name,mode)
#---------------------------------------

sub isaudit
{
   @_ == 3 or croak 'usage: $fd->isaudit(NAME, MODE)';
   my $this = shift;
   my $name = shift;
   my $mode = shift;
   return ( isaudit1($this->fd,$name,$mode) >= 0);
}

#---------------------------------------
# CIsam->isbegin
#---------------------------------------

sub isbegin
{
   @_ == 1 or croak 'usage: CIsam->isbegin';
   return (isbegin1() >= 0); 
}

#---------------------------------------
# CIsam->isbuild (name,len,kd,mode)
#---------------------------------------

sub isbuild
{
   @_ == 5 or croak 'usage: CIsam->isbuild(NAME, RECLEN, KEYDESC, MODE)';
   my $class = shift;
   my ($name,$len,$kd,$mode) = @_;
   my @param=();
   push(@param, $name);
   push(@param, $len);
   push(@param, $mode);
   push(@param, $kd->k_flags);
   push(@param, $kd->k_nparts);
 
   for my $ind (0..$kd->k_nparts-1) {
     for my $j (0..2) {
       push(@param, $kd->k_part($ind)->[$j]);
     }
   }
 
   my $this = {};
   bless($this, $class);
   my $fd = isbuild1( @param );
   if ($fd < 0) {
      return undef;
      }
   else {
      $this->{fd} = $fd;  
      $this->{name} = $name;  
      return $this;
   }
}

#---------------------------------------
# CIsam->iscleanup
#---------------------------------------

sub iscleanup
{
   @_ == 1 or croak 'usage: CIsam->iscleanup';
   return (iscleanup1() >= 0); 
}

#---------------------------------------
# $fd->isclose()
#---------------------------------------

sub isclose
{
   @_ == 1 or croak 'usage: $fd->isclose';
   my $this = shift;
   return ( isclose1($this->fd) >= 0);
}

#---------------------------------------
# $fd->iscluster(kd)
#---------------------------------------

sub iscluster
{
   @_ == 2 or croak 'usage: $fd->iscluster(KEYDESC)';
   my $this = shift;
   my $kd = shift;
  
   my @param=();
   push(@param, $this->fd);
   push(@param, $kd->k_flags);
   push(@param, $kd->k_nparts);
 
   for my $ind (0..$kd->k_nparts-1) {
     for my $j (0..2) {
       push(@param, $kd->k_part($ind)->[$j])
     }
   }
 
   my $class = ref($this);
   my $new = {};
   bless($new, $class);
   my $fd = iscluster1( @param );
   if ($fd < 0) {
      return undef;
      }
   else {
      $new->{fd} = $fd;
      $new->{name} = $this->name;
      return $new;
   }
}

#---------------------------------------
# CIsam->iscommit
#---------------------------------------

sub iscommit
{
   @_ == 1 or croak 'usage: CIsam->iscommit';
   return (iscommit1() >= 0); 
}

#---------------------------------------
# $fd->isdelcurr()
#---------------------------------------

sub isdelcurr
{
   @_ == 1 or croak 'usage: $fd->isdelcurr';
   my $this = shift;
   return ( isdelcurr1($this->fd) >= 0);
}

#---------------------------------------
# $fd->isdelete(data)
#---------------------------------------

sub isdelete
{
   @_ == 2 or croak 'usage: $fd->isdelete(ISAMDATA)';
   my $this = shift;
   my $rdata = shift;
   return ( isdelete1($this->fd,$$rdata) >= 0);
}

#---------------------------------------
# $fd->isdelindex(kd)
#---------------------------------------

sub isdelindex
{
   @_ == 2 or croak 'usage: $fd->isdelindex(KEYDESC)';
   my $this = shift;
   my $kd = shift;
  
   my @param=();
   push(@param, $this->fd);
   push(@param, $kd->k_flags);
   push(@param, $kd->k_nparts);
 
   for my $ind (0..$kd->k_nparts-1) {
     for my $j (0..2) {
       push(@param, $kd->k_part($ind)->[$j])
     }
   }
 
   return ( isdelindex1( @param ) >= 0);
}

#---------------------------------------
# $fd->isdelrec(recnum)
#---------------------------------------

sub isdelrec
{
   @_ == 2 or croak 'usage: $fd->isdelrec(RECNUM)';
   my $this = shift;
   my $recnum = shift;
   return ( isdelrec1($this->fd,$recnum) >= 0);
}

#---------------------------------------
# CIsam->iserase(name)
#---------------------------------------

sub iserase
{
   @_ == 2 or croak 'usage: CIsam->iserase(NAME)';
   my $class = shift;
   my $name = shift;
   return (iserase1($name) >= 0);
}

#---------------------------------------
# $fd->isflush()
#---------------------------------------

sub isflush
{
   @_ == 1 or croak 'usage: $fd->isflush';
   my $this = shift;
   return ( isflush1($this->fd) >= 0);
}

#---------------------------------------
# $fd->isindexinfo(idx)
#---------------------------------------

sub isindexinfo
{
   @_ == 2 or croak 'usage: $fd->isindexinfo(INDEX)';
   my ($this,$idx) = @_;
   my ($cc, $kd);

   if ($idx == 0) {
      $kd = new Dictinfo;
      my @ret = isisaminfo1($this->fd);
      $cc = shift @ret;
      $kd->di_nkeys(shift @ret);
      $kd->di_recsize(shift @ret);
      $kd->di_idxsize(shift @ret);
      $kd->di_nrecords(shift @ret);
      }
   else {
      $kd = new Keydesc;
      my @ret = isindexinfo1($this->fd,$idx);
      $cc = shift @ret;
      $kd->k_flags( shift @ret );
      $kd->k_nparts( shift @ret );
      for my $ind (0..$kd->k_nparts) {
         $kd->k_part($ind, [shift @ret, shift @ret, shift @ret]);
      }

   }
   if ($cc < 0) {
      return undef;
      }
   else {
      return $kd;
   }
}

#---------------------------------------
# $fd->islock()
#---------------------------------------

sub islock
{
   @_ == 1 or croak 'usage: $fd->islock';
   my $this = shift;
   return ( islock1($this->fd) >= 0);
}

#---------------------------------------
# CIsam->islogclose
#---------------------------------------

sub islogclose
{
   @_ == 1 or croak 'usage: CIsam->islogclose';
   return (islogclose1() >= 0); 
}

#---------------------------------------
# CIsam->islogopen(name)
#---------------------------------------

sub islogopen
{
   @_ == 2 or croak 'usage: CIsam->islogopen(NAME)';
   my $class = shift;
   my $name = shift;
   return (islogopen1($name) >= 0);
}

#---------------------------------------
# CIsam->isopen(name,mode)
#---------------------------------------

sub isopen
{
   @_ == 3 or croak 'usage: CIsam->isopen(NAME, MODE)';
   my $class = shift;
   my $this = {};
   my $dataset_name = shift;
   my $mode = shift;
   bless($this, $class);
   my $fd = isopen1($dataset_name, $mode);
   if ($fd < 0) {
      return undef;
      }
   else {
      $this->{fd} = $fd;
      $this->{name} = $dataset_name;
      return $this;
   }
}

#---------------------------------------
# $fd->isread(data,mode)
#---------------------------------------

sub isread
{
   @_ == 3 or croak 'usage: $fd->isread(ISAMDATA, MODE)';
   my $this = shift;
   my $rdata = shift;
   my $mode = shift;
   return ( isread1($this->fd,$$rdata,$mode) >= 0);
}

#---------------------------------------
# CIsam->isrecover
#---------------------------------------

sub isrecover
{
   @_ == 1 or croak 'usage: CIsam->isrecover';
   return (isrecover1() >= 0); 
}

#---------------------------------------
# $fd->isrelease()
#---------------------------------------

sub isrelease
{
   @_ == 1 or croak 'usage: $fd->isrelease';
   my $this = shift;
   return ( isrelease1($this->fd) >= 0);
}

#---------------------------------------
# CIsam->isrename(oldname,newname)
#---------------------------------------

sub isrename
{
   @_ == 3 or croak 'usage: CIsam->isrename(OLDNAME, NEWNAME)';
   my $class = shift;
   my $oldname = shift;
   my $newname = shift;
   return (isrename1($oldname,$newname) >= 0);
}

#---------------------------------------
# $fd->isrewcurr(data)
#---------------------------------------

sub isrewcurr
{
   @_ == 2 or croak 'usage: $fd->isrewcurr(ISAMDATA)';
   my $this = shift;
   my $rdata = shift;
   return ( isrewcurr1($this->fd,$$rdata) >= 0);
}

#---------------------------------------
# $fd->isrewrec(recnum,data)
#---------------------------------------

sub isrewrec
{
   @_ == 3 or croak 'usage: $fd->isrewrec(RECNUM, ISAMDATA)';
   my $this = shift;
   my $recnum = shift;
   my $rdata = shift;
   return ( isrewrec1($this->fd,$recnum,$$rdata) >= 0);
}

#---------------------------------------
# $fd->isrewrite(data)
#---------------------------------------

sub isrewrite
{
   @_ == 2 or croak 'usage: $fd->isrewrite(ISAMDATA)';
   my $this = shift;
   my $rdata = shift;
   return ( isrewrite1($this->fd,$$rdata) >= 0);
}

#---------------------------------------
# CIsam->isrollback
#---------------------------------------

sub isrollback
{
   @_ == 1 or croak 'usage: CIsam->isrollback';
   return (isrollback1() >= 0); 
}

#---------------------------------------
# $fd->issetunique(uniqueid)
#---------------------------------------

sub issetunique
{
   @_ == 2 or croak 'usage: $fd->issetunique(UNIQUEID)';
   my $this = shift;
   my $uniqueid = shift;
   return ( issetunique1($this->fd,$uniqueid) >= 0);
}

#---------------------------------------
# $fd->isstart(kd,len,data,mode)
#---------------------------------------

sub isstart
{
   @_ == 5 or croak 'usage: $fd->isstart(KEYDESC, LENGTH, ISAMDATA, MODE)';
   my $this = shift;
   my $kd = shift;
   my $length = shift;
   my $rdata = shift;
   my $mode = shift;
  
   my @param=();
   push(@param, $this->fd);
   push(@param, $length);
   push(@param, $$rdata);
   push(@param, $mode);
   push(@param, $kd->k_flags);
   push(@param, $kd->k_nparts);
 
   for my $ind (0..$kd->k_nparts-1) {
     for my $j (0..2) {
       push(@param, $kd->k_part($ind)->[$j])
     }
   }
 
   return ( isstart1( @param ) >= 0);
}

#---------------------------------------
# $fd->isuniqueid()
#---------------------------------------

sub isuniqueid
{
   @_ == 1 or croak 'usage: $fd->isuniqueid';
   my $this = shift;
   my $uniqueid;
   my $cc = isuniqueid1($this->fd,$uniqueid);
   if ($cc >= 0) {
      return $uniqueid;
      }
   else {
      return undef;
   }
}

#---------------------------------------
# $fd->isunlock()
#---------------------------------------

sub isunlock
{
   @_ == 1 or croak 'usage: $fd->isunlock';
   my $this = shift;
   return ( isunlock1($this->fd) >= 0);
}

#---------------------------------------
# $fd->iswrcurr(data)
#---------------------------------------

sub iswrcurr
{
   @_ == 2 or croak 'usage: $fd->iswrcurr(ISAMDATA)';
   my $this = shift;
   my $rdata = shift;
   return ( iswrcurr1($this->fd,$$rdata) >= 0);
}

#---------------------------------------
# $fd->iswrite(data)
#---------------------------------------

sub iswrite
{
   @_ == 2 or croak 'usage: $fd->iswrite(ISAMDATA)';
   my $this = shift;
   my $rdata = shift;
   return ( iswrite1($this->fd,$$rdata) >= 0);
}



# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!



=head1 NAME

CIsam - Perl Object Oriented extension for ISAM files

=head1 SYNOPSIS

use CIsam;

=head1 DESCRIPTION

CIsam.pm is a thin wrapper to the C-ISAM functions calls.

=head1 Exported constants

  AUDGETNAME
  AUDHEADSIZE
  AUDINFO
  AUDSETNAME
  AUDSTART
  AUDSTOP 
  CHARTYPE
  DECIMALTYPE
  DOUBLETYPE
  FLOATTYPE
  INTTYPE
  LONGTYPE
  MINTTYPE
  MLONGTYPE
  STRINGTYPE
  ISAUTOLOCK
  ISCLOSED
  ISCURR
  ISD1
  ISD2
  ISDD
  ISDESC
  ISDUPS
  ISEQUAL
  ISEXCLLOCK
  ISFIRST
  ISFIXLEN
  ISGREAT
  ISGTEQ
  ISINOUT
  ISINPUT
  ISLAST
  ISLCKW
  ISLOCK
  ISMANULOCK
  ISMASKED
  ISNEXT
  ISNOCARE
  ISNODUPS
  ISNOLOG
  ISOUTPUT
  ISPREV
  ISRDONLY
  ISSYNCWR
  ISTRANS
  ISVARCMP
  ISVARLEN
  ISWAIT

=head1 AUTHOR

Ilya Verlinsky, ilya@wsi.net

=head1 METHODS

=over 4
The most imprtant methods that will be used by application programmers
will be contained in IsamObjects.pm
IsamObjects Provides the following functionality :
It allowes for the Object Oriented access of Isam files.
The DataBase Layout is specified in the .pm files that programmer will create.
For the example of the syntax see ./eg/Person.pm in the CIsam distribution
directory.
Functions provided by the IsamObjects:

=item $obj->new()

Parameters:

	This is the object constructor. If IsamObjects::BUILD is passed to it, it
	will create the nessasary Isam files for that object to be stored in.
	If no options are passed it will try to open the Isam files for reading and
	writing in its default mode ISINOUT + ISMANULOCK. If user desires some other
	mode than default he must pass the opening mode to the constructor.

Example:

	my $ps = new Person(IsamObjects::BUILD) - this will build the Isam files
	
	my $ps = new Person; - this will open the db in the default mode

	my $ps = new Person(&ISINOUT + &ISMANULOCK) - This will open the db in custom
	                                              mode 

=item $obj->path("indexname")

Parameters:

    indexname as contained in the database layout module of
    the index to be used when accessing the file (set). Only one path
    may be active at a time.  The paths must be valid paths which are
    specified in the layout as indexed fields.

Example:
	
	$obj->path("foo");

=item $obj->get(ISMODE)

Parameters:
	
	Informix access mode should be passed. This will tell the DB
	the way to access the records. Examples of modes are ISFIRST,
	ISLAST, ISGTEQ, ISEQUAL, ISGREAT, ISNEXT. 
	For all modes except ISFIRST, ISLAST, and ISNEXT the database
	engine will also perform the search function. The function will
	return a full record from the db with it will stuff in the
	appropriate hash positions.

Example:
	
	$obj->get(&ISGTEQ);

=item $obj->add();

Parameters:
	
	No parameters needs to be passed to this function. It will add a
	non-existant record to the database.
	WARNING: If the record witht he same unique number is already in the
	db unpredictable situation can occur. For such a case use update()
	function.

Example:

	$obj->add();

=item $obj->update

Parameters:
	
	No parameters. It will update the existing record in the db.
	WARNING: Do not use to add new records. Unpredictable errors can
	occur.

Example:

	$obj->update();

=item $obj->clear();

Parameters:
	
	None. This function will clear the record and set all the values
	to their defaults - 0 for numeric and ' ' for the character.

Example:
	
	$obj->clear();
 
The CIsam module allowes for the user of IsamObjects to access even the
lowes CIsam functions throught the Isam Object

$obj->{ISAM_OBJ}

CIsam.pm module include class methods indicated by CIsam->method
and object methods indicated by $fd->method where $fd is a 
reference to an instance obtained by isopen, isbuild or iscluster
eg. my $fd = CIsam->isopen("myfile",&ISINOUT);

=item CIsam->iserrno([INTVALUE])

Returns the value of the global CIsam variable iserrno unless C<INTVALUE>
is specified, in which case, sets the value of iserrno.

=item CIsam->isrecnum([LONGVALUE])

Returns the value of the global CIsam variable isrecnum unless C<LONGVALUE>
is specified, in which case, sets the value of isrecnum.

=item CIsam->isreclen([INTVALUE])

Returns the value of the global CIsam variable isreclen unless C<INTVALUE>
is specified, in which case, sets the value of isreclen.

=item CIsam->iserrio([INTVALUE])

Returns the value of the global CIsam variable iserrio unless C<INTVALUE>
is specified, in which case, sets the value of iserrio.

=item $fd->fd

Returns CIsam file descriptor

=item $fd->name
 
Returns the filename 

=item $fd->isaddindex(KEYDESC)

Returns TRUE if successfully adds an index to $fd

=item CIsam->isbuild(NAME, LEN, KEYDESC, MODE)

Returns a reference to an CIsam object or undef if unsuccessful

=item CIsam->iscleanup

Returns TRUE if successful

=item $fd->isclose

Returns TRUE if successful

=item $fd->iscluster(KEYDESC)

KEYDESC is a reference to a Keydesc object.
Returns a reference to an CIsam object or undef if unsuccessful 

=item CIsam->iscommit

Returns TRUE if successful

=item $fd->isdelcurr

Returns TRUE if successful

=item $fd->isdelete(DATA)

DATA is a reference to a scalar. Returns TRUE if successful

=item $fd->isdelindex(KEYDESC)

KEYDESC is a reference to a Keydesc object.
Returns TRUE if successful

=item $fd->isdelrec(RECNUM)

RECNUM is a long integer
Returns TRUE if successful

=item CIsam->iserase(NAME)

NAME is a filename. Returns TRUE if successful

=item $fd->isflush

Returns TRUE if successful 

=item $fd->isindexinfo(IDX)

IDX is an integer. returns undef if unsuccessful.
If IDX == 0, returns a reference to a Dictinfo object.
If IDX > 0, returns a reference to a Keydesc object

=item $fd->islock

Returns TRUE if successful

=item CIsam->islogclose

Returns TRUE if successful

=item CIsam->islogopen

Returns TRUE if successful

=item CIsam->isopen(NAME, MODE)

NAME is a filename, MODE is an integer
Returns undef if unsuccessful, otherwise returns a reference
to an CIsam object

=item $fd->isread(DATA, MODE)

DATA is a reference to a scalar. MODE is an integer.
Returns TRUE if successful

=item CIsam->isrecover

Returns TRUE if successful

=item $fd->isrelease

Returns TRUE if successful

=item CIsam->isrename(OLDNAME, NEWNAME) 

Returns TRUE if successful

=item $fd->isrewcurr(DATA)

DATA is a reference to a scalar. Returns TRUE if successful 

=item $fd->isrewrec(RECNUM, DATA)

RECNUM is the record number, DATA is a reference to the Data. 
Returns TRUE if successful

=item $fd->isrewrite(DATA)

DATA is a reference to the Data. Returns TRUE if successful 

=item CIsam->isrollback 

Returns TRUE if successful

=item $fd->issetunique(UNIQUEID) 

UNIQUEID is an integer scalar. Returns TRUE if successful

=item $fd->isstart(KEYDESC, LENGTH, DATA, MODE)

KEYDESC is a reference to a Keydesc object, LENGTH is 0 or the
number of bytes of the key, DATA is a reference to a scalar,
MODE is an integer value.

Returns TRUE if successful

=item $fd->isuniqueid

Returns undef if unsuccessful or an long value

=item $fd->isunlock

Returns TRUE if successful

=item $fd->iswrcurr(DATA)

DATA is a reference to a scalar. Returns TRUE if successful

=item $fd->iswrite(DATA)
 
DATA is a reference to a scalar. Returns TRUE if successful


=back
 
=head1 SEE ALSO 

perl(1). 
IsamObjects.


=cut
