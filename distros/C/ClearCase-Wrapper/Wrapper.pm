package ClearCase::Wrapper;

$VERSION = '1.19';

require 5.006;

use AutoLoader 'AUTOLOAD';
use B;
use strict;
use warnings;

use vars qw(%Packages %ExtMap $libdir $prog $dieexit $dieexec $diemexec);

# Inherit some symbols from the main package. We will later "donate"
# these to all overlay packages as well.
BEGIN {
    *prog = \$::prog;
    *dieexit = \$::dieexit;
    *dieexec = \$::dieexec;
    *diemexec = \$::diemexec;
}

# For some reason this can't be handled the same as $prog above ...
use constant MSWIN => $^O =~ /MSWin|Windows_NT/i ? 1 : 0;

# This is the list of functions we want to export to overlay pkgs.
my @exports = qw(MSWIN GetOptions Assert Burrow Msg Pred ViewTag
                AutoCheckedOut AutoNotCheckedOut AutoViewPrivate);

# Hacks for portability with Windows env vars.
BEGIN {
    $ENV{LOGNAME} ||= $ENV{USERNAME};
    $ENV{HOME} ||= "$ENV{HOMEDRIVE}/$ENV{HOMEPATH}";
}

# Unless the user has their own CLEARCASE_PROFILE, set it to the global one.
BEGIN {
    # Learn where this module was found so we can look there for other files.
    ($libdir = $INC{'ClearCase/Wrapper.pm'}) =~ s%\.pm$%%;

    if (defined $ENV{CLEARCASE_PROFILE}) {
      $ENV{_CLEARCASE_WRAPPER_PROFILE} = $ENV{CLEARCASE_PROFILE};
    } elsif ($ENV{_CLEARCASE_WRAPPER_PROFILE}) {
      $ENV{CLEARCASE_PROFILE} = $ENV{_CLEARCASE_WRAPPER_PROFILE};
    } elsif (! -f "$ENV{HOME}/.clearcase_profile") {
      my $rc = join('/', $libdir, 'clearcase_profile');
      $ENV{CLEARCASE_PROFILE} = $rc if -r $rc;
    }
}

# Skip the Getopt::Long->import(), we need our own GetOptions().
require Getopt::Long;

# Getopt::Long::GetOptions() respects '--' but strips it, while
# we want to respect '--' and leave it in. Thus this override.
sub GetOptions {
    @ARGV = map {/^--$/ ? qw(=--= --) : $_} @ARGV;
    my $ret = Getopt::Long::GetOptions(@_);
    @ARGV = map {/^=--=$/ ? qw(--) : $_} @ARGV;
    return $ret;
}

# Technically we should use Getopt::Long::Configure() for these but
# there's a tangled version history and this is faster anyway.
$Getopt::Long::passthrough = 1; # required for wrapper programs
$Getopt::Long::ignorecase = 0;  # global override for dumb default

# Any subroutine declared in a module located via this code
# will eclipse one of the same name declared above.
## NOTE: functions defined in modules found here should not
## be placed directly into ClearCase::Wrapper. They MUST be
## placed in the standard package analogous to their pathname
## (e.g. ClearCase::Wrapper::Foo). Magic occurs here to get
## them into ClearCase::Wrapper where they belong.
sub _FindAndLoadModules {
    my ($dir, $subdir) = @_;
    # Not sure how glob() sorts so force a standard order.
    my @pms = sort glob("$dir/$subdir/*.pm");
    for my $pm (@pms) {
      my $dirQuoted = quotemeta($dir);
      $pm =~ s%^$dirQuoted/(.*)\.pm$%$1%;
      (my $pkg = $pm) =~ s%[/\\]+%::%g;
      eval "*${pkg}::exit = \$dieexit";
      eval "*${pkg}::exec = \$dieexec";

      # In this block we temporarily enter the overlay's package
      # just in case the overlay module forgot its package stmt.
      # We then require the overlay file and also, if it's
      # an autoloaded module (which is recommended), we drag
      # in the index file too. This is because we need to
      # derive a list of all functions defined in the overlay
      # in order to import them to our own namespace.
      {
          eval qq(package $pkg); # default the pkg correctly
          no warnings qw(redefine);
          eval {
            eval "require $pkg";
            warn $@ if $@;
          };
          next if $@;
          my $ix = "auto/$pm/autosplit.ix";
          if (-e "$dir/$ix") {
            eval { require $ix };
            warn $@ if $@;
          }
      }

      # Now the overlay module is read in. We need to examine its
      # newly-created symbol table, determine which functions
      # it defined, and import them here. The same basic thing is
      # done for the base package later.
      no strict 'refs';
      my %names = %{"${pkg}::"};
      for (keys %names) {
          # Skip symbols that can't be names of valid cleartool ops.
          next if m%^(?:_?[A-Z]|__|[ab]$)%;
          my $tglob = "${pkg}::$_";
          my $coderef = \&{$tglob};
          next unless ref $coderef;
          my $cv = B::svref_2object($coderef);
          next unless $cv->isa('B::CV');
          next if $cv->GV->isa('B::SPECIAL');
          my $p = $cv->GV->STASH->NAME;
          next unless $p eq $pkg;

          # Take what survives the above tests and create a hash
          # mapping defined functions to the pkg that defines them.
          $ExtMap{$_} = $pkg;
          # We import the entire typeglob for 'foo' when we
          # find an extension func named foo(). This allows usage
          # msg extensions (in the form $foo) to come over too.
          eval qq(*$_ = *$tglob);
      }

      # The base module defines a few functions which the
      # overlay's code might want to use. Make aliases
      # for those in the overlay's symbol table.
      for (@exports) {
          eval "*${pkg}::$_ = \\&$_";
      }
      eval "*${pkg}::prog = \\\$prog";

      $Packages{$pkg} = $INC{"$pm.pm"};
    }
}
for my $subdir (qw(ClearCase/Wrapper ClearCase/Wrapper/Site)) {
    for my $dir (@INC) {
      _FindAndLoadModules($dir, $subdir);
    }
}

$Packages{'ClearCase::Wrapper'} = __FILE__;

# Piggyback on the -ver flag to show our version too.
if (@ARGV && $ARGV[0] =~ /^-ver/i) {
    my $fmt = "*%-32s %s (%s)\n";
    local $| = 1;
    for (sort keys %Packages) {
      my $ver = eval "\$$_\::VERSION" || '????';
      my $mtime = localtime((stat $Packages{$_})[9]);
      printf $fmt, $_, $ver, $mtime || '----';
    }
    exit 0 if $ARGV[0] =~ /^-verw/i;
}

# Take a string and an array, return the index of the 1st occurrence
# of the string in the array.
sub _FirstIndex {
    my $flag = shift;
    for my $i (0..$#_) {
       return $i if $flag eq $_[$i];
    }
    return undef;
}

