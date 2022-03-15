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

use strict; use warnings FATAL => 'all'; use utf8; use 5.012;
use feature qw(state);
package  Data::Dumper::Interp;
$Data::Dumper::Interp::VERSION = '2.23';

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
use List::Util qw(min max first any);
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
sub oops(@) { @_ = ("\noops:",@_,"\n  "); goto &Carp::confess }

use Exporter 'import';
our @EXPORT    = qw(vis  avis  alvis  ivis  dvis  hvis  hlvis
                    visq avisq alvisq ivisq dvisq hvisq hlvisq
                    u qsh _forceqsh qshpath);

our @EXPORT_OK = qw($Debug $MaxStringwidth $Truncsuffix $Stringify $Foldwidth
                    $Useqq $Quotekeys $Sortkeys $Sparseseen);

our @ISA       = ('Data::Dumper'); # see comments at new()

############### Utility Functions #################

sub u(_) { $_[0] // "undef" }
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

our ($Debug, $MaxStringwidth, $Truncsuffix, $Stringify,
     $Foldwidth, $Foldwidth1,
     $Useqq, $Quotekeys, $Sortkeys, $Sparseseen);

$Debug          = 0            unless defined $Debug;
$MaxStringwidth = 0            unless defined $MaxStringwidth;
$Truncsuffix    = "..."        unless defined $Truncsuffix;
$Stringify      = 1            unless defined $Stringify;
$Foldwidth      = undef        unless defined $Foldwidth;  # undef auto-detects
$Foldwidth1     = undef        unless defined $Foldwidth1; # override for 1st

# The following override Data::Dumper defaults
$Useqq          = 1            unless defined $Useqq;
$Quotekeys      = 0            unless defined $Quotekeys;
$Sortkeys       = \&__sortkeys unless defined $Sortkeys;
$Sparseseen     = 1            unless defined $Sparseseen;

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
sub Stringify {
  my($s, $v) = @_;
  @_ == 2 ? (($s->{Stringify} = $v), return $s) : $s->{Stringify};
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

sub __getobj {
  (blessed($_[0]) && $_[0]->isa(__PACKAGE__) ? shift : __PACKAGE__->new())
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
sub alvis(@)   { &__getobj_a ->_vistype('l' )->Dump; }
sub alvisq(@)  { &__getobj_a ->_vistype('l' )->Useqq(0)->Dump; }
sub hvis(@)   { &__getobj_h ->_vistype('h' )->Dump; }
sub hvisq(@)  { &__getobj_h ->_vistype('h' )->Useqq(0)->Dump; }
sub hlvis(@)  { &__getobj_h ->_vistype('hl')->Dump; }
sub hlvisq(@) { &__getobj_h ->_vistype('hl')->Useqq(0)->Dump; }

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
    ->Stringify($Stringify)
    ->Truncsuffix($Truncsuffix)
    ->Quotekeys($Quotekeys)
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

sub __walk_worker($$$$$) {
  my (undef, $detection_pass, $stringify, $maxstringwidth, $truncsuf) = @_;
  return 1
    unless defined $_[0];
  # Truncate over-length strings
  if ($maxstringwidth) {
    if (ref($_[0]) eq "") { # a scalar
      my $maxwid = $maxstringwidth + length($truncsuf);
      if (!_show_as_number($_[0])
          && length($_[0]) > $maxstringwidth + length($truncsuf)) {
        return \undef if $detection_pass;
        $_[0] = substr($_[0],0,$maxstringwidth).$truncsuf;
      }
    }
  }
  if (my $class = blessed($_[0])) {
    # Strinify objects which have the stringification operator
    if (overload::Method($class,'""')) { # implements operator stringify
      if (any { ref() eq "Regexp" ? $class =~ /$_/
                                  : ($_ eq "1" || $_ eq $class) } @$stringify)
      {
        return \undef if $detection_pass;  # halt immediately
        # Make the change.  We are on a 2nd pass on a cloned copy
        my $prefix = _show_as_number($_[0]) ? $magic_num_prefix : "";
        $_[0] = "${prefix}($class)".$_[0];  # *calls stringify operator*
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
  #     most liklye to have been used by the programmer to store the value.
  #
  #  2. Floating point values come out as "strings" to avoid some
  #     cross-platform problem I don't understand.  For our purposes
  #     we want all numbers to appear as numbers.
  if (!reftype($_[0]) && looks_like_number($_[0])) {
    return \undef if $detection_pass;  # halt immediately
    my $prefix = _show_as_number($_[0])
                   ? $magic_num_prefix : $magic_numstr_prefix;
    $_[0] = $prefix.$_[0];
  }
  1
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

  my ($debug, $maxstringwidth, $stringify)
    = @$self{qw/Debug MaxStringwidth Stringify/};

  # Do desired substitutions in the data (cloning first)
  if ($stringify || $maxstringwidth) {
    $stringify = [ $stringify ] unless ref($stringify) eq 'ARRAY';
    $maxstringwidth //= 0;
    my $truncsuf = $self->{Truncsuffix};
    my $r = $self->_Visit_Values(
      sub{ __walk_worker(shift,1,$stringify,$maxstringwidth,$truncsuf) } );
    if (ref $r) {  # something needs changing
      $self->_Modify_Values(
        sub{ __walk_worker(shift,0,$stringify,$maxstringwidth,$truncsuf) } );
    }
  }

  my @values = $self->Values;
  if (@values != 1) {
    croak(@values==0 ? "No Values set" : "Only a single scalar value allowed")
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

# Walk an arbitrary structure calling &coderef on each item. stopping
# The sub should return 1 to continue, or any other defined value to
# terminate the traversal early.
# Members of containers are visited after processing the container item itself,
# and containerness is checked after &$coderef returns so that &$coderef
# may transform the item (by reference through $_[0]) e.g. to replace a
# container with a scalar.
# RETURNS: The final $&coderef return val
sub __walk($$;$);
sub __walk($$;$) {  # (coderef, item [, seenhash])
  no warnings 'recursion';
  my $seen = $_[2] // {};
  # Test for recursion both before and after calling the coderef, in case the
  # code unconditionally clones or otherwise replaces the item with new data.
  if (reftype($_[1])) {
    my $refaddr0 = refaddr($_[1]);
    return 1 if $seen->{$refaddr0}; # increment only below
  }
  # Now call the coderef and re-check the item
  my $r = &{ $_[0] }($_[1]);
  return $r unless (my $reftype = reftype($_[1])); # no longer a container?
  my $refaddr1 = refaddr($_[1]);
  return $r if $seen->{$refaddr1}++;
  return $r unless $r eq "1";
  if ($reftype eq 'ARRAY') {
    foreach (@{$_[1]}) {
      my $r = __walk($_[0], $_, $seen);
      return $r unless $r eq "1";
    }
  }
  elsif ($reftype eq 'HASH') {
    #foreach (values %{$_[1]})
    #  return 0 unless __walk($_[0], $_, $seen);
    #}
    # sort to retain same visitation order in cloned copy
    foreach (sort keys %{$_[1]}) {
      my $r = __walk($_[0], $_[1]->{$_}, $seen);
      return $r unless $r eq "1";
    }
  }
  1
}

# __walk() is called with the specified subref on the
# array of Values in the object.  The sub should not modify anything,
# but may return other than "1" to terminate the traversal.
# Returns the last value returned by the visitor sub.
sub _Visit_Values {
  my ($self, $coderef) = @_;
  my @values = $self->Values;
  __walk($coderef, \@values);
}

# Edit Values: __walk() is called with the specified subref on the
# array of Values in the object.  The Values are cloned first to
# avoid corrupting the user's data structure.
# The sub should return only 1, or 0 to terminate the traversal early.
sub _Modify_Values {
  my ($self, $coderef) = @_;
  my @values = $self->Values;
  unless ($self->{VisCloned}++) {
    require Clone;
    @values = map{ Clone::clone($_) } @values;
  }
  my $r = __walk($coderef, \@values);
  confess "bug" unless $r =~ /^[01]$/;
  $self->Values(\@values);
}

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

# FIXME: These don't take into account quoted strings in the interior!
our $curlies_re = RE_balanced(-parens=>'{}');
our $parens_re = RE_balanced(-parens=>'()');
our $curliesorsquares_re = RE_balanced(-parens=>'{}[]');

my $bareword_re = qr/\b[A-Za-z_][A-Za-z0-9_]*\b/;
my $qquote_re = qr/"(?:[^"\\]++|\\.)*+"/;
my $squote_re = qr/'(?:[^'\\]++|\\.)*+'/;
my $quote_re = qr/${qquote_re}|${squote_re}/;

# These never match spaces (except as part of a quote)
my $nonquote_atom_re
      = qr/ (?: [^,;\{\}\[\]"'\s]++ | \\["'] )++ | [,;\{\}\[\]] /xs;
my $atom_re = qr/ $quote_re | $nonquote_atom_re /x;

my $indent_unit = 2;

sub __insert_spaces() { # edits $_ in place
  #FIXME BUG HERE might corrupt interior of quoted strings

  ### TEMP? Verify that we can parse everything
  ### (probably redundant with 'unmatched tail' check in __fold)
  /\A(?: ${atom_re} | \s+ )+\z/xs or oops "regex problem($_)";

  s( $quote_re ?+ \K
     ( \bsub\s*${curlies_re} | (?: $nonquote_atom_re | \s+)*+ )
   )
   ( do {
       local $_ = $1;
       s/\ (?![\$\@])//g;                        # FIXME: is this correct?
       s/^sub\ ?(${curlies_re})/"sub { ".substr($1,1,length($1)-2)." }"/eg;
       s/=>/ => /g;
       s/(=>\s*[-.\w\\]+,)/$1 /g;  #  key => value,<add space here>
       s/([\]\}],)(?!\ )/$1 /g; # after ], or },
       #s/,(?!\ )/, /g;      # space after every comma
       # Insert a space after an opening bracket at start of line, so the
       # first item will line up with the indentation of stuff at that level.
       s/\ +/ /sg;           # collapse muiltiple spaces
       $_
     }
   )exsg;
}#__insert_spaces

my $foldunit_re = qr/${atom_re}(?: , | \s*=>)?+/x;

sub _fold { # edits $_ in place
  my $self = shift;
  my ($debug, $maxwidth, $maxwidth1, $pad) =
       (@$self{qw/Debug Foldwidth Foldwidth1/}, $self->Pad);
  return
    if $maxwidth == 0;  # no folding
  my $maxwid = $maxwidth1 || $maxwidth;
  #$maxwid = INT_MAX if $maxwid==0;  # no folding, but maybe space adjustments
  $maxwid = max(0, $maxwid - length($pad));
  my $smidgen = max(5, int($maxwid / 6));

  pos = 0;
  my $curr_indent = 0;
  my $next_indent = 0;
  our $nind; local $nind = 0;
  my sub __ind_adjustment(;$) {
    if ($debug) {
      my $len = $curr_indent + pos() - $-[0];
      say "#VisFold: @{_}atom «$^N» len=$len pos=${\pos} \$-[0]=$-[0] c_indent=$curr_indent n_indent=$next_indent nind=$nind mw=$maxwid,$smidgen";
    }
    local $_ = $^N;;
    /^["']/ ? 0 : ( (()=/[\[\{\(]/) - (()=/[\]\}\)]/) )*$indent_unit;
  }
  s(\G
    (?{ say "##Visfold at top: pos=",u(pos)," ->«",substr($_,pos//0),"»"
          if $debug;
        local $nind = $next_indent;  # initialize localized var
    })
    (
      \s*(${foldunit_re})  # at least one even if too wide
      (?{ local $nind = $nind + __ind_adjustment("First ") })
      (?:
          \s*
          (${foldunit_re})
          (?{ local $nind = $nind + __ind_adjustment("Cont  ") })
          (?(?{ my $len = $curr_indent + pos() - $-[0];
                $len <= ($^N eq "[" ? $maxwid-$smidgen : $maxwid)
              })|(*FAIL))
      )*+
    )
    (?{ $next_indent = $nind }) # copy to non-localized storage
    (?<extra>\s*)
   )(do{
       my $len = length($1);
       my $indent = $curr_indent;
       $curr_indent = $next_indent;
       $maxwid = max(0, $maxwidth - length($pad)); # stop using maxwidth1
       say "#VisFold: --folding-- after «$1» pos ${\pos} new mw=$maxwid"
         if $debug;
       $pad . (" " x $indent) . $1 ."\n"
     }
   )exsg
    or oops "\nnot matched (pad='$pad' maxwid=$maxwid):\n", _dbvis($_),"\n";
  s/\n\z//
    or oops "unmatched tail (pad='${pad}') in:\n",_dbvis($_);
  #say "## fold RESULT:", _dbvis($_);
}#__fold

sub __unescape_printables() {
  # Data::Dumper outputs wide characters as escapes with Useqq(1).
  #say "__un INPUT:$_";

  s( \G (${atom_re}) (?<trailing>\s*)
   )( do{
        local $_ = $1;
        if (/^"/) {  # "double quoted string
          s{ \G (?: [^\\]++ | \\[^x] )*+ \K ( \\x\{ (?<hex>[a-fA-F0-9]+) \} )
           }{
              my $orig = $1;
              local $_ = hex( length($+{hex}) > 6 ? '0' : $+{hex} );
              $_ = $_ > 0x10FFFF ? "\0" : chr($_); # 10FFFF is Unicode limit
              # Using 'lc' so regression tests do not depend on Data::Dumper's
              # choice of case when escaping wide characters.
              m<\P{XPosixGraph}|[\0-\377]> ? lc($orig) : $_
           }xesg;
        }
        $_
      }.$+{trailing}
   )xesg;
}

sub _postprocess_DD_result {
  (my $self, local $_) = @_;

  my ($debug, $vistype, $maxwidth, $maxwidth1)
    = @$self{qw/Debug _vistype Foldwidth Foldwidth1/};

  croak "invalid _vistype ", u($vistype)
    unless ($vistype//0) =~ /^(?:[salh]|hl)$/;

  say "##RAW  :",$_ if $self->{Debug};

  s/(['"])\Q$magic_num_prefix\E(.*?)(\1)/$2/sg;
  s/\Q$magic_numstr_prefix\E//sg;

  __unescape_printables;
  __insert_spaces;
  $self->_fold();

  if (($vistype//"s") eq "s") { }
  elsif ($vistype eq "a") {
    s/\A\[/(/ && s/\]\z/)/s or oops;
  }
  elsif ($vistype eq "l") {
    s/\A\[// && s/\]\z//s or oops;
  }
  elsif ($vistype eq "h") {
    s/\A\{/(/ && s/\}\z/)/s or oops;
  }
  elsif ($vistype eq "hl") {
    s/\A\{// && s/\}\z//s or oops;
  }
  else { oops }

  $_
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

  # cf man perldata
  state $userident_re = qr/ (?: (?=\p{Word})\p{XID_Start} | _ )
                            (?: (?=\p{Word})\p{XID_Continue}  )* /x;

  state $pkgname_re = qr/ ${userident_re} (?: :: ${userident_re} )* /x;

  state $anyvname_re =
    qr/ ${pkgname_re} | [0-9]+ | \^[A-Z]
                      | [-+!\$\&\;i"'().,\@\/:<>?\[\]\~\^\\] /x;

  state $anyvname_or_refexpr_re = qr/ ${anyvname_re} | ${curlies_re} /x;

  &_SaveAndResetPunct;

  my $debug = $self->Debug;
  my $useqq = $self->Useqq;

  my @pieces;  # list of [visfuncname or "", inputstring]
  { local $_ = $input;
    if (/\b((?:ARRAY|HASH)\(0x[a-fA-F0-9]+\))/) {
      state $warned=0;
      carp("Warning: String passed to ${s_or_d}vis may have been interpolated by Perl\n(use 'single quotes' to avoid this)\n") unless $warned++;
    }
    say "#Vis_Interp START «$_»" if $debug;
    while (
      /\G (
           # Stuff without variable references (might include \n etc. escapes)
           ( (?: [^\\\$\@\%] | \\[^\$\@\%] )++ )
           |
           # $#arrayvar $#$$...refvarname $#{aref expr} $#$$...{ref2ref expr}
           #
           (?: \$\#\$*+\K ${anyvname_or_refexpr_re} )
           |
           # $scalarvar $$$...refvarname ${sref expr} $$$...{ref2ref expr}
           #  followed by [] {} ->[] ->{} ->method() ... «zero or more»
           # EXCEPT $$<punctchar> is parsed as $$ followed by <punctchar>
           #
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
      say "#Vis expr «$_»" if $debug;
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
          # FIXME verify that multi-value eval results work
          push @pieces, ["avis", $_];
        }
        elsif ($sigl eq '%') {
          push @pieces, ["hvis", $_];
        }
        else { confess "BUG:sigl='$sigl'"; }
      } else {
        if (/^.+?(?<!\\)([\$\@\%])/) { confess __PACKAGE__." bug: Missed '$1' in «$_»" }
        if (/\\/) {
          # Interpolate backslash escapes so users can say (ivis '$foo\n';)
          s/([()])/\\$1/g;
          push @pieces, [ "e", "qq(".$_.")" ];
        } else {
          push @pieces, [ "=", $_ ];
        }
      }
    }
    if (!defined(pos) || pos() < length($_)) {
      my $leftover = substr($_,pos()//0);
      confess __PACKAGE__." Bug:LEFTOVER «$leftover»";
    }
  }# local $_

  my $q = $useqq ? "" : "q";
  my $funcname = $s_or_d . "vis" .$q;
  @_ = ($self, $funcname, \@pieces);
  goto &DB::DB_Vis_Interpolate
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
      my $maxwidth = $self->{Foldwidth};
      local $self->{Foldwidth1} = $self->{Foldwidth1} // $maxwidth;
      if ($maxwidth) {
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
    $errmsg =~ s/ at \(eval \d+\) line \d+[^\n]*\n?\z//s;
    Carp::confess("${label_for_errmsg}: Error interpolating '$evalarg' at $fname line $lno:\n$errmsg\n");
  }

  wantarray ? @result : (do{die "bug" if @result>1}, $result[0])
}# DB_Vis_Eval

1;
 __END__

=encoding UTF-8

=head1 NAME

Data::Dumper::Interp - Data::Dumper optimized for humans, with interpolation

=head1 SYNOPSIS

  use open IO => ':locale';
  use Data::Dumper::Interp;

  @ARGV = ('-i', '/file/path');
  my %hash = (abc => [1,2,3,4,5], def => undef);
  my $ref = \%hash;

  # Interpolate variables in strings, substituting Data::Dumper output
  say ivis 'FYI ref is $ref\nThat hash is: %hash\nArgs are @ARGV';

    -->FYI ref is {abc => [1,2,3,4,5], def => undef}
       That hash is: (abc => [1,2,3,4,5], def => undef)
       Args are ("-i","/file/path")

  # Label interpolated values with "expr=" 
  say dvis '@ARGV'; -->@ARGV=("-i","/file/path")

  # Functions to format one thing 
  say vis \@ARGV;   #any scalar   -->["-i", "/file/path"]
  say avis @ARGV;   -->("-i", "/file/path")
  say hvis %hash;   -->(abc => [1,2,3,4,5], def => undef)

  # Stringify objects
  { use bigint;
    my $struct = { debt => 999_999_999_999_999_999.02 };
    say vis $struct;
      --> {debt => (Math::BigFloat)999999999999999999.02}
  }

  # Wide characters are readable
  use utf8;
  my $h = {msg => "My language is not ASCII ☻ ☺ 😊 \N{U+2757}!"};
  say dvis '$h' ;
    --> h={msg => "My language is not ASCII ☻ ☺ 😊 ❗"}

  #-------- OO API --------

  say Data::Dumper::Interp->new()
      ->MaxStringwidth(50)->Maxdepth($levels)->vis($datum);

  #-------- UTILITY FUNCTIONS --------
  say u($might_be_undef);  # $_[0] // "undef"
  say qsh($string);        # quote if needed for /bin/sh
  say qshpath($pathname);  # quote except for ~ or ~username prefix

    system "ls -ld ".join(" ",map{ qshpath } ("/tmp", "~", "~sally/subdir"));


=head1 DESCRIPTION

The namesake feature of this module is interpolating Data::Dumper output 
into strings.
In addition, simple functions are provided to visualize a scalar, array, or hash.
And finally a few utilities to quote strings for /bin/sh.

Data::Dumper is used internally to visualize (i.e. format) data, 
with pre- and postprocessing to "improve" the results:
Output is compact (1 line if possibe) and omits a trailing newline;
Unicode characters appear as themselves,
objects like Math:BigInt are stringified, and some
Data::Dumper bugs^H^H^H^Hquirks are circumvented.
See "DIFFERENCES FROM Data::Dumper".

=head1 FUNCTIONS

=head2 ivis 'string to be interpolated'

Returns the argument with variable references and escapes interpolated
as in in Perl double-quotish strings, using Data::Dumper to
format variable values.

C<$var> is replaced by its value,
C<@var> is replaced by "(comma, sparated, list)",
and C<%hash> by "(key => value, ...)" visualizations.

Most Perl expressions are recognized including slices and method calls.
For example

  say ivis 'The value is ${\@myarray}[42]->{$key}->method(...)'

would print "The value is " followed by the Data:Dumper visualization of
the value of that expression.

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

=head2 vis

=head2 vis SCALAR

=head2 avis LIST

=head2 hvis EVENLIST

These are the underlying functions used by C<ivis> to visualize expressions.

C<vis> formats a single scalar ($_ if no argument is given).

C<avis> formats an array (or any list) as comma-separated values in parenthesis.

C<hvis> formats a hash as key => value pairs in parens.

=head2 alvis LIST

=head2 hlvis EVENLIST

These variants produce a bare list without the enclosing parenthesis

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
variables listed below.

The functions described above may also be used as I<methods>
when called on a C<Data::Dumper::Interp> object
(when not called as a method they create a new object internally).

For example:

   $msg = Data::Dumper::Interp->new()->Foldwidth(40)->avis(@ARGV);

returns the same string as

   local $Data::Dumper::Interp::Foldwidth = 40;
   $msg = avis(@ARGV);

=head1 Configuration Variables / Methods

These work in the same way as similar variables/methods in Data::Dumper.

Global variables determine the initial state of objects created by C<new>,
and the state of an object can be quieried or changed with corresponding
methods.  When a method is called with arguments to set a value,
the method returns the object itself to facilitate chained calls.

The following configuration methods may be used:

=head2 $Data::Dumper::Interp::MaxStringwidth or $obj->MaxStringwidth(INTEGER)

=head2 $Data::Dumper::Interp::Truncsuffix or $obj->Truncsuffix("...")

Longer strings are truncated and I<Truncsuffix> appended.
MaxStringwidth=0 (the default) means no limit.

=head2 $Data::Dumper::Interp::Foldwidth or $obj->Foldwidth(INTEGER)

Defaults to the terminal width at the time of first use.

=head2 $Data::Dumper::Interp::Stringify or $obj->Stringify(BOOL);

=head2                        or (classname);

=head2                        or ([list of classnames]);

A I<false> value disables object stringification.

A "1" (the default) enables stringification of all objects which
support it (i.e. they overload the "" operator).

Otherwise stringification is enabled only for the specified
class name(s).

=head2 $Data::Dumper::Interp::Sortkeys or $obj->Sortkeys(subref)

Controls sorting and optionally filtering of hash keys.  
See C<Data::Dumper> documentation.

C<Data::Dumper::Interp> provides a default which sorts
numeric substrings in keys by numerical
value (see "DIFFERENCES FROM Data::Dumper").

=head2 $Data::Dumper::Interp::Quotekeys or $obj->Quotekeys(subref)

See C<Data::Dumper> documentation.

=head1

=head1 UTILITY FUNCTIONS

=head2 u

=head2 u SCALAR

Returns the argument ($_ by default) if it is defined, otherwise
the string "undef".

=head2 qsh

=head2 qsh $string

=head2 qshpath

=head2 qshpath $might_have_tilde_prefix

The string ($_ by default) is quoted if necessary for parsing
by /bin/sh, which has different quoting rules than Perl.
"Double quotes" are used when no escapes would be needed,
otherwise 'single quotes'.

If the string contains only "shell-safe" ASCII characters
it is returned as-is, without quotes.

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

Visualized data structures differ from using C<Data::Dumper> directly 
as follows:

=over 2

=item *

Everything is shown on a single line if possible, otherwise wrapped to
the terminal width with indentation appropriate to structure levels.

A final newline is I<not> included.

=item *

Printable Unicode characters appear as themselves instead of \x{ABCD}.

Note: If your data contains 'wide characters', you must encode
the result before displaying it as explained in C<perluniintro>.
For example with C<< use open IO => ':locale'; >>

Undecoded binary octets (e.g. data read from a 'binmode' file)
will be escaped as individual bytes when necessary.

=item *

Object refs are replaced by the object's stringified representation.
For example, C<bignum> and C<bigrat> numbers are shown as easily
readable values rather than "bless( {...}, 'Math::BigInt')".

Stingified objects are prefixed with "(classname)" to make clear what
happened.

=item *

Hash keys are sorted treating numeric "components" numerically.
For example "A.20" sorts before "A.100".

=item *

Punctuation variables, including $@ and $?, are preserved over calls.

=item *

Representation of numbers and strings are made predictable and obvious:
Floating-point values always appear as numbers (not 'quoted strings'),
and strings containing digits like "42" appear as quoted strings
and not numbers (string vs. number detection is ala JSON::PP).

Such differences might not matter to Perl when executing code,
but may be important when communicating to a human.

=back

=head1 SEE ALSO

Data::Dumper

=head1 AUTHOR

Jim Avera  (jim.avera AT gmail dot com)

=for nobody Foldwidth1 is currently an undocumented experimental method
=for nobody which sets a different fold width for the first line only.
=for nobody Terse & Indent methods exist to croak; using them is not allowed.
=for nobody oops is an internal function (called to die if bug detected)
=for nobody Debug method is for author's debugging, not documented

=for Pod::Coverage Foldwidth1 Terse Indent oops Debug

=cut
