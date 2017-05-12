use warnings;

# Library scanning -- it's mostly useless, but who knows...

sub MY::libscan {
    shift;
    local $_ = shift;
    return /^(\.arch-ids|\..*\.sw[op]|\{arch\}|\+.*)$/ ? undef : $_;
}

# Invoke scanning ourselves...

sub tla_inventory {
    return unless -d "{arch}";
    my @inv;
    eval {
	open INV, "tla inventory -s |" or die "Can't run tla: $!";
	open MAN, ">MANIFEST";
	while(<INV>) {
	    next if /.arch-inventory$/;
	    print MAN $_;
	    chomp;
	    push @inv, $_;
	}
	for(@extra_inv, 'MANIFEST', 'ChangeLog') {
	    print MAN "$_\n";
	    push @inv, $_;
	}
	system("tla changelog > ChangeLog");
    };
    return @inv;
}

sub manifest_inventory {
    open MAN, "<MANIFEST";
    my @inv = map { chomp; $_; } <MAN>;
    close MAN;
    return @inv;
}

# Our own dirscan, since the MakeMaker one is called in the middle of
# processing and we can't change it's results...

sub putdep {
    push @{$depend{shift()}}, @_;
}

@bdirs = 'build';
sub in_build {
    for(@_) {
	m"^(build.*)/[^/]*$" or die "!build: $_";
	putdep($_, "build/.stamp");
	push @bdirs, $1 unless grep { $_ eq $1; } @bdirs;
    }
}

sub putPM {
    for(@_) {
	$PM{$_} = m"^(lib|build)/(.*)$" ? "\$(INST_LIB)/$2" :
					  "\$(INST_LIBDIR)/$_";
    }
    return ();
}

sub putPL {
    my @r;
    for(@_) {
	next if /(Build|Makefile)\.PL$/;
	($PL{$_} = "\$(INST_LIB)/$2"), next if m"^(lib|build)/(.*)\.PL$";
	($PL{$_} = "\$(INST_LIBDIR)/$1"), next if m"(.*\.pm)\.PL$";
	($PL{$_} = "\$(INST_BIN)/$1"), next if m"(.*)\.PL$";
	push @r, $_;
    }
    return @r;
}

sub in_boot {
    my $b = $_[0];
    $b =~ s{^(?:build/)?(.*)(?:\...?)?$}{$1};
    $b =~ s{/}{__}g;
    push @BOOT, $b;
}

# Bez zkopírování toho .xs to makemaker odmítá udìlat.
# Jo a MakeMaker z nìjakého dùvodu nepapá .xs v lib, co¾ se tím taky o¹etøí.
sub putXS {
    for(@_) {
	my $b;
	$b = m"^(lib|build)/(.*)\.xs$" ? "build/$2" :
	     m"(.*)\.xs$"              ? "build/\$(PARENT_NAME)/$1" :
					 die "!XS: $_";
	in_build("$b.xs");
	in_boot("$b");
	$XS{"$b.xs"} = "$b.c";
	push @OBJECT, "$b.o";
	$postamble .= <<"EOP";

$b.xs : $_
	cp \$< \$@

EOP
    }
    return ();
}

$postamble = <<EOS;

build/.stamp :
	perl -MFile::Path -e 'mkpath([qw(\$(BDIRS))])'
	touch build/.stamp

clean :: clean_build

clean_build :
	-\$(RM_RF) build

EOS

sub inventory {
    @inv_full = tla_inventory;
    @inv_full = manifest_inventory unless @inv_full;

    @inv = map {
	/\.pm$/ ? putPM($_) :
	/\.xs$/ ? putXS($_) :
	/\.PL$/ ? putPL($_) :
	($_);
    } @inv_full;
}

sub macro {
    +{ BDIRS => join(' ', @bdirs) };
}

sub depend {
    +{ map { ref($_) eq 'ARRAY' ? join(' ', @$_) : $_; } %depend };
}

