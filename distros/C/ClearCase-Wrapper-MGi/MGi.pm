package ClearCase::Wrapper::MGi;

$VERSION = '1.00';

use warnings;
use strict;
use constant CYGWIN => $^O =~ /cygwin/i ? 1 : 0;
use vars qw($CT $EQHL $PRHL $STHL $FCHL %Xfer $Benchstart);
use File::Find;
($EQHL, $PRHL, $STHL, $FCHL) = qw(EqInc PrevInc StBr FullCpy);

# Note: only wrapper supported functionality--possible fallback to cleartool
sub _Wrap {
  local @ARGV = @_;
  ClearCase::Wrapper::Extension($ARGV[0]);
  no strict 'refs';
  my $rc = eval { "ClearCase::Wrapper::$ARGV[0]"->(@ARGV) };
  if ($@) {
    chomp $@;		 #One extra newline to avoid dumping the stack
    if ($@ =~ m%^\d+$%) {
      $rc = $@;
    } elsif ($@) {
      print STDERR "$@\n";
      $rc = 1;
    } else {
      $rc = 0;
    }
  } else {
    $rc = ClearCase::Argv->new(@ARGV)->system unless $rc; # fallback!
  }
  return $rc;			# Completed, successful or not
}
## Internal service routines, undocumented.
sub _Compareincs {
  my ($t1, $t2) = @_;
  my ($p1, $M1, $m1, $s1) = pfxmajminsfx($t1);
  my ($p2, $M2, $m2, $s2) = pfxmajminsfx($t2);
  if (!(defined($p1) and defined($p2) and ($p1 eq $p2) and ($s1 eq $s2))) {
    warn Msg('W', "$t1 and $t2 not comparable\n");
    return 1;
  }
  return ($M1 <=> $M2 or (defined($m1) and defined($m2) and $m1 <=> $m2));
}
sub _Samebranch {		# same branch
  my ($cur, $prd) = @_;
  $cur =~ s:/\d+$:/:; # Treat CHECKEDOUT as other branch
  $prd =~ s:/\d+$:/:;
  return $cur eq $prd;
}
sub _Sosbranch {		# same or sub- branch
  my ($cur, $prd) = @_;
  $cur =~ s:/\d+$:/:;
  $prd =~ s:/\d+$:/:;
  return $cur =~ /^\Q$prd\E/;
}
sub _Printoffspring {
  no warnings 'recursion';
  my ($id, $gen, $opt, $ind, $seen, $out) = @_;
  my $top = $out? 0 : ($out = [], $seen = {}, 1);
  if ($seen->{$id}++) {
    push @{$out}, sprintf("%${ind}s\[alternative: ${id}\]", '')
      unless $opt->{short} or $opt->{fmt};
    return;
  }
  my @p = @{ $gen->{$id}{parents} || [] };
  my @c = @{ $gen->{$id}{children} || [] };
  my $l = $gen->{$id}{labels} || '';
  my ($s, $u) = ([], []);
  push @{$seen->{$_}? $s : $u}, $_ for @p;
  if (@{$u} and !($opt->{short} or $opt->{fmt})) {
    my $pprinted = 0;
    map{$pprinted++ if $gen->{$_}{printed}} @{$s};
    push @{$out}, ' 'x($ind-1) . '[contributor' . (@{$u}>1? 's' : '') . ': '
      . join(' ', @{$u}) . ']' if $pprinted and $ind;
  }
  my $yes = ($opt->{all} or (@c != 1) or (@{$s} != 1)
	       or !_Samebranch($id, $s->[0]) or !_Sosbranch($c[0], $id));
  if ($l or $yes) {
    if ($opt->{short}) {
      if ($yes) {
	# the arg (0-indented) is being printed with its parents
	push @{$out}, sprintf("%${ind}s${id}", '') if $ind;
	$gen->{$id}{printed}++;
	$ind++; # increase only if printed
      }
    } else {
      if ($ind) {
	my $data = $opt->{fmt}? $l : "$id$l";
	$data =~ s/\%/\%\%/g;	#Escape possible percent signs
	push @{$out}, sprintf("%${ind}s$data", '');
      }
      $gen->{$id}{printed}++;
      $ind++;
    }
  }
  _Printoffspring($_, $gen, $opt, $ind, $seen, $out) for @c;
  map{print "$_\n"} reverse @{$out} if $top; # only once
}
sub _Printparents {
  no warnings 'recursion';
  my ($id, $gen, $seen, $opt, $ind) = @_;
  if ($seen->{$id}++) {
    printf("%${ind}s\[alternative: ${id}\]\n", '')
      unless $opt->{short} or $opt->{fmt};
    return;
  }
  my @p = @{ $gen->{$id}{parents} || [] };
  my @c = @{ $gen->{$id}{children} || [] };
  my $l = $gen->{$id}{labels} || '';
  my (@s, @u) = ();
  foreach my $c (@c) {
    if ($seen->{$c}) {
      push @s, $c;
    } else {
      push @u, $c;
    }
  }
  if (scalar(@u) and !($opt->{short} or $opt->{fmt})) {
    my $cprinted = 0;
    for my $c (@s) {
      $cprinted++ if $gen->{$c}{printed};
    }
    if (($cprinted or !$ind) and !$opt->{offspring}) {
      my $plural = @u>1? 's' : '';
      if ($ind == 0) {
	print "\[offspring: ";
      } else {
	my $pind = $ind - 1;
	print ' 'x$pind, "\[sibling${plural}: ";
      }
      print join(' ', @u), "\]\n";
    }
  }
  my $yes = ($opt->{all} or (scalar(@p) != 1) or (scalar(@s) != 1)
	       or !_Samebranch($id, $s[0]) or !_Sosbranch($id, $p[0]));
  if ($l or $yes) {
    if ($opt->{short}) {
      if ($yes) {
	printf("%${ind}s${id}\n", '');
	$gen->{$id}{printed}++;
	$ind++;
      }
    } else {
      my $data = $opt->{fmt}? $l : "$id$l";
      $data =~ s/\%/\%\%/g; #Escape possible percent signs
      printf "%${ind}s$data\n", '';
      $gen->{$id}{printed}++;
      $ind++;
    }
  }
  return if (defined($opt->{depth})) and ($opt->{depth} < $ind);
  foreach my $p (@p) {
    if ($gen->{$id}{depth} < $gen->{$p}{depth}) {
      _Printparents($p, $gen, $seen, $opt, $ind);
    } elsif (!($opt->{short} or $opt->{fmt})) {
      printf("%${ind}s\[alternative: ${p}\]\n", '');
    }
  }
}
sub _Findpredinstack {
  my ($g, $stack) = @_;
  while ($$stack[-1]) {
    return $$stack[-1] if _Sosbranch($g, $$stack[-1]);
    pop @{$stack};
  }
  return 0;
}
sub _Setdepths {
  no warnings 'recursion';
  my ($id, $dep, $gen) = @_;
  if (defined($gen->{$id}{depth})) {
    if ($gen->{$id}{depth} > $dep) {
      $gen->{$id}{depth} = $dep;
    } else {
      return;
    }
  } else {
    $gen->{$id}{depth} = $dep;
  }
  my @p = defined($gen->{$id}{parents}) ? @{ $gen->{$id}{parents} } : ();
  foreach my $p (@p) {
    _Setdepths($p, $gen->{$id}{depth} + 1, $gen);
  }
}
sub _Checkcs {
  use File::Basename;
  use Cwd;
  my ($v) = @_;
  $v =~ s/^(.*?)\@\@.*$/$1/;
  my $dest = dirname($v);
  $dest .= '/' unless $dest =~ m%/$%;
  my $pwd = getcwd();
  $CT->cd($dest)->system if $dest;
  my @cs = grep /^\#\#:BranchOff: *root/, $CT->argv('catcs')->qx;
  $CT->cd($pwd)->system if $dest;
  return scalar @cs;
}
sub _Pbrtype {
  my ($pbrt, $bt) = @_;
  if (!defined($pbrt->{$bt})) {
    my $tc = $CT->argv('des', qw(-fmt %[type_constraint]p),
		       "brtype:$bt")->qx;
    $pbrt->{$bt} = ($tc =~ /one version per branch/);
  }
  return $pbrt->{$bt};
}
sub _Parsevtree {
  my ($ele, $obs, $sel) = @_;
  $CT->lsvtree;
  my @opt = qw(-merge -all);
  push @opt, '-obs' if $obs;
  $CT->opts(@opt);
  my @vt = $CT->args($ele)->qx;
  my $v0 = $vt[1];
  @vt = grep m%(^$sel|[\\/]([1-9]\d*|CHECKEDOUT))( .*)?$%, @vt;
  map { s%\\%/%g } @vt, $v0;
  my (%gen, @root);
  $gen{$v0}{labels} = $1 if $v0 =~ s%/0( \(.*)$%/0%;
  my @stack = ();
  foreach my $g (@vt) {
    $g =~ s%^(.*/CHECKEDOUT) view ".*"(.*)$%$1$2%;
    if ($g =~ m%^(.*)( \(.*\))$%) {
      $g = $1;
      $gen{$g}{labels} = $2;
    }
    if ($g =~ /^  -> (.*)$/) {
      my $v = $1;
      my $n = "$ele\@\@$v";
      push @{ $gen{$stack[-1]}{children} }, $n;
      push @{ $gen{$n}{parents} }, $stack[-1];
      next;
    }
    if (_Findpredinstack($g, \@stack)) {
      push @{ $gen{$g}{parents} }, $stack[-1];
      push @{ $gen{$stack[-1]}{children} }, $g;
    } elsif ($g ne $v0 and !$gen{$g}{parents}) {
      push @root, $g; #come back later
    }
    push @stack, $g;
  }
  for (@root) {
    next if $gen{$_}{parents};
    push @{ $gen{$_}{parents} }, $v0;
    push @{ $gen{$v0}{children} }, $_;
  }
  return \%gen;
}
sub _Parents {
  my ($ver, $ele) = @_;
  # v0 is $ele@@/main/0, whatever the actual name of 'main' for $ele
  # Only mention v0 as last recourse, if there is nothing else
  my $pred = $CT->des([qw(-fmt %En@@%PVn)], $ver)->qx;
  return if $pred eq "$ele@@";	# Only v0 has no parent
  my @ret = grep s/^<- .*?(@.*)/$ele$1/,
    $CT->des([qw(-s -ahl Merge)], $ver)->qx;
  $pred = $CT->des([qw(-fmt %En@@%PVn)], $pred)->qx
    while $pred =~ m%\@[^@]*[/\\][^@]+[/\\][^@]+[/\\]0$%;
  s%\\%/%g for grep $_, $pred, @ret; # Windows...
  push @ret, $pred unless $pred =~ m%/0$% and @ret;
  return @ret
}
sub _Offspring {
  my ($ele, $sel, $gen) = @_;
  my @offsp = grep s/^-> .*?(@.*)/$ele$1/,
    $CT->des([qw(-s -ahl Merge)], $sel)->qx;
  my ($br, $nr) = ($sel =~ m%^(.*)/(\d+)$%); # $sel is normalized
  if ($br and opendir BR, $br) {	     # Skip for CHECKEDOUT
    my @f = grep !/^\.\.?/, readdir BR;
    closedir BR;
    my @n = sort {$a <=> $b} grep { /^\d+$/ and $_ > $nr } @f;
    push @offsp, join('/', $br, $n[0]) if @n;
    my $sil = new ClearCase::Argv({autochomp=>1, stderr=>0});
    push @offsp, grep {$sil->des([qw(-fmt %Pn)], $_)->qx eq $sel}
      join('/', $br, $_, '0')
      for grep { /^\D/ and $sil->des(['-s'], "brtype:$_")->qx } @f;
    push @offsp, join('/', $br, 'CHECKEDOUT')
      if $sil->lsco([qw(-fmt %En@@%PVn)], $ele)->qx eq $sel;
    my %chld = map{$_ => 1} @{ $gen->{$sel}{children} }; # no duplicates
    push @{ $gen->{$sel}{children} }, grep{!$chld{$_}} @offsp;
  }
}
sub _DesFmt {
  my ($fmt, $arg) = @_;
  my $ph = 'PlAcEhOlDeR';
  if ($fmt =~ s/\%\[(.*?)\](N?)l/$ph/) {
    my ($re, $ncom) = (qr($1), $2);
    $CT = new ClearCase::Argv({autochomp=>1}) unless $CT;
    my @lb = grep /$re/, split / /, $CT->des([qw(-fmt %Nl)], $arg)->qx;
    my $lb = $ncom? join(' ', @lb) : @lb? '(' . join(', ', @lb) . ')' : '';
    $fmt =~ s/$ph/$lb/;
  }
  return $CT->des(['-fmt', $fmt], $arg)->qx;
}
sub _DepthGen {
  my ($ele, $dep, $sel, $verbose, $fmt, $gen) = @_;
  $gen = {} unless $gen;
  _Offspring($ele, $sel, $gen) if $verbose;
  if ($dep--) {
    return if defined $gen->{$sel}{parents};
    my @p = _Parents($sel, $ele);
    @{ $gen->{$sel}{parents} } = @p;
    $gen->{$sel}{labels} = _DesFmt($fmt, $sel) if $fmt;
    push @{ $gen->{$_}{children} }, $sel for @p;
    _DepthGen($ele, $dep, $_, $verbose, $fmt, $gen) for @p;
  } elsif ($fmt) {
    $gen->{$sel}{labels} = _DesFmt($fmt, $sel);
  }
  return $gen;
}
sub _RecOff {
  my ($ele, $sel, $fmt, $gen, $seen) = @_;
  return if $seen->{$sel}++;
  ($gen->{$sel}{labels}) = grep /\S/, _DesFmt($fmt, $sel);
  my %par = map{$_ => 1} @{ $gen->{$sel}{parents} }; # no duplicates
  push @{ $gen->{$sel}{parents} }, grep{!$par{$_}} _Parents($sel, $ele);
  _Offspring($ele, $sel, $gen);
  _RecOff($ele, $_, $fmt, $gen, $seen) for @{ $gen->{$sel}{children} };
}
sub _RecGen {
  my ($ele, $sel, $opt) = @_;
  my $fmt = $opt->{fmt} || ' %l';
  my $gen = _DepthGen($ele, $opt->{depth}, $sel, !$opt->{short}, $fmt);
  if ($opt->{offspring}) {
    my $seen = {};
    _RecOff($ele, $sel, $fmt, $gen, $seen)
  }
  return $gen;
}
sub _Ensuretypes {
  my @typ = ($EQHL, $PRHL); # Default value
  @typ = @{shift @_} if ref $_[0] eq 'ARRAY';
  my @vob = @_;
  my %cmt = ($EQHL => q(Equivalent increment),
	     $PRHL => q(Previous increment in a type chain),
	     $FCHL => q(Full Copy of increment));
  my $silent = $CT->clone({stdout=>0, stderr=>0});
  my $die = $CT->clone({autofail=>1});
  for my $t (@typ) {
    for my $v (@vob) {
      my $t2 = "$t\@$v";
      $die->mkhltype([qw(-shared -c), $cmt{$t}], $t2)->system
	if $silent->des(['-s'], "hltype:$t2")->system;
    }
  }
}
sub _Pfxmajminsfx {
  my $t = shift;
  if ($t =~ /^([\w.-]+[-_])(\d+)(?:\.(\d+))?(\@.*)?$/) {
    my $min = ($3 or '');
    my $sfx = ($4 or '');
    return ($1, $2, $min, $sfx);
  } else {
    warn Msg(
      'W', "$t doesn't match the pattern expected for an incremental type\n");
  }
}
sub _Nextinc {
  my $inc = shift;
  my ($pfx, $maj, $min, $sfx) = _Pfxmajminsfx($inc);
  return '' unless $pfx and $maj;
  my $count = defined($min)? $maj . q(.) . ++$min : ++$maj;
  return $pfx . $count . $sfx;
}
sub _Findnext {		# on input, the type exists
  my $c = shift;
  my @int = grep { s/^<- lbtype:(.*)$/$1/ }
    $CT->argv(qw(des -s -ahl), $PRHL, "lbtype:$c")->qx;
  if (@int) {
    my @i = ();
    for (@int) {
      push @i, _Findnext($_);
    }
    return @i;
  } else {
    return ($c);
  }
}
sub _Findfreeinc {	   # on input, the values may or may not exist
  my ($nxt, %n) = shift;
  while (my ($k, $v) = each %{$nxt}) {
    while ($CT->des(['-s'], "lbtype:$v")->stderr(0)->qx) { #exists
      my @cand = sort _Compareincs _Findnext($v);
      $v = _Nextinc($cand[$#cand]);
    }
    $n{$k} = $v;
  }
  while (my ($k, $v) = each %n) { $$nxt{$k} = $v }
}
sub _Wanted {
  my $path = File::Spec->rel2abs($File::Find::name);
  $path =~ s%\\%/%g if $^O =~ /MSWin32|Windows_NT/i;
  if (-f $_ || -l $_) {
    if (-r _) {
      # Passed all tests, put it on the list.
      $Xfer{$path} = $path;
    } else {
      warn Msg('E', "permission denied: $path");
    }
  } elsif (-d _) {
    if ($_ eq 'lost+found') {
      $File::Find::prune = 1;
      return;
    }
    # Keep directories in the list only if they're empty.
    opendir(DIR, $_) || warn Msg('E', "$_: $!");
    my @entries = readdir DIR;
    closedir(DIR);
    $Xfer{$path} = $path if @entries == 2;
  } elsif (! -e _) {
    die Msg('E', "no such file or directory: $path");
  } else {
    warn Msg('E', "unsupported file type: $path");
  }
}
sub _Yesno {
  my ($cmd, $fn, $yn, $test, $errmsg) = @_;
  my $ret = 0;
  my @opts = $cmd->opts;
  for my $arg ($cmd->args) {
    $cmd->opts(@opts); #reset
    if ($test) {
      my $res = $test->($arg);
      if (!$res) {
	warn ($res or Msg('E', $errmsg . '"' . $arg . "\".\n"));
	next;
      } elsif ($res == -1) { # Skip interactive part
	$ret |= $fn->($cmd);
	next;
      }
    }
    printf $yn->{format}, $arg;
    my $ans = <STDIN>; chomp $ans; $ans = lc($ans);
    $ans = $yn->{default} unless $ans;
    while ($ans !~ $yn->{valid}) {
      print $yn->{instruct};
      $ans = <STDIN>; chomp $ans; $ans = lc($ans);
      $ans = $yn->{default} unless $ans;
    }
    if ($yn->{opt}->{$ans}) {
      $cmd->opts(@opts, $yn->{opt}->{$ans});
      $cmd->args($arg);
      $ret |= $fn->($cmd);
    } else {
      $ret = 1;
    }
  }
  exit $ret;
}
use AutoLoader 'AUTOLOAD';

#############################################################################
# Usage Message Extensions
#############################################################################
{
  local $^W = 0;
  no strict 'vars';

  my $z = $ARGV[0] || '';
  $checkin = "\n* [-dir|-rec|-all|-avobs] [-ok] [-diff [diff-opts]] [-revert]";
  $lsgenealogy = "$z [-short] [-all] [-fmt format] [-obsolete] [-depth d]"
    . "\n[-offspring] pname ...";
  $mkbrtype = "\n* [-archive]";
  $mklabel = "\n* [-up] [-force] [-over type [-all]]";
  $mklbtype = "\n* [-family] [-increment] [-archive] [-fullcopy type] \n"
    . "[-config cr [-exclude vobs]]";
  $rmtype = "\n* [-family] [-increment]";
  $setcs = "\n* [-clone view-tag] [-expand] [-sync|-needed]";
  $mkview = "\n* [-clone view-tag [-equiv lbtype,timestamp]]";
  $describe = "\n* [-par/ents <n>] [-fam/ily <n>]";
  $rollout = "$z [-force] [-c comment] -to baseline brtype|lbtype";
  $rollback = "$z [-force] [-c comment] -to increment";
  $archive = "$z [-c comment|-nc] brtype|lbtype ...";
  $annotate = "\n* [-line|-grep regexp]";
  $synctree = "$z -from sbase [-c comment] [-quiet] [-force] [-rollback]"
    . "\n[-summary] [-label type] [pname ...]";
}

#############################################################################
# Command Aliases
#############################################################################
*co             = *checkout;
*ci		= *checkin;
*des            = *describe;
*desc           = *describe;
*lsg		= *lsgenealogy;
*lsge		= *lsgenealogy;
*lsgen		= *lsgenealogy;
*unco           = *uncheckout;
*ro             = *rollout;
*rb             = *rollback;
*ar             = *archive;
*arc            = *archive;
*arch           = *archive;
*an             = *annotate;
*ann            = *annotate;
*anno           = *annotate;
*st             = *synctree;
*sy             = *synctree;
*syn            = *synctree;
*sync           = *synctree;

1;

__END__

sub _Mkbco {
  use strict;
  use warnings;
  use File::Copy;
  my ($cmd, @cmt) = @_;
  my $rc = 0;
  my %pbrt = ();
  my $bt = $cmd->{bt};
  my @opts = $cmd->opts;
  if ($cmd->flag('nco')) { #mkbranch
    my @a = ($bt);
    push @a, $cmd->args;
    $cmd->args(@a);
    push @opts, @cmt;
    $cmd->opts(@opts);
    return $cmd->system;
  } elsif ($cmd->flag('branch')) { #co
    push @opts, @cmt;
    $cmd->opts(@opts);
    return $cmd->system;
  }
  die Msg('E', 'Element pathname required.') unless $cmd->args;
  foreach my $e ($cmd->args) {
    my $ver = $cmd->{ver};
    my $typ = $CT->des([qw(-fmt %m)], $e)->qx;
    if ($typ !~ /(branch|version)$/) {
      warn Msg('W', "Not a vob object: $e");
      $rc = 1;
      next;
    }
    if ($ver) {
      $ver = "/$ver" unless $ver =~ m%^[\\/]%;
      $e =~ s%\@\@.*$%%;
      my $v = $e;
      $ver = "$v\@\@$ver";
    } elsif ($e =~ m%^(.*?)\@\@.*$%) {
      $ver = $e;
      $e = $1;
      $ver =~ s%[\\/]$%%;
      $ver .= '/LATEST' if $typ eq 'branch';
    }
    if (!$ver or !$bt) {
      my $sel = $CT->ls(['-d'], $e)->qx;
      if ($bt) {
	$ver = $1 if $sel =~ /^(.*?) +Rule/;
      } elsif ($sel =~ /^(.*?) +Rule:.*-mkbranch (.*?)\]?$/) {
	($ver, $bt) = ($ver? $ver : $1, $2);
      }
    }
    if ($bt and _Checkcs($e)) {
      my $main = 'main';
      if ($CT->des(['-s'], "$e\@\@/main/0")->stderr(0)->stdout(0)->system) {
	$main = ($CT->lsvtree($e)->qx)[0];
	$main =~ s%^[^@]*\@\@[\\/](.*)$%$1%;
      }
      my $vob = $CT->des(['-s'], "vob:$e")->qx;
      my $re = _Pbrtype(\%pbrt, "$bt\@$vob") ?
	qr([\\/]${main}[\\/]$bt[\\/]\d+$) : qr([\\/]$bt[\\/]\d+$);
      if ($ver =~ m%$re%) {
	push @opts, @cmt, $e;
	$rc |= $CT->co(@opts)->system;
      } else {
	my @mkbcopt = @cmt? @cmt : qw(-nc);
	my $out = $cmd->flag('out');
	my $nda = $cmd->flag('ndata');
	copy($e, $out) or die Msg('E', "Failed to create $out: $!") if $out;
	push @mkbcopt, '-nco' if $out or $nda;
	if ($CT->mkbranch([@mkbcopt, '-ver', "/$main/0", $bt], $e)->system) {
	  $rc = 1;
	} else {
	  if ($out or $nda) {
	    my $e0 = "$e\@\@/$main/$bt/0";
	    $rc = $CT->co(['-nda', @cmt? @cmt : '-nc'], $e0)->system;
	  }
	  if ($ver !~ m%\@\@[\\/]${main}[\\/]0$%) {
	    my @o = ('-to', $e);
	    push @o, '-nda' if $out or $nda;
	    my $lrc = $CT->merge([@o], $ver)->stdout(0)->system;
	    unlink glob("$e.contrib*");
	    if ($ENV{FSCBROKER}) {
	      require ClearCase::FixSrcCont; #optional fix of source container
	      ClearCase::FixSrcCont::runfix($ver);
	    }
	    $rc |= $lrc;
	  }
	}
      }
    } else { # Ensure proper treatment of cascading branches
      my @args;
      push @args, @opts, @cmt;
      my $fn = ($cmd->prog())[1]; # Skip 'cleartool'
      if ($fn =~ /^mkb/ and $bt) { # May be abbreviated
	push @args, $bt;
	push @args, $e; # Ensure non empty array
	$rc |= $CT->mkbranch(@args)->system;
      } else {
	push @args, $e;
	$rc |= $CT->co(@args)->system;
      }
    }
  }
  return $rc;
}
sub _PreCi {
  use strict;
  use warnings;
  my ($ci, @arg) = @_;
  my $lsco = ClearCase::Argv->lsco([qw(-cview -s -d)])->stderr(1);
  my $res = $lsco->args(@arg)->qx;
  if (!$res or $res =~ /^cleartool: Error/m) {
    warn Msg('E', 'Unable to find checked out version for '
	       . join(', ', @arg) . "\n");
    return 0;
  }
  my $opt = $ci->{opthashre};
  return 1 unless $opt->{diff} || $opt->{revert};
  my $elem = $arg[0]; #Only one because of -cqe
  my $diff = $ci->clone->prog('diff');
  $CT = $ci->clone;
  $CT->autochomp(1);
  my $par = $CT->argv(qw(des -fmt %En@@%PVn), $elem)->qx;
  $par =~ s%\\%/%g;
  $diff->optsDIFF(q(-serial), $diff->optsDIFF);
  $diff->args($par, $elem);
  # Without -diff we only care about return code
  $diff->stdout(0) unless $opt->{diff};
  # With -revert, suppress msgs from typemgrs that don't do diffs
  $diff->stderr(0) if $opt->{revert};
  if ($diff->system('DIFF')) {
    return 1;
  } else {
    if ($opt->{revert}) { # unco instead of checkin
      _Unco(ClearCase::Argv->unco(['-rm'], $elem));
      return 0;
    } else { # -diff
      warn Msg('E', q(By default, won't create version with )
		 . q(data identical to predecessor.));
      return 0;
    }
  }
}
sub _Preemptcmt { #return the comments apart: e.g. mklbtype needs discrimination
  use File::Temp qw(tempfile);
  my ($cmd, $fn, $tst, $tnc) = @_; #parsed, 3 groups: cquery|cqeach nc c|cfile=s
  use warnings;
  use strict;
  my @opts = $cmd->opts;
  my ($ret, @mod, @copt) = 0;
  my ($cqf, $ncf, $cf) =
    ($cmd->flag('cquery'), $cmd->flag('nc'), $cmd->flag('c'));
  if (!$cqf and !$ncf and !$cf) {
    if (defined $ENV{_CLEARCASE_PROFILE}) { #ClearCase::Argv shift
      if (open PRF, "<$ENV{_CLEARCASE_PROFILE}") {
	while (<PRF>) {
	  if (/^\s*(.*?)\s+(-\w+)/) {
	    my ($op, $fg) = ($1, $2);
	    if (($op eq ($cmd->prog())[1]) or ($op eq '*')) {
	      if ($fg eq '-nc') {
		$ncf = 1;
	      } elsif ($fg eq '-cqe') {
		$cqf = 1;
		push @opts, '-cqe';
	      } elsif ($fg eq '-cq') {
		$cqf = 1;
		push @opts, '-cq';
	      }
	      last;
	    }
	  }
	}
	close PRF;
      }
    }
    if (!$cqf and !$ncf and !$cf) {
      my $re =
	qr/c[io]|check(in|out)|mk(dir|elem|(at|br|el|hl|lb|tr)type|pool|vob)/;
      if (($cmd->prog())[1] =~ /^($re)$/) {
	$cqf = 1;
	push @opts, '-cqe';
      } else {
	$ncf = 1;
      }
    }
  }
  if ($ncf or $cf) {
    if ($ncf) {
      $cmd->opts(grep !/^-nc(?:omment)?$/,@opts);
      if ($tst and $tnc) {
	my (@args1, @args) = $cmd->args;
	for (@args1) {
	  push @args, $_ if $tst->($cmd, $_);
	}
	exit 0 unless @args;
	$cmd->args(@args);
      }
      $ret = $fn->($cmd, qw(-nc));
    } else {
      my $skip = 0;
      for (@opts) {
	if ($skip) {
	  $skip = 0;
	  push @copt, $_;
	} else {
	  if (/^-c/) {
	    $skip = 1;
	    push @copt, $_;
	  } else {
	    push @mod, $_;
	  }
	}
      }
      $cmd->opts(@mod);
      $ret = $fn->($cmd, @copt);
    }
  } elsif ($cqf) {
    my $cqe = grep /^-cqe/, @opts;
    @opts = grep !/^-cq/, @opts;
    my @arg = $cmd->args;
    my $go = 1;
    while ($go) {
      $cmd->opts(@opts); #reset
      if ($cqe) {
	my $arg = shift @arg;
	$go = scalar @arg;
	next if $tst and !$tst->($cmd, $arg);
	$cmd->args($arg);
	print qq(Comments for "$arg":\n);
      } else {
	$go = 0;
	last if $tst and !$tst->($cmd, @arg); #None checked out
	print "Comment for all listed objects:\n";
      }
      my $cmt = '';
      while (<STDIN>) {
	last if /^\.$/;
	$cmt .= $_;
      }
      chomp $cmt;
      if ($cmt =~ /\n/) {
	my ($fh, $cfile) = tempfile();
	print $fh $cmt;
	close $fh;
	$ret |= $fn->($cmd, '-cfile', $cfile);
      } else {
	$ret |= $fn->($cmd, '-c', $cmt);
      }
    }
  }
  exit $ret;
}
sub _Unco {
  use warnings;
  use strict;
  my ($unco, $rc) = (shift, 0);
  $CT = ClearCase::Argv->new({autochomp=>1});
  for my $arg ($unco->args) { # Already sorted if several
    my $b0 = $CT->argv(qw(ls -s -d), $arg)->qx;
    $rc |= $unco->args($arg)->system;
    if ($b0 =~ s%^(.*)[\\/]CHECKEDOUT$%$1% and $b0 !~ m%@@/[^/]+$%) {
      opendir BR, $b0 or next;
      my @f = grep !/^\.\.?$/, readdir BR;
      closedir BR;
      $CT->argv(qw(rmbranch -f), $b0)->system
	if (scalar @f == 2) and $f[0] eq '0' and $f[1] eq 'LATEST';
    }
  }
  return $rc;
}
sub _Checkin {
  use strict;
  use warnings;
  my ($ci, @cmt) = @_;
  $ci->opts($ci->opts, @cmt);
  if ($ci->flag('from') and !$ci->flag('keep')) {
    my %kr = (yes => '-keep', no => '-rm');
    my %yn = (
      format   => q(Save private copy of "%s"?  [yes] ),
      default  => q(yes),
      valid    => qr/yes|no/,
      instruct => "Please answer with one of the following: yes, no\n",
      opt      => \%kr,
    );
    my $lsco = ClearCase::Argv->lsco([qw(-cview -s)]);
    $lsco->stderr(1);
    my $ok = sub { return $lsco->args(shift)->qx? 1:0 };
    my $err = 'Unable to find checked out version for ';
    my $run = sub { my $ci = shift; $ci->system };
    _Yesno($ci, $run, \%yn, $ok, $err); #only one arg: may exit
  } else {
    return $ci->system;
  }
}
# Input: lbtype type, either floating 'family' type, or fixed
# 'incremental'.
# Output: ordered list of short type names, as chained.
sub _EqLbTypeList {
  use strict;
  use warnings;
  my $top = shift;
  return unless $top;
  $top = "lbtype:$top" unless $top =~ /^lbtype:/;
  my $ct = ClearCase::Argv->new({autochomp=>1});
  my ($eq) = grep s/^-> (.*)$/$1/, $ct->des([qw(-s -ahl), $EQHL], $top)->qx;
  $_ = $eq? $eq : $top;
  my @list;
  do {
    push @list, $1 if /^lbtype:(.*?)(@.*)?$/;
    ($_) = grep s/^-> (.*)$/$1/, $ct->des([qw(-s -ahl), $PRHL], $_)->qx;
  } while ($_);
  return @list;
}
# Record the elements on the path to the argument, from 'mklabel -up'
# Issues: symbolic links, esp. cross-vob, relative or absolute, view extended
# path on UNIX or drive context on Windows/Cygwin; using -follow at entry
sub _Recpath {
  use File::Basename;
  use File::Spec::Functions qw(rel2abs catfile);
  my ($anc, $follow, $n, $stop) = @_;
  my $type = $CT->des([qw(-fmt %m)], $n)->qx;
  if ($type eq 'symbolic link') {
    if ($follow) {
      my $path = $CT->des([qw(-fmt %[slink_text]p)], $n)->qx;
      $path =~ y%\\%/% if MSWIN;
      if ($path =~ m%^/%) {
	if (MSWIN or CYGWIN) {
	  my $tag = $CT->des(['-s'], "vob:$n")->qx;
	  my $pfx = $1 if $n =~ m%^(.*?\Q$tag\E)%;
	  $path = catfile($pfx, $path);
	}
      } else {
	my $p = dirname($n);
	while ($path =~ /^\./) {
	  $path =~ s%^\./(.*)$%$1%;
	  $p = dirname($p) while $path =~ s%^\.\./(.*)$%$1%;
	  if ($path eq '.') {
	    $path = ''; last
	  }
	  if ($path eq '..') {
	    $path = ''; $p = dirname($p); last;
	  }
	  last if $path =~ m%^\.[^/]%;
	}
	$path = $path? catfile($p, $path) : $p;
      }
      if (!$stop) {
	my $tag = $CT->des(['-s'], "vob:$path")->qx;
	$stop = length($1) if $path =~ m%^(.*?\Q$tag\E)%;
      }
      _Recpath($anc, 1, $path, $stop);
      $stop = 0;
    }
  } elsif ($type !~ /version$/) {
    return; # Non reachable or dangling
  }
  my $pn = rel2abs($n); # if 'a/' with 'a' a symlink, yields 'a', but vob remote
  if (!$stop) {
    my $tag = $CT->des(['-s'], "vob:$n")->qx;
    $stop = length($1) if $pn =~ m%^(.*?\Q$tag\E)%;
  }
  $pn = $CT->des([(qw(-fmt %En))], $pn)->qx if $pn =~ /@/; #version ext. name
  my $dad = dirname($pn);
  return if length($dad) < $stop;
  $anc->{$dad}++;
  _Recpath($anc, 1, $dad, $stop);
}
sub _RecLock {
  my $obj = shift;
  my (@lock) = $CT->lslock([qw(-fmt %d\n%u\n%Nc)], $obj)->qx;
  my @args = ();
  if (@lock) {
    my $date = shift @lock;
    my $user = shift @lock;
    my @cmt;
    for (@lock) {
      if (m%^Locked except for users:\s+(.*)%) {
	push @args, '-nusers', grep{s/ /,/g} $1;
      } elsif (/^Locked for all users( \(obsolete\))?\.$/) {
	push @args, '-obs' if $1;
      } else {
	push @cmt, $_;
      }
    }
    unshift @cmt, "Relocked to mkhlink. Locked on $date by $user";
    push @args, '-c', join('\n',@cmt), $obj;
  }
  return @args;
}

=head1 NAME

ClearCase::Wrapper::MGi - Support for an alternative to UCM.

=head1 SYNOPSIS

This is an C<overlay module> for B<ClearCase::Wrapper> containing Marc
Girod's non-standard extensions. See C<perldoc ClearCase::Wrapper> (by
David Boyce) for more details.

The alternative to UCM consists in a novel branching model, and a concept
of incremental types.

=head1 CLEARTOOL EXTENSIONS

=over 2

=item * LSGENEALOGY

New command. B<LsGenealogy> is an alternative way to display the
version tree of an element. It will treat merge arrows on a par level
with parenthood on a branch, and will navigate backwards from the
version currently selected, to find what contributors took part in its
state.
This is thought as being particularly adapted to displaying the
bush-like structure characteristic of version trees produced under the
advocated branching strategy.

Flags:

=over 1

=item B<-all>

Show 'uninteresting' versions, otherwise skipped:

=over 1

=item - bearing no label

=item - not at a chain boundary.

=back

Note that a different algorithm is used with and without the C<-all> option.
The latter uses C<lsvtree> and may thus be slow on elements with a large
version tree. The former is thus more scalable.

=item B<-obsolete>

Add obsoleted branches to the search.

=item B<-short>

Skip displaying labels and 'labelled' versions and do not report
alternative paths or siblings.

=item B<-fmt>

Substitute to the default representation of every version (optionally
including labels), the output of C<des -fmt 'format' version>.

The indentation is preserved, but all the verbose annotations
(offspring, siblings, alternatives) are stripped (as in B<short>
mode).

=item B<-depth>

Specify a maximum depth at which to stop displaying the genealogy of
the element.

=item B<-offspring>

Print the offspring of the selected version (for every argument).
Offspring are not restricted by the I<depth> argument.

This option is compatible with B<-fmt>.

=back

=cut

sub lsgenealogy {
  use warnings;
  use strict;
  my %opt;
  GetOptions(\%opt, qw(short all fmt=s obsolete depth=i offspring));
  Assert(@ARGV > 1);		# die with usage msg if untrue
  die Msg('E', 'Incompatible flags: "short" and "fmt"')
    if $opt{short} and $opt{fmt};
  $opt{depth} = 0 if $opt{offspring} and !defined $opt{depth};
  shift @ARGV;
  my @argv = ();
  for (@ARGV) {
    $_ = readlink if -l && defined readlink;
    push @argv, MSWIN ? glob($_) : $_;
  }
  $CT = ClearCase::Argv->new({autofail=>0, autochomp=>1, stderr=>0});
  while (my $e = shift @argv) {
    my ($ver, $type) =
      $CT->des([qw(-fmt %En@@%Vn\n%m)], $e)->qx;
    if (!defined($type) or ($type !~ /version$/)) {
      warn Msg('W', "Not a version: $e");
      next;
    }
    $ver =~ s%\\%/%g;
    my $ele = $ver;
    $ele =~ s%^(.*?)\@.*%$1%; # normalize in case of vob root directory
    my $gen = (($opt{all} or $opt{fmt}) and defined $opt{depth})?
      _RecGen($ele, $ver, \%opt)
      : _Parsevtree($ele, $opt{obsolete}, $ver);
    _Printoffspring($ver, $gen, \%opt, 0) if $opt{offspring};
    _Setdepths($ver, 0, $gen);
    my %seen = ();
    _Printparents($ver, $gen, \%seen, \%opt, 0);
  }
  exit 0;
}

=item * CO/CHECKOUT

Supports the BranchOff feature, which you can set up via an attribute
in the config spec.  The rationale and the design are documented in:

L<http://www.cmcrossroads.com/cgi-bin/cmwiki/view/CM/BranchOffMain0>

Instead of branching off the selected version, the strategy is to
branch off the root of the version tree, copy-merging there from the
former.

This allows to avoid both merging back to /main or to a delivery
branch, and cascading branches indefinitely.  The logical version tree
is restituted by navigating the merge arrows, to find all the direct
or indirect contributors.

The creation of cascading branches is preserved if specified by the
config spec, unless in a I<BranchOff> config spec, in which case it
doesn't make sense.

Flag:

=over 1

=item B<-ver/sion>

Ignored under a I<BranchOff> config spec,
but the version specified in the pname is anyway obeyed,
as a branch may always be spawn.

=back

=cut

sub checkout {
  use warnings;
  use strict;
  map { $_ = readlink if -l && defined readlink } @ARGV[1..$#ARGV];
  # Duplicate the base Wrapper checkout functionality.
  my @agg = grep /^-(?:dir|rec|all|avo)/, @ARGV;
  die Msg('E', "mutually exclusive flags: @agg") if @agg > 1;
  if (@agg) {
    # Remove the aggregation flag, push the aggregated list of
    # not-checked-out file elements onto argv, and return.
    my %opt;
    GetOptions(\%opt, qw(directory recurse all avobs ok));
    my @added = AutoNotCheckedOut($agg[0], $opt{ok}, 'f', @ARGV);
    push(@ARGV, @added);
  }
  ClearCase::Argv->ipc(1) unless ClearCase::Argv->ctcmd(); #set by the user
  $CT = ClearCase::Argv->new({autochomp=>1});
  my $co = ClearCase::Argv->new(@ARGV);
  $co->parse(qw(reserved unreserved nmaster out=s ndata ptime nwarn
		version branch=s query nquery usehijack
		cquery|cqeach nc c|cfile=s));
  my ($unsup) = grep /^-/, $co->args;
  die Msg('E', qq(Unrecognized option "$unsup")) if $unsup;
  if (MSWIN) {
    my @args = $co->args;
    map { $_ = glob($_) } @args;
    $co->args(@args);
  }
  _Preemptcmt($co, \&_Mkbco);
}

=item * MKBRANCH

Actually a special case of checkout.

Flag:

=over 1

=item B<-nco>

Special case of reverting to the default behaviour,
as this cannot reasonably be served in a new branch under BranchOff
(no version to which to attach the I<Merge> hyperlink).

=back

=cut

sub mkbranch {
  use warnings;
  use strict;
  map { $_ = readlink if -l && defined readlink } @ARGV[1..$#ARGV];
  my @agg = grep /^-(?:dir|rec|all|avo)/, @ARGV;
  die Msg('E', "mutually exclusive flags: @agg") if @agg > 1;
  if (@agg) {
    # Remove the aggregation flag, push the aggregated list of
    # not-checked-out file elements onto argv, and return.
    my %opt;
    GetOptions(\%opt, qw(directory recurse all avobs ok));
    my @added = AutoNotCheckedOut($agg[0], $opt{ok}, 'f', @ARGV);
    push(@ARGV, @added);
  }
  ClearCase::Argv->ipc(1) unless ClearCase::Argv->ctcmd();
  $CT = ClearCase::Argv->new({autochomp=>1});
  my $ver;
  GetOptions("version=s" => \$ver);
  my $mkbranch = ClearCase::Argv->new(@ARGV);
  $mkbranch->parse(qw(nwarn nco ptime cquery|cqeach nc c|cfile=s));
  my @args = $mkbranch->args;
  my $bt = shift @args;
  map { $_ = glob($_) } @args if MSWIN;
  $bt =~ s/^brtype:(.*)$/$1/;
  my %v;
  if ($bt =~ /\@/) {
    $v{''} = 1;
  } else {
    $v{$CT->des([qw(-fmt @%n)], "vob:$_")->stderr(0)->qx}++ for @args;
  }
  for (keys %v) {
    die "\n" if $CT->des(['-s'], "brtype:$bt$_")->stdout(0)->system;
  }
  $mkbranch->args(@args);
  $mkbranch->{bt} = $bt;
  $mkbranch->{ver} = $ver;
  _Preemptcmt($mkbranch, \&_Mkbco);
}

=item * DIFF

Evaluate the predecessor from the genealogy, i.e. take into account merges on
an equal basis as parents on the same physical branch.
In case there are multiple parents, consider the one on the same branch as
'more equal than the others' (least surprise principle).

Preserve the (Wrapper default) assumption of a B<-pred> flag, if only one
argument is given.

=cut

sub diff {
  use warnings;
  use strict;
  for (@ARGV[1..$#ARGV]) {
    $_ = readlink if -l && defined readlink;
  }
  push(@ARGV, qw(-dir)) if @ARGV == 1;
  my $limit = 0;
  if (my @num = grep /^-\d+$/, @ARGV) {
    @ARGV = grep !/^-\d+$/, @ARGV;
    die Msg('E', "incompatible flags: @num") if @num > 1;
    $limit = -int($num[0]);
  }
  my $diff = ClearCase::Argv->new(@ARGV);
  $diff->autochomp(1);
  $diff->ipc(1) unless $diff->ctcmd(1);
  $diff->parse(qw(options=s serial_format|diff_format|window
		  graphical|tiny|hstack|vstack|predecessor));
  my @args = $diff->args;
  my @opts = $diff->opts;
  my $pred = grep /^-(pred)/, @opts;
  my $auto = grep /^-(?:dir|rec|all|avo)/, @args;
  my @elems = AutoCheckedOut(0, @args);
  return 0 unless $pred or $auto or (scalar @elems == 1); #fallback!
  $diff->opts(grep !/-pred/, @opts) if $pred;
  $diff->args(@elems);
  $CT = $diff->clone();
  my $rc = 0;
  for my $e (@elems) {
    my ($ele, $ver, $type) =
      $CT->argv(qw(des -fmt), '%En\n%En@@%Vn\n%m', $e)->qx;
    if (!defined($type) or ($type !~ /version$/)) {
      warn Msg('W', "Not a version: $e");
      next;
    }
    $ele =~ s%\\%/%g;
    $ver =~ s%\\%/%g;
    my $bra = $1 if $ver =~ m%^(.*?)/(?:\d+|CHECKEDOUT)$%;
    my $gen = _DepthGen($ele, $limit + 1, $ver);
    my $p = $gen->{$ver}{'parents'};
    $p = $gen->{$p->[0]}{'parents'} while $p and $limit--;
    if (!($p and @{$p})) {
      warn Msg('E', "No predecessor version to compare to: $e");
      $rc = 1;
      next;
    }
    my ($brp) = grep { m%^\Q$bra\E/\d+$% } @{$p};
    $ver = $ele if $ver =~ m%/CHECKEDOUT$%;
    $rc |= $diff->args($brp? $brp : $p->[0], $ver)->system;
  }
  exit $rc;
}

=item * UNCHECKOUT

The wrapper implements the functionality commonly provided by a trigger,
to remove the parent branch if it has no checkouts, no sub-branches, and
no remaining versions, while unchecking out version number 0.

=cut

sub uncheckout {
  use warnings;
  use strict;
  my %opt;
  GetOptions(\%opt, qw(ok)) if grep /^-(dif|ok)/, @ARGV;
  for (@ARGV[1..$#ARGV]) {
    $_ = readlink if -l && defined readlink;
  }
  ClearCase::Argv->ipc(1) unless ClearCase::Argv->ctcmd(1);
  my $unco = ClearCase::Argv->new(@ARGV);
  $unco->parse(qw(keep|rm cact cwork));
  $unco->optset('IGNORE');
  $unco->parseIGNORE(qw(c|cfile=s cquery|cqeach nc));
  $unco->args(sort {$b cmp $a} AutoCheckedOut($opt{ok}, $unco->args));
  if ($unco->flag('keep')) {
    exit _Unco($unco);
  } else {
    my %kr = (yes => '-keep', no => '-rm');
    my %yn = (
      format   => q(Save private copy of "%s"?  [yes] ),
      default  => q(yes),
      valid    => qr/yes|no/,
      instruct => "Please answer with one of the following: yes, no\n",
      opt      => \%kr,
    );
    my $lsco = ClearCase::Argv->lsco([qw(-cview -s)]);
    $lsco->stderr(1);
    my $dm = ClearCase::Argv->des([qw(-fmt %m)]);
    $dm->stderr(1);
    my $ok = sub {
      my $e = shift;
      return -1 if $dm->args($e)->qx =~ /^directory/;
      return $lsco->args($e)->qx? 1:0;
    };
    my $err = 'Unable to find checked out version for ';
    _Yesno($unco, \&_Unco, \%yn, $ok, $err);
  }
}

=item * MKLBTYPE

Extension: families of types, with a chain of fixed types, linked in a
succession, and one floating type, convenient for use in config specs.
One application is incremental types, applied only to modified versions,
allowing however to simulate full baselines.
Such a functionality is implemented as part of UCM, for fixed types,
and I<magic> config specs. The wrapper offers thus something similar
on base ClearCase.

This wrapper also includes a modified version of the extension for
global types originally proposed in C<ClearCase::Wrapper::DSB>. In the
realm of an admin vob, types are created global by default. This
implementation makes the feature configurable, via a
C<$ClearCase::Wrapper::MGi::global> variable set in
C<.clearcase_profile.pl>, so that a user is not forced to obey an
injonction from (possibly other site) administrators.

The current baseline is embodied with floating labels, which are moved
over successive versions. The first pair of a floating and a fixed
type is created with the B<-fam/ily> flag. Further fixed types are
created with the B<-inc/rement> flag.

Types forming a family are related with hyperlinks of two types:

=over 1

=item B<EqInc>

Equivalent incremental fixed type. A I<fixed> (i.e. which by
convention, will not been I<moved>), I<sparse> (i.e. applied only to
changes) type. This helps to mark the history of application of the
I<floating> type, which is also a I<full> one, for reproducibility
purposes.

=item B<PrevInc>

Previous incremental fixed type.

=back

Attributes are created of a per label family type, and are used to
mark the deletion of labels applied at a previous increment.  The
attribute type for family lbtype I<XXX> is I<RmXXX>, and the value is
the numeric (treated as I<real>) value of the increment.

Flags:

=over 1

=item B<-fam/ily>

Create two label types, linked with an B<EqInc> hyperlink.
The first, given as argument, will be considered as an alias for successive
increments of the second. It is the I<family> type.
The name of the initial incremental type is this of the I<family> type, with
a suffix of I<_1.00>.

Also create a I<RmLBTYPE> attribute type to record removals of labels.

For lbtypes, if the floating type was previously archived (e.g. to
deactivate config spec rules), then the command I<revives> the type
hidden as part of archiving (and not applied anywhere). The new
equivalent fixed type is the one following the last equivalent type,
which is however B<not> set as its I<previous> increment.

=item B<-inc/rement>

Create a new increment of an existing label type family, given as argument.
This new type will take the place of the previous increment, as the
destination of the B<EqInc> hyperlink on the I<family> type.
It will have a B<PrevInc> hyperlink pointing to the previous increment in
the family.

For lbtypes, if the floating type was previously archived, then the
behavior reverts to the B<-fam/ily> one.  This means that an archived
label type may be I<incremented>. This however amounts to a new
creation and is only provided as a convenience (no need to remember
the state of the family--whether it was rolled out and archived or
not).

=item B<-arc/hive>

Rename the current type to an I<archive> value (name as prefix, and a
numeral suffix. Initial value: I<-001>), create a new type, and make the
archived one its predecessor, with a B<PrevInc> hyperlink.
Comments go to the type being archived.

The implementation is largely shared with I<mkbrtype>.

For label types, the newly created type is hidden away (with a suffix
of I<_0>) and locked. It is being restored the next time C<mklbtype -fam>
is given for the same name.

=item B<-glo/bal>

Support for global family types is preliminary.

=item B<-con/fig>

Make or increment lbtypes in all vobs used by a config record.

=item B<-exc/lude>

When using a config record, exclude comma separated vobs for label
type creation.

=item B<-full/copy>

Create a new type, while is applied to all versions which bore labels
of a floating type, at the time of a given increment.

The type is created and applied only in one vob, even if the original
type was global.

This option is only compatible, among the extensions, with the
B<-family> flag (optional).

It is also incompatible with B<-replace> (the implementation was not
considered worth the while).

=back

=cut

sub _GenMkTypeSub {
  use strict;
  use warnings;
  use Cwd;
  my ($type, $Name, $name) = @_;
  return sub {
    my ($ntype, @cmt) = @_;
    my $rep = $ntype->{rep};
    $CT = new ClearCase::Argv({autochomp=>1});
    my @args = $ntype->args;
    my %opt = %{$ntype->{fopts}};
    my $silent = $CT->clone({stdout=>0});
    my (%vob, $unkvob, %fcpy);
    /\@(.*)$/? $vob{$1}++ : $vob{'.'}++ for @args;
    my @vob = keys %vob;
    if (my $inc = $opt{fullcopy}) { #if fail, fail early
      $inc =~ s/^lbtype://;
      my $lbinc = "lbtype:$inc";
      die Msg('E', "'$inc' must be an incremental fixed label type")
	unless grep /^<-/, $CT->des([qw(-s -ahl), "$EQHL,$PRHL"], $lbinc)->qx;
      die Msg('E', 'Only one lbtype for full copy') if @args > 1;
      my ($base, $nr, $vob) = $inc =~ /^(.*)_(.*?)(?:@(.*))?$/;
      if ($vob) {
	die Msg('E', "Conflicting vob specifications: '$vob[0]' and '$vob'")
	  if $vob[0] ne '.' and $vob[0] ne $vob;
	$fcpy{vob} = $vob;
	$vob[0] = $vob;
	$args[0] .= "\@$vob" unless $args[0] =~ /@/;
      } else {
	$fcpy{vob} = $vob[0] if $vob[0] ne '.';
      }
      $fcpy{base} = $base;
      $fcpy{nr} = $nr;
      $fcpy{lbinc} = $lbinc;
    }
    if ($opt{config}) {
      die Msg('E', 'Only one lbtype per config record') if @args > 1;
      die Msg('E', 'Incompatible flags: "-config" and "-archive"')
	if $opt{archive};
      die Msg('E', 'Incompatible flags: "-config" and "-replace"') if $rep;
      my $cr = $opt{config};
      my $fail = $CT->clone({autofail=>1});
      my $mvob = $fail->des(['-s'], "vob:$cr")->qx;
      die Msg('E', qq(Vob specification in lbtype not allowed with "-config"))
	if $args[0] =~ /\@.*$/;
      my %vbs;
      my @dir = $CT->catcr([qw(-flat -s -type d -nxn)], $cr)->qx;
      die "\n" if grep /^</, @dir; #one vob not mounted
      $vbs{$CT->des(['-s'], "vob:$_")->stderr(0)->qx}++ for @dir;
      delete $vbs{$mvob};
      if ($opt{exclude}) {
	for (split /,/, $opt{exclude}) {
	  die Msg('E', 'Cannot exclude the vob of the cr') if $_ eq $mvob;
	  delete $vbs{$_};
	}
      }
      $vob[0] = $mvob if $vob[0] eq '.'; #override the current vob as default
      push @vob, keys %vbs;
    }
    for (@vob) { #Diagnose all the errors, even if one is enough to fail
      $unkvob++ if $silent->argv(qw(des -s), "vob:$_")->system;
    }
    return 1 if $unkvob;
    if ($ClearCase::Wrapper::MGi::global and !$ntype->flag('global')) {
      my %avob;
      for my $v (@vob) {
	my ($hl) = grep s/^-> (?:vob:)(.*)$/$1/,
	  $CT->desc([qw(-s -ahl AdminVOB), "vob:$v"])->qx;
	$avob{$v} = $hl if $hl;
      }
      if (scalar keys %avob) {
	$ntype->opts('-global', $ntype->opts);
	for (@vob) {	   #Fix the vobs, to ensure the metadata types
	  $_ = $avob{$_} if $avob{$_};
	}
	for (@args) { #Fix the types, to create them in the admin vob(s)
	  $_ = $1 . $avob{$2} if /^(.*\@)(.*)$/ and $avob{$2};
	}
	warn Msg('W', "making global type(s) @args");
      }
    }
    my $rc = 0;
    if (%opt and grep !/^fullcopy$/, keys %opt) {
      map { s/^$type://; $_ } @args;
      if ($opt{increment}) { # lbtypes only
	my @t = @args;
	if ($opt{config}) {
	  @t = ();
	  my $lt = (split /\@/, $args[0])[0];
	  push @t, "${lt}\@$_" for @vob;
	  $args[0] = $t[0]; # Only one arg if config, maybe not in current vob
	}
	my @new = grep{$silent->des(['-s'], "lbtype:$_")->stderr(0)->system} @t;
	if (@new) {
	  {no warnings qw(uninitialized); map{s/^(.*?)(\@.*)?$/${1}_0$2/} @new}
	  my @arc = grep {$CT->des(['-s'], "lbtype:$_")->stderr(0)->qx} @new;
	  die Msg('E', 'Cannot process a mix of active and archived types')
	    if @arc and scalar @arc != scalar @t;
	  if (@arc) {
	    undef $opt{increment};
	    $opt{family} = 1;
	  } elsif (@new == @t) {
	    die Msg('E', 'Use -fam to create the family types');
	  } else {
	    $args[0] =~ s/\@.*$//;
	    my $vobs = join ', ', grep s/^.*\@//, @new;
	    die Msg('E', "No '$args[0]' in $vobs. Forgot an '-exc' option?");
	  }
	} else {
	  my @mst = map{$CT->des([qw(-fmt %[master]p)], "lbtype:$_")->qx} @t;
	  #In case of global types, get the servers, then the vobs and replicas
	  my @lrep = map{$CT->des([qw(-fmt %[replica_name]p)], "vob:$_")->qx}
	    grep s/^.*?\@//, map{$CT->des([qw(-fmt %Xn)], "lbtype:$_")->qx} @t;
	  my @nlm; #non locally mastered types
	  for (@mst) {
	    my $lr = shift @lrep;
	    push @nlm, shift(@t) unless /^\Q$lr\E\@/;
	  }
	  die Msg('E', "Cannot increment non locally mastered types: @nlm")
	    if @nlm;
	}
      }
      if (!$opt{family} and !$opt{config} and !$ntype->flag('global')) {
	my @glb = grep /^global/,
	  map{$CT->des([qw(-fmt %[type_scope]p)], "$type:$_")->qx} @args;
	die Msg('E', 'Cannot process a mix of global and ordinary types')
	  if @glb and scalar @glb != scalar @args;
	if (@glb) {
	  $ntype->opts('-global', $ntype->opts);
	  @vob = (); #The types were already created
	}
      }
      _Ensuretypes(@vob);
      if ($rep) {
	@args = grep { $_ = $CT->des([qw(-fmt %Xn)], "$type:$_")->qx } @args;
	exit 1 unless @args;
	if ($opt{family}) {
	  my @a = ();
	  my $gflg = (grep /^-glo/, $ntype->opts)? '-glo' : '-ord';
	  foreach my $t (@args) {
	    if ($CT->des([qw(-s -ahl), $EQHL], $t)->stderr(0)->qx) {
	      warn Msg('E', "$t is already a family type");
	      if ($t =~ s/^lbtype:(.*)$/$1/) {
		my $att = "Rm$t";
		$CT->mkattype([qw(-vtype real -c), q(Deleted in increment),
			       $gflg], "$att")->stderr(0)->system;
	      }
	    } else {
	      push @a, $t;
	    }
	  }
	  exit 1 unless @a;
	  my %pair = ();
	  foreach (@a) {
	    $pair{"$1$2"} = "${1}_1.00$2" if /^$type:(.*?)(@.*)$/;
	  }
	  _Findfreeinc(\%pair);
	  $ntype->args(values %pair);
	  $ntype->opts(@cmt, $ntype->opts);
	  $rc = $ntype->system;
	  map {
	    if (defined($pair{$_})) {
	      my $inc = "$type:$pair{$_}";
	      $silent->mkhlink([$EQHL], "$type:$_", $inc)->system;
	      if ($type eq 'lbtype') {
		my $att = "Rm$_";
		$CT->mkattype([qw(-vtype real -c), q(Deleted in increment),
			       $gflg], "$att")->stderr(0)->system;
	      }
	    }
	  } keys %pair;
	} elsif ($opt{archive}) {
	  $ntype->opts('-nc', $ntype->opts);
	  foreach my $t (@args) {
	    my ($pfx, $vob) = $t =~ /^$type:(.*?)(@.*)$/;
	    my ($prev) = grep s/^-> $type:(.*?)@.*/$1/,
	      $CT->des([qw(-s -ahl), $PRHL], $t)->stderr(0)->qx;
	    my $arc;
	    if ($prev) {
	      if (my ($pfx, $nr) = $prev =~ /^(.*-)(\d+)$/) {
		$arc = $pfx . $nr++;
	      } else {
		$arc = $prev . '-001';
	      }
	    } else {
	      $arc = $pfx . '-001';
	    }
	    ($pfx, my $nr) = $arc =~ /^(.*-)(\d+)$/;
	    while ($CT->des(['-s'], "$type:${arc}$vob")->stderr(0)->qx) {
	      $arc = $pfx . $nr++;
	    }
	    if ($CT->lslock(['-s'], $t)->qx and $CT->unlock($t)->system) {
	      warn Msg('E', "Cannot unlock: cannot rename!\n");
	      $rc = 1;
	      next;
	    }
	    my @cpy = grep {s/^<- (.*)$/$1/}
	      $CT->des([qw(-s -ahl GlobalDefinition)], $t)->qx
		if grep /^-glo/, $ntype->opts;
	    if ($CT->rename($t, $arc)->system) {
	      $rc = 1;
	      next;
	    }
	    $ntype->args($t);
	    $ntype->system;
	    for (@cpy) {
	      $silent->cptype($t, $_)->system;
	      $silent->mkhlink(['GlobalDefinition'], $_, $t)->system;
	    }
	    my $at = "$type:${arc}$vob";
	    $silent->mkhlink([$PRHL], $t, $at)->system;
	    $CT->chevent([@cmt], $at)->stdout(0)->system
	      unless $cmt[0] and $cmt[0] =~ /^-nc/;
	    if ($type eq 'lbtype') {
	      my $t0 = $t;
	      $t0 =~ s/^lbtype:(.*?)(@.*)$/lbtype:${1}_0$2/;
	      $CT->rename($t, $t0)->system;
	      $arc = "lbtype:$arc$vob";
	      my ($eq) = grep s/^-> (.*)/$1/,
		$CT->des([qw(-s -ahl), $EQHL], $arc)->stderr(0)->qx;
	      my @arg = ($t0, $arc);
	      push @arg, $eq if $eq;
	      $CT->lock(@arg)->stderr(0)->system;
	    }
	  }
	} else {		# increment
	  die Msg('E', "Incompatible flags: replace and incremental");
	}
      } else {
	my @a = @args;
	if ($opt{family}) {
	  map { $_ = "$type:$_" } @a;
	  die Msg('E', "Some types already exist among @args")
	    unless $silent->des(['-s'], @a)->stderr(0)->system;
	  my @opts = $ntype->opts();
	  my (%pair, @skip, %glo) = ();
	  if ($opt{config}) {
	    $args[0] .= '@' . shift @vob;
	    push @opts, '-glo' unless grep(/^-glo/, @opts);
	  }
	TYPE: foreach my $t (@args) {
	    if ($t =~ /^(.*?)(@.*)?$/) {
	      my ($pfx, $sfx) = ($1, $2?$2:'');
	      if ($type eq 'lbtype') {
		my $t0 = "lbtype:${pfx}_0$sfx";
		if ($CT->des(['-s'], $t0)->stderr(0)->qx) {
		  my $g0 =
		    $CT->des([qw(-fmt %[type_scope]p)], $t0)->qx eq 'global';
		  # test before unlocking, and record the vobs where linked
		  if ($opt{config} and $g0) {
		    $g0 = [$CT->des([qw(-s -ahl GlobalDefinition)], $t0)->qx];
		    die Msg('E', qq("$t" conflicts with an archived type))
		      if grep m%/\Q$vob[0]\E$%, @{$g0};
		  }
		  _Wrap('unlock', $t0);
		  my $lbt = "lbtype:$t";
		  $CT->rename($t0, $lbt)->stderr(0)->system
		    and die Msg('E', qq(Failed to restore "$t0" into "$t".));
		  if ($opt{config}) {
		    my %already;
		    if ($g0) {
		      $already{$_}++ for grep {s%^.*\@(.*)$%$1%} @{$g0};
		    } else {
		      $CT->mklbtype([qw(-rep -glo)], $lbt)->system
		    }
		    # Fix the copies, because we'll skip the type creation
		    for my $v (@vob[1..$#vob]) {
		      next if $already{$v};
		      my $cpy =  (split /\@/, $lbt)[0] . "\@$v";
		      $silent->cptype($lbt, $cpy)->system;
		      $silent->mkhlink(['GlobalDefinition'], $cpy, $lbt)->system;
		    }
		  }
		  push @skip, $t;
		  $glo{$t} = 1 if $g0 and !grep(/^-glo/, @opts);
		  if (my ($p) = grep s/^-> (.*)$/$1/,
		      $CT->des([qw(-s -ahl), $PRHL], "lbtype:$t")->qx) {
		    my ($e) = grep s/^-> lbtype:(.*)$/$1/,
		      $CT->des([qw(-s -ahl), $EQHL], $p)->qx;
		    $pair{$t} = $e || "${pfx}_1.00$sfx";
		  } else {
		    $pair{$t} = "${pfx}_1.00$sfx";
		  }
		} else {
		  $pair{$t} = "${pfx}_1.00$sfx";
		}
	      } else {
		$pair{$t} = "${pfx}_1.00$sfx";
	      }
	    }
	  }
	  if (@skip) {
	    my $sk = '^(?:' . join('|', @skip) . ')$'; #Should use \Q...\E
	    @a = grep !/$sk/, @args;
	  } else {
	    @a = @args;
	  }
	  if (@a) {
	    $ntype->args(@a);
	    $ntype->opts('-nc', @opts);
	    $ntype->system;
	  }
	  if (%pair) {
	    _Findfreeinc(\%pair);
	    for my $t (keys %pair) {
	      next unless defined $pair{$t};
	      my @o = @opts;
	      push @o, '-glo' if $glo{$t};
	      $ntype->args($pair{$t});
	      $ntype->opts(@cmt, @o);
	      $ntype->system;
	      my $inc = "$type:$pair{$t}";
	      my $tt = $CT->des([qw(-fmt %Xn)], "$type:$t")->qx;
	      $silent->mkhlink([$EQHL, $tt], $inc)->system;
	      next if $type eq 'brtype';
	      if ($glo{$t}) { # If restored type, otherwise handle all later
		my @tvob = grep {s/^<- lbtype:.*?\@(.*)$/$1/}
		    $CT->des([qw(-s -ahl GlobalDefinition)], $tt)->qx;
		for my $v (@tvob) {
		  my ($cpy) = ($inc =~ /^(.*?\@)/);
		  $cpy .= $v;
		  _Wrap('cptype', $inc, $cpy);
		}
	      }
	      unshift @o, q(Deleted in increment);
	      $CT->mkattype([qw(-vty real -c), @o], "Rm$t")->stderr(0)->system;
	    }
	    if ($opt{config} and @vob) {
	      for my $a (@a) { # restored types are skipped from these
		my $src = "lbtype:$a";
		for my $v (@vob) {
		  my $cpy =  (split /\@/, $src)[0] . "\@$v";
		  _Wrap('cptype', $src, $cpy);
		}
	      }
	    }
	  }
	} elsif ($opt{increment}) { # increment
	  map {($_) = grep s/^$type://,
		 $CT->des([qw(-fmt %Xn)], "$type:$_")->qx} @args;
	  my %targ;		#target vobs per type
	  if ($opt{config}) {
	    my ($tn, $tv) = split /\@/, $args[0];
	    die Msg('E', qq("$tn" is "administered" from another vob))
	      if $tv ne $vob[0];
	    shift @vob; # Retain only the vobs where to copy
	  } else {
	    my $cvob = $CT->des(['-s'], 'vob:.')->stderr(0)->qx;
	    for (@args) {
	      my $mvob = $1 if /\@(.*)$/;
	      my $lvob = (shift(@a) =~ /\@(.*)$/)?
		$CT->des(['-s'], "vob:$1")->qx : $cvob;
	      $targ{$_} = $lvob if $lvob and $lvob ne $mvob;
	    }
	  }
	  $ntype->opts(@cmt, $ntype->opts);
	  my $lct = ClearCase::Argv->new(); #Not autochomp
	  my ($fl, $loaded) = $ENV{FORCELOCK};
	INCT: for my $t (@args) {
	    my ($pt, $lck) = "$type:$t";
	    if (!$CT->des(['-s'], $pt)->stderr(0)->qx) {
	      warn Msg('E', qq($Name type not found: "$t"));
	      next;
	    }
	    my ($pair) = grep s/^\s*(.*) -> $type:(.*)\@(.*)$/$1,$2,$3/,
	      $CT->des([qw(-l -ahl), $EQHL], $pt)->stderr(0)->qx;
	    my ($hlk, $prev, $vob) = split /,/, $pair if $pair;
	    if (!$prev) {
	      warn Msg('E', "Not a family type: $t");
	      next INCT;
	    }
	    my $lbt = "lbtype:$t";
	    if ($CT->lslock(['-s'], $lbt)->stderr(0)->qx) {
	      $lck = 1; #remember to lock the previous equivalent back
	       #This should happen as vob owner, to retain the timestamp
	      _Wrap('unlock', $lbt); # Will unlock both types
	    }
	    if ($opt{config} and @vob) {
	      $silent->mklbtype([qw(-rep -glo)], $t)->system
		unless $CT->des([qw(-fmt %[type_scope]p)], $lbt)->qx eq 'global';
	      my %already;
	      $already{$_}++ for grep {s%^.*\@(.*)$%$1%}
		$CT->des([qw(-s -ahl GlobalDefinition)], $lbt)->qx;
	      my $t1 = (split /\@/, $lbt)[0];
	      for my $v (@vob) {
		next if $already{$v};
		my $cpy =  "$t1\@$v";
		_Wrap('cptype', $lbt, $cpy);
	      }
	      if (grep !/^-glo/, $ntype->opts) {
		my @opts = $ntype->opts;
		push @opts, '-glo';
		$ntype->opts(@opts);
	      }
	    }
	    if ($prev =~ /^(.*)_(\d+)(?:\.(\d+))?$/) {
	      my ($base, $maj, $min, $new) = ($1, $2, $3);
	      my $ext = ($t =~ /^.*(@.*)$/)? $1 : '';
	      my $p1 = $prev . $ext;
	      do {
		$new = "${base}_" .
		  (defined($min)? $maj . '.' . ++$min : ++$maj);
		$new .= $ext;
	      } while $CT->des(['-s'], "$type:$new")->stderr(0)->qx;
	      $ntype->args($new)->system and exit 1;
	      $silent->rmhlink($hlk)->system;
	      $silent->mkhlink(['-nc', $EQHL,
			    "$type:$t"], "$type:$new")->system;
	      $silent->mkhlink(['-nc', $PRHL,
			    "$type:$new"], "$type:$p1")->system;
	      if (my $v = $targ{$t}) {
		my $t1 = "$type:$new";
		my $t2 = "$type:${1}$v" if $new =~ /^(.*?\@)/;
		$silent->cptype($t1, $t2)->system;
		$silent->mkhlink(['GlobalDefinition'], $t2, $t1)->system;
	      }
	      if ($opt{config} and @vob) { # Only lbtypes
		my $lbt = "lbtype:$new";
		my $lbt1 = "lbtype:$1" if $new =~ /^(.*?\@)/;
		for my $v (@vob) {
		  my $cpy =  "$lbt1$v";
		  _Wrap('cptype', $lbt, $cpy);
		}
	      }
	      if ($lck) {
		_Wrap('lock', "lbtype:$prev\@$vob") and die "\n";
	      }
	    } else {
	      warn Msg('W',qq(Previous increment non suitable in $t: "$prev"));
	    }
	  }
	}
      }
    } else {			# no inc/arc/fam option
      if ($fcpy{vob}) {
	$args[0] .= "\@$fcpy{vob}" if $args[0] !~ /@/; #one single arg
      }
      if ($rep) {
	$ntype->opts(@cmt, '-replace', $ntype->opts);
	map { $_ = "$type:$_" unless /^$type:/ } @args;
	my @a = $CT->des([qw(-fmt %Xn)], @args)->stderr(0)->qx;
	if (@a) {
	  my @link;
	  if ($ntype->flag('global')) { # replace also the equivalent types
	    my @eq = grep s/^-> (.*)$/$1/,
	      $CT->des([qw(-s -ahl)], $EQHL, @a)->qx;
	    push @args, @eq;
	    $ntype->args(@args);
	  } else { # remove the hyperlinks, i.e. make the types 'non-family'
	    @link = grep s/^\s*(.*) -> .*$/$1/,
	      $CT->des([qw(-l -ahl)], "$EQHL,$PRHL", @a)->qx;
	  }
	  $rc = $ntype->system; # may fail because of restrictions: first
	  $rc = $CT->rmhlink(@link)->system if @link and !$rc;
	} else {
	  foreach (@args) {
	    s/^$type://;
	    warn Msg('E', qq($Name type not found: "$_".));
	  }
	  exit 1;
	}
      } else {
	$ntype->args(@args);
	$ntype->opts(@cmt, $ntype->opts);
	$rc = $ntype->system;
      }
      return $rc if $rc; #only in error, so no fallback
    }
    if (%fcpy) {	#full copy: type already created; now apply it
      my @eqlst = _EqLbTypeList($fcpy{lbinc});
      my $lbt = $args[0];
      $lbt =~ s/@.*$//;
      my $qry = '&&!attr_sub(Rm' . "$fcpy{base},<=,$fcpy{nr})";
      my @lbargs = ($lbt);
      push @lbargs, '-replace' if $rep;
      my $vob = ($fcpy{vob} or $CT->des(['-s'], 'vob:.')->qx);
      my @findopts;
      push @findopts, $vob if $fcpy{vob};
      push @findopts, qw(-a -ele), '!lbtype_sub(' . $lbt . ')', '-ver';
      my $lbtv = "lbtype:$lbt";
      $lbtv .= "\@$vob" if $fcpy{vob};
      for my $inc (@eqlst) {
	my @ver = $CT->find(@findopts, "lbtype($inc)$qry", '-print')->qx;
	next unless @ver;
	$rc |= _Wrap('mklabel', @lbargs, @ver);
      }
      _Ensuretypes([$FCHL], $vob);
      my @lckargs = _RecLock $fcpy{lbinc};
      _Wrap('unlock', $fcpy{lbinc}) if @lckargs;
      $rc |= $CT->mkhlink([$FCHL], $fcpy{lbinc}, $lbtv)->system;
      _Wrap('lock', @lckargs) if @lckargs;
    }
    exit $rc;
  };
}
sub _GenExTypeSub {
  use strict;
  use warnings;
  my $type = shift;
  return sub {
    my ($mkt, $arg) = @_;
    $arg = "$type:$arg" unless $arg =~ /^$type:/;
    # Maybe need to check that non locked?
    return ClearCase::Argv->des('-s', $arg)->stdout(0)->system? 0 : 1;
  };
}
sub mklbtype {
  use strict;
  use warnings;
  my (%opt, $rep);
  GetOptions(\%opt,
	     qw(family increment archive config=s c99=s exclude=s fullcopy=s));
  GetOptions('replace' => \$rep);
  die Msg('E', 'Incompatible options: family increment archive')
    if (keys %opt > 1 and !($opt{config} or $opt{fullcopy}))
      or (keys %opt > 2 and !$opt{exclude})
      or keys %opt > 3;
  die Msg('E', 'Incompatible options: fullcopy and '
	    . join', ', grep !/^(?:fullcopy|family)$/, keys %opt)
    if $opt{fullcopy} and keys %opt > 1 and !$opt{family};
  die Msg('E', 'Incompatible options: fullcopy and replace')
    if $opt{fullcopy} and $rep;
  my $ntype = ClearCase::Argv->new(@ARGV);
  $ntype->parse(qw(global|ordinary vpelement|vpbranch|vpversion
		   pbranch|shared gt|ge|lt|le|enum|default|vtype=s
		   cquery|cqeach nc c|cfile=s));
  if (!$ntype->args) {
    warn Msg('E', 'Type name required.');
    @ARGV = qw(help mklbtype);
    ClearCase::Wrapper->help();
    return 1;
  }
  $ntype->{fopts} = \%opt;
  $ntype->{rep} = $opt{archive}? 1 : $rep;
  my $tst = $ntype->{rep}? _GenExTypeSub('lbtype') : 0;
  _Preemptcmt($ntype, _GenMkTypeSub(qw(lbtype Label label)), $tst);
}

=item * MKBRTYPE

Extension: archive a brtype away, in order to avoid having to modify
config specs using it (rationale: config specs are not versioned, so
they'd rather be stable). Also, starting new branches from the I<main>
one (whatever its real type) makes it easier to roll back changes if
need-be, branch off an earlier version, and bring back again the
changes rolled back at some later stage, after the problems have been
fixed.

The implementation is largely shared with I<mklbtype>.
See its documentation for the B<PrevInc> hyperlink type.

=over 1

=item B<-arc/hive>

Rename the current type to an I<archive> value (name as prefix, and a
numeral suffix. Initial value: I<-001>), create a new type, and make the
archived one its predecessor, with a B<PrevInc> hyperlink.
Comments go to the type being archived.

=item B<-glo/bal>

Global types (in an Admin vob or not) are currently not supported for
archiving.

=back

=cut

sub mkbrtype {
  use strict;
  use warnings;
  my (%opt, $rep);
  GetOptions(\%opt, q(archive));
  GetOptions('replace' => \$rep);
  die Msg('E', 'Incompatible options: global types cannot be archived')
    if %opt and grep /^-glo/, @ARGV;
  ClearCase::Argv->ipc(1);
  my $ntype = ClearCase::Argv->new(@ARGV);
  $ntype->parse(qw(global|ordinary acquire pbranch
		   cquery|cqeach nc c|cfile=s));
  $ntype->{fopts} = \%opt;
  $ntype->{rep} = $opt{archive}? 1 : $rep;
  my $tst = $ntype->{rep}? _GenExTypeSub('brtype') : 0;
  _Preemptcmt($ntype, _GenMkTypeSub(qw(brtype Branch branch)), $tst);
}

=item * LOCK

New B<-allow> and B<-deny> flags. These work like I<-nuser> but operate
incrementally on an existing I<-nuser> list rather than completely
replacing it. When B<-allow> or B<-deny> are used, I<-replace> is
implied.

When B<-iflocked> is used, no lock will be created where one didn't
previously exist; the I<-nusers> list will only be modified for
existing locks.

In case of a family type, lock also the equivalent incremental type.

There may be an issue if the two types are not owned by the same account.
You may overcome it by providing a module specification via the environment
variable B<FORCELOCK>. This module must export both a B<flocklt> and a
B<funlocklt> (force lock and unlock label type) functions.
The functions take an B<lbtype> and a B<vob tag> as input (B<flocklt>
optionally takes a B<replace> flag and an B<nusers> exception list).
The two functions take the responsibility of printing the standard output
(but not necessarily the errors), and return an error code: 0 for success,
other for error.
See the documentation for examples of implementation.

=cut

sub lock {
  use warnings;
  use strict;
  my (%opt, $nusers);
  GetOptions(\%opt, qw(allow=s deny=s iflocked));
  GetOptions('nusers=s' => \$nusers);
  my $lock = ClearCase::Argv->new(@ARGV);
  $lock->parse(qw(c|cfile=s cquery|cqeach nc pname=s obsolete replace));
  die Msg('E', "cannot specify -nusers along with -allow or -deny")
    if %opt and $nusers;
  die Msg('E', "cannot use -allow or -deny with multiple objects")
    if %opt and $lock->args > 1;
  my $lslock = ClearCase::Argv->lslock([qw(-fmt %c)], $lock->args);
  my($currlock) = $lslock->autofail(1)->qx;
  if ($currlock && $currlock =~ m%^Locked except for users:\s+(.*)%) {
    my %nusers = map {$_ => 1} split /\s+/, $1;
    if ($nusers) {
      %nusers = ();
      map { $nusers{$_} = 1 } split /,/, $nusers;
    } else {
      if ($opt{allow}) {
	map { $nusers{$_} = 1 } split /,/, $opt{allow};
      } elsif ($opt{deny}) {
	map { delete $nusers{$_} } split /,/, $opt{deny};
      } else {
	%nusers = ();
      }
    }
    $lock->opts($lock->opts, '-nusers', join(',', sort keys %nusers))
      if %nusers;
  } elsif (($nusers or $opt{allow}) and
	     (!$currlock or $opt{iflocked} or $lock->flag('replace'))) {
    $lock->opts($lock->opts, '-nusers', ($nusers or $opt{allow}));
  }
  if ($currlock and !$lock->flag('replace')) {
    if ($opt{allow} or $opt{deny}) {
      $lock->opts($lock->opts, '-replace')
    } else {
      die Msg('E', 'Object is already locked.');
    }
  }
  my @args = $lock->args;
  $CT = ClearCase::Argv->new({autochomp=>1});
  my (@lbt, @oth, %vob);
  my $locvob = $CT->des(['-s'], 'vob:.')->stderr(0)->qx;
  foreach (@args) {
    if (/^lbtype:/) {
      my $t = $CT->des([qw(-fmt %Xn\n)], $_)->qx;
      if ($t and $CT->des([qw(-fmt %m)], $t)->stderr(0)->qx eq 'label type') {
	my ($t1, $v) = $t;
	$v = $2 if $t =~ s/lbtype:(.*)@(.*)$/$1/;
	$vob{$t} = $v;
	push @lbt, $t;
	my @et = grep s/^-> lbtype:(.*)@.*$/$1/,
	  $CT->des([qw(-s -ahl), $EQHL], $t1)->qx;
	if (@et) {
	  my ($e, $p) = ($et[0], '');
	  $vob{$e} = $vob{$t};
	  push @lbt, $e;
	  my @pt = grep s/^-> lbtype:(.*)@.*$/$1/,
	    $CT->des([qw(-s -ahl), $PRHL], "lbtype:$e\@$v")->qx;
	  if (@pt) {
	    $p = $pt[0];
	    if (!$CT->lslock(['-s'], "lbtype:$p\@$v")->stderr(0)->qx) {
	      push @lbt, $p;
	      $vob{$p} = $v;
	    }
	  }
	}
      }
    } else {
      push @oth, $_;
    }
  }
  my $rc = @oth? $lock->args(@oth)->system : 0;
  my ($fl, $loaded) = $ENV{FORCELOCK};
  for my $lt (@lbt) {
    my $v = $vob{$lt};
    my @out = $lock->args("lbtype:$lt\@$v")->stderr(1)->qx;
    if (grep /^cleartool: Error/, @out) {
      if ($fl and !$loaded) {
	my $fn = $fl; $fn =~ s%::%/%g; $fn .= '.pm';
	require $fn;
	$fl->import;
	$loaded = 1;
      }
      if (!$fl) {
	print @out;
	$rc = 1;
      } elsif (flocklt($lt, $v, $lock->flag('replace'),
		       ($nusers or $opt{allow}))) {
	$rc = 1;
      }
    } else {
      print @out;
    }
  }
  exit $rc;
}

=item * UNLOCK

In case of a family type, unlock also the equivalent incremental type.

There may be an issue if the two types are not owned by the same account.
See the B<LOCK> documentation for overcoming it with a B<FORCELOCK>
environment variable.

There is also the case of global types: then one ensures that the
family type is usable locally, by copying in the equivalent
incremental type.

=cut

sub unlock {
  use warnings;
  use strict;
  my $unlock = ClearCase::Argv->new(@ARGV);
  $unlock->parse(qw(c|cfile=s cquery|cqeach nc version=s pname=s));
  my @args = $unlock->args;
  $CT = ClearCase::Argv->new({autochomp=>1});
  my (@lbt, @oth, %vob, %tvob, %eqt);
  my $locvob = $CT->des(['-s'], 'vob:.')->stderr(0)->qx;
  foreach (@args) {
    if (/^lbtype:/) {
      my $t = $CT->des([qw(-fmt %Xn\n)], $_)->qx;
      if ($CT->des([qw(-fmt %m)], $t)->stderr(0)->qx eq 'label type') {
	my $t1 = $t;
	$tvob{$_} = /lbtype:.*?(@.*)$/? $1 : '';
	$vob{$t} = $2 if $t =~ s/lbtype:(.*?)@(.*)$/$1/;
	push @lbt, $t;
	my @et = grep s/^-> lbtype:(.*)@.*$/$1/,
	  $CT->des([qw(-s -ahl), $EQHL], $t1)->qx;
	if (@et) {
	  my $eq = $et[0];
	  $eqt{$_} = $eq;
	  push @lbt, $eq;
	  $vob{$eq} = $vob{$t};
	}
      }
    } else {
      push @oth, $_;
    }
  }
  my $rc = @oth? $unlock->args(@oth)->system : 0;
  my ($fl, $loaded) = $ENV{FORCELOCK};
  for my $lt (@lbt) {
    my $v = $vob{$lt};
    if ($CT->lslock(['-s'], "lbtype:$lt\@$v")->qx) {
      my @out = $unlock->args("lbtype:$lt\@$v")->stderr(1)->qx;
      if (grep /^cleartool: Error/, @out) {
	if ($fl and !$loaded) {
	  my $fn = $fl; $fn =~ s%::%/%g; $fn .= '.pm';
	  require $fn;
	  $fl->import;
	  $loaded = 1;
	}
	if (!$fl) {
	  print @out;
	  $rc = 1;
	} elsif (funlocklt($lt, $v)) {
	  $rc = 1;
	}
      } else {
	print @out;
      }
    } else {
      warn Msg('E', 'Object is not locked.');
      warn Msg('E', "Unable to unlock label type \"$lt\".");
      $rc = 1;
    }
  }
  for (@args) {
    my $eq = $eqt{$_};
    next unless $eq;
    my $tv = $tvob{$_};
    my $lb = "lbtype:$eq$tv"; #target vob
    if (!$CT->des(['-s'], $lb)->stderr(0)->qx) {
      my $v = $vob{$eq};
      my $ets = ($lb =~ /^([^@]*)/)[0] . "\@$v";
      _Wrap('cptype', $ets, $lb);
    }
  }
  exit $rc;
}

=item * MKLABEL

In case of a family type, apply also the equivalent incremental type.
The meaning of B<-replace> is affected: it concerns the equivalent fixed
type, and is implicit for the floating type (the one given as argument).

Preserve the support for the B<-up> flag from B<ClearCase::Wrapper::DSB>
and lift the restriction to using it only with B<-recurse>.

Added a B<-force> option which makes mostly sense in the case of applying
incremental labels. Without it, applying the floating label type will be
skipped if there has been errors while (incrementally) applying the
equivalent fixed one. Forcing the application may make sense if the errors
come from multiple application e.g. due to links, or in order to retry the
application after a first failure.
It may also be used to apply labels upwards even if recursive application
produced errors.

B<-config>: adapted for incremental types. This requires that the
label types have been created previously with I<mklbtype -config>.
It will not use admin vobs!

The script will skip, and report, vobs in which the types have not
been copied/linked to.

With incremental types, the I<-replace> flag is implicit in
conjunction with I<-config>.

Extension: B<-over> takes either a label or a branch type. In either case,
the labels will be applied over the result of a find command run on the
unique version argument, and looking for versions matching respectively
B<lbtype(xxx)> or <version(.../xxx/LATEST)> queries, and B<!lbtype(lb)> (with
I<xxx> the B<-over>, and I<lb> the main label type parameter.
Internally B<-over> performs a B<find>. This one depends by default on the
current config spec, with the result that it is not guaranteed to reach all
the versions specified, at least in the first pass. One may thus use an B<-all>
option which will be passed to the B<find>.
The B<-over> option doesn't require an element argument (default: current
directory). With the B<-all> option, it uses one if given, as a filter.
When using a branch type to apply labels, it links the types with a B<StBr>
hyperlink. This is in preparation for an eventual rollout of the label type:
this one will then archive the branch type (away) in addition to the label
type, if they are used in the config spec, so that rules based on neither
would hide the updated baseline.

=cut

sub mklabel {
  use warnings;
  use strict;
  use File::Basename;
  use File::Spec::Functions qw(rel2abs);
  File::Spec->VERSION(0.82);
  my %opt;
  GetOptions(\%opt, qw(up force over=s all config=s c99=s));
  ClearCase::Argv->ipc(1);
  my $mkl = ClearCase::Argv->new(@ARGV);
  $mkl->parse(qw(replace|recurse|follow|ci|cq|nc
		 version=s c|cfile|select|type|name=s));
  my @opt = $mkl->opts();
  die Msg('E', 'all is only supported in conjunction with over')
    if $opt{all} and !$opt{over};
  {
    my @inc = ([qw(up config)], [qw(up over)]);
    for (@inc) {
      my ($a, $b) = @{$_}[0..1];
      die Msg('E', "Incompatible flags: $a and $b") if $opt{$a} and $opt{$b};
    }
    @inc = qw(config over);
    for (@inc) {
      die Msg('E', "Incompatible flags: $_ and recurse")
	if $opt{$_} and grep /^-r(ec|$)/, @opt;
    }
  }
  my($lbtype, @elems) = $mkl->args;
  die Msg('E', 'Only one version argument with the over flag')
    if $opt{over} and scalar @elems > 1;
  die Msg('E', 'Label type required') unless $lbtype;
  $lbtype =~ s/^lbtype://;
  $CT = ClearCase::Argv->new({autochomp=>1});
  my (%vb, @lt);
  for my $e (@elems?@elems:($opt{config} or '.')) {
    my $v = $CT->argv(qw(des -s), "vob:$e")->stderr(0)->qx;
    $vb{$v}++ if $v;
  }
  if ($lbtype =~ /@/) {
    push @lt, $lbtype;
  } else {
    push @lt, "$lbtype\@$_" for keys %vb;
  }
  my @lt1 = @lt;
  my $fail = $CT->clone({autofail=>1});
  my @et = grep s/^-> lbtype:(.*)@.*$/$1/,
    map { $fail->argv(qw(des -s -ahl), $EQHL, "lbtype:$_")->qx } @lt1;
  if (!@et and $opt{config}) { #restore @ARGV before falling back to cleartool
    my @tail;
    while (@ARGV > 1 and my $item = pop @ARGV) {
      if ($item =~ /^-/) {
	push @ARGV, $item;
	last;
      }
      push @tail, $item;
    }
    push @ARGV, '-config', $opt{config}, reverse @tail;
  }
  return 0 unless $opt{up} or $opt{over} or @et; # fallback!
  $fail->argv(qw(des -s), @elems)->stdout(0)->system if @elems; #-over & -con ok
  my %con = (cr => rel2abs($opt{config})) if $opt{config}; # scope globals
  if (%con) {
    push @opt, '-rep' if @et and !grep /^-rep/, @opt;
    my $cr = $con{cr}; # for convenience
    die Msg('E', "No arguments expected: '@elems'") if @elems;
    my @dir = $CT->catcr([qw(-flat -s -type d -nxn)], $cr)->qx;
    die "\n" if grep /^</, @dir; #one vob not mounted
    my $mvob = $CT->des(['-s'], "vob:$cr")->qx;
    my $pfx = $1 if $cr =~ m%^(.*?)$mvob%; #Windows, cygwin, view extended path
    my (%crvb, %lbvb);
    $crvb{$CT->des(['-s'], "vob:$_")->stderr(0)->qx}++ for @dir;
    $lbvb{$_}++ for grep s/^<- .*\@(.*)$/$1/,
      $CT->des([qw(-s -ahl GlobalDefinition)], "lbtype:$lt[0]")->qx;
    my $lvob = (keys %vb)[0];
    if ($lbvb{$lvob}++) { # Only the copies found already
      die Msg('E',
	      "Mismatch between the source vob of '$lbtype' and this of '$cr'");
    }
    for (keys %lbvb) {
      push @{$con{rmall}}, $_ unless $crvb{$_};
    }
    my @origvb = keys %crvb;
    for (@origvb) {
      next if $lbvb{$_};
      warn Msg('W', "No label type found in '$_': skipping.");
      delete $crvb{$_};
    }
    for ($CT->catcr([qw(-flat -s -ele -type fd)], $cr)->qx) {
      $con{ver}{$_}++ if $crvb{$CT->des(['-s'], "vob:$pfx$_")->qx};
    }
    @elems = keys %{$con{ver}};
    @{$con{vob}} = keys %crvb;
  }
  die Msg('E', "Only one vob supported for family types") if @et > 1;
  map {
    die Msg('E', qq(Lock on label type "$_" prevents operation "make label"))
      if $CT->argv(qw(lslock -s),"lbtype:$_")->stderr(0)->qx
    } @lt;
  my ($ret, @rec, @mod) = 0;
  if (grep /^-r(ec|$)/, @opt) {
    if (@et) {
      #The -vob_only flag would hide the checkout info for files
      @rec = grep m%@@[/\\]%, $CT->argv(qw(ls -s -r), @elems)->qx;
    } else {
      $mkl->syfail(1) unless $opt{force};
      $ret = $mkl->system;
    }
  } elsif ($opt{over}) {
    my ($t, $ver, $lb) = ($opt{over}, $elems[0]);
    die Msg('E', 'The -over flag requires a local type argument')
      if !$t or $t =~ /\@/;
    my $base = $ver || '.';
    my $vob = $fail->argv(qw(des -s), "vob:$base")->qx;
    if ($t =~ /lbtype:(.*)$/) {
      $t = $1; $lb = 1;
      die unless $CT->argv(qw(des -s), "lbtype:$t\@$vob")->qx;
    } elsif ($t =~ /brtype:(.*)/) {
      $t = $1; $lb = 0;
      die unless $CT->argv(qw(des -s), "brtype:$t\@$vob")->qx;
    } else {
      if ($CT->argv(qw(des -s), "lbtype:$t\@$vob")->stderr(0)->qx) {
	$lb = 1;
      } elsif ($CT->argv(qw(des -s), "brtype:$t\@$vob")->stderr(0)->qx) {
	$lb = 0;
      } else {
	die Msg('E', 'The argument of the -over flag must be an existing type')
      }
    }
    my $query = $lb? "lbtype($t)" : "version(.../$t/LATEST)";
    $query .= " \&\&! lbtype($lbtype)";
    $base = '-a' if $opt{all};
    @mod = $CT->argv('find', $base, '-ver', $query, '-print')->stderr(0)->qx;
    if ($opt{all} and $ver) {
      $ver = rel2abs($ver);
      @mod = grep /^${ver}(\W|$)/, @mod;
    }
    if (!$lb and @mod) { # only if on branches; skip if nothing to label
      my $sil = $CT->clone({stdout=>0, stderr=>0});
      my $cmt = 'Stream branch type, to rollout with lbtype';
      for my $v (keys %vb) {
	my $ht = "$STHL\@$v";
	$CT->mkhltype([qw(-shared -c), $cmt], $ht)->system
	  if $sil->des(['-s'], "hltype:$ht")->system;
	my $lt = "lbtype:$lbtype\@$v";
	$sil->mkhlink([$STHL], $lt, "brtype:$t\@$v")->system
	  unless grep /brtype:$t\@$v$/, $CT->des([qw(-s -ahl), $STHL], $lt)->qx;
      }
    }
  }
  $mkl->opts(grep !/^-r(ec|$)/, @opt); # recurse handled already
  if ($opt{up}) {
    my %ancestors;
    my $follow = grep /^-f/, @opt;
    _Recpath(\%ancestors, $follow, $_) for @elems;
    if (@et) {
      push @elems, sort {$b cmp $a} keys %ancestors;
    } else {
      @elems = () if grep /^-r(ec|$)/, @opt; #already labelled
      push @elems, sort {$b cmp $a} keys %ancestors;
      $ret |= $mkl->args($lbtype, @elems)->system;
      exit $ret;
    }
  }
  if (!$opt{over}) {
    push @elems, @rec;
    @mod = grep {
      my $v = $_;
      $_ = (grep /^$lbtype$/, split/ /,
	    $CT->argv(qw(des -fmt), '%Nl', $v)->qx)? '' : $v;
    } @elems;
  }
  if (%con) {
    for (@{$con{rmall}}) {
      my @ver = $CT->find($_, qw(-a -ver), "lbtype($lbtype)", '-print')->qx;
      _Wrap('rmlabel', $lbtype, @ver) if @ver;
    }
    my $chkalias = sub {
      local $_;
      my $v = shift;
      my @al = split /, /, $CT->des([qw(-fmt %[aliases]ACp)], $v)->qx;
      return 0 if @al == 1; #don't waste more time
      # describe returns aliases in a different way than find
      my $e = ($v =~ /^(.*?)\@/)? $1 : $v;
      my $d = dirname $e;
      my ($a1, $a2, $rc);
      push @{/^\Q$d\E/?$a1:$a2}, $_ for @al;
      if (@{$a1} > 1) {
	my $dv = $CT->ls([qw(-s -d)], $d)->qx;
	for (grep s%\Q$dv\E%$d%, @{$a1}) {
	  next if $v =~ /^\Q$_\E\@/; #original representation
	  if ($con{ver}{$CT->ls([qw(-s -d)], $_)->qx}) {
	    $rc = 1;
	    last;
	  }
	}
      }
      return 1 if $rc;
      for (@{$a2}) {
	my $d1 = $1 if /^(.*?)\@/; #Should always match
	my $dv = $CT->ls([qw(-s -d)], $d1)->qx;
	s%\Q$dv\E%$d1%;
	if ($con{ver}{$CT->ls([qw(-s -d)], $_)->qx}) {
	  $rc = 1;
	  last;
	}
      }
      return $rc;
    };
    for (@{$con{vob}}) {
      my @ver = grep { !$con{ver}{$_} and !$chkalias->($_) }
	$CT->find($_, qw(-a -ver), "lbtype($lbtype)", '-print')->qx;
      _Wrap('rmlabel', $lbtype, @ver) if @ver;
    }
    my $cr = $con{cr};
    $CT->winkin($cr)->system;
    my $vob = $CT->des('-s', "vob:$cr")->qx;
    for my $t (qw(ConfigRecordDO ConfigRecordOID)) {
      $CT->mkattype(qw(-vty string -nc), "$t\@$vob")->system
	unless $CT->des('-s', "attype:$t\@$vob")->stderr(0)->qx;
    }
    my $lb = "lbtype:$et[0]\@$vob";
    my $val = $CT->des(['-s'], $cr)->qx;
    $val =~ s%^.*?\Q$vob\E%$vob%;
    $CT->mkattr([qw(-rep ConfigRecordDO), qq("$val")], $lb)->system;
    $val = '"' . $CT->des([qw(-fmt %On)], $cr)->qx . '"';
    $CT->mkattr([qw(-rep ConfigRecordOID), $val], $lb)->system;
  }
  exit $ret unless @mod;
  my $rmattr = ClearCase::Argv->rmattr([("Rm$lbtype")]);
  my @raopts = $rmattr->opts;
  push(@raopts, '-ver', $mkl->flag('version')) if $mkl->flag('version');
  $rmattr->opts(@raopts);
  for (@mod) {
    if (@et) {
      my $rc = $mkl->args($et[0], $_)->system;
      $ret |= $rc;
      next if $rc and !$opt{force};
      $rmattr->args($_)->stderr(0)->system unless $rc;
    }
    @opt = $mkl->opts;
    push @opt, '-rep' if @et and !grep /^-rep/, @opt; #implicit for floating
    $mkl->opts(@opt);
    $ret |= $mkl->args($lbtype, $_)->system;
  }
  exit $ret;
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

Since checkin is such a common operation, a special feature is supported
to save typing: an unadorned I<ci> cmd is C<promoted> to I<ci -dir -me
-diff -revert>. In other words typing I<ct ci> will step through each
file checked out by you in the current directory and view,
automatically undoing the checkout if no changes have been made and
showing diffs followed by a checkin-comment prompt otherwise.

[ From David Boyce's ClearCase::Wrapper. Adapted to user interactions
preempting. ]

=cut

sub checkin {
  use strict;
  use warnings;
  # Allows 'ct ci' to be shorthand for 'ct ci -me -diff -revert -dir'.
  push(@ARGV, qw(-me -diff -revert -dir)) if grep(!/^-pti/, @ARGV) == 1;
  # -re999 isn't a real flag, it's to disambiguate -rec from -rev. Id. -cr999.
  my %opt;
  GetOptions(\%opt, qw(crnum=s cr999=s diff ok revert re999))
    if grep /^-(crn|dif|ok|rev)/, @ARGV;
  ClearCase::Argv->ipc(1);
  # This is a hidden flag to support DB's checkin_post trigger.
  # It allows the bug number to be supplied as a cmdline option.
  $ENV{CRNUM} = $opt{crnum} if $opt{crnum};
  my $ci = ClearCase::Argv->new(@ARGV);
  # Parse checkin and (potential) diff flags into different optsets.
  $ci->parse(qw(cquery|cqeach nc c|cfile=s
		nwarn|cr|ptime|identical|cact|cwork keep|rm from=s));
  if ($opt{'diff'} || $opt{revert}) {
    $ci->optset('DIFF');
    $ci->parseDIFF(qw(serial_format|diff_format|window columns|options=s
		      graphical|tiny|hstack|vstack|predecessor));
  }
  # Now do auto-aggregation on the remaining args.
  my @elems = AutoCheckedOut($opt{ok}, $ci->args); # may exit
  if (!@elems) {
    warn Msg('E', 'Element pathname required.');
    @ARGV = qw(help checkin);
    ClearCase::Wrapper->help();
    return 1;
  }
  # Turn symbolic links into their targets so CC will "do the right thing".
  for (@elems) {
    $_ = readlink if -l && defined readlink;
  }
  $ci->args(@elems);
  # Give a warning if the file is open for editing by vim.
  # (DB knows, there are lots of other editors but it just happens
  # to be easy to detect vim by its .swp file)
  for (@elems) {
    die Msg('E', "$_: appears to be open in vim!") if -f ".$_.swp";
  }
  if ($opt{diff}) {
    warn Msg('W', 'Ignoring c/nc flags when diff set')
      if grep /^-c|-nc$/, $ci->opts;
    # In case ~/.clearcase_profile makes ci -nc the default, make sure
    # we prompt for a comment - unless checking in dirs only.
    if (grep(-f, @elems)) {
      $ci->opts('-cqe', grep(!/^-c|^-nc$/, $ci->opts));
      $ci->{AV_LKG}{''}{cquery}=1;
      delete @{$ci->{AV_LKG}{''}}{qw(c nc)};
    }
  }
  $ci->{opthashre} = \%opt;
  _Preemptcmt($ci, \&_Checkin, \&_PreCi, $opt{revert});
}

=item * RMBRANCH

No semantic change. This implementation is only needed to handle the
optional interactive dialog in the context of the ipc mode of the
underlying I<ClearCase::Argv>.

=cut

sub rmbranch {
  use strict;
  use warnings;
  ClearCase::Argv->ipc(1);
  my $rmbranch = ClearCase::Argv->new(@ARGV);
  $rmbranch->parse(qw(cquery|cqeach nc c|cfile=s force));
  if ($rmbranch->flag('force')) {
    exit $rmbranch->system;
  } else {
    my %forceorabort = (yes => '-force');
    my %yn = (
      format   =>
	q(Remove branch, all its sub-branches and sub-versions? [no] ),
      default  => q(no),
      valid    => qr/yes|no/,
      instruct => "Please answer with one of the following: yes, no\n",
      opt      => \%forceorabort,
    );
    my $des = ClearCase::Argv->des([qw(-s)]);
    $des->stderr(0);
    $des->stdout(0);
    my $exists = sub { return $des->args(shift)->system? 0:1 };
    my $err = q(Pathname not found: );
    my $run = sub { my $rmbranch = shift; $rmbranch->system };
    _Yesno($rmbranch, $run, \%yn, $exists, $err);
  }
}

=item * RMLABEL

For family types, remove both types, and add a I<RmLBTYPE> attribute
mentioning the increment of the removal of the LBTYPE label, for use
in config specs based on sparse fixed types equivalent to a given
state of the floating type.

=cut

sub rmlabel {
  use strict;
  use warnings;
  my $rmlabel = ClearCase::Argv->new(@ARGV);
  $rmlabel->parse(qw(cquery|cqeach nc c|cfile=s recurse follow version=s));
  my($lbtype, @elems) = $rmlabel->args;
  $CT = ClearCase::Argv->new({autochomp=>1});
  if (!($lbtype and @elems)) {
    warn Msg('E', 'Type name required') unless $lbtype;
    warn Msg('E', 'Element pathname required') unless @elems;
    $CT->argv(qw(help rmlabel))->system;
    exit 1;
  }
  if (MSWIN) {
    $_ = glob($_) for @elems;
  }
  $lbtype =~ s/^lbtype://;
  my (%vb, @lt, %et, %vpe);
  for my $e (@elems) {
    my $v = $CT->argv(qw(des -s), "vob:$e")->stderr(0)->qx;
    next unless $v;
    $vb{$v}++;
    $vpe{$e} = $v;
  }
  if ($lbtype =~ /@(.*)$/) {
    my ($v, @v) = ($1, keys %vb);
    die Msg('E', qq(Object is in unexpected VOB: "$lbtype".))
      if scalar @v > 1 or (scalar @v == 1 and $v !~ /^$v[0]/);
    push @lt, $lbtype;
  } else {
    push @lt, "$lbtype\@$_" for keys %vb;
  }
  $et{$_}++ for grep s/^-> lbtype:(.*)@.*$/$1/,
    map { $CT->argv(qw(des -s -ahl), $EQHL, "lbtype:$_")->qx } @lt;
  my @et = keys %et;
  die Msg('E', qq("$lbtype" must have the same equivalent type in all vobs.))
    if scalar @et > 1;
  my $et = (scalar @et == 1)? $et[0] : '';
  my $fn = sub {
    my ($rml, @cmt) = @_;
    my @opts = $rml->opts;
    my @opcm = @opts;
    push @opcm, @cmt;
    my $rc = 0;
    my %query; #Cache the queries per vob
    for (@elems) {
      my $v = $vpe{$_};
      my $e = $CT->des([qw(-s)], $_)->qx; #in case passed by the label: f@@/L
      $rml->opts(@opcm);
      $rml->args($lbtype, $e);
      my $r1 = $rml->system;
      if ($et) {
	my $att = "Rm$lbtype";
	my $val = $et;
	$val =~ s/^.*_//;
	if (!$r1) { #floating successfully removed
	  my ($f) = ($e =~ /(.*)@@.*$/);
	  if (!defined $query{$v}) {
	    my @eqlst = grep s/(.*)/lbtype($1)/, _EqLbTypeList("$lbtype\@$v");
	    $query{$v} =
	      (@eqlst? (@eqlst==1? $eqlst[0] : '(' . join('||', @eqlst) . ')')
		 . "&&!attype($att)" : 0);
	  }
	  if ($query{$v}) {
	    my @v = $CT->find($f, qw(-d -ver), $query{$v}, '-print')->qx;
	    $CT->mkattr([$att, $val], @v)->stdout(0)->system if @v;
	  }
	}
	$rml->opts(@opts);
	$rml->args($et, $e);
	$r1 |= $rml->stderr(0)->system;
      }
      $rc |= $r1;
    }
    return $rc;
  };
  _Preemptcmt($rmlabel, $fn);
}

=item * RMTYPE

For family label types, 3 cases:

=over

=item -fam: remove all types in the family, as well as the I<RmLBTYPE>
attribute type. This is a rare and destructive situation, unless the
equivalent type is I<LBTYPE_1.00> (the family was just created).
The types actually affected ought of course to be unlocked.

=item -inc: remove the current increment, and move back the family
type onto the previous one. Note: I<RmLBTYPE> attributes ... may be
left behind (for now...)

=item default (no flag): remove the family (floating) type and the
current increment, storing the information about the previous one into
the "hidden" I<LBTYPE_0> type, from which it may be recovered with a
later C<mklbtype -fam LBTYPE>.

=back

Note that removing directly an incremental fixed type is left
unchanged for low level purposes, and thus may corrupt the whole
hierarchy: you need to restore links and take care of possible
I<RmLBTYPE> attributes.

=cut

sub rmtype {
  use strict;
  use warnings;
  my %opt;
  GetOptions(\%opt, qw(f999 family increment)); # f999 to disambiguate -force
  die Msg('E', qq("-family" and "-increment" are mutualy exclusive.))
    if $opt{family} and $opt{increment};
  my $rmtype = ClearCase::Argv->new(@ARGV);
  $rmtype->parse(qw(cquery|cqeach nc c|cfile=s ignore rmall force));
  my @type = $rmtype->args;
  my (@lbt, @oth);
  for (@type) {
    if (/^lbtype:/) {
      push @lbt, $_;
    } else {
      push @oth, $_;
    }
  }
  if (!@lbt) {
    warn Msg('W', '"-family" applies only to label types') if $opt{family};
    warn Msg('W', '"-increment" applies only to label types')
      if $opt{increment};
    exit $rmtype->system;
  }
  my $rs;
  $rs = $rmtype->args(@oth)->system if @oth;
  $CT = ClearCase::Argv->new({autochomp=>1});
  if (!$rmtype->flag('rmall')) {
    my @glb;
    for (@lbt) {
      push @glb, $_
	if $CT->argv(qw(des -fmt %[type_scope]p), $_)->qx eq 'global';
    }
    if (@glb) {
      warn Msg('E', "Global type: must specify removal of all instances.");
      warn Msg('E', qq(Unable to remove label type "$_"))
	for grep { s/^lbtype:(.*)(\@.*)?$/$1/ } @glb;
      exit 1;
    }
  }
  my (@args, @eq, @lck) = @lbt;
  my $lct = new ClearCase::Argv; #Not autochomp
  my ($fl, $loaded) = $ENV{FORCELOCK};
 LBT:for my $t (@lbt) {
    my ($eq) = grep s/^-> (lbtype:.*)/$1/,
      $CT->des([qw(-s -ahl), $EQHL], $t)->stderr(0)->qx;
    if ($eq) {
      my ($base, $vob) = ($1, $2?$2:'') if $t =~ /^lbtype:(.*?)(\@.*)?$/;
      if ($opt{family} or $eq =~ /_1.00(\@.*)?$/) {
	push @eq, grep(s/^(.*)/lbtype:${1}$vob/, _EqLbTypeList($t)),
	  "attype:Rm${base}$vob";
      } else {
	my ($prev) = grep s/^-> (lbtype:.*)/$1/,
	  $CT->argv(qw(des -s -ahl), $PRHL, $eq)->qx;
	if ($prev and $CT->argv(qw(lslock -s), $prev)->stderr(0)->qx) {
	  push @lck, $prev;
	  my @out = $lct->argv('unlock', $prev)->stderr(1)->qx;
	  if (grep /^cleartool: Error/, @out) {
	    if ($fl and !$loaded) {
	      my $fn = $fl; $fn =~ s%::%/%g; $fn .= '.pm';
	      require $fn;
	      $fl->import;
	      $loaded = 1;
	    }
	    if (!$fl) {
	      print @out;
	      next LBT;
	    } else {
	      my ($p, $v) = ($1, $2) if $prev =~ /^lbtype:(.*)\@(.*)$/;
	      next LBT if funlocklt($p, $v);
	    }
	  } else {
	    print @out;
	  }
	}
	if ($opt{increment}) {
	  my ($hl) = grep s/^\s+(.*) -> $eq/$1/,
	    $CT->argv(qw(des -l -ahl), $EQHL, $t)->qx;
	  if ($hl) {
	    $rs |= $CT->argv('rmhlink', $hl)->stdout(0)->system;
	    $rs |= $CT->argv('mkhlink', $EQHL, $t, $prev)->stdout(0)->system;
	    for (@args) {
	      $_ = $eq if $_ eq $t;
	    }
	    # rollback... for all vobs referenced with GlobalDefinition...
	    my @vb = grep s/^\s+.*?\s+.*? -> .*?\@(.*)$/$1/,
	      map{ $CT->argv('des', "hlink:$_")->qx } grep s/^\s+(.+?) <-.*/$1/,
	      $CT->argv(qw(des -l -ahl GlobalDefinition), $eq)->qx;
	    my ($tn, $vb) = ($1, $2) if $eq =~ /^lbtype:(.*)\@(.*)/;
	    push @vb, $vb;
	    my @e = map{$CT->argv('find', $_, qw(-a -ele), "lbtype_sub($tn)",
			      qw(-nxn -print))->qx} @vb;
	    warn Msg('W', qq(Need to move "$base" back on @e.)) if @e;
	  } else {
	    warn Msg('E', qq(Failed to roll "$t" one step back.));
	    $rs = 1;
	  }
	} else {
	  if ($prev) {
	    my $t0 = "lbtype:${base}_0$vob"; # store the last eq into hidden type
	    $CT->argv(qw(mklbtype -nc), $t0)->stdout(0)->system;
	    $CT->argv(qw(mkhlink), $EQHL, $t0, $prev)->stdout(0)->system;
	    $CT->argv('lock', $t0)->stdout(0)->system;
	  }
	  push @eq, $eq;
	}
      }
    }
  }
  push @args, @eq if @eq;
  $rs |= $rmtype->args(@args)->system;
  for my $l (@lck) {
    my @out = $lct->argv('lock', $l)->stderr(1)->qx;
    if ($fl and grep /^cleartool: Error/, @out) {
      my ($p, $v) = ($1, $2) if $l =~ /^lbtype:(.*)\@(.*)$/;
      flocklt($p, $v); # loaded while unlocking
    } else {
      print @out;
    }
  }
  exit $rs;
}

=item * CPTYPE

For family types: copy both the "family" (floating) type and its equivalent fixed
incremental type (and all the hierarchy?).

For global types, create the hyperlinks.

=cut

sub _CpType {
  use strict;
  use warnings;
  my ($cpt, @cmt) = @_;
  $CT = new ClearCase::Argv({autochomp=>1});
  my ($src, $dst) = $cpt->args;
  my $glb = $CT->des([qw(-fmt %[type_scope]p)], $src)->qx;
  $glb = 0 if $glb and $glb eq 'ordinary';
  my ($eqt) = grep s/^->\s+(.*)$/$1/, $CT->des([qw(-s -ahl), $EQHL], $src)->qx;
  if ($glb) { #Get the real source
    $src = $CT->des([qw(-fmt %Xn)], $src)->qx;
    $cpt->args($src, $dst);
  }
  my $ret = $cpt->system;
  return $ret if $ret or !($glb or $eqt); # no fallback!
  if ($eqt) {
    my ($deq) = ($eqt =~ /^(.*?)\@/);
    my ($dvb) = ($dst =~ /^.*?(\@.*)$/);
    $deq .= $dvb;
    $ret = $cpt->args($eqt, $deq)->system;
    if (!$ret) {
      if ($glb) {
	$ret = $CT->mkhlink(['GlobalDefinition'], $deq, $eqt)->system;
      } else {
	$ret = $CT->mkhlink([$EQHL], $dst, $deq)->system;
      }
    }
  }
  if ($dst !~ /:/) {
    $dst = "$1$dst" if $src =~ /^(.*?:)/;
  }
  $ret += $CT->mkhlink(['GlobalDefinition'], $dst, $src)->system if $glb;
  return $ret unless $src =~ /^lbtype:/; #no fallback!
  my $rmat = $src;
  $rmat =~ s/lbtype:/attype:Rm/;
  if (!$CT->des(['-s'], $rmat)->stdout(0)->stderr(0)->system) {
    $dst =~ s/lbtype:/attype:Rm/;
    $ret += $cpt->args($rmat, $dst)->system;
    $ret += $CT->mkhlink(['GlobalDefinition'], $dst, $rmat)->system
      if $CT->des([qw(-fmt %[type_scope]p)], $rmat)->stderr(0)->qx eq 'global';
  }
  return $ret;
}
sub cptype {
  use strict;
  use warnings;
  my $cpt = ClearCase::Argv->new(@ARGV);
  $cpt->parse(qw(c|cfile cq|cqe nc replace));
  if (scalar $cpt->args != 2) {
    warn Msg('E', 'Type name required.');
    @ARGV = qw(help cptype);
    ClearCase::Wrapper->help();
    return 1;
  }
  return 1 if ClearCase::Argv->des(['-s'], ($cpt->args)[0])->stdout(0)->system;
  _Preemptcmt($cpt, \&_CpType);
}

=item * SETCS

From the version in DSB.pm 1.14--retaining its additions:

Adds a B<-clone> flag which lets you specify another view from which
to copy the config spec.

Adds a B<-sync> flag. This is similar to B<-current> except that it
analyzes the CS dependencies and only flushes the view cache if the
I<compiled_spec> file is out of date with respect to the
I<config_spec> source file or any file it includes. In other words:
B<setcs -sync> is to B<setcs -current> as B<make foo.o> is to
B<cc -c foo.c>.

Adds a B<-needed> flag. This is similar to B<-sync> above but it
doesn't recompile the config spec. Instead, it simply indicates with
its return code whether a recompile is in order.

Adds a B<-expand> flag, which "flattens out" the config spec by
inlining the contents of any include files.

Add support for incremental label type families, via an
I<##:IncrementalLabels:> attribute in the config spec: generate a
config spec fragment equivalent to the type specified, and include it.
An optional clause of C<-nocheckout> will be propagated to the
generated rules.

=cut

sub setcs {
  use strict;
  use warnings;
  my %opt;
  GetOptions(\%opt, qw(clone=s expand needed sync));
  die Msg('E', "-expand and -sync are mutually exclusive")
    if $opt{expand} && $opt{sync};
  die Msg('E', "-expand and -needed are mutually exclusive")
    if $opt{expand} && $opt{needed};
  my $tag = ViewTag(@ARGV) if grep /^(expand|sync|needed|clone)$/, keys %opt;
  if ($opt{expand}) {
    my $ct = Argv->new([$^X, '-S', $0]);
    my $settmp = ".$::prog.setcs.$$";
    open(EXP, ">$settmp") || die Msg('E', "$settmp: $!");
    print EXP $ct->opts(qw(catcs -expand -tag), $tag)->qx;
    close(EXP);
    $ct->opts('setcs', $settmp)->system;
    unlink $settmp;
    exit $?;
  } elsif ($opt{sync} || $opt{needed}) {
    chomp(my @srcs = qx($^X -S $0 catcs -sources -tag $tag));
    exit 2 if $?;
    (my $obj = $srcs[0]) =~ s/config_spec/.compiled_spec/;
    die Msg('E', "$obj: no such file") if ! -f $obj;
    die Msg('E', "no permission to update $tag's config spec") if ! -w $obj;
    my $otime = (stat $obj)[9];
    my $needed = grep { (stat $_)[9] > $otime } @srcs;
    if ($opt{sync}) {
      if ($needed) {
	ClearCase::Argv->setcs(qw(-current -tag), $tag)->exec;
      } else {
	exit 0;
      }
    } else {
      exit $needed;
    }
  } elsif ($opt{clone}) {
    my $ct = ClearCase::Argv->new;
    my $ctx = $ct->find_cleartool;
    my $cstmp = ".$ARGV[0].$$.cs.$tag";
    Argv->autofail(1);
    Argv->new("$ctx catcs -tag $opt{clone} > $cstmp")->system;
    $ct->setcs('-tag', $tag, $cstmp)->system;
    unlink($cstmp);
    exit 0;
  }
  my $setcs = ClearCase::Argv->new(@ARGV);
  $setcs->parse(qw(force default|current|stream overwrite|rename
		   ctime|ptime tag=s));
  exit $setcs->system if $setcs->flag('force') or $setcs->flag('default')
    or $setcs->flag('overwrite') or $setcs->flag('ctime');
  my ($cs) = $setcs->args;
  if (!$cs) {
    warn Msg('E', 'Configuration spec must be specified.');
    @ARGV = qw(help setcs);
    ClearCase::Wrapper->help();
    return 1;
  }
  my (@cs1, @cs2, $incfam, $noco);
  open my $fh, '<', $cs or die Msg('E', qq(Unable to access "$cs": $!));
  while (<$fh>) {
    if (/^\#\#:IncrementalLabels: *([^\s]+)(\s+-nocheckout)?/) {
      ($incfam, $noco) = ($1, $2?$2:'');
      last;
    }
    push @cs1, $_;
  }
  @cs2 = <$fh> if $incfam;
  close $fh;
  exit $setcs->system unless $incfam;
  my ($lbtype, $vob) = $incfam =~ /^(?:lbtype:)?(.*?)\@(.*)$/;
  die Msg('E', qq(Failed to parse the vob from "$incfam")) unless $vob;
  my $rmat = 'Rm' . ($lbtype =~ /^(.*)_/ ? $1 : $lbtype);
  my @eqlst = _EqLbTypeList($lbtype);
  my $nr = $1 if $eqlst[0] =~ /^.*_(\d+\.\d+)$/;
  die Msg('E', qq($lbtype" is not the top of a label type family))
    unless $nr;
  my $ct = ClearCase::Argv->new({autochomp=>1});
  $tag = $ct->pwv('-s')->qx unless $tag = $setcs->flag('tag');
  die Msg('E', 'Cannot get view info for current view: not a ClearCase object.')
    unless $tag;
  my ($vws) = reverse split '\s+', $ct->lsview($tag)->qx;
  open $fh, '>', "$vws/$lbtype"
    or die Msg('E',
	       qq(Failed to write config spec fragment "$vws/$lbtype": $!\n));
  print $fh qq(element * "{lbtype($_)&&!attr_sub($rmat,<=,$nr)}$noco"\n)
    for @eqlst;
  close $fh;
  $cs .= $$;
  open $fh, '>', $cs or die Msg('E', qq(Could not write "$cs": $!));
  print $fh @cs1;
  print $fh "include $vws/$lbtype\n";
  print $fh @cs2;
  close $fh;
  my $rc = $setcs->args($cs)->system;
  unlink $cs;
  exit $rc; # avoid fallback!
}

=item * DESCRIBE

From DSB.pm

Enhancement. Adds the B<-parents> flag, which takes an integer argument
I<N> and runs the I<describe> command on the version I<N> predecessors
deep instead of the currently-selected version.
into temp files and diffs them. If only one view is specified, compares
against the current working view's config spec.

The parents take the genealogy of contributions into account.

Every version may thus have several parents. In fact, at a given
generation level, the same contributors might occur several times: the
command will show them only once.

Two enhancements to the formats supported by the C<-fmt> flag:

=over 1

=item - C<%PVn> and C<%PSn> take the genealogy into consideration

=item - C<%[...]l> accepts a regexp to filter the labels to be displayed

=back

=cut

sub describe {
  use strict;
  use warnings;
  my $desc = ClearCase::Argv->new(@ARGV);
  $desc->optset(qw(CC WRAPPER));
  $desc->parseCC(qw(g|graphical local l|long s|short
		    fmt=s alabel=s aattr=s ahlink=s ihlink=s
		    cview version=s ancestor
		    predecessor pname type=s cact));
  $desc->parseWRAPPER(qw(parents|par9999=i family=i));
  my $generations = abs($desc->flagWRAPPER('parents') || 0);
  my @args = $desc->args;
  if (grep /^-par/, @args) {
    @args = grep !/^-par/, @args;
    $generations = 1;
  }
  my $rc = 0;
  if ($generations) {
    die Msg('E', 'incompatible flags: "parents" and "family"')
      if $desc->flagWRAPPER('family');
    $CT = new ClearCase::Argv({autochomp=>1});
    my @nargs;
    for my $arg (@args) {
      my $i = $generations;
      my ($ver, $type) =
	$CT->des([qw(-fmt %En@@%Vn\n%m)], $arg)->qx;
      if (!defined($type) or ($type !~ /version$/)) {
	warn Msg('W', "Not a version: $arg");
	next;
      }
      $ver =~ s%\\%/%g;
      my $ele = $ver;
      $ele =~ s%^(.*?)\@.*%$1%; # normalize in case of vob root directory
      my $gen = _DepthGen($ele, $i, $ver);
      my @p = @{$gen->{$ver}{'parents'}};
      while (@p and --$i) {
	my %q;
	for (@p) {
	  $q{$_}++ for @{$gen->{$_}{'parents'}};
	}
	@p = keys %q;
      }
      push(@nargs, @p) if @p;
    }
    scalar @nargs? $desc->args(@nargs) : exit 0; # avoid fallback!
  } else {
    if (defined($desc->flagWRAPPER('family')) or grep /^-fam/, @args) {
      my $nr;
      if (grep /^-fam/, @args) {
	@args = grep !/^-fam/, @args;
	$nr = 0;
      } else {
	$nr = abs($desc->flagWRAPPER('family'));
      }
      my @nargs;
      for my $t (@args) {
	if ($t =~ /^lbtype:.*?(@.*)?$/) {
	  my $v = $1? $1 : '';
	  my @l = _EqLbTypeList($t);
	  $nr = $#l if $nr and $nr > $#l;
	  push @nargs, "lbtype:$_$v" for $nr?(@l)[0..$nr-1]:@l;
	} else {
	  warn Msg('E', "Unable to access '$t': 'lbtype:' prefix required");
	  $rc = 1;
	}
      }
      @nargs? $desc->args(@nargs) : exit $rc; # avoid fallback!
    } elsif (my $fmt = $desc->flagCC('fmt')) {
      if ($fmt =~ s/\%P([VS]n)/\%$1/) {
	my $farg = 0;
	for (@{$desc->{AV_OPTS}{CC}}) {
	  if ($farg) {
	    $_ = $fmt;
	    last;
	  } else {
	    $farg = 1 if /^-fmt$/;
	  }
	}
	$desc->{AV_LKG}{CC}{fmt} = $fmt; # for possible further processing
	$CT = new ClearCase::Argv({autochomp=>1});
	my @nargs;
	for my $arg (@args) {
	  my $i = $generations;
	  my ($ver, $type) =
	    $CT->des([qw(-fmt %En@@%Vn\n%m)], $arg)->qx;
	  if (!defined($type) or ($type !~ /version$/)) {
	    warn Msg('W', "Not a version: $arg");
	    next;
	  }
	  $ver =~ s%\\%/%g;
	  my $ele = $ver;
	  $ele =~ s%^(.*?)\@.*%$1%; # normalize in case of vob root directory
	  my $gen = _DepthGen($ele, 1, $ver);
	  my @p = @{$gen->{$ver}{'parents'}};
	  push(@nargs, @p) if @p;
	}
	scalar @nargs? $desc->args(@nargs) : exit 0; # avoid fallback!
      }
    }
  }
  if (my $fmt = $desc->flagCC('fmt')) { # Maybe already modified
    my $ph = 'PlAcEhOlDeR';
    if ($fmt =~ s/\%\[(.*?)\](N?)l/$ph/) {
      my ($re, $ncom) = (qr($1), $2);
      my @args = $desc->args;
      my $fix = 0;
      for (@{$desc->{AV_OPTS}{CC}}) {
	$fix++;
	last if /^-fmt$/;
      }
      $CT = new ClearCase::Argv({autochomp=>1}) unless $CT;
      for (@args) {
	my @lb = grep /$re/, split / /, $CT->des([qw(-fmt %Nl)], $_)->qx;
	my $lb = $ncom? join(' ', @lb) : @lb? '(' . join(', ', @lb) . ')' : '';
	(my $f = $fmt) =~ s/$ph/$lb/;
	$desc->{AV_OPTS}{CC}->[$fix] = $f;
	$rc |= $desc->args($_)->system('CC');
      }
      exit $rc;
    }
  }
  $rc |= $desc->system('CC');
  exit $rc; # avoid fallback!
}

=item * MKVIEW

Enhancement. Clone, equivalent fixed config spec.
Works only for dynamic views, as I don't know how to get the snapshot
view directory

=cut

sub mkview {
  use strict;
  use warnings;
  use File::Basename;
  use File::Spec;
  use File::Temp qw(tempfile);
  use Sys::Hostname;
  use Date::Format;
  use Date::Parse;
  my $mkv = ClearCase::Argv->new(@ARGV);
  $mkv->optset(qw(CC WRAPPER));
  $mkv->parseCC(qw(snapshot tag=s tcomment=s tmode=s region=s stream=s
		   shareable_dos|nshareable_dos cachesize=s
		   stgloc=s host=s hpath=s gpath=s
		   colocated_server vws=s));
  $mkv->parseWRAPPER(qw(clone=s equiv=s quiet));
  return 0 unless $mkv->flagWRAPPER('clone'); # fallback!
  my $tag = $mkv->flagCC('tag');
  if (!$tag) {
    warn Msg('E', 'View tag must be specified.');
    @ARGV = qw(help mkview);
    ClearCase::Wrapper->help();
    return 1;
  }
  $CT = ClearCase::Argv->new({autochomp=>0});
  my $lsv = $CT->lsview([qw(-l -prop -full)], $mkv->flagWRAPPER('clone'))->qx;
  return 1 unless $lsv;
  my %tm = (unix=>'transparent', msdos=>'insert_cr', strip_cr=>'strip_cr');
  my ($tmo, @prop) = ($tm{$1}, split /\s+/, $2)
    if $lsv =~ /Text mode: (.*?)\n.*Properties: (.*?)\n/s;
  die Msg('E', 'Snapshot views not supported for cloning!')
    if grep /^snapshot$/, @prop or $mkv->flagCC('snapshot');
  my @nsup = grep !/(dynamic|shareable_dos|readwrite|readonly)$/, @prop;
  die Msg('E', "Non supported for cloning: @nsup") if @nsup;
  $tmo = $mkv->flagCC('tmode') if $mkv->flagCC('tmode');
  my $shdo = $mkv->flagCC('shareable_dos');
  ($shdo) = grep /shareable_dos$/, @prop unless $shdo;
  my @k = grep !/(stgloc|host|hpath|gpath|tmode|shareable_dos)/,
    keys %{$mkv->{AV_LKG}{'CC'}};
  my @opts = (map(("-$_", $mkv->flagCC($_)), @k), '-tmo', $tmo, "-$shdo");
  my ($host, $ogpa, $hpa, $own) = ($2, $1, $3, $4)
    if $lsv =~ m{ \QGlobal path: \E(.*?)\n.*
		  \QServer host: \E(.*?)\n.*
		  \Qaccess path: \E(.*?)\n.*
		  \QView owner: \E(?:.*?/)(.*?)\n
	      }xs;
  if ($mkv->flagCC('stgloc')) {
    push @opts, '-stg', $mkv->flagCC('stgloc');
  } else {
    my $pwnam = (getpwuid($<))[0];
    if ($mkv->flagCC('hpath')) {
      $hpa = $mkv->flagCC('hpath');
    } else {
      my $pdir = dirname($hpa);
      if (basename($pdir) eq $own) {
	$hpa = File::Spec->catdir(dirname($pdir), $pwnam, "$tag.vws");
      } else {
	$hpa = File::Spec->catdir($pdir, "$tag.vws");
      }
    }
    my $gpa = $mkv->flagCC('gpath');
    if (!$gpa) {
      my $pdir = dirname($ogpa);
      if (basename($pdir) eq $own) {
	$gpa = File::Spec->catdir(dirname($pdir), $pwnam, "$tag.vws");
      } else {
	$gpa = File::Spec->catdir($pdir, "$tag.vws");
      }
    }
    $host = $mkv->flagCC('host') if $mkv->flagCC('host');
    push @opts, '-host', $host, '-hpa', $hpa, '-gpa', $gpa;
    if (!$mkv->args) {
      if ($host eq hostname or $gpa =~ m%^//%) { #UNC gives 'Access is denied'
	$mkv->args($hpa);
      } else {
	$mkv->args($gpa);	#Should work from anywhere
      }
    }
  }
  $mkv->opts(@opts);
  my $cs = File::Spec->catfile($ogpa, 'config_spec');
  my (@eqlst, $lb, $ts, $lbt, $nr, $rt); #reference time
  if (my $eq = $mkv->flagWRAPPER('equiv')) {
    ($lb, $ts) = split /,/, $eq;
    $CT->autochomp(1);
    $lbt = "lbtype:$lb";
    if ($lb =~ /^lbtype:(.*)$/) {
      $lbt = $lb;
      $lb = $1;
    }
    die Msg('E', qq(Label type not found: "$lb"))
      unless $CT->des(['-s'], $lbt)->qx;
    @eqlst = _EqLbTypeList($lb);
    $nr = $1 if $eqlst[0] =~ /^.*_(\d+\.\d+)$/;
    die Msg('E', qq("$lb" is not the top of a label type family)) unless $nr;
    if ($ts) {
      my $ots = $ts;
      $rt = str2time($ts);
      if (!$rt) {
	$ts =~ tr/-./  /;
	$rt = str2time($ts);
      }
      die Msg('E', qq(Failed to parse "$ots" as a timestamp)) unless $rt;
      die Msg('E', qq("$lb" is not a floating label type))
	unless grep /^->/, $CT->des([qw(-s -ahl), $EQHL], $lbt)->qx;
      my $v = $lb =~ /(@.*)$/? $1 : '';
      while (str2time($CT->des(qw(-fmt %d), "lbtype:$eqlst[0]$v")->qx) > $rt) {
	shift @eqlst;
	last unless @eqlst;
      }
      die Msg('E', qq("$ts" too old: no equivalent baseline)) unless @eqlst;
      $nr = $1 if $eqlst[0] =~ /^.*_(\d+\.\d+)$/;
      my @bits = map{ $_ = 0 unless $_ } strptime($ts);
      $ts = strftime(q(%Y-%m-%dT%H:%M:%S%z), @bits); #Standardize
    }
  }
  if ($mkv->flagWRAPPER('quiet')) {
    $mkv->stdout(0);
    $mkv->stderr(0);
  }
  $mkv->system and exit 1;
  $CT->chview(['-readonly'], $tag)->system if grep /^readonly$/, @prop;
  if (@eqlst) {
    my $l = ($lb =~ /^(.*?)@/? $1 : $lb);
    my $rmat = "Rm$l";
    my $f = "$hpa/$l";
    if ($ts) {
      $f .= ".$ts"
    } else {
      $ts = $CT->des([qw(-fmt %d)], $lbt)->qx;
      $rt = str2time($ts);
      $l =~ s/^(.*)_[\d.]+$/$1/;
    }
    my $trim = sub {
      if ($_ and m%^element\s+(\S+)\s+(?:\.\.\.)?[/\\](\S+)[/\\]LATEST\b.*$%) {
	my $vb = ($1 eq '*'? '' : $1);
	my @bt = split m%[/\\]%, $2;
	if ($vb) {
	  $vb =~ s%^(.*?)[/\\]\.\.\.%$1%;
	  $vb = $CT->des(['-s'], "vob:$vb")->stderr(0)->qx;
	}
	my $ext = $vb? "\@$vb" : '';
	$vb = 'this vob' unless $vb;
	for my $t (@bt) {
	  my $ts = $CT->des([qw(-fmt %d)], "brtype:$t$ext")->stderr(0)->qx;
	  warn Msg('W', qq(Branch type "$t" not found in $vb.\n))
	    unless $ts;
	  return 0 if !$ts or str2time($ts) > $rt;
	}
      }
      return 1;
    };
    my (@cs1, @cs2, $incfam, $noco);
    push @cs1, "time $ts\n";
    open my $fh, '<', $cs or die Msg('E', qq(Unable to access "$cs": $!));
    while (<$fh>) {
      if (/^element .*\s\Q$l\E(\s+-nocheckout)?/) {
	$noco = defined($1)? $1 : '';
	$incfam = 1;
	last;
      }
      push @cs1, $_ if $trim->($_);
    }
    @cs2 = grep $trim->(), <$fh> if $incfam;
    close $fh;
    if ($incfam) {
      open $fh, '>', $f
	or die Msg('E', qq(Failed to write config spec fragment "$f": $!));
      print $fh qq(element * "{lbtype($_)&&!attr_sub($rmat,<=,$nr)}$noco"\n)
	for @eqlst;
      close $fh;
    } else {
      warn Msg('W', qq(No rule based on "$l" was found in "$cs".\n));
    }
    ($fh, $cs) = tempfile(DIR => File::Spec->tmpdir);
    print $fh @cs1;
    if ($incfam) {
      if ($^O eq 'cygwin') {
	$f =~ s%^/cygdrive/(\w)%$1:%;
	$f =~ s%/%\\%g;
      }
      print $fh "include $f\n";
      print $fh @cs2;
    }
    close $fh;
  }
  $CT->setcs(['-tag', $tag], $cs)->exec;
}

=item * ROLLOUT

New command. Deliver by applying labels of the base line family
(applying the fixed increment and moving the floating).

Without the B<-force> option, will perform a prior I<find> to verify
that no I<home merge> (I<rebase>) is needed.

As part of the rollout, the type identifying the development (label
type or branch type) will be I<archived> away if it is used in the
current config spec. This is to ensure that the config spec will
select the new baseline after the rollout. Note that branch types
associated with a family label (used previously with a I<mklabel
-over>) will be archived as well.

Note that the rollout concerns a type at the vob level (or across
several vobs). It is however dependent on the view used, which is
assumed to be a development view selecting the versions being
rolled-out.

The baseline type must be a family type.

The intention is to eventually support global types.
This is disabled for now.
The problem lies in applying labels in multiple vobs, which may be
too slow to be practical.

If the type being delivered (or eventually any branch type it carries
changes from) is global, the rollout will affect all the vobs
concerned. This is a consequence of the fact that the types will get
archived. The baseline type scope will have to match.

=cut

sub rollout {
  use strict;
  use warnings;
  use Cwd;
  my %opt;
  GetOptions(\%opt, qw(force comment=s to=s));
  Assert(@ARGV == 2);		# die with usage msg if untrue
  shift @ARGV;
  my $arg = $ARGV[0];
  die Msg('E', 'The target baseline type is a mandatory argument')
    unless $opt{to};
  my $bl = $opt{to}; $bl =~ s/^lbtype://;
  my $lbl = "lbtype:$bl";
  my @cmt = $opt{comment}? ('-c', $opt{comment}) : '-nc';
  $CT = ClearCase::Argv->new({autochomp=>1});
  my $sil = $CT->clone({stdout=>0, stderr=>0});
  my $fail = $CT->clone({autochomp=>1, autofail=>1});
  $arg =~ s/^.*://; #remove possible prefix
  my $lvob = $CT->des(['-s'], 'vob:.')->stderr(0)->qx; # Maybe not in a vob
  my $vob = $arg =~ /\@(.*)$/? $1 : $lvob;
  if ($bl =~ /\@(.*)$/) {
    die Msg('E', "$bl must be in the same vob as $arg") unless $1 eq $vob;
  } else {
    $lbl .= "\@$vob";
  }
  my $bt = $sil->des(['-s'], "lbtype:$arg")->system; #branch or label type
  die Msg('E', "$arg not found")
    if $bt and $sil->des(['-s'], "brtype:$arg")->system;
  my $targ = $bt? "brtype:$arg" : "lbtype:$arg";
  my @vobs;
  if ($fail->des([qw(-fmt %[type_scope]p)], $targ)->qx eq 'global') {
    die Msg('E', 'Global types are not supported in this version');
    my @hl = grep/^\s+GlobalDefinition/,
      $CT->des([qw(-l -ahl GlobalDefinition)], $targ)->qx;
    if (@hl) {
      my $hl0 = $1 if $hl[0] =~ /^\s+(\S+)/;
      my $mvob = $1 if $CT->des("hlink:$hl0")->qx =~ /->\s+\S+@(\S+)$/;
      if ($mvob ne $vob) {
	$arg  =~ s/@\Q$vob\E$/\@$mvob/;
	$targ =~ s/@\Q$vob\E$/\@$mvob/;
	$bl   =~ s/@\Q$vob\E$/\@$mvob/;
	$lbl  =~ s/@\Q$vob\E$/\@$mvob/;
	$vob = $mvob;
      }
      for (@hl) { push @vobs, $1 if /<-\s+\S+@(\S+)$/; }
    }
  }
  if (!$opt{force}) {
    # Note: cleartool runs in Windows mode when we are on Cygwin
    my @nolog = (MSWIN or CYGWIN)? qw(-log NUL) : qw(-log /dev/null);
    my $hmrg;
    for my $v ($vob, @vobs) {
      if ($CT->findmerge($v, '-fve', $bl, @nolog, '-print')->stderr(0)->qx) {
	$hmrg = 1;
	last;
      }
    }
    die Msg('E', 'Home merge (rebase) needed') if $hmrg;
  }
  if ($sil->des(['-s'], $lbl)->system) {
    my @opt = @cmt;
    push @opt, '-glo' if @vobs;
    _Wrap(qw(mklbtype -fam), @opt, $lbl) and die "\n";
    for (@vobs) {
      my $dst = $lbl;
      $dst =~ s/@\Q$vob\E$/\@$_/;
      _Wrap('cptype', $lbl, $dst); #Fails if the type existed in one vob
    }
  } else {
    if ($CT->des([qw(-s -ahl), $EQHL], $lbl)->qx) {
      die Msg('E', 'The baseline is not locked: conflicting rollout pending?')
	if $ClearCase::Wrapper::MGi::lockbl and !$CT->lslock(['-s'], $lbl)->qx;
      _Wrap(qw(mklbtype -inc), @cmt, $lbl) and die "\n";
    } else {
      die Msg('E', 'The baseline type must be a family type');
    }
  }
  my $la = $arg; $la =~ s/\@.*$//; # Local name: vob in $lbl
  my $lb = $bl; $lb =~ s/\@.*$//;
  my $cwd = getcwd;
  my $rc = 0;
  for my $v ($vob, @vobs) {
    $CT->cd($v)->system;
    $rc += _Wrap(qw(mklabel -over), $la, $lb, $v);
  }
  _Wrap('lock', $lbl) if $ClearCase::Wrapper::MGi::lockbl;
  exit $rc if $rc; #nothing to fallback to, so avoid
  $CT->cd($cwd)->system;
  if ($bt) {
    $rc = _Wrap(qw(mkbrtype -nc -arc), $arg);
  } else {
    my @bt = grep s/^-> //, $CT->des([qw(-s -ahl), $STHL], "lbtype:$arg")->qx;
    if (@bt) {
      my $tag = ViewTag();
      die Msg('E', "view tag cannot be determined") unless $tag;;
      my($vws) = reverse split '\s+', $CT->lsview($tag)->qx;
      my @cs = ();
      no warnings qw(once);
      *::push2cs = sub {chomp; s/\#.*//; push @cs, $_};
      Burrow('CATCS_00', "$vws/config_spec", '::push2cs');
      my @abt = ();
      for my $bt (@bt) {
	my $t = $1 if $bt =~ /^brtype:(.*?)(\@.*)?$/;
	push @abt, $bt if grep /\b\Q$t\E\b/, @cs;
      }
      _Wrap(qw(mkbrtype -nc -arc), @abt) if @abt;
    }
    $rc = _Wrap(qw(mklbtype -nc -arc), $arg);
  }
  exit $rc;
}

=item * ROLLBACK

New command. Roll back to a previous increment.

This is in effect a new rollout, and will result in a new increment of
the baseline family label type.

The change set required as argument is a fixed incremental label type.

=cut

sub rollback {
  use strict;
  use warnings;
  use Sys::Hostname;
  use File::Path qw(remove_tree);
  use Cwd;
  my %opt;
  GetOptions(\%opt, qw(force to=s comment=s));
  Assert(@ARGV == 1);		# die with usage msg if untrue
  die Msg('E', q("to" argument mandatory)) unless $opt{to};
  shift @ARGV;
  my @cmt = ('-c', ($opt{comment} or "rollback to $opt{to}"));
  $CT = ClearCase::Argv->new({autochomp=>1});
  my $sil = $CT->clone({stdout=>0, stderr=>0});
  my $fail = $CT->clone({autochomp=>1, autofail=>1, stdout=>0});
  my $inc = $opt{to};
  $inc =~ s/^.*://; #remove possible prefix
  my $tinc = "lbtype:$inc";
  $fail->des(['-s'], $tinc)->system;
  my $t = $tinc;
  while (my ($t1) =
	   grep s/^<- (.*)$/$1/, $CT->des([qw(-s -ahl), $PRHL], $t)->qx) {
    $t = $t1;
  }
  my ($flt) = grep s/^<- (.*)$/$1/, $CT->des([qw(-s -ahl), $EQHL], $t)->qx;
  die Msg('E', 'Only rolling back to increments (label types)') unless $flt;
  my $tag = ViewTag();
  die Msg('E', "view tag cannot be determined") unless $tag;;
  my($vws) = reverse split '\s+', $CT->lsview($tag)->qx;
  my $used = 0;
  no warnings qw(once);
  my $flt0 = $1 if $flt =~ /^lbtype:(.*)$/;
  my $flt1 = $1 if $flt0 =~ /^(.*?)\@.*$/;
  die Msg('E', "Unexpected value: $flt") unless $flt1;
  *::usedflt = sub {chomp; s/\#.*//; $used |= /element .*?\s\Q$flt1\E(\s|$)/};
  Burrow('CATCS_00', "$vws/config_spec", '::usedflt');
  die Msg('E', "the current view doesn't use $flt1") unless $used;
  my $tmptag = $tag . '_00';
  {
    my $nr = 0;
    $tmptag = $tag . sprintf("_%02d", ++$nr)
      until ($sil->lsview(['-s'], $tmptag)->system or $nr == 99);
    die Msg('E', "100 temporary views not cleaned?") if $nr == 99;
  }
  my $nul = MSWIN? '>NUL' : '>/dev/null';
  my $rmv = sub{
    if (MSWIN or CYGWIN) {
      my ($sto, $uuid) = grep s/^(\s+Global path|View uuid): //,
	$CT->lsview(['-l'], $tmptag)->qx; #Trust the order in the output...
      my $host = $1 if $sto =~ m%^//([^/]+)/%;
      if ($host eq hostname) {
	if (MSWIN) {
	  $sto =~ s%^//$host%C:%;
	} else {
	  $sto =~ s%^//$host%/cygdrive/c%;
	}
      } else {
	die Msg('E', "Not supported yet: rmview on Windows of remote view");
      }
      $CT->endview(['-server'], $tmptag)->system;
      $CT->rmtag(['-view'], $tmptag)->system;
      $CT->unregister([qw(-view -uuid)], $uuid)->system;
      remove_tree($sto);
      my ($use) = grep /\\\\view\\\Q$tmptag\E\s+/, qx(net use);
      system("net use /d $1 $nul") if $use =~ /^Unavailable\s+([A-Z]:)\s+/;
    } else {
      $CT->rmview(['-tag'], $tmptag)->system;
    }
  };
  my $lvob = $CT->des(['-s'], 'vob:.')->stderr(0)->qx;
  my $vob = $1 if $flt0 =~ /^.*?\@(.*)$/; #FIXME: global type...
  my $cwd = getcwd();
  my $chdir = (MSWIN or CYGWIN or $cwd =~ m%^/view/%
		 or ($lvob and $lvob ne $vob));
  if (MSWIN or CYGWIN) {
    my $winpfx = $1 if $cwd =~ m%^(.*?)\Q$lvob\E.*%;
    die Msg('E', "Failed to extract the view prefix for $lvob from $cwd")
      unless $winpfx;
    $CT->cd("${winpfx}$vob")->system;
  } else {
    $CT->cd($vob)->system if $chdir;
  }
  _Wrap(qw(mkview -quiet -tag), $tmptag, '-clone', $tag, '-equiv', $tinc)
    and die "\n";
  if (_Wrap('mklbtype', @cmt, '-inc', $flt)) {
    $rmv->();
    die Msg('E', "Failed to increment $flt1: aborting");
  }
  if (MSWIN or CYGWIN) {
    my @use = grep /^(?:\w+)?\s+[A-Z]:/, qx(net use);
    my @unav = grep /^Unavailable/, @use;
    my $drv;
    if (@unav) {
      $drv = $1 if $unav[0] =~ /^Unavailable\s+([A-Z]):/;
      system(qw(net use /d), "$drv:");
    } else {
      my %used;
      for (@use) { $used{$1}++ if /^\s+([A-Z]):/ }
      for (reverse 'A'..'Z') {
	next if $used{$_};
	$drv = $_;
	last;
      }
    }
    if (!$drv) {
      $rmv->();
      die Msg('E', 'Need a free drive letter to map the $tmptag temp view');
    }
    open(SAVEOUT, ">&STDOUT");
    open(STDOUT, $nul);
    system(qw(net use), "$drv:", "\\\\view\\$tmptag");
    open(STDOUT, ">&SAVEOUT");
    if (MSWIN) {
      $CT->cd("${drv}:$vob")->system;
    } else {
      $drv = lc $drv;
      $CT->cd("/cygdrive/${drv}$vob")->system;
    }
  } else {
    $CT->setview($tmptag)->system;
    $CT->cd($vob)->system if $chdir;
  }
  my $qry = "lbtype_sub($flt1)||attype_sub(Rm$flt1)";
  my @targ;
  for ($CT->find(qw(-a -vis -ele), $qry, qw(-nxn -print))->qx) {
    my $ver = $CT->des(['-s'], $_)->qx;
    push @targ, $ver unless $ver eq $CT->des(['-s'], "$_\@\@/$flt1")->qx
  }
  my @rm = $CT->find(qw(-a -nvis -ver), "lbtype($flt1)", '-print')->qx;
  _Wrap('mklabel', @cmt, $flt1, @targ) if @targ;
  _Wrap('rmlabel', @cmt, $flt1, @rm) if @rm;
  _Wrap('lock', $flt);
  $CT->cd($cwd)->system if $chdir;
  $CT->setview($tag)->system unless MSWIN or CYGWIN;
  $rmv->();
  exit 0; #FIXME: return code
}

=item * ARCHIVE

New command. Synonymous to alternatively mkbrtype or mklbtype -arc

This command assigns the comment in a more intuitive way than its
alternative with mkbrtype: the comment goes to the type being
archived, instead of to the new type being created.

The non-intuitive behaviour is justified by the consistency with the
behaviour of mklbtype -arc, for which no user visible type is created.

Another advantage of this syntax over the alternative is the
possibility to archive in a single command both a lbtype and a brtype
associated, as happens with the rollout command.

Label types and branch types are grouped and processed in this order.

=cut

sub archive {
  use strict;
  use warnings;
  my %opt;
  GetOptions(\%opt, qw(nc c|cfile=s));
  if (keys %opt > 1) {
    warn Msg('E', 'Only one comment option supported');
  } elsif (@ARGV > 1) {
    shift @ARGV;
    my @lbt = grep /^lbtype:/, @ARGV;
    my @brt = grep /^brtype:/, @ARGV;
    if (@lbt + @brt != @ARGV) {
      my @unk = grep !/(br|lb)type:/, @ARGV;
      warn Msg('E', "'lbtype: or 'brtype:' prefix required for '@unk'");
    } else {
      my @opt = qw(-arc);
      if ($opt{nc}) {
	unshift @opt, '-nc';
      } elsif (%opt) {
	my ($k, $v) = each %opt;
	unshift @opt, "-$k", $v;
      }
      my $rc = _Wrap('mklbtype', @opt, @lbt) if @lbt;
      $rc   += _Wrap('mkbrtype', @opt, @brt) if @brt;
      exit $rc; #avoid fallback!
    }
  } else {
    warn Msg('E', 'Type name required.');
  }
  @ARGV = qw(help archive);
  ClearCase::Wrapper->help();
  return 1;
}

=item * LSTYPE

This function is provided to work around a bug in ClearCase which IBM
does not admit as a bug.

I<lstype> will issue errors (not warnings) in two scenarios related to
I<GlobalDefinition> hyperlinks. In one case, it will abort,
i.e. return an incomplete list of types.

The wrapper function will convert the errors into warnings in case no
admin vob is concerned, i.e. when the issue detected has in fact a
lighter impact than the effect of aborting I<lstype>.

The condition under which I<lstype> would abort on error related to
MultiSite synchronization, and cannot be avoided. The resulting
behaviour will thus appear to happen randomly, and for transient
periods of time.

The behaviour of I<lstype> is thus both inconsistent and unpredictable.

The fix offers an informative warning instead of an error.
It is restricted to I<lbtype>s, and skipped in presence of admin vobs.

Note: the result is significantly (~5x) slower, when the standard
command works.

=cut

sub lstype {
  use strict;
  use warnings;
  my $lst = ClearCase::Argv->new(@ARGV);
  $lst->parse(qw(local long|short|nostatus fmt=s obsolete kind=s invob=s
		 unsorted));
  return 0 if $lst->flag('local') or $lst->flag('long') and $lst->flag('fmt')
    or !$lst->flag('kind') or $lst->flag('kind') ne 'lbtype'
      or (grep/^-[ls]|nos/, $lst->opts) > 1;
  $CT = new ClearCase::Argv({autochomp=>1});
  my $v = $lst->flag('invob') || '.';
  return 0 if $CT->des([qw(-s -ahl AdminVOB)], "vob:$v")->qx;
  my (@lopts, @dopts) = ();
  push @lopts, qw(-local -kind lbtype -nostatus),
    grep{defined} ($lst->flag('obsolete') and '-obs'),
      ($lst->flag('invob') and ('-invob', $lst->flag('invob'))),
	($lst->flag('unsorted') and '-uns');
  my $sil = $CT->clone({stderr=>0});
  my $err = $CT->clone({stdout=>0, stderr=>1});
  my $lock = !grep /-nos/, $lst->opts;
  my $fmt = $lst->flag('fmt');
  push @dopts, grep{defined} grep(/^-[sl]/, $lst->opts), $fmt && ('-fmt', $fmt);
  push @dopts, '-s' unless $lock; #i.e. if -nostatus
  $lst->opts(@lopts);
  my $ext = $lst->flag('invob')? '@' . $lst->flag('invob') : '';
  my $cb = sub {
    my $t = shift; $t =~ y/\r//d; chomp $t;
    my $lbt = "lbtype:${t}$ext";
    if (my $e = $err->des(['-s'], $lbt)->qx) {
      if (my @l = grep{s/^\s+(G.*?)\s.*$/hlink:$1/}
	    $CT->des([qw(-l -local -ahl GlobalDefinition)], $lbt)->qx) {
	my %oid;
	for ($CT->dump($l[0])->qx) {
	  $oid{$1} = $2 if /^\s+to (\w+)=(.*)$/;
	}
	if ($oid{vob} and $oid{obj}) {
	  my $vob = $sil->lsvob([qw(-s -fam), $oid{vob}])->qx;
	  if ($vob) {
	    my $obj = $sil->des(['-s'], "oid:$oid{obj}\@$vob")->qx;
	    if (!$obj) {
	      warn Msg('W', "Could not find the global definition of "
			 . "'$t' in '$vob'. Synchronization issue?");
	    return 1;
	    }
	  } else {
	    warn Msg('W', "Could not find the vob containing the "
		       . "global definition for '$t': $oid{vob}");
	    return 1;
	  }
	}
      }
      print STDERR "$e\n";
    } else {
      my @opts = ($lock and $CT->lslock(['-s'], $lbt)->qx)?
	('-fmt', '%n (%[locked]p)\n') : @dopts;
      $CT->des([@opts], $lbt)->system;
    }
    return 1;			#continue
  };
  $lst->pipecb($cb);
  $lst->pipe; # no fallback!
  exit 0;
}

=item * ANNOTATE

This implementation serves two purposes:

=over 2

=item - fix some errors resulting from our breaking a tool assumption

=item - provide a greppable standard output

=back

The default behaviour assumes that related changes all took place
within the same I<line of descent> (i.e. physical branch hierarchy).

This assumption is defeated in the case of the I<BranchOff> strategy,
with which ancestors are typically merged from branches outside this
line of descent.

The C<-all> flag allows to examine changes beyond the line of descent,
but results in spurious C<UNRELATED> annotations (C<Merge> arrows are
ignored at large, although they clearly I<relate> changes...)

In the context of the I<source container layout fixing>, the
assumption results in spurious errors, when the version referenced is
outside the line of descent, even if otherwise perfectly valid.

The wrapper forces the injection of the C<-all> flag for files, and
resorts to lshistory for directories.

As C<Merge> arrows are ignored, the reference version for a new branch
spawned off the root of the tree is systematically empty (unless
fixing the layout of source containers).

This is the reference towards which changes are reported. It results
that the same lines are reported as added multiple times.

Better fixing of the problems described above is only provided in the
context of the additional options below.

The default behaviour of C<annotate> is file oriented. The file
produced is of a verbose format, which would contain long lines. These
ones are thus truncated.

This defeats most of the usefulness of the tool.

One offers two alternative new flags to produce line oriented output:

=over 2

=item -line: line oriented output suitable for grepping, with no truncation

=item -grep: use Perl to grep the output of I<annotate>

=back

=cut

sub annotate {
  use strict;
  use warnings;
  my (%opt, %ignore, %out);
  GetOptions(\%out, qw(line grep=s));
  GetOptions(\%ignore, qw(all rm));
  GetOptions(\%opt, qw(nco out=s));
  $ARGV[0] = 'annotate'; #make 'ct an' work
  my $ann = ClearCase::Argv->new(@ARGV);
  $ann->parse(qw(short|long fmt=s rmfmt=s nheader ndata force));
  my $fout = ($opt{out} and $opt{out} ne '-')? $opt{out} : '';
  die Msg('E', "Incompatible options.") if keys %out and ($ann->opts or $fout);
  my @args = $ann->args;
  die Msg('E', "$fout must be a directory") if $fout and @args>1 and !-d $fout;
  my @dirs = grep {-d $_} @args;
  if (@dirs) {
    @args = grep {!-d $_} @args;
    if (!$ann->flag('ndata') and !keys %out) {
      warn Msg('E', "Version has no data $_") for @dirs;
      die "\n" unless @args;
    }
  }
  $CT = new ClearCase::Argv({autochomp=>1});
  my $re = $out{grep}? qr/$out{grep}/ : '';
  if (@dirs) {
    my $rc = 0;
    if (keys %out) {
      for my $d (@dirs) {
	my %t;
	for ($CT->lshis([qw(-d -fmt), '%Nd %Vn %u %o:%Nc\n'], $d)->qx) {
	  if(/^([^:]+):(.*)$/) {
	    push @{$t{$1}}, $2;
	  } else {
	    push @{$t{$1}}, $_;
	  }
	}
	if ($re) {
	  for my $k (reverse sort keys %t) {
	    print "$k $_\n" for grep /$re/, @{$t{$k}};
	  }
	} else {
	  for my $k (reverse sort keys %t) {
	    print "$k $_\n" for @{$t{$k}};
	  }
	}
      }
    } else {
      my @opts = $ann->opts;
      $ann->opts('-out', $opt{out}, @opts) if $opt{out};
      $rc = $ann->args(@dirs)->system;
      $ann->opts(@opts);
    }
    exit $rc unless @args;
  }
  if (!$opt{nco}) {
    my @co = $CT->lsco([qw(-cview -s)], @args)->qx;
    if (@co) {
      @args = grep {!$CT->lsco([qw(-cview -s)], $_)->qx} @args;
      warn Msg('E',
	       "You may not annotate a checked-out version (use -nco flag): $_")
	for @co;
      die "\n" unless @args;
    }
  }
  if (keys %out) {
    $ENV{CLEARCASE_TAB_SIZE} = 2 unless $ENV{CLEARCASE_TAB_SIZE};
    no warnings qw(qw);
    my $fmt = $ENV{CCMGI_ANNF} || '%Sd %25.-25Vn %-9.9u,|,%Sd %25.-25Vn %-9.9u';
    $ann->opts(qw(-all -out - -nhe -rmf), ' D ', '-fmt', $fmt);
    $opt{out} = '-';
  } else {
    $ann->opts(qw(-all -out -), $ann->opts);
  }
  $ann->opts('-nco', $ann->opts) if $opt{nco};
  my $dir = -d $fout? $fout : '';
  my $rc = 0;
  for my $a (@args) {
    my @out = $ann->args($a)->qx;
    my @mver = grep{s%^\s+-> (\S+)$%$1%} $CT->lsvtree([qw(-s -merge)], $a)->qx;
    my %add;
    for my $v (@mver) { #versions merged to
      next if $v =~ /CHECKEDOUT$/; #annotate works only on checked-in versions
      my $ev = "$a\@\@$v";
      my ($prd) = grep{s/^<- (.*)/$1/} $CT->des([qw(-s -ahl Merge)], $ev)->qx;
      my @new = grep{s%^>\s+(.*)$%$1%} $CT->diff(['-diff'], $prd, $ev)->qx;
      $add{$v}->{$_}++ for @new;
    }
    if (keys %out) {
      map {s/^(\d\S+\s+\S+ \S+\s+)U /$1  /} @out;
      my @prune = @out;
      @out = ();
      for (@prune) {
	if (/^\S+\s+(\S+) \S+\s+(?:D\s+)?(.*)$/) {
	  push @out, $_ if !defined($add{$1}) or $add{$1}->{$2};
	} else {
	  push @out, $_;
	}
      }
    } else {
      map {s/ UNRELATED /           /} @out;
    }
    if ($opt{out} and $opt{out} eq '-') {
      if ($re) {
	my $pfl = $ENV{CCMGI_ANNL} || 49; # format length: 10 + 1 + 25 + 9 + 3
	print for grep {substr($_, $pfl) =~ /$re/} @out;
      } else {
	print for @out;
      }
    } else {
      require File::Slurp;
      require File::Basename;
      File::Basename->import('basename');
      require File::Spec;
      my $f = "$a.ann";
      $f = ($dir? File::Spec->catfile($dir, basename($f)): $fout) if $fout;
      $rc |= File::Slurp::write_file($f, @out);
      print qq(Annotated result written to "$f".\n);
    }
  }
  exit $rc;
}

=item * SYNCTREE

This function offers an alternative interface, somewhat simplified,
with different flags and default options, to the standalone
I<synctree> script from I<ClearCase::SyncTree>.

The implementation is however imported from the module.

This is used to update a directory tree or a list of colocated elements.

To create a tree in place, use preferably C<mkelem -rec>.

The supported flags are:

=over 1

=item B<-from>

=item B<-lab/el>

=item B<-sum/mary>

=item B<-c/omment>

=item B<-quiet>

=item B<-force>: mutually exclusive with B<rollback>

=item B<-rollback>: this restores the default behaviour of the original
I<synctree>. See below: B<stop>

=back

The default options used are (with respect to the standalone script):

=over 1

=item ci/checkin

=item yes: no preview option, no prompting for confirmation

=item rmname, if only one argument, and a directory

=item rellinks: turn absolute symlinks within sbase into relative ones

=item reuse: attempt to avoid creating evil twins

=item vreuse, if label: do not create identical versions if can label old ones

=item cr: config records are respected -- using "checkin -from"

=item stop: abort in case of error.

Typically, you need to fix the cause of the problem, possibly checkin
recursively with the -revert option, remove any remaining view private
files, and restart to continue.

The default is changed from the original I<synctree> because the
I<reuse> option tends to bring in hidden directories which may have
wrong protections. Such errors are thus not infrequent, and the
cleanup makes them cumbersome to fix.

=back

=cut

sub synctree {
  use strict;
  use warnings;
  use ClearCase::SyncTree 0.60; #warning: sort interpreted as function
  use Benchmark;
  use Cwd;
  my %opt;
  GetOptions(\%opt, qw(from=s summary label=s comment=s force rollback));
  die Msg("-force and -rollback are mutually exclusive")
    if $opt{force} and $opt{rollback};
  Assert(@ARGV > 1);		# die with usage msg if untrue
  shift @ARGV;
  my @argv = ();
  for (@ARGV) {
    $_ = readlink if -l && defined readlink;
    push @argv, MSWIN ? glob($_) : $_;
  }
  ClearCase::Argv->inpathnorm(0);
  if ($opt{summary}) {
    $Benchstart = new Benchmark;
    ClearCase::Argv->summary;	# start keeping stats
    END {
      if ($Benchstart) {
	# print out the stats we kept
	print STDERR ClearCase::Argv->summary;
	# show timing data
	my $timing = timestr(timediff(new Benchmark, $Benchstart));
	print "Elapsed time: $timing\n";
      }
    }
  }
  my $sync = ClearCase::SyncTree->new;
  if (@argv == 1 and (-d $argv[0] or ! -e $argv[0])) {
    $opt{dbase} = $sync->dstbase($argv[0]);
    @argv = ();
  } else {
    $opt{dbase} = $sync->dstbase(dirname($argv[0]));
  }
  die Msg('E', "no such directory $opt{from}") unless -d $opt{from};
  $opt{sbase} = Cwd::realpath($opt{from});
  $opt{sbase} =~ s%\\%/%g if MSWIN;
  ClearCase::Argv->quiet(1) if $opt{quiet};
  if ($opt{label}) {
    my $ct = $sync->clone_ct({autofail=>0, stderr=>0});
    my $dvob = $ct->des(['-s'], "vob:$opt{dbase}")->qx;
    my $lbtype = "lbtype:$opt{label}\@$dvob";
    $sync->lblver($opt{label}) if $opt{vreuse} && $ct->des(['-s'], $lbtype)->qx;
    my ($inclb) = grep s/-> (lbtype:.*)$/$1/,
      $ct->des([qw(-s -ahl EqInc)], $lbtype)->qx;
    if ($inclb) {
      die "$prog: Error: incremental label types must be unlocked\n"
	if $ct->lslock(['-s'], $lbtype, $inclb)->qx;
      $inclb =~ s/^lbtype:(.*)@.*$/$1/;
      $sync->inclb($inclb);
    }
  }
  {
    my @src;
    if (@argv) {
      my @abort;
      for my $arg (@argv) {
	if (-r $arg) {
	  my $real = Cwd::realpath($arg);
	  $real = $sync->normalize($real);
	  if ($real =~ s/^\Q$opt{dbase}\E/$opt{sbase}/ and -r $real) {
	    push @src, $real;
	    next;
	  }
	}
	push @abort, $arg;
      }
      die Msg('E', "argument" . (@abort > 1? 's' : '') . " not found:\n  "
		. join("\n  ", @abort)) if @abort;
    } else {
      push @src, $opt{sbase};
    }
    local $SIG{__WARN__} = sub { die Msg('E', @_) };
    my %cfg;
    $cfg{wanted} = \&_Wanted;
    find(\%cfg, $_) for @src;
  }
  $sync->reuse(1);
  $sync->vreuse(1) if $opt{label};
  $sync->dstcheck;
  my $rc = 0;
  $sync->err_handler(sub {exit 2}) unless $opt{cleanup} or $opt{force};
  $sync->err_handler(\$rc) if $opt{force};
  $opt{comment} = 'imported with "ct synctree"' unless $opt{comment};
  $sync->comment($opt{comment});
  $sync->srcbase($opt{sbase});
  $sync->srcmap(%Xfer);
  $sync->remove(1) unless @argv;
  $sync->rellinks(1);
  $sync->analyze;
  $sync->rmdirlinks;
  $sync->add;
  $sync->modify;
  $sync->subtract unless @argv;
  $sync->label($opt{label}) if $opt{label};
  exit $rc unless $sync->get_addhash || $sync->get_modhash
		                     || $sync->get_sublist || $sync->_lsco;
  $sync->err_handler(\$rc);
  if ($ENV{FSCBROKER}) {
    require ClearCase::FixSrcCont; #optional fix of source container
    my $ct = $sync->clone_ct({autofail=>0});
    for ($ct->lsco([qw(-cview -me -a -fmt), '%PVn %[hlink:Merge]p\n'],
		   $opt{dbase})->qx) {
      next unless m%^\S+/0 "Merge\@.*?" <- "(.*?)"%;
      ClearCase::FixSrcCont::add2fix($1);
    }
    ClearCase::FixSrcCont::runfix();
  }
  $sync->checkin;
  exit $rc;
}

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 IONA Technologies PLC (until v0.05),
2008-2012 Marc Girod (marc.girod@gmail.com) for later versions.
All rights reserved.
This Perl program is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), ClearCase::Wrapper, ClearCase::Wrapper::DSB, ClearCase::Argv,
ClearCase::SyncTree

=cut
