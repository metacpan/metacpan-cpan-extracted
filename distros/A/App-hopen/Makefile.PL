#!perl
# Makefile.PL for App::hopen
use 5.014;
use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;
use File::Spec;

my $VERSION_FROM = File::Spec->catfile(qw(lib App hopen.pm));
my $IS_TRIAL = check_trial();
my $secure_perl_path = get_perl_filename();
my @provides = ();

# Check if this is a TRIAL version {{{1
sub check_trial {
    TRIAL: {
        # Get the VERSION line
        open my $fd, '<', $VERSION_FROM or last TRIAL;
        my $linetext;
        while(<$fd>) {
            next unless /VERSION/;
            $linetext = $_;
            last;
        }
        close $fd;
        return !!($linetext =~ /\bTRIAL\b/);
    }
    return 0;
} #check_trial()

# }}}1
# Module metadata {{{1
eval {
    require Module::Metadata;
    @provides =
        (provides => Module::Metadata->provides(version => '2', dir => 'lib'));
        # Thanks to https://stackoverflow.com/a/28928985/2877364 by LEONT
        # for suggesting Module::Metadata.
};

# }}}1
# Get the filename of the Perl interpreter running this. {{{1
# Modified from perlvar.
# The -x test is for cygwin or other systems where $Config{perlpath} has no
# extension and $Config{_exe} is nonempty.  E.g., symlink perl->perl5.10.1.exe.
# There is no "perl.exe" on such a system.
sub get_perl_filename {
    my $secure_perl_path = $Config{perlpath};
    if ($^O ne 'VMS') {
        $secure_perl_path .= $Config{_exe}
            unless (-x $secure_perl_path) ||
                            ($secure_perl_path =~ m/$Config{_exe}$/i);
    }
    return $secure_perl_path;
} # get_perl_filename()

# }}}1
# Makefile customization (MY) {{{1
{   package MY;

    # dist_core: make `dist` a :: target rather than a : target,
    # and add distcheck before dist.  Also, add -TRIAL to the tgz if necessary.
    sub dist_core {
        my $self = shift;
        my $text = $self->SUPER::dist_core(@_);
        $text =~ s/^dist\s*:[^:]/dist:: distcheck /m;

        # Add -TRIAL if it's a trial release
        if($IS_TRIAL) {
            # Note: we don't have to worry about EOL; Appveyor uses gmake even
            # on Windows, and it only uses \n.
            print STDERR "TRIAL version\n";
            my $newtext .=  # Command to rename the tgz.  TODO see if this works on Windows.
                "\t\"$secure_perl_path\" -MExtUtils::Command -e mv -- " .
                '"$(DISTVNAME).tar$(SUFFIX)" ' .
                '"$(DISTVNAME)-TRIAL.tar$(SUFFIX)"' . "\n";

            # Insert $newtext at the end of the `dist` target
            $text =~ s{
                ^(dist\h*:.*\n      # dist header line
                    (?:\h+\S.*\n)+) # dist body lines.  `.` doesn't match `\n`.
                                    # NOTE: on Appveyor, the continuation line
                                    # begins with a space rather than a tab.
                                    # Therefore, look for \h after \n.
                                    # Not \s, because that matches a \n!
            }{$1$newtext}mx;
        } #endif $IS_TRIAL

        return $text;
    } # MY::dist_core

    # Generate README.md; add uninstall target and other test targets
    sub postamble {     # TODO also handle Windows nmake syntax (SET vs. export)

        # Note: pod2markdown is marked with a hyphen so that `make` can
        # succeed and generate META files even if Pod::Markdown is not yet
        # installed.

        my $make_readme_md = File::Spec->catfile(qw(support readme.pl));
        return <<EOT;
authortest:
\tRELEASE_TESTING=1 prove -lvj4 xt

testhere:   # Run the tests from lib rather than blib
\tprove -lj4

README.md: @{[$VERSION_FROM]} Makefile.PL $make_readme_md
\t"$secure_perl_path" "$make_readme_md" -i "\$<" -o "\$@" -f md --appveyor cxw42/app-hopen --avbadge hopenbuild/app-hopen

README: @{[$VERSION_FROM]} Makefile.PL $make_readme_md
\t"$secure_perl_path" "$make_readme_md" -i "\$<" -o "\$@" -f text

all :: README.md README
dist :: README.md README

# Uninstallation: mimic what the normal "uninstall" target does, but actually
# carry out the actions.
# Note: this may leave empty directories in place, since the packlist only
# includes files.

ACTUALLY_UNINSTALL = "$secure_perl_path" -MExtUtils::Install -e 'uninstall(shift,1)' --

actually_uninstall :: actually_uninstall_from_\$(INSTALLDIRS)dirs
\t\$(NOECHO) \$(NOOP)

actually_uninstall_from_perldirs ::
\t-\$(ACTUALLY_UNINSTALL) "\$(PERL_ARCHLIB)/auto/\$(FULLEXT)/.packlist"

actually_uninstall_from_sitedirs ::
\t-\$(ACTUALLY_UNINSTALL) "\$(SITEARCHEXP)/auto/\$(FULLEXT)/.packlist"

actually_uninstall_from_vendordirs ::
\t-\$(ACTUALLY_UNINSTALL) "\$(VENDORARCHEXP)/auto/\$(FULLEXT)/.packlist"

EOT

    } #postamble()
} #package MY

