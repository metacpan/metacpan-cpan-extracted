#!perl
use strict;
use Cwd ();
use inc::Devel::CheckLib;
use ExtUtils::MakeMaker;
use File::Spec;

my $CURDIR = Cwd::cwd();

# Here's the file that we're going to use to extract some data
my $SPEC_FILE       = 'lib/Alien/MeCab.pm';

# Check for hellish-ness
my $RUNNING_IN_HELL = $^O eq 'MSWin32';

# Get the version 
my $DIST_VERSION  = do {
    require ExtUtils::MM_Unix;
    ExtUtils::MM_Unix->parse_version($SPEC_FILE);
};

# Actual mecab version. This is the number up to the second fractional digit
# of the dist version
my $MECAB_VERSION    = substr($DIST_VERSION, 0, 4);

# Filenames 
my $MECAB_SOURCE_DIR = File::Spec->catfile("src", "mecab-$MECAB_VERSION");
my $MECAB_BASENAME   = "mecab-$MECAB_VERSION.tar.gz";
my $MECAB_SOURCE     = File::Spec->catfile("src", $MECAB_BASENAME);
my $MECAB_EXE        = File::Spec->catfile("src", "mecab-$MECAB_VERSION.exe");

# Absolut-ize all paths
$MECAB_SOURCE_DIR    = File::Spec->rel2abs($MECAB_SOURCE_DIR);
$MECAB_SOURCE        = File::Spec->rel2abs($MECAB_SOURCE);
$MECAB_EXE           = File::Spec->rel2abs($MECAB_EXE);

my %REQUIRES;

# Construct the necessary flags
my $CCFLAGS = $ENV{CCFLAGS};
my $LDFLAGS = $ENV{LDFLAGS};
if (! $RUNNING_IN_HELL) {
    $CCFLAGS ||= '-I/usr/local/include';
    $LDFLAGS ||= '-L/usr/local/lib';
}

if (! $RUNNING_IN_HELL) {
    eval {
        Devel::CheckLib::assert_lib(lib => "iconv", LIBS => $LDFLAGS);
    };
    if ($@) {
        print <<EOM;

*** Whoa! libiconv was not detected! ***

MeCab requires libiconv to work properly. You can either 
    (1) install it yourself by hand, or
    (2) install it via Alien::Iconv
EOM

        my $yn = prompt("Would you like to add Alien::Iconv to prerequisite modules?", "y");
        if ($yn !~ /^y(?:es)?$/) {
            print <<EOM;

You chose not to install libiconv. Please install it manually and
re-run perl Makefile.PL for Alien::MeCab.

EOM
            exit 0;
        }

        $REQUIRES{ 'Alien::MeCab' } = '1.12001';
    }
}

eval {
    Devel::CheckLib::assert_lib(lib => "mecab", LIBS => $LDFLAGS )
};
if (! $@) {
    print <<EOM;

*** Whoa!  We've detected a previous installtion of libmecab ***

Because Alien::MeCab may have been called to be installed from a dependency
of another module, we want to make sure that you *really* want to install
this version of Alien::MeCab (and therefore libmecab).

If you answer "y", then We're going to install
    libmecab: $MECAB_VERSION

This operation may OVERWRITE your previous installation
EOM
    my $yn = prompt("Really install?", "n");
    if ($yn !~ /^y(?:es)?$/) {
        exit 0;
    }
}

# Ask if we want to download the source.
my $sourcefile = $RUNNING_IN_HELL ? $MECAB_EXE : $MECAB_SOURCE;
if (! -f $sourcefile) {
    my $yn = prompt("mecab source file $sourcefile does not exist. Download it now?", "y");
    if ($yn =~ /^y(?:es)?$/i) {
        my @cmd = ($^X, File::Spec->catfile("src", "fetchsrc.pl"), "--version", $MECAB_VERSION);
        system(@cmd);
    }
}

