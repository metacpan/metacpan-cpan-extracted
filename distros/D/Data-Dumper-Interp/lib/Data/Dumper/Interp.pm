# Copyright © Jim Avera 2012-2023.  This software may be distributed,
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

use strict; use warnings FATAL => 'all'; use utf8; 
use 5.010;  # say, state
use 5.018;  # lexical_subs
use feature qw(say state lexical_subs);
use feature 'lexical_subs'; no warnings "experimental::lexical_subs";
package  Data::Dumper::Interp;
$Data::Dumper::Interp::VERSION = '5.002';

package  # newline prevents Dist::Zilla::Plugin::PkgVersion from adding $VERSION
  DB;
sub DB_Vis_Evalwrapper { # Must appear before any variables are declared
  eval $Data::Dumper::Interp::string_to_eval; ## no critic
}

package Data::Dumper::Interp;
# POD documentation follows __END__

# Old versions of Data::Dumper did not honor useqq when showing globs
# so filehandles came out as \*{'::fh'} instead of \*{"::\$fh"}
# I'm not sure whether we actually care here but the tests do care
#Now I think I've configured the testers to skip based on VERSION
#use Data::Dumper v2.174 ();
use Data::Dumper ();

use Carp;
use POSIX qw(INT_MAX);
use Encode ();
use Scalar::Util qw(blessed reftype refaddr looks_like_number);
use List::Util qw(min max first);
use List::Util 1.33 qw(any);
use List::Util 1.29 qw(pairmap);
use Regexp::Common qw/RE_balanced/;
use Term::ReadKey ();
use overload ();

sub _dbshow(_) {  # for our internal debugging messages
  my $v = shift;
  blessed($v) ? "(".blessed($v).")".$v   # stringify with (classname) prefix
              : _dbvis($v)               # number or "string"
}
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
  s/[\x{00}-\x{1F}]/ chr( ord($&)+0x2400 ) /aseg;
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
our @EXPORT    = qw(visnew
                    vis  avis  alvis  ivis  dvis  hvis  hlvis
                    visq avisq alvisq ivisq dvisq hvisq hlvisq
                    u quotekey qsh __forceqsh qshpath);

our @EXPORT_OK = qw($Debug $MaxStringwidth $Truncsuffix $Objects $Foldwidth
                    $Useqq $Quotekeys $Sortkeys $Sparseseen
                    $Maxdepth $Maxrecurse $Deparse);

our @ISA       = ('Data::Dumper'); # see comments at new()

############### Utility Functions #################

sub __stringify($) {
  if (defined(my $class = blessed($_[0]))) {
    return "$_[0]" if overload::Method($class,'""');
  }
  $_[0]  # includes undef, ordinary ref, or non-stringifyable object
}

