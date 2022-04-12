# Copyright © Jim Avera 2012-2022.  This software may be distributed,
# at your option, under the GNU General Public License version 1 or 
# any later version, or the Perl "Artistic License".
#
# The above license restrictions apply solely because this library contains 
# code snippets extracted from perl5db.pl and JSON::PP, which are marked
# as such in adjacent comments in the code.  Those items are distributed
# under the license terms given above.  The author of this library, Jim Avera,
# has dedicated the remaining portions of this library to the Public Domain
# per Creative Commons CC0 (http://creativecommons.org/publicdomain/zero/1.0/).
# You may use portions other than the above-mentioned extracts without any
# restriction, but the library as a whole (or any portion containing those 
# extracts) may only be distributred under the said software licenses.

##FIXME: Blessed structures are not formatted because we treat bless(...) as an atom

use strict; use warnings FATAL => 'all'; use utf8; use 5.020;
use feature qw(say state);
package  Data::Dumper::Interp;
$Data::Dumper::Interp::VERSION = '3.1';

package  # newline prevents Dist::Zilla::Plugin::PkgVersion from adding $VERSION
  DB;
sub DB_Vis_Evalwrapper { # Must appear before any variables are declared
  eval $Data::Dumper::Interp::string_to_eval; ## no critic
}

package Data::Dumper::Interp;
# POD documentation follows __END__

use Data::Dumper v2.174 ();
use Carp;
use POSIX qw(INT_MAX);
use Encode ();
use Scalar::Util qw(blessed reftype refaddr looks_like_number);
use List::Util qw(min max first any pairmap);
use Regexp::Common qw/RE_balanced/;
use Term::ReadKey ();
use overload ();

sub _dbvis(_) {  # for our internal debugging messages
  chomp( my $s = Data::Dumper->new([shift])->Useqq(1)->Terse(1)->Indent(0)->Dump );
  $s
}
sub _dbvisq(_) {  # for our internal debugging messages
  chomp( my $s = Data::Dumper->new([shift])->Useqq(0)->Terse(1)->Indent(0)->Dump );
  $s
}
sub _dbavis(@) { "(" . join(", ", map{_dbvis} @_) . ")" }
our $_dbmaxlen = 300;
sub _dbrawstr(_) { "«".(length($_[0])>$_dbmaxlen ? substr($_[0],0,$_dbmaxlen-3)."..." : $_[0])."»" }
sub _dbstr($) {
  local $_ = shift;
  s/\n/\N{U+2424}/sg; # a special NL glyph
  s/[\x{00}-\x{20}]/ chr( ord($&)+0x2400 ) /aseg;
  _dbrawstr($_) . " (".length().")";
}
sub _dbstrposn($$) {
  local $_ = shift;
  my $posn = shift;
  local $_dbmaxlen = max($_dbmaxlen+2, $posn+2);
  $_ = _dbstr($_);
  $_ .= "\n " . (" " x $posn) . "^";
}
sub oops(@) { @_ = ("\n".__PACKAGE__." oops:",@_,"\n  "); goto &Carp::confess }

use Exporter 'import';
our @EXPORT    = qw(vis  avis  alvis  ivis  dvis  hvis  hlvis
                    visq avisq alvisq ivisq dvisq hvisq hlvisq
                    u quotekey qsh _forceqsh qshpath);

our @EXPORT_OK = qw($Debug $MaxStringwidth $Truncsuffix $Overloads $Foldwidth
                    $Useqq $Quotekeys $Sortkeys $Sparseseen
                    $Maxdepth $Maxrecurse $Deparse);

our @ISA       = ('Data::Dumper'); # see comments at new()

############### Utility Functions #################

