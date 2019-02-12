## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Utils.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: generic DTA::CAB utilities

package DTA::CAB::Utils;
use Exporter;
use Carp;
use Encode qw(encode decode);
use File::Basename qw(basename);
use File::Temp;
use POSIX qw(strftime); ##-- for strftime
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(Exporter);
our @EXPORT= qw();
our %EXPORT_TAGS =
    (
     minmax => [qw(min2 max2)],
     xml  => [qw(xml_safe_string xml_escape)],
     libxml => [qw(libxml_parser libxml_doc libxml_xpnodes libxml_xpnode libxml_xpvalue libxml_xpcontext)],
     libxslt => [qw(xsl_stylesheet)],
     data => [qw(path_value path_parse)],
     encode => [qw(deep_encode deep_decode deep_recode deep_utf8_upgrade)],
     profile => [qw(si_str profile_str)],
     version => [qw(cab_version)],
     threads => [qw(threads_enabled downup)],
     temp => [qw(tmpfsdir tmpfsfile mktmpfsdir)],
     getopt => [qw(GetArrayOptions GetStringOptions)],
     proc => [qw(mstat memsize memrss pid_cmd)],
     files => [qw(fhbits file_mtime)],
     time => [qw(timestamp_str emavg)]
    );
our @EXPORT_OK = map {@$_} values(%EXPORT_TAGS);
$EXPORT_TAGS{all} = [@EXPORT_OK];

##==============================================================================
## Functions: options
##==============================================================================

## $bool = GetArrayOptions(\@pseudo_argv,  %options)
##  + wrapper for Getopt::Long::GetOptionsFromArray()
sub GetArrayOptions {
  return Getopt::Long::GetOptionsFromArray(@_);
}

## $bool          = GetStringOptions($argv_string, %options)
## ($bool,\@args) = GetStringOptions($argv_string, %options)
##  + wrapper for Getopt::Long::GetOptionsFromString()
sub GetStringOptions {
  return Getopt::Long::GetOptionsFromString(@_);
}

##==============================================================================
## Functions: minmax
##==============================================================================

sub min2 { return $_[0]<$_[1] ? $_[0] : $_[1]; }
sub max2 { return $_[0]>$_[1] ? $_[0] : $_[1]; }

##==============================================================================
## Functions: temporaries
##==============================================================================

## $dir = tmpfsdir()
##  + gets root temporary directory:
##    first writable directory among @ENV{qw(CAB_TMPDIR TMPDIR TMP)},"/tmpfs","/dev/shm","/tmp","."
##  + returns undef if none of the above succeeds
sub tmpfsdir {
  foreach (@ENV{qw(CAB_TMPDIR TMP TMPDIR)},qw(/tmp .)) { #/tmpfs /dev/shm
    return $_ if (defined($_) && -d $_ && -w $_);
  }
  return undef;
}

## $dir = mktmpfsdir($template,%args)
##  + creates new temp directory in tmpfsdir()
sub mktmpfsdir {
  my ($template,%args) = @_;
  $template = "tmpXXXXX" if (!defined($template));
  return File::Temp::tempdir($template, DIR=>tmpfsdir(), %args);
}

## $filename   = tmpfsfile($template,%args)
## ($fh,$file) = tmpfsfile($template,%args)
##   + default %args = (DIR=>tmpfsdir())
sub tmpfsfile {
  use File::Temp;
  my ($template,%args) = @_;
  my ($fh,$file) = File::Temp::tempfile($template, DIR=>tmpfsdir(), %args);
  return ($fh,$file) if (wantarray);
  $fh->close();
  return $file;
}

##==============================================================================
## Functions: threads & semaphores
##==============================================================================

## $bool = threads_enabled()
##  + should return a true value iff the 'threads' module has been loaded
##  + realls just checks for $threads::VERSION
##  + thread support is basically BROKEN (see the v1.16-threads-argh branch for a start)
sub threads_enabled {
  return defined($threads::VERSION);
}


