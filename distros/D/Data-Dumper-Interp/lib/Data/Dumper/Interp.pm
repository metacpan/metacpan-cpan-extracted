# License: Public Domain or CC0 See
# https://creativecommons.org/publicdomain/zero/1.0/
# The author, Jim Avera (jim.avera at gmail) has waived all copyright and
# related or neighboring rights.  Attribution is requested but is not required.

##FIXME: Refaddr(1) has no effect inside Blessed structures

use strict; use warnings FATAL => 'all'; use utf8;
#use 5.010; # say, state
#use 5.011; # cpantester gets warning that 5.11 is the minimum acceptable
#use 5.014; # /r for non-destructive substitution
use 5.018;  # lexical_subs
use feature qw(say state lexical_subs current_sub);
use feature 'lexical_subs';
use feature 'unicode_strings';



package
  # newline so Dist::Zilla::Plugin::PkgVersion won't add $VERSION
        DB {
  sub DB_Vis_Evalwrapper {
    eval $Data::Dumper::Interp::string_to_eval; ## no critic
  }
}

package Data::Dumper::Interp;

{ no strict 'refs'; ${__PACKAGE__."::VER"."SION"} = 997.999; }
our $VERSION = '7.019'; # VERSION from Dist::Zilla::Plugin::OurPkgVersion
our $DATE = '2025-06-22'; # DATE from Dist::Zilla::Plugin::OurDate

# Arrgh!  Moose forcibly enables experimental feature warnings!
# So import Moose first and then adjust warnings...
use Moose;

extends 'Data::Visitor' => { -version => 0.32 },
        'Exporter'      => { -version => 5.57 },
        ;

no warnings "experimental::lexical_subs";

use constant _SUPPORTS_CORE_BOOLS => defined &builtin::is_bool;
my $bitwise_supported;
BEGIN {
  $bitwise_supported = eval "use feature 'bitwise'";
  warnings->unimport("experimental::builtin") if _SUPPORTS_CORE_BOOLS;
}
use if $bitwise_supported, "feature", "bitwise";

use Data::Dumper ();
use Carp;
use POSIX qw(INT_MAX);
use Scalar::Util qw(blessed reftype refaddr looks_like_number weaken);
use List::Util 1.45 qw(min max first none all any sum0);
use Data::Structure::Util qw/circular_off/;
use Regexp::Common qw/RE_balanced RE_quoted/;
use Term::ReadKey ();
use Sub::Identify qw/sub_name sub_fullname get_code_location/;
use File::Basename qw/basename/;
use overload ();

############################ Exports #######################################
# Short-hand functions/methods are generated on demand (i.e. if imported or
# called as a method) based on a naming convention.
############################################################################

our @EXPORT    = qw( visnew
                     vis avis hvis ivis dvis
                     viso aviso hviso iviso dviso
                     visq avisq hvisq ivisq dvisq
                     visr avisr hvisr ivisr dvisr
                     rvis rvisq
                     addrvis addrvisl
                     u quotekey qsh qshlist qshpath
                   );

our @EXPORT_OK = qw(addrvis_digits

                    $Debug $MaxStringwidth $Trunctailwidth $Truncsuffix
                    $Objects $Foldwidth $Useqq $Quotekeys $Sortkeys
                    $Maxdepth $Maxrecurse $Deparse $Deepcopy);

our %EXPORT_TAGS = (
  null => [],
);

sub _generate_sub($;$); # forward

our ($COND_LB, $COND_RB, $COND_MULT, $LQ, $RQ);

#---------------------------------------------------------------------------
my $sane_cW = $^W;
my $sane_cH = $^H;
our @save_stack;
sub _SaveAndResetPunct() {
  # Save things which will later be restored
  push @save_stack, [ $@, $!+0, $^E+0, $., $,, $/, $\, $?, $^W ];
  # Reset sane values
  $,  = "";       # output field separator is null string
  $/  = "\n";     # input record separator is newline
  $\  = "";       # output record separator is null string
  $?  = 0;        # child process exit status
  $^W = $sane_cW; # our load-time warnings
  #$^H = $sane_cH; # our load-time pragmas (strict etc.)
}
sub _RestorePunct_NoPop() {
  ( $@, $!, $^E, $., $,, $/, $\, $?, $^W ) = @{ $save_stack[-1] };
}
sub _RestorePunct() {
  &_RestorePunct_NoPop;
  pop @save_stack;
}
#---------------------------------------------------------------------------

our $AUTOLOAD_debug;

sub import {
  my $class = shift;
  my @args = @_;

  my $exporting_default = (@args==0 or grep{ /:DEFAULT/ } @args);

  our $Debug;
  local $Debug = $Debug;
  if (my $tag = first{ /^:debug/i } @args) {
    @args = grep{ ! /^:debug/i } @args;
    my $level = ($tag =~ /=(\d+)/ ? $1 : 1);
    $AUTOLOAD_debug = $Debug = $level; # show generated code
  }

  if (grep{ /^:all$/i } @args) {
    @args = grep{ ! /^:all$/i } @args;
    # Generate all modifiers combinations as suffixes in alphabetical order.
    my %already = map{$_ => 1} @args;
    push @args, ":DEFAULT" unless $already{':DEFAULT'};
    for my $v1 (qw/avis hvis vis ivis dvis/) { # avisl hvisl ?
      for my $v2 ('1', '2', "") {
        for my $v3 ('l', "") {
          next if $v3 && $v1 !~ /^[ah]/; # 'l' only with avis or hvis
          for my $v4 ('o', "") {
            for my $v5 ('q', "") {
              for my $v6 ('r', "") {
                my $subname = $v1.$v2.$v3.$v4.$v5.$v6;
                next if $already{$subname}++;
                push @args, $subname;
              }
            }
          }
        }
      }
    }
  }

  foreach my $subname (@args, ($exporting_default ? @EXPORT : ())) {
    next unless $subname =~ /^[a-zA-Z]/a;  # skip :tag or $var
    push @EXPORT_OK, $subname;
    no strict 'refs';
    if (defined(*$subname{CODE})) {
      warn "# $subname ALREADY DEFINED\n" if ($Debug//0) > 1;
    } else {
      # Only generate a 'forward' stub to allow prototype checks.
      # Subs actually called will be defined via AUTOLOAD
      _generate_sub($subname, 1);
    }
  }

  @args = (':null') if @_ && !@args;

  warn "Passing to Exporter::import ",&_dbavis(@args),"\n"
    if $Debug;

  __PACKAGE__->export_to_level(1, $class, @args);
}

sub AUTOLOAD {  # invoked on call to undefined *method*
  our $AUTOLOAD;
  _SaveAndResetPunct();
  our $Debug;
  local $Debug = $AUTOLOAD_debug;
  carp "AUTOLOAD $AUTOLOAD" if $Debug;
  _generate_sub($AUTOLOAD);
  _RestorePunct();
  no strict 'refs';
  goto &$AUTOLOAD;
}
#sub DESTROY {}  #unnecessary: No D::D::Interp objects are ever instantiated

############################################################################
# Internal debug-message utilities

sub u(_); # forward
sub oops(@) { @_=("\n".(caller)." oops:\n",@_,"\n"); goto &Carp::confess }
sub btwN($@) { my $N=shift; local $_=join("",map{u} @_); s/\n\z//s; printf "%4d: %s\n",(caller($N))[2],$_; }
sub btw(@) { unshift @_,0; goto &btwN }

sub _chop_ateval($) {  # remove "at (eval N) line..." from an exception message
  (local $_ = shift) =~ s/ at \(eval[^\)]*\) line \d+[^\n]*\n?\z//s;
  $_
}
sub _croak_or_confess(@) {
  # Chain to croak, or to confess if there is an eval in the call stack
  if (Carp::longmess("") =~ /\beval\b/) {
    goto &Carp::confess;
  }
  goto &Carp::croak;
}

sub _tf($) { $_[0] ? "T" : "F" }
sub _showfalse(_) { $_[0] ? $_[0] : 0 }
sub _dbvisnew($) {
  my $v = shift;
  Data::Dumper->new([$v])->Terse(1)->Indent(0)->Quotekeys(0)
              ->Sortkeys(1)->Useqq(1)
              ###->Sortkeys(\&__sortkeys)->Pair("=>")
              #->Useperl(1)
}
sub _dbvis(_) {chomp(my $s=_dbvisnew(shift)->Useqq(1)->Dump); $s }
sub _dbvisq(_){chomp(my $s=_dbvisnew(shift)->Useqq(0)->Dump); $s }
sub _dbvis1(_){chomp(my $s=_dbvisnew(shift)->Maxdepth(1)->Useqq(1)->Dump); $s }
sub _dbvis2(_){chomp(my $s=_dbvisnew(shift)->Maxdepth(3)->Useqq(1)->Dump); $s }
sub _dbavis(@){ "(" . join(", ", map{_dbvis} @_) . ")" }
sub _dbavis2(@){ "(" . join(", ", map{_dbvis2} @_) . ")" }
sub _dbrvis(_) { (ref($_[0]) ? addrvis(refaddr $_[0]) : "")._dbvis($_[0])  }
sub _dbrvis2(_){ (ref($_[0]) ? addrvis(refaddr $_[0]) : "")._dbvis2($_[0]) }
sub _dbravis2(@){ "(" . join(", ", map{_dbrvis2} @_) . ")" }
sub _dbshow(_) {
  my $v = shift;
  blessed($v) ? "(".blessed($v).")".$v   # stringify with (classname) prefix
              : _dbvis($v)               # something else
}
our $_dbmaxlen = 300;
sub _dbrawstr(_) { "${LQ}".(length($_[0])>$_dbmaxlen ? substr($_[0],0,$_dbmaxlen-3)."..." : $_[0])."${RQ}" }
sub _dbstr($) {
  local $_ = shift;
  return "undef" if !defined;
  s/\x{0a}/\N{U+2424}/sg; # a special NL glyph
  s/ /\N{U+00B7}/sg;      # space -> Middle Dot
  s/[\x{00}-\x{1F}]/ chr( ord($&)+0x2400 ) /aseg;
  $_
}
sub _dbstrposn($$) {
  local $_ = shift;
  my $posn = shift;
  local $_dbmaxlen = max($_dbmaxlen+8, $posn+8);
  my $visible = _dbstr($_); # simplified 'controlpics'
  "posn=$posn shown at '(<<HERE)':"
    . substr($visible, 0, $posn+1)."(<<HERE)".substr($visible,$posn+1)
}
############################################################################


#################### Configuration Globals #################

our ($Debug, $MaxStringwidth, $Truncsuffix, $Trunctailwidth, $Objects,
     $Refaddr, $Foldwidth, $Foldwidth1,
     $Useqq, $Quotekeys, $Sortkeys,
     $Maxdepth, $Maxrecurse, $Deparse, $Deepcopy);

sub _reset_defaults() {
  $Debug          = 0            unless defined $Debug;
  $MaxStringwidth = 0            unless defined $MaxStringwidth;
  $Truncsuffix    = "..."        unless defined $Truncsuffix;
  $Trunctailwidth = 0            unless defined $Trunctailwidth;
  $Objects        = 1            unless defined $Objects;
  $Refaddr        = 0            unless defined $Refaddr;
  $Foldwidth      = undef        unless defined $Foldwidth;  # undef auto-detects
  $Foldwidth1     = undef        unless defined $Foldwidth1; # override for 1st

  # The following override Data::Dumper defaults
  # Initial D::D values are captured once when we are first loaded.

  #$Useqq          = "<unicode:controlpic>" unless defined $Useqq;
  $Useqq          = "<unicode>"    unless defined $Useqq;
  $Quotekeys      = 0            unless defined $Quotekeys;
  $Sortkeys       = \&__sortkeys unless defined $Sortkeys;
  $Maxdepth       = $Data::Dumper::Maxdepth   unless defined $Maxdepth;
  $Maxrecurse     = $Data::Dumper::Maxrecurse unless defined $Maxrecurse;
  $Deparse        = 0            unless defined $Deparse;
  $Deepcopy       = 0            unless defined $Deepcopy;
}
_reset_defaults(); # at startup

# This user-callable function (or method) restores default defaults
# Mainly useful after calling visnew->set_defaults()
sub reset_defaults() {
  undef $Debug;
  undef $MaxStringwidth;
  undef $Truncsuffix;
  undef $Trunctailwidth;
  undef $Objects;
  undef $Refaddr;
  undef $Foldwidth;  # undef auto-detects
  undef $Foldwidth1; # override for 1st

  undef $Useqq;
  undef $Quotekeys;
  undef $Sortkeys;
  undef $Maxdepth;
  undef $Maxrecurse;
  undef $Deparse;
  undef $Deepcopy;
  _reset_defaults();
}

#################### Methods #################

has dd => (
  is => 'ro',
  lazy => 1,
  default => sub{
    my $self = shift;
    Data::Dumper->new([],[])
      ->Terse(1)
      ->Indent(0)
      ->Sparseseen(1)
      ->Useqq($Useqq)
      ->Quotekeys($Quotekeys)
      ->Sortkeys($Sortkeys)
      ->Maxdepth($Maxdepth)
      ->Maxrecurse($Maxrecurse)
      ->Deparse($Deparse)
      ->Deepcopy($Deepcopy)
  },
  # This generates pass-through methods which call the dd object
  handles => [qw/Values Useqq Quotekeys Trailingcomma Pad Varname Quotekeys
                 Maxdepth Maxrecurse Useperl Sortkeys Deparse Deepcopy
                /],
);

# Config values which have no counter part in Data::Dumper
has Debug          => (is=>'rw', default => sub{ $Debug                 });
has MaxStringwidth => (is=>'rw', default => sub{ $MaxStringwidth        });
has Truncsuffix    => (is=>'rw', default => sub{ $Truncsuffix           });
has Trunctailwidth => (is=>'rw', default => sub{ $Trunctailwidth        });
has Objects        => (is=>'rw', default => sub{ $Objects               });
has Refaddr        => (is=>'rw', default => sub{ $Refaddr               });
has Foldwidth      => (is=>'rw', default => sub{
                         $Foldwidth // do{
                           _set_default_Foldwidth();
                           $Foldwidth
                         }
                       });