# }}}1

# Main options for EUMM
my %opts = (
    NAME             => 'App::hopen',
    AUTHOR           => q{Christopher White <cxwembedded@gmail.com>},
    VERSION_FROM     => $VERSION_FROM,
    ABSTRACT_FROM    => $VERSION_FROM,
    #ABSTRACT         => 'The hopen build system, command-line interface',
    LICENSE          => 'lgpl_2_1',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.014',
        # For:
        #   - full Unicode support (this was the big one) (5.014)
        #   - string "eval" handles $@ correctly (see perldoc -f eval)
        #   - nondestructive replace (s///r) (5.014)
        #   - backtracking control verbs (5.010)
        #   - working smartmatch (5.010001)
        #   - stringifying regexes with modifiers (5.014)
        #   - FH->autoflush without needing IO::Handle (see
        #     perldoc -f select) (5.014)

    # In the following, if a specific version is listed, but no explanation
    # is given, that means we want that version for bugfixes it includes.
    # Prereqs commented out with "##" were used at one time but no longer
    # appear to be.
    CONFIGURE_REQUIRES => {
        'Config' => '0',
        'ExtUtils::MakeMaker' => '0',
        'File::Spec' => '0',
        'strict' => '0',
        'warnings' => '0',
    },
    BUILD_REQUIRES => {
        'Getopt::Long' => '0',
        'Path::Class' => '0.37',
        'Pod::Markdown' => '0',     # pod2markdown
        'Pod::Text' => '0',         # pod2text
    },
    TEST_REQUIRES => {
        'Carp' => '0',
        'Exporter' => '0',
        'Import::Into' => '0',
        'rlib' => '0',
        'Scalar::Util' => '0',
        'Test::Deep' => '0.084',        # for superhashof
        ## 'Test::Directory' => '0.02',    # for subdirs
        'Test::Exception' => '0',
        'Test::More' => '0',
        # Test::TempDir::Tiny?  If so, remove Test::Directory dependency?
        'Test::Warn' => '0.35',     # for metadata
    },
    PREREQ_PM => {
        # Other hopen packages -------------------
        'Data::Hopen' => '0.000013',

        # Non-hopen dependencies -----------------
        #'Algorithm::Dependency' => '1.106',
            # - Probably don't need this; we can use Graph::topological_sort().

        'Carp' => '0',

        'Class::Method::Modifiers' => '2.10',   # most recent code change
        'Class::Tiny' => '1.000',   # New API.  NOTE: <1.001 has no BUILDARGS
        #'Class::Tiny::Antlers' => '0',

        #'Class::Tiny::Chained' => '0.002',
            # - Looks like it might be handy.
            # 0.002+ because that has only core dependencies.

        'Class::Tiny::ConstrainedAccessor' => '0.000010',   # custom constraints

        ## 'Class::XPath' => '1.4',
        'Config' => '0',
        'Cwd' => '0',

        'constant' => '0',
        'Data::Dumper' => '0',
        'Deep::Hash::Utils' => '0.03',  # For correct metadata
        ## 'experimental' => '0.009',      # For support on perl < 5.15.7
        'Exporter' => '0',
        'feature' => '0',
        # 'File::Find::Rule' => '0',    # - might be nice for finding files
        'File::Glob' => '0',
        #'File::Globstar' => '0.5',      # Fewer dependencies
        'File::Path::Tiny' => '0.9',
        'File::pushd' => '1.013',
        'File::Spec' => '0',
        'File::stat' => '0',
        'File::Which' => '1.22',    # for msys2 support
        'Hash::Merge' => '0.299',
        'Hash::Ordered' => '0.011',
        'Import::Into' => '0',
        'Getargs::Mixed' => '1.04', # For -undef_ok option
        'Getopt::Long' => '2.5',    # For long option bugfix
        'Graph' => '0.9704',        # For latest multiedged support
        'List::MoreUtils' => '0.428',

        # 'Module::Find' => '0.12', # For bugfixes
                                    # - Use for finding plugins to load.
                                    # - May also need Module::Runtime.
                                    # - Alternative is Module::Pluggable,
                                    #   but that appears to have more test
                                    #   failures.

        # 'Number::Compare' => '0', # - looks cool

        'overload' => '0',

        'Package::Alias' => '0.12',

        # 'Parse::RecDescent' => '1.967015',
            # - Use for parsing Lua tables as inline config data?
            #   I am thinking about using this for specifying flavors at
            #   build time.  E.g., `--flavor debug=1,["+"]=42`.
            # - Syntax at https://www.lua.org/pil/3.6.html .
            # - See https://www.perlmonks.org/?node_id=462581 for operator
            #   precedence in P::RD grammars.

        'Path::Class' => '0.37',
        'Pod::Usage' => '0',
        # 'Probe::Perl' => '0', # For perl interpreter file location or other info.
                                # Alternative: Padre::Perl

        'Quote::Code' => '1.01',
        #'Role::Tiny' => '1.000000',

        'Scalar::Util' => '0',
        'Set::Scalar' => '1.27',    # For correct metadata
        ## 'Storable' => '3.06',
            # So it can handle REGEXP -
            # https://rt.perl.org/Public/Bug/Display.html?id=50608

        'String::Print' => '0.92',
        ## 'Sub::ScopeFinalizer' => '0.02',        # For correct META.yml

        'strict' => '0',
        'Type::Tiny' => '1.004004',

        'vars::i' => '1.06',
        'warnings' => '0',
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },

        resources => {
            bugtracker => {
                web  => 'https://github.com/hopenbuild/App-hopen/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/hopenbuild/App-hopen.git',
                web  => 'https://github.com/hopenbuild/App-hopen',
            },
        },

        prereqs => {
            develop => {
                requires => {
                    'App::RewriteVersion' => '0',   # for perl-bump-version
                    'Module::Metadata' => '1.000016',
                },
            },
        },

        @provides,

    }, #META_MERGE

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-hopen-*' },
); # %opts

$opts{META_MERGE}->{release_status} = 'testing' if $IS_TRIAL;

# Some tests run on older versions of EUMM that do not support TEST_REQUIRES.
# This is a workaround, modified from
# https://metacpan.org/source/RJBS/JSON-Typist-0.005/Makefile.PL ,
# linked from http://blogs.perl.org/users/neilb/2017/05/specifying-dependencies-for-your-cpan-distribution.html .
# If we are on a version of EUMM that doesn't support TEST_REQUIRES,
# move those dependencies to PREREQ_PM.
unless( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
    $opts{PREREQ_PM}->{$_} = $opts{TEST_REQUIRES}->{$_}
        foreach keys %{$opts{TEST_REQUIRES}};
    delete $opts{TEST_REQUIRES};
}

WriteMakefile(%opts);
# vi: set fdm=marker fdl=0: #
