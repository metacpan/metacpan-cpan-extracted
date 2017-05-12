#!perl
use strict;
use Cwd ();
use inc::Devel::CheckLib;
use ExtUtils::MakeMaker;
use File::Spec;

my $CURDIR = Cwd::cwd();

# Here's the file that we're going to use to extract some data
my $SPEC_FILE       = 'lib/Alien/Iconv.pm';

# Check for hellish-ness
my $RUNNING_IN_HELL = $^O eq 'MSWin32';

if ($RUNNING_IN_HELL) {
    print STDERR <<EOM;
I have no clue how to install iconv under Windows. If there's a way,
please help by sending patches!
EOM
    exit 0;
}

# Get the version 
my $DIST_VERSION  = do {
    require ExtUtils::MM_Unix;
    ExtUtils::MM_Unix->parse_version($SPEC_FILE);
};

# Actual iconv version. This is the number up to the second fractional digit
# of the dist version
my $ICONV_VERSION    = substr($DIST_VERSION, 0, 4);

# Filenames 
my $ICONV_SOURCE_DIR = File::Spec->catfile("src", "libiconv-$ICONV_VERSION");
my $ICONV_BASENAME   = "libiconv-$ICONV_VERSION.tar.gz";
my $ICONV_SOURCE     = File::Spec->catfile("src", $ICONV_BASENAME);

# Absolut-ize all paths
$ICONV_SOURCE_DIR    = File::Spec->rel2abs($ICONV_SOURCE_DIR);
$ICONV_SOURCE        = File::Spec->rel2abs($ICONV_SOURCE);

# Construct the necessary flags
my $CCFLAGS = $ENV{CCFLAGS};
my $LDFLAGS = $ENV{LDFLAGS};
if (! $RUNNING_IN_HELL) {
    $CCFLAGS ||= '-I/usr/local/include';
    $LDFLAGS ||= '-L/usr/local/lib';
}

eval {
    Devel::CheckLib::assert_lib(lib => "iconv", LIBS => $LDFLAGS )
};
if (! $@) {
    print <<EOM;

*** Whoa!  We've detected a previous installtion of libiconv ***

Because Alien::Iconv may have been called to be installed from a dependency
of another module, we want to make sure that you *really* want to install
this version of Alien::Iconv (and therefore libiconv).

If you answer "y", then We're going to install
    libiconv: $ICONV_VERSION

This operation may OVERWRITE your previous installation
EOM
    my $yn = prompt("Really install?", "n");
    if ($yn !~ /^y(?:es)?$/) {
        exit 0;
    }
}

# Ask if we want to download the source.
my $sourcefile = $ICONV_SOURCE;
if (! -f $sourcefile) {
    my $yn = prompt("iconv source file $sourcefile does not exist. Download it now?", "y");
    if ($yn =~ /^y(?:es)?$/i) {
        my @cmd = ($^X, File::Spec->catfile("src", "fetchsrc.pl"), "--version", $ICONV_VERSION);
        system(@cmd);
    }
}

# If the source hasn't been expanded, then unpack it

if (! -d $ICONV_SOURCE_DIR) {
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
            Archive::Tar->extract_archive( $ICONV_BASENAME, 1 );
        };
        if ($@) {
            print STDERR "Failed to gunzip file $ICONV_SOURCE $IO::Compress::Gunzip::GunzipError\n";
            chdir $CURDIR;
            exit 0;
        }
        chdir $CURDIR;
    }
}

{
    print "\n";
    my $run_configure;
    if( -e File::Spec->catfile($ICONV_SOURCE_DIR, 'config.status')) {
        $run_configure = prompt(
            "Looks like Iconv has already been configured.\n".
            "Do you want to re-run configure?",
            "n"
        );
    } else {
        $run_configure = prompt(
            "No config.status found. Run Iconv's configure now?", 'y'
        );
    }

    if( $run_configure =~ /^y/i ) {
        print "\nWe're going to run configure for iconv.\n",
            "First, we'll ask you a few questions about common options\n\n";

        my $prefix = prompt( "Where would you like to install libiconv?", "/usr/local" );
        my $configure_args = '';
        $configure_args .= "--prefix=$prefix " if $prefix;

        $configure_args .= prompt("Are there any other arguments you would like to pass to configure?" );

        print "\nIconv will be configured with the following arguments:\n",
            "  $configure_args\n";

        chdir $ICONV_SOURCE_DIR;

        local $ENV{CFLAGS}  = $CCFLAGS;
        local $ENV{LDFLAGS} = $LDFLAGS;
        my @cmd = (File::Spec->catfile($ICONV_SOURCE_DIR, "configure"),
            split(/\s+/, $configure_args));
        if (system(@cmd) != 0) {
            print <<"END";
configure $configure_args failed: $!
    Something went wrong with the Iconv configuration.
    You should correct it and re-run Makefile.PL.
END
            chdir $CURDIR;
            exit 0;
        }
        chdir $CURDIR;
    }
}


print <<EOM;
Going to use the following information:
    DIST_VERSION: $DIST_VERSION
    ICONV_VERSION: $ICONV_VERSION
    CCFLAGS: $CCFLAGS
    LDFLAGS: $LDFLAGS
EOM

WriteMakefile(
    CCFLAGS => $CCFLAGS,
    LDFLAGS => $LDFLAGS,
    NAME => 'Alien-Iconv',
    VERSION => $DIST_VERSION,
);

print "Now you should type 'make'\n";

package MY;
sub top_targets
{
    my $inherited = shift->SUPER::top_targets(@_);
    $inherited =~ s/^all :: /all :: libiconv /;
    return $inherited;
}

sub constants
{
    my $inherited = shift->SUPER::constants(@_);
    $inherited .= "MEACB_VERSION=$ICONV_VERSION\nICONV_SRC=src/libiconv-$ICONV_VERSION\n";
    return $inherited;
}

sub postamble {
    my $make_str;

	if ($RUNNING_IN_HELL) {
        $make_str = <<MAKE_FRAG;
MAKE_FRAG
    } else {
        $make_str = <<'MAKE_FRAG';
libiconv:
	cd $(ICONV_SRC) && $(MAKE) all

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