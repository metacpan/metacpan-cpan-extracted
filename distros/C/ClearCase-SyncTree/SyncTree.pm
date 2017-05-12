package ClearCase::SyncTree;

$VERSION = '0.60';

require 5.004;

use strict;

use Cwd;
use File::Basename;
use File::Compare;
use File::Copy;
use File::Find;
use File::Path;
use File::Spec 0.82;
use ClearCase::Argv 1.34 qw(chdir);

use constant MSWIN => $^O =~ /MSWin|Windows_NT/i ? 1 : 0;
use constant CYGWIN => $^O =~ /cygwin/i ? 1 : 0;

my $lext = '.=lnk=';	# special extension for pseudo-symlinks

sub new {
    my $proto = shift;
    my $class;
    if ($class = ref($proto)) {
	# Make a (deep) clone of the invoking instance
	require Clone;
	Clone->VERSION(0.12);	# 0.10 has a known bug
	return Clone::clone($proto);
    }
    $class = $proto;
    my $self = {@_};
    bless $self, $class;
    $self->comment('By:' . __PACKAGE__);
    # Default is to sync file modes unless on ^$%#* Windows.
    $self->protect(1);
    # Set up a ClearCase::Argv instance with the appropriate attrs.
    $self->ct;
    # By default we'll call SyncTree->fail on any cleartool error.
    $self->err_handler($self, 'fail');
    # Set default file comparator.
    $self->cmp_func(\&File::Compare::compare);
    return $self;
}

sub err_handler {
    my $self = shift;
    my $ct = $self->ct;
    if (@_ >= 2) {
	my($obj, $method) = @_;
	$method = join('::', ref($obj), $method) unless $method =~ /::/;
	$ct->autofail([\&$method, $obj]);
    } else {
	$ct->autofail(@_);
    }
}

# For internal use only.  Provides a std msg format.
sub _msg {
    my $prog = basename($0);
    my $type = shift;
    my $msg = "@_";
    chomp $msg;
    return "$prog: $type: $msg\n";
}

# For internal use only.  A synonym for die() with a std error msg format.
sub fatal {
    die _msg('Error', @_);
}

# For internal use only.  A synonym for warn() with a std error msg format.
sub warning {
    warn _msg('Warning', @_);
}

# For internal use only.  Returns the ClearCase::Argv object.
sub ct {
    my $self = shift;
    return $self->{ST_CT} if $self->{ST_CT};
    if (!defined(wantarray)) {
	my $ct = ClearCase::Argv->new({autochomp=>1, outpathnorm=>1});
	$ct->syxargs($ct->qxargs);
	$self->{ST_CT} = $ct;
    }
    return $self->{ST_CT};
}

# For internal use only.  Returns a clone of the ClearCase::Argv object.
sub clone_ct {
    my $self = shift;
    my $ct = $self->ct->clone(@_);
    my $af = $self->ct->autofail
          unless $_[0] and (ref($_[0]) eq 'HASH') and exists $_[0]->{autofail};
    $ct->autofail($af) if $af && ref($af); #Cloning doesn't share the value
    return $ct;
}

sub gen_accessors {
    my @key = map {uc} @_;
    no strict 'refs';
    for (@key) {
	my $var = "ST_$_";
	my $meth = lc;
	*$meth = sub {
	    my $self = shift;
	    $self->{$var} = shift if @_;
	    return $self->{$var};
	}
    }
}
gen_accessors(qw(protect remove reuse vreuse lblver ignore_co overwrite_co
		 snapdest ctime lbtype inclb cmp_func rellinks dstview));
sub gen_flags {
    my @key = map {uc} @_;
    no strict 'refs';
    for (@key) {
	my $var = "ST_$_";
	my $meth = lc;
	*$meth = sub {
	    my $self = shift;
	    $self->{$var} = 1 if $_[0] || !defined(wantarray);
	    return $self->{$var};
	}
    }
}
gen_flags(qw(label_mods no_cr no_cmp));

sub comment {
    my $self = shift;
    my $cmnt = shift;
    if (ref $cmnt) {
	$self->{ST_COMMENT} = $cmnt;
    } elsif ($cmnt) {
	$self->{ST_COMMENT} = ['-c', $cmnt];
    }
    return $self->{ST_COMMENT};
}

sub normalize {
    my $self = shift;
    chomp(my $path = shift);
    my $dv = $self->dstview;
    my $md = $self->mvfsdrive if MSWIN;
    for ($path) {
	if (MSWIN) {
	    s%^$md:%%;
	    s%^[\\/]\Q$dv%%;
	    s%\\%/%g;
	    $_ = "$md:/$dv$_";
	} elsif (CYGWIN) {
	    # 4 cases: unc; /view/x user mount; view drive; mvfs drive/tag
	    s%^/(/?view/$dv|cygdrive/\w(/$dv)?)%%;
	    $_ = "//view/$dv$_";
	} else {
	    s%^/view/$dv%%;
	    $_ =  "/view/$dv$_";
	}
	s%/\.?$%%;
    }
    return $path;
}

sub canonicalize {
    my $self = shift;
    my $base = shift;
    for (@_) {
	$_ = File::Spec->canonpath(join('/', $base, $_))
			if $_ && ! File::Spec->file_name_is_absolute($_);
    }
}

# Returns -other and -do private files. Checkouts are handled separately.
sub _lsprivate {
    my $self = shift;
    my $implicit_dirs = shift;
    my $base = $self->dstbase;
    my $dv = $self->dstview;
    my $ct = $self->clone_ct({autofail=>0, stderr=>0});
    my @vp;
    for ($ct->argv('lsp', [qw(-oth -do -s -inv), "$base/.", '-tag', $dv])->qx) {
	$_ = $self->normalize($_);
	push(@vp, $_) if m%^\Q$base/%;
    }
    push(@vp, grep {$ct->des([qw(-s)], "$_/.\@\@")->stdout(0)->system}
	   @{$self->{ST_IMPLICIT_DIRS}})
			         if $self->{ST_IMPLICIT_DIRS} && $implicit_dirs;
    return @vp;
}

sub _lsco {
    my $self = shift;
    my $base = $self->_mkbase;
    my $ct = $self->clone_ct;
    my $sil = $self->clone_ct(stderr=>0, autofail=>0);
    my %co;
    for ($ct->lsco([qw(-s -cvi -a)], $base)->qx) {
	$_ = $self->normalize($_);
	$co{$_}++ if m%^\Q$base/% || $_ eq $base;
    }
    for my $dir (@{$self->{ST_IMPLICIT_DIRS}}) {
	my $dad = dirname($dir);
	$co{$dad}++ if $sil->lsco([qw(-s -cvi -d)], $dad)->qx;
    }
    return wantarray? sort keys %co : scalar keys %co;
}

sub mvfsdrive {
    my $self = shift;
    if (MSWIN && ! $self->{ST_MVFSDRIVE}) {
       no strict 'subs';
       use vars '$Registry';
       require Win32::TieRegistry;
       # HKLM is read-only for non-admins so open read-only
       Win32::TieRegistry->import('TiedRef', '$Registry', qw(KEY_READ));
       my $LMachine = $Registry->Open('LMachine', {Access => KEY_READ});
       $self->{ST_MVFSDRIVE} = $LMachine->{SYSTEM}->
	        {CurrentControlSet}->{Services}->{Mvfs}->{Parameters}->{drive};
       die "$0: Error: unable to find MVFS drive" unless $self->{ST_MVFSDRIVE};
    }
    return $self->{ST_MVFSDRIVE};
}

sub ccsymlink {
    my $dst = shift;
    return 1 if -l $dst;
    return 0 unless MSWIN || CYGWIN;
    my $ct = new ClearCase::Argv({autochomp=>1, stderr=>0});
    return $ct->des([qw(-fmt %m)], $dst)->qx eq 'symbolic link';
}

# readlink might work under some conditions (CC version, mount options, ...)
sub readcclink {
    my $dst = shift;
    my $ret = readlink $dst;
    return $ret if $ret || !(MSWIN || CYGWIN);
    my $ct = new ClearCase::Argv({autochomp=>1});
    $ret = $ct->ls($dst)->qx;
    $ret =~ s%\\%/%g if MSWIN;
    return (($ret =~ s/^.*? --> (.*)$/$1/)? $ret : '');
}

