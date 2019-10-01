#!perl
# Makefile.PL for App::GitFind
use 5.010;
use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;
use File::Spec;

my $VERSION_FROM = File::Spec->catfile(qw(lib App GitFind.pm)); # main code
my $SCRIPT = File::Spec->catfile(qw(script git-find));          # invoker
my $IS_TRIAL = check_trial();
my $secure_perl_path = get_perl_filename();
my @provides = ();

# yapp-generated command-line parser
my $CMDLINE_FROM = File::Spec->catfile(qw(support cmdline.yp));
my $CMDLINE_TO = File::Spec->catfile(qw(lib App GitFind cmdline.pm));
my $CMDLINE_DIR = File::Spec->catfile(qw(lib App GitFind));

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
    # and add distcheck and yapp before dist.
    sub dist_core {
        my $self = shift;
        my $text = $self->SUPER::dist_core(@_);
        $text =~ s/^dist\h*:[^:]/dist:: distcheck $CMDLINE_TO /m;

        return $text;
    } # MY::dist_core

    # Generate README.md; add uninstall target and other test targets
    sub postamble {     # TODO also handle Windows nmake syntax (SET vs. export)

        # Note: pod2markdown is marked with a hyphen so that `make` can
        # succeed and generate META files even if Pod::Markdown is not yet
        # installed.

        my $make_readme_md = File::Spec->catfile(qw(support readme.pl));
        return <<EOT;

# Convenience target to run yapp
yapp: $CMDLINE_TO

# Convenience target to run cover
cover:
\tcover +ignore 'lib/perl5/' -test

$CMDLINE_TO: $CMDLINE_FROM
\t-mkdir "$CMDLINE_DIR"
\tyapp -m "App::GitFind::cmdline" -o "\$@" "\$<"

authortest:
\tRELEASE_TESTING=1 prove -lvj4 xt

testhere:   # Run the tests from lib rather than blib
\tprove -lj4

README.md: $SCRIPT Makefile.PL $make_readme_md
\t-"$secure_perl_path" "$make_readme_md" -i "\$<" -o "\$@" -f md

README: $SCRIPT Makefile.PL $make_readme_md
\t-"$secure_perl_path" "$make_readme_md" -i "\$<" -o "\$@" -f text

# The following command line is rather bizarre so that it can be run on
# bash or cmd.  '\$\$' collapses to a single dollar sign, and the string eval
# is used to separate the dollar signs from the variable names so they will
# not trigger shell interpolation.  Double-quotes only, for compatibility
# with cmd, and no embedded double quotes (q() or qq() instead).

#git-find.packed.pl: $VERSION_FROM $SCRIPT Makefile.PL $CMDLINE_TO
#\t"$secure_perl_path" -Ilib -MApp::FatPacker -MConfig -e "eval q(\$\$) . q(ENV{PERL5LIB}=join \$\$) . q(Config{path_sep}, \@INC;); App::FatPacker->new->run_script([q(pack), q($SCRIPT)])" > "\$@"

all :: README.md README #git-find.packed.pl
dist :: README.md README #git-find.packed.pl

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
    NAME             => 'App::GitFind',
    AUTHOR           => q{Christopher White <cxw@cpan.org>},
    VERSION_FROM     => $VERSION_FROM,
    ABSTRACT_FROM    => $VERSION_FROM,
    LICENSE          => 'mit',
    EXE_FILES        => [$SCRIPT],
    MIN_PERL_VERSION => '5.010',

    # In the following, if a specific version is listed, but no explanation
    # is given, that means we want that version for bugfixes it includes.
    CONFIGURE_REQUIRES => {
        'Config' => '0',
        'ExtUtils::MakeMaker' => '0',
        'File::Spec' => '0',
        'strict' => '0',
        'warnings' => '0',
    },
    BUILD_REQUIRES => {
        #'App::FatPacker' => '0.009016',
        'Getopt::Long' => '2.5',
        'Parse::Yapp' => '0',
        'Path::Class' => '0.37',
        'Pod::Markdown' => '0',     # pod2markdown
        'Pod::Text' => '0',         # pod2text
    },
    TEST_REQUIRES => {
        'Capture::Tiny' => '0.39',
        'Carp' => '0',
        'Cwd' => '0',
        'Exporter' => '0',
        'File::Basename' => '0',
        'Import::Into' => '0',
        'lib::relative' => '1.000',
        'List::AutoNumbered' => '0.000007',
        'List::Util' => '1.43',
        'Path::Class' => '0',
        #'Scalar::Util' => '0',
        'Sub::Multi::Tiny' => '0.000012',
        #'Test::Deep' => '0.084',        # for superhashof
        #'Test::Directory' => '0.02',    # for subdirs
        #'Test::Exception' => '0',
        'Test2::V0' => '0.000125',      # the latest as of writing
        # Test::TempDir::Tiny?  If so, remove Test::Directory dependency?
        'Test::UseAllModules' => '0.15',    # Test2 support
        #'Test::Warn' => '0.35',     # for metadata
        'Types::Standard' => '1.004004'
    },
    PREREQ_PM => {
        #'Class::Method::Modifiers' => '2.10',   # most recent code change
        'Class::Tiny' => '1.001',   # BUILDARGS
        #'Class::Tiny::ConstrainedAccessor' => '0.000010', # custom constraints
        'Class::Tiny::Immutable' => '0',

        #'Config' => '0',
        #'Cwd' => '0',

        #'constant' => '0',
        #'Data::Dumper' => '2.154',      # For Maxrecurse
        'Data::Dumper::Compact' => '0',
        #'Exporter' => '0',
        'Fcntl' => '0',
        #'feature' => '0',
        'File::Find::Object' => '0.3.1',
        # 'File::Find::Rule' => '0',    # - might be nice for finding files
        #'File::Glob' => '0',
        #'File::Globstar' => '0.5',      # Fewer dependencies
        #'File::Next' => '1.16',
        #'File::Path::Tiny' => '0.9',
        #'File::pushd' => '1.013',
        #'File::Spec' => '0',
        #'File::stat' => '0',
        #'File::Which' => '1.22',    # for msys2 support
        'Getargs::Mixed' => '1.04', # For -undef_ok option
        'Getopt::Long' => '2.34',   # For autohelp and autoversion
        'Git::Raw' => '0.84',       # For worktrees, submodules
        'Hash::Merge' => '0.299',
        #'Hash::Ordered' => '0.011',
        #'Import::Into' => '0',
        'Iterator::Simple' => '0.07',

        'List::SomeUtils' => '0.50',
        'Math::Cartesian::Product' => '1.009',

        # 'Module::Find' => '0.12', # For bugfixes
                                    # - Use for finding plugins to load.
                                    # - May also need Module::Runtime.
                                    # - Alternative is Module::Pluggable,
                                    #   but that appears to have more test
                                    #   failures.

        # 'Number::Compare' => '0', # - looks cool

        #'overload' => '0',

        'Path::Class' => '0.37',
            # NOTE: we no longer use Path::Class directly - we have our
            # own version in App::GitFind::PathClassMicro.  However,
            # listing Path::Class here means we will always have the correct
            # dependencies for that rolled-in version.

        'Pod::Usage' => '0',
        'POSIX' => '0',
        # 'Probe::Perl' => '0', # For perl interpreter file location or other info.

        #'Quote::Code' => '1.01',
        #'Role::Tiny' => '1.000000',

        #'Scalar::Util' => '0',
        #'Set::Scalar' => '1.27',    # For correct metadata
        ## 'Storable' => '3.06',
            # So it can handle REGEXP -
            # https://rt.perl.org/Public/Bug/Display.html?id=50608

        #'String::Print' => '0.92',
        # 'Sub::ScopeFinalizer' => '0.02',        # For correct META.yml

        #'Syntax::Construct' => '0.07',
        #'Type::Tiny' => '1.004004',

        'vars' => '0',
        'vars::i' => '1.10',
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },

        resources => {
            bugtracker => {
                web  => 'https://github.com/cxw42/git-find/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/cxw42/git-find.git',
                web  => 'https://github.com/cxw42/git-find',
            },
        },

        prereqs => {
            develop => {
                requires => {
                    'App::RewriteVersion' => '0',   # for perl-bump-version
                    'CPAN::Meta' => '0',
                    'File::Spec' => '0',
                    'Module::Metadata' => '1.000016',
                    'Perl::PrereqScanner' => '1.023',
                    'Test::Kwalitee' => '0',
                    'Test::More' => '0',    # used in xt
                },
                suggests => {
                    'Devel::Cover' => '0',
                    'ylib' => '0.003',  # for `PERL5OPT=-Mylib prove -l`
                },
            },
        },

        @provides,

    }, #META_MERGE

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-GitFind-*' },
); # %opts

if($IS_TRIAL) {
    print STDERR "TRIAL version\n";
    $opts{META_MERGE}->{release_status} = 'testing';
    $opts{DISTVNAME} = '$(DISTNAME)-$(VERSION)-TRIAL';
}

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