## @rc = downup($semaphore,\&sub,$count=1)          ##-- list context
## $rc = downup($semaphore,\&sub,$count=1)          ##-- scalar context
##  + wraps sub() call in { $semaphore->down() ... $semaphore->up() }, catching die()
##  + thread support is basically BROKEN (see the v1.16-threads-argh branch for a start)
sub downup {
  my ($sem,$sub,$count) = @_;
  $count = 1 if (!defined($count));
  DTA::CAB->trace("downup($sem): DOWN");
  $sem->down($count);
  my (@rc);
  if (wantarray) {
    eval { @rc = $sub->(); };
  } else {
    eval { $rc[0] = $sub->(); };
  }
  DTA::CAB->trace("downup($sem): UP");
  $sem->up($count);
  die ($@) if ($@);
  return wantarray ? @rc : $rc[0];
}


##==============================================================================
## Functions: version dump
##==============================================================================

## $str = cab_version(%opts)
##  + %opts:
##     program          => $program_name,    ##-- default: basename($0) (undef for no report)
##     program_version  => $program_version, ##-- default: undef (don't report)
##     author           => $author,          ##-- default: $DTA::CAB::Utils::CAB_AUTHOR
our $CAB_AUTHOR = "Bryan Jurish <jurish\@bbaw.de>";
sub cab_version {
  my %opts = @_;
  $opts{program} = basename($0) if (!exists($opts{program}));
  $opts{author}  = $CAB_AUTHOR  if (!exists($opts{author}));
  return
    (
     ($opts{program}
      ? ($opts{program}
	 .($opts{program_version} ? " version $opts{program_version}" : '')
	 .($opts{author} ? " by $opts{author}" : '')
	 ."\n")
      : '')
     ." : DTA::CAB version $DTA::CAB::VERSION\n"
     ." : $DTA::CAB::SVNVERSION\n"
    );
}

##==============================================================================
## Functions: XML strings
##==============================================================================

## $safe = xml_safe_string($str)
##  + returns an XML-safe string
sub xml_safe_string {
  my $s = shift;
  $s =~ s/\:\:/\./g;
  $s =~ s/[\s\/\\]/_/g;
  return $s;
}