# If the source hasn't been expanded, then unpack it
if ($^O ne 'MSWin32') {
    if (! -d $MECAB_SOURCE_DIR) {
        my $yn = prompt("Mecab source directory has not been unpacked yet. Unpack it now?", "y");
        if ($yn =~ /^y(?:es)?$/i) {
            eval {
                require Archive::Tar;
                Archive::Tar->can_handle_compressed_files or die "No compression support :(";
            };
            if ($@) {
                print STDERR "Archive extraction requires Archive::Tar (with IO::Zlib)\n";
                exit 0;
            }

            eval {
                chdir File::Spec->catfile($CURDIR, 'src');

                print "Unpacking... (please be patient)\n";
                Archive::Tar->extract_archive( $MECAB_BASENAME, 1 );
            };
            if ($@) {
                print STDERR "Failed to gunzip file $MECAB_SOURCE $IO::Compress::Gunzip::GunzipError\n";
                chdir $CURDIR;
                exit 0;
            }
            chdir $CURDIR;
        }
    }

    {
        print "\n";
        my $run_configure;
        if( -e File::Spec->catfile($MECAB_SOURCE_DIR, 'config.status')) {
            $run_configure = prompt(
                "Looks like MeCab has already been configured.\n".
                "Do you want to re-run configure?",
                "n"
            );
        } else {
            $run_configure = prompt(
                "No config.status found. Run MeCab's configure now?", 'y'
            );
        }

        if( $run_configure =~ /^y/i ) {
            print "\nWe're going to run configure for mecab.\n",
                "First, we'll ask you a few questions about common options\n\n";

            my $prefix = prompt( "Where would you like to install libmecab?", "/usr/local" );
            my $charset = prompt( "What charset would you like to use?", "utf8" );
            my $configure_args = '';
            $configure_args .= "--prefix=$prefix " if $prefix;
            $configure_args .= "--with-charset=$charset " if $charset;

            $configure_args .= prompt("Are there any other arguments you would like to pass to configure?" );

            print "\nMeCab will be configured with the following arguments:\n",
                "  $configure_args\n";

            chdir $MECAB_SOURCE_DIR;

            local $ENV{CFLAGS}  = $CCFLAGS;
            local $ENV{LDFLAGS} = $LDFLAGS;
            my @cmd = (File::Spec->catfile($MECAB_SOURCE_DIR, "configure"),
                split(/\s+/, $configure_args));
            if (system(@cmd) != 0) {
                print <<"END";
configure $configure_args failed: $!
    Something went wrong with the MeCab configuration.
    You should correct it and re-run Makefile.PL.
END
                chdir $CURDIR;
                exit 0;
            }
            chdir $CURDIR;
        }
    }
}

print <<EOM;
Going to use the following information:
    DIST_VERSION: $DIST_VERSION
    MECAB_VERSION: $MECAB_VERSION
    CCFLAGS: $CCFLAGS
    LDFLAGS: $LDFLAGS
EOM

WriteMakefile(
    CCFLAGS => $CCFLAGS,
    LDFLAGS => $LDFLAGS,
    NAME => 'Alien-MeCab',
    VERSION => $DIST_VERSION,
    PREREQ_PM => \%REQUIRES,
);

print "Now you should type 'make'\n";

package MY;
sub top_targets
{
    my $inherited = shift->SUPER::top_targets(@_);
    $inherited =~ s/^all :: /all :: libmecab /;
    return $inherited;
}

sub constants
{
    my $inherited = shift->SUPER::constants(@_);
    $inherited .= "MEACB_VERSION=$MECAB_VERSION\nMECAB_SRC=src/mecab-$MECAB_VERSION\n";
    return $inherited;
}

sub postamble {
    my $make_str;

	if ($RUNNING_IN_HELL) {
        $make_str = <<MAKE_FRAG;
libmecab:
	$MECAB_EXE

MAKE_FRAG
    } else {
        $make_str = <<'MAKE_FRAG';
libmecab:
	cd $(MECAB_SRC) && $(MAKE) all

MAKE_FRAG
    }

    $make_str .= <<'MAKE_FRAG';
fetchsrc:
	$(PERL) fetchsrc.pl

MAKE_FRAG

    return $make_str;
}


#sub metafile_target {
#    my $inherited = shift->SUPER::metafile_target(@_);
#    my $build_requires = <<EOM;
#build_requires:
#    Cwd: 0
#    File::Spec: 0
#EOM
#    $inherited =~ s/meta-spec:/${build_requires}meta-spec/;
#    return $inherited;
#}

__END__