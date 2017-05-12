#!perl -w
#
# CGI::Bus::fut - File Utils Library
#
# admiral 
#
# 

package CGI::Bus::fut;
require 5.000;
use strict;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use CGI::Bus::Base;
use vars qw(@ISA);
@ISA =qw(CGI::Bus::Base);



1;



#######################
# Path Utils
#######################

sub copy {
 my $s   =shift;
 my $opt =$_[0] =~/^-/i ? shift : '';
 my ($src,$dst) =@_;
 # 'd'irectory or 'f'ile hint; 'r'ecurse subdirectories, 'i'gnore errors
 $opt =~s/-//g;
 if ($^O eq 'MSWin32' && (eval{Win32::IsWinNT} ||(($ENV{OS}||'') =~/Windows_NT/i))) {
    $src =~tr/\//\\/;
    $opt ="${opt}Z";
    $opt ="${opt}Y" if ([eval{Win32::GetOSVersion()}]->[1] ||0) >=5
 }
 elsif ($^O eq 'MSWin32') {
    $src =~tr/\//\\/;
    $dst =~tr/\//\\/
 }
 if ($^O ne 'MSWin32' && $^O ne 'dos') {
  # eval ('use File::Copy; File::Copy::copy(\@_)') || croak($!);
    $opt =~ tr/fd//;
    $opt ="-${opt}p";
    $opt =~ tr/ri/Rf/;
    $s->parent->oscmd('cp', $opt, @_)
 }
 else {
    my $rsp =($opt =~/d/i ? 'D' : $opt =~/f/i ? 'F' : '');
    $opt =~s/(r)/SE/i; $opt =~s/(i)/C/i; $opt =~s/[fd]//ig; $opt =~s/(.{1})/\/$1/gi;
    my @cmd =('xcopy',"/H/R/K/Q$opt","\"$src\"","\"$dst\"");
    push @cmd, sub{print($rsp)} if $rsp && ($ENV{OS} && $ENV{OS}=~/windows_nt/i ? !-e $dst : !-d $dst);
    $s->parent->oscmd(@cmd)
 }
}



sub delete {
 my $s   =shift;
 my $opt =$_[0] =~/^\-/ || $_[0] eq '' ? shift : '';
 my $ret =1;
 $s->pushmsg("delete " .join(', ', @_));
 foreach my $par (@_) {
   foreach my $elem ($s->glob($par)) {
     if (-d $elem) {                 # '-r' - recurse subdirectories
        if ($opt =~/r/i && !$s->delete($opt,"$elem/*")) {
              $ret =0
        }
        elsif (!rmdir($elem)) {
              $ret =0;
              $opt =~/i/i || die("delete('$elem'): $!\n");
        }
     }
     elsif (-f $elem && !unlink($elem)) {
           $ret =0;
           $opt =~/i/i || die("delete('$elem'): $!\n");
     }
   }
 }
 $ret
}