{
    package MY;
    
# Need explicit -o on cccmd...
    sub const_cccmd {
	local $_ = shift->SUPER::const_cccmd(@_);
	s/ -c / -o \$@ -c /;
	$_;
    }

# PL files must be processed in test and test only depends on pure_all. Thus
# pure_all and not all must depend on processing PL files.
    sub processPL {
	local $_ = shift->SUPER::processPL(@_);
	s/^all ::/pure_all ::/m;
	$_;
    }

# Add some things to metafile, that M::B does and EU::MM does not

    sub metafile {
	my $self = shift;
	local $_ = $self->SUPER::metafile_target(@_);
	return $_ unless $::add_to_metafile;
	my @add = $self->echo($::add_to_metafile, 'META.yml', 1);
	my $add = join("\n\t", @add);
	s/\n+$/\n\t$add\n\n/;
	$_;
    }
}

{
    package MM; # Now THIS is called a hack!

# This shall fix 'tree-version' in version...
    sub init_VERSION {
#D#	print "init_VERSION called!\n";
	my $self = shift;
	$self->SUPER::init_VERSION(@_);
	my $version = $self->{VERSION};

	if($version eq 'tree-version') { # Going to fix-up version...
	    my $text = qr/(?:-?[\w,%])+/;
	    my $patch = qr/(?:base|patch|version|versionfix)/;
	    my $treever = qx(tla logs -f -r | head -n 1);
	    die "Running tla failed (status $?)" if $?;

	    $self->{XS_VERSION} = undef if($version eq $self->{XS_VERSION});

	    my ($ARCHIVE, $CATEGORY, $BRANCH, $VERSION, $REVISION)
	    = $treever =~ m{^   (.*)
		/   ($text)
		--  (?:($text)--)?
		([\d.]+)
		--  $patch-([\d.]+)
		$}x or die "Bad tree revision: `$treever'";

	    if($BRANCH eq 'release') {
		$version = "$VERSION.$REVISION";
	    } else {
		$version = "$VERSION-$BRANCH-$REVISION";
	    }

	    $version =~ s{^(\d+\.)([\d.]*)}{
		my $h = $1;
		my $t = $2;
		$t =~ s/(\d+)/sprintf "%3.3i", $1/ge;
		$t =~ s/\.//g;
		"$h$t";
	    }e;
	    $self->{VERSION_FIXED_UP} = 1;
	    $self->{XS_VERSION} ||= $version;
	    $self->{VERSION} = $version;
	}
    }

}

# This will be called from MakeFile externaly...
sub fixup_version {
    my ($file, $version) = @_;
#D#    print "Called to fixup version $version in $file\n";
    local *FH;
    open FH, '<', $file or die "Can't read $file: $!";
    my $mod = 0;
    my @file = map {
	s{(\bVERSION\b.*)\btree-version\b}{
	    $mod = 1;
	    $1 . $version;}e;
	$_;
    } <FH>;
    close FH;
    return unless $mod;
    print "Fixing version $version in $file\n";
    unlink $file or die "Can't unlink $file: $!";
    open FH, '>', $file or die "Can't write $file: $!";
    print FH $_ foreach @file;
    close FH;
}

{
    package MY;

# This adds fixup_version to distdir target.
    sub distdir {
	my $self = shift;
	local $_ = $self->SUPER::distdir;
#D#	print "Fixing up distdir...\n";
	return $_ unless $self->{VERSION_FIXED_UP};
	return $_ unless $self->{VERSION_FROM};
	print "Will fixup version in distdir\n";
	my $fixup_cmd = <<"EOCMD";
	\$(PERLRUN) -e 'require "MakeTools.PM"; fixup_version(\@ARGV);' \$(DISTVNAME)/\$(VERSION_FROM) \$(VERSION)
EOCMD
	s/\n+$/\n$fixup_cmd\n/m or die "Fixup failed";
	$_;
    }
}

1;

# vim: set ft=perl:
# arch-tag: 987ee8a1-e554-463c-bab6-bb8faea07c7d