has Foldwidth1     => (is=>'rw', default => sub{ $Foldwidth1            });
has _Listform      => (is=>'rw');

sub _SetDefaults {
    my $self = shift;
    $Debug = $self->Debug();
    $MaxStringwidth = $self->MaxStringwidth();
    $Truncsuffix = $self->Truncsuffix();
    $Trunctailwidth = $self->Trunctailwidth();
    $Objects = $self->Objects();
    $Refaddr = $self->Refaddr();
    $Foldwidth = $self->Foldwidth();
    $Foldwidth1 = $self->Foldwidth1();
    $Quotekeys = $self->Quotekeys();
    # These from from the Data::Dumper object, via wrappers
    $Useqq = $self->Useqq();
    $Quotekeys = $self->Quotekeys();
    $Maxdepth = $self->Maxdepth();
    $Maxrecurse = $self->Maxrecurse();
    $Sortkeys = $self->Sortkeys();
    $Deparse = $self->Deparse();
    $Deepcopy = $self->Deepcopy();
    return $self
}

# Make "setters" return the outer object $self
around       [qw/Values Useqq Quotekeys Trailingcomma Pad Varname Quotekeys
                 Maxdepth Maxrecurse Useperl Sortkeys Deparse Deepcopy

                 Debug MaxStringwidth Truncsuffix Trunctailwidth Objects Refaddr
                 Foldwidth Foldwidth1 _Listform
                /] => sub{
  my $orig = shift;
  my $self = shift;
  #Carp::cluck("##around (@_)\n");
  if (@_ > 0) {
    $self->$orig(@_);
    return $self;
  }
  $self->$orig
};

############### Utility Functions #################

#---------------------------------------------------------------------------
# Display an address as <decimal:hex> showing only the last few digits.
# The number of digits shown increases when collisions occur.
# The arg can be a numeric address or a ref from which the addr is taken.
# If a ref the result is REFTYPEorOBJTYPE<dec:hex> otherwise just <dec:hex>
use constant _ADDRVIS_SHARED_MARK => "S*";
our $addrvis_ndigits = 3;
our $addrvis_seen    = {};   # full (decimal) address => undef
our $addrvis_dec_abbrs = {}; # abbreviated decimal digits => undef
sub _abbr_hex($) {
  # Preserve a _ADDRVIS_SHARED_MARK prefix, if present
  local $_ = shift;
  /^((?:\Q${\_ADDRVIS_SHARED_MARK}\E)?\K)(.*)/ or die;
  $1.substr(sprintf("%0*x", $addrvis_ndigits, $2), -$addrvis_ndigits)
}
sub _abbr_dec($) {
  # Strip off _ADDRVIS_SHARED_MARK prefix, if present
  local $_ = shift;
  /^((?:\Q${\_ADDRVIS_SHARED_MARK}\E)?\K)(.*)/ or die;
  substr(sprintf("%0*d", $addrvis_ndigits, $2), -$addrvis_ndigits)
}
sub _refaddrdechex($) {  # Returns just "<hex:dec>" (possibly marked as shared)
  my $arg = shift // return("undef");
  my $refstr = ref($arg);
  my $addr;
  if ($refstr ne "") {
    if ($INC{"threads/shared.pm"}
                    && defined(my $id = threads::shared::is_shared($arg))) {
      $addr = _ADDRVIS_SHARED_MARK.$id;
    } else {
      $addr = refaddr($arg)
    }
  }
  elsif (looks_like_number($arg)) { $addr = $arg }
  else {
    #Carp::cluck("addrvis arg '$arg' is neither a ref or a number\n");
    carp("addrvis arg '$arg' is neither a ref or a number\n");
    return ""
  }

  if (! exists $addrvis_seen->{$addr}) {
    my $dec_abbr = _abbr_dec($addr);
    while (exists $addrvis_dec_abbrs->{$dec_abbr}) {
      ++$addrvis_ndigits;
      %$addrvis_dec_abbrs = map{ (_abbr_dec($_) => undef) } keys %$addrvis_seen;
      $dec_abbr = _abbr_dec($addr);
    }
    $addrvis_dec_abbrs->{$dec_abbr} = undef;
    $addrvis_seen->{$addr} = undef;
  }
  '<'._abbr_dec($addr).':'._abbr_hex($addr).'>'
}
sub addrvis(_) {
  my $arg = shift // return("undef");
  my $r = _refaddrdechex($arg);  # hex:dec with possible shared-mem indicator
  ref($arg).$r
}
sub addrvisl(_) {
  # Return bare "hex:dec" or "Typename hex:dec"
  &addrvis =~ s/^([^\<]*)\<(.*)\>$/ $1 ? "$1 $2" : $2 /er or oops
}
sub addrvis_digits(;$) {
  return $addrvis_ndigits if ! defined $_[0];  # "get" request
  if ($_[0] <= $addrvis_ndigits) {
    return $addrvis_ndigits; # can not decrease
  }
  $addrvis_ndigits   = $_[0];
  %$addrvis_dec_abbrs = map{ (_abbr_dec($_) => undef) } keys %$addrvis_seen;
  $addrvis_ndigits;
}
sub addrvis_forget() {
  $addrvis_seen      = {};
  $addrvis_dec_abbrs = {};
  $addrvis_ndigits = 3;
}

=for Pod::Coverage addrvis_digits addrvis_forget

=cut