# Implements the -me -tag convention (see POD).
if (my $me = _FirstIndex('-me', @ARGV)) {
    if ($ARGV[0] =~ /^(?:set|start|end)view$|^rdl$|^work/) {
      my $delim = 0;
      for (@ARGV) {
          last if /^--$/;
          $delim++;
      }
      for (reverse @ARGV[0..$delim-1]) {
          if (/^\w+$/) {
            $_ = join('_', $ENV{LOGNAME}, $_);
            last;
          }
      }
      splice(@ARGV, $me, 1);
    } elsif (my $tag = _FirstIndex('-tag', @ARGV)) {
      $ARGV[$tag+1] = join('_', $ENV{LOGNAME}, $ARGV[$tag+1]);
      splice(@ARGV, $me, 1);
    }
}

# Implements the -M flag (see POD).
if (my $mflag = _FirstIndex('-M', @ARGV) || $ENV{CLEARCASE_WRAPPER_PAGER}) {
    splice(@ARGV, $mflag, 1) if $mflag && !$ENV{CLEARCASE_WRAPPER_PAGER};
    pipe(READER, WRITER);
    my $pid;
    if ($pid = fork) {
      close WRITER;
      open(STDIN, ">&READER") || die Msg('E', "STDIN: $!");
      my $pager = $ENV{CLEARCASE_WRAPPER_PAGER} || $ENV{PAGER};
      if (!$pager) {
          require Config;
          $pager = $Config::Config{pager} || 'more';
      }
      exec $pager || warn Msg('W', "can't run $pager: $!");
    } else {
      die Msg('E', "can't fork") if !defined($pid);
      close READER;
      open(STDOUT, ">&WRITER") || die Msg('E', "STDOUT: $!");
    }
}

# Implements the -P flag to pause after a GUI operation.
if (my $pflag = _FirstIndex('-P', @ARGV)) {
    splice(@ARGV, $pflag, 1);
    if (MSWIN) {
      eval "END { system qw(cmd /c pause) }";
    } else {
      my $foo = <STDIN>;
    }
}

#############################################################################
# Usage Message Extensions
#############################################################################
{
   no strict 'vars';

   # Extended messages for actual cleartool commands that we extend.
   $checkin      = "\n* [-dir|-rec|-all|-avobs] [-ok] [-diff [diff-opts]]" .
                  "\n* [-revert [-mkhlink]]";
   $checkout      = "\n* [-dir|-rec] [-ok]";
   $diff      = "\n* [-<n>] [-dir|-rec|-all|-avobs]";
   $diffcr      = "\n* [-data]";
   $lsprivate      = "\n* [-dir|-rec|-all] [-ecl/ipsed] [-type d|f]" .
              "\n* [-rel/ative] [-ext] [pname]";
   $lsview      = "\n* [-me]";
   $mkelem      = "\n* [-dir|-rec] [-do] [-ok]";
   $uncheckout      = " * [-nc]";

   # Extended messages for pseudo cleartool commands that we implement here.
   my $z = $ARGV[0] || '';
   $edit      = "$z <co-flags> [-ci] <ci-flags> pname ...";
   $extensions      = "$z [-long]";
}

#############################################################################
# Command Aliases
#############################################################################
*ci            = *checkin;
*co            = *checkout;
*lsp            = *lsprivate;
*lspriv            = *lsprivate;
*unco            = *uncheckout;
*vi            = *edit;

#############################################################################
# Allow per-user configurability. Give the individual access to @ARGV just
# before we hand it off to the local wrapper function and/or cleartool.
# Access to this feature is suppressed if the 'NO_OVERRIDES' file exists.
#############################################################################
if (-r "$ENV{HOME}/.clearcase_profile.pl" && ! -e "$libdir/NO_OVERRIDES") {
    require "$ENV{HOME}/.clearcase_profile.pl";
    no warnings qw(redefine);
    *Argv::exec = $diemexec;
}

# Add to ExtMap the names of extensions defined in the base package.
for (keys %ClearCase::Wrapper::) {
    # Skip functions that can't be names of valid cleartool ops.
    next if m%^(?:_?[A-Z]|__)%;
    # Skip typeglobs that don't involve functions.
    my $tglob = "ClearCase::Wrapper::$_";
    next unless ref \&{$tglob};
    # Take what survives the above tests and create a hash
    # mapping defined functions to the pkg that defines them.
    $ExtMap{$_} ||= __PACKAGE__;
}

# Returns undefined if <op> is not being extended and returns the
# package that extends it otherwise. Potentially useful for extension
# writers.
sub Extension {
    my $op = shift;
    return $ExtMap{$op};
}

# Returns the full name of a command, whether native or not; unchanged in error
sub Canonic {
    my $op = shift;
    my $tglob = $ExtMap{$op} . "::" . $op;
    my $coderef = \&{$tglob};
    return $op unless ref $coderef;
    my $cv = B::svref_2object($coderef);
    return $cv->GV->NAME;
}

# Returns a boolean indicating whether the named cmd is native to
# CC or not. Note: the first call to this func has a "cost" of one
# "cleartool help" operation; subsequent calls are free.
{
    my %native;
    sub Native {
      my $op = shift;
      return 1 if $op =~ m%^lsp(riv)?%;
      if (! $op) {
          ($op = (caller(1))[3]) =~ s%.*:%%;
      }
      if (! keys %native) {
          my @usg = grep /^Usage:/, ClearCase::Argv->help->qx;
          for (@usg) {
            if (/^Usage:\s*(\w+)\s*(\|\s*(\w+))?/) {
                $native{$1} = 1 if $1;
                $native{$3} = 1 if $3;
            }
          }
      }
      if (exists($native{$op})) {
          return 1;
      } elsif ($op =~ m%^(?:des|lsh)%) {
          return 1;
      } else {
          return 0;
      }
    }
}