sub find {
 my $s   =shift;
 my $opt =($_[0] =~/^\-/i ? shift : '');
 my ($sub, $i, $ret) =(0,0,0);
 local $_            if $opt !~/-\$/i;
 $opt =$opt ."-\$"   if $opt !~/-\$/i;
 foreach my $dir (@_) {
   $i++;
   if    ((!$sub || ref($dir)) && ref($_[$#_]) && $i <=$#_) {
         foreach my $elem (@_[$i..$#_]){if(ref($elem)){$sub =$elem; last}};
         next if ref($dir)
   }
   elsif (ref($dir)) {
         $sub =$dir; next
   }
   my $fs;
   foreach my $elem ($s->glob($dir)) {
     $_ =$elem;
     my @stat =stat($elem);
     my @nme  =(/^(.*)[\/\\]([^\/\\]+)$/ ? ($1,$2) : ('',''));
     if    (@stat ==0 && ($opt =~/[^!]*i/i || ($^O eq 'MSWin32' && $elem =~/[\?]/i))) {next} # bug in stat!
     elsif (@stat ==0) {die("stat('$elem'): $!\n"); undef($_); return(0)}
     elsif ($stat[2] & 0120000 && $opt =~/!.*s/i) {next} # symlink
     elsif (!defined($fs)) {$fs =$stat[2]}
     elsif ($fs !=$stat[2] && $opt =~/!.*m/i)  {next}    # mountpoint?
     if ($stat[2] & 0040000 && $opt =~/!.*l/i) {         # finddepth
        $ret +=$s->find($opt, "$elem/*", $sub); defined($_) || return(0);
        $_ =$elem;
     }
     if    ($stat[2] & 0040000 && $opt =~/!.*d/i) {}     # exclude dirs
     elsif (&$sub(\@stat,@nme)) {$ret +=1};
     defined($_) || return(0);                      # error stop: undef($_)
     if ($stat[2] & 0040000 && $opt !~/!.*[rl]/i) { # no recurse, $_[0]->[2] =0
        $ret +=$s->find($opt, "$elem/*", $sub); defined($_) || return(0);
     }
   }
 }
 $ret
}


sub glob {
 my $s =shift;
 my @ret;
 if    ($^O ne 'MSWin32') {
    CORE::glob(@_)
 }
 elsif (-e $_[0]) {
    push @ret, $_[0];
    @ret
 }
 else {
    my $msk =($_[0] =~/([^\/\\]+)$/i ? $1 : '');
    my $pth =substr($_[0],0,-length($msk));
    $msk =~s/\*\.\*/*/g;
    $msk =~s:(\(\)[].+^\-\${}[|]):\\$1:g;
    $msk =~s/\*/.*/g;
    $msk =~s/\?/.?/g;
    local (*DIR, $_); opendir(DIR, $pth eq '' ? './' : $pth) || die("open '$pth': $!\n");
    while(defined($_ =readdir(DIR))) {
      next if $_ eq '.' || $_ eq '..' || $_ !~/^$msk$/i;
      push @ret, "${pth}$_";
    }
    closedir(DIR) || die("close '$pth': $!\n");
    @ret
 }
}



sub globn {
 map {$_ =~/[\\\/]([^\\\/]+)$/ ? $1 : $_} shift->glob(@_)
}



sub mkdir {
 my ($s, $p, $m) =@_;
 $m =0777 if !$m;
 if (!-d $p) {
    $s->pushmsg("mkdir $p");
    my @p =split /[\\\/]/, $p; 
    my $v ='';
    foreach my $d (@p) {
      $v .= $d;
      ($v eq '') ||mkdir($v, $m) ||die("mkdir '$v': $!\n") if !-d $v;
      $v .='/'
    }
 }
 $p
}



sub rmpath {
 my ($s, $p) =@_;
 my $r =0;
 while ($p && -d $p) {
   last if !rmdir($p);
   $r +=1;
   $s->pushmsg("rmpath $p");
   last if !($p =~/[\\\/][^\\\/]+$/);
   $p =$`;
 }
}



sub size {
 my $s   =shift;
 my $opt =($_[0] =~/^\-/i ? shift : '-i');
 my $file=shift;
 my $sub =(ref($_[0]) ? shift : sub{1});
 my $sze =0;
 $s->find($opt, $file, sub{$sze +=$_[0]->[7] if &$sub(@_)});
 $sze
}



#######################
# File Utils
#######################



sub fcompare {
 my $s =shift;
 my $opt =($_[0] =~/^\-/i ? shift : ''); 
 my $ret =eval("use File::Compare; compare(\@_)");
 if ($@ || $ret <0) {die("compare(" .join(', ',@_) ."): $@\n"); 0}
 else {$ret}
}



sub fhandle {
 my ($s,$file,$sub)=@_;
 my $hdl =select();
 my $ret;
 if (ref($file) || ref(\$file) eq 'GLOB') {select(*$file); $ret =&$sub($hdl); select($hdl)}
 else {
   my $c =(caller(1) ? caller(1) .'::' : '');
   local *{"${c}HANDLE"}; open("${c}HANDLE", $file) || die("open '$file': $!\n");
   select ("${c}HANDLE"); $ret =&$sub($hdl); select($hdl);
   close  ("${c}HANDLE") || die("close '$file': $!\n");
 }
 $ret;
}



sub fload {
 my $s   =shift;
 my $opt =($_[0] =~/^\-/i ? shift : ''); # 'a'rray, 's'calar, 'b'inary
    $opt =$opt .'a' if $opt !~/[asb]/i && wantarray;
 my ($file, $sub) =@_;
 my ($row, @rez);
 local *IN;
 eval ('use Fcntl qw(:DEFAULT :flock)');
 ($] < 5.006 ? open(IN, "<$file") : eval 'open(IN, "<", $file)') 
 || die("open '<$file': $!\n");
 flock(IN, LOCK_SH());
 if    ($sub) {
       $row  =1;
       local $_;
       while (!eof(IN)) {
         defined($_ =<IN>) || die("read '<$file': $!\n");
         chomp;
         $opt=~/a/i ? &$sub() && push(@rez,$_)
                    : &$sub();
       }
 }
 elsif ($opt=~/a/i) {
       while (!eof(IN)) {
         defined($row =<IN>) || die("read '<$file': $!\n");
         chomp($row);
         push (@rez, $row);
       }
 }
 else {
       binmode(IN) if $opt =~/b/i;
       defined(read(IN, $row, -s $file)) || die("read '<$file': $!\n");
 }
 close(IN) || die("close '<$file': $!\n");
 $opt=~/a/i ? @rez : $row
}



sub fstore {
 my $s    =shift;
 my $opt  =($_[0] =~/^\-/i ? shift : ''); # 'b'inary
 my $file =shift;
 local *OUT;
 eval ('use Fcntl qw(:DEFAULT :flock)');
 my $mode ='>';
    $mode ='>>' if $opt =~/>/;
 if (substr($file,0,1) eq '>') {
    $mode ='>>';
    $file =substr($file,1);
 }
 ($] < 5.006 ? open(OUT, "${mode}${file}") : eval 'open(OUT, $mode, $file)')
 || die("open '>$file': $!\n");
 flock(OUT, LOCK_EX());
 if ($opt=~/b/i) {
     binmode(OUT);
     print(OUT @_)   || die("write '>$file': $!\n");
 }
 else {
   foreach my $row (@_) {
     !defined($row)  || print(OUT $row, "\n") || die("write '>$file': $!\n");
   }
 }
 close(OUT)          || die("write '>$file': $!\n");
}



sub fdump {
 my ($s,$f,$d) =@_;
 if  (scalar(@_) >2) {$s->fstore('-',$s->parent->dumpout($d))}
 else                {$s->parent->dumpin($s->fload('-s',$f))}
}



sub fdumpload {
 my ($s,$f) =@_;
 $s->parent->dumpin($s->fload('-s',$f))
}



sub fdumpstore {
 my ($s,$f,$d) =@_;
 $s->fstore('-',$f,$s->parent->dumpout($d))
}



