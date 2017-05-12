#!perl -w
#
# CGI::Bus::file - File object
#
# admiral 
#
# 

package CGI::Bus::file;
require 5.000;
use strict;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use CGI::Bus::Base;
use IO::File;
use Fcntl qw(:DEFAULT :flock);
use vars qw(@ISA $AUTOLOAD);
@ISA =qw(CGI::Bus::Base);


1;


sub new {
 my $c=shift;
 my $s ={};
 bless $s,$c;
 $s =$s->CGI::Bus::Base::initialize(@_);
 $s->parent->set('-reset')->{-file}=1 if $s->parent;
 $s->iofile();
 $s
}


sub AUTOLOAD {
 my $s =shift;
 my $m =substr($AUTOLOAD, rindex($AUTOLOAD, '::')+2);
 if    (substr($m,2) eq 'O_')    {eval "Fcntl::$m()"}
 elsif (substr($m,5) eq 'LOCK_') {eval "Fcntl::$m()"}
 else  {$s->iofile->$m(@_)}
}



sub DESTROY {
 my $s =shift;
 eval {$s->close()};
 eval {$s->CGI::Bus::Base::DESTROY};
}


#######################


sub iofile {  # IO::File object
 my $s =shift;
 if (!$s->{-iofile}) {
    $s->{-iofile} =IO::File->new();
    if    (scalar(@_))  {$s->open(@_)}
    elsif ($s->{-name}) {$s->open($s->{-name},$s->{-mode},$s->{-perm})} 
 }
 elsif (scalar(@_)) {
    $s->{-iofile} =IO::File->new();
    $s->open(@_)
 }
 $s->{-iofile}
}



sub open {    # Open file 'r', 'rw', 'rwc', 'w', 'a' modes
 my $s =shift;
 $s->{-name} =$_[0];
 $s->{-mode} =!$_[1] ?'r' :lc($_[1]) eq 'rw' ?'r+' :lc($_[1]) eq 'rwc' ?(O_CREAT|O_RDWR) :$_[1];
 $s->{-perm} =($_[2]||0666);
 $s->{-iofile} =IO::File->new() if !$s->{-iofile};
 $s->{-iofile}->open($s->{-name}, $s->{-mode}, $s->{-perm})
 || die("open '" .($s->{-name}||'') ."': $!\n");
 $s->seek(0,0) if ($s->{-mode} ne 'a') && !($s->{-mode} & O_APPEND);
#$s->lock(($s->{-mode} eq 'r') || ($s->{-mode} & O_RDONLY) ?LOCK_SH :LOCK_EX);
 $s
}



sub close {   # Close file
 my $s =shift;
 $s->iofile->close() if $s->iofile->opened;
 $s->{-name}   =undef;
 $s->{-mode}   =undef;
 $s->{-perm}   =undef;
 $s->{-lock}   =undef;
 $s->{-iofile} =undef;
 $s
}



sub lock {    # Lock file
 my $s =shift;
 return ($s->{-lock}||0) if !scalar(@_);
 my $l =shift;
 if    ($l =~/\w{2}/) {$l =eval('Fcntl::LOCK_' .uc($l) .'()')}
 elsif ($l ==0)       {$l =LOCK_UN}
 if (($s->{-lock} ||0) != (($l != LOCK_UN) ?$l :0)) {
    flock($s->iofile, LOCK_UN);
    if ($l !=LOCK_UN) {
       flock($s->iofile, $l) ||die("lock '" .($s->{-name}||'') ."', '$l': $!\n");
       $s->{-lock} =$l
    }
    else {
       $s->{-lock} =0
    }
 }
 $s
}


sub seek {    # Position file
 my $s =shift;
 CORE::seek   ($s->iofile, $_[0], $_[1]||0) ||die("seek '"    .($s->{-name}||'') ."', '" .join(',',@_) ."': $!\n");
 CORE::sysseek($s->iofile, $_[0], $_[1]||0) ||die("sysseek '" .($s->{-name}||'') ."', '" .join(',',@_) ."': $!\n");
 $s;
}



sub load {    # Load file contents
 my $s   =shift;
 my $opt =($_[0] =~/^\-/i ? shift : ''); # 'a'rray, 's'calar, 'b'inary
    $opt =$opt .'a' if $opt !~/[asb]/i && wantarray;
 my $sub =shift;
 my ($row, @rez);
 $s->lock(LOCK_SH) if !$s->{-lock} ||$s->{-lock} ne LOCK_SH ||$s->{-lock} ne LOCK_EX;
 $s->seek(0,0);
 if    ($sub) {
       $row  =1;
       local $_;
       while (!eof($s->iofile)) {
         defined($_ =$s->iofile->getline) || die("load '" .$s->{-name} ."': $!\n");
         chomp;
         $opt=~/a/i ? &$sub() && push(@rez,$_)
                    : &$sub();
       }
 }
 elsif ($opt=~/a/i) {
       while (!eof($s->iofile)) {
         defined($row =$s->iofile->getline) || die("load '" .$s->{-name} ."': $!\n");
         chomp($row);
         push (@rez, $row);
       }
 }
 else {
       binmode($s->iofile) if $opt =~/b/i;
       defined(read($s->iofile, $row, -s $s->{-name})) || die("load '" .$s->{-name} ."': $!\n");
 }
 $opt=~/a/i ? @rez : $row
}



sub store {   # Store file contents
 my $s    =shift;
 my $opt  =($_[0] =~/^\-/i ? shift : ''); # 'b'inary
 $s->lock(LOCK_EX);
 if ($opt=~/b/i) {
     binmode($s->iofile);
     $s->iofile->print(@_) ||die("store '" .$s->{-name} ."': $!\n");
 }
 else {
   foreach my $row (@_) {
     next if !defined($row);
     $s->iofile->print($row, "\n") ||die("store '" .$s->{-name} ."': $!\n");
   }
 }
 eval{$s->iofile->flush};
 $s
}



sub dump {      # Load or Store data dump
 my  ($s,$d) =@_;
 if  (scalar(@_) >1) {$s->truncate(0); $s->seek(0)->store('-',$s->parent->dumpout($d))}
 else                {$s->parent->dumpin($s->load('-s'))}
}



sub dumpload {  # Load data dump from file
 my ($s) =@_;
 $s->parent->dumpin($s->load('-s'))
}



sub dumpstore { # Store data dump to file
 my ($s,$d) =@_;
 $s->truncate(0);
 $s->seek(0)->store('-',$s->parent->dumpout($d))
}