## $xmlstr = xml_escape($str)
sub xml_escape {
  my $s = shift;
  $s =~ s/\&(?![\w\#]+\;)/\&amp;/g;
  $s =~ s/\'/\&apos;/g;
  $s =~ s/\"/\&quot;/g;
  $s =~ s/\</\&lt;/g;
  $s =~ s/\>/\&gt;/g;
  return $s;
}

##==============================================================================
## Functions: Deep recoding
##==============================================================================

## $decoded = deep_decode($encoding,$thingy,%options)
##  + %options:
##     force    => $bool,   ##-- decode even if the utf8 flag is set
##     skipvals => \@vals,  ##-- don't decode (or recurse into)  $val (overrides $force)
##     skiprefs => \@refs,  ##-- don't decode (or recurse into) $$ref (overrides $force)
##     skippkgs => \@pkgs,  ##-- don't decode (or recurse into) anything of package $pkg (overrides $force)
sub deep_decode {
  my ($enc,$thingy,%opts) = @_;
  my %skipvals = defined($opts{skipvals}) ? (map {($_=>undef)} @{$opts{skipvals}}) : qw();
  my %skiprefs = defined($opts{skiprefs}) ? (map {($_=>undef)} @{$opts{skiprefs}}) : qw();
  my %skippkgs = defined($opts{skippkgs}) ? (map {($_=>undef)} @{$opts{skippkgs}}) : qw();
  my $force    = $opts{force};
  my @queue = (\$thingy);
  my ($ar);
  while (defined($ar=shift(@queue))) {
    if (exists($skiprefs{$ar}) || exists($skipvals{$$ar}) || (ref($$ar) && exists($skippkgs{ref($$ar)}))) {
      next;
    } elsif (UNIVERSAL::isa($$ar,'ARRAY')) {
      push(@queue, map { \$_ } @{$$ar});
    } elsif (UNIVERSAL::isa($$ar,'HASH')) {
      push(@queue, map { \$_ } values %{$$ar});
    } elsif (UNIVERSAL::isa($$ar, 'SCALAR') || UNIVERSAL::isa($$ar,'REF')) {
      push(@queue, $$ar);
    } elsif (!ref($$ar)) {
      $$ar = decode($enc,$$ar) if (defined($$ar) && ($force || !utf8::is_utf8($$ar)));
    }
  }
  return $thingy;
}

## $encoded = deep_encode($encoding,$thingy,%opts)
##  + %opts:
##     force => $bool,            ##-- encode even if the utf8 flag is NOT set
##     skipvals => \@vals,        ##-- don't encode (or recurse into)  $val (overrides $force)
##     skiprefs => \@refs,        ##-- don't encode (or recurse into) $$ref (overrides $force)
##     skippkgs => \@pkgs,        ##-- don't encode (or recurse into) anything of package $pkg (overrides $force)
sub deep_encode {
  my ($enc,$thingy,%opts) = @_;
  my %skipvals = defined($opts{skipvals}) ? (map {($_=>undef)} @{$opts{skipvals}}) : qw();
  my %skiprefs = defined($opts{skiprefs}) ? (map {($_=>undef)} @{$opts{skiprefs}}) : qw();
  my %skippkgs = defined($opts{skippkgs}) ? (map {($_=>undef)} @{$opts{skippkgs}}) : qw();
  my $force    = $opts{force};
  my @queue = (\$thingy);
  my ($ar);
  while (defined($ar=shift(@queue))) {
    if (exists($skiprefs{$ar}) || !defined($$ar) || exists($skipvals{$$ar}) || (ref($$ar) && exists($skippkgs{ref($$ar)}))) {
      next;
    } elsif (UNIVERSAL::isa($$ar,'ARRAY')) {
      push(@queue, map { \$_ } @{$$ar});
    } elsif (UNIVERSAL::isa($$ar,'HASH')) {
      push(@queue, map { \$_ } values %{$$ar});
    } elsif (UNIVERSAL::isa($$ar, 'SCALAR') || UNIVERSAL::isa($$ar,'REF')) {
      push(@queue, $$ar);
    } elsif (!ref($$ar)) {
      $$ar = encode($enc,$$ar) if (defined($$ar) && ($force || utf8::is_utf8($$ar)));
    }
  }
  return $thingy;
}

## $recoded = deep_recode($from,$to,$thingy, %opts);
sub deep_recode {
  my ($from,$to,$thingy,%opts) = @_;
  return deep_encode($to,deep_decode($from,$thingy,%opts),%opts);
}

## $upgraded = deep_utf8_upgrade($thingy)
sub deep_utf8_upgrade {
  my ($thingy) = @_;
  my @queue = (\$thingy);
  my ($ar);
  while (defined($ar=shift(@queue))) {
    if (UNIVERSAL::isa($$ar,'ARRAY')) {
      push(@queue, map { \$_ } @{$$ar});
    } elsif (UNIVERSAL::isa($$ar,'HASH')) {
      push(@queue, map { \$_ } values %{$$ar});
    } elsif (UNIVERSAL::isa($$ar, 'SCALAR') || UNIVERSAL::isa($$ar,'REF')) {
      push(@queue, $$ar);
    } elsif (!ref($$ar)) {
      utf8::upgrade($$ar) if (defined($$ar));
    }
  }
  return $thingy;
}


##==============================================================================
## Functions: abstract data path value
##==============================================================================

## $val_or_undef = path_value($obj, \@path)
## $val_or_undef = path_value($obj, $path_str)
sub path_value {
  my $obj = shift;
  foreach (@{path_parse($_[0])}) {
    return undef if (!ref($obj));
    $obj = (UNIVERSAL::isa($obj,'HASH') ? $obj->{$_}
	    : (UNIVERSAL::isa($obj,'ARRAY') ? $obj->[$_]
	       : (UNIVERSAL::isa($obj,'CODE') ? $obj->($_)
		  : die(__PACKAGE__ . "::path_value(): cannot handle object $obj"))));
  }
  return $obj;
}

## \@path = PACKAGE::path_parse(\@path)
## \@path = PACKAGE::path_parse($path_str)
sub path_parse {
  no warnings 'uninitialized';
  return UNIVERSAL::isa($_[0],'ARRAY') ? $_[0] : [split(m{/},$_[0]=~m{^/} ? substr($_[0],1) : $_[0])];
}


##======================================================
## Profiling

## $str = si_str($float)
sub si_str {
  my $x = shift;
  return sprintf("%.2fY", $x/10**24) if ($x >= 10**24);  ##-- yotta
  return sprintf("%.2fZ", $x/10**21) if ($x >= 10**21);  ##-- zetta
  return sprintf("%.2fE", $x/10**18) if ($x >= 10**18);  ##-- exa
  return sprintf("%.2fP", $x/10**15) if ($x >= 10**15);  ##-- peta
  return sprintf("%.2fT", $x/10**12) if ($x >= 10**12);  ##-- tera
  return sprintf("%.2fG", $x/10**9)  if ($x >= 10**9);   ##-- giga
  return sprintf("%.2fM", $x/10**6)  if ($x >= 10**6);   ##-- mega
  return sprintf("%.2fK", $x/10**3)  if ($x >= 10**3);   ##-- kilo
  return sprintf("%.2f",  $x)        if ($x >= 0);       ##-- (natural units)
  return sprintf("%.2fm", $x*10**3)  if ($x >= 10**-3);  ##-- milli
  return sprintf("%.2fu", $x*10**6)  if ($x >= 10**-6);  ##-- micro
  return sprintf("%.2fn", $x*10**9)  if ($x >= 10**-9);  ##-- nano
  return sprintf("%.2fp", $x*10**12) if ($x >= 10**-12); ##-- pico
  return sprintf("%.2ff", $x*10**15) if ($x >= 10**-15); ##-- femto
  return sprintf("%.2fa", $x*10**18) if ($x >= 10**-18); ##-- atto
  return sprintf("%.2fz", $x*10**21) if ($x >= 10**-21); ##-- zepto
  return sprintf("%.2fy", $x*10**24) if ($x >= 10**-24); ##-- yocto
  return sprintf("%.2g", $x); ##-- default
}

## $str = profile_str($elapsed_secs, $ntoks, $nchrs)
sub profile_str {
  my ($elapsed,$ntoks,$nchrs) = @_;
  my $toksPerSec = si_str($ntoks>0 && $elapsed>0 ? ($ntoks/$elapsed) : -0);
  my $chrsPerSec = si_str($nchrs>0 && $elapsed>0 ? ($nchrs/$elapsed) : -0);
  my $d = int($elapsed/(60*60*24));
  my $h = int($elapsed/(60*60)) % 24;
  my $m = int($elapsed/60) % 60;
  my $s = ($elapsed % 60) + ($elapsed-(60*int($elapsed/60))-($elapsed % 60));
  my $timestr = sprintf("%dd %dh %dm %.2fs (%.2fs)", $d,$h,$m,$s,$elapsed);
  $timestr =~ s/^(?:0[dhm]\s*)+//;
  return sprintf("%d tok, %d chr in %s: %s tok/sec ~ %s chr/sec\n",
		 $ntoks,$nchrs, $timestr, $toksPerSec,$chrsPerSec);
}

##==============================================================================
## Utils: XML::LibXML
##==============================================================================

## %LIBXML_PARSERS
##  + XML::LibXML parsers, keyed by parser attribute strings (see libxml_parser())
our %LIBXML_PARSERS = qw();

## $parser = libxml_parser(%opts)
##  + %opts:
##     line_numbers => $bool,  ##-- default: 1
##     load_ext_dtd => $bool,  ##-- default: 0
##     validation   => $bool,  ##-- default: 0
##     keep_blanks  => $bool,  ##-- default: 1
##     expand_entities => $bool, ##-- default: 1
##     recover => $bool,         ##-- default: 1
sub libxml_parser {
  require XML::LibXML;
  my %opts = @_;
  my %defaults = (
		  line_numbers => 1,
		  load_ext_dtd => 0,
		  validation => 0,
		  keep_blanks => 1,
		  expand_entities => 1,
		  recover => 1,
		 );
  %opts = (%defaults,%opts);
  my $key  = join(', ', map {"$_=>".($opts{$_} ? 1 : 0)} sort(keys(%defaults)));
  return $LIBXML_PARSERS{$key} if ($LIBXML_PARSERS{$key});

  my $parser = $LIBXML_PARSERS{$key} = XML::LibXML->new();
  $parser->keep_blanks($opts{keep_blanks}||0);     ##-- do we want blanks kept?
  $parser->expand_entities($opts{expand_ents}||0); ##-- do we want entities expanded?
  $parser->line_numbers($opts{line_numbers}||0);
  $parser->load_ext_dtd($opts{load_ext_dtd}||0);
  $parser->validation($opts{validation}||0);
  $parser->recover($opts{recover}||0);
  return $parser;
}

## $doc = libxml_doc($which=>$src, %parserOpts)
##  + $which is one of 'file', 'string', 'fh', or 'doc'
sub libxml_doc {
  my ($which,$src,%opts) = @_;
  my $parser = libxml_parser(%opts);
  if ($which eq 'file') {
    return $parser->parse_file($src);
  } elsif ($which eq 'fh') {
    return $parser->parse_fh($src);
  } elsif ($which eq 'string') {
    return $parser->parse_string($src);
  } elsif ($which eq 'doc') {
    return $src;
  }
  confess(__PACKAGE__, "::libxml_doc() unknown source type '$which'!");
  return undef;
}

## \@vals = libxml_xpnodes($nod,$xpath)
##   + wrapper for scalar($nod->findnodes($xpath)||[])
sub libxml_xpnodes {
  return undef if (!defined($_[0]));
  return scalar($_[0]->findnodes($_[1]));
}

## \@vals = libxml_xpnode($nod,$xpath)
##   + wrapper for scalar($nod->findnodes($xpath)||[])->[0]
sub libxml_xpnode {
  return (libxml_xpnodes(@_)||[])->[0];
}

## $val_or_undef = libxml_xpvalue($nod,$xpath)
##   + wrapper for $nod->findnodes($xpath)->[0]->textContent
sub libxml_xpvalue {
  my $nod = libxml_xpnode(@_);
  return defined($nod) ? $nod->textContent : undef;
}

## $xpc = libxml_xpcontext($doc_or_nod)
##  + returns an XML::LibXML::XPathContext suitable for matching $doc_or_nod
##    - if $doc_or_nod is an XML::LibXML::Document, its root node is used as context, otherwise $nod
##  + registers all namespaces returned by $doc_or_nod->namespaces()
sub libxml_xpcontext {
  my $nod = shift;
  $nod = $nod->documentElement if (UNIVERSAL::isa($nod,'XML::LibXML::Document'));
  my $xc = XML::LibXML::XPathContext->new($nod);
  $xc->registerNs(($_->declaredPrefix||'DEFAULT'),$_->declaredURI) foreach ($nod ? $nod->namespaces : qw());
  return $xc;
}

##==============================================================================
## Utils: XML::LibXSLT
##==============================================================================

## $XSLT
##  + package-global shared XML::LibXSLT object (or undef)
our $XSLT = undef;

## $xslt = PACKAGE::xsl_xslt()
##  + returns XML::LibXSLT object
sub xsl_xslt {
  require XML::LibXML;
  require XML::LibXSLT;
  $XSLT = XML::LibXSLT->new() if (!$XSLT);
  return $XSLT;
}

## $stylesheet = PACKAGE::xsl_stylesheet(file=>$xsl_file)
## $stylesheet = PACKAGE::xsl_stylesheet(fh=>$xsl_fh)
## $stylesheet = PACKAGE::xsl_stylesheet(doc=>$xsl_doc)
## $stylesheet = PACKAGE::xsl_stylesheet(string=>$xsl_string)
sub xsl_stylesheet {
  require XML::LibXML;
  require XML::LibXSLT;
  my ($which,$src) = @_;
  my $xsldoc = libxml_doc($which=>$src, line_numbers=>1);
  confess(__PACKAGE__, "::xsl_stylesheet: could not parse XSL $which source as XML: $!") if (!$xsldoc);

  my $xslt = xsl_xslt();
  my $stylesheet = $xslt->parse_stylesheet($xsldoc)
    or confess(__PACKAGE__, "::xsl_stylesheet(): could not parse XSL $which document as stylesheet: $!");

  return $stylesheet;
}

##==============================================================================
## Functions: file stuff
##==============================================================================

## $bits = fhbits(@fhs_or_fds)
sub fhbits {
  my $bits='';
  vec($bits,$_,1)=1 foreach (map {ref($_) ? fileno($_) : $_} @_);
  return $bits;
}

##==============================================================================
## Functions: proc filestsystem

## \%mstat_or_undef = mstat()
## \%mstat_or_undef = mstat($pid=$$)
## \%mstat_or_undef = mstat(\%mstat)
##   + class or instance method
sub mstat {
  my $that = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  return $_[0] if (UNIVERSAL::isa($_[0],'HASH')); ##-- redundant call mstat(\%mstat)
  my $pid  = shift || $$;
  open(my $fh, "/proc/$pid/statm") or return {pid=>$pid};
  local $/ = undef;
  my $buf = <$fh>;
  chomp($buf);
  close($fh);
  my (%mstat);
  @mstat{qw(pid size resident share text lib data dt)} = ($pid, split(' ',$buf));
  $mstat{pagesize} = POSIX::sysconf( POSIX::_SC_PAGESIZE );
  return \%mstat;
}

## $memsize_kb_or_undef = memsize()
## $memsize_kb_or_undef = memsize($pid)
## $memsize_kb_or_undef = memsize(\%mstat)
##  + virtual memory size (address space)
sub memsize {
  my $that  = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my $mstat = $that->mstat(@_);
  return defined($mstat) ? $mstat->{size}*(($mstat->{pagesize}||4096)/1024) : undef;
}

## $resident_kb_or_undef = memrss()
## $resident_kb_or_undef = memrss($pid)
## $resident_kb_or_undef = memrss(\%mstat)
##  + resident set size (physical memory used)
sub memrss {
  my $that  = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my $mstat = $that->mstat(@_);
  return defined($mstat) ? $mstat->{resident}*(($mstat->{pagesize}||4096)/1024) : undef;
}

## $cmd = pid_cmd($pid)
sub pid_cmd {
  my $that  = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my $pid = shift;
  my ($fh,$buf);
  return
    ($pid && (readlink("/proc/$pid/exe")
	      || do {
		open($fh, "/proc/$pid/cmdline")
		  && scalar($buf=<$fh>)
		  && (split(/\0/,$buf,2))[0]
		})
    ) || undef;
}

##==============================================================================
## Functions: files

## $mtime_in_floating_seconds = file_mtime($filename_or_fh)
##  + de-references symlinks
sub file_mtime {
  my $that  = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my $file = shift;
  my @stat = (UNIVERSAL::can('Time::HiRes','stat') ? Time::HiRes::stat($file) : stat($file));
  return $stat[9];
}

##==============================================================================
## Functions: time

## $timestamp_str = PACAKGE::timestamp_str()
## $timestamp_str = PACAKGE::timestamp_str($time)
sub timestamp_str {
  my $that = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my $time = @_ ? shift : time();
  return POSIX::strftime("%FT%T%z", localtime($time));
}

## DTA::CAB::Utils::EMA : exponential moving average
package DTA::CAB::Utils::EMA;
use strict;

## $ema = PACKAGE->new(%args)
##  + %args, object structure:
##    {
##     decay  => \@seconds, ##-- number(s) of seconds until the contribution of a sample falls below 1/e (default=[60 300 900] ~ 1,5,15 minutes)
##     vals   => \@vals,    ##-- current moving average values (default=0)
##     t      => $time,     ##-- timestamp of the current sample as returned by Time::HiRes::gettimeofday (default=current timestamp)
##    }
sub new {
  require Time::HiRes;
  my $that = shift;
  my $ema  = {
	      decay =>[60, (5*60), (15*60)],
	      vals  =>[],
	      t     =>[Time::HiRes::gettimeofday()],
	      @_,
	     };
  $ema->{vals}[$_] //= 0 foreach (0..$#{$ema->{decay}});
  return bless($ema,ref($that)||$that);
}

## $ema = $ema->append($newValue)
## $ema = $ema->append($newValue,$newTime)
##  + append a new sample value with timestamp $newTime
sub append {
  require Time::HiRes;
  my ($ema,$newVal,$newTime) = @_;
  $newVal  //= 0;
  $newTime   = [Time::HiRes::gettimeofday()] if (!$newTime);
  my $tdiff  = Time::HiRes::tv_interval($ema->{t},$newTime);
  my ($alpha);
  foreach (0..$#{$ema->{decay}}) {
    $alpha = exp(-$tdiff/$ema->{decay}[$_]);
    $ema->{vals}[$_] = (1-$alpha)*$newVal + $alpha*$ema->{vals}[$_];
  }
  $ema->{t} = $newTime;
  return $ema;
}

##  @vals = $ema->vals($newVal,$newTime)
## \@vals = $ema->vals($newVal,$newTime)
##  + wrapper for $ema->append($newVal,$newTime)->{vals}
##  + optionally append a sample and return current (decayed) value(s)
##  + default $newVal=0, default $newTime=[Time::HiRes::gettimeofday] --> current decayed sample values
sub vals {
  $_[0]->append(@_[1..$#_]);
  return wantarray ? @{$_[0]{vals}} : $_[0]{vals};
}


1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Utils - generic DTA::CAB utilities

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::CAB::Utils;
 
 ##========================================================================
 ## Functions: XML strings
 
 $safe = xml_safe_string($str);
 
 ##========================================================================
 ## Functions: Deep recoding
 
 $decoded = deep_decode($encoding,$thingy,%options);
 $encoded = deep_encode($encoding,$thingy,%opts);
 $recoded = deep_recode($from,$to,$thingy, %opts);
 $upgraded = deep_utf8_upgrade($thingy);
 
 ##========================================================================
 ## Functions: abstract data path value
 
 $val_or_undef = path_value($obj,@path);

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Utils: Globals
=pod

=head2 Globals

=over 4

=item Variable: @EXPORT

No symbols are exported by default.

=item Variable: %EXPORT_TAGS

Supports the following export tags:

 :xml     ##-- xml_safe_string
 :data    ##-- path_value
 :encode  ##-- deep_encode, deep_decode, deep_recode, deep_utf8_upgrade

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Utils: Functions: XML strings
=pod

=head2 Functions: XML strings

=over 4

=item xml_safe_string

 $safe = xml_safe_string($str);

Returns a string $safe similar to the argument $str which
can function as an element or attribute name in XML.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Utils: Functions: Deep recoding
=pod

=head2 Functions: Deep recoding

=over 4

=item deep_decode

 $decoded = deep_decode($encoding,$thingy,%options);

Perform recursive string decoding on all scalars in $thingy.
Does B<NOT> check for cyclic references.

%options:

 force    => $bool,   ##-- decode even if the utf8 flag is set
 skipvals => \@vals,  ##-- don't decode (or recurse into)  $val (overrides $force)
 skiprefs => \@refs,  ##-- don't decode (or recurse into) $$ref (overrides $force)
 skippkgs => \@pkgs,  ##-- don't decode (or recurse into) anything of package $pkg (overrides $force)


=item deep_encode

 $encoded = deep_encode($encoding,$thingy,%opts);

Perform recursive string encoding on all scalars in $thingy.
Does B<NOT> check for cyclic references.

%opts:

 force => $bool,            ##-- encode even if the utf8 flag is NOT set
 skipvals => \@vals,        ##-- don't encode (or recurse into)  $val (overrides $force)
 skiprefs => \@refs,        ##-- don't encode (or recurse into) $$ref (overrides $force)
 skippkgs => \@pkgs,        ##-- don't encode (or recurse into) anything of package $pkg (overrides $force)

=item deep_recode

 $recoded = deep_recode($from,$to,$thingy, %opts);

Wrapper for:

 deep_encode($to,deep_decode($from,$thingy,%opts),%opts);

=item deep_utf8_upgrade

 $upgraded = deep_utf8_upgrade($thingy);

Perform recursive utf_uprade() on all scalars in $thingy.
Does B<NOT> check for cyclic references.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Utils: Functions: abstract data path value
=pod

=head2 Functions: abstract data path value

=over 4

=item path_value

 $val_or_undef = path_value($obj,@path);

Gets the value of the data path @path in $obj.

=back

=cut

##========================================================================
## END POD DOCUMENTATION, auto-generated by podextract.perl

##======================================================================
## Footer
##======================================================================

=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2019 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
