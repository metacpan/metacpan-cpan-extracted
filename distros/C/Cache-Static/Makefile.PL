use 5.005;
use ExtUtils::MakeMaker;

my @POSSIBLE_EXTENSIONS = qw ( XML::Comma HTML::Mason DBI );
my @POSSIBLE_WRAPPERS   = qw ( DBI );
my @extensions          = qw ( XML::Comma HTML::Mason );
my @wrappers            = qw ();

#HACK: use 2 for true, "" for false, so that $default_disable ne $disable works
my $default_disable_hmc = my $disable_hmc = "";
my $i = 0;
while($i <= $#ARGV) {
	$arg = $ARGV[$i];
	if($arg =~ /^(\-|\+)?x(=)?hmc$/i) {
		$disable_hmc = (defined($1) && ($1 eq '+')) ? 0 : 1;
		#remove from ARGV so MakeMaker isn't confused
		splice(@ARGV, $i, $i+1);
	} elsif($arg =~ /^(\-|\+)?x(=)?.*$/) {
		my $enable = 1 if(defined($1) && ($1 eq '+'));
		my $name = $arg;
		$name =~ s/(\-|\+)?x(=)?//;
		#get case right
		my @t = grep(/$name$/i, (@POSSIBLE_EXTENSIONS, @POSSIBLE_WRAPPERS));
		$name = $t[0] || die "unknown extension/wrapper: $name";
		if($enable) {
			#add anything that's in possible, but not actual extensions/wrappers
			push @extensions, $name if(
				grep(/^$name$/i, @POSSIBLE_EXTENSIONS) &&
					!grep(/^$name$/i, @extensions));
			push @wrappers, $name if(
				grep(/^$name$/i, @POSSIBLE_WRAPPERS) &&
					!grep(/^$name$/i, @wrappers));
		} else {
			#remove an extension/wrapper
			@extensions = grep(!/^$name$/i, @extensions);
			@wrappers = grep(!/^$name$/i, @wrappers);
		}
		splice(@ARGV, $i, $i+1);
	} elsif($arg =~ /^\+.*$/) {
		die "do we really want to allow force-adding an extension/wrapper?";
	} else {
		# let this argument fall through to MakeMaker
		## usage("unknown argument to Makefile.PL: $arg");
		$i++;
	}
}

my $prereq_pms = { Digest::MD5 => 0, Storable => 0 };
my $pms = { 'lib/Cache/Static.pm' => 'blib/lib/Cache/Static.pm' };

#foo::bar -> Cache::Static::foo_bar_Util
foreach my $ext (@extensions) {
	eval "require $ext";
	if ($@) {
		warn "skipping $ext\n";
	} else {
		warn "including extension: $ext\n";
		my $name = $ext.'_Util';
		$name =~ s/\:\:/_/g;
		$prereq_pms->{$ext} = 0;
		$pms->{"lib/Cache/Static/$name.pm"} = 
			"blib/lib/Cache/Static/$name.pm";
		if($ext eq 'HTML::Mason') {
			if($disable_hmc) {
				warn "disabling HTML::Mason compiler as per your request\n"
					unless($disable_hmc eq $default_disable_hmc);
			} else {
				warn "including HTML::Mason compiler as per your request\n"
					unless($disable_hmc eq $default_disable_hmc);
				$pms->{"lib/Cache/Static/HTML_Mason_Util/hmc.pm"} = 
					"blib/lib/Cache/Static/HTML_Mason_Util/hmc.pm";
			}
		}
	}
}

#foo::bar -> Cache::Static::foo_bar
foreach my $ext (@wrappers) {
	eval "require $ext";
	if ($@) {
		warn "skipping $ext\n";
	} else {
		warn "including wrapper: $ext\n";
		my $name = $ext;
		$name =~ s/\:\:/_/g;
		$prereq_pms->{$ext} = 0;
		$pms->{"lib/Cache/Static/$name.pm"} = 
			"blib/lib/Cache/Static/$name.pm";
	}
}

#always install Configuration.pm
$pms->{'lib/Cache/Static/Configuration.pm'} =
	'blib/lib/Cache/Static/Configuration.pm';

WriteMakefile(
	NAME              => 'Cache::Static',
	VERSION_FROM      => 'lib/Cache/Static.pm', # finds $VERSION
	EXE_FILES         => [ <bin/*.pl> ],
	INSTALLSCRIPT     => '/usr/local/bin',
	PREREQ_PM         => $prereq_pms,
	PM                => $pms,
);

open(F, ">lib/Cache/Static/Configuration.pm");
print F "package Cache::Static::Configuration;\n1;\n__DATA__\n\n";
print F "extensions => [ ".join(", ", map { "'$_'" } @extensions)." ],\n";
print F "wrappers => [ ".join(", ", map { "'$_'" } @wrappers)." ],\n";
close(F);

#install cache_static.macro
use misc::MakeMakerMod;
misc::MakeMakerMod::add_steps(
	step => "install",
	what => "perl misc/install-extras.pl"
);

sub usage {
	my $arg = shift;
	chomp($arg);

	my @ext = (@extensions, @wrappers);
	print STDERR "$arg\n";
	print STDERR "perl Makefile.PL\n";
	print STDERR '   [ -x$extension1 -x$extension2 ... ]'."\n";
	print STDERR "      valid extensions are: @ext\n";
	print STDERR "      note that wrappers can also be included here\n";
	print STDERR "   [ -xhmc ]\n";
	print STDERR "      this disables HTML_Mason_Util trying to detemrine\n";
	print STDERR "      which component files to depend on - useful if you\n";
	print STDERR "      have, for example, overridden the resolver class\n";
	exit(1);
}