sub u(_) { $_[0] // "undef" }
sub quotekey(_); # forward.  Implemented after regex declarations.

sub __stringify_if_overloaded($) {
  if (defined(my $class = blessed($_[0]))) {
    return "$_[0]" if overload::Method($class,'""');
  }
  $_[0]
}

use constant _NIX_SHELL_UNSAFE_REGEX => qr/[^-=\w_:\.,\/]/a;
sub __nix_forceqsh(_) {
  local $_ = shift;
  return "undef" if !defined;  # undef without quotes
  $_ = vis($_) if ref;
  # Prefer "double quoted" if no shell escapes would be needed.
  if (/["\$`!\\\x{00}-\x{1F}\x{7F}]/) {
    # Unlike Perl, /bin/sh does not recognize any backslash escapes in '...'
    s/'/'\\''/g; # foo'bar => foo'\''bar
    return "'${_}'";
  } else {
    return "\"${_}\"";
  }
}

use constant _WIN_CMD_UNSAFE_REGEX   => qr/[^-=\w_:\.,\\]/a;
sub __win_forceqsh(_) {
  local $_ = shift;
  return "undef" if !defined;  # undef without quotes
  $_ = vis($_) if ref;
  # This was intended to quote as would be needed to pass the word as a
  # parameter to a command typed to cmd.com in Windows.
  # However parameter parameter parsing is implemented within each command
  # and there is no universal ruleset.   For example Strawberry perl
  # appears to split parameters on white space only, whereas (as I understand)
  # Windows commands, at least built-in ones, split words on any of
  # space tab , ; or = and all those must be protected, see
  #    https://ss64.com/nt/syntax-esc.html
  #
  # For the moment at least, qsh "quotes" words so they come through when
  # passed as parameters to Strawberry perl when, in cmd.com, you type
  #
  #    perl \path\to\script.pl PARAM1 PARAM2 ...
  #
  # Here's what I *think* is true:
  #  * "double quotes" escape word delimiters (space tab , ; =)
  #  * ^ escapes : & \ < > ^ | when NOT in "quotes"
  #    (but we always put them in "quotes")
  #  * ^<newline> (outside of "quotes") is ignored
  #    (it appears to be impossible to directly include a newline in a cmd
  #     parameter.  It requires a helper program or interpolating
  #     a %variable%, see https://superuser.com/a/1519790)
  #  * \ outside "quotes" means \
  #    \ inside "quotes" is literal _unless_ followed by "
  # Backslash usually need not be protected, except:
  #  * \ quotes " whether inside "quotes" or bare (!)
  #  * \ quotes \ ONLY(?) if immediately followed by " or \"
  #    otherwise \\ means two backslashes.
  #FIXME TODO UNFINISHED
  s/\\(?=")/\\\\/g;
  s/"/\\"/g;
  s/\\\z/\\\\/g; # because the closing " will follow
  return "\"${_}\"";  # 6/7/23: UNtested
}

sub qsh(_) {
  local $_ = __stringify_if_overloaded(shift());
  $^O eq "MSWin32" ?
    (defined && !ref && $_ ne "" && $_ ne "undef" && $_ !~ _WIN_CMD_UNSAFE_REGEX ? $_ : __win_forceqsh)
    :
    (defined && !ref && $_ ne "" && $_ ne "undef" && $_ !~ _NIX_SHELL_UNSAFE_REGEX ? $_ : __nix_forceqsh)
}
sub qshpath(_) {  # like qsh but does not quote initial ~ or ~username
  local $_ = __stringify_if_overloaded(shift());
  return qsh($_) if !defined or ref;
  my ($tilde_prefix, $rest) = /^( (?:\~[^\/\\]*[\/\\]?+)? )(.*)/xs or die;
  $rest eq "" ? $tilde_prefix : $tilde_prefix.qsh($rest)
}

# Should this have been called 'aqsh' ?
sub qshlist(@) { join " ", map{qsh} @_ }

########### Subs callable as either a Function or Method #############

sub __getself { # Return $self if passed or else create a new object
  local $@;
  my $blessed = eval{ blessed($_[0]) }; # In case a tie handler throws
  croak _chop_ateval($@) if $@;
  $blessed && $_[0]->isa(__PACKAGE__) ? shift : __PACKAGE__->new()
}
sub __getself_s { &__getself->Values([$_[0]]) }
sub __getself_a { &__getself->Values([[@_]])   }
sub __getself_h {
  my $obj = &__getself;
  ($#_ % 2)==1 or confess "Uneven arg count for key => val pairs";
  $obj->Values([{@_}])
}

sub _EnabUseqqFeature {
  # Append <feature> to Useqq ONLY if Useqq has not been changed from the
  # default (indicated by "<pointy brackets>" -- see setting of $Useqq = ... )
  # AND the default enables some extended features.
  my ($self, $feature) = @_;
  my $curr = $self->Useqq;
  return $self if length($curr//"") <= 1
                    || substr($curr,0,1) ne "<"
                    || substr($curr,-1,1) ne ">";
#btw '###ENABLE CHANGING Useqq; curr=', _dbvis($curr), "  \$Useqq=$Useqq";
  $self->Useqq($curr.$feature)
}

sub _utfoutput() {
  # Delay testing STDOUT until the first actual call which needs to know
  state $utf_output = grep /utf/i, PerlIO::get_layers(*STDOUT, output=>1);
}

sub _generate_sub($;$) {
  my ($arg, $proto_only) = @_;
  (my $methname = $arg) =~ s/.*:://;
  my sub error($) {
    _croak_or_confess "Invalid sub/method name '$methname' (@_)\n"
  }

  # Method names are ivis, dvis, vis, avis, or hvis with prepended
  # or appended modifier letters or digits (in any order), with
  # optional underscore separators.
  local $_ = $methname;

  s/alvis/avisl/;  # backwards compat.
  s/hlvis/hvisl/;  # backwards compat.

  # Discontinued because NOW visl means something else.
  #s/^[^diha]*\K(?:lvis|visl)/avisl/; # 'visl' same as 'avisl' for bw compat.

  s/([ahid]?vis|set_defaults)// or error "can not infer the basic function";
  my $basename = $1;  # avis, hvis, ivis, dvis, or vis
  my $N = s/(\d+)// ? $1 : undef;
  my %mod = map{$_ => 1} split //, $_;
  delete $mod{"_"}; # ignore underscores in names

  if (($Debug//0) > 1) {
    warn "## (D=$Debug) methname=$methname base=$basename \$_=$_\n";
  }
##  if ($basename =~ /^[id]/) {
##    error "'$1' is inapplicable to $basename" if /([ahl])/;
##  }
##  error "'$1' mis-placed: Only allowed as '${1}vis'" if /([ahi])/;


  # All these subs can be called as either or methods or functions.
  # If the first argument is an object it is used, otherwise a new object
  # is created; then option-setting methods are called as implied by
  # the specific sub name.
  #
  # Finally the _Do() method is invoked for primatives like 'vis'.
  #
  # For ivis/dvis, control jumps to _Interpolate() which uses the object
  # repeatedly when calling primatives to interpolate values into the string.

  my $listform = '';
  my $signature = $basename =~ /^[ah]/ ? '@' : '_'; # avis(@) ivis(_) vis(_)
  my $code = "sub $methname($signature)";
  if ($basename eq "vis") {
    my $listform = delete($mod{l}) ? 'l' : '';
    $code .= " { &__getself_s->_Listform('${listform}')";
  }
  elsif ($basename eq "avis") {
    my $listform = delete($mod{l}) ? 'l' : 'a';
    $code .= " { &__getself_a->_Listform('${listform}')";
  }
  elsif ($basename eq "hvis") {
    my $listform = delete($mod{l}) ? 'l' : 'h';
    $code .= " { &__getself_h->_Listform('${listform}')";
  }
  elsif ($basename eq "set_defaults") {
    $code .= " { &__getself" ;
  }
  elsif ($basename eq "ivis") {
    $code .= " { \@_ = ( &__getself" ;
  }
  elsif ($basename eq "dvis") {
    $code .= " { \@_ = ( &__getself->_EnabUseqqFeature(_utfoutput() ? ':showspaces:condense' : ':condense')" ;
    #$code .= " { \@_ = ( &__getself->_EnabUseqqFeature(':showspaces')" ;
  }
  else { oops "basename=",u($basename) }

  my $useqq = "";
  $useqq .= ":unicode:controlpics" if delete $mod{c};
  $useqq .= ":condense"            if delete $mod{C};
  $code .= '->Debug(2)'            if delete $mod{D};
  $useqq .= ":hex"                 if delete $mod{h};
  $code .= '->Objects(0)'          if delete $mod{o};
  $useqq .= ":octets"              if delete $mod{O};
  $code .= '->Refaddr(1)'          if delete $mod{r};
  $useqq .= ":underscores"         if delete $mod{u};

  $code .= "->Useqq(\$Useqq.'${useqq}')" if $useqq ne "";

  $code .= "->_EnabUseqqFeature(_utfoutput() ? ':showspaces:condense' : ':condense')" if delete($mod{d}) or $basename eq "dvis";

  $code .= "->Useqq(0)"     if delete $mod{q};

  $code .= "->Maxdepth($N)" if defined($N);

  if ($basename =~ /^([id])vis/) {
    $code .= ", shift, '$1' ); goto &_Interpolate }";
  }
  elsif ($basename eq 'set_defaults') {
    $code .= "->_SetDefaults }";
  } else {
    $code .= "->_Do }";
  }

  for (keys %mod) { error "Unknown or inappropriate modifier '$_'" }

  if ($proto_only) {
    $code =~ s/ *\{.*/;/ or oops;
  }
  # To see the generated code
  #   use Data::Dumper::Interp qw/:debug :DEFAULT/; # or :all
  if ($Debug) {
    warn "# generated: $code\n";
  }
  eval "$code";  oops "code=$code\n\$@=$@" if $@;
}#_generate_sub


sub visnew()  { __PACKAGE__->new() }  # shorthand


############# only internals follow ############

BEGIN {
  if (! Data::Dumper->can("Maxrecurse")) {
    # Supply if missing in older Data::Dumper
    eval q(sub Data::Dumper::Maxrecurse {
             my($s, $v) = @_;
             @_ == 2 ? (($s->{Maxrecurse} = $v), return $s)
                     : $s->{Maxrecurse}//0;
           });
    die $@ if $@;
  }
}

sub _get_terminal_width() {  # returns undef if unknowable
  if (u($ENV{COLUMNS}) =~ /^[1-9]\d*$/) {
    return $ENV{COLUMNS}; # overrides actual terminal width
  } else {
    local *_; # Try to avoid clobbering special filehandle "_"
    # This does not actualy work; https://github.com/Perl/perl5/issues/19142

    my $fh =
      -t STDOUT ? *STDOUT :
      -t STDERR ? *STDERR :
       # under Windows the filehandle must be an *output* handle
       do{my $fh; for("/dev/tty",'CONOUT$') { last if open $fh, $_ } $fh}
         || (-t STDIN && *STDIN)
       ;
    my ($width, $height);
    if ($fh) {
      # Some platforms (bsd?) carp if the terminal size can not be determined.
      # We don't want to see any such warnings.  Also there might be a
      # __WARN__ trap which we don't want to trigger
      #
      # Sigh.  It never ends!  On some platforms (different libc?)
      # "stty" directly prints "stdin is not a tty" which we can not trap.
      # Probably this is a bug in Term::Readkey where it should redirect
      # such messages to /dev/null.  So we have to do it here.
      require Capture::Tiny;
      () = Capture::Tiny::capture_merged(sub{
        delete local $SIG{__WARN__};
        delete local $SIG{__DIE__};
        ($width, $height) = eval{ Term::ReadKey::GetTerminalSize($fh) };
      });
    }
    return $width; # possibly undef (sometimes seems to be zero ?!?)
  }
}

sub _set_default_Foldwidth() {
  _SaveAndResetPunct();
  $Foldwidth = _get_terminal_width || 80;
  _RestorePunct();
  undef $Foldwidth1;
}

use constant _UNIQUE => substr(refaddr \&oops,-5);
use constant {
  _MAGIC_NOQUOTES_PFX   => "|NQMagic${\_UNIQUE}|",
  _MAGIC_KEEPQUOTES_PFX => "|KQMagic${\_UNIQUE}|",
  _MAGIC_REFPFX         => "|RPMagic${\_UNIQUE}|",
  _MAGIC_ELIDE_NEXT     => "|ENMagic${\_UNIQUE}|",
};

#---------------------------------------------------------------------------
my  $my_maxdepth;
our $my_visit_depth = 0;

my ($maxstringwidth, $truncsuffix, $trunctailwidth, $objects,
    $opt_refaddr, $listform, $debug);
my ($sortkeys, $ovopt);

sub _Do {
  oops unless @_ == 1;
  my $self = $_[0];

  local $_;
  &_SaveAndResetPunct;

  ($maxstringwidth, $truncsuffix, $trunctailwidth, $objects, $opt_refaddr, $listform, $debug)
    = @$self{qw/MaxStringwidth Truncsuffix Trunctailwidth Objects Refaddr _Listform Debug/};
  $sortkeys = $self->Sortkeys;

  $maxstringwidth = 0 if ($maxstringwidth //= 0) >= INT_MAX;
  $truncsuffix //= "...";
  $trunctailwidth = min($trunctailwidth//0, $maxstringwidth);
  $ovopt = "tagged";
  if (ref($objects) eq "HASH") {
    foreach my $key (keys %$objects) {
      if ($key eq 'show_classname') { # DEPRECATED
        $ovopt = $objects->{$key} ? "tagged" : "transparent"
      }
      elsif ($key eq 'overloads') {
        if (!defined($objects->{$key})) {
          $ovopt = "tagged";
        }
        elsif ($objects->{$key} =~ /^(?:tagged|transparent|ignore)$/) {
          $ovopt = $objects->{$key}
        }
        else { confess "Invalid 'overloads' sub-opt value '$objects->{$key}'" }
      }
      elsif ($key eq 'objects') { }
      else {
        confess "Objects hashref value has unknown key '$key'\n";
      }
    }
    $objects = $objects->{objects} // (ref($Objects) ? 1 : $Objects);
  }
  $objects = [ $objects ] unless ref($objects //= []) eq 'ARRAY';

  my @orig_values = $self->dd->Values;
  croak "Exactly one item may be in Values" if @orig_values != 1;
  my $original = $orig_values[0];
  btw "##ORIGINAL=",u($original),"=",_dbvis($original) if $debug;

  _croak_or_confess "*vis($original) called in void context.\nDid you forget to 'say ...'?"
    if ! defined wantarray;

  # Allow one extra level if we wrapped the user's args in __getself_[ah]
  $my_maxdepth = $self->Maxdepth || INT_MAX;
  ++$my_maxdepth if $listform && $my_maxdepth < INT_MAX;

  oops unless $my_visit_depth == 0;
  my $modified = $self->visit($original); # see Data::Visitor

  btw "## DD input : ",_dbvis($modified) if $debug;
  $self->dd->Values([$modified]);

  # Always call Data::Dumper with Indent(0) and Pad("") to get a single
  # maximally-compact string, and then manually fold the result to Foldwidth,
  # inserting the user's Pad before each line *except* the first.
  #
  # Also disable Maxdepth because we handle that ourself (see visit_ref).
  my $users_Maxdepth = $self->Maxdepth; # implemented by D::D
  $self->Maxdepth(0);
  my $users_pad = $self->Pad();
  $self->Pad("");

  my ($dd_result, $our_result);
  my ($sAt, $sQ) = ($@, $?);
  { my $dd_warning = "";

    { local $SIG{__WARN__} = sub{ $dd_warning .= $_[0] };
      eval{ $dd_result = $self->dd->Dump };
    }
    if ($dd_warning || $@) {
      warn "Data::Dumper complained:\n$dd_warning\n$@" if $debug;
      ($@, $?) = ($sAt, $sQ);
      $our_result = $self->dd->Values([$original])->Dump;
    }
  }
  ($@, $?) = ($sAt, $sQ);
  $self->Pad($users_pad);
  $self->Maxdepth($users_Maxdepth);

  $our_result //= $self->_postprocess_DD_result($dd_result, $original);

  # Allow deletion of the possibly-recursive clone
  circular_off($modified);
  $self->dd->Values([]);

  &_RestorePunct;
  $our_result;
}#_Do

#----------------------------------------------------------------------------
# methods called from Data::Visitor (and helpers) when transforming the input

our $in_overload_replacement = 0;

sub _prefix_refaddr($;$) {
  my ($item, $original) = @_;
  # If enabled by Refaddr(true):
  #
  # Prefix (the formatted representation of) a ref with it's abbreviated
  # address.  This is done by wrapping the ref in a temporary [array] with the
  # prefix, and unwrapping the Data::Dumper result in _postprocess_DD_result().
  return $item
    unless $opt_refaddr
           && ! $in_overload_replacement
           && ($listform ? ($my_visit_depth > 0) # Not on our argument container
                         : 1);                   # Else always if not a (list)
  my $pfx = _refaddrdechex($original//$item);
  # However don't do this if $item already has an addrvis() substituted,
  # which happens if an object does not stringify or provide another overload
  # replacement -- see _object_subst().
  my $ix = index($item,$pfx);
say "_prefix_refaddr: ior=$in_overload_replacement pfx=$pfx ix=$ix original=",_dbvis1($original)," item=$item" if $debug;
  return $item if $ix >= 0;
  $item = [ _MAGIC_REFPFX.$pfx, $item, _MAGIC_ELIDE_NEXT ];
  btwN 1, '@@@addrvis-prefixed object:',_dbvis2($item) if $debug;
  $item
}#_prefix_refaddr

sub _object_subst($) {
  my $item = shift;
  my $overload_depth;
  CHECKObject: {
    if (my $class = blessed($item)) {
btw '@@@repl item is obj ',$item if $debug;
      my $enabled;
      OSPEC:
      foreach my $ospec (@$objects) {
        if (ref($ospec) eq "Regexp") {
          my @stack = ($class);
          my %seen;
          while (my $c = shift @stack) {
            $enabled=1, last OSPEC if $c =~ $ospec;
            last CHECKObject if $seen{$c}++; # circular ISAs !
            no strict 'refs';
            push @stack, @{"${c}::ISA"};
          }
        } else {
          $enabled=1, last OSPEC if ($ospec eq "1" || $item->isa($ospec));
        }
      }
      last CHECKObject
        unless $enabled;
      if ($ovopt ne "ignore" && overload::Overloaded($item)) {
btw '@@@repl obj is overloaded' if $debug;
        # N.B. Overloaded(...) also returns true if it's a NAME of an
        # overloaded package; should not happen in this case.
        warn("Recursive overloads on $item ?\n"),last
          if $overload_depth++ > 10;
        my $cn = $ovopt eq "tagged" ? "($class)" : "";
        # Stringify objects which have the stringification operator
        if (overload::Method($class,'""')) {
          my $prefix = _show_as_number($item) ? _MAGIC_NOQUOTES_PFX : "";
btw '@@@repl prefix="',$prefix,'"' if $debug;
          $item = $item.""; # stringify;
          if ($item !~ /^${class}=REF/) {
            $item = "${prefix}${cn}$item";
          } else {
            # The "stringification" looks like Perl's default; don't prefix it
          }
btw '@@@repl stringified:',$item if $debug;
          redo CHECKObject;
        }
        # Substitute the virtual value behind an overloaded deref operator
        # and prefix with (classname) to make clear what happened.
        my sub _wrap_with_classname($) {
          $cn ? [ _MAGIC_REFPFX.$cn, $_[0], _MAGIC_ELIDE_NEXT ] : $_[0]
        }
        if (overload::Method($class,'@{}')) {
          $item = _wrap_with_classname \@{ $item };
btw '@@@repl (overload @{} --> ', $item,')' if $debug;
          redo CHECKObject;
        }
        if (overload::Method($class,'%{}')) {
          $item = _wrap_with_classname \%{ $item };
btw '@@@repl (overload %{} --> ', $item,')' if $debug;
          redo CHECKObject;
        }
        if (overload::Method($class,'${}')) {
          $item = _wrap_with_classname \${ $item };
btw '@@@repl (overload ${} --> ', $item,')' if $debug;
          redo CHECKObject;
        }
        if (overload::Method($class,'&{}')) {
          $item = _wrap_with_classname \&{ $item };
btw '@@@repl (overload &{} --> ', $item,')' if $debug;
          redo CHECKObject;
        }
        if (overload::Method($class,'*{}')) {
          $item = _wrap_with_classname \*{ $item };
btw '@@@repl (overload *{} --> ', $item,')' if $debug;
          redo CHECKObject;
        }
      }
      if ($class eq 'Regexp') {
        # D::D will just stringify it, which is fine except actual tabs etc.
        # will be shown as themselves and not \t etc.
        # We try to fix that in _postprocess_DD_result;
      } else {
        # No overloaded operator (that we care about);
        # substitute addrvis(obj)
btw '@@@repl (no overload repl, not Regexp)' if $debug;
        $item = _MAGIC_NOQUOTES_PFX.addrvis($item);
      }
    }
  }#CHECKObject
  $item
}#_object_subst

sub visit_value {
  my $self = shift;
  say "!V value ",_dbravis2(@_)," depth:$my_visit_depth" if $debug;
  my $item = shift;
  # N.B. Not called for hash keys (short-circuited in visit_hash_key)

  return $item
    if !defined($item);

  return _object_subst($item)
    if defined(blessed $item);

  return $item
    if reftype($item);  # some other (i.e. not blessed) reference

  # Prepend a "magic prefix" (later removed) to items which Data::Dumper is
  # likely to represent wrongly or anyway not how we want:
  #
  #  1. Scalars set to strings like "6" will come out as a number 6 rather
  #     than "6" with Useqq(1) or Useperl(1) (string-ness is preserved
  #     with other options).  IMO this is a Data::Dumper bug which the
  #     maintainers won't fix it because the difference isn't functionally
  #     relevant to correctly-written Perl code.  However we want to help
  #     humans debug their software by showing the representation they
  #     most likely used to create the datum.
  #
  #  2. Floating point values come out as "strings" to avoid some
  #     cross-platform issue.  For our purposes we want all numbers
  #     to appear unquoted.
  #
  if (looks_like_number($item) && $item !~ /^0\d/ && !_is_bool($item)) {
    my $prefix = _show_as_number($item) ? _MAGIC_NOQUOTES_PFX
                                        : _MAGIC_KEEPQUOTES_PFX ;
    $item = $prefix.$item;
btw '@@@repl prefixed item:',$item if $debug;
  }

  # Truncacte overly-long strings
  elsif ($maxstringwidth && !_show_as_number($item)
         && length($item) > $maxstringwidth + length($truncsuffix)) {
    my $tail_offset = length($item) - $trunctailwidth;
btw '@@@repl truncating ',substr($item,0,10),"...","[ msw=$maxstringwidth l=",length($item)," ttw=$trunctailwidth to=$tail_offset]" if $debug;
    #$item = "".substr($item,0,$maxstringwidth).$truncsuffix;
    $item = "".substr($item,0,$maxstringwidth-$trunctailwidth).$truncsuffix.substr($item,$tail_offset,$trunctailwidth);
  }
  $item
}#visit_value

sub visit_hash_key {
  my ($self, $item) = @_;
  say "!V visit_hash_key ",_dbravis2($item)," depth:$my_visit_depth" if $debug;
  return $item; # don't truncate or otherwise munge
}

sub visit_object {
  my $self = shift;
  my $item = shift;
  say "!V object a=",_refaddrdechex($item)," depth:$my_visit_depth"," item=",_dbvis1($item) if $debug;
  my $original = $item;

  local $my_visit_depth = $my_visit_depth + 1;
  # FIXME: with Objects(0) we should visit object internals so $my_maxdepth
  #  can be applied correctly.  Currently we just leave object refs as-is
  #  for D::D to expand, and Maxdepth will be handled incorrectly if this
  #  is underneath a magic_refaddr wrapper or avis/hvis top wrapper.

  # First register the ref (to detect duplicates); this calls visit_seen()
  # which usually substitutes something.
  { # Suppress Refaddr treatment of the results of any overloads
    local $in_overload_replacement = $in_overload_replacement + 1;
    my $nitem = $self->SUPER::visit_object($item);
    # Can not compare object refs with != in case that op is not defined!
    # (and refaddr() returns undef if $nitem is e.g. a "magic string")
    if (u(refaddr($nitem)) ne u(refaddr($item))) {
      say "!     (obj) new: $item --> ",_dbvis2($nitem) if $debug;
      $item = $nitem;
      # Re-visit the replacement item, which might contain inner structure.
      $nitem = $self->SUPER::visit($item);
      say "!     (obj) recursion on repl: $item --> $nitem" if $debug;
      $item = $nitem;
    }
  }
  $item = _prefix_refaddr($item, $original);
  $item
}#visit_object

sub visit_ref {
  my ($self, $item) = @_;
  if (ref($item) eq 'ARRAY') {
    say "!V ref  A=",_refaddrdechex($item)," depth:$my_visit_depth max:$my_maxdepth item=",_dbavis2(@$item) if $debug;
  } else {
    say "!V ref  a=",_refaddrdechex($item)," depth:$my_visit_depth max:$my_maxdepth item=",_dbvis1($item) if $debug;
  }
  my $original = $item;

  # The Refaddr option introduces [...] wrappers in the tree and so
  # Data::Dumper's Maxdepth() option will not work as we intend.
  # Therefore we implement Maxdepth ourself
  if ($my_visit_depth >= $my_maxdepth) {
    oops unless $my_visit_depth == $my_maxdepth;
    $item = _MAGIC_NOQUOTES_PFX.addrvis($item);
    say "!       maxdepth reached, returning ",_dbvis2($item) if $debug;
    return $item
  }

  # Show name of sub for CODE refs (using Sub::Identify)
  if (ref($item) eq 'CODE' && ! $self->Deparse()) {
    #$item = _MAGIC_NOQUOTES_PFX.addrvis($item);
    my $subname = sub_fullname($item);
    if ($subname =~ /__ANON__/) {  # add more info
      my ($file, $line) = get_code_location($item);
      $subname .= " from ".basename($file).":$line";
    }
    $item = _MAGIC_NOQUOTES_PFX.'\&'.$subname;
    say "!       CODEref without DEPARSE, returning ",_dbvis2($item) if $debug;
    #return $item;
  }

  # First descend into the structure, probably returning a clone
  local $my_visit_depth = $my_visit_depth + 1;
  if (ref($item)) { # not replaced above...
    #my $nitem = $self->SUPER::visit_ref($item);
    my $nitem = $self->SUPER::visit_ref($item);
    say "!       (ref) new: ",_dbvis2($item), " --> ",_dbvis2($nitem) if $debug;
    $item = $nitem;
  }

  # Prepend the original address to whatever the representation is now
  $item = _prefix_refaddr($item, $original);

  $item
}
sub visit_hash_entries {
  my ($self, $hash) = @_;
  # Visit in sorted order
  return map { $self->visit_hash_entry( $_, $hash->{$_}, $hash ) }
             (ref($sortkeys) ? @{ $sortkeys->($hash) } : (sort keys %$hash));
}

sub visit_glob {
  my ($self, $item) = @_;
  say "!V glob ref()=",ref($item)," depth:$my_visit_depth"," item=",_dbravis2($item) if $debug;
  # By default Data::Visitor will create a new anon glob in the output tree.
  # Instead, put the original into the output so the user can recognize
  # it e.g. "*main::STDOUT" instead of an anonymous from Symbol::gensym
  return $item
}

sub visit_seen {
  my ($self, $data, $first_result) = @_;
  say "!V seen orig=",_dbrvis2($data)," depth:$my_visit_depth","  1stres=",_dbrvis2($first_result)
    if $debug;

  # $data is a ref which has been visited before, i.e. there is a circularity.
  # Data::Dumper will display a $VAR->... expression.
  # With the Refaddr option the $VAR index may be incorrect due to the
  # temporary [...] wrappers inserted into the cloned tree.
  #
  # Therefore if Refaddr is in effect substitute an addrvis() string
  # which the user will be able to match with other refs to the same thing.
  if ($opt_refaddr) {
    my $t = ref($data);
    return _MAGIC_NOQUOTES_PFX._refaddrdechex($data)."[...]" if $t eq "ARRAY";
    return _MAGIC_NOQUOTES_PFX._refaddrdechex($data)."{...}" if $t eq "HASH";
    return _MAGIC_NOQUOTES_PFX._refaddrdechex($data)."\\..." if $t eq "SCALAR";
    return _MAGIC_NOQUOTES_PFX.addrvis($data);
  }

  $first_result
}

#---------------------------------------------------------------------
sub _preprocess { # Modify the cloned data
  no warnings 'recursion';
  my ($self, $cloned_itemref, $orig_itemref) = @_;
  my ($debug, $seenhash) = @$self{qw/Debug Seenhash/};

btw '##pp AAA cloned=",addrvis($cloned_itemref)," -> ',_dbvis($$cloned_itemref) if $debug;
btw '##         orig=",addrvis($orig_itemref)," -> ",_dbvis($$orig_itemref)' if $debug;

  # Pop back if this item was visited previously
  if ($seenhash->{ _refaddrdechex($cloned_itemref) }++) {
    btw '     Seen already' if $debug;
    return
  }

  # About TIED VARIABLES:
  # We must never modify a tied variable because of user-defined side-effects.
  # So when we want to replace a tied variable we untie it first, if possible.
  # N.B. The whole structure was cloned, so this does not untie the
  # user's variables.
  #
  # All modifications (untie and over-writing) is done in eval{...} in case
  # the data is read-only or an UNTIE handler throws -- in which case we leave
  # the cloned item as it is.  This occurs e.g. with the 'Readonly' module;
  # I tried using Readonly::Clone (insterad of Clone::clone) to copy the input,
  # since it is supposed to make a mutable copy; but it has bugs with refs to
  # other refs, and doesn't actually make everything mutable; it was a big mess
  # so now taking the simple way out.

    # Side note: Taking a ref to a member of a tied container,
    # e.g. \$tiedhash{key}, actually returns an overloaded object or some other
    # magical thing which, every time it is de-referenced, FETCHes the datum
    # into a temporary.
    #
    # There is a bug somewhere which makes it unsafe to store these fake
    # references inside tied variables because after the variable is 'untie'd
    # bad things can happen (refcount problems?).   So after a lot of mucking
    # around I gave up trying to do anything intelligent about tied data.
    # I still have to untie variables before over-writing them with substitute
    # content.

  # Note: Our Item is only ever a scalar, either the top-level item from the
  # user or a member of a container we unroll below.  In either case the
  # scalar could be either a ref to something or a non-ref value.

  eval {
    if (tied($$cloned_itemref)) {
      btw '     Item itself is tied' if $debug;
      my $copy = $$cloned_itemref;
      untie $$cloned_itemref;
      $$cloned_itemref = $copy; # n.b. $copy might be a ref to a tied variable
      oops if tied($$cloned_itemref);
    }

    my $rt = reftype($$cloned_itemref) // ""; # "" if item is not a ref
    if (reftype($cloned_itemref) eq "SCALAR") {
      oops if $rt;
      btw '##pp item is non-ref scalar; stop.' if $debug;
      return
    }

    # Item is some kind of ref
    oops unless reftype($cloned_itemref) eq "REF";
    oops unless reftype($orig_itemref) eq "REF";

    if ($rt eq "SCALAR" || $rt eq "LVALUE" || $rt eq "REF") {
      btw '##pp dereferencing ref-to-scalarish $rt' if $debug;
      $self->_preprocess($$cloned_itemref, $$orig_itemref);
    }
    elsif ($rt eq "ARRAY") {
      btw '##pp ARRAY ref' if $debug;
      if (tied @$$cloned_itemref) {
        btw '     aref to *tied* ARRAY' if $debug;
        my $copy = [ @$$cloned_itemref ]; # only 1 level
        untie @$$cloned_itemref;
        @$$cloned_itemref = @$copy;
      }
      for my $ix (0..$#{$$cloned_itemref}) {
        $self->_preprocess(\$$cloned_itemref->[$ix], \$$orig_itemref->[$ix]);
      }
    }
    elsif ($rt eq "HASH") {
  btw '##pp HASH ref' if $debug;
      if (tied %$$cloned_itemref) {
        btw '     href to *tied* HASH' if $debug;
        my $copy = { %$$cloned_itemref }; # only 1 level
        untie %$$cloned_itemref;
        %$$cloned_itemref = %$copy;
        die if tied %$$cloned_itemref;
      }
      #For easier debugging, do in sorted order
      btw '   #### iterating hash values...' if $debug;
      for my $key (sort keys %$$cloned_itemref) {
        $self->_preprocess(\$$cloned_itemref->{$key}, \$$orig_itemref->{$key});
      }
    }
  };#eval
  if ($@) {
    btw "*EXCEPTION*, just returning\n$@\n" if $debug;
  }
}

sub _is_bool(_) {
  _SUPPORTS_CORE_BOOLS && builtin::is_bool($_[0])
}

sub _show_as_number(_) {
  my $value = shift;

  # IMPORTANT: We must not do any numeric ops or comparisions
  # on $value because that may set some magic which defeats our attempt
  # to try bitstring unary & below (after a numeric compare, $value is
  # apparently assumed to be numeric or dual-valued even if it
  # is/was just a "string").

  return 0 if !defined $value;

  # if the utf8 flag is on, it almost certainly started as a string
  return 0 if (ref($value) eq "") && utf8::is_utf8($value);

  return 0 if _is_bool($value);

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
    no if $bitwise_supported, "feature", "bitwise";
    no warnings "once";
    # Use FF... so we can see what $value was in debug messages below
    my $dummy = ($value & "\x{FF}\x{FF}\x{FF}\x{FF}\x{FF}\x{FF}\x{FF}\x{FF}");
  };
  btw '##_san $value \$@=$@' if $Debug;
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
    if ($@ =~ /no method found/) { # overloaded but does not do '&'
      # It must use overloads, but does not implement '&'
      # Assume it is string-ish
      return 0 if defined blessed($value); # else our mistake, isn't overloaded
    }
    warn "# ".__PACKAGE__." : value=",_dbshow($value),
         "\n    Unhandled warn/exception from unary & :$@\n"
      if $Debug;
    # Unknown problem, treat as a string
    return 0;
  }
  elsif (ref($uand_str_result) ne "" && $uand_str_result =~ /NaN|Inf/) {
    # unary & returned an object representing Nan or Inf
    # (e.g. Math::BigFloat) so $value must be numberish.
    return 1;
  }
  warn "# ".__PACKAGE__." : (value & \"...\") succeeded\n",
       "    value=", _dbshow($value), "\n",
       "    uand_str_result=", _dbvis($uand_str_result),"\n"
    if $Debug;
  # Sigh.  With Perl 5.32 (at least) $value & "..." stringifies $value
  # or so it seems.
  if (blessed($value)) {
    # +42 might throw if object is not numberish e.g. a DateTime
    if (blessed(eval{ $value + 42 })) {
      warn "    Object and value+42 is still an object, so probably numberish\n"
        if $Debug;
      return 1
    } else {
      warn "    Object and value+42 is NOT an object, so it must be stringish\n"
        if $Debug;
      return 0
    }
  } else {
    warn "    NOT an object, so must be a string\n",
      if $Debug;
    return 0;
  }
}# _show_as_number

# Split keys into "components" (e.g. 2_16.A has 3 components) and sort
# components containing only digits numerically.
sub __sortkeys {
  my $hash = shift;
  my $r = [
    sort { my @a = split /(?<=\d)(?=\D)|(?<=\D)(?=\d)/,$a;
           my @b = split /(?<=\d)(?=\D)|(?<=\D)(?=\d)/,$b;
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
  ];
  $r
}

my $quoted_re = RE_quoted(-delim => q{'"});

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

my $addrvis_re = qr/\<\d+:(?:\Q${\_ADDRVIS_SHARED_MARK}\E)?[\da-fA-F]+\>/;

sub __unmagic_atom() {  # edits $_
##  # FIXME this probably could omit the ([^'"]*?) bc there is never anything
##  # between the open quote and the _MAGIC_NOQUOTES_PFX
##  s/(['"])([^'"]*?)
##    (?:\Q${\_MAGIC_NOQUOTES_PFX}\E)
##    (.*?)(\1)/$2$3/xgs;

  s/(['"])
    (?:\Q${\_MAGIC_NOQUOTES_PFX}\E) (.*?)
    (\1)/do{ local $_ = $2;
             s!\\(.)!$1!g;  # undo double-quotish backslash escapes
             $_ }/xegs;

  s/\Q${\_MAGIC_KEEPQUOTES_PFX}\E//gs;
}

sub __unesc_unicode() {  # edits $_
  if (/^"/) {
    # Data::Dumper with Useqq(1) outputs wide characters as hex escapes;
    # turn them back into the original characters if "printable".
    # That means "Graph" category EXCEPT:
    #   BOM (which is ZERO WIDTH NO-BREAK SPACE so is considered "Graphical")
    #   and any other "Format" category Unicode characters; we want see those
    #   in hex.
    s{
       \G (?: [^\\]++ | \\[^x] )*+ \K (?<w> \\x\x{7B} (?<hex>[a-fA-F0-9]+) \x{7D} )
     }{
       my $orig = $+{w};
       local $_ = hex( length($+{hex}) > 6 ? '0' : $+{hex} );
       $_ = $_ > 0x10FFFF ? "\0" : chr($_); # 10FFFF is Unicode limit
       # Using 'lc' so regression tests do not depend on Data::Dumper's
       # choice of case when escaping wide characters.
       (m<\P{XPosixGraph}|[\0-\177]>
          || m<\p{General_Category=Format}>) ? lc($orig) : $_
     }xesg;
  }
}

my %ctlesc2codepoint = (
  '\\a' => ord("\a"),
  '\\b' => ord("\b"),
  '\\t' => ord("\t"),
  '\\n' => ord("\n"),
  '\\f' => ord("\f"),
  '\\r' => ord("\r"),
  '\\e' => ord("\e"),
);
sub __unesc_nonoctal () {  # edits $_
  # Change backslash escapes like \n back to octal escapes.
  # This is to better visualize binary octet streams
  if (/^"/) {
    s{
       \G (?: [^\\]++ | \\[x0-7] )*+ \K (?<w> \\[abtnfre])(?<digitnext>\d?)
     }{
      $+{digitnext}
        ? sprintf("\\%03o", ($ctlesc2codepoint{$+{w}} // oops))
        : sprintf("\\%01o", ($ctlesc2codepoint{$+{w}} // oops))
     }xesg;
  }
}

sub __change_quotechars($$$) {  # edits $_
  if (s/^"//) {
    oops unless s/"$//;
    my ($pfx, $l, $r) = @_;
    s/\\"/"/g;
    s/([\Q$l\E])/\\$1/g if length($l)==1; # assume traditional qqLR
    s/([\Q$r\E])/\\$1/g if length($r)==1; # with single-character brackets
    $_ = $pfx.$l.$_.$r;
  }
}

my %qqesc2controlpic = (
  '\0' => "\N{SYMBOL FOR NULL}",   # occurs if next char is not a digit
  '\000' => "\N{SYMBOL FOR NULL}", # occurs if next char is a digit
  '\a' => "\N{SYMBOL FOR BELL}",
  '\b' => "\N{SYMBOL FOR BACKSPACE}",
  '\e' => "\N{SYMBOL FOR ESCAPE}",
  '\f' => "\N{SYMBOL FOR FORM FEED}",
  '\n' => "\N{SYMBOL FOR NEWLINE}",
  '\r' => "\N{SYMBOL FOR CARRIAGE RETURN}",
  '\t' => "\N{SYMBOL FOR HORIZONTAL TABULATION}",
);
my %char2controlpic = (
  map{
    my $cp = $qqesc2controlpic{$_};
    my $char = eval(qq("$_")) // die;
    die "XX<<$_>> YY<<$char>>" unless length($char) == 1;
    ($char => $cp)
  } keys %qqesc2controlpic
);
sub __subst_controlpic_backesc() {  # edits $_
  # Replace '\t' '\n' etc. escapes with "control picture" characters
  return unless/^"/;
  s{ \G (?: [^\\]++ | \\[^0abefnrt] )*+ \K
        ( \\[abefnrt] | \\0(?![0-7]) | \\[0-3][0-7][0-7] )
   }{
      $qqesc2controlpic{$1} // $1
    }xesg;
}
sub __subst_visiblespaces() {  # edits $_
  if (/^"/) {
    #s{\N{MIDDLE DOT}}{\N{BLACK LARGE CIRCLE}}g;
    #s{ }{\N{MIDDLE DOT}}g;
    s{ }{\N{OPEN BOX}}g;  # ␣
  }
}

sub __condense_strings($) {  # edits $_
  if (/^"/) {
    my $minrep_m1 = $_[0] - 1;
    my $singlechar_restr = "[^\\\\${COND_LB}${COND_RB}${COND_MULT}]";

    # Special case a string of nul represented as \n\n\n...\00n (n=0..7)
    # D::D generates this to avoid ambiguity if a digit follows
    s<( (\\([0-7])){$minrep_m1,}\\00\g{-1} )>
     < $COND_LB."${2}${COND_MULT}".((length($1)-2)/length($2)).$COND_RB >xge;

    # \0 \1 ... if there is no digit following, which makes it ambiguous
    s<( (\\\d) \g{-1}{$minrep_m1,} ) (?![0-7]) >
     < $COND_LB."${2}${COND_MULT}".(length($1)/length($2)).$COND_RB >xge;

    # \x for almost any x besides a digit or \
    s<( ($singlechar_restr | \\\D | \\[0-3][0-7][0-7] | \\x\{[^\{\}]+\})
        \g{-1}{$minrep_m1,} )
     >
     < $COND_LB."${2}${COND_MULT}".(length($1)/length($2)).$COND_RB >xge;
  }
}

sub __nums_in_hex() {
  if (looks_like_number($_)) {
    s/^([1-9]\d+)$/ sprintf("%#x", $1) /e; # Leave single-digit numbers as-is
  }
}
sub __nums_with_underscores() {
  if (looks_like_number($_)) {
    while( s/^([^\._]*?\d)(\d\d\d)(?=$|\.|_)/$1_$2/ ) { }
  }
}

my $indent_unit;

sub _mycallloc(;@) {
  my ($lno, $subcalled) = (caller(1))[2,3];
  ":".$lno.(@_ ? _dbavis(@_) : "")." "
}

use constant {
  _WRAP_ALWAYS  => 1,
  _WRAP_ALLHASH => 2,
};
use constant _WRAP_STYLE => (_WRAP_ALLHASH);

sub _postprocess_DD_result {
  (my $self, local $_, my $original) = @_;
  no warnings 'recursion';
  my ($debug, $listform, $foldwidth, $foldwidth1)
    = @$self{qw/Debug _Listform Foldwidth Foldwidth1/};
  my $useqq = $self->Useqq();

  carp "WARNING: The Useqq specification string ",_dbvis($useqq)," contains a non-ASCII character but 'use utf8;' was not in effect when the literal was compiled; the intended chracter was probably not used.\n"
    if $useqq =~ /[^\x{0}-\x{7F}]/ && !utf8::is_utf8($useqq);

  my ($unesc_unicode,$condense_strings,$octet_strings,$nums_in_hex,
      $controlpics,$showspaces,$underscores,$q_pfx,$q_lq,$q_rq);
  if ($useqq && $useqq ne "1") {
    my @useqq = split /(?<!\\):/, $useqq;
    foreach (@useqq) {
      $unesc_unicode    = 1,next if /utf|unic/;
      $condense_strings = 1,next if /cond/;
      $octet_strings    = 1,next if /octet/;
      $nums_in_hex      = 1,next if /hex/;
      $controlpics      = 1,next if /pic/;
      $showspaces        = 1,next if /space/;
      $underscores      = 1,next if /under/;
      $_ = "qq={}" if $_ eq "qq"; # deprecated
      if (/^qq=(.)(.)$/) { # deprecated
        $q_pfx = "qq"; $q_lq = $1; $q_rq = $2;
        next
      }
      next if $_ eq ""; # null specifier
      if (/style=((?:[^:,]+|\\.)+),((?:[^:]|\\.)+)/) {
        $q_pfx = ""; $q_lq = $1; $q_rq = $2;
        $q_lq =~ s/\\(.)/$1/g; $q_rq =~ s/\\(.)/$1/g;
        next
      }
      oops "Invalid ",_dbvis($_)," in Useqq specifier ",_dbvis($useqq),"\n";
    }
  }

  my $pad = $self->Pad() // "";

  $indent_unit = 2; # make configurable?

  my $maxlinelen = $foldwidth1 || $foldwidth || INT_MAX;
  my $maxlineNlen = ($foldwidth // INT_MAX) - length($pad);

  if ($unesc_unicode && _utfoutput()) {
    # Probably it's safe to use wide characters
    $COND_LB = "\N{LEFT DOUBLE PARENTHESIS}";
    $COND_RB = "\N{RIGHT DOUBLE PARENTHESIS}";
    $COND_MULT = "\N{MULTIPLICATION SIGN}";
    $LQ = "«";
    $RQ = "»";
  } else {
    $COND_LB = "(";
    $COND_RB = ")";
    $COND_MULT = "x";
    $LQ = "<<";
    $RQ = ">>";
  }

  if ($debug) {
    our $_dbmaxlen = INT_MAX;
    btw "## DD result: fw1=",u($foldwidth1)," fw=",u($foldwidth)," pad='${pad}' maxll=$maxlinelen maxlNl=$maxlineNlen\n   result=",_dbrawstr($_);
  }

  my $top = { tlen => 0, children => [] };
  my $context = $top;
  my $prepending = "";

  my sub atom($;$) {
    (local $_, my $mode) = @_;
    $mode //= "";

    __unmagic_atom ;
    __unesc_unicode          if $unesc_unicode;
    __unesc_nonoctal         if $octet_strings;
    __subst_controlpic_backesc      if $controlpics;
    __subst_visiblespaces    if $showspaces;
    __condense_strings(8)    if $condense_strings;
    __change_quotechars($q_pfx, $q_lq, $q_rq) if defined($q_pfx);
    __nums_in_hex            if $nums_in_hex;
    __nums_with_underscores  if $underscores;

    if ($prepending) { $_ = $prepending . $_; $prepending = ""; }

    btwN 1,"###atom",_mycallloc(), _dbrawstr($_),"($mode)"
      ,"\n context:",_dbvisnew($context)->Sortkeys(sub{[grep{exists $_[0]->{$_}} qw/O C tlen children CLOSE_AFTER_NEXT/]})->Dump()
      if $debug;
    if ($mode eq "prepend_to_next") {
      $prepending .= $_;
    } else {
      if ($mode eq "") {
        push @{ $context->{children} }, $_;
      }
      elsif ($mode eq "open") {
        my $child = {
          O => $_,
          tlen => 0, # incremented below
          children => [],
          C => undef,
          parent => $context,
        };
        weaken( $child->{parent} );
        push @{ $context->{children} }, $child;
        $context = $child;
      }
      elsif ($mode eq "close") {
        oops if defined($context->{C});
        $context->{C} = $_;
        $context->{tlen} += length;
        $context = $context->{parent}; # undef if closing the top item
      }
      elsif ($mode eq "append_to_prev") {
        my $prev = $context;
        { #block for 'redo'
          oops "No previous!" unless @{$prev->{children}} > 0;
          if (ref($prev->{children}->[-1] // oops)) {
            $prev = $prev->{children}->[-1];
            if (! $prev->{C}) { # empty or not-yet-read closer?
              redo; # ***
            }
            $prev->{C} .= $_;
          } else {
            $prev->{children}->[-1] .= $_;
          }
        }
      }
      else {
        oops "mode=",_dbvis($mode);
      }
      my $c = $context;
      while(defined $c) {
        $c->{tlen} += length($_);
        $c = $c->{parent};
      }
      if ($context->{CLOSE_AFTER_NEXT}) {
        oops(_dbvis($context)) if defined($context->{C});
        $context->{C} = "";
        $context = $context->{parent};
      }
    }
  }#atom

  my sub fat_arrow($) {  # =>
    my $lhs = $context->{children}->[-1] // oops;
    oops if ref($lhs);
    my $newchild = {
      O => "",
      tlen => length($lhs),
      children => [ $lhs ],
      C => undef,
      parent => $context,
    };
    weaken($newchild->{parent});
    $context->{children}->[-1] = $newchild;
    $context = $newchild;
    atom($_[0]); # the " => "
    oops unless $context == $newchild;
    $context->{CLOSE_AFTER_NEXT} = 1;
  }

  # There is a trade-off between compactness (e.g. want a single line when
  # possible), and ease of reading large structures.
  #
  # At any nesting level, if everything (including any nested levels) fits
  # on a single line, then that part is output without folding;
  #
  # 4/25/2023: Now controlled by constant _WRAP_STYLE:
  #
  # (_WRAP_STYLE == _WRAP_ALWAYS):
  # If folding is necessary, then *every* member of the folded block
  # appears on a separate line, so members all vertically align.
  #
  # *(_WRAP_STYLE & _WRAP_ALLHASH): Members of a hash (key => value)
  # are shown on separate lines, but not members of an array.
  #
  # Otherwise:
  #
  # When folding is necessary, every member appears on a separate
  # line if ANY of them will not fit on a single line; however if
  # they all fit individually, then shorter members will be run
  # together on the same line.  For example:
  #
  #    [aaa,bbb,[ccc,ddd,[eee,fff,hhhhhhhhhhhhhhhhhhhhh,{key => value}]]]
  #
  # might be shown as
  #    [ aaa,bbb,  # N.B. space inserted before aaa to line up with next level
  #      [ ccc,ddd,  # packed because all siblings fit individually
  #        [eee,fff,hhhhhhhhhhhhhhhhhhhhh,{key => value}] # entirely fits
  #      ]
  #    ]
  # but if Foldwidth is smaller then like this:
  #    [ aaa,bbb,
  #      [ ccc,  # sibs vertically-aligned because not all of them fit
  #        ddd,
  #        [ eee,fff,  # but within this level, all siblings fit
  #          hhhhhhhhhhhhhhhhhhhhh,
  #          {key => value}
  #        ]
  #      ]
  #    ]
  # or if Foldwidth is very small then:
  #    [ aaa,
  #      bbb,
  #      [ ccc,
  #        ddd,
  #        [ eee,
  #          fff,
  #          hhhhhhhhhhhhhhhhhhhhh,
  #          { key
  #            =>
  #            value
  #          }
  #        ]
  #      ]
  #    ]
  #
  # Note: Indentation is done regardless of Foldwidth, so deeply nested
  # structures may extend beyond Foldwidth even if all elements are short.

  my $outstr;
  my $linelen;
  our $level;
  my sub expand_children($) {
    my $parent = shift;
    # $level is already set appropriately for $parent->{children},
    # and the parent's {opener} is at the end of $outstr.
    #
    # Intially we are called with a fake parent ($top) containing
    # no {opener} and the top-most item as its only child, with $level==0;
    # this puts the top item at the left margin.
    #
    # If all children individually fit then run them all together,
    # wrapping only between siblings; otherwise start each sibling on
    # it's own line so they line up vertically.
    # [4/25/2023: Now controlled by _WRAP_STYLE]

    my $available = $maxlinelen - $linelen;
    my $indent_width = $level * $indent_unit;

    my $run_together =
      (_WRAP_STYLE & _WRAP_ALWAYS)==0
      &&
      all{ (ref() ? $_->{tlen} : length) <= $available } @{$parent->{children}}
      ;

    if (!$run_together
        && @{$parent->{children}}==3
        && !ref(my $item=$parent->{children}->[1])) {
      # Concatenate (key,=>) if possible
      if ($item =~ /\A *=> *\z/) {
        $run_together = 1;
        btw "#     (level $level): Running together $parent->{children}->[0] => value" if $debug;
      }
    }

    my $indent = ' ' x $indent_width;

    btw "###expand",_mycallloc(), "level $level, avail=$available",
        " rt=",_tf($run_together),
        " indw=$indent_width ll=$linelen maxll=$maxlinelen : ",
        #"{ tlen=",$parent->{tlen}," }",
        " p=",_dbvisnew($parent)->Sortkeys(sub{[grep{exists $_[0]->{$_}} qw/O C tlen CLOSE_AFTER_NEXT/]})->Dump(),
        "\n  os=",_dbstr($outstr) if $debug;

    #oops(_dbavis($linelen,$indent_width)) unless $linelen >= $indent_width;

    my $first = 1;
    for my $child (@{$parent->{children}}) {
      my $child_len = ref($child) ? $child->{tlen} : length($child);
      my $fits = ($child_len <= $available) || 0;

      if ($first) {
      } else {
        if(!$fits && !ref($child)) {
          if ($child =~ /( +)\z/ && ($child_len-length($1)) <= $available) {
            # remove trailing space(s) e.g. in ' => '
            substr($child,-length($1),INT_MAX,"");
            $child_len -= length($1);
            oops unless $child_len <= $available;
            $fits = 2;
            btw "#     (level $level): Chopped ",_dbstr($1)," from child" if $debug;
          }
          if (!$fits && $linelen <= $indent_width && $run_together) {
            # If we wrap we'll end up at the same or worse position after
            # indenting, so don't bother wrapping if running together
            $fits = 3;
            btw "#     (level $level): Wrap would not help" if $debug
          }
        }
        if (!$fits || !$run_together) {
          # start a second+ line
          $outstr =~ s/ +\z//;
          $outstr .= "\n$indent";
          $linelen = $indent_width;
          $maxlinelen = $maxlineNlen;

          # elide any initial spaces after wrapping, e.g. in " => "
          $child =~ s/^ +// unless ref($child);

          $available = $maxlinelen - $linelen;
          $child_len = ref($child) ? $child->{tlen} : length($child);
          $fits = ($child_len <= $available);
          btw "#     (level $level): 2nd+ Pre-WRAP; ",_dbstr($child)," cl=$child_len av=$available ll=$linelen f=$fits rt=",_tf($run_together)," os=",_dbstr($outstr) if $debug;
        } else {
          btw "#     (level $level): (no 2nd+ pre-wrap); ",_dbstr($child)," cl=$child_len av=$available ll=$linelen f=$fits rt=",_tf($run_together) if $debug;
        }
      }

      if (ref($child)) {
        ++$level;
        $outstr .= $child->{O};
        $linelen += length($child->{O});
        if (! $fits && $child->{O} ne "") {
          # Wrap before first child, if there is a real opener (not for '=>')
          $outstr =~ s/ +\z//;
          $outstr .= "\n$indent" . (' ' x $indent_unit);
          $linelen = $indent_width + $indent_unit;
          $maxlinelen = $maxlineNlen;
          btw "#     (l $level): Wrap after opener: os=",_dbstr($outstr) if $debug;
        }
        __SUB__->($child);
        if (! $fits && $child->{O} ne "") {
          # Wrap before closer if we wrapped after opener
          $outstr =~ s/ +\z//;
          $outstr .= "\n$indent";
          $linelen = $indent_width;
          $maxlinelen = $maxlineNlen;
          btw "#     (l $level): Wrap after closer; ll=$linelen os=",_dbstr($outstr) if $debug;
        }
        $outstr .= $child->{C};
        $linelen += length($child->{C});
        --$level;
      } else {
        $outstr .= $child;
        $linelen += length($child);
        btw "#     (level $level): appended SCALAR ",_dbstr($child)," os=",_dbstr($outstr) if $debug;
      }
      $available = $maxlinelen - $linelen;
      $first = 0;
    }
  }#expand_children

  # Remove the [array wrapper] used to prepend a string to the
  # representation of a ref, e.g. as created by _prefix_refaddr().
  #
  # The original $ref was replaced by
  #
  #    [ _MAGIC_REFPFX."prefix", $ref, _MAGIC_ELIDE_NEXT ];
  #
  # Whieh Data::Dumper formatted as
  #
  #    ["_MAGIC_REFPFXprefix", <representation of $ref> "_MAGIC_ELIDE_NEXT"]
  #
  # and we want to end up with
  #
  #    prefix<representation of $ref>      e.g. <984:ef8>[42,77]
  #
  s/\[\s*(["'])\Q${\_MAGIC_REFPFX}\E(.*?)\1,\s*/$2/gs;
  s/,\s*(["'])\Q${\_MAGIC_ELIDE_NEXT}\E\1,?\s*\]//gs
    && $debug && btw "Unwrapped REFPFX ",_dbvis($_);

  while ((pos()//0) < length) {
       if (/\G[\\\*\!]/gc)                       { atom($&, "prepend_to_next") }
    elsif (/\G[,;]/gc)                           { atom($&, "append_to_prev") }
    elsif (/\G"(?:[^"\\]++|\\.)*+"/gsc)          { atom($&) } # "quoted"
    elsif (/\G'(?:[^'\\]++|\\.)*+'/gsc)          { atom($&) } # 'quoted'
    elsif (m(\Gqr/(?:[^\\\/]++|\\.)*+/[a-z]*)gsc){  # Regexp
      local $_ = $&;
      # Data::Dumper just stringifies a compiled regex, and Perl (v5.34)
      # does not stringify actual tab as \t etc. probably because the result
      # would be ambiguous if preceeded by another backslash, e.g.
      #  \<tab> -> \\t would be wrong (backslash character + 't').
      #
      # If 'controlpics' is enabled, they are always substituted and then
      # a preceding backslash is not a problem; otherwise \-escapes are
      # substituted only if not preceded by another backslash.
      if ($controlpics) {
        s{([\x{0}\a\b\e\f\n\r\t])}{ $char2controlpic{$1} // $1 }esg;
      } else {
        if (/[\x{0}\a\b\e\f\n\r\t]/) {
          s/(?<!\\)\x{0}/\\0/g;
          s/(?<!\\)[\b]/\N{SYMBOL FOR BACKSPACE}/; # Bare \b matches boundaries
          s/(?<!\\)\e/\\e/g;
          s/(?<!\\)\f/\\f/g;
          s/(?<!\\)\x{0A}/\\n/g;
          s/(?<!\\)\x{0D}/\\r/g;
          s/(?<!\\)\t/\\t/g;
        }
      }
      atom($_)
    }
    elsif (/\G${addrvis_re}/gsc)                 { atom($&, "prepend_to_next") }

    # With Deparse(1) the body has arbitrary Perl code, which we can't parse
    elsif (/\Gsub\s*(?:${parens_re}\s*)?${curlies_re}/gc) { atom($&) } # sub{...}

    # $VAR1->[ix] $VAR1->{key} or just $varname
    elsif (/\G(?:my\s+)?\$(?:${userident_re}|\s*->\s*|${balanced_re}+)++/gsc) { atom($&) }

    elsif (/\G\b[A-Za-z_][A-Za-z0-9_]*+\b/gc)    { atom($&) } # bareword?
    elsif (/\G-?\d[\deE\.]*+\b/gc)               { atom($&) } # number
    elsif (/\G\s*=>\s*/gc)                       { fat_arrow($&) }
    elsif (/\G\s*=(?=[\w\s'"])\s*/gc)            { atom($&) }
    elsif (/\G:*${pkgname_re}/gc)                { atom($&) }
    elsif (/\G[\[\{\(]/gc)                       { atom($&, "open") }
    elsif (/\G[\]\}\)]/gc)                       { atom($&, "close") }
    elsif (/\G\s+/sgc)                           {          }
    else {
      my $remnant = substr($_,pos//0);
      Carp::cluck "UNPARSED at ${\_dbstrposn($_,pos()//0)}\n",
                  "   (Using remainder as-is)\n",
                  "FULL STRING: ${\_dbstr($_)}\n",
                  "original: ${\_dbstr($original)}\n" ;
      atom($remnant);
      while (defined $context->{parent}) { atom("", "close"); }
      last;
    }
  }
  oops "Dangling prepend ",_dbstr($prepending) if $prepending;

  btw "--------top-------\n",_dbvisnew($top)->Sortkeys(sub{[qw/O C tlen children/]})->Dump,"\n-----------------" if $debug;

  $outstr = "";
  $linelen = 0;
  $level = 0;
  expand_children($top);

  if (index($listform,'a') >= 0) {
    # show [...] as (val1,val2,...) array initializer
    # Remove any initial Addrvis prefix
    $outstr =~ s/\A(?:${addrvis_re})?\[/(/ && $outstr =~ s/\]\z/)/s or oops _dbvis($outstr);
  }
  elsif (index($listform,'h') >= 0) {
    # show {...} as (key => val, ...) hash initializer
    $outstr =~ s/\A(?:${addrvis_re})?\{/(/ && $outstr =~ s/\}\z/)/s or oops;
  }
  elsif (index($listform,'l') >= 0) {
    # show as a bare list without brackets; the brackets might be on own lines.
    $outstr =~ s/\A(?:${addrvis_re})?\[\s*(.*?)\s*\]\z/$1/s
    or
    $outstr =~ s/\A(?:${addrvis_re})?\{\s*(.*?)\s*\}\z/$1/s
    or
    $outstr =~ s/\A(?:${addrvis_re})?\(\s*(.*?)\s*\)\z/$1/s # from 'a' conversion above
    or
    $outstr =~ s/\A${quoted_re}\z/substr($&,1,length($&)-2)/es # a single string without "quote marks"
    ;
  }

  # Insert user-specified padding after each embedded newline
  if ($pad) {
    $outstr =~ s/\n\K(?=[^\n])/$pad/g;
  }

  $outstr
} #_postprocess_DD_result {

sub _Interpolate {
  my ($self, $input, $i_or_d) = @_;
  _croak_or_confess $i_or_d."vis('$input') called in void context.\nDid you forget to 'say ...'?"
    unless defined wantarray;

  return "<undef arg>" if ! defined $input;

  &_SaveAndResetPunct;

  my $debug = $self->Debug;
  my $useqq = $self->Useqq;

  my $q = $useqq ? "" : "q";
  my $funcname = $i_or_d . "vis" .$q;

  my @pieces;  # list of [visfuncname or 'p' or 'e', inputstring]
  { local $_ = $input;
    if (/\b((?:ARRAY|HASH|SCALAR)\(0x[a-fA-F0-9]+\))/) {
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
          push @pieces, ['P', (/^\$(?!_)(${userident_re})\z/ ? $1 : $_)."="];
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
        else { oops }
      }
      else {
        if (/^.+?(?<!\\)([\$\@\%])/) {
          confess __PACKAGE__." bug: Missed '$1' in ${LQ}$_${RQ}"
        }
        # Due to the need to simplify the big regexp above, \x{abcd} is now
        # split into "\x" and "{abcd}".  Combine consecutive pass-thrus
        # into a single passthru ('p'), converted later to 'e' if an eval
        # is needed.
        if (@pieces && $pieces[-1]->[0] eq 'p') {
          $pieces[-1]->[1] .= $_;
        } else {
          push @pieces, [ 'p', $_ ];
        }
      }
    }
    if (!defined(pos) || pos() < length($_)) {
      my $leftover = substr($_,pos()//0);
      my $e;
      # Try to recognize user syntax errors
      if ($leftover =~ /^[\$\@\%][\s\%\@]/) {
        $e = "Invalid expression syntax starting at '$leftover' in $funcname arg"
      } else {
        # Otherwise we may have a parser bug
        $e = "Invalid expression (or ".__PACKAGE__." bug):\n${LQ}$leftover${RQ}";
      }
      carp "$e\n";
      push @pieces, ['p',"<INVALID EXPRESSION>".$leftover];
    }
    foreach (@pieces) {
      my ($meth, $str) = @$_;
      # If the user uses 'single quoted' strings then backslash escapes
      # can not be emulated exactly as they would work in double-quoted strings
      # because \ is inconsistently passed through, namely only when not
      # followed by another backslash (or a quote character).
      #   say ivis '\015';   # octal escape for CR intended?
      #   say ivis '\\015';  # four literal characters \015 intended?
      # We can not tell the difference because we get \015 in both cases.
      #
      # Currently we interpolate all \-escapes we see, so to get a literal
      # backslash users must double them, e.g.
      #   say ivis 'The four char escape sequence \\\\015 produces \015';
      # Here-docs do not treat \ specially and so avoid this problem:
      #   say ivis <<\END;
      #   The four char escape sequence \\015 produces \015
      #   END
      #
      # 0/18/23: Now really *all* \-escapes are interpolated, so this works:
      #   say ivis '\$foo = $foo'   # $foo = <value>

      #next unless $meth eq 'p' && $str =~ /\\[abtnfrexXN0-7]/;
      #$str =~ s/([()\$\@\%])/\\$1/g;  # dont hide \-escapes to be interpolated!

      if ($meth eq 'p') {
        if ($str =~ /\\./) {
          $str =~ s/\$\\/\$\\\\/g;   # Assume the punct var $\ is not intended
          $str =~ s/([()])/\\$1/g;
          $_->[1] = "qq(" . $str . ")";
          $_->[0] = 'e';
        }
      }
      elsif ($meth eq 'P') {
          $_->[0] = 'p';
      }
    }
  } #local $_

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
  my $result = "";
  foreach my $p (@$pieces) {
    my ($methname, $arg) = @$p;
#say "III methname=$methname arg='$arg'";
    if ($methname eq 'p') {
      $result .= $arg;
    }
    elsif ($methname eq 'e') {
      $result .= DB::DB_Vis_Eval($funcname, $arg);
    } else {
      # Reduce width before first wrap to account for stuff already on the line
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
# dvis() and friends using "goto &_Interpolate", which in turn
# does "goto &DB::DB_Vis_Interpolate" to enter package DB.
sub DB_Vis_Eval($$) {
  my ($label_for_errmsg, $evalarg) = @_;
  Carp::confess("Data::Dumper::Interp bug:empty evalarg") if $evalarg eq "";
  # Inspired perl5db.pl but at this point has been rewritten

  # Find the closest non-DB caller.  The eval will be done in that package.
  #
  # We want @_ to refer to the arguments to *that* caller, not to e.g. dvis;
  # find the next caller further up which has arguments (i.e. wasn't doing
  # "&subname;"), and make @_ contain those arguments.
  my ($distance, $pkg, $fname, $lno);
  for ($distance = 0 ; ; $distance++) {
    ($pkg, $fname, $lno) = caller($distance);
    last if $pkg ne "DB";
  }
  local @_; # = ("*DDI:Should not see*");
  while() {
    $distance++;
    my ($p, $hasargs) = (caller($distance))[0,4];
    if (! defined $p){
      @_ = ( '<@_ is not defined in the outer block>' );
      last
    }
    if ($hasargs) {
      #WAS: @_ = @{ [ @DB::args ] };  # copy in case of recursion
      #4/26/24: This sometimes gets "panic: attempt to copy freed scalar"
      #
      # N.B. We can not copy args using +0 or ."" because then objects
      # will numify/stringify and we can't display their internals.
      #
      # I tried cloning DB::args with Clone::clone but still got SEGV somewhere
      # or "Attempt to free unreferenced scalar".
      #
      # Trying code lifted from Carp.pm :
      @_ = map {
                my $arg;
                local $@= $@;
                eval {
                    $arg = $_;
                    1;
                } or do {
                    $arg = '** argument not available anymore **';
                };
                $arg;
            } @DB::args;
      last
    }
  }

  local @Data::Dumper::Interp::result;
  local $Data::Dumper::Interp::string_to_eval =
    "package $pkg; "
     # N.B. eval first clears $@ so we must restore $@ inside the eval
   .' &Data::Dumper::Interp::_RestorePunct_NoPop();'  # saved in _Interpolate
     # In case something carps or croaks (e.g. because of ${\(somefunc())}
     # or a tie handler), force a full backtrace so the user's call location
     # is visible.  Unfortunately there is no way to make carp() show only
     # the location of the user's call because we must force the eval'd
     # string into in e.g. package main so user functions can be found.
   .' local $Carp::Verbose = 1;'
   .' @Data::Dumper::Interp::result = '.$evalarg.';'
   .' $Data::Dumper::Interp::save_stack[-1]->[0] = $@;' # possibly changed by a tie handler
   ;
  &DB_Vis_Evalwrapper;
  my $errmsg = $@;
  my @result = @Data::Dumper::Interp::result;

  if ($errmsg) {
    $errmsg = Data::Dumper::Interp::_chop_ateval($errmsg);
    Carp::carp("${label_for_errmsg} interpolation error: $errmsg\n");
    @result = ( (defined($result[0]) ? $result[0] : "")."<invalid/error>"
                , "" # second item in case this ends up in %{ ... }
              );
  }

  wantarray ? @result : (do{Carp::confess("bug",Data::Dumper::Interp::_dbavis(@result)) if @result>1}, $result[0])
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
  my $href = \%hash;
  my $coderef = \&mysub;
  my $obj = bless {}, "Foo::Bar";

  # Interpolate variables in strings with Data::Dumper output
  say ivis 'FYI ref is $href\nThat hash is: %hash\nArgs are @ARGV';

    # -->FYI ref is {abc => [1,2,3,4,5], def => undef}
    #    That hash is: (abc => [1,2,3,4,5], def => undef)
    #    Args are ("-i","/file/path")

  # Label interpolated values with "expr="
  say dvis '$coderef  $href\nand @ARGV';

    #-->coderef=\&main::mysub  href={abc => [1,2,3,4,5], def => undef}
    #   and @ARGV=("-i","/file/path")

  # Functions to format one thing
  say vis $href;     # {abc => [1,2,3,4,5], def => undef}
  say vis \@ARGV;    # ["-i", "/file/path"]  # any scalar
  say avis @ARGV;    # ("-i", "/file/path")
  say hvis %hash;    # (abc => [1,2,3,4,5], def => undef)

  # Format a reference with abbreviated referent address
  say visr $href;     # HASH<457:1c9>{abc => [1,2,3,4,5], ...}

  # Just abbreviate a referent address or arbitrary number
  say addrvis refaddr($href);  # 457:1c9
  say addrvis $href;           # HASH<457:1c9>
  say addrvis $obj;            # Foo::Bar<984:ef8>

  # Stringify objects
  { use bigint;
    my $struct = { debt => 999_999_999_999_999_999.02 };
    say vis $struct;
      # --> {debt => (Math::BigFloat)999999999999999999.02}

    # But if you do want to see object internals...
    #
    say visnew->viso($struct);
      # --> {debt => bless({...lots of stuff...},'Math::BigInt')}

    # These do the same thing
    say visnew->Objects(0)->vis($struct);
    { local $Data::Dumper::Interp::Objects=0; say vis $struct; }
    say viso $struct;   # 'viso' is not exported by default
  }

  # Wide characters are readable
  use utf8;
  my $h = {msg => "My language is not ASCII ☻ ☺ 😊 \N{U+2757}!"};
  say dvis '$h' ;
    # --> h={msg => "My language is not ASCII ☻ ☺ 😊 ❗!"}

  #-------- OO API --------

  say visnew->MaxStringwidth(50)->Maxdepth($levels)->vis($datum);

  say Data::Dumper::Interp->new()
            ->MaxStringwidth(50)->Maxdepth($levels)->vis($datum);

  #-------- UTILITY FUNCTIONS --------
  say u($might_be_undef);  # $_[0] // "undef"
  say quotekey($string);   # quote if not a valid bareword
  say qsh($string);        # quote if needed for /bin/sh
  say qshpath($pathname);  # shell quote excepting ~ prefix
  say "Runing this: ", qshlist(@command_and_args);

  system "ls -ld ".join(" ",map{ qshpath }
                            ("/tmp", "~sally/My Documents", "~"));


=head1 DESCRIPTION

This Data::Dumper wrapper optimizes output for human consumption
and avoids side-effects which interfere with debugging.

The namesake feature is interpolating Data::Dumper output
into strings.  Simple functions are also provided
to format a scalar, array, or hash.

Internally, Data::Dumper is called to visualize (i.e. format) data
with pre- and post-processing to "improve" the results:

=over 2

=item * One line if possible, else folded to terminal width, WITHOUT newline.

=item * Safely printable Unicode characters appear as themselves.

=item * Code refs show the name of the referenced sub.

=item * Objects like Math:BigInt etc. are stringified (by default).

=item * "Virtual" values behind overloaded deref operators are shown.

=item * Data::Dumper bugs^H^H^H^Hquirks are circumvented.

=back

See "DIFFERENCES FROM Data::Dumper".

Utilities are also provided to quote strings for /bin/sh.

=head1 FUNCTIONS

=head2 ivis I<'string to be interpolated'>

Returns the argument with variable references and escapes interpolated
as in in Perl double-quotish strings, but using Data::Dumper to
format variable values.

C<$var> is replaced by its value,
C<@var> is replaced by "(comma, sparated, list)",
and C<%hash> by "(key => value, ...)" .
Complex expressions with indexing, dereferences, slices
and method calls are also recognized.

Expressions are evaluated in the caller's context using Perl's debugger
hooks, and may refer to almost any lexical or global visible at
the point of call (see "LIMITATIONS").

IMPORTANT: The argument must be single-quoted to prevent Perl
from interpolating it beforehand.

=head2 dvis I<'string to be interpolated'>

The 'd' is for "B<d>ebugging".  Like C<ivis> but labels expansions
with "expr=" and shows spaces visibly as '·'.  Other debug-oriented
formatting may also occur (TBD).

=head2 vis [I<SCALAREXPR>B<]>

=head2 avis I<LIST>

=head2 hvis I<EVENLIST>

C<vis> formats a single scalar ($_ if no argument is given)
and returns the resulting string.

C<avis> formats an array (or any list) as comma-separated values in parenthesis.

C<hvis> formats key => value pairs in parenthesis.

=head2 FUNCTION (and METHOD) VARIATIONS

Variations of the above five functions have extra characters
in their names to imply certain options.
For example C<visq> is like C<vis> but
shows strings in single-quoted form (implied by the 'B<q>' suffix).

There are no fixed function names; you can use any combination of
characters in any order, prefixed or suffixed to the primary name
with optional '_' separators.
The function will be I<generated> when it is imported* or called as a method.

The available modifier characters are:

=over 2

B<l> - omit parenthesis to return a bare list with "avis" or "hvis"; omit quotes from a string formatted by "vis".

B<o> - show object internals (see C<Objects>);


B<r> - show abbreviated addresses in refs (see C<Refaddr>).

B<< <NUMBER> >> - limit structure depth to <NUMBER> levels (see C<Maxdepth>).

See C<Useqq> for more info about these:

B<c> - Show control characters as "Control Picture" characters

B<C> - condense strings of repeated characters

B<d> - ("debug-friendly") Condense strings; show spaces as middle-dot if STDOUT is utf-encoding

B<h> - show numbers > 9 in hexadecimal

B<O> - Optimize for strings containing binary octets.

B<q> - show strings 'single quoted' if possible

=over

With B<q> Data::Dumper is called with C<Useqq(0)>, but depending
on the version of Data::Dumper the result may be "double quoted"
anyway if wide characters are present.

=back

B<u> - show numbers with underscores between groups of three digits

=back

Functions must be imported explicitly
unless they are imported by default (see list below).

=for HIDE or created via the :all tag.

To avoid having to import functions in advance, you can
use them as methods and import only the C<visnew> function:

  use Spreadsheet::Edit::Interp qw/visnew/;
  ...
  say visnew->vis($struct);
  say visnew->visrq($my_object);
  say visnew->avis(@ARGV);
  say visnew->avis2lrq(@ARGV);
  etc.

(C<visnew> creates a new object.  Non-existent methods are auto-generated
via the AUTOLOAD mechanism).

=head2 Functions imported by default

 ivis  dvis    vis  avis  hvis
 ivisq dvisq   visq avisq hvisq rvis rvisq

 visnew
 addrvis addrvisl
 u quotekey qsh qshlist qshpath

=for HIDE =head2 The :all import tag
=for HIDE Z<> Z<>
=for HIDE
=for HIDE   use Data::Dumper::Interp qw/:all/;
=for HIDE
=for HIDE This generates and imports methods uing all possible combinations of
=for HIDE I<< <NUMBER> >>,C<l>,C<o>,C<q>, and C<r>,
=for HIDE in alphabetical order, with NUMBER <= 2.
=for HIDE There are 119 variations, too many to remember.
=for HIDE
=for HIDE You only need to know the basic names
=for HIDE
=for HIDE   ivis, dvis, vis, avis, and hvis
=for HIDE
=for HIDE and the possible suffixes and their
=for HIDE order (I<< <NUMBER> >>,C<l>,C<o>,C<q>,C<r>).
=for HIDE
=for HIDE For example, one function is C<< B<avis2lq> >>, which
=for HIDE
=for HIDE  * Formats multiple arguments as an array ('avis')
=for HIDE  * Decends at most 2 levels into structures ('2')
=for HIDE  * Returns a comma-separated list *without* parenthesis ('l')
=for HIDE  * Shows strings in single-quoted form ('q')
=for HIDE
=for HIDE You could have used alternate names for the same function such as C<avis2ql>,
=for HIDE C<q2avisl>, C<q_2_avis_l> etc. if called as methods or explicitly imported.

* To save memory, only stub declarations with prototypes are generated
for imported functions.
Bodies are generated when actually used via the AUTOLOAD mechanism.
The C<:debug> import tag prints messages chronicling this process.

=head1 Showing Abbreviated Addresses

=head2 addrvis I<REF_or_NUMBER>

Returns a string showing an address or number in both decimal and
hexadecimal, abbreviated to only the last few digits.

The number of digits starts at 3 and increases over time if necessary
to keep new results unambiguous.

For REFs, the result is like I<< "HASHE<lt>457:1c9E<gt>" >>
or I<< "Package::NameE<lt>457:1c9E<gt>" >>.

If the argument is a plain number, just the abbreviated value
is returned, e.g. I<< "E<lt>457:1c9E<gt>" >>.

I<"undef"> is returned if the argument is undefined.
Croaks if the argument is defined but not a number or reference.

If a ref refers to a shared variable (see L<threads::shared>)
then the internal ID is used and a distinguishing mark is included.

C<addrvis_digits(NUMBER)> forces a minimum width
and C<addrvis_forget()> discards past values and resets to 3 digits.

=head2 addrvisl I<REF_or_NUMBER>

Like C<addrvis> but omits the <angle brackets>.

=head1 OBJECT-ORIENTED API

=head2 Data::Dumper::Interp->new()

=head2 visnew()

These synonyms create an object initialized from the global configuration
variables listed below.  No arguments are permitted.

B<All the functions described above> and any variations
may be called as I<methods> on an object
(when not called as a method the functions create a new object internally).

For example:

   $msg = visnew->Foldwidth(40)->avis(@ARGV);

returns the same string as

   local $Data::Dumper::Interp::Foldwidth = 40;
   $msg = avis @ARGV;

"Variations" can be called similarly, for example

   $msg = visnew->Foldwidth(40)->vis_r2($x); # show addresses; Maxdepth 2

=head1 Configuration Methods & Variables

These work the same way as variables/methods in Data::Dumper.

Each config method has a corresponding global variable
in package C<Data::Dumper::Interp> which provides the default value.

When a config method is called without arguments the current value is returned,
and when called with an argument the value is changed and
the object is returned so that calls can be chained.

=head2 MaxStringwidth(I<INTEGER>)

=head2 Truncsuffix(I<"...">)

=head2 Trunctailwidth(I<INTEGER>)

Longer strings are truncated and I<Truncsuffix> appended.
MaxStringwidth=0 (the default) means no length limit.

If I<Trunctailwidth> is set, characters are deleted from the middle, leaving
that many characters from the end of the string.

=head2 Foldwidth(I<INTEGER>)

Defaults to the terminal width at the time of first use.

=head2 Objects(I<FALSE>);

=head2 Objects(I<1>);

=head2 Objects(I<"classname">)

=head2 Objects(I<[ list of classnames ]>)

A I<false> value disables special handling of objects
(that is, blessed things) and internals are shown as with Data::Dumper.

A "1" (the default) enables for all objects,
otherwise only for the specified class name(s) or derived classes.

When enabled, object internals are never shown.
The class and abbreviated address are shown as with C<addrvis>
e.g. "Foo::Bar<392:0f0>", unless the object overloads
the stringification ('""') operator,
or array-, hash-, scalar-, or glob- deref operators;
in that case the first overloaded operator found will be evaluated,
the object replaced by the result, and the check repeated.

By default, "(classname)" is prepended to the result of an overloaded operator
to make clear what happened.

=head2 Objects(I<< {objects => VALUE, overloads => OVOPT} >>)

This form, passing a hashref,
allows passing additional options for blessed objects:

=over

B<overloads =E<gt> "tagged"> (the default): "(classname)" is prepended to the result when an overloaded operator is evaluated.

B<overloads =E<gt> "transparent"> : The overload results
will appear unadorned, i.e. they will look as if the overload result
was the original value.

B<overloads =E<gt> "ignore"> : Overloaded operators are not evaluated at all;
the original object's abbreviated refaddr is shown
(if you want to see object internals, disable I<Objects> entirely.)

Deprecated: B<show_classname =E<gt> False> : Please use S<< B<overloads =E<gt> "transparent"> instead. >>

=back

The I<objects> value indicates whether and for which classes special
object handling is enabled (false, "1", "classname" or [list of classnames]).

=head2 Refaddr(I<BOOL>)

If true, references are identified as with C<addrvis>.

=head2 Sortkeys(I<SUBREF>)

The default sorts numeric substrings in keys by numerical
value, e.g. "A.20" sorts before "A.100".  See C<Data::Dumper> documentation.

=head2 Useqq(I<argument>)

0 means generate 'single quoted' strings when possible.

1 means generate "double quoted" strings as-is from Data::Dumper.
Non-ASCII charcters will likely appeqar as hex or octal escapes.

Otherwise generate "double quoted" strings enhanced according to option
keywords given as a :-separated list, e.g. Useqq("unicode:controlpics").
The avilable options are:

=over 4

=item "unicode"

Printable ("graphic")
characters are shown as themselves rather than hex escapes, and
'\n', '\t', etc. are shown for ASCII control codes.

=item "controlpics"

Show ASCII control characters using single "control picture" characters:
'␤' is shown for newline instead of '\n', and
similarly ␀ ␇ ␈ ␛ ␌ ␍ ␉ for \0 \a \b \e \f \r \t.

Every character occupies the same space with a fixed-width font, but
the tiny "control picures" can be hard to read;
to see traditional \n etc.  while still seeing wide characters as themselves,
set C<Useqq> to just "unicode";

=item "octets"

Optimize for viewing binary strings (i.e. strings of octets, not "wide"
characters).  Octal escapes are shown instead of \n, \r, etc.

=item "showspaces"

Make space characters visible (as '␣').

(An older "spacedots" option used Middle Dot for this purpose)

=item "condense"

Repeated characters in strings are shown as "⸨I<char>xI<repcount>⸩".
For example

  vec(my $s, 31, 1) = 1;
  my $str = unpack "b*", $s;
  say $str;
    -->00000000000000000000000000000001
  say visnew->Useqq("unicode:condense")->visl($str);
    -->⸨0×31⸩1

=item "underscores"

Show numbers with '_' seprating groups of 3 digits.

=item "style=OPENQUOTE,CLOSEQUOTE"

Use the given symbols instead of double quotes.  The symbols may
contain multiple characters. Escape , or : with backslash(E<92>).

=item "qq=XY"

(Deprecated) Equivalent to "style=qqX,Y"

=item "qq"

(Deprecated) Equivalent to "style=qq{,}"

=back

The default is C<Useqq('unicode')> except for C<dvis> which also
enables 'condense' and possibly 'showspaces'.
Functions/methods with 'q' in their name force C<Useqq(0)>;

=head2 Quotekeys

=head2 Maxdepth

=head2 Maxrecurse

=head2 Deparse

=head2 Deepcopy

See C<Data::Dumper> documentation.

=head1 B<set_defaults> Method

As an alternative to directly setting the global variables listed above,
the corresponding I<methods> can be called on an object
and finally the C<set_defaults> method, which stores whatever settings are in the
object back into the global variables.  For example

  visnew->MaxStringwidth(50)->Refaddr(1)->set_defaults();

would set the C<$Data::Dumper::Interp::MaxStringwidth>
and <$Data::Dumper::Interp::Refaddr>
variables, without risk of uncaught spelling errors.

=head2 B<reset_defaults>

The C<reset_defaults> method sets all Configuration variables to original default values.

=head1

=head1 UTILITY FUNCTIONS

=head2 u

=head2 u I<SCALAR>

Returns the argument ($_ by default) if it is defined, otherwise
the string "undef".

=head2 quotekey

=head2 quotekey I<SCALAR>

Returns the argument ($_ by default) if it is a valid bareword,
otherwise a "quoted string".

=head2 qsh

=head2 qsh I<$string>

The string ($_ by default) is quoted if necessary for parsing
by the shell (/bin/sh), which has different quoting rules than Perl.
On Win32 quoting is for cmd.com.

If the string contains only "shell-safe" ASCII characters
it is returned as-is, without quotes.

If the argument is a ref but is not an object which stringifies,
then vis() is called and the resulting string quoted.
An undefined value is shown as C<undef> without quotes;
as a special case to avoid ambiguity the string 'undef' is always "quoted".

=head2 qshpath I<$might_have_tilde_prefix>

Like C<qsh> except that an initial ~ or ~username is left
unquoted.  Useful with bash or csh.

=head2 qshlist I<@items>

Format e.g. a shell command and arguments, quoting when necessary.

Returns a single string with items separated by spaces.

=head1 LIMITATIONS

=over 2

=item Interpolated Strings

C<ivis> and C<dvis> evaluate expressions in the user's context
using Perl's debugger support ('eval' in package DB -- see I<perlfunc>).
This mechanism has some limitations:

@_ may show incorrect values except immediately after sub entry.
For example after "shift" @_ will appear to still have the original arguments.

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
using its "Purity" feature.
Data::Dumper::Interp simply passes through these annotations.

However with I<Refaddr(true)>, multiple references to the same thing
will all show the address of the referenced thing.

=item threads::shared support

When the address of a shared variable is shown
(e.d. when the B<Refaddr> option is enabled or if calling B<addrvis()>),
the variable's I<globally unique ID> shown instead of the C<refaddr>.

(The C<refaddr> of a shared variable is misleading it refers
to a thread-local intermediary and may be different in
each thread even though the same shared object is being referenced).

Relatedly, the C<$VAR> references in default Data::Dumper output are
generally incorrect when shared variables are involved because Data::Dumper
uses only C<refaddr> values to identify refs to the same item.
Enabling I<Refaddr(true)> will show linkage correctly, albiet in a different way.

=item The special "_" stat filehandle may not be preserved

Data::Dumper::Interp queries the operating
system for the window size to initialize C<$Foldwidth>, if it
is not already defined; this may change the "_" filehandle.
After the first call (or if you pre-set C<$Foldwidth>),
the "_" filehandle will not change across calls.

=back

=head1 DIFFERENCES FROM Data::Dumper

Results differ from plain C<Data::Dumper> output in the following ways
(most of these can be controlled via Config options):

=over 2

=item *

Punctuation variables such as $@, $!, and $?, are preserved over calls.

=item *

A final newline is I<never> included.

Everything is shown on a single line if possible, otherwise wrapped to
your terminal width (or C<$Foldwidth>), with indented structure levels.

=item *

Printable Unicode characters appear as themselves instead of \x{ABCD}.

Note: If your data contains 'wide characters', you should
C<< use open IO => ':locale'; >> or otherwise arrange to
encode the output for your terminal.
You'll also want C<< use utf8; >> if your Perl source
contains characters outside the ASCII range.

Undecoded binary octets (e.g. data read from a 'binmode' file)
will still be escaped as individual bytes.

=item *

Depending on options, spaces·may·be·shown·visibly
and '␤' may be shown for newline (and similarly for other ASCII controls).

"White space" characters in qr/compiled regex/ are shown as \t, \n etc.

=item *

Unless B<Deparse> is enabled,
CODE refs show the name of the referenced sub using L<Sub::Identify>
instead of C<sub{ "DUMMY" }>.  If the sub is anonymous, the file:lineno
where it was defined is shown.

=item *

The internals of objects are not shown by default.

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

Numbers and strings which look like numbers are kept distinct when displayed,
i.e. "0" does not become 0 or vice-versa. Floating-point values are shown
as numbers not 'quoted strings' and similarly for stringified objects.

Although such differences might be immaterial to Perl during execution,
they may be important when communicating to a human.

=item *

References to shared variables (see L<threads::shared>) are shown correctly
with the C<Refaddr> feature.  Data::Dumper's C<$VAR> expressions are usually
incorrect when shared variables are involved.

=back

=head1 SEE ALSO

Data::Dumper

=head1 AUTHOR

Jim Avera  (jim.avera AT gmail)

=head1 LICENSE

Public Domain or CC0.

=for nobody Foldwidth1 is currently an undocumented experimental method
=for nobody which sets a different fold width for the first line only.
=for nobody The Debug method is for author's debugging, and not documented.
=for nobody
=for nobody oops and btw btwN are internal debugging functions

=for Pod::Coverage Foldwidth1 oops btw btwN Debug

=cut