sub srcbase {
    my $self = shift;
    if (@_) {
	my $sbase = File::Spec->rel2abs(shift);
	$sbase =~ s%\\%/%g;	# rel2abs forces native (\) separator
	$sbase =~ s%/\.$%%;	# workaround for bug in File::Spec 0.82
	# File::Spec::Win32::rel2abs leaves trailing / on drive letter root.
	$sbase =~ s%/*$%% if $sbase ne '/';
	$self->{ST_SRCBASE} = $sbase;
	*src_slink = sub { return -l shift };
	*src_rlink = sub { return readlink shift };
	if (MSWIN || CYGWIN) {
	    my $ct = $self->clone_ct({autofail=>1, autochomp=>1});
	    my $olddir = getcwd;
	    $ct->_chdir($sbase) || die "$0: Error: $sbase: $!";
	    if ($ct->pwv(['-s'])->qx !~ /\s+NONE\s+/) {
		*src_slink = \&ccsymlink;
		*src_rlink = \&readcclink;
	    }
	    $ct->_chdir($olddir);
	}
    }
    return $self->{ST_SRCBASE};
}

sub dstbase {
    my $self = shift;
    if (@_) {
	my $dbase = shift;
	-e $dbase || mkpath($dbase, 0, 0777) || die "$0: Error: $dbase: $!";
	my $ct = $self->clone_ct({autofail=>1, autochomp=>1});
	my $olddir = getcwd;
	$ct->_chdir($dbase) || die "$0: Error: $dbase: $!";
	$dbase = getcwd;
	my $dv = $ct->pwv(['-s'])->qx;
	die "$0: Error: destination base ($dbase) not in a view/VOB context"
						if !$dv || $dv =~ m%\sNONE\s%;
	$self->dstview($dv);
	# We need to derive the current vob of the dest path, which we
	# do by cd-ing there temporarily and running "ct desc -s vob:.".
	# But with a twist because of @%$*&# Windows.
	my $dvob;
	if (!($dvob = $self->dstvob)) {
	    # We need this weird hack to get a case-correct version of the
	    # dest path, in case the user typed it in random case. There
	    # appears to be a bug in CC 4.2; "ct desc vob:foo" fails if
	    # "foo" is not the right case even if MVFS is set to be
	    # case insensitive. This is caseid v0869595, bugid CMBU00055321.
	    # Since Windows mount points must be at the root level,
	    # we assume the vob tag must be the root dir name. We must
	    # still then look that up in lsvob to get the tag case right.
	    if (MSWIN) {
		my @vobs = $ct->lsvob(['-s'])->qx;
		my $dirpart = (File::Spec->splitpath($dbase, 1))[1];
		for my $name (File::Spec->splitdir($dirpart)) {
		    last if $dvob;
		    next unless $name;
		    for my $vob (@vobs) {
			if ($vob =~ m%^[/\\]$name$%i) {
			    ($dvob = $vob) =~ s%\\%/%g;
			    last;
			}
		    }
		}
	    } else {
		$dvob = $ct->desc(['-s'], "vob:.")->qx;
	    }
	    $self->dstvob($dvob);
	}
	# On Windows, normalize the specified dstbase to use the
	# MVFS drive (typically M:), e.g. M:\view-name\vob-tag\path...
	# This avoids all kinds of problems with using the view
	# via a different drive letter or a UNC (\\view) path.
	# Similarly, on UNIX we normalize to a view-extended path
	# even if we're already in a set view because it's the
	# lowest common denominator. Also, if the set view differs
	# from the 'dest view', the dest view should win.
	if (MSWIN) {
	    $dbase =~ s%\\%/%g;
	    use vars '%RegHash';
	    require Win32::TieRegistry;
	    Win32::TieRegistry->import('TiedHash', '%RegHash');
	    my $mdrive = $self->mvfsdrive;
	    $dbase = getcwd;
	    $dbase =~ s%.*?$dvob%$mdrive:/$dv$dvob%i;
	} else {
	    $dbase = getcwd;
	    if (CYGWIN) {
	        $dbase =~ s%^/(/?view/$dv|cygdrive/\w)%%;
		$dbase = "//view/$dv$dbase";
	    } else {
	        $dbase =~ s%^/view/$dv%%;
		$dbase = "/view/$dv$dbase";
	    }
	}
	$ct->_chdir($olddir) || die "$0: Error: $olddir: $!";
	$self->{ST_DSTBASE} = $dbase;
	(my $dvb = $dbase) =~ s%^(.*?$dvob).*$%$1%;
	$self->snapdest(1) unless -e "$dvb/@@";
    }
    return $self->{ST_DSTBASE};
}

# We may have created a view-private parent tree, so must
# work our way upwards till we get to a versioned dir.
sub _mkbase {
    my $self = shift;
    if (! $self->{ST_MKBASE}) {
	my $mbase = $self->dstbase;
	my $dvob = $self->dstvob;
	(my $dext = $mbase) =~ s%(.*?$dvob)/.*%$1%;
	my $ct = $self->clone_ct({stdout=>0, stderr=>0, autofail=>0});
	while (1) {
	    last if length($mbase) <= length($dext);
	    last if -d $mbase && ! $ct->desc(['-s'], "$mbase/.@@")->system;
	    push(@{$self->{ST_IMPLICIT_DIRS}}, $mbase);
	    $mbase = dirname($mbase);
	}
	$self->{ST_MKBASE} = $mbase;
    }
    return $self->{ST_MKBASE};
}

sub dstvob {
    my $self = shift;
    if (@_) {
	$self->{ST_DSTVOB} = shift;
	$self->{ST_DSTVOB} =~ s%\\%/%g;
    }
    return $self->{ST_DSTVOB};
}

sub srclist {
    my $self = shift;
    my $type = ref($_[0]) ? ${shift @_} : 'NORMAL';
    my $sbase = $self->srcbase;
    die "$0: Error: must specify src base before src list" if !$sbase;
    for (@_) {
	next if $_ eq $sbase;
	if (m%^(?:[a-zA-Z]:)?$sbase[/\\]*(.+)%) {
	    $self->{ST_SRCMAP}->{$1}->{type} = $type;
	} elsif (-e "$sbase/$_") {
	    $self->{ST_SRCMAP}->{$_}->{type} = $type;
	} else {
	    warn "Warning: $_: no such file or directory\n";
	}
    }
}

sub srcmap {
    my $self = shift;
    my $type = ref($_[0]) ? ${shift @_} : 'NORMAL';
    my %sdmap = @_;
    my $sbase = $self->srcbase;
    my $dbase = $self->dstbase;
    die "$0: Error: must specify src base before src map" if !$sbase;
    die "$0: Error: must specify dst base before src map" if !$dbase;
    for (keys %sdmap) {
	if (m%^(?:[a-zA-Z]:)?\Q$sbase\E[/\\]*(.*)$%) {
	    my $key = $1;
	    $self->{ST_SRCMAP}->{$key}->{type} = $type;
	    my($dst) = ($sdmap{$_} =~ m%^\Q$dbase\E[/\\]*(.+)$%);
	    $self->{ST_SRCMAP}->{$key}->{dst} = $dst;
	} elsif (-e $_) {
	    $self->{ST_SRCMAP}->{$_}->{type} = $type;
	    if ($sdmap{$_} =~ m%^\Q$dbase\E[/\\]*(.+)$%) {
		$self->{ST_SRCMAP}->{$_}->{dst} = $1;
	    } else {
		$self->{ST_SRCMAP}->{$_}->{dst} = $sdmap{$_};
	    }
	} elsif (-e "$sbase/$_") {
	    $self->{ST_SRCMAP}->{$_}->{type} = $type;
	    $self->{ST_SRCMAP}->{$_}->{dst} = $sdmap{$_};
	} else {
	    warn "Warning: $_: no such file or directory\n";
	}
    }
}

sub eltypemap {
    my $self = shift;
    %{$self->{ST_ELTYPEMAP}} = @_ if @_;
    return $self->{ST_ELTYPEMAP} ? %{$self->{ST_ELTYPEMAP}} : ();
}

sub dstcheck {
    my $self = shift;
    my $dbase = $self->dstbase;
    die "$0: Error: must specify dest base before dstcheck" if !$dbase;
    my @existing = ();
    if (-e $dbase) {
	# Check for view private files under the dest base.
	my @vp = $self->_lsprivate(0);
	my $n = @vp;
	my $s = $n == 1 ? '' : 's';
	my $es = $n == 1 ? 's' : '';
	die "$0: Error: $n view-private file$s exist$es under $dbase:\n @vp\n"
									if @vp;
	# Check for checkouts under the dest base.
	@existing = $self->_lsco;
	$n = @existing;
	$s = $n >= 2 ? 's' : '';
	if ($n == 0) {
	    # do nothing
	} elsif ($self->ignore_co) {
	    warning "skipping $n checkout$s under $dbase";
	} elsif ($self->overwrite_co) {
	    warning "overwriting $n checkout$s under $dbase";
	} else {
	    fatal("$n checkout$s found under $dbase");
	}
    }
    $self->{ST_PRE} = { map {$_ => 1} @existing };
}

# Comparator function used to implement the -vreuse option
# If the default comparaison fails, look at versions of suitable size
# in the version tree, and apply the comparaison to them.
# If a suitable version is found, add it to a list of versions on which
# to apply a label.
sub vtcomp {
    my($self, $src, $dst) = @_;
    my $cmp = $self->cmp_func;
    my $lb = $self->lblver;
    if ($lb) {
        my $lblver = "$dst\@\@/$lb";
	$dst = $lblver if -r $lblver;
    }
    return 0 unless $cmp->($src, $dst);
    my $vt = ClearCase::Argv->lsvtree([qw(-a -s -nco)]);
    my @vt = reverse grep {m%[\\/]\d*$%} $vt->args($dst)->qx;
    chomp @vt;
    my $sz = -s $src;
    for (@vt) {
        next if -s $_ != $sz;
	if (!$cmp->($src, $_)) {
	    push @{$self->{ST_LBL}}, $_;
	    return 0;
	}
    }
    return 1;
}

sub _needs_update {
    my($self, $src, $dst, $comparator) = @_;
    my $update = 0;
    if (src_slink($src) && ccsymlink($dst)) {
	my $srctext = src_rlink($src);
	my $desttext = readcclink $dst;
	$update = !defined($comparator) || ($srctext ne $desttext);
    } elsif (! src_slink($src) && ! ccsymlink($dst)) {
	if (!defined($comparator)) {
	    $update = 1;
	} elsif ($self->vreuse) {
	    $update = $self->vtcomp($src, $dst);
	} elsif (-s $src != -s $dst) {
	    $update = 1;
	} else {
	    $update = &$comparator($src, $dst);
	}
	$self->failm("failed comparing $src vs $dst: $!") if $update < 0;
    } else {
	$update = 1;
    }
    if ($update && (!exists($self->{ST_PRE}->{$dst}) || $self->overwrite_co)) {
	return 1;
    } else {
	return 0;
    }
}

sub checkcs {
    my $self = shift;
    my($dest) = @_;
    my $ct = ClearCase::Argv->new({autofail=>1, autochomp=>1});
    my $pwd = getcwd;
    $ct->_chdir($dest) || die "$0: Error: $dest: $!";
    $dest = getcwd;
    my @cs = grep /^\#\#:BranchOff: *root/, $ct->argv('catcs')->qx;
    $ct->_chdir($pwd) || die "$0: Error: $pwd: $!";
    return scalar @cs;
}

sub analyze {
    my $self = shift;
    my $type = ref($_[0]) ? ${shift @_} : 'NORMAL';
    my $sbase = $self->srcbase;
    my $dbase = $self->dstbase;
    die "$0: Error: must specify dest base before analyzing" if !$dbase;
    die "$0: Error: must specify dest vob before analyzing" if !$self->dstvob;
    $self->_mkbase;
    $self->{branchoffroot} = $self->checkcs($dbase);
    # Derive the add and modify lists by traversing the src map and
    # comparing src/dst files.
    delete $self->{ST_ADD};
    delete $self->{ST_MOD};
    my @sl = $dbase eq $self->{ST_MKBASE}? sort grep{-d $_}
      $self->clone_ct->find($dbase, qw(-type l -print))->qx : ();
    map { $_ = "/$_" } @sl if CYGWIN; # mismatch between conventions
    if (@sl) {
	my %sl = map{ $_ => 1} @sl;
	for my $l (@sl) {
	    my $s = $l;
	    $s =~ s%^\Q$dbase\E/(.*)$%$1%;
	    if (exists $self->{ST_SRCMAP}->{$s}) {
		$s = join('/', $sbase, $s);
		delete $sl{$l} if src_slink($s);
	    }
	}
	@sl = sort keys %sl;
    }
    my $comparator = $self->no_cmp ? undef : $self->cmp_func;
    SRC: for (sort keys %{$self->{ST_SRCMAP}}) {
	next if $self->{ST_SRCMAP}->{$_}->{type} &&
		$self->{ST_SRCMAP}->{$_}->{type} !~ /$type/;
	my $src = join('/', $sbase, $_);
	$src = $_ unless -e $src || src_slink($src);
	my $dst = join('/', $dbase, $self->{ST_SRCMAP}->{$_}->{dst} || $_);
	for my $s (@sl) {
	    if ($dst =~ /^\Q$s\E/) {
		$self->{ST_DIRLNK}->{$s} = 1;
		$self->{ST_ADD}->{$_}->{src} = $src;
		$self->{ST_ADD}->{$_}->{dst} = $dst;
		next SRC;
	    }
	}
	# It's possible for a symlink to not satisfy -e if it's dangling.
	# Case-insensitive file test operators are a problem on Windows.
	# You cannot modify files when they don't exist under the proper name.
	if (! ecs($dst) && ! ccsymlink($dst)) {
	    $self->{ST_ADD}->{$_}->{src} = $src;
	    $self->{ST_ADD}->{$_}->{dst} = $dst;
	} elsif (! -d $src || src_slink($src)) {
	    if ($self->_needs_update($src, $dst, $comparator)) {
		$self->{ST_MOD}->{$_}->{src} = $src;
		$self->{ST_MOD}->{$_}->{dst} = $dst;
	    }
	}
    }
    if ($self->{ST_DIRLNK}) {
	my @rem;
	my @slst = sort keys %{$self->{ST_DIRLNK}};
	for (reverse @slst) {
	    for my $l (@slst) {
		if (/^\Q$l\E./) {
		    push @rem, $_;
		    last;
		}
	    }
	}
	delete @{$self->{ST_DIRLNK}}{@rem} if @rem;
	unlink $self->{ST_DIRLNK} unless keys %{$self->{ST_DIRLNK}};
    }
    # Last, check for subtractions but only if asked - it's potentially
    # expensive and error-prone.
    return unless $self->remove;
    my(%dirs, %files, %xfiles);
    my $wanted = sub {
	my $path = $File::Find::name;
	return if $path eq $dbase;
	if ($path =~ /lost\+found/) {
	    $File::Find::prune = 1;
	    return;
	}
	# Get a relative path from the absolute path.
	(my $relpath = $path) =~ s%^\Q$dbase\E\W?%%;
	if (ccsymlink($path)) { # Vob link
	    $files{$relpath} = $path;
	} elsif (-d $path) {
	    $dirs{$path} = $relpath;
	} elsif (-f $path) {
	    $files{$relpath} = $path;
	}
    };
    find($wanted, $dbase);
    my %dst2src;
    for (keys %{$self->{ST_SRCMAP}}) {
	my $dst = $self->{ST_SRCMAP}->{$_}->{dst};
	$dst2src{$dst} = $_ if $dst;
    }
    for (sort keys %files) {
	next if $self->{ST_SRCMAP}->{$_} && !$self->{ST_SRCMAP}->{$_}->{dst};
	$xfiles{$files{$_}}++ if !$dst2src{$_};
    }
    $self->{ST_SUB}->{exfiles} = \%xfiles;
    $self->{ST_SUB}->{dirs} = \%dirs;
}

sub preview {
    my $self = shift;
    my $indent = ' ' x 4;
    my($adds, $mods, $subs) = (0, 0, 0);
    if ($self->{ST_DIRLNK}) {
	my $dl = keys %{$self->{ST_DIRLNK}};
	print "Removing $dl directory symlinks:\n";
	for (sort keys %{$self->{ST_DIRLNK}}) {
	    print "${indent}$_\n";
	}
    }
    if ($self->{ST_ADD}) {
	$adds = keys %{$self->{ST_ADD}};
	print "Adding $adds elements:\n";
	for (sort keys %{$self->{ST_ADD}}) {
	    printf "$indent%s +=>\n\t%s\n", $self->{ST_ADD}->{$_}->{src},
			 $self->{ST_ADD}->{$_}->{dst};
	}
    }
    if ($self->{ST_MOD}) {
	$mods = keys %{$self->{ST_MOD}};
	print "Modifying $mods elements:\n";
	for (sort keys %{$self->{ST_MOD}}) {
	    printf "$indent%s ==>\n\t%s\n", $self->{ST_MOD}->{$_}->{src},
			 $self->{ST_MOD}->{$_}->{dst};
	}
    }
    if ($self->remove && $self->{ST_SUB}) {
	my @exfiles = sort keys %{$self->{ST_SUB}->{exfiles}};
	$subs = @exfiles;
	print "Subtracting $subs elements:\n" if $subs;
	for (@exfiles) {
	    printf "$indent%s\n", $_;
	}
    }
    my $total = $adds + $mods + $subs;
    print "Element change summary: add=$adds modify=$mods subtract=$subs\n";
    return $total;
}

sub pbrtype {
    my $self = shift;
    my $bt = shift;
    my $ct = $self->clone_ct;
    my $vob = $self->{ST_DSTVOB};
    if (!defined($self->{ST_PBTYPES}->{$bt})) {
	my $tc = $ct->des([qw(-fmt %[type_constraint]p)],
			                              "brtype:$bt\@$vob")->qx;
	$self->{ST_PBTYPES}->{$bt} = ($tc =~ /one version per branch/);
    }
    return $self->{ST_PBTYPES}->{$bt};
}

sub branchco {
    my $self = shift;
    my $dir = shift;
    my @ele = @_;
    my $ct = $self->clone_ct({autochomp=>0});
    my $rc;
    if ($self->{branchoffroot}) {
	foreach my $e (@ele) {
	    my $sel = $ct->ls(['-d'], $e)->autochomp(1)->qx;
	    if ($sel =~ /^(.*?) +Rule:.*-mkbranch (.*?)\]?$/) {
		my ($ver, $bt) = ($1, $2);
		my $sil = $self->clone_ct({stdout=>0, stderr=>0});
		my $main = 'main';
		if ($sil->des(['-s'], "$e\@\@/main/0")->system) {
		    $main = ($ct->lsvtree($e)->autochomp(1)->qx)[0];
		    $main =~ s%^[^@]*\@\@[\\/](.*)\r?$%$1%;
		}
		my $re = $self->pbrtype($bt) ?
		  qr([\\/]${main}[\\/]$bt[\\/]\d+$) : qr([\\/]$bt[\\/]\d+$);
		if ($ver =~ m%$re%) {
		    $rc |= $ct->co($self->comment, $e)->system;
		} else {
		    my $r = $ct->mkbranch([@{$self->comment}, '-ver',
					      "/${main}/0", $bt], $e)->system;
		    if ($r) {
			$rc = 1;
		    } else {
			if ($ver !~ m%\@\@[\\/]${main}[\\/]0$%) {
			    $rc |= $dir ?
				$ct->merge(['-to', $e],
					   $ver)->stdout(0)->system :
				$ct->merge(['-ndata', '-to', $e],
					   $ver)->stdout(0)->system;
			    unlink("$e.contrib");
			}
		    }
		}
	    } else {
		$rc |= $ct->co($self->comment, $e)->system;
	    }
	}
    } else {
	$rc = $ct->co($self->comment, @ele)->system;
    }
    return $rc;
}

sub rmdirlinks {
    my $self = shift;
    return unless $self->{ST_DIRLNK};
    my $lsco = ClearCase::Argv->lsco([qw(-s -d -cview)]);
    for (sort {$b cmp $a} keys %{$self->{ST_DIRLNK}}) {
	my $dad = dirname $_;
	$self->branchco(1, $dad) unless $lsco->args($dad)->qx;
	$self->clone_ct->rm($_)->system;
	delete $self->{ST_SUB}->{exfiles}->{$_}; #If it is there
    }
}

sub mkrellink {
    my ($self, $src) = @_;
    my $txt = src_rlink($src);
    my $sbase = $self->srcbase;
    return $txt unless $self->{ST_RELLINKS} and ($txt =~ /^$sbase/);
    $txt =~ s%^$sbase/(.*)%$1%;
    $src =~ s%^$sbase/(.*)%$1%;
    my @t = split m%/%, $txt;
    my @s = split m%/%, $src;
    my $i = 0;
    while ($t[$i] eq $s[$i]) {
	$i++;
	shift @t;
	shift @s;
    }
    while ($i++ < $#s) { unshift @t, '..'; }
    $txt = join '/', @t;
    return $txt;
}

# Remove spurious names from restored directory
sub skimdir {
    my ($self, $dst, $pfx) = @_;
    my $flt = qr{^(\Q$pfx\E.*?)(?:/.*)?$}; # paths normalized
    opendir(DIR, $dst);
    my @f = grep !m%^\.\.?$%, readdir DIR;
    closedir DIR;
    my %ok = map {$_ => 1} grep s%$flt%$1%, keys %{$self->{ST_SRCMAP}};
    for (@f) {
	my $f = $pfx . $_;
	$self->{ST_SUB}->{exfiles}->{join('/', $dst, $_)}++ unless $ok{$f};
    }
}

sub vtree {
    my ($self, $dir) = @_;
    if (!exists $self->{ST_VT}->{$dir}) {
	my $vt = ClearCase::Argv->lsvtree({autochomp=>1}, [qw(-a -s -nco)]);
	# optimization: branch/0 of a directory is either empty or duplicate
	my @vt = reverse grep { m%[/\\](\d+)$% && $1>=1 } $vt->args($dir)->qx;
	$self->{ST_VT}->{$dir} = \@vt;
    }
    return $self->{ST_VT}->{$dir};
}

# Once a directory version was found, move it first in the list for next tries
sub raise_dver {
    my ($self, $i, $dir) = @_;
    return unless $i;
    my $vt = $self->{ST_VT}->{$dir};
    my $ver = splice @{$vt}, $i, 1;
    unshift @{$vt}, $ver;
}

# Reuse from removed elements, or create as view private, directories
sub reusemkdir {
    my ($self, $dref, $rref) = @_;
    my (%found, %dfound, %priv);
    my $snapview = $self->snapdest;
    my $ds = ClearCase::Argv->desc({stderr=>1},[qw(-s)]);
    my $dm = ClearCase::Argv->desc([qw(-fmt %m)]);
    my $rm = ClearCase::Argv->rm;
    my $lsco = ClearCase::Argv->lsco([qw(-s -d -cview)]);
    my $ln = ClearCase::Argv->ln;
    for my $dst (sort keys %{$dref}) {
	next if $dfound{$dst};
	my $reused;
	my($name, $dir) = fileparse($dst);
	if (!$priv{$dir}) {
	  if ($rref->{$dst}) {
	    $self->branchco(1, $dir) unless $lsco->args($dir)->qx;
	    $rm->args($dst)->system;
	  }
	  my $i = -1; #index in the vtree list
	VER: for (@{$self->vtree($dir)}) {
	    $i++;
	    my $dirext = "$_/$name";
	    # case-insensitive file test operator on Windows is a problem
	    if ($snapview ? $ds->args($dirext)->qx !~ /Error:/ : ecs($dirext)) {
	      next if $dm->args($dirext)->qx eq 'file element';
	      while (ccsymlink($dirext)) {
		$name = readcclink $dirext;
		$name =~ s/\@\@$//;
		$dirext = "$_/$name";
		# consider only relative, and local symlinks
		next VER if !ecs($dirext) ||
		  $dm->args($dirext)->qx eq 'file element';
	      }
	      $reused = 1;
	      $self->raise_dver($i, $dir);
	      $self->branchco(1, $dir) unless $lsco->args($dir)->qx;
	      $ln->args($dirext, $dst)->system;
	      # Need to reevaluate all the files under this dir
	      # The case of implicit dirs, is recorded as '.'
	      my $d = $dref->{$dst} eq '.'? '' : $dref->{$dst} . '/';
	      $self->skimdir($dst, $d) if $self->remove;
	      my $cmp = $self->no_cmp ? undef : $self->cmp_func;
	      my @keys = sort $d? grep m%^\Q$d\E%, keys %{$self->{ST_ADD}}
		: keys %{$self->{ST_ADD}};
	      for my $e (@keys) {
		my $edst = join '/', $self->dstbase, $e;
		my @intdir = split m%/%, $e;
		pop @intdir;
		if (@intdir) {
		  my $dd = $self->dstbase;
		  my $pf = '';
		  while (my $id = shift @intdir) {
		    $dd = join '/', $dd, $id;
		    $pf = $pf . $id . '/';
		    $self->skimdir($dd, $pf) if -d $dd && !$dfound{$dd}++;
		  }
		}
		# Problem: does it match the type under srcbase?
		if (-d $edst and !ccsymlink($edst)) { # We know it is empty
		  opendir(DIR, $edst);
		  my @f = grep !m%^\.\.?$%, readdir DIR;
		  closedir DIR;
		  if (@f) {
		    $self->branchco(1, $edst)
		      unless $lsco->args($edst)->qx;
		    $rm->args(map{join '/', $edst, $_} @f)->system;
		  }
		  $dfound{$edst}++; #Skip in this loop
		  next;
		}
		if (exists($self->{ST_ADD}->{$e}->{dst})) {
		  my $src = $self->{ST_ADD}->{$e}->{src};
		  my $dst = $self->{ST_ADD}->{$e}->{dst};
		  if (-e $dst) {
		    $self->{ST_MOD}->{$e} = $self->{ST_ADD}->{$e}
		      if $self->_needs_update($src, $dst, $cmp);
		    $found{$e}++; #Remove from the add list
		  }
		}
	      }
	      last;
	    }
	  }
	}
	if (!$reused) {
	    my $err;
	    mkpath($dst, {error => \$err, verbose => 0, mode => 0777});
	    $self->failm(join(': ', %{$err->[0]})) if $err and @{$err};
	    $priv{"${dst}/"}++;
	}
    }
    return %found;
}

# recursively record parent directories, and clashing objects to remove
sub recadd {
    my ($self, $src, $dst, $dir, $rm, $seen) = @_;
    my $dad = dirname($dst);
    return if $seen->{$dad}++ || (-d $dad && !ccsymlink($dad)); #exists, normal
    my $sdad = dirname($src);
    $self->recadd($sdad, $dad, $dir, $rm, $seen);
    $rm->{$dad}++ if -f $dad || ccsymlink($dad); #something clashing: remove
    $dir->{$dad} = $sdad;
}

sub add {
    my $self = shift;
    my $sbase = $self->srcbase;
    my $mbase = $self->_mkbase;
    my $ct = $self->clone_ct;
    return if ! $self->{ST_ADD};
    if ($self->reuse) { # First, reuse parent directories
	my (%dir, %rm, %dseen);
	# in the way if added in _mkbase as view private; ignore failures
	rmdir($_) for reverse sort @{$self->{ST_IMPLICIT_DIRS}};
	for my $d (sort keys %{$self->{ST_ADD}}) {
	    my $src = $self->{ST_ADD}->{$d}->{src};
	    my $dst = $self->{ST_ADD}->{$d}->{dst};
	    $dir{$dst} = $d if -d $src && !src_slink($src); # empty dir
	    $self->recadd($d, $dst, \%dir, \%rm, \%dseen);
	}
	my %found = $self->reusemkdir(\%dir, \%rm);
	delete $self->{ST_ADD}->{$_} for keys %found;
    }
    for (sort keys %{$self->{ST_ADD}}) {
	my $src = $self->{ST_ADD}->{$_}->{src};
	my $dst = $self->{ST_ADD}->{$_}->{dst};
	my $err;
	if (-d $src && ! src_slink($src)) { # Already checked in the reuse case
	    -e $dst || mkpath($dst, {error=>\$err, verbose=>0, mode=>0777});
	    $self->failm(join(': ', %{$err->[0]})) if $err and @{$err};
	} elsif (-e $src) {
	    my $dad = dirname($dst);
	    -d $dad || mkpath($dad, {error=>\$err, verbose=>0, mode=>0777});
	    $self->failm(join(': ', %{$err->[0]})) if $err and @{$err};
	    if (src_slink($src)) {
		open(SLINK, ">$dst$lext") || $self->failm("$dst$lext: $!");
		print SLINK $self->mkrellink($src), "\n";;
		close(SLINK);
	    } else {
		$self->{ST_CI_FROM}->{$_} = $self->{ST_ADD}->{$_}
					   if !exists($self->{ST_PRE}->{$dst});
	    }
	} elsif (src_slink($src)) { #Dangling symlink: import
	    open(SLINK, ">$dst$lext") || $self->failm("$dst$lext: $!");
	    print SLINK $self->mkrellink($src), "\n";;
	    close(SLINK);
	} else {
	    $ct->failm("$src: no such file or directory");
	}
    }
    my @candidates = sort $self->_lsprivate(1),
			  map { $_->{dst} } values %{$self->{ST_CI_FROM}};
    return if !@candidates;
    # We'll be separating the elements-to-be into files and directories.
    my(%files, @symlinks, %dirs);
    # If the parent directories of any of the candidates are
    # already versioned, we'll need to check them out unless
    # it's already been done.
    my @dads = sort map {dirname($_)} @candidates;
    my %lsd = map {split(/\s+Rule:\s+/, $_, 2)}
			$ct->argv('ls', [qw(-d -nxn -vis -vob)], @dads)->qx;
    for my $dad (keys %lsd) {
	# If already checked out, nothing to do.
	next if ! $lsd{$dad} || $lsd{$dad} =~ /CHECKEDOUT$/;
	# Now we know it's an element which needs to be checked out.
	$dad =~ s%\\%/%g if MSWIN;
	$dirs{$dad}++;
    }
    $self->branchco(1, keys %dirs) if keys %dirs;
    # Process candidate directories here, then do files below.
    my $mkdir = $self->clone_ct->mkdir({autofail=>0, autochomp=>0},
				                               $self->comment);
    for my $cand (@candidates) {
	if (! -d $cand) {
	    if ($cand =~ /$lext$/) {
		push(@symlinks, $cand);
	    } else {
		$files{$cand} = 1;
	    }
	    next;
	}
	# Now we know we're dealing with directories.  These cannot
	# exist at mkelem time so we move them aside, make
	# a versioned dir, then move all the files from the original
	# back into the new dir (still as view-private files).
	my $tmpdir = "$cand.$$.keep.d";
	if (!rename($cand, $tmpdir)) {
	    warn "$0: Error: can't rename '$cand' to '$tmpdir': $!\n";
	    $ct->fail;
	    next;
	}
	if ($mkdir->args($cand)->system) {
	    warn "Warning: unable to rename $tmpdir back to $cand!"
		                                unless rename($tmpdir, $cand);
	    $ct->fail;
	    next;
	}
	if (!opendir(DIR, $tmpdir)) {
	    warn "$0: Error: $tmpdir: $!";
	    $ct->fail;
	    next;
	}
	while (defined(my $i = readdir(DIR))) {
	    next if $i eq '.' || $i eq '..';
	    rename("$tmpdir/$i", "$cand/$i") || $self->failm("$cand/$i: $!");
	}
	closedir DIR;
	rmdir $tmpdir || warn "$0: Error: $tmpdir: $!";
    }

    # Optionally, reconstitute an old element of the same name if present.
    if ($self->reuse) {
	my $snapview = $self->snapdest;
	my $ds = ClearCase::Argv->desc({stderr=>1}, [qw(-s)]);
	my $dm = ClearCase::Argv->desc([qw(-fmt %m)]);
	my $ln = ClearCase::Argv->ln;
	my %reused;
	for my $elem (keys %files) {
	    my($name, $dir) = fileparse($elem);
	    my $i = -1;
	  DVER:
	    for (@{$self->vtree($dir)}) {
		$i++;
		my $dirext = "$_/$name@@";
		# case-insensitive file test operator on Windows is a problem
		if ($snapview ? $ds->args($dirext)->qx !~ /Error:/ :
							    ecs("$_/$name")) {
		    next if $dm->args("$_/$name")->qx =~ /^directory /;
		    while (ccsymlink("$_/$name")) {
		        $name = readcclink "$_/$name";
			$name =~ s/\@\@$//;
			next DVER if !ecs("$_/$name") ||
			            $dm->args("$_/$name")->qx =~ /^directory /;
		    }
		    $reused{$elem} = 1;
		    delete $files{$elem};
		    unlink($elem);
		    $ln->args("$_/$name", $elem)->system;
		    $self->raise_dver($i, $dir);
		    last;
		}
	    }
	}
	# If any elements were "reconstituted", they must be taken off the
	# list of elems to be checked in explicitly, since 'ct ln' is
	# just a directory op.
	my %xkeys;
	if (!$self->no_cr && %reused) {
	    for (keys %{$self->{ST_CI_FROM}}) {
		if (exists($self->{ST_CI_FROM}->{$_})
			&& exists($self->{ST_CI_FROM}->{$_}->{dst})
			&& exists($reused{$self->{ST_CI_FROM}->{$_}->{dst}})) {
		    $xkeys{$_} = 1;
		}
	    }
	    for (keys %xkeys) {
		delete $self->{ST_CI_FROM}->{$_};
	    }
	}
	# Also, reconstituted elements may now be candidates for
	# modification. Re-analyze the status for these. If any of
	# them differ from their counterparts in the src area, copy
	# them from the ADD list to the MOD list.
	my $comparator = $self->no_cmp ? undef : $self->cmp_func;
	for my $elem (keys %{$self->{ST_ADD}}) {
	    if (exists($reused{$self->{ST_ADD}->{$elem}->{dst}})) {
		my $src = $self->{ST_ADD}->{$elem}->{src};
		my $dst = $self->{ST_ADD}->{$elem}->{dst};
		if ($self->_needs_update($src, $dst, $comparator)) {
		    $self->{ST_MOD}->{$elem} = $self->{ST_ADD}->{$elem};
		}
	    }
	}
    }
    for (sort keys %{$self->{ST_CI_FROM}}) {
	my $dst = $self->{ST_CI_FROM}->{$_}->{dst};
	if ($files{$dst}) {
	    my $src = $self->{ST_CI_FROM}->{$_}->{src};
	    copy($src, $dst) || $ct->failm("$_: $!");
	    utime(time(), (stat $src)[9], $dst) ||
	                                    warn "Warning: $dst: touch failed";
	}
    }
    # Now do the files in one fell swoop.
    $ct->mkelem($self->comment, sort keys %files)->system if %files;

    # Deal with symlinks.
    for my $symlink (@symlinks) {
	(my $lnk = $symlink) =~ s/$lext$//;
	if (!open(SLINK, $symlink)) {
	    warn "$symlink: $!";
	    next;
	}
	chomp(my $txt = <SLINK>);
	close SLINK;
	unlink $symlink;
	$ct->ln(['-s'], $txt, $lnk)->system;
    }
}

# Tried to use Cwd::abs_path, but it behaves differently on Cygwin and UNIX
sub absdst {
    my ($self, $dir, $f) = @_;
    if ($f =~ /^\./) {
	my $sep = qr{[/\\]};
	my @d = split $sep, $dir;
	while ($f =~ s/^(\.\.?$sep)//) {
	    pop @d if $1 =~ /^\.{2}/;
	}
	$dir = join '/', @d;
    }
    return File::Spec->catfile($dir, $f);
}

sub modify {
    my $self = shift;
    return if !keys %{$self->{ST_MOD}};
    my(%files, %symlinks);
    for (keys %{$self->{ST_MOD}}) {
	if (src_slink($self->{ST_MOD}->{$_}->{src})) {
	    $symlinks{$_}++;
	} else {
	    $files{$_}++;
	}
    }
    my $rm = $self->clone_ct('rmname');
    my $ln = $self->clone_ct('ln');
    $ln->opts('-s', $ln->opts);
    my $lsco = ClearCase::Argv->lsco([qw(-s -d -cview)]);
    my $comparator = $self->no_cmp ? undef : $self->cmp_func;
    if (keys %files) {
	my (@toco, @del);
	for my $key (sort keys %files) {
	    my $src = $self->{ST_MOD}->{$key}->{src};
	    my $dst = $self->{ST_MOD}->{$key}->{dst};
	    my $new;
	    if (ccsymlink($dst)) {
	        # The source is a file, but the destination is a symlink: look
	        # (recursively) at what this one points to, and link in this
	        # file.
	        # Build up the path of the destination, in such a way that it
	        # may be found, or not, in the hash.
		my $dangling;
		my $sep = qr%[/\\]%;
		my $dst1 = $dst;
	        while (ccsymlink($dst1)) {
		    my $tgt = readcclink $dst1;
		    my $dir = dirname $dst1;
		    $tgt = $self->absdst($dir, $tgt) unless $tgt =~ m%^[/\\]%;
		    $tgt =~ s%\\%/%g if MSWIN;
		    if (-e $tgt) {
			$dst1 = $tgt;
		    } else {
			$dangling = 1;
			last;
		    }
		}
		my $dir = dirname($dst);
		$self->branchco(1, $dir) unless $lsco->args($dir)->qx;
		$self->clone_ct->rm($dst)->system; #remove the first symlink
		if ($dangling || !$self->{ST_SUB}->{exfiles}->{$dst1}) {
		    if (!copy($src, $dst)) {
			warn "$0: Error: $dst: $!\n";
			$rm->fail;
		    }
		    utime(time(), (stat $src)[9], $dst) ||
		      warn "Warning: $dst: touch failed";
		    $self->clone_ct->mkelem($self->comment, $dst)->system;
		    $new = 1;
		    delete $self->{ST_MOD}->{$key};
		    push @del, $key;
		} else {
		    my $dir1 = dirname($dst1);
		    $self->branchco(1, $dir1)
		              unless ($dir eq $dir1) || $lsco->args($dir1)->qx;
		    $self->clone_ct->mv($dst1, $dst)->system;
		    delete $self->{ST_SUB}->{exfiles}->{$dst1}; #done already
		    if (!$self->_needs_update($src, $dst, $comparator)) {
			delete $self->{ST_MOD}->{$key};
			push @del, $key;
		    }
		}
	    }
	    push(@toco, $dst) unless exists($self->{ST_PRE}->{$dst}) || $new;
	}
	$self->branchco(0, @toco) if @toco;
	delete @files{@del};
	for (sort keys %files) {
	    my $src = $self->{ST_MOD}->{$_}->{src};
	    my $dst = $self->{ST_MOD}->{$_}->{dst};
	    next if exists($self->{ST_PRE}->{$dst});
	    if ($self->no_cr) {
		if (!copy($src, $dst)) {
		    warn "$0: Error: $dst: $!\n";
		    $rm->fail;
		    next;
		}
		utime(time(), (stat $src)[9], $dst) ||
				            warn "Warning: $dst: touch failed";
	    } else {
		$self->{ST_CI_FROM}->{$_} = $self->{ST_MOD}->{$_};
	    }
	}
    }
    if (keys %symlinks) {
	my %checkedout = map {$_ => 1} $self->_lsco;
	for (sort keys %symlinks) {
	    my $txt = $self->mkrellink($self->{ST_MOD}->{$_}->{src});
	    my $lnk = $self->{ST_MOD}->{$_}->{dst};
	    my $dad = dirname($lnk);
	    if (!$checkedout{$dad}) {
		$checkedout{$dad} = 1 if ! $self->branchco(1, $dad);
	    }
	    if (!$rm->args($lnk)->system) {
	        my @fil = grep /^\Q$lnk\E/, keys %{$self->{ST_SUB}->{exfiles}};
	        delete @{$self->{ST_SUB}->{exfiles}}{@fil};
		delete $self->{ST_SUB}->{dirs}{$lnk};
	    }
	    $ln->args($txt, $lnk)->system;
	}
    }
}

sub subtract {
    my $self = shift;
    return unless $self->{ST_SUB};
    my $ct = $self->clone_ct;
    my %co = map {$_ => 1} $self->_lsco;
    my $exnames = $self->{ST_SUB}->{exfiles}; # Entries to remove
    my (%dir, %keep); # Directories respectively to inspect, and to keep
    $dir{dirname($_)}++ for keys %{$exnames};
    $dir{$_}++ for keys %{$self->{ST_SUB}->{dirs}}; # Existed originally
    my $dbase = $self->dstbase;
    for my $d (sort {$b cmp $a} keys %dir) {
	next if $keep{$d};
	my ($k) = ($d =~ m%^\Q$dbase\E/(.*)$%);
	if ($k and $self->{ST_SRCMAP}->{$k}) {
	    delete $exnames->{$d};
	    my $dad = $d;
	    $keep{$dad}++ while $dad = dirname($dad) and $dad gt $dbase;
	    next;
	}
	if (opendir(DIR, $d)) {
	    my @entries = grep !/^\.\.?$/, readdir DIR;
	    closedir(DIR);
	    map { $_ = join('/', $d, $_) } @entries;
	    if (grep { !$exnames->{$_} and $ct->ls(['-s'], $_)->qx !~ /\@$/}
		  @entries) { # Something not to delete--some version selected
		my $dad = $d;
		$keep{$dad}++ while $dad = dirname($dad) and $dad gt $dbase;
	    } else {
		if (@entries) {
		    my @co = grep {$co{$_}} @entries; # Checkin before removing
		    $ct->ci($self->comment, @co)->system if @co;
		    delete @$exnames{@entries}; # Remove the contents
		}
		$exnames->{$d}++; # Add the container
	    }
	}
    }
    delete @$exnames{keys %keep};
    my @exnames = keys %{$exnames};
    for my $dad (map {dirname($_)} @exnames) {
	$self->branchco(1, $dad) unless $co{$dad}++;
    }
    # Force because of possible checkouts in other views. Fail for unreachable
    $ct->rm([@{$self->comment}, '-f'], @exnames)->system if @exnames;
}

sub label {
    my $self = shift;
    my $lbtype = shift || $self->lbtype;
    return unless $lbtype;
    my $dbase = $self->dstbase;
    my $ct = $self->clone_ct({autochomp=>0});
    my $ctq = $self->clone_ct({stdout=>0});
    my $ctbool = $self->clone_ct({autofail=>0, stdout=>0, stderr=>0});
    my $dvob = $self->dstvob;
    my $locked;
    if ($ctbool->lstype(['-s'], "lbtype:$lbtype\@$dvob")->system) {
	$ct->mklbtype($self->comment, "lbtype:$lbtype\@$dvob")->system;
    } elsif (!$self->inclb) {
	$locked = $ct->lslock(['-s'], "lbtype:$lbtype\@$dvob")->qx;
	$ct->unlock("lbtype:$lbtype\@$dvob")->system if $locked;
    }
    # Allow for labelling errors, in case of hard links: only the link
    # recorded can be labelled, the other being seen as 'removed'
    if ($self->label_mods || $self->inclb) {
	my @mods = $self->_lsco;
	push @mods, @{$self->{ST_LBL}} if $self->{ST_LBL};
	if (@mods) {
	    $ctbool->mklabel([qw(-nc -rep), $self->inclb], @mods)->system
	                                                      if $self->inclb;
	    $ctbool->mklabel([qw(-nc -rep), $lbtype], @mods)->system;
	}
    } else {
	my $lbl = $self->lblver;
        if ($lbl) {
	    my $ct = $self->clone_ct({autochomp=>1, autofail=>0, stderr=>0});
	    my @rv = grep{ s/^(.*?)(?:@@(.*))/$1/ &&
			     ($2 =~ /CHECKEDOUT$/ || !-r "$_\@\@/$lbl") }
	      $ct->ls([qw(-r -vob -s)], $dbase)->qx,
	      $ct->ls([qw(-d -vob -s)], $dbase)->qx;
	    $ctbool->mklabel([qw(-nc -rep), $lbtype], $dbase, @rv)->system;
        } else {
	    $ctbool->mklabel([qw(-nc -rep -rec), $lbtype], $dbase)->system;
	}
	# Possibly move the label back to the right versions
	$ctbool->mklabel([qw(-nc -rep), $lbtype], @{$self->{ST_LBL}})->system
	                                                   if $self->{ST_LBL};
	# Last, label the ancestors of the destination back to the vob tag.
	my($dad, @ancestors);
	my $min = length($self->normalize($dvob));
	for ($dad = dirname($dbase);
			         length($dad) >= $min; $dad = dirname($dad)) {
	    push(@ancestors, $dad);
	}
	$ctq->mklabel([qw(-rep -nc), $lbtype], @ancestors)->system
								if @ancestors;
    }
    $self->clone_ct->lock("lbtype:$lbtype\@$dbase")->system if $locked;
}

sub get_addhash {
    my $self = shift;
    if ($self->{ST_ADD}) {
	return
	    map { $self->{ST_ADD}->{$_}->{src}, $self->{ST_ADD}->{$_}->{dst} }
		keys %{$self->{ST_ADD}};
    } else {
	return ();
    }
}

sub get_modhash {
    my $self = shift;
    if ($self->{ST_MOD}) {
	return
	    map { $self->{ST_MOD}->{$_}->{src}, $self->{ST_MOD}->{$_}->{dst} }
		keys %{$self->{ST_MOD}};
    } else {
	return ();
    }
}

sub get_sublist {
    my $self = shift;
    if ($self->{ST_SUB}) {
	return sort keys %{$self->{ST_SUB}->{exfiles}};
    } else {
	return ();
    }
}

sub checkin {
    my $self = shift;
    my $mbase = $self->_mkbase;
    my $dad = dirname($mbase);
    my @ptime = qw(-pti) unless $self->ctime;
    my @cmnt = @{$self->comment};
    my $ct = $self->clone_ct({autochomp=>0});
    # If special eltypes are registered, chtype them here.
    if (my %emap = $self->eltypemap) {
	for my $re (keys %emap) {
	    my @chtypes = grep {/$re/} map {$self->{ST_ADD}->{$_}->{dst}}
				       keys %{$self->{ST_ADD}};
	    next unless @chtypes;
	    $ct->chtype([@cmnt, '-f', $emap{$re}], @chtypes)->system;
	}
    }
    # Do one-by-one ci's with -from (to preserve CR's) unless
    # otherwise requested.
    if (! $self->no_cr) {
	for (keys %{$self->{ST_CI_FROM}}) {
	    my $src = $self->{ST_CI_FROM}->{$_}->{src};
	    my $dst = $self->{ST_CI_FROM}->{$_}->{dst};
	    $ct->ci([@ptime, @cmnt, qw(-ide -rm -from), $src], $dst)->system;
	}
	delete @{$self->{ST_MOD}}{keys %{$self->{ST_CI_FROM}}};
    }
    # Check-in first the files modified under the recorded names,
    # in case of hardlinks, since checking the other link first
    # in a pair would fail.
    my @mods;
    push @mods, $self->{ST_MOD}->{$_}->{dst} for
       grep {!ccsymlink($self->{ST_MOD}->{$_}->{dst})} keys %{$self->{ST_MOD}};
    $ct->ci([@cmnt, '-ide', @ptime], sort @mods)->system if @mods;
    # Check in anything not handled above.
    my %checkedout = map {$_ => 1} $self->_lsco;
    my @todo = grep {m%^\Q$mbase%} keys %checkedout;
    @todo = grep {!exists($self->{ST_PRE}->{$_})} @todo if $self->ignore_co;
    unshift(@todo, $dad) if $checkedout{$dad};
    # Sort reverse in case the checked in versions are not selected by the view
    $ct->argv('ci', [@cmnt, '-ide', @ptime], sort {$b cmp $a} @todo)->system
                                                                      if @todo;
    # Fix the protections of the target files if requested. Unix files
    # get careful consideration of bitmasks etc; Windows files just get
    # promoted to a+x if their extension looks executable.
    if ($self->protect) {
	if (MSWIN) {
	    my @exes;
	    for (keys %{$self->{ST_ADD}}) {
		next unless m%\.(bat|cmd|exe|dll|com|cgi|.?sh|pl)$%i;
		push(@exes, $self->{ST_ADD}->{$_}->{dst});
	    }
	    $ct->argv('protect', [qw(-chmod a+x)], @exes)->system if @exes;
	} else {
	    my %perms;
	    for (keys %{$self->{ST_ADD}}) {
		my $src = $self->{ST_ADD}->{$_}->{src};
		my $dst = $self->{ST_ADD}->{$_}->{dst};
		my $src_mode = (stat $src)[2];
		my $dst_mode = (stat $dst)[2];
		# 07551 represents the only bits that matter to clearcase
		if (($src_mode & 07551) ne ($dst_mode & 07551) &&
			$src !~ m%\.(?:p|html?|gif|mak|rc|ini|java|
				    c|cpp|cxx|h|bmp|ico)$|akefile%x) {
		    my $sym = sprintf("%o", ($src_mode & 07775) | 0444);
		    push(@${$perms{$sym}}, $dst);
		}
	    }
	    for (keys %{$self->{ST_MOD}}) {
		my $src = $self->{ST_MOD}->{$_}->{src};
		my $dst = $self->{ST_MOD}->{$_}->{dst};
		my $src_mode = (stat $src)[2];
		my $dst_mode = (stat $dst)[2];
		# 07551 represents the only bits that matter to clearcase
		if (($src_mode & 07551) ne ($dst_mode & 07551) &&
			$src !~ m%\.(?:p|html?|gif|mak|rc|ini|java|
				    c|cpp|cxx|h|bmp|ico)$|akefile%x) {
		    my $sym = sprintf("%o", ($src_mode & 07775) | 0444);
		    push(@${$perms{$sym}}, $dst);
		}
	    }
	    for (keys %perms) {
		$ct->argv('protect', ['-chmod', $_], @${$perms{$_}})->system;
	    }
	}
    }
}

sub cleanup {
    my $self = shift;
    my $mbase = $self->_mkbase;
    my $dad = dirname($mbase);
    my $ct = $self->clone_ct({autofail=>0});
    my @vp = $self->_lsprivate(1);
    for (sort {$b cmp $a} @vp) {
	if (-d $_) {
	    rmdir $_ || warn "$0: Error: unable to remove $_\n";
	} else {
	    unlink $_ || warn "$0: Error: unable to remove $_\n";
	}
    }
    my %checkedout = map {$_ => 1} $self->_lsco;
    my @todo = grep {m%^\Q$mbase%} keys %checkedout;
    @todo = grep {!exists($self->{ST_PRE}->{$_})} @todo
				    if $self->ignore_co || $self->overwrite_co;
    unshift(@todo, $dad) if $checkedout{$dad};
    if ($self->{branchoffroot}) {
	for (sort {$b cmp $a} @todo) {
	    my $b = $ct->ls([qw(-s -d)], $_)->qx;
	    $ct->unco([qw(-rm)], $_)->system;
	    if ($b =~ s%^(.*)[\\/]CHECKEDOUT$%$1%) {
		opendir BR, $b or next;
		my @f = grep !/^(\.\.?|0|LATEST)$/, readdir BR;
		closedir BR;
		$ct->rmbranch([qw(-f)], $b)->system unless @f;
	    }
	}
    } else {
	$ct->unco([qw(-rm)], sort {$b cmp $a} @todo)->system if @todo;
    }
}

# Undo current work and exit. May be called from an exception handler.
sub fail {
    my $self = shift;
    my $rc = shift;
    $self->ct->autofail(0);	# avoid exception-handler loop
    $self->cleanup;
    exit(defined($rc) ? $rc : 2);
}

sub failm {
    my ($self, $msg, $rc) = @_;
    warn "$0: Error: $msg\n";
    $self->fail($rc);
}

sub version {
    my $self = shift;
    return $ClearCase::SyncTree::VERSION;
}

# Here 'ecs' means Exists Case Sensitive. We don't generally
# want the case-insensitive file test operators on Windows.
# The underlying problem is that cleartool is always case
# sensitive. I.e. you can mkelem 'Foo' and then open 'foo'
# if you have the right MVFS settings, but you cannot check
# out or describe 'foo', only 'Foo'.
# This could lead to other problems on Windows though, since you
# may create evil twins if you subtract an old name and
# then add it under a name which differs only by case.  But at
# least that does work, whereas trying to checkout a path
# with the wrong case does not work at all.  Let the evil twin
# trigger handle the evil twin scenario.
sub ecs {
    my $file = shift;
    my $rc = 0;
    if (MSWIN || CYGWIN) {
	if (opendir DIR, dirname($file)) {
	    my $match = basename($file);
	    # Faster than for/last when not found!
	    $rc = 1 if grep {$_ eq $match} readdir DIR;
	    closedir DIR;
	}
    } else {
	$rc = -e $file;
    }
    return $rc;
}

1;

__END__

=head1 NAME

ClearCase::SyncTree - Synchronize a tree of files with a tree of elements

=head1 SYNOPSIS

    # Create a 'synctree' object.
    my $sync = ClearCase::SyncTree->new;
    # Tell it where the files are coming from ...
    $sync->srcbase($sbase);
    # Tell it where they're going to ...
    $sync->dstbase($dbase);
    # Supply the list of files to work on (relative or absolute paths).
    $sync->srclist(keys %files);
    # Compare src and dest lists and figure out what to do.
    $sync->analyze;
    # Create new elements in the target area.
    $sync->add;
    # Update existing files which differ between src and dest.
    $sync->modify;
    # Remove any files from dest that aren't in src.
    $sync->subtract;
    # Check in the changes.
    $sync->checkin;

See the enclosed I<synctree> script for full example usage.

=head1 DESCRIPTION

This module provides an infrastructure for programs which want to
I<synchronize> a set of files, typically a subtree, with a similar
destination subtree in VOB space.  The enclosed I<synctree> script is
an example of such a program.

The source area may be in a VOB or may be a regular filesystem; the
destination area must be in a VOB. Methods are supplied for adding,
subtracting, and modifying destination files so as to make that area
look identical to the source.

Symbolic links are supported, even on Windows (of course in this case
the source filesystem must support them, which is only likely in the
event of an MVFS->MVFS transfer). Note that the text of the link is
transported verbatim from source area to dest area; thus relative
symlinks may no longer resolve in the destination.

=head2 CONSTRUCTOR

Use C<ClearCase::SyncTree-E<gt>new> to construct a SyncTree object, which
can then be filled in and used via the instance methods below.

=head2 INSTANCE METHODS

Following is a brief description of each supported method. Examples
are given for all methods that take parameters; if no example is
given usage may be assumed to look like:

    $obj->method;

=over 2

=item * -E<gt>srcbase

Provides the base by which to 'relativize' the incoming pathnames.
E.g.  with a B<srcbase> of I</tmp/x> the incoming file I</tmp/x/y/z>
will become I<y/z> and will be deposited under the B<dstbase> (see) by
that path. Example:

    $obj->srcbase('/var/tmp/newstuff');

=item * -E<gt>dstbase

Provides the root of the tree into which to place the relative paths
derived from B<srcbase> as described above. Example:

    $obj->dstbase('/vobs/tps/newstuff');

=item * -E<gt>srclist/-E<gt>srcmap

There are two ways to specify the list of incoming files. They may be
provided as a simple list via B<srclist>, in which case they'll be
relativized as described above and deposited in B<dstbase>, or they can
be specified via B<srcmap> which allows the destination file to have a
different name from the source.

I<srclist> takes a list of input filenames. These may be absolute or
relative; they will be canonicalized internally.

I<srcmap> is similar but takes a hash which maps input filenames to
their destination counterparts.

Examples:

    $obj->srclist(@ARGV);	# check in the named files

    my %filemap = (x/y/z.c => 'x/y/z.cxx', a/b => 'foo');
    $obj->srcmap(%filemap);	# check in the named files

=item * -E<gt>analyze

After the object knows its I<srcbase>, I<dstbase>, and input file
lists, this method compares the source and target trees and categorizes
the required actions into I<additions> (new files in the destination
area), I<modifications> (those which exist but need to be updated) and
I<subtractions> (those which no longer exist in the source area).
After analysis is complete, the corresponding actions may be taken via
the I<add>, I<modify>, and I<subtract> methods as desired.

However, note that I<subtract> analysis is optional; it must be
requested by setting the -E<gt>remove attribute prior to calling
-E<gt>analyze.

=item * -E<gt>add

Takes the list of I<additions> as determined by the B<analyze> method
and creates them as new elements.

=item * -E<gt>modify

Takes the list of I<modifications> as determined by the B<analyze>
method and updates them in the destination tree.

=item * -E<gt>subtract

Takes the list of I<subtractions> as determined by the B<analyze>
method and rmname's them in the destination tree. The -E<gt>remove attribute
must have been set prior to calling B<analyze>.

=item * -E<gt>remove

Boolean. The list of files to subtract from the destination area will
not be derived unless this attribute is set before analysis begins.
This is because it takes time to do I<subtract> analysis, so there's no
sense doing it unless you plan to call -E<gt>subtract later.

=item * -E<gt>label

Labels the new work. The label type can be specified as a parameter;
otherwise it will be taken from the attribute previously set by the
I<lbtype> method.

Labeling consists of a I<mklabel -recurse> from I<dstbase> down,
followed by labeling of parent directories from I<dstbase> B<up> to the
vob root. Example:

    $obj->label('FOO');

See also I<-E<gt>label_mods>, as well as I<Support for incremental
label families>.

=item * -E<gt>checkin

Checks in all checkouts under the I<dstbase> area.

=item * -E<gt>cleanup

Undoes all checkouts under the I<dstbase> area.

=item * -E<gt>fail

Calls the I<cleanup> method, then exits with a failure status. This is
the default exception handler; a different handler can be registered
via the I<err_handler> method (see).

=item * -E<gt>err_handler

Registers an exception handler to be called upon failure of any
cleartool command. Call with 0 to have no handler. Pass it a code ref
to register a function, with an object and method I<name> to register a
method, with a scalar ref to count errors. Examples:

    $obj->err_handler(0);		# ignore cleartool errors
    $obj->err_handler(\$rc);		# count errors in $rc
    $obj->err_handler(\&func);		# register func() for errors
    $obj->err_handler($self, 'method');	# register $obj->method

=item * -E<gt>protect

Sets an attribute which causes the I<checkin> method to align file
permissions after checking in. The meaning of this varies by platform:
on Unix an attempt is made to bring destination mode bits into
alignment with those of the source file. On Windows, files with
extensions such as .exe and .dll are made executable (though most
Windows filesystems don't pay attention to executable modes, MVFS does
and thus the execute bit becomes a source of frequent confusion for
Windows ClearCase users). Example:

    $obj->protect(0);			# no dest mode fixups

=item * -E<gt>reuse

Attempt "element reuse". Before creating a new file with I<mkelem>,
look through its directory's version tree to see if another of the same
name exists in any other version. If so, assume the new file intended
to be the same element and link the old and new names.

    $obj->reuse(1);

=item * -E<gt>vreuse

Attempt "version reuse". Instead of creating a new version, apply the
label provided onto an old suitable one, even if it wasn't selected by
the config spec.

    $obj->vreuse(1);

=item * -E<gt>ctime

Sets a boolean indicating whether to throw away the timestamp of the
source file and give modified files their checkin date instead. This
flag is I<false> by default (i.e. checkins have I<-ptime> behavior).

=item * -E<gt>ignore_co/-E<gt>overwrite_co

By default, no view private files are allowed in the dest dir at
I<-E<gt>analyze> time. This generally means either classic view-private
files or checked-out elements, which are a form of view-private files.
The -E<gt>ignore_co attribute causes existing checkouts to be ignored
instead of being disallowed; they do not cause the operation to abort,
nor do their contents get modified. The -E<gt>overwrite_co attribute
also prevents existing checkouts from aborting the operation but it
causes the checked-out version to be replaced by the contents of the
source file (if that exists and has different contents of course).

=item * -E<gt>label_mods

By default the I<-E<gt>label> method will recursively label all visible
elements under the I<dstbase> directory. With this attribute set it
will label only modified elements instead.  Note that this may cause
confusion if an element is labeled but its parent directory isn't.

=item * -E<gt>no_cr

By default, checkins initiated by the I<checkin> method are done one at
a time using the I<-from> flag. This will preserve config records in
the case where the input file is a derived object.  Setting the
I<no_cr> attribute causes checkins to be done in one big C<"cleartool
ci"> operation, which is faster but loses CR's.

=item * -E<gt>no_cmp

This attribute causes all files which exist in both src and dest areas
to be considered modified by the I<analyze> method. An update will be
forced for all such elements.

=item * -E<gt>cmp_func

Sets or returns the coderef that's used to compare the source and
destination files. The default is I<File::Compare::compare()> but can
be replaced with a ref to your preferred function, eg:

    $obj->cmp_func(\&my_compare_function);

The function takes the names of the two files to compare. It should set
C<$!> if a file cannot be opened.

=item * -E<gt>comment

Provides a comment to be used by the I<checkin> method. The default
comment is C<"By:$0">. Example:

    $obj->comment("your comment here");

=item * -E<gt>eltypemap

In case the eltype of a particular file or set of files needs to be
overridden at creation time. Example:

    $obj->eltypemap('\.(ht|x)ml$' => 'compressed_file');

=back

=head2 Support for the BranchOff feature.

BranchOff is a feature you can set up via an attribute in your config
spec.  The rationale and the design are documented in:

 http://www.cmwiki.com/BranchOffMain0

Instead of branching off the selected version, the strategy is to
branch off the root of the version tree, copy-merging there from the
former.

This allows to avoid both merging back to /main or to a delivery
branch, and cascadig branches indefinitely.  The logical version tree
is restituted by navigating the merge arrows, to find all the direct
or indirect contributors.

See also I<ClearCase::Wrapper::MGi> on CPAN.

=head2 Support for incremental label families

I<ClearCase::Wrapper::MGi> supports managing families of incremental
fixed label types, as lists, linked with hyperlinks. The top of a list
is accessible as the equivalent fixed label type of a floating label
type, which has a stable name.  This allows to move the floating
labels, and keep track of their successive positions with sparse fixed
labels.

I<ClearCase::SyncTree> follows this strategy if the label type
provided has an I<EqInc> hyperlink.

Using an incremental type with the I<label> method, I<label_mods> is
implicit (and ignored).

=head2 Support for Cygwin

VOB paths show under Cygwin with forward slashes as separators. UNC
paths start with C<//>, and drives are presented with a C</cygdrive/>
prefix. Cygwin also offers a C<mount> tool, allowing the user to mount
her views under C</view>, to match the UNIX convention.

The support for Cygwin normalizes the paths on the UNC syntax.

=head1 BUGS

=over 2

=item *

If a file is removed via the -E<gt>subtract method and later added back
via -E<gt>add, the result will be a new element (aka I<evil twin>).
The -E<gt>reuse method (see) may be used to prevent evil twins.

=item *

I have not tested SyncTree in snapshot views and would not expect that
to work out of the box, though I did make some effort to code for the
possibility.

=back

Following items are from Uwe Nagler of Lucent, unverified:

=over 2

=item * Mode changes of files should be supported.

Currently:  If ONLY the protections of an existing file (in source and
VOB destination ) is changed in the source then this change is NOT
transferred into the VOB destination.  E.g. If a file later gets
"execute" permissions (scripts) in the source then the file in VOB
destination keeps the old permissions.

=item * File type changes should be supported

Currently:  If the type of an existing file (in source and VOB
destination) is changed in the source (ASCII->Binary) then the change
in VOB destination fails because of a ClearCase error (wrong file
type).

=item * Cleanup Bug #1

Wrong cleanup after detection of own checkouts below VOB destination:
If the current view has a checkout at the same branch where synctree
wants to checkout then (a) the whole synctree run is marked as failed
(which is OK) but (b) the cleanup performs a uncheckout and the user
will lose the data of its checkout.

=item * Cleanup Bug #2

Wrong cleanup after detecting other checkouts below VOB destination:
If another view has a checkout at the same branch where synctree wants
to checkout then (a) the whole synctree run is NOT marked as failed (b)
only this element is not updated

=back

=head1 AUTHOR

Based on code originally written by Paul D. Smith
<pausmith@nortelnetworks.com>.  Paul's version was based on the Bourne
shell script 'citree' delivered as sample code with ClearCase.

Rewritten for Unix/Win32 portability by David Boyce in 8/1999, then
reorganized into a module in 1/2000. This module no longer bears the
slightest resemblance to any version of citree.

Support for 2 features compatible with ClearCase::Wrapper::MGi
(branching off the root of the version tree--usually, /main/0, and
applying incremental labels), as well as for cygwin, added by Marc
Girod.

=head1 COPYRIGHT

Copyright 1997,1998 Paul D. Smith and Bay Networks, Inc.

Copyright 1999-2010 David Boyce (dsbperl AT boyski.com).

This script is distributed under the terms of the GNU General Public License.
You can get a copy via ftp://ftp.gnu.org/pub/gnu/ or its many mirrors.
This script comes with NO WARRANTY whatsoever, not even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 STATUS

SyncTree is currently ALPHA code and thus I reserve the right to change
the API incompatibly. At some point I'll bump the version suitably and
remove this warning, which will constitute an (almost) ironclad promise
to leave the interface alone.

=head1 PORTING

This module is known to work on Solaris 2.6-10 and Windows NT 4.0SP3-5
to Vista SP2, and with perl 5.004_04 to 5.10.  As these platforms
cover a fairly wide range there should be no I<major> portability
issues, but please send bug reports or patches to the address above.

=head1 SEE ALSO

perl(1), synctree(1), ClearCase::Argv(3), Getopt::Long(3), IPC::ChildSafe(3)