sub u(_) { $_[0] // "undef" }
sub quotekey(_); # forward.  Implemented after regex declarations.

sub __forceqsh(_) {
  # Unlike Perl, /bin/sh does not recognize any backslash escapes in '...'
  local $_ = shift;
  return "undef" if !defined;  # undef without quotes
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
  local $_ = __stringify(shift());
  defined && !ref && !/[^-=\w_\/:\.,]/ 
    && $_ ne "" && $_ ne "undef" ? $_ : __forceqsh
}
sub qshpath(_) {  # like qsh but does not quote initial ~ or ~username
  local $_ = __stringify(shift());
  return qsh($_) if !defined or ref;
  my ($tilde_prefix, $rest) = /^( (?:\~[^\/\\]*[\/\\]?+)? )(.*)/xs or die;
  $rest eq "" ? $tilde_prefix : $tilde_prefix.qsh($rest)
}

#################### Configuration Globals #################

our ($Debug, $MaxStringwidth, $Truncsuffix, $Objects,
     $Foldwidth, $Foldwidth1,
     $Useqq, $Quotekeys, $Sortkeys, $Sparseseen,
     $Maxdepth, $Maxrecurse, $Deparse);

$Debug          = 0            unless defined $Debug;
$MaxStringwidth = 0            unless defined $MaxStringwidth;
$Truncsuffix    = "..."        unless defined $Truncsuffix;
$Objects        = 1            unless defined $Objects;
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
sub Objects {
  my($s, $v) = @_;
  @_ == 2 ? (($s->{Objects} = $v), return $s) : $s->{Objects};
}
sub Overloads {
  state $warned;
  carp "WARNING: 'Overloads' is deprecated, please use 'Objects'\n"
    unless $warned++;
  my($s, $v) = @_;
  goto &Objects;
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
our $initialbang = 999; ###TEMP DEBUG
sub new {
  croak "No args are allowed for ".__PACKAGE__."::new" if @_ > 1;
  my ($class) = @_;
  #(bless $class->SUPER::new([],[]), $class)->_config_defaults()
  
  ###TEMP DEBUGGING
  # Try to catch FreeBSD bug where $! changes somewhere
  $initialbang = $!+0;
  my $r = (bless $class->SUPER::new([],[]), $class)->_config_defaults();
  Carp::confess blessed($r),"::new(...) changed \$! unexpectedly (was $initialbang, now ",$!+0
    if $! != $initialbang;
  $r
}

########### Subs callable as either a Function or Method #############

sub __chop_loc($) {
  (local $_ = shift) =~ s/ at \(eval[^\)]*\) line \d+[^\n]*\n?\z//s;
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

sub visnew()  { __PACKAGE__->new() }  # shorthand

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
sub ivis(_) { @_=(&__getobj,          shift,'i');goto &_Interpolate }
sub ivisq(_){ @_=(&__getobj->Useqq(0),shift,'i');goto &_Interpolate }
sub dvis(_) { @_=(&__getobj,          shift,'d');goto &_Interpolate }
sub dvisq(_){ @_=(&__getobj->Useqq(0),shift,'d');goto &_Interpolate }

############# only internals follow ############

BEGIN {
  if (! Data::Dumper->can("Maxrecurse")) { 
    eval q(sub Maxrecurse { # Supply if missing in older Data::Dumper 
             my($s, $v) = @_;
             @_ == 2 ? (($s->{Maxrecurse} = $v), return $s) : $s->{Maxrecurse}//0;
           });
    die $@ if $@;
  }
}
sub _config_defaults {
  my $self = shift;

  &__set_default_Foldwidth if ! defined $Foldwidth;

  $self
    ->Debug($Debug)
    ->MaxStringwidth($MaxStringwidth)
    ->Foldwidth($Foldwidth)
    ->Foldwidth1($Foldwidth1)
    ->Objects($Objects)
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
    
    _SaveAndResetPunct();
    # Suppress hard-coded "didn't work" warning from Term::ReadKey when
    # the terminal size can not be determined via any method
    my $wmsg = "";
    local $SIG{'__WARN__'} = sub { $wmsg .= $_[0] };
    my ($width, $height) = Term::ReadKey::GetTerminalSize(
      -t STDERR ? *STDERR : -t STDOUT ? *STDOUT
      : do{my $fh; for("/dev/tty",'CONOUT$') { last if open $fh, $_ } $fh}
    );
    warn $wmsg if $wmsg && $wmsg !~ /did.*n.*work/i;

    if (($Foldwidth = $width)) {
      say "Default Foldwidth=$Foldwidth from Term::ReadKey" if $Debug;
    } else {
      $Foldwidth = 80;
      say "Foldwidth=$Foldwidth from hard-coded backup default" if $Debug;
    }
    _RestorePunct();
  }
  undef $Foldwidth1;
}

my $unique = refaddr \&new;
my $magic_num_prefix    = "<NUMMagic$unique>";
my $magic_numstr_prefix = "<NUMSTRMagic$unique>";
my $COPY_NEEDED = "_CN_$unique";
sub __COPY_NEEDED() { $COPY_NEEDED }

sub _doedits {
  my $self = shift; oops unless @_ == 5;
  my ($item, $testonly, $maxstringwidth, $truncsuf, $objects) = @_;
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
  my $overload_depth;
  while (my $class = blessed($item)) {
    # Some kind of object reference
    last unless any { ref() eq "Regexp" ? $class =~ $_
                                        : ($_ eq "1" || $_ eq $class) 
                    } @$objects;
    if (overload::Overloaded($item)) {
      # N.B. Overloaded(...) also returns true if it's a NAME of an 
      # overloaded package; should not happen in this case.
      warn("Recursive overloads on $item ?\n"),last
        if $overload_depth++ > 10;
      # Stringify objects which have the stringification operator
      if (overload::Method($class,'""')) {
        return __COPY_NEEDED if $testonly;
        my $prefix = _show_as_number($item) ? $magic_num_prefix : "";
        $item = $item.""; # stringify;
        if ($item !~ /^${class}=REF/) {
          $item = "${prefix}($class)$item"; 
        } else {
          # The "stringification" looks like Perl's default, so don't prefix it
        }
        next
      }
      # Substitute the virtual value behind an overloaded deref operator
      elsif (overload::Method($class,'@{}')) {
        return __COPY_NEEDED if $testonly;
        $item = \@{ $item };
        next
      }
      elsif (overload::Method($class,'%{}')) {
        return __COPY_NEEDED if $testonly;
        $item = \%{ $item };
        next
      }
      elsif (overload::Method($class,'${}')) {
        return __COPY_NEEDED if $testonly;
        $item = \${ $item };
        next
      }
      elsif (overload::Method($class,'&{}')) {
        return __COPY_NEEDED if $testonly;
        $item = \&{ $item };
        next
      }
      elsif (overload::Method($class,'*{}')) {
        return __COPY_NEEDED if $testonly;
        $item = \*{ $item };
        next
      }
    }
    # No overloaded operator (that we care about); just stringify the ref
    unless ($class eq "Regexp") {  # unless Perl will handle it nicely
      return __COPY_NEEDED if $testonly;
      $item = "$item"
    } 
    last
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
  #     cross-platform issue.  For our purposes we want all numbers 
  #     to appear as numbers.  
  if (!reftype($item) && $item !~ /^0\d/ && looks_like_number($item) ) {
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

  my ($maxstringwidth, $objects, $debug)
    = @$self{qw/MaxStringwidth Objects Debug/};

  # Do desired substitutions in a copy of the data.
  #
  # (This used to just Clone:clone the whole thing and then walk and modify 
  # the copy; but cloned tied variables could blow up if their handlers
  # got confused by our changes in the copy.  Now our copy never contains
  # tied variables, although it might contain cloned objects (with any
  # internal tied vars substituted).

  { my @values = $self->Values;
    croak "No Values set" if @values == 0;
    croak "Only a single scalar value is allowed" if @values > 1;
    $maxstringwidth //= 0;
    $maxstringwidth = 0 if $maxstringwidth >= INT_MAX;
    my $truncsuf = $self->{Truncsuffix};
    $objects = [ $objects ] unless ref($objects) eq 'ARRAY';
    $objects = undef unless grep{ $_ } @$objects; # all false?
    my $callback = sub { 
      $self->_doedits(@_, $maxstringwidth, $truncsuf, $objects) 
    };
    eval { 
      $values[0] = __copysubst($values[0], $callback)
    };
    croak "Exception while traversing value:\n----\n$@----\n" if $@;
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
# data and misbehave.  The copy machinery re-creates all refs so as to
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

sub _show_as_number(_) {
  my $value = shift;

  # IMPORTANT: We must not do any numeric ops or comparisions
  # on $value because that may set some magic which defeats our attempt 
  # to try bitstring unary & below (after a numeric compare, $value is 
  # apparently assumed to be numeric or dual-valued even if it 
  # is/was just a "string").
  
  return 0 if !defined $value;

  # if the utf8 flag is on, it almost certainly started as a string
  return 0 if !ref($value) && utf8::is_utf8($value);

  # There was a Perl bug where looks_like_number() provoked a warning from 
  # BigRat.pm if it is called under 'use bigrat;' so we must not do that.
  #   https://github.com/Perl/perl5/issues/20685
  #return 0 unless looks_like_number($value);

  # JSON::PP uses these tricks:
  # string & "" -> ""  # bitstring AND, truncating to shortest operand
  # number & "" -> 0 (with warning)
  # number * 0 -> 0 unless number is nan or inf

  # Attempt uniary & with "string" and see what happens
  my $uand_str_result = eval { 
    use warnings "FATAL" => "all"; # Convert warnings into exceptions
    # 'bitwise' is the default only in newer perls. So disable.
    BEGIN {
      eval { # "no feature 'bitwise'" won't compile on Perl 5.20
        feature->unimport( 'bitwise' ); 
        warnings->unimport("experimental::bitwise");
      };
    }
    no warnings "once";
    # Use FF so we can see what $value was in debug messages below
    my $dummy = ($value & "\x{FF}\x{FF}\x{FF}\x{FF}\x{FF}\x{FF}\x{FF}\x{FF}");
  };
  if ($@) {
    if ($@ =~ /".*" isn't numeric/) {
      return 1; # Ergo $value must be numeric
    }
    if ($@ =~ /\& not supported/) {
      # If it is an object then it probably (but not necessarily)
      # is numeric but just doesn't support bitwise operators,
      # for example BigRat.
      return 1 if defined blessed($value);
    } 
    warn "### ".__PACKAGE__." : value=",_dbshow($value),
         "\n    Unhandled warn/exception from unary & :$@\n"
      if $Data::Dumper::Interp::Debug;
    # Unknown problem, treat as a string
    return 0;
  } 
  elsif (ref($uand_str_result) && $uand_str_result =~ /NaN|Inf/) {
    # unary & returned a an object representing Nan or Inf 
    # (e.g. Math::BigFloat) so $value must be numberish.
    return 1;
  }
  warn "### ".__PACKAGE__." : (value & \"...\") succeeded\n",
       "    value=", _dbshow($value), "\n",
       "    uand_str_result=", _dbvis($uand_str_result),"\n"
    if $Data::Dumper::Interp::Debug;
  # Sigh.  With Perl 5.32 (at least) $value & "..." stringifies $value
  # or so it seems.
  if (blessed($value)) {
    # +42 might throw if object is not numberish e.g. a DateTime
    if (blessed(eval{ $value + 42 })) {
      warn "    Object and value+42 is still an object, so probably numberish\n"
        if $Data::Dumper::Interp::Debug;
      return 1
    } else {
      warn "    Object and value+42 is NOT an object, so it must be stringish\n"
        if $Data::Dumper::Interp::Debug;
      return 0
    }
  } else {
    warn "    NOT an object, so must be a string\n",
      if $Data::Dumper::Interp::Debug;
    return 0;
  }
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

sub __unesc_unicode() {  # edits $_
  if (/^"/) {
    # Data::Dumper with Useqq(1) outputs wide characters as hex escapes 
  
    s/
       \G (?: [^\\]++ | \\[^x] )*+ \K (?<w> \\x\x{7B} (?<hex>[a-fA-F0-9]+) \x{7D} )
     / 
       my $orig = $+{w};
       local $_ = hex( length($+{hex}) > 6 ? '0' : $+{hex} );
       $_ = $_ > 0x10FFFF ? "\0" : chr($_); # 10FFFF is Unicode limit
       # Using 'lc' so regression tests do not depend on Data::Dumper's
       # choice of case when escaping wide characters.
       m<\P{XPosixGraph}|[\0-\177]> ? lc($orig) : $_
     /xesg;
  } 
}

sub __change_quotechars($) {  # edits $_
  if (s/^"//) {
    oops unless s/"$//;
    s/\\"/"/g;
    my ($l, $r) = split //, $_[0]; oops unless $r;
    s/([\Q$l$r\E])/\\$1/g;
    $_ = "qq".$l.$_.$r;
  } 
}

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
  my $controlpics   = $useqq =~ /pic/;
  my $qq            = $useqq =~ /qq(?:=(..))?/ ? ($1//'{}') : '';

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
    __change_quotechars($qq) if $qq;

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
  push @save_stack, [ $@, $!+0, $^E+0, $,, $/, $\, $?, $^W ];
  $,  = "";       # output field separator is null string
  $/  = "\n";     # input record separator is newline
  $\  = "";       # output record separator is null string
  $?  = 0;        # child process exit status
  $^W = $sane_cW; # our load-time warnings
  #$^H = $sane_cH; # our load-time strictures etc.
}
sub _RestorePunct() {
  ( $@, $!, $^E, $,, $/, $\, $?, $^W ) = @{ pop @save_stack };
}

sub _Interpolate {
  my ($self, $input, $i_or_d) = @_;
  return "<undef arg>" if ! defined $input;

###TEMP DEBUGGING
# Try to catch FreeBSD bug where $! changes somewhere
$initialbang = $!+0;
  
  &_SaveAndResetPunct;

#say "###III1 ",_dbvis($save_stack[-1]);
#say "###III2 ",_dbvis($initialbang);
oops unless $save_stack[-1]->[1] == $initialbang;
oops unless $!+0 == $initialbang;

  my $debug = $self->Debug;
oops unless $!+0 == $initialbang;
  my $useqq = $self->Useqq;
oops unless $!+0 == $initialbang;

  my $q = $useqq ? "" : "q";
  my $funcname = $i_or_d . "vis" .$q;

  my @pieces;  # list of [visfuncname or 'p' or 'e', inputstring]
  { local $_ = $input;
    if (/\b((?:ARRAY|HASH)\(0x[a-fA-F0-9]+\))/) {
      state $warned=0;
      carp("Warning: String passed to $funcname may have been interpolated by Perl\n(use 'single quotes' to avoid this)\n") unless $warned++;
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
        if ($i_or_d eq 'd') {
          # Inject a "plain text" fragment containing the "expr=" prefix,
          # omitting the '$' sigl if the expr is a plain '$name'.
          push @pieces, ['p', (/^\$(?!_)(${userident_re})\z/ ? $1 : $_)."="];
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
        # split into "\x" and "{abcd}".  Combine consecutive pass-thrus
        # into a single passthru ('p') and convert later to 'e' if 
        # an eval if needed.
        if (@pieces && $pieces[-1]->[0] eq 'p') {
          $pieces[-1]->[1] .= $_;
        } else {
          push @pieces, [ 'p', $_ ];
        }
      }
    }
    if (!defined(pos) || pos() < length($_)) {
      my $leftover = substr($_,pos()//0);
      # Try to recognize user syntax errors
      croak "Invalid expression syntax starting at '$leftover' in $funcname arg"
        if $leftover =~ /^[\$\@\%][\s\%\@]/;
      # Otherwise we may have a parser bug
      confess "Invalid expression (or ".__PACKAGE__." bug):\n«$leftover»";
    }
    foreach (@pieces) {
      my ($meth, $str) = @$_;
      next unless $meth eq 'p' && $str =~ /\\[abtnfrexXN0-7]/;
      $str =~ s/([()\$\@\%])/\\$1/g;  # don't hide \-escapes to be interpolated!
      $str =~ s/\$\\/\$\\\\/g;
      $_->[1] = "qq(" . $str . ")";
      $_->[0] = 'e';
    }
  } #local $_
oops unless $!+0 == $Data::Dumper::Interp::initialbang;

  @_ = ($self, $funcname, \@pieces);
  goto &DB::DB_Vis_Interpolate
}

sub quotekey(_) { # Quote a hash key if not a valid bareword
  $_[0] =~ /\A${userident_re}\z/s ? $_[0] : 
            $_[0] =~ /(?!.*')["\$\@]/  ? visq("$_[0]") : 
            $_[0] =~ /\W/ && !looks_like_number($_[0]) ? vis("$_[0]") : 
            "\"$_[0]\""
}

package 
  DB;

sub DB_Vis_Interpolate {
  my ($self, $funcname, $pieces) = @_;
  #say "###Vis pieces=",Data::Dumper::Interp::_dbvis($pieces);
Carp::confess() unless $!+0 == $Data::Dumper::Interp::initialbang;
  my $result = "";
  foreach my $p (@$pieces) {
    my ($methname, $arg) = @$p;
    if ($methname eq 'p') {
      $result .= $arg;
    }
    elsif ($methname eq 'e') {
Carp::confess() unless $!+0 == $Data::Dumper::Interp::initialbang;
      $result .= DB::DB_Vis_Eval($funcname, $arg);
Carp::confess() unless $!+0 == $Data::Dumper::Interp::initialbang;
    } else {
      # Reduce indent before first wrap to account for stuff alrady there
      my $leftwid = length($result) - rindex($result,"\n") - 1;
      my $foldwidth = $self->{Foldwidth};
      local $self->{Foldwidth1} = $self->{Foldwidth1} // $foldwidth;
      if ($foldwidth) {
        $self->{Foldwidth1} -= $leftwid if $leftwid < $self->{Foldwidth1}
      }
Carp::confess() unless $!+0 == $Data::Dumper::Interp::initialbang;
      $result .= $self->$methname( DB::DB_Vis_Eval($funcname, $arg) );
Carp::confess() unless $!+0 == $Data::Dumper::Interp::initialbang;
    }
  }

Carp::confess() unless $!+0 == $Data::Dumper::Interp::initialbang;
  &Data::Dumper::Interp::_RestorePunct;  # saved in _Interpolate
Carp::confess() unless $!+0 == $Data::Dumper::Interp::initialbang;
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
Carp::confess() unless $!+0 == $Data::Dumper::Interp::initialbang;
  my ($distance, $pkg, $fname, $lno);
  for ($distance = 0 ; ; $distance++) {
    ($pkg, $fname, $lno) = caller($distance);
    last if $pkg ne "DB";
  }
Carp::confess() unless $!+0 == $Data::Dumper::Interp::initialbang;
  local *_ = [];
  while() {
    $distance++;
    my ($p, $hasargs) = (caller($distance))[0,4];
    if (! defined $p){
      *_ = [ '<@_ is not defined in the outer block>' ];
      last
    }
    if ($hasargs) {
      *_ = [ @DB::args ];  # copy in case of recursion
      last
    }
  }

Carp::confess() unless $!+0 == $Data::Dumper::Interp::initialbang;
  &Data::Dumper::Interp::_RestorePunct;  # saved in _Interpolate
Carp::confess() unless $!+0 == $Data::Dumper::Interp::initialbang;
  $Data::Dumper::Interp::user_dollarat = $@; # 'eval' will reset $@
  $Data::Dumper::Interp::user_bang = $!;     # not sure why this might be changed(!?!)
  my @result = do {
    local @Data::Dumper::Interp::result;
    local $Data::Dumper::Interp::string_to_eval =
      "package $pkg; "
     .' $@ = $Data::Dumper::Interp::user_dollarat; '
     .' $! = $Data::Dumper::Interp::user_bang; '
     .' @Data::Dumper::Interp::result = '.$evalarg.';'
     .' $Data::Dumper::Interp::user_dollarat = $@; '  # possibly changed by a tie handler
     ;
Carp::confess() unless $!+0 == $Data::Dumper::Interp::initialbang;
     &DB_Vis_Evalwrapper;
Carp::confess() unless $!+0 == $Data::Dumper::Interp::initialbang;
     @Data::Dumper::Interp::result
  };
  my $errmsg = $@;
Carp::confess() unless $!+0 == $Data::Dumper::Interp::initialbang;
  &Data::Dumper::Interp::_SaveAndResetPunct;
Carp::confess() unless $!+0 == $Data::Dumper::Interp::initialbang;
  $Data::Dumper::Interp::save_stack[-1]->[0] = $Data::Dumper::Interp::user_dollarat;

  if ($errmsg) {
    $errmsg = Data::Dumper::Interp::__chop_loc($errmsg);
    Carp::croak("${label_for_errmsg}: Error interpolating '$evalarg':\n$errmsg\n");
  }

Carp::confess() unless $!+0 == $Data::Dumper::Interp::initialbang;
  wantarray ? @result : (do{die "bug" if @result>1}, $result[0])
}# DB_Vis_Eval

1;
 __END__

=pod

=encoding UTF-8

=head1 NAME

Data::Dumper::Interp - interpolate Data::Dumper output into strings for human consumption

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

    # But if you do want to see object internals
    say visnew->Objects(0)->vis($struct); 
    { local $Data::Dumper::Interp::Objects=0; say vis $struct; } #another way
      # --> {debt => bless({...lots of stuff...},'Math::BigInt')}
  }

  # Wide characters are readable
  use utf8;
  my $h = {msg => "My language is not ASCII ☻ ☺ 😊 \N{U+2757}!"};
  say dvis '$h' ;
    # --> h={msg => "My language is not ASCII ☻ ☺ 😊 ❗"}

  #-------- OO API --------

  say Data::Dumper::Interp->new()
            ->MaxStringwidth(50)->Maxdepth($levels)->vis($datum);

  say visnew->MaxStringwidth(50)->Maxdepth($levels)->vis($datum);

  #-------- UTILITY FUNCTIONS --------
  say u($might_be_undef);  # $_[0] // "undef"
  say quotekey($string);   # quote hash key if not a valid bareword
  say qsh($string);        # quote if needed for /bin/sh
  say qshpath($pathname);  # shell quote excepting ~ or ~username prefix

    system "ls -ld ".join(" ",map{ qshpath } 
                              ("/tmp", "~sally/My Documents", "~"));


=head1 DESCRIPTION

This Data::Dumper wrapper optimizes output for human consumption 
and avoids side-effects which interfere with debugging.

The namesake feature is interpolating Data::Dumper output 
into strings, but simple functions are also provided
to visualize a scalar, array, or hash.

Internally, Data::Dumper is called to visualize (i.e. format) data
with pre- and post-processing to "improve" the results:

=over 2

=item * Output is compact (1 line if possibe,
otherwise folded at your terminal width), WITHOUT a trailing newline.

=item * Printable Unicode characters appear as themselves.

=item * Object internals are not shown; Math:BigInt etc. are stringified.

=item * "virtual" values behind overloaded array/hash-deref operators are shown

=item * Data::Dumper bugs^H^H^H^Hquirks are circumvented.

=back

See "DIFFERENCES FROM Data::Dumper".

Finally, a few utilities are provided to quote strings for /bin/sh.

=head1 FUNCTIONS

=head2 ivis 'string to be interpolated'

Returns the argument with variable references and escapes interpolated
as in in Perl double-quotish strings, but using Data::Dumper to
format variable values.

C<$var> is replaced by its value,
C<@var> is replaced by "(comma, sparated, list)",
and C<%hash> by "(key => value, ...)" .
More complex expressions with indexing, dereferences, slices
and method calls are also recognized, e.g.

  'The answer is $foo->[$bar->{$somekey}]->frobnicate(42) for Pete's sake'

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

C<hvis> formats key => value pairs in parenthesis.

=head2 alvis LIST

=head2 hlvis EVENLIST

The "l" variants return a bare list without the enclosing parenthesis.

=head2 ivisq 'string to be interpolated'

=head2 dvisq 'string to be interpolated'

=head2 visq [SCALAREXPR]

=head2 avisq LIST

=head2 hvisq LIST

=head2 alvisq LIST

=head2 hlvisq EVENLIST

The 'q' variants display strings in 'single quoted' form if possible.

Internally, Data::Dumper is called with C<Useqq(0)>, but depending on
the version of Data::Dumper the result may be "double quoted" anyway
if wide characters are present.

=head1 OBJECT-ORIENTED INTERFACES

=head2 Data::Dumper::Interp->new()

=head2 visnew()

Creates an object initialized from the global configuration
variables listed below
(the function C<visnew> is simply a shorthand wrapper function).

No arguments are permitted.

The functions described above may then be called as I<methods>
on the object
(when not called as a method the functions create a new object internally).

For example:

   $msg = visnew->Foldwidth(40)->avis(@ARGV);
 or
   $msg = Data::Dumper::Interp->new()->Foldwidth(40)->avis(@ARGV);

return the same string as

   local $Data::Dumper::Interp::Foldwidth = 40;
   $msg = avis(@ARGV);

=head1 Configuration Variables / Methods

These work the same way as variables/methods in Data::Dumper.

Each configuration method has a corresponding global variable
in package C<Data::Dumper::Interp> which provides the default.

When a method is called without arguments the current value is returned.

When a method is called with an argument to set a value, the object
is returned so that method calls can be chained.

=head2 MaxStringwidth(INTEGER)

=head2 Truncsuffix("...")

Longer strings are truncated and I<Truncsuffix> appended.
MaxStringwidth=0 (the default) means no limit.

=head2 Foldwidth(INTEGER)

Defaults to the terminal width at the time of first use.

=head2 Objects(BOOL);

=head2 Objects("classname")

=head2 Objects([ list of classnames ])

A I<false> value disables special handling of objects
and internals are shown as with Data::Dumper.

A "1" (the default) enables for all objects, otherwise only 
for the specified class name(s).

When enabled, object internals are never shown.  
If the stringification ('""') operator, 
or array-, hash-, scalar-, or glob- deref operators are overloaded,
then the first overloaded operator found will be evaluated and the
object replaced by the result, and the check repeated; otherwise
the I<ref> is stringified in the usual way, so something
like "Foo::Bar=HASH(0xabcd1234)" appears.

Beginning with version 5.000 the B<deprecated> C<Overloads> method
is an alias for C<Objects>.

=for Pod::Coverage Overloads

=head2 Sortkeys(subref)

The default sorts numeric substrings in keys by numerical
value, e.g. "A.20" sorts before "A.100".  See C<Data::Dumper> documentation.

=head2 Useqq

The default is "unicode:controlpic" except for 
functions/methods with 'q' in their name, which force C<Useqq(0)>.

0 means generate 'single quoted' strings when possible.

1 means generate "double quoted" strings, as-is from Data::Dumper.
Non-ASCII charcters will be shown as hex escapes.

Otherwise generate "double quoted" strings enhanced according to option
keywords given as a :-separated list, e.g. Useqq("unicode:controlpic").
The avilable options are:

=over 4

=item "unicode"

All printable
characters are shown as themselves rather than hex escapes, and
'\n', '\t', etc. are shown for common ASCII control codes.

=item "controlpic"

Show ASCII control characters using single "control picture" characters,
for example '␤' is shown for newline instead of '\n'.  
Similarly for \0 \a \b \e \f \r and \t.

This way every character occupies the same space with a fixed-width font.  
However the commonly-used "Last Resort" font for these characters
can be hard to read on modern high-res displays.
You can set C<Useqq> to just "unicode" to see traditional \n etc. 
backslash escapes while still seeing wide characters as themselves.

=item "qq"

=item "qq=XY"

Show using Perl's qq{...} syntax, or qqX...Y if deliters are specified,
rather than "...".

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
otherwise a "quoted string".

=head2 qsh [$string]

The string ($_ by default) is quoted if necessary for parsing
by /bin/sh, which has different quoting rules than Perl.

If the string contains only "shell-safe" ASCII characters
it is returned as-is, without quotes.

If the argument is a ref but is not an object which stringifies,
then vis() is called and the resulting string quoted.
An undefined value is shown as C<undef> without quotes; 
as a special case to avoid ambiguity the string 'undef' is always "quoted".

=head2 qshpath [$might_have_tilde_prefix]

Similar to C<qsh> except that an initial ~ or ~username is left
unquoted.  Useful for paths given to bash or csh.

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

A final newline is I<never> included.

Everything is shown on a single line if possible, otherwise wrapped to
your terminal width (or C<$Foldwidth>) with indentation 
appropriate to structure levels.

=item *

Printable Unicode characters appear as themselves instead of \x{ABCD}.

Note: If your data contains 'wide characters', you should
C<< use open IO => ':locale'; >> or otherwise arrange to
encode the output for your terminal.
You'll also want C<< use utf8; >> if your Perl source
contains characters outside the ASCII range.

Undecoded binary octets (e.g. data read from a 'binmode' file)
will still be escaped as individual bytes when necessary.

=item *

'␤' and similar "control picture" characters are shown for ASCII controls.

=item *

The internals of objects are not shown.

If stringifcation is overloaded it is used to obtain the object's
representation.  For example, C<bignum> and C<bigrat> numbers are shown as easily
readable values rather than S<"bless( {...}, 'Math::...')">.

Stingified objects are prefixed with "(classname)" to make clear what
happened.

The "virtual" value of objects which overload a dereference operator 
(C<@{}> or C<%{}>) is displayed instead of the object's internals.

=item *

Hash keys are sorted treating numeric "components" numerically.
For example "A.20" sorts before "A.100".

=item *

Punctuation variables, including $@ and $?, are preserved over calls.

=item *

Numbers and strings which look like numbers are kept distinct when displayed, 
i.e. "0" does not become 0 or vice-versa. Floating-point values are shown
as numbers not 'quoted strings' and similarly for stringified objects.

Although such differences might be immaterial to Perl during execution,
they may be important when communicating to a human.

=back

=head1 SEE ALSO

Data::Dumper

Jim Avera  (jim.avera AT gmail)

=for nobody Foldwidth1 is currently an undocumented experimental method
=for nobody which sets a different fold width for the first line only.
=for nobody 
=for nobody Terse & Indent methods exist to croak; using them is not allowed.
=for nobody oops is an internal function (called to die if bug detected).
=for nobody The Debug method is for author's debugging, and not documented.
=for nobody BLK_* CLOSER FLAGS_MASK NOOP OPENER are internal "constants".

=for Pod::Coverage Foldwidth1 Terse Indent oops Debug

=for Pod::Coverage BLK_CANTSPACE BLK_TRIPLE BLK_FOLDEDBACK BLK_HASCHILD BLK_MASK CLOSER FLAGS_MASK NOOP OPENER

=cut