sub u(_) { $_[0] // "undef" }
sub quotekey(_); # forward.  Implemented after regex declarations.
sub _forceqsh(_) {
  # Unlike Perl, /bin/sh does not recognize any backslash escapes in '...'
  local $_ = shift;
  return "undef" if !defined;
  $_ = vis($_) if ref;
  # Prefer "double quoted" if no shell escapes would be needed
  if (/["\$`!\\\x{00}-\x{1F}\x{7F}]/) {
    s/'/'\\''/g; # foo'bar => foo'\''bar
    return "'${_}'";
  } else {
    return "\"${_}\"";
  }
}
sub qsh(_) {
  local $_ = shift;
  defined && !/[^-=\w_\/:\.,]/ && $_ ne "" && !ref ? $_ : _forceqsh
}
sub qshpath(_) {  # like qsh but does not quote initial ~ or ~username
  local $_ = shift;
  return qsh if !defined or ref;
  my ($tilde_prefix, $rest) = /^( (?:\~[^\/\\]*[\/\\]?+)? )(.*)/xs or die;
  $rest eq "" ? $tilde_prefix : $tilde_prefix.qsh($rest)
}

#################### Configuration Globals #################

our ($Debug, $MaxStringwidth, $Truncsuffix, $Overloads,
     $Foldwidth, $Foldwidth1,
     $Useqq, $Quotekeys, $Sortkeys, $Sparseseen,
     $Maxdepth, $Maxrecurse, $Deparse);

$Debug          = 0            unless defined $Debug;
$MaxStringwidth = 0            unless defined $MaxStringwidth;
$Truncsuffix    = "..."        unless defined $Truncsuffix;
$Overloads      = 1            unless defined $Overloads;
$Foldwidth      = undef        unless defined $Foldwidth;  # undef auto-detects
$Foldwidth1     = undef        unless defined $Foldwidth1; # override for 1st

# The following override Data::Dumper defaults
$Useqq          = "utf8:controlpics" unless defined $Useqq;
$Quotekeys      = 0            unless defined $Quotekeys;
$Sortkeys       = \&__sortkeys unless defined $Sortkeys;
$Sparseseen     = 1            unless defined $Sparseseen;
$Maxdepth       = $Data::Dumper::Maxdepth   unless defined $Maxdepth;
$Maxrecurse     = $Data::Dumper::Maxrecurse unless defined $Maxrecurse;
$Deparse        = 0             unless defined $Deparse;

#################### Methods #################

sub Debug {
  my($s, $v) = @_;
  @_ == 2 ? (($s->{Debug} = $v), return $s) : $s->{Debug};
}
sub MaxStringwidth {
  my($s, $v) = @_;
  @_ == 2 ? (($s->{MaxStringwidth} = $v), return $s) : $s->{MaxStringwidth};
}
sub Truncsuffix {
  my($s, $v) = @_;
  @_ == 2 ? (($s->{Truncsuffix} = $v), return $s) : $s->{Truncsuffix};
}
sub Overloads {
  my($s, $v) = @_;
  @_ == 2 ? (($s->{Overloads} = $v), return $s) : $s->{Overloads};
}
sub Foldwidth {
  my($s, $v) = @_;
  @_ == 2 ? (($s->{Foldwidth} = $v), return $s) : $s->{Foldwidth};
}
sub Foldwidth1 {  # experimental
  my($s, $v) = @_;
  @_ == 2 ? (($s->{Foldwidth1} = $v), return $s) : $s->{Foldwidth1};
}
sub Terse  { confess "Terse() may not be called on ", __PACKAGE__, " objects" }
sub Indent { confess "Indent() may not be called on ", __PACKAGE__, " objects" }

sub _vistype {
  my($s, $v) = @_;
  @_ >= 2 ? (($s->{_vistype} = $v), return $s) : $s->{_vistype};
}

# Our new() takes no parameters and returns a default-initialized object,
# on which option-setting methods may be called and finally "vis", "avis", etc.
# as a method to produce the output (those routines can also be called as
# functions, in which case they create a new object internally).
#
# An earlier version of this package was a true drop-in replacement for
# Data::Dumper and supported all of the same APIs (mostly by inheritance)
# including Data::Dumper's new([values],[names]) constructor.
# Extensions were accessed via differently-named alternative constructors.
#
# This package is no longer API compatible with Data::Dumper,
# but uses the same option-setting paradigm where methods like Foldwidth()
# modify the object if called with arguments while returning the object to
# allow method chaining.
#
# Global variabls in Data::Dumper::Interp are provided for all config options
# which users may change on Data::Dumper::Interp objects.
sub new {
  croak "No args are allowed for ".__PACKAGE__."::new" if @_ > 1;
  my ($class) = @_;
  (bless $class->SUPER::new([],[]), $class)->_config_defaults()
}

########### Subs callable as either a Function or Method #############

sub __chop_loc($) {
  (local $_ = shift) =~ s/ at .*? line \d+[^\n]*\n?\z//s;
  $_
}
sub __getobj {
  # Args are not evaluated until referenced, and tie handlers might throw
  my $bl; do{ local $@; eval {$bl=blessed($_[0])}; croak __chop_loc($@) if $@ };
  $bl && $_[0]->isa(__PACKAGE__) ? shift : __PACKAGE__->new()
}
sub __getobj_s { &__getobj->Values([$_[0]]) }
sub __getobj_a { &__getobj->Values([\@_])   } #->Values([[@_]])
sub __getobj_h {
  my $o = &__getobj;
  (scalar(@_) % 2)==0 or croak "Uneven number args for hash key => val pairs";
  $o ->Values([{@_}])
}

# These can be called as *FUNCTIONS* or as *METHODS*
sub vis(_)    { &__getobj_s ->_vistype('s' )->Dump; }
sub visq(_)   { &__getobj_s ->_vistype('s' )->Useqq(0)->Dump; }
sub avis(@)   { &__getobj_a ->_vistype('a' )->Dump; }
sub avisq(@)  { &__getobj_a ->_vistype('a' )->Useqq(0)->Dump; }
sub hvis(@)   { &__getobj_h ->_vistype('h' )->Dump; }
sub hvisq(@)  { &__getobj_h ->_vistype('h' )->Useqq(0)->Dump; }
sub alvis(@)  { substr &avis,  1, -1 }  # bare List without parenthesis
sub alvisq(@) { substr &avisq, 1, -1 }
sub hlvis(@)  { substr &hvis,  1, -1 }
sub hlvisq(@) { substr &hvisq, 1, -1 }

# Trampolines which replace the call frame with a call directly to the
# interpolation code which uses $package DB to access the user's context.
sub ivis(_) { @_=(&__getobj,          shift,'s');goto &_Interpolate }
sub ivisq(_){ @_=(&__getobj->Useqq(0),shift,'s');goto &_Interpolate }
sub dvis(_) { @_=(&__getobj,          shift,'d');goto &_Interpolate }
sub dvisq(_){ @_=(&__getobj->Useqq(0),shift,'d');goto &_Interpolate }

############# only internals follow ############

sub _config_defaults {
  my $self = shift;

  &__set_default_Foldwidth if ! defined $Foldwidth;

  $self
    ->Debug($Debug)
    ->MaxStringwidth($MaxStringwidth)
    ->Foldwidth($Foldwidth)
    ->Foldwidth1($Foldwidth1)
    ->Overloads($Overloads)
    ->Truncsuffix($Truncsuffix)
    ->Quotekeys($Quotekeys)
    ->Maxdepth($Maxdepth)
    ->Maxrecurse($Maxrecurse)
    ->Deparse($Deparse)
    ->Sortkeys($Sortkeys)
    ->Sparseseen($Sparseseen)
    ->Useqq($Useqq)
    ->SUPER::Terse(1)
    ->SUPER::Indent(0)
}

sub __set_default_Foldwidth() {
  if (u($ENV{COLUMNS}) =~ /^[1-9]\d*$/) {
    $Foldwidth = $ENV{COLUMNS}; # overrides actual terminal width
    say "Default Foldwidth=$Foldwidth from ENV{COLUMNS}" if $Debug;
  } else {
    local *_; # Try to avoid clobbering special filehandle "_"
    # Does not yet work, see https://github.com/Perl/perl5/issues/19142
    my ($width, $height) = Term::ReadKey::GetTerminalSize(
      -t STDERR ? *STDERR : -t STDOUT ? *STDOUT
      : do{my $fh; for("/dev/tty",'CONOUT$') { last if open $fh, $_ } $fh}
    );
    if (($Foldwidth = $width)) {
      say "Default Foldwidth=$Foldwidth from Term::ReadKey" if $Debug;
    } else {
      $Foldwidth = 80;
      say "Foldwidth=$Foldwidth from hard-coded backup default" if $Debug;
    }
  }
}

my $unique = refaddr \&new;
my $magic_num_prefix    = "<NUMMagic$unique>";
my $magic_numstr_prefix = "<NUMSTRMagic$unique>";
my $COPY_NEEDED = "_CN_$unique";
sub __COPY_NEEDED() { $COPY_NEEDED }

sub _doedits {
  my $self = shift;
  my ($item, $testonly, $maxstringwidth, $truncsuf, $overloads) = @_;
  return undef
    unless defined($item);
  if ($maxstringwidth) {
    if (ref($item) eq "") { # a scalar
      if (!_show_as_number($item)
          && length($item) > $maxstringwidth + length($truncsuf)) {
        return __COPY_NEEDED if $testonly;
        $item = substr($item,0,$maxstringwidth).$truncsuf;
      }
    }
  }
  #if (my $class = blessed($item)) {
  if (overload::Overloaded($item)) {
    my $class = blessed($item) // oops;
    if (any { ref() eq "Regexp" ? $class =~ $_
                                : ($_ eq "1" || $_ eq $class) 
            } @$overloads) {
      # Stringify objects which have the stringification operator
      if (overload::Method($class,'""')) {
        return __COPY_NEEDED if $testonly;
        my $prefix = _show_as_number($item) ? $magic_num_prefix : "";
        $item = "${prefix}($class)".$item;  # *calls stringify operator*
      }
      # Substitute the virtual value behind an overloaded deref operator
      elsif (overload::Method($class,'@{}')) {
        return __COPY_NEEDED if $testonly;
        $item = \@{ $item };
      }
      elsif (overload::Method($class,'%{}')) {
        return __COPY_NEEDED if $testonly;
        $item = \%{ $item };
      }
      elsif (overload::Method($class,'${}')) {
        return __COPY_NEEDED if $testonly;
        $item = \${ $item };
      }
      elsif (overload::Method($class,'&{}')) {
        return __COPY_NEEDED if $testonly;
        $item = \&{ $item };
      }
      elsif (overload::Method($class,'*{}')) {
        return __COPY_NEEDED if $testonly;
        $item = \*{ $item };
      }
    }
  }
  # Prepend a "magic prefix" (later removed) to items which Data::Dumper is
  # likely to represent wrongly or anyway not how we want:
  #
  #  1. Scalars set to strings like "6" will come out as a number 6 rather
  #     than "6" with Useqq(1) or Useperl(1) (string-ness is preserved
  #     with other options).  IMO this is a Data::Dumper bug which the
  #     maintainers won't fix it because the difference isn't functionally
  #     relevant to correctly-written Perl code.  However we want to help
  #     humans debug their software and so want to see the representation
  #     most likely to be what the programmer used to create the datum.
  #
  #  2. Floating point values come out as "strings" to avoid some
  #     cross-platform problem issue.  For our purposes we want all numbers 
  #     to appear as numbers.
  if (!reftype($item) && looks_like_number($item)) {
    return __COPY_NEEDED if $testonly;
    my $prefix = _show_as_number($item) ? $magic_num_prefix 
                                        : $magic_numstr_prefix;
    $item = $prefix.$item;
  }
  $item
}

sub Dump {
  my $self = $_[0];
  local $_;
  &_SaveAndResetPunct;
  if (! ref $self) { # ala Data::Dumper
    $self = $self->new(@_[1..$#_]);
  } else {
    croak "extraneous args" if @_ != 1;
  }

  my ($maxstringwidth, $overloads, $debug)
    = @$self{qw/MaxStringwidth Overloads Debug/};

  # Do desired substitutions in a copy of the data.
  #
  # (This used to just Clone:clone the whole thing and then walk and modify 
  # the copy; but cloned tied variables could blow up if their handlers
  # got conused by our changes in the copy.  Now our copy never contains
  # tied variables, although it might contain cloned objects (with any
  # internal tied vars substituted).

  { my @values = $self->Values;
    croak "No Values set" if @values == 0;
    croak "Only a single scalar value is allowed" if @values > 1;
    $maxstringwidth //= 0;
    $maxstringwidth = 0 if $maxstringwidth >= INT_MAX;
    my $truncsuf = $self->{Truncsuffix};
    $overloads = [ $overloads ] unless ref($overloads) eq 'ARRAY';
    $overloads = undef unless grep{ $_ } @$overloads; # all false?
    my $callback = sub { 
      $self->_doedits(@_, $maxstringwidth, $truncsuf, $overloads) 
    };
    eval { 
      $values[0] = __copysubst($values[0], $callback)
    };
    croak "Exception while traversing value: $@" if $@;
    $self->Values(\@values);
  }

  # We always call Data::Dumper with Indent(0) and Pad("") to get a single
  # maximally-compact string, and then manually fold the result to Foldwidth,
  # and insert the user's Pad before each line.
  my $pad = $self->Pad();
  $self->Pad("");
  {
    my ($sAt, $sQ) = ($@, $?); # Data::Dumper corrupts these
    $_ = $self->SUPER::Dump;
    ($@, $?) = ($sAt, $sQ);
  }
  $self->Pad($pad);
  $_ = $self->_postprocess_DD_result($_);

  &_RestorePunct;
  $_
}

# Recursively copy an arbitrary structure, calling a callback to provide
# possibly-substitute values.  The callback will be called again on any
# substituted values until no substitution occurs (i.e. the original value
# is returned).
#
# A "testonly" parameter to the callback indicates that the callback
# may return __COPY_NEEDED as soon as it determines that a substitute 
# value will probably be provided; the callback may ignore this parameter and 
# always just return the substitute value, if that is easier.
#
# Substitute values may not use tied variables or overloads because the
# copy-and-substitute process may cause tie handlers to encounter unexpected
# data, and misbehave.  The copy machinery re-creates all refs so as to
# disable any overloads initially present; if the virtual content behind an
# overload is desired, the callback must perform the overloaded operation(s) 
# and return the virtual content as a substition value.

sub _x_same_items($$) {
  my ($a, $b) = @_;
  return 0 if ref($a) ne ref($b); # different types or different classes
  return 1 if !defined($a) and !defined($b);
  return 0 if !defined($a) or !defined($b);
  # avoid executing any overloads
  ref($a) ? (refaddr($a)==refaddr($b)) : ($a eq $b)  
}
sub _same_items($$) {
  my ($a, $b) = @_;
  my $r = _x_same_items($a,$b);
  #say "# _same_items ",_dbvis($a)," ",_dbvis($b)," = ", _dbvis($r);
  $r
}

sub __copysubst($$;$$);
sub __copysubst($$;$$) {
  my ($item, $coderef, $testonly, $seenhash) = @_;
  no warnings 'recursion';
  $seenhash //= {};
  my $rt = reftype($item);
  if ($rt) {
    return $item if $seenhash->{ refaddr($item) }; # increment only below
  }
  if (! defined $testonly) {
    #say "## testing ", _dbvis($item);
    $testonly = 1;
    my $testresult = __copysubst($item, $coderef, $testonly, $seenhash);
    return $item
      if _same_items($item, $testresult)
         && ref($testresult) || u($testresult) ne __COPY_NEEDED;
    #say "## copy needed!";
    $testonly = 0;
    $seenhash = {};
  }

  my $count;
  for(;;) { 
    my $nitem = $coderef->($item, $testonly);
    last if _same_items($item, $nitem);
    return __COPY_NEEDED
      if $testonly && u($nitem) eq __COPY_NEEDED;
    $item = $nitem;
    oops "Too many repeated substitutions" if ++$count > 10;
  } 
  $rt = reftype($item);
  if ($rt) {
    $seenhash->{ refaddr($item) }++;
    my $class = blessed($item);

    if ($rt eq "REF" || $rt eq "SCALAR") {
      my $copy = __copysubst(${ $item }, $coderef, $testonly, $seenhash);
      return __COPY_NEEDED
        if $testonly && u($copy) eq __COPY_NEEDED;
      $item = \$copy;
    }
    elsif ($rt eq "ARRAY") {
      $item = [ map{ __copysubst($_, $coderef, $testonly, $seenhash) }
                   @$item ];
      return __COPY_NEEDED
        if $testonly && grep {u() eq __COPY_NEEDED} @$item;
    }
    elsif ($rt eq "HASH") {
      $item = {
        pairmap { ( __copysubst($a, $coderef, $testonly, $seenhash)
                    =>
                    __copysubst($b, $coderef, $testonly, $seenhash) ) 
                } %$item
      };
      return __COPY_NEEDED
        if $testonly && grep {u() eq __COPY_NEEDED} %$item;
    }
    bless $item, $class if $class; # re-create objects
  }
  # Else not a ref, or else a ref we don't know how to handle.
  $item
}#__copysubst

sub _show_as_number(_) { # Derived from JSON::PP version 4.02
  my $value = shift;
  return unless defined $value;
  no warnings 'numeric';
  # if the utf8 flag is on, it almost certainly started as a string
  return if utf8::is_utf8($value);
  # detect numbers
  # string & "" -> ""
  # number & "" -> 0 (with warning)
  # nan and inf can detect as numbers, so check with * 0
  return unless length((my $dummy = "") & $value);
  return unless 0 + $value eq $value;
  return 1 if $value * 0 == 0;
  return -1; # inf/nan
}

# Split keys into "components" (e.g. 2_16.A has 3 components) and sort
# components containing only digits numerically.
sub __sortkeys {
  my $hash = shift;
  return [
    sort { my @a = split /([_\W])/,$a;
           my @b = split /([_\W])/,$b;
           for (my $i=0; $i <= $#a; ++$i) {
             return 1 if $i > $#b;  # a is longer
             my $r = ($a[$i] =~ /^\d+$/ && $b[$i] =~ /^\d+$/)
                      ? ($a[$i] <=> $b[$i]) : ($a[$i] cmp $b[$i]) ;
             return $r if $r != 0;
           }
           return -1 if $#a < $#b; # a is shorter
           return 0;
         }
         keys %$hash
  ]
}

my $balanced_re = RE_balanced(-parens=>'{}[]()');

# cf man perldata
my $userident_re = qr/ (?: (?=\p{Word})\p{XID_Start} | _ )
                           (?: (?=\p{Word})\p{XID_Continue}  )* /x;

my $pkgname_re = qr/ ${userident_re} (?: :: ${userident_re} )* /x;

our $curlies_re = RE_balanced(-parens=>'{}');
our $parens_re = RE_balanced(-parens=>'()');
our $curliesorsquares_re = RE_balanced(-parens=>'{}[]');

my $anyvname_re =
  qr/ ${pkgname_re} | [0-9]+ | \^[A-Z]
                    | [-+!\$\&\;i"'().,\@\/:<>?\[\]\~\^\\] /x;

my $anyvname_or_refexpr_re = qr/ ${anyvname_re} | ${curlies_re} /x;

my %qqesc2controlpic = (
  '\0' => "\N{SYMBOL FOR NULL}",
  '\a' => "\N{SYMBOL FOR BELL}",
  '\b' => "\N{SYMBOL FOR BACKSPACE}",
  '\e' => "\N{SYMBOL FOR ESCAPE}",
  '\f' => "\N{SYMBOL FOR FORM FEED}",
  '\n' => "\N{SYMBOL FOR NEWLINE}",
  '\r' => "\N{SYMBOL FOR CARRIAGE RETURN}",
  '\t' => "\N{SYMBOL FOR HORIZONTAL TABULATION}",
);

sub __unesc_unicode() {  # edits $_
  if (/^"/) {
    # Data::Dumper outputs wide characters as escapes with Useqq(1).
  
    s{ \G (?: [^\\]++ | \\[^x] )*+ \K (?<w> \\x\{ (?<hex>[a-fA-F0-9]+) \} )
     }{
        my $orig = $+{w};
        local $_ = hex( length($+{hex}) > 6 ? '0' : $+{hex} );
        $_ = $_ > 0x10FFFF ? "\0" : chr($_); # 10FFFF is Unicode limit
        # Using 'lc' so regression tests do not depend on Data::Dumper's
        # choice of case when escaping wide characters.
        m<\P{XPosixGraph}|[\0-\377]> ? lc($orig) : $_
      }xesg;
  } 
}
sub __subst_controlpics() {  # edits $_
  if (/^"/) {
    s{ \G (?: [^\\]++ | \\[^0abefnrt] )*+ \K ( \\[abefnrt] | \\0(?![0-7]) )
     }{
        $qqesc2controlpic{$1} // $1
      }xesg;
  }
}

my $indent_unit;
my $linelen;
my $reserved;
my $outstr;
my @stack; # [offset_of_start, flags]
 
sub BLK_FOLDEDBACK() {    1 } # block start has been folded back to min indent
sub BLK_CANTSPACE()  {    2 } # blanks may not (any longer) be inserted
sub BLK_HASCHILD()   {    4 }
sub BLK_TRIPLE()     {    8 } # block is actually a key => value triple
sub BLK_MASK()       { 0x0F }
sub OPENER()         { 0x10 } # (used in &atom flags argument)
sub CLOSER()         { 0x20 } # (used in &atom flags argument)
sub NOOP()           { 0x40 } # (used in &atom flags argument)
sub FLAGS_MASK()     { 0x7F }
sub _fmt_flags($) {
  my $r = "";
  $r .= " FOLDEDBACK" if $_[0] & BLK_FOLDEDBACK;
  $r .= " CANTSPACE"  if $_[0] & BLK_CANTSPACE;
  $r .= " HASCHILD"   if $_[0] & BLK_HASCHILD;
  $r .= " TRIPLE"     if $_[0] & BLK_TRIPLE;
  $r .= " OPENER"     if $_[0] & OPENER;
  $r .= " CLOSER"     if $_[0] & CLOSER;
  $r .= " NOOP"       if $_[0] & NOOP;
  $r .= " *INVALID($_[0])" if ($_[0] & ~FLAGS_MASK);
  $r
}
sub _fmt_block($) {
  my $blk = shift;
  "[".$blk->[0]."→".substr($outstr,$blk->[0],1)._fmt_flags($blk->[1])."]"
}
sub _fmt_stack() { @stack ? (join ",", map{ _fmt_block($_) } @stack) : "()" }

sub __unmagic($) {
  ${$_[0]} =~ s/(['"])([^'"]*?)
                (?:\Q$magic_numstr_prefix\E|\Q$magic_num_prefix\E)
                (.*?)(\1)/$2$3/xgs;
}

sub _postprocess_DD_result {
  (my $self, local $_) = @_;
  my ($debug, $vistype, $foldwidth, $foldwidth1)
    = @$self{qw/Debug _vistype Foldwidth Foldwidth1/};
  my $useqq = $self->Useqq();
  my $unesc_unicode = $useqq =~ /utf|unic/;
  my $controlpics = $useqq =~ /pic/;

  oops if @stack or $reserved;
  $reserved = 0;
  $linelen = 0;
  $outstr = "";
  $indent_unit = 2; # make configurable?
  say "##RAW ",_dbrawstr($_) if $debug;

  # Fit everything in a single line if possible.  
  #
  # Otherwise "fold back" block-starters onto their their own line, indented 
  # according to level, beginning at the (second-to-)outer level:
  #
  #    [aaa,bbb,[ccc,ddd,[eee,fff,«not enough space for next item»
  # becomes
  #    [ aaa,bbb,
  #      [ccc,ddd,[eee,fff,«next item goes here»
  #
  # If necessary fold back additional levels:
  #    [ aaa,bbb,
  #      [ ccc,ddd,
  #        [eee,fff,«next item goes here»
  #
  # When a block-starter is folded back, additional space is inserted 
  # before the first sub-item so it will align with the next indent level,
  # as shown for 'aaa' and 'ccc' above.
  #
  # If folding back all block-starters does not provide enough room,
  # then the current line is folded at the end:
  #
  #    [ aaa,bbb,
  #      [ ccc,ddd,
  #        [ eee,fff,
  #          «next items go here»
  #          «may fold again later if required»
  #
  # The insertion of spaces to align the first item in a block sometimes causes
  # *expansion*, with less available space than before:
  #
  #     [[[aaa,bbb,ccc,«next item would go here»
  # becomes
  #     [
  #       [
  #         [aaa,bbb,ccc,«even less space here !»
  #
  # To avoid retroactive line overflows, enough space is reserved to fold back
  # all unclosed blocks without causing existing content to overflow (unless
  # a single item is too large, in which case overflow occurs regardless).
  #
  # 'key => value' triples are treated as a special kind of "block" so
  # that they are kept together if possible.

  my $foldwidthN = $foldwidth || INT_MAX;
  my $maxlinelen = $foldwidth1 || $foldwidthN;
  my sub _fold_block($$;$) {
    my ($bx, $foldposn, $debmsg) = @_;
    oops if $foldposn <= $stack[$bx]->[0]; # must be after block opener
    oops if $foldposn < length($outstr) - $linelen; # must be in last line

    # If the block has children, insert spacing before the first child
    # if not already done (as indicated by BLK_CANTSPACE not yet set),
    # consuming reserved space.  N.B. if there are no children then
    # no space has been reserved for this block.
    if ( ($stack[$bx]->[1] & (BLK_CANTSPACE|BLK_HASCHILD)) == BLK_HASCHILD ) {
      my $spaces = " " x ($indent_unit-1);
      my $insposn = $stack[$bx]->[0] + 1;
      $linelen += length($spaces)
        if $insposn >= length($outstr)-$linelen;
      substr($outstr, $insposn, 0) = $spaces;
      $foldposn += length($spaces);
      foreach (@stack[$bx+1 .. $#stack]) { $_->[0] += length($spaces) }
      ($reserved -= length($spaces)) >= 0 or oops;
      $stack[$bx]->[1] |= BLK_CANTSPACE; 
      say "#***>space inserted b4 first item in bx $bx" if $debug;
    }
    my $indent = ($bx+1) * $indent_unit;
    # Remove any spaces at what will become end of line before a fold
    pos($outstr) = max(0, $foldposn - $indent_unit);
    my $replacelen = $outstr =~ /\G\S*\K\s++/gcs ? length($&) : 0;
    if (pos($outstr) == $foldposn) {
      $foldposn -= $replacelen;
    } else {
      $replacelen = 0;  # did not match immediately preceding the bracket
    } 
    pos($outstr) = undef;
    my $delta = 1 + $indent - $replacelen; # \n + spaces
    $linelen = length($outstr) - $replacelen - $foldposn + $indent;
    oops if $stack[$bx]->[0] > $foldposn;
    $stack[$bx]->[0] += $delta if $stack[$bx]->[0] == $foldposn;
    oops if $bx < $#stack && $stack[$bx+1]->[0] < $foldposn;
    foreach ($bx+1 .. $#stack) { $stack[$_]->[0] += $delta }
    substr($outstr, $foldposn, $replacelen) = "\n" . (" " x $indent);
    $maxlinelen = $foldwidthN;
    say "   After fold: stack=${\_fmt_stack()} length(outstr)=${\length($outstr)} llen=$linelen maxllen=$maxlinelen res=$reserved\n",_dbstr($outstr) if $debug;
  }#_fold_block

  my ($previtem, $prevflags);
  my sub atom($;$) {
    # Queue each item for one "look ahead" cycle before fully processing.  
    (local $_, my $flags) = ($previtem, $prevflags);
    ($previtem, $prevflags) = ($_[0], $_[1]//0);
    __unmagic(\$previtem);

    if (/\A[\\\*]+$/) {
      # Glue backslashes or * onto the front of whatever follows
      $previtem = $_ . $previtem;
      return;
    }

    __unesc_unicode if $unesc_unicode;
    __subst_controlpics if $controlpics;

say "atom ",_dbrawstr($_),_fmt_flags($flags), "  stack:", _fmt_stack(), " os=",_dbstr($outstr)
  if $debug;

    return if ($flags & NOOP);
   
    if ( !($flags & CLOSER)
         && @stack 
         && ($stack[-1]->[1] & (BLK_HASCHILD|BLK_CANTSPACE))==0 ) {
      # First child: Reserve space to insert blanks before it 
      $reserved += ($indent_unit - 1);
      $stack[-1]->[1] |= BLK_HASCHILD if @stack;
    }
    if ( ($flags & CLOSER) 
         && ($stack[-1]->[1] & (BLK_HASCHILD|BLK_CANTSPACE))==BLK_HASCHILD 
         && length() <= ($indent_unit - 1)) {
      # Closing a block which has reserved space but has not been folded yet;
      # If the closer is not larger than the reserved space, release the
      # reserved space so the closer can fit on the same line.
      $reserved -= ($indent_unit - 1); oops if $reserved < 0;
      $stack[-1]->[1] |= BLK_CANTSPACE;
    }

    # Fold back enclosing blocks to try to make room
    while ( $maxlinelen - $linelen < $reserved + length() ) {
      my $bx = first { ($stack[$_]->[1] & BLK_FOLDEDBACK)==0 } 1..$#stack;
      last 
        unless defined($bx);
      my $foldposn = $stack[$bx]->[0];
      _fold_block($bx-1, $foldposn, "encl");
      $stack[$bx]->[1] |= BLK_FOLDEDBACK;
    }

    # Fold the innermost block to start a new line if more space is needed.
    # Ignore $reserved if the item is a closer because reserved space will 
    # not be needed if the item fits on the same line.
    #
    # But always fold if this is a block-closer and there exist already-folded
    # children; in that case align the closer with opener like this:
    #     [ aaa, bbb, 
    #       ccc, «wrap instead of putting closer here»
    #     ]
    #
    # If removing trailing spaces makes it fit exactly then remove the spaces.
    #
    my $deficit = (($flags & CLOSER) ? 0 : $reserved) + length() 
                    - ($maxlinelen - $linelen) ;
    if ($deficit > 0 && /\s++\z/s && length($&) >= $deficit) {
      s/\s{$deficit}\z// or oops;
      $deficit = 0;  # e.g. if item is " => "
    }
    if (@stack && 
         ($deficit > 0
          ||
          (($flags & CLOSER) && (length($outstr) - $stack[-1]->[0] > $linelen)))
       )
    {
      _fold_block($#stack, length($outstr), "TAIL FOLD");
      if ($flags & OPENER) {
        $flags |= BLK_FOLDEDBACK; # born already in left-most position
      }
      if ($flags & CLOSER) {
        # Back up to previous indent level so closer aligns with it's opener
        my $removed = substr($outstr,length($outstr)-$indent_unit,INT_MAX,"");
        oops unless $removed eq (" " x $indent_unit);
      }
      s/^\s++//s; # elide leading spaces at start of (indented) line
    }

    $outstr .= $_; # Append the new item
    $linelen += length();

    if ($flags & CLOSER) {
      if ( ($stack[-1]->[1] & (BLK_HASCHILD|BLK_CANTSPACE)) == BLK_HASCHILD ) {
        # Release reserved space which was not needed
        $reserved -= ($indent_unit - 1); oops if $reserved < 0;
      }
      oops if @stack==1 && $reserved != 0;
      pop @stack;
    }

    if ($flags & OPENER) {
      push @stack, [length($outstr)-length(), $flags & BLK_MASK];
    }

    if (@stack && $stack[-1]->[1] & BLK_TRIPLE) {
      say "     Closing TRIPLE" if $debug;
      $reserved -= ($indent_unit - 1)  # can never happen!
        if ($stack[-1]->[1] & (BLK_HASCHILD|BLK_CANTSPACE))==BLK_HASCHILD;
      pop @stack;
    }
  }
  my sub pushlevel($) { atom( $_[0], OPENER ); }
  my sub poplevel($) { atom( $_[0], CLOSER ); }
  my sub triple($) {
    my $item = shift;
    say "##triple '$item'" if $debug;
    # Make a "key => value" or "var = value" triple be a block, 
    # to keep together if possible
    oops _fmt_flags($prevflags) if $prevflags != 0;
    $prevflags |= (OPENER | BLK_CANTSPACE);
    atom( $item, 0 );  # " => " or " = "
    atom( "", NOOP );      # push through the =>
    $stack[-1]->[1] |= BLK_TRIPLE;
  }
  my sub commasemi($) {
    # Glue to the end of the pending item, so they always appear together
    $previtem .= $_[0];
  }
#  my sub space() {
#    return if substr($outstr,-1,1) eq " ";
#    atom(" ");
#  }

  $previtem = "";
  $prevflags = NOOP;

  while ((pos()//0) < length) {
       if (/\G[\\\*]/gc)                         { atom($&) } # glued fwd
    elsif (/\G[,;]/gc)                           { commasemi($&) }
    elsif (/\G"(?:[^"\\]++|\\.)*+"/gc)           { atom($&) } # "quoted"
    elsif (/\G'(?:[^'\\]++|\\.)*+'/gc)           { atom($&) } # 'quoted'
    elsif (m(\Gqr/(?:[^\\\/]++|\\.)*+/[a-z]*)gc) { atom($&) } # Regexp
    
    # With Deparse(1) the body has arbitrary Perl code, which we can't parse
    elsif (/\Gsub\s*${curlies_re}/gc)            { atom($&) } # sub{...}

    # $VAR1->[ix] $VAR1->{key} or just $varname
    elsif (/\G(?:my\s+)?\$(?:${userident_re}|\s*->\s*|${balanced_re})++/gc) { atom($&) } 

    elsif (/\G\b[A-Za-z_][A-Za-z0-9_]*+\b/gc) { atom($&) } # bareword?
    elsif (/\G\b-?\d[\deE\.]*+\b/gc)          { atom($&) } # number
    elsif (/\G\s*=>\s*/gc)                    { triple($&) }
    elsif (/\G\s*=(?=[\w\s'"])\s*/gc)         { triple($&) }
    elsif (/\G:*${pkgname_re}/gc)             { atom($&) }
    elsif (/\G[\[\{\(]/gc) { pushlevel($&) }
    elsif (/\G[\]\}\)]/gc) { poplevel($&)  }
    elsif (/\G\s+/sgc)                        {          }
    else { oops "UNPARSED ",_dbstr(substr($_,pos//0,30)."..."),"\   at pos ",u(pos()), " ",_dbstrposn($_,pos()//0);
    }
  }
  atom(""); # push through the lookahead item

  if (($vistype//"s") eq "s") { 
  }
  elsif ($vistype eq 'a') {
    $outstr =~ s/\A\[/(/ && $outstr =~ s/\]\z/)/s or oops;
  }
  elsif ($vistype eq 'h') {
    $outstr =~ s/\A\{/(/ && $outstr =~ s/\}\z/)/s or oops;
  }
  else { oops }
  oops if @stack;
  $outstr
} #_postprocess_DD_result {

my $sane_cW = $^W;
my $sane_cH = $^H;
our @save_stack;
sub _SaveAndResetPunct() {
  # Save things which will later be restored, and reset to sane values.
  push @save_stack, [ $@, $!+0, $^E+0, $,, $/, $\, $^W ];
  $,  = "";       # output field separator is null string
  $/  = "\n";     # input record separator is newline
  $\  = "";       # output record separator is null string
  $^W = $sane_cW; # our load-time warnings
  #$^H = $sane_cH; # our load-time strictures etc.
}
sub _RestorePunct() {
  ( $@, $!, $^E, $,, $/, $\, $^W ) = @{ pop @save_stack };
}

sub _Interpolate {
  my ($self, $input, $s_or_d) = @_;
  return "<undef arg>" if ! defined $input;

  &_SaveAndResetPunct;

  my $debug = $self->Debug;
  my $useqq = $self->Useqq;

  my @pieces;  # list of [visfuncname or "", inputstring]
  { local $_ = $input;
    if (/\b((?:ARRAY|HASH)\(0x[a-fA-F0-9]+\))/) {
      state $warned=0;
      carp("Warning: String passed to ${s_or_d}vis may have been interpolated by Perl\n(use 'single quotes' to avoid this)\n") unless $warned++;
    }
    while (
      /\G (
           # Stuff without variable references (might include \n etc. escapes)
           
           #This gets "recursion limit exceeded"
           #( (?: [^\\\$\@\%] | \\[^\$\@\%] )++ )
           #|

           (?: [^\\\$\@\%]++ )
           |
           #(?: (?: \\[^\$\@\%] )++ )
           (?: (?: \\. )++ )
           |

           # $#arrayvar $#$$...refvarname $#{aref expr} $#$$...{ref2ref expr}
           #
           (?: \$\#\$*+\K ${anyvname_or_refexpr_re} )
           |
           
           # $scalarvar $$$...refvarname ${sref expr} $$$...{ref2ref expr}
           #  followed by [] {} ->[] ->{} ->method() ... «zero or more»
           # EXCEPT $$<punctchar> is parsed as $$ followed by <punctchar>
           
           (?:
             (?: \$\$++ ${pkgname_re} \K | \$ ${anyvname_or_refexpr_re} \K )
             (?:
               (?: ->\K(?: ${curliesorsquares_re}|${userident_re}${parens_re}? ))
               |
               ${curliesorsquares_re}
             )*
           )
           |

           # @arrayvar @$$...varname @{aref expr} @$$...{ref2ref expr}
           #  followed by [] {} «zero or one»
           #
           (?: \@\$*+\K ${anyvname_or_refexpr_re} ${$curliesorsquares_re}? )
           |
           # %hash %$hrefvar %{href expr} %$$...sref2hrefvar «no follow-ons»
           (?: \%\$*+\K ${anyvname_or_refexpr_re} )
          ) /xsgc)
    {
      local $_ = $1; oops unless length() > 0;
      if (/^[\$\@\%]/) {
        my $sigl = substr($_,0,1);
        if ($s_or_d eq 'd') {
          # Inject a "plain text" fragment containing the dvis "expr=" prefix,
          # omitting the '$' sigl if the expr is a plain '$name'.
          push @pieces, ["=", (/^\$(?!_)(${userident_re})\z/ ? $1 : $_)."="];
        }
        if ($sigl eq '$') {
          push @pieces, ["vis", $_];
        }
        elsif ($sigl eq '@') {
          push @pieces, ["avis", $_];
        }
        elsif ($sigl eq '%') {
          push @pieces, ["hvis", $_];
        }
        else { confess "BUG:sigl='$sigl'"; }
      } else {
        if (/^.+?(?<!\\)([\$\@\%])/) { confess __PACKAGE__." bug: Missed '$1' in «$_»" }
        # Due to the need to simplify the big regexp above, \x{abcd} is now 
        # split into "\x" and "{abcd}".  Accumlate everything as a single 
        # passthru ("=") and convert later to "e" if an eval if needed.
        if (@pieces && $pieces[-1]->[0] eq "=") {
          $pieces[-1]->[1] .= $_;
        } else {
          push @pieces, [ "=", $_ ];
        }
      }
    }
    if (!defined(pos) || pos() < length($_)) {
      my $leftover = substr($_,pos()//0);
      confess __PACKAGE__." Bug:LEFTOVER «$leftover»";
    }
    foreach (@pieces) {
      my ($meth, $str) = @$_;
      next unless $meth eq "=" && $str =~ /\\[abtnfrexXN0-7]/;
      $str =~ s/([()\$\@\%])/\\$1/g;  # don't hide \-escapes to be interpolated!
      $str =~ s/\$\\/\$\\\\/g;
      $_->[1] = "qq(" . $str . ")";
      $_->[0] = 'e';
    }
  } #local $_

  my $q = $useqq ? "" : "q";
  my $funcname = $s_or_d . "vis" .$q;
  @_ = ($self, $funcname, \@pieces);
  goto &DB::DB_Vis_Interpolate
}

sub quotekey(_) { # Quote a hash key if not a valid bareword
  $_[0] =~ /\A${userident_re}\z/s ? $_[0] : visq("$_[0]")
}

package 
  DB;

sub DB_Vis_Interpolate {
  my ($self, $funcname, $pieces) = @_;
  #say "###Vis pieces=",Data::Dumper::Interp::_dbvis($pieces);
  my $result = "";
  foreach my $p (@$pieces) {
    my ($methname, $arg) = @$p;
    if ($methname eq "=") {
      $result .= $arg;
    }
    elsif ($methname eq "e") {
      $result .= DB::DB_Vis_Eval($funcname, $arg);
    } else {
      # Reduce indent before first wrap to account for stuff alrady there
      my $leftwid = length($result) - rindex($result,"\n") - 1;
      my $foldwidth = $self->{Foldwidth};
      local $self->{Foldwidth1} = $self->{Foldwidth1} // $foldwidth;
      if ($foldwidth) {
        $self->{Foldwidth1} -= $leftwid if $leftwid < $self->{Foldwidth1}
      }
      $result .= $self->$methname( DB::DB_Vis_Eval($funcname, $arg) );
    }
  }

  &Data::Dumper::Interp::_RestorePunct;  # saved in _Interpolate
  $result
}# DB_Vis_Interpolate

# eval a string in the user's context and return the result.  The nearest
# non-DB frame must be the original user's call; this is accomplished by
# using "goto &_Interpolate" in the entry-point sub.
sub DB_Vis_Eval($$) {
  my ($label_for_errmsg, $evalarg) = @_;
  Carp::confess("Data::Dumper::Interp bug:empty evalarg") if $evalarg eq "";
  # Many ideas here taken from perl5db.pl

  # Find the closest non-DB caller.  The eval will be done in that package.
  # Find the next caller further up which has arguments (i.e. wasn't doing
  # "&subname;"), and make @_ contain those arguments.
  my ($distance, $pkg, $fname, $lno);
  for ($distance = 0 ; ; $distance++) {
    ($pkg, $fname, $lno) = caller($distance);
    last if $pkg ne "DB";
  }
  while() {
    $distance++;
    my ($p, $hasargs) = (caller($distance))[0,4];
    if (! defined $p){
      @DB::args = ('<@_ is not defined in the outer block>');
      last
    }
    last if $hasargs;
  }
  local *_ = [ @DB::args ];  # copy in case of recursion

  &Data::Dumper::Interp::_RestorePunct;  # saved in _Interpolate
  $Data::Dumper::Interp::user_dollarat = $@; # 'eval' will reset $@
  my @result = do {
    local @Data::Dumper::Interp::result;
    local $Data::Dumper::Interp::string_to_eval =
      "package $pkg; "
     .' $@ = $Data::Dumper::Interp::user_dollarat; '
     .' @Data::Dumper::Interp::result = '.$evalarg.';'
     .' $Data::Dumper::Interp::user_dollarat = $@; '  # possibly changed by a tie handler
     ;
     &DB_Vis_Evalwrapper;
     @Data::Dumper::Interp::result
  };
  my $errmsg = $@;
  &Data::Dumper::Interp::_SaveAndResetPunct;
  $Data::Dumper::Interp::save_stack[-1]->[0] = $Data::Dumper::Interp::user_dollarat;

  if ($errmsg) {
    $errmsg = Data::Dumper::Interp::__chop_loc($errmsg);
    Carp::croak("${label_for_errmsg}: Error interpolating '$evalarg' at $fname line $lno:\n$errmsg\n");
  }

  wantarray ? @result : (do{die "bug" if @result>1}, $result[0])
}# DB_Vis_Eval

1;
 __END__

=encoding UTF-8

=head1 NAME

Data::Dumper::Interp - Data::Dumper for humans, with interpolation

=head1 SYNOPSIS

  use open IO => ':locale';
  use Data::Dumper::Interp;

  @ARGV = ('-i', '/file/path');
  my %hash = (abc => [1,2,3,4,5], def => undef);
  my $ref = \%hash;

  # Interpolate variables in strings with Data::Dumper output
  say ivis 'FYI ref is $ref\nThat hash is: %hash\nArgs are @ARGV';

    # -->FYI ref is {abc => [1,2,3,4,5], def => undef}
    #    That hash is: (abc => [1,2,3,4,5], def => undef)
    #    Args are ("-i","/file/path")

  # Label interpolated values with "expr=" 
  say dvis '$ref\nand @ARGV'; 

    # -->ref={abc => [1,2,3,4,5], def => undef} 
    #    and @ARGV=("-i","/file/path")

  # Functions to format one thing 
  say vis $ref;     #-->{abc => [1,2,3,4,5], def => undef}
  say vis \@ARGV;   #-->["-i", "/file/path"]  # any scalar
  say avis @ARGV;   #-->("-i", "/file/path")
  say hvis %hash;   #-->(abc => [1,2,3,4,5], def => undef)

  # Stringify objects
  { use bigint;
    my $struct = { debt => 999_999_999_999_999_999.02 };
    say vis $struct;
      # --> {debt => (Math::BigFloat)999999999999999999.02}
  }

  # Wide characters are readable
  use utf8;
  my $h = {msg => "My language is not ASCII ☻ ☺ 😊 \N{U+2757}!"};
  say dvis '$h' ;
    # --> h={msg => "My language is not ASCII ☻ ☺ 😊 ❗"}

  #-------- OO API --------

  say Data::Dumper::Interp->new()
      ->MaxStringwidth(50)->Maxdepth($levels)->vis($datum);

  #-------- UTILITY FUNCTIONS --------
  say u($might_be_undef);  # $_[0] // "undef"
  say quotekey($string);   # quote hash key if not a valid bareword
  say qsh($string);        # quote if needed for /bin/sh
  say qshpath($pathname);  # shell quote excepting ~ or ~username prefix

    system "ls -ld ".join(" ",map{ qshpath } 
                              ("/tmp", "~sally/My Documents", "~"));


=head1 DESCRIPTION

This is a wrapper for Data::Dumper optimized for use by humans
instead of machines; the output defaults to higher-level 
forms which may not be 'eval'able.

The namesake feature of this module is interpolating Data::Dumper output 
into strings, but simple functions are also provided to 
visualize a scalar, array, or hash.

Casual debug messages are a primary use case.

Internally, Data::Dumper is called to visualize (i.e. format) data
with pre- and postprocessing to "improve" the results:
Output omits a trailing newline and is compact (1 line if possibe,
otherwise folded at your terminal width);
Unicode characters appear as themselves,
objects like Math:BigInt are stringified, "virtual" values behind
overloaded array/hash-deref operators are shown, and 
some Data::Dumper bugs^H^H^H^Hquirks are circumvented.
See "DIFFERENCES FROM Data::Dumper".

Finally, a few utilities are provided to quote strings for /bin/sh.

=head1 FUNCTIONS

=head2 ivis 'string to be interpolated'

Returns the argument with variable references and escapes interpolated
as in in Perl double-quotish strings, using Data::Dumper to
format variable values.

C<$var> is replaced by its value,
C<@var> is replaced by "(comma, sparated, list)",
and C<%hash> by "(key => value, ...)" .
Most complex expressions are recognized, e.g. indexing,
dereferences, slices, etc.

Expressions are evaluated in the caller's context using Perl's debugger
hooks, and may refer to almost any lexical or global visible at
the point of call (see "LIMITATIONS").

IMPORTANT: The argument string must be single-quoted to prevent Perl
from interpolating it beforehand.

=head2 dvis 'string to be interpolated'

Like C<ivis> with the addition that interpolated expressions
are prefixed with a "exprtext=" label.

The 'd' in 'dvis' stands for B<d>ebugging messages, a frequent use case where
brevity of typing is more highly prized than beautiful output.

=head2 vis [SCALAREXPR]

=head2 avis LIST

=head2 hvis EVENLIST

C<vis> formats a single scalar ($_ if no argument is given)
and returns the resulting string.

C<avis> formats an array (or any list) as comma-separated values in parenthesis.

C<hvis> formats a hash as key => value pairs in parenthesis.

=head2 alvis LIST

=head2 hlvis EVENLIST

These "l" variants return a bare list without the enclosing parenthesis.

=head2 ivisq 'string to be interpolated'

=head2 dvisq 'string to be interpolated'

=head2 visq [SCALAREXPR]

=head2 avisq LIST

=head2 hvisq LIST

=head2 alvisq LIST

=head2 hlvisq EVENLIST

Alternatives with a 'q' suffix display strings in 'single quoted' form
if possible.

Internally, Data::Dumper is called with C<Useqq(0)>, but depending on
the version of Data::Dumper the result may be "double quoted" anyway
if wide characters are present.

=head1 OBJECT-ORIENTED INTERFACES

=head2 Data::Dumper::Interp->new()

Creates an object initialized from the global configuration
variables listed below.  C<new> takes no arguments.

The functions described above may then be called as I<methods>
on a C<Data::Dumper::Interp> object
(when not called as a method they create a new object internally).

For example:

   $msg = Data::Dumper::Interp->new()->Foldwidth(40)->avis(@ARGV);

returns the same string as

   local $Data::Dumper::Interp::Foldwidth = 40;
   $msg = avis(@ARGV);

=head1 Configuration Variables / Methods

These work the same way as variables/methods in Data::Dumper.

For each of the following configuration items, there is a global
variable in package C<Data::Dumper::Interp> which provides the default value,
and a I<method> of the same name which sets or retrieves a config value
on a specific object.

When a method is called without arguments the current value is returned.

When a method is called with an argument to set a value, the object
is returned so that method calls can be chained.

=head2 MaxStringwidth(INTEGER)

=head2 Truncsuffix("...")

Longer strings are truncated and I<Truncsuffix> appended.
MaxStringwidth=0 (the default) means no limit.

=head2 Foldwidth(INTEGER)

Defaults to the terminal width at the time of first use.

=head2 Overloads(BOOL);

=head2 Overloads("classname")

=head2 Overloads([ list of classnames ])

A I<false> value disables stringification or evaluation of overloaded
deref operators.

A "1" (the default) enables stringification or showing "virtual" values
behind overloaded deref operators for all applicable objects 
(i.e. those which overload the "", @{} or %{} operator).

Otherwise this is enabled only for the specified class name(s).

=head2 Sortkeys(subref)

The default sorts numeric substrings in keys by numerical
value.  See C<Data::Dumper> documentation.

=head2 Useqq

The default is "unicode:controlpic" except for 
functions/methods with 'q' in their name, which force C<Useqq(0)>.

0 means generate 'single quoted' strings when possible.

1 means generate "double quoted" strings, as-is from Data::Dumper.
Non-ASCII charcters will be shown as hex escapes.

Otherwise generate "double quoted" strings enhanced according to option
keywords given as a :-separated list, e.g. Useqq("unicode:controlpic").
The two avilable options are:

=over 4

=item "unicode" (or "utf8" for historical reasons)

Show all printable
characters as themselves rather than hex escapes.

=item "controlpic"

Show non-printing ASCII characters using single "control picture" characters,
for example '␤' is shown for newline instead of '\n'.  
Similarly for \0 \a \b \e \f \r and \t.

This is sometimes useful for debugging because every character occupies 
the same space with a fixed-width font.  
The commonly-used "Last Resort" font draws these symbols 
with single-pixel lines, which on modern high-res displays
can be dim and hard to read.  If you experience this problem,
set C<Useqq> to "unicode" to see traditional \n etc. backslash escapes.

=back

=head2 Quotekeys

=head2 Sparseseen

=head2 Maxdepth

=head2 Maxrecurse

=head2 Deparse

See C<Data::Dumper> documentation.

=head1

=head1 UTILITY FUNCTIONS

=head2 u

=head2 u SCALAR

Returns the argument ($_ by default) if it is defined, otherwise
the string "undef".

=head2 quotekey

=head2 quotekey SCALAR

Returns the argument ($_ by default) if it is a valid bareword,
otherwise a quoted string.

=head2 qsh

=head2 qsh $string

=head2 qshpath

=head2 qshpath $might_have_tilde_prefix

The string ($_ by default) is quoted if necessary for parsing
by /bin/sh, which has different quoting rules than Perl.

If the string contains only "shell-safe" ASCII characters
it is returned as-is, without quotes.
Otherwise "double quotes" are used when no escapes would be needed,
otherwise 'single quotes'.

C<qshpath> is like C<qsh> except that an initial ~ or ~username is left
unquoted.  Useful for paths given to bash or csh.

If the argument is a ref it is first formatted as with C<vis()> and the
resulting string quoted.
Undefined values appear as C<undef> without quotes.

=head1 LIMITATIONS

=over 2

=item Interpolated Strings

C<ivis> and C<dvis> evaluate expressions in the user's context
using Perl's debugger support ('eval' in package DB -- see I<perlfunc>).
This mechanism has some limitations:

@_ will appear to have the original arguments to a sub even if "shift"
has been executed.  However if @_ is entirely replaced, the correct values
will be displayed.

A lexical ("my") sub creates a closure, and variables in visible scopes
which are not actually referenced by your code may not exist in the closure;
an attempt to display them with C<ivis> will fail.  For example:

    our $global;
    sub outerfunc {
      my sub inner {
        say dvis '$global'; # croaks with "Error interpolating '$global'"
        # my $x = $global;  # ... unless this is un-commented
      }
      &inner();
    }
    &outerfunc;


=item Multiply-referenced items

If a structure contains several refs to the same item,
the first ref will be visualized by showing the referenced item
as you might expect.

However subsequent refs will look like C<< $VAR1->place >>
where C<place> is the location of the first ref in the overall structure.
This is how Data::Dumper indicates that the ref is a copy of the first
ref and thus points to the same datum.
"$VAR1" is an artifact of how Data::Dumper would generate code
using its "Purity" feature.  Data::Dumper::Interp does nothing
special and simply passes through these annotations.

=item The special "_" stat filehandle may not be preserved

Data::Dumper::Interp queries the operating
system to obtain the window size to initialize C<$Foldwidth>, if it
is not already defined; this may change the "_" filehandle.  
After the first call (or if you pre-set C<$Foldwidth>),
the "_" filehandle will not change across calls.

=back

=head1 DIFFERENCES FROM Data::Dumper

Results differ from plain C<Data::Dumper> output in the following ways
(most substitutions can be disabled via Config options):

=over 2

=item *

A final newline is I<not> included.

Everything is shown on a single line if possible, otherwise wrapped to
the terminal width with indentation appropriate to structure levels.

=item *

Printable Unicode characters appear as themselves instead of \x{ABCD}.

Note: If your data contains 'wide characters', you must encode
the result before displaying it as explained in C<perluniintro>,
for example with C<< use open IO => ':locale'; >>.  
You'll also want C<< use utf8; >> if your Perl source
contains characters outside the ASCII range.

Undecoded binary octets (e.g. data read from a 'binmode' file)
will be escaped as individual bytes when necessary.

=item *

'␤' and similar "control picture" characters are shown for ASCII controls.

=item *

Object refs are replaced by the object's stringified representation.
For example, C<bignum> and C<bigrat> numbers are shown as easily
readable values rather than S<"bless( {...}, 'Math::...')">.

Stingified objects are prefixed with "(classname)" to make clear what
happened.

=item *

The "virtual" value of objects which overload a dereference operator 
(C<@{}> or C<%{}>) is displayed instead of the object's internals.

=item *

Hash keys are sorted treating numeric "components" numerically.
For example "A.20" sorts before "A.100".

=item *

All punctuation variables, including $@ and $?, are preserved over calls.

=item *

Representation of numbers and strings are made predictable and obvious:
Floating-point values always appear as numbers (not 'quoted strings'),
and strings containing digits like "42" appear as quoted strings
and not numbers (string vs. number detection is ala JSON::PP).

Although such differences might be immaterial to Perl when executing code,
they may be important when communicating to a human.

=back

=head1 SEE ALSO

Data::Dumper

Jim Avera  (jim.avera AT gmail)

=for nobody Foldwidth1 is currently an undocumented experimental method
=for nobody which sets a different fold width for the first line only.
=for nobody Terse & Indent methods exist to croak; using them is not allowed.
=for nobody oops is an internal function (called to die if bug detected).
=for nobody Debug method is for author's debugging, not documented.
=for nobody BLK_* CLOSER FLAGS_MASK NOOP OPENER are internal "constants".

=for Pod::Coverage Foldwidth1 Terse Indent oops Debug

=for Pod::Coverage BLK_CANTSPACE BLK_TRIPLE BLK_FOLDEDBACK BLK_HASCHILD BLK_MASK CLOSER FLAGS_MASK NOOP OPENER


=cut