# This is an enhancement like the ones below but is kept "above the
# fold" because wrapping of cleartool man is an integral and generic
# part of the module. It runs "cleartool man <cmd>" as requested,
# followed by "perldoc ClearCase::Wrapper" iff <cmd> is extended below.
sub man {
    $_ = Canonic($_) for @ARGV[1..$#ARGV];
    my $page = (grep !/^-/, @ARGV)[1];
    return 0 unless $page;
    ClearCase::Argv->new(@ARGV)->system if Native($page);
    if (exists($ClearCase::Wrapper::{$page})) {
      # This EV hack causes perldoc to search for the right keyword
      # within the module's perldoc.
      if (!MSWIN) {
          require Config;
          my $pager = $Config::Config{pager};
          $ENV{PERLDOC_PAGER} ||= "$pager +/" . uc($page)
            if $pager =~ /more|less/;
      }
    } elsif ($page ne $::prog) {
      if (!Native($page)) {
          ClearCase::Argv->new(@ARGV)->exec;
      } else {
          exit($? ? 1 : 0);
      }
    }
    my $psep = MSWIN ? ';' : ':';
    require File::Basename;
    $ENV{PATH} = join($psep, File::Basename::dirname($^X), $ENV{PATH});
    my $module = $ExtMap{$page} || __PACKAGE__;
    Argv->perldoc($module)->exec;
    exit $?;
}

1;

__END__

=head1 NAME

ClearCase::Wrapper - General-purpose wrapper for B<cleartool>

=head1 SYNOPSIS

This perl module functions as a wrapper for B<cleartool>, allowing its
command-line interface to be extended or modified. It allows defaults
to be changed, new flags to be added to existing B<cleartool> commands,
or entirely new commands to be synthesized.

=cut

###########################################################################
## Internal service routines, autoloaded since not always needed.
###########################################################################

# Function to read through include files recursively, used by
# config-spec parsing meta-commands. The first arg is a
# filename, the second an "action" which is eval-ed
# for each line.  It can be as simple as 'print' or as
# complex a regular expression as desired. If the action is
# null, only the names of traversed files are printed.
sub Burrow {
    # compatibility with old call signature, throw away uneeded param
    shift if (@_ && $_[0] eq 'CATCS_00');

    my($filename, $action) = @_;
    print $filename, "\n" if !$action;
    open($filename, $filename) || die Msg('E', "$filename: $!");
    while (<$filename>) {
      if (/^include\s+(.*)/) {
          Burrow($1, $action);
          next;
      }
      eval $action if $action;
    }
    close($filename);
    return 0;
}

# For standard format error msgs - see code for examples.
sub Msg {
    my $key = shift;
    my $type = {W=>'Warning', E=>'Error'}->{$key} if $key;
    my $msg;
    if ($type) {
      $msg = "$prog: $type: @_";
    } else {
      $msg = "$prog: @_";
    }
    chomp $msg;
    return "$msg\n";
}

# Allows the extension writer to make an assertion. If this assertion
# is untrue, dump the current command's usage msg to stderr and exit.
sub Assert {
    my($assertion, @msg) = @_;
    return if $assertion;
    my $op = "";
    for (my $i=1; ((caller($i))[3]) =~ /ClearCase::Wrapper::/; $i++) { 
        $op = (caller($i))[3];
    }
    $op =~ s%.*:%%;
    no strict 'refs';
    my $str = ${$op} || $op || 'help';

    for (@msg) {
      chomp;
      print STDERR Msg('E', $_);
    }
    _helpmsg(STDERR, 1, "help", $op);
}

# Recursive function to find the n'th predecessor of a given version.
sub Pred {
    my($vers, $count, $ct) = @_;
    if ($count) {
      $ct ||= ClearCase::Argv->new;
      (my $elem = $vers) =~ s/@@.*//;
      chomp(my $pred = $ct->desc([qw(-pred -s)], $vers)->qx);
      return Pred("$elem@\@$pred", $count-1, $ct);
    } else {
      return $vers;
    }
}

# Examines supplied arg vector, returns the explicit or implicit working view.
sub ViewTag {
    my $vtag;
    if (@_) {
      local(@ARGV) = @_;
      GetOptions("tag=s" => \$vtag);
    }
    if (!$vtag) {
      require Cwd;
      my $cwd = Cwd::fastgetcwd;
      if (MSWIN) {
          $cwd =~ s/^[A-Z]://i;
          $cwd =~ s%\\%/%g;
      }
      if ($cwd =~ m%/+view/([^/]+)%) {
          $vtag ||= $1;
      }
    }
    if (!$vtag && $ENV{CLEARCASE_ROOT}) {
      $vtag = (split(m%[/\\]%, $ENV{CLEARCASE_ROOT}))[-1];
    }
    $vtag ||= ClearCase::Argv->pwv(['-s'])->qx;
    chomp $vtag if $vtag;
    undef $vtag if $vtag =~ m%\sNONE\s%;
    return $vtag;
}

# Print out the list of elements derived as 'eligible', whatever
# that means for the current op.
sub _ShowFound {
    my $ok = shift;
    my $n = @_;
    my $msg;
    if ($n == 0) {
      $msg = Msg(undef, "no eligible elements found");
    } elsif ($n == 1) {
      $msg = Msg(undef, "found 1 file: @_");
    } elsif ($n <= 10) {
      $msg = Msg(undef, "found $n files: @_");
    } else {
      $msg = Msg(undef, "found $n files: @_[0..3] ...");
    }
    print STDERR $msg;
    # Ask if it's OK to continue, exit if no. Generally results from -ok flag.
    if ($ok && $n) {
      (my $op = (caller(2))[3]) =~ s%.*:%%;
      require ClearCase::ClearPrompt;
      my $a = ClearCase::ClearPrompt::clearprompt(
                      qw(proceed -def p -type ok -pro), "Continue $op?");
      exit 0 unless $a == 0;
    }
}

# Return the list of checked-out elements according to the
# -dir/-rec/-all/-avobs flags. Passes the supplied args to
# lsco, returns the result. The first parameter is a boolean
# indicating whether to give the user an "ok to proceed?"
# prompt; this function may exit if the answer is no.
sub AutoCheckedOut {
    my $ok = shift;
    return () unless @_;
    my @args = @_;
    my @auto = grep /^-(?:dir|rec|all|avo)/, @args;
    return @args unless @auto;
    die Msg('E', "mutually exclusive flags: @auto") if @auto > 1;
    my $lsco = ClearCase::Argv->new('lsco', [qw(-cvi -s)],
                                        grep !/^-(d|cvi)/, @args);
    $lsco->stderr(0) if grep !/^-/, @args; # in case v-p files are listed
    chomp(my @co = $lsco->qx);
    if (MSWIN) {
      for (@co) { s%\\%/%g }
    }
    _ShowFound($ok, @co);
    exit 0 unless @co;
    return @co;
}

# Return the list of not-checked-out FILE elements according to
# the -dir/-rec flags (-all/-avobs not supported). The first parameter
# is a boolean indicating whether to give the user an "ok to proceed?"
# prompt; this function may exit if the answer is no.
sub AutoNotCheckedOut {
    my $agg = shift;
    my $ok = shift;
    my $fd = shift;
    shift;      # dump the command name (e.g. 'co')
    die Msg('E', "only -dir/-recurse supported: $agg") if $agg =~ /^-a/;
    # First derive a list of all FILE elements under the cwd.
    my @e = ClearCase::Argv->new(qw(find . -typ), $fd, qw(-cvi -nxn -pri))->qx;
    # Chomp and remove any leading "./".
    for (@e) {
      chomp;
      s%^\.[\\/]%%;
    }
    # Turn the list into a hash.
    my %elems = map {$_ => 1} @e;
    # Then, narrow it to elems WITHIN the cwd unless -rec.
    if ($agg !~ /^-rec/) {
      for (keys %elems) {
          delete $elems{$_} if m%[/\\]%;
      }
    }
    # Remove those which are already checked out to this view.
    if (%elems) {
      my $lsco = ClearCase::Argv->new('lsco', [qw(-cvi -s)]);
      for ($lsco->args(keys %elems)->qx) {
          chomp;
          delete $elems{$_};
      }
    }
    # Done: we have a list of all file elems that are not checked out.
    my @not_co = sort keys %elems;
    if (MSWIN) {
      for (@not_co) { s%\\%/%g }
    }
    _ShowFound($ok, @not_co);
    exit 0 unless @not_co;
    return @not_co;
}

# Return the list of view-private files according to the
# -dir/-rec/-all/-avobs flags. Passes the supplied args to
# ct lsp and massages the result. The first param is a boolean
# indicating whether to give the user an "ok to proceed?"
# prompt; this function may exit if the answer is no.
sub AutoViewPrivate {
    my($ok, $do, $scope, $parents, $screen) = @_;
    my @vps;
    # Can't use lsprivate in a snapshot view ...
    if (-e '.@@/main/0') {
      my $lsp = Argv->new([$^X, '-S', $0, 'lsp'], [qw(-s -oth), $scope]);
      $lsp->opts($lsp->opts, '-do') if $do;
      chomp(@vps = $lsp->qx);
    } else {
      require File::Spec;
      File::Spec->VERSION(0.82);
      die Msg('E', "-do flag not supported in snapshot views") if $do;
      die Msg('E', "$scope flag not supported in snapshot views")
                                              if $scope =~ /^-a/;
      my $ls = ClearCase::Argv->ls([qw(-s -view -vis)]);
      $ls->opts($ls->opts, $scope) if $scope =~ /^-r/;
      chomp(@vps = $ls->qx);
      @vps = map {File::Spec->rel2abs($_)} @vps;
    }
    if (MSWIN) {
      for (@vps) { s%\\%/%g }
    }
    # Some v-p files we may not be interested in ...
    @vps = grep !m%$screen%, @vps if $screen;
    @vps = sort @vps;

    if ($parents && @vps && $scope =~ /^-(dir|rec)/) {
      # In case the command was run in a v-p directory, traverse upwards
      # towards the vob root adding parent directories till we reach
      # a versioned dir.
      require Cwd;
      my $ctls = ClearCase::Argv->ls({autofail=>1}, [qw(-d -s -vob)], '.');
      while (! $ctls->qx) {
          unshift(@vps, Cwd::getcwd());
          $vps[0] =~ s%\\%/%g if MSWIN;
          if (! Cwd::chdir('..')) {
            my $err = "$!";
            die Msg('E', Cwd::getcwd() . ": $err");
          }
      }
    }

    _ShowFound($ok, @vps);      # may exit
    exit 0 unless @vps;
    return @vps;
}

=head1 CLEARTOOL ENHANCEMENTS

=over 4

=item * EXTENSIONS

A pseudo-command which lists the currently-defined extensions. Use with
B<-long> to see which overlay module defines each extension. Note that
both extensions and their aliases (e.g. I<checkin> and I<ci>) are
shown.

=cut

sub extensions {
    my %opt;
    GetOptions(\%opt, qw(short long));
    my @exts = sort grep !/^_/, keys %ExtMap;
    for (@exts) {
      print "$ExtMap{$_}::" if $opt{long};
      print $_, "\n";
    }
    exit 0;
}

=item * CI/CHECKIN

Extended to handle the B<-dir/-rec/-all/-avobs> flags. These are fairly
self-explanatory but for the record B<-dir> checks in all checkouts in
the current directory, B<-rec> does the same but recursively down from
the current directory, B<-all> operates on all checkouts in the current
VOB, and B<-avobs> on all checkouts in any VOB.

Extended to allow B<symbolic links> to be checked in (by operating on
the target of the link instead).

Extended to implement a B<-diff> flag, which runs a B<I<diff -pred>>
command before each checkin so the user can review his/her changes
before typing the comment.

Implements a new B<-revert> flag. This causes identical (unchanged)
elements to be unchecked-out instead of being checked in.

Implements a new B<-mkhlink> flag. This works in the context of the 
B<-revert> flag and causes any inbound merge hyperlinks to an unchanged
checked-out element to be copied to its predecessor before the unchanged
element is unchecked-out.

Since checkin is such a common operation a special feature is supported
to save typing: an unadorned I<ci> cmd is C<promoted> to I<ci -dir -me
-diff -revert>. In other words typing I<ct ci> will step through each
file checked out by you in the current directory and view,
automatically undoing the checkout if no changes have been made and
showing diffs followed by a checkin-comment prompt otherwise.

=cut

sub checkin {
    # Allows 'ct ci' to be shorthand for 'ct ci -me -diff -revert -dir'.
    push(@ARGV, qw(-me -diff -revert -dir)) if grep(!/^-pti/, @ARGV) == 1;

    # -re999 isn't a real flag, it's to disambiguate -rec from -rev
    # Same for -cr999.
    my %opt;
    GetOptions(\%opt, qw(crnum=s cr999=s diff ok revert re999 mkhlink mk999))
                  if grep /^-(crn|dif|ok|rev|mkh)/, @ARGV;

    die Msg('E', "-mkhlink flag requires -revert flag")
                        if ($opt{mkhlink} && ! $opt{revert});

    # This is a hidden flag to support my checkin_post trigger.
    # It allows the bug number to be supplied as a cmdline option.
    $ENV{CRNUM} = $opt{crnum} if $opt{crnum};

    my $ci = ClearCase::Argv->new(@ARGV);

    # Parse checkin and (potential) diff flags into different optsets.
    $ci->parse(qw(c|cfile=s cqe|nc
                nwarn|cr|ptime|identical|rm|cact|cwork from=s));
    if ($opt{'diff'} || $opt{revert}) {
      $ci->optset('DIFF');
      $ci->parseDIFF(qw(serial_format|diff_format|window columns|options=s
                      graphical|tiny|hstack|vstack|predecessor));
    }

    # Now do auto-aggregation on the remaining args.
    my @elems = AutoCheckedOut($opt{ok}, $ci->args);      # may exit

    # Turn symbolic links into their targets so CC will "do the right thing".
    for (@elems) { $_ = readlink if -l && defined readlink }

    $ci->args(@elems);

    # Give a warning if the file is open for editing by vim.
    # (I know, there are lots of other editors but it just happens
    # to be easy to detect vim by its .swp file)
    for (@elems) {
      die Msg('E', "$_: appears to be open in vim!") if -f ".$_.swp";
    }

    # Unless -diff or -revert in use, we're done.
    $ci->exec unless $opt{'diff'} || $opt{revert};

    # Make sure the -pred flag is there as we're going one at a time.
    my $diff = $ci->clone->prog('diff');
    $diff->optsDIFF(qw(-pred -serial), $diff->optsDIFF);

    # In case ~/.clearcase_profile makes ci -nc the default, make sure
    # we prompt for a comment - unless checking in dirs only.
    $ci->opts('-cqe', $ci->opts)
                  if !grep(/^-c|^-nc$/, $ci->opts) && grep(-f, @elems);

    # Without -diff we only care about return code
    $diff->stdout(0) unless $opt{'diff'};

    # With -revert, suppress msgs from typemgrs that don't do diffs
    $diff->stderr(0) if $opt{revert};

    # Now process each element, diffing and then either ci-ing or unco-ing.
    for $elem (@elems) {
      my $chng = $diff->args($elem)->system('DIFF');
      if ($opt{revert} && !$chng) {
          # If -revert and -mkhlink and no changes, copy hlinks before unco
            if ($opt{mkhlink}) {
                my $ct = ClearCase::Argv->new({autochomp=>1});
                my @links = grep {s/^<- //}
                    $ct->desc(['-s', '-ahl', 'Merge'], $elem)->qx;
                my $pred = Pred($elem,1,$ct);
                $pred = Pred($pred,1,$ct) if $pred =~ m#/0$#;
                for (@links) {
                    $ct->mkhlink(['-unidir','Merge'], $_, $pred)->system;
                }
            }

          # If -revert and no changes, unco instead of checkin
          ClearCase::Argv->unco(['-rm'], $elem)->system;
      } else {
          $ci->args($elem)->system;
      }
    }

    # All done, no need to return to wrapper program.
    exit $?>>8;
}

=item * CO/CHECKOUT

Extended to handle the B<-dir/-rec> flags. NOTE: the B<-all/-avobs>
flags are disallowed for checkout. Also, directories are not checked
out automatically with B<-dir/-rec>.

=cut

sub checkout {
    for (@ARGV[1..$#ARGV]) { $_ = readlink if -l && defined readlink }
    # If no aggregation flags used, we have no value to add so drop out.
    my @agg = grep /^-(?:dir|rec|all|avo)/, @ARGV;
    return 0 unless @agg;
    die Msg('E', "mutually exclusive flags: @agg") if @agg > 1;

    # Remove the aggregation flag, push the aggregated list of
    # not-checked-out file elements onto argv, and return.
    my %opt;
    GetOptions(\%opt, qw(directory recurse all avobs ok));
    my @added = AutoNotCheckedOut($agg[0], $opt{ok}, 'f', @ARGV);  # may exit
    push(@ARGV, @added);
    return 0;
}

=item * DIFF

Extended to handle the B<-dir/-rec/-all/-avobs> flags.

Improved default: if given just one element and no flags, assume B<-pred>.

Extended to implement B<-n>, where I<n> is an integer requesting that
the diff take place against the I<n>'th predecessor.

=cut

sub diff {
    for (@ARGV[1..$#ARGV]) { $_ = readlink if -l && defined readlink }

    # Allows 'ct diff' to be shorthand for 'ct diff -dir'.
    push(@ARGV, qw(-dir)) if @ARGV == 1;

    my $limit = 0;
    if (my @num = grep /^-\d+$/, @ARGV) {
      @ARGV = grep !/^-\d+$/, @ARGV;
      die Msg('E', "incompatible flags: @num") if @num > 1;
      $limit = -int($num[0]);
    }
    my $diff = ClearCase::Argv->new(@ARGV);
    $diff->parse(qw(options=s serial_format|diff_format|window
                graphical|tiny|hstack|vstack|predecessor));
    my @args = $diff->args;
    my $auto = grep /^-(?:dir|rec|all|avo)/, @args;
    my @elems = AutoCheckedOut(0, @args);      # may exit
    $diff->args(@elems);
    my @opts = $diff->opts;
    my @extra = ('-serial') if !grep(/^-(?:ser|dif|col|g)/, @opts);
    if ($limit && @elems == 1) {
      $diff->args(Pred($elems[0], $limit, ClearCase::Argv->new), @elems);
    } else {
      push(@extra, '-pred') if ($auto || @elems < 2) && !grep(/^-pre/, @opts);
    }
    $diff->opts(@opts, @extra) if @extra;
    if ($auto && @elems > 1) {
      for (@elems) { $diff->args($_)->system }
      exit $?;
    } else {
      $diff->exec;
    }
}

=item * DIFFCR

Extended to add the B<-data> flag, which compares the I<contents>
of differing elements and removes them from the output if the
contents do not differ.

=cut

sub diffcr {
    my %opt;
    GetOptions(\%opt, qw(data)) if grep m%^-d%, @ARGV;
    # If -data not passed, fall through to regular behavior.
    if ($opt{data}) {
      GetOptions(\%opt, qw(long));
      die Msg('E', "incompatible flags: -data and -long")
          if exists $opt{long};

      require Digest::MD5;
      my $md51 = Digest::MD5->new;
      my $md52 = Digest::MD5->new;

      my $diffcr = ClearCase::Argv->new(@ARGV);
      my @results = $diffcr->qx;
      my %elems;
      for (@results) {
          if (m%^([<>]\s+)(.*)@@([/\\]\S*)(.*)%) {
            my($prefix, $elem, $version, $suffix) = ($1, $2, $3, $4);
            next if ! -f $elem;
            if (exists $elems{$elem}) {
                my $same = 0;
                if ($elems{$elem}->[0] eq $version) {
                  $same = 1;
                } else {
                  my $v1 = join('@@', $elem, $elems{$elem}->[0]);
                  my $v2 = join('@@', $elem, $version);

                  if (open(V1, $v1) && open(V2, $v2)) {
                      $md51->addfile(*V1);
                      close(V1);
                      my $digest1 = $md51->hexdigest;

                      $md52->addfile(*V2);
                      close(V2);
                      my $digest2 = $md52->hexdigest;

                      if ($digest1 eq $digest2) {
                        $same = 1;
                      } else {
                        chomp $elems{$elem}->[1];
                        $elems{$elem}->[1] .= " [$digest1]\n";
                        chomp $_;
                        $_ .= " [$digest2]\n";
                      }
                  }
                }
                if (!$same) {
                  print $elems{$elem}->[1];
                  print;
                }
                delete $elems{$elem};
            } else {
                $elems{$elem} = [$version, $_];
            }
          } else {
            print;
          }
      }
      exit(0);
    }
}

=item * EDIT/VI

Convenience command. Same as 'checkout' but execs your favorite editor
afterwards. Takes all the same flags as checkout, plus B<-ci> to check
the element back in afterwards. When B<-ci> is used in conjunction with
B<-diff> the file will be either checked in or un-checked out depending
on whether it was modified.

The aggregation flags B<-dir/-rec/-all/-avo> may be used, with the
effect being to run the editor on all checked-out files in the named
scope. Example: I<"ct edit -all">.

=cut

sub edit {
    for (@ARGV[1..$#ARGV]) { $_ = readlink if -l && defined readlink }
    # Allows 'ct edit' to be shorthand for 'ct edit -dir -me'.
    push(@ARGV, qw(-dir -me)) if @ARGV == 1;
    my %opt;
    # -c999 isn't a real flag, it's there to disambiguate -c vs -ci
    GetOptions(\%opt, qw(ci c999)) if grep /^-ci$/, @ARGV;
    my $co = ClearCase::Argv->new('co', @ARGV[1..$#ARGV]);
    $co->optset('CI');
    $co->parse(qw(out|branch=s reserved|unreserved|ndata|version|nwarn));
    $co->parseCI(qw(nwarn|cr|ptime|identical|rm from=s c|cfile=s cq|nc diff|revert));
    my $editor = $ENV{WINEDITOR} || $ENV{VISUAL} || $ENV{EDITOR} ||
                                        (MSWIN ? 'notepad' : 'vi');
    # Handle -dir/-rec/etc
    if (grep /^-(?:dir|rec|all|avo)/, @ARGV) {
      $co->args(grep -f, AutoCheckedOut(0, $co->args));      # may exit
    }
    my $ed = Argv->new;
    $ed->prog($editor);
    $ed->args($co->args);
    $co->args(grep !-w, $co->args);
    $co->opts('-nc', $co->opts);
    $co->autofail(1)->system if $co->args;
    # Run the editor, check return code.
    $ed->system;
    exit $? unless $opt{'ci'};
    my $ci = Argv->new([$^X, '-S', $0, 'ci']);
    $ci->opts($co->optsCI);
    $ci->opts('-revert') unless $ci->opts;
    $ci->args($ed->args);
    $ci->exec;
}

# No POD for this one because no options (same as native variant).
sub _helpmsg {
    my $FH = shift;
    my $rc = shift;
    # Let cleartool handle any malformed requests.
    return 0 if @_ > 2;
    my @text;
    if (@_ == 2) {
      my $op = $_[1] = Canonic($_[1]);
      @text = ClearCase::Argv->new(@_)->stderr(0)->qx;
      if (Extension($op)) {
          chomp $text[-1] if @text;;
          if (my $msg = $$op) {
            chomp $msg;
            my $indent;
                if (! @text or $text[0] =~ 'Usage: help ') {
                  @text = ("Usage: * ");
                    $indent = "Usage: * $op ";
                $msg =~ s/^help/$op/;
                } else {
                ($indent) = ($text[-1] =~ /^(\s*)/);
                    if (!$indent) {
                    ($indent) = ($text[0] =~ /^([^\s]+[\s*]+[^\s]+\s+)/);
                    }
                }
                $indent = " " x (length($indent) - 2);
            $msg =~ s/\n([^\*])/\n  $1/gs;
            $msg =~ s/\n/\n$indent/gs;
            push(@text, $msg);
          }
            push @text, "\n";
      }
        print $FH @text;
      exit $rc;
    } else {
      @text = ClearCase::Argv->new(@_)->stderr(0)->qx;
    }
    print $FH @text, "\n";
    my $bars = '='x70;
    print $FH "$bars\n= ClearCase::Wrapper Extensions:\n$bars\n\n";
    for (sort grep !/^_/, keys %ClearCase::Wrapper::ExtMap) {
      next if m%^(lsp(riv)?|c.)$%;
      $cmd = "ClearCase::Wrapper::$_";
      my (@text) = grep {$_} split /\n/, $$cmd;
      next unless @text;
      for (@text[1..$#text]) {s/^/ /;}
      $text =~ s%^(help)?\s+%%s;
      my $star = ClearCase::Wrapper::Native($_) ? '' : '* ';
      my $leader = "Usage: $star$_";
      for (@text) {
        s/^\*/ */;
        print $FH "$leader$_\n";
        $leader =~ s/./ /g;
      }
    }
    exit $rc
}

sub help {

    _helpmsg(STDOUT, 0, @ARGV);
}

=item * LSPRIVATE

Extended to recognize B<-dir/-rec/-all/-avobs>.  Also allows a
directory to be specified such that 'ct lsprivate .' restricts output
to the cwd. This directory arg may be used in combination with B<-dir>
etc.

The B<-eclipsed> flag restricts output to eclipsed elements.

The flag B<-type d|f> is also supported with the usual semantics (see
cleartool find).

The flag B<-visible> flag ignores files not currently visible in the
view.

Output is relative to the current or specified directory if the
B<-rel/ative> flag is used.

The B<-ext> flag sorts the output by extension.

=cut

sub lsprivate {
    my %opt;
    GetOptions(\%opt, qw(directory recurse all avobs eclipsed
                                    ext relative type=s visible));

    my $lsp = ClearCase::Argv->new(@ARGV);
    $lsp->parse(qw(short co|do|other|long tag=s invob=s));

    my $pname = '.';

    # Extension: allow [dir] argument
    if ($lsp->args) {
      chomp(($pname) = $lsp->args);
      $lsp->args;
      # Default to -rec but accept -dir.
      $opt{recurse} = 1 unless $opt{directory} || $opt{all} || $opt{avobs};
    }

    # Extension: implement [-dir|-rec|-all|-avobs]
    if ($opt{directory} || $opt{recurse} || $opt{all} || $opt{avobs} || $opt{eclipsed} || $opt{ext}) {
      require Cwd;
      my $dir = Cwd::abs_path($pname);
      my $tag = $lsp->flag('tag');
      $lsp->opts($lsp->opts, '-invob', $pname)
                  if ($opt{directory} || $opt{recurse} || $opt{all}) &&
                      !$lsp->flag('invob');
      if ($opt{directory} || $opt{recurse}) {
          if ($dir =~ s%/+view/([^/]+)%%) {      # UNIX view-extended path
            $tag ||= $1;
          } elsif ($dir =~ s%^[A-Z]:%%) {      # WIN view-extended path
            if ($tag) {
                $dir =~ s%^/$tag%%i;
            } else {
                $tag = ViewTag(@ARGV);
            }
          } elsif (!$tag) {
            $tag = ViewTag(@ARGV);
          }
          $lsp->opts($lsp->opts, '-tag', $tag) if !$lsp->flag('tag');
      }
      chomp(my @privs = sort $lsp->qx);
      exit $? if $? || !@privs;
      # Strip out all results which are not eclipsed. An element
      # is eclipsed if (a) there's a view-private copy,
      # (b) there's also a versioned copy, and (c) it's not checked out.
      if ($opt{eclipsed}) {
          my %coed = ();
          if ($lsp->flag('short')) {
            %coed = map {chomp; $_ => 1}
                        ClearCase::Argv->lsco(qw(-avo -s -cvi))->qx;
          }
          my @t_privs;
          for (@privs) {
            next if m%\s\[checkedout\]%;
            next unless -e "$_@@/main/0";
            my $sv = $_;
            $sv =~ s%(/+view)?/$tag%% if $tag;
            next if exists $coed{$sv};
            push(@t_privs, $_);
          }
          @privs = @t_privs;
      }
      if ($opt{directory} || $opt{recurse}) {
          for (@privs) {
            if (MSWIN) {
                s/^[A-Z]://i;
                s%\\%/%g;
            }
            s%(/+view)?/$tag%%;
          }
          @privs = map {$_ eq $dir ? "$_/" : $_} @privs;
          my $job = $opt{relative} ? 'map ' : 'grep ';
          $job .= $opt{recurse} ? '{m%^$dir/(.*)%}' : '{m%^$dir/([^/]*)$%s}';
          $opt{type} ||= 'e' if $opt{visible};
          $job = "grep {-$opt{type}} $job" if $opt{type};
          eval qq(\@privs = $job \@privs);
          exit 0 if !@privs;
      }
      if ($opt{ext}) {      # sort by extension
          require File::Basename;
          @privs = map  { $_->[0] }
             sort { "$a->[1]$a->[2]$a->[3]" cmp "$b->[1]$b->[2]$b->[3]" }
             map  { [$_, (File::Basename::fileparse($_, '\.\w+'))[2,0,1]] }
             @privs;
      }
      for (@privs) { print $_, "\n" }
      exit 0;
    }
    $lsp->exec;
}

=item * LSVIEW

Extended to recognize the general B<-me> flag, which restricts the
searched namespace to E<lt>B<username>E<gt>_*.

=cut

sub lsview {
    my @args = grep !/^-me/, @ARGV;
    push(@args, "$ENV{LOGNAME}_*") if @args != @ARGV;
    ClearCase::Argv->new(@args)->autoquote(0)->exec;
}

=item * MKELEM

Extended to handle the B<-dir/-rec> flags, enabling automated mkelems
with otherwise the same syntax as original. Directories are also
automatically checked out as required in this mode. B<Note that this
automatic directory checkout is only enabled when the candidate list is
derived via the B<-dir/-rec> flags>.  If the B<-ci> flag is present,
any directories automatically checked out are checked back in too.

By default, only regular (I<-other>) view-private files are considered
by B<-dir|-rec>.  The B<-do> flag causes derived objects to be made
into elements as well.

If B<-ok> is specified, the user will be prompted to continue after the
list of eligible files is determined.

When invoked in a view-private directory, C<mkelem -dir/-rec> will
traverse up the directory structure towards the vob root until it finds
a versioned dir to work from. Directories traversed during this walk
are added to the list of new elements.

=cut

sub mkelem {
    my %opt;
    GetOptions(\%opt, qw(directory recurse all avobs do ok));
    die Msg('E', "-all|-avobs flags not supported for mkelem")
                              if $opt{all} || $opt{avobs};
    return unless $opt{directory} || $opt{recurse};

    # Derive the list of view-private files to work on. This may exit
    # if no eligibles are found.
    my $scope = $opt{recurse} ? '-rec' : '-dir';
    my $re = q%(?:\.(?:n|mv)fs_\d+|\.(?:abe|cmake)\.state|\.(?:swp|tmp))$%;
    my @vps = AutoViewPrivate($opt{ok}, $opt{do}, $scope, 1, $re);

    my $ct = ClearCase::Argv->new({-autofail=>1});

    # We'll be separating the elements-to-be into files and directories.
    my(@files, %dirs);

    # If the parent directories of any of the candidates are already
    # versioned elements we may need to check them out.
    require File::Basename;
    my %seen;
    for (@vps) {
      my $d = File::Basename::dirname($_);
      next if ! $d || $dirs{$d};
      next if $seen{$d}++;
      my $lsd = $ct->ls(['-d'], $d)->qx;
      # If no version selector was given it's a view-private dir and
      # will be handled below.
      next unless $lsd =~ /\sRule:\s/;
      # If already checked out, nothing to do.
      next if $lsd =~ /CHECKEDOUT$/;
      # Now we know it's an element and needs to be checked out.
      $dirs{$d}++;
    }
    $ct->co(['-nc'], keys %dirs)->system if %dirs;

    # Process candidate directories here, then do files below.
    for my $cand (@vps) {
      if (! -d $cand) {
          push(@ARGV, $cand);
          next;
      }
      # Now we know we're dealing with directories.  These must not
      # exist at mkelem time so we move them aside, make
      # a versioned dir, then move all the files from the original
      # back into the new dir (still as view-private files).
      my $tmpdir = "$cand.$$.keep.d";
      die Msg('E', "$cand: $!") if !rename($cand, $tmpdir);
      $ct->mkdir(['-nc'], $cand)->system;
      opendir(DIR, $tmpdir) || die Msg('E', "$tmpdir: $!");
      while (defined(my $i = readdir(DIR))) {
          next if $i eq '.' || $i eq '..';
          die Msg('E', "$cand/$i: $!") if !rename("$tmpdir/$i", "$cand/$i");
      }
      closedir DIR;
      warn Msg('W', "$tmpdir: $!") unless rmdir $tmpdir;
      # Keep a record of directories to be checked in when done.
      $dirs{$cand}++;
    }

    # Now we've made all the directories, do the files in one fell swoop.
    $ct->argv(@ARGV)->system if grep -f, @ARGV;

    # Last - if the -ci flag was supplied, check the dirs back in.
    # Also flush the view cache if dirs were created. Really
    # we could be smarter here because it really only needs flushing
    # if one of the dirs was the cwd.
    if (%dirs) {
      $ct->ci(['-nc'], keys %dirs)->system if grep /^-ci$/, @ARGV;
      $ct->setcs(['-curr'])->system;
    }

    # Done - don't drop back to main program.
    exit $?;
}

=item * UNCO

Extended to accept (and ignore) the standard comment flags for
consistency with other cleartool cmds.

Extended to handle the -dir/-rec/-all/-avobs flags.

Extended to operate on ClearCase symbolic links.

=cut

sub uncheckout {
    my %opt;
    GetOptions(\%opt, qw(ok)) if grep /^-(dif|ok)/, @ARGV;
    for (@ARGV[1..$#ARGV]) { $_ = readlink if -l && defined readlink }
    my $unco = ClearCase::Argv->new(@ARGV);
    $unco->parse(qw(keep rm cact cwork));
    $unco->optset('IGNORE');
    $unco->parseIGNORE(qw(c|cfile=s cqe|nc));
    $unco->args(sort {$b cmp $a} AutoCheckedOut($opt{ok}, $unco->args));
    $unco->exec;
}

=back

=head1 GENERAL FEATURES

=over 4

=item * symlink expansion

Before processing a checkin or checkout command, any symbolic links on
the command line are replaced with the file they point to. This allows
developers to operate directly on symlinks for ci/co.

=item * -M flag

As a convenience feature, the B<-M> flag runs all output through your
pager. Of course C<"ct lsh -M foo"> saves only a few keystrokes over
"ct lsh foo | more" but for heavy users of shell history the more
important feature is that it preserves the value of ESC-_ (C<ksh -o
vi>) or !$ (csh). The CLEARCASE_WRAPPER_PAGER EV has the same effect.

This may not work on Windows, though it's possible that a sufficiently
modern Perl build and a smarter pager than I<more.com> will do the
trick.

=item * -P flag

The special B<-P> flag will cause C<ct> to I<pause> before finishing.
On Windows this means running the built in C<pause> command. This flag
is useful for plugging I<ClearCase::Wrapper> scripts into the CC GUI.

=item * -me -tag

Introduces a global convenience/standardization feature: the flag
B<-me> in the context of a command which takes a B<-tag view-tag>
causes I<"$LOGNAME"> to be prefixed to the tag name with an
underscore.  This relies on the fact that even though B<-me> is a
native cleartool flag, at least through CC 7.0 no command which takes
B<-tag> also takes B<-me> natively. For example:

    % <wrapper-context> mkview -me -tag myview ... 

The commands I<setview, startview, endview, and lsview> also take B<-me>,
such that the following commands are equivalent:

    % <wrapper-context> setview dboyce_myview
    % <wrapper-context> setview -me myview

=back

=head1 CONFIGURABILITY

Various degrees of configurability are supported:

=over 4

=item * Global Enhancements and Extensions

To add a global override called 'cleartool xxx', you could just write a
subroutine 'xxx', place it after the __END__ token in Wrapper.pm, and
re-run 'make install'. However, these changes wcould be lost when a new
version of ClearCase::Wrapper is released, and you'd have to take
responsibility for merging your changes with mine.

Therefore, the preferred way to make site-wide customizations or
additions is to make an I<overlay> module. ClearCase::Wrapper will
automatically include ('require') all modules in the
ClearCase::Wrapper::* subclass. Thus, if you work for C<TLA
Corporation> you should put your enhancement subroutines in a module
called ClearCase::Wrapper::TLA and they'll automatically become
available.

A sample overlay module is provided in the C<./examples> subdir. To
make your own you need only take this sample, change all uses of the
word 'MySite' to a string of your choice, replace the sample subroutine
C<mysite()> with your own, and install. It's a good idea to document
your extension in POD format right above the sub and make the
appropriate addition to the "Usage Message Extensions" section.  Also,
if the command has an abbreviation (e.g. checkout/co) you should add
that to the "Command Aliases" section. See ClearCase::Wrapper::DSB
for examples.

Two separate namespaces are recognized for overlays:
I<ClearCase::Wrapper::*> and I<ClearCase::Wrapper::Site::*>. The intent
is that if your extension is site-specific it should go in the latter
area, if of general use in the former. These may be combined.  For
instance, imagine TLA Corporation is a giant international company with
many sites using ClearCase, and your site is known as R85G. There could
be a I<ClearCase::Wrapper::TLA> overlay with enhancements that apply
anywhere within TLA and/or a I<ClearCase::Wrapper::Site::R85G> for
your people only. Note that since overlay modules in the Site namespace
are not expected to be published on CPAN the naming rules can be less
strict, which is why C<TLA> was left out of the latter module name.

Overlays in the general I<ClearCase::Wrapper::*> namespace are
traversed before I<ClearCase::Wrapper::Site::*>. This allows
site-specific configuration to override more general code. Within each
namespace modules are read in standard ASCII sorted alphabetical
order.

All override subroutines are called with @ARGV as their parameter list
(and @ARGV is also available directly of course). The function can do
whatever it likes but it's recommended that I<ClearCase::Argv> be used
to run any cleartool subcommands, and its base class I<Argv> be used to
run other programs. These modules help with UNIX/Windows portability
and debugging, and aid in parsing flags into different categories where
required. See their PODs for full documentation, and see the supplied
extensions for lots of examples.

=item * Personal Preference Setting

As well as allowing for site-wide enhancements to be made in
Wrapper.pm, a hook is also provided for individual users to set their
own defaults.  If the file C<~/.clearcase_profile.pl> exists it will be
read before launching any of the sitewide enhancements. Note that this
file is passed to the Perl interpreter and thus has access to the full
array of Perl syntax. This mechanism is powerful but the corollary is
that users must be experienced with both ClearCase and Perl, and to
some degree with the ClearCase::Wrapper module, to use it. Here's an
example:
 
    % cat ~/.clearcase_profile.pl
    require ClearCase::Argv;
    Argv->dbglevel(1);
    ClearCase::Argv->ipc(2);

The purpose of the above is to turn on ClearCase::Argv "IPC mode"
for all commands. The verbosity (Argv->dbglevel) is only set to
demonstrate that the setting works. The require statement is used
to ensure that the module is loaded before we attempt to configure it.

=item * Sitewide ClearCase Comment Defaults

This distribution comes with a file called I<clearcase_profile> which
is installed as part of the module. If the user has no
I<clearcase_profile> file in his/her home directory and if
CLEARCASE_PROFILE isn't already set, CLEARCASE_PROFILE will
automatically be pointed at this supplied file. This allows the
administrator to set sitewide defaults of checkin/checkout comment
handling using the syntax supported by ClearCase natively but without
each user needing to maintain their own config file or set their own
EV.

=item * CLEARCASE_WRAPPER_NATIVE

This environment variable may be set to suppress all extensions,
causing the wrapper to behave just like an alias to cleartool, though
somewhat slower.

=back

=head1 DIAGNOSTICS

The flag B<-/dbg=1> prints all cleartool operations executed by the
wrapper to stderr as long as the extension in use was coded with
ClearCase::Argv, which is the case for all supplied extensions.

=head1 INSTALLATION

I recommend you install the I<cleartool.plx> file to some global dir
(e.g. /usr/local/bin), then symlink it to I<ct> or whatever short name
you prefer.  For Windows the strategy is similar but requires a
"ct.bat" redirector instead of a symlink. See "examples/ct.bat" in the
distribution.  Unfortunately, there's no equivalent mechanism for
wrapping GUI access to clearcase.

To install or update a global enhancement you must run "make pure_all
install" - at least that's what I've found to work.  Also, don't forget
to check that the contents of
C<lib/ClearCase/Wrapper/clearcase_profile> are what you want your users
to have by default.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1997-2006 David Boyce (dsbperl AT boyski.com). All rights
reserved.  This Perl program is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut
