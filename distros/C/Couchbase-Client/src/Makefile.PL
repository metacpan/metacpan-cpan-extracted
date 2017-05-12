#!/usr/bin/perl
package PLCBCDeps;

use strict;
use warnings;
use ExtUtils::MakeMaker;
use Dir::Self;
use Devel::CheckLib;
use Dir::Self;
use Data::Dumper;
use File::Spec;
use Dir::Self;
use Config;

use Cwd qw(abs_path);

use lib (__DIR__ . '/..');

my $Sharepath = File::Spec->catfile(
    'auto', 'share', 'dist', 'Couchbase-Client', 'Library');

require ExtUtils::Liblist;

my $LIBCOUCHBASE = "libcouchbase";

my $PARENT_MM;

my $SEARCHPATH_S;
{
    my @checklib_libs = grep $_ && $_ ne '-lcouchbase', @PLCBTopLevel::LIBS;
    $SEARCHPATH_S = join(' ', @checklib_libs) || '';
}

my %CHECKLIB_OPTIONS = (
    LIBS => $SEARCHPATH_S,
    INC => $PLCBTopLevel::INC
);

my %MM_Options = (
    NAME => 'Couchbase::libcouchbase',
    AUTHOR => q{M. Nunberg <mnunberg@haskalah.org},
    VERSION_FROM => 'libcouchbase.pm',
    ABSTRACT_FROM => 'libcouchbase.pm'
);

my $LIBCOUCHBASE_CFUNC = <<'EOC';
unsigned int version = 0;
(void)libcouchbase_get_version(&version);
if(version >= 0x010001) {
    return 0;
}
return 1;
EOC

my $LIBEVENT_CFUNC = <<EOC;

int version_major = 0, version_minor = 0;

const char *version_string = event_get_version();
if(!version_string) {
    return 1;
}

sscanf(version_string, "%d.%d", &version_major, &version_minor);

if(version_major >= 2) {
    return 0;
} else if(version_major == 1 && version_minor >= 4) {
    return 0;
}
return 1;

EOC

sub check_dependency {
    my ($names,$fn,%extra) = @_;
    $names = ref $names ? $names : [ $names ];
    
    print STDERR "\nChecking for @{$names}...\n";
    local %ENV = %ENV;
    
    if ($PLCBTopLevel::Bundled) {
        return 0;
    }

    foreach my $libname (@$names) {
        my (undef,undef,$ldargs,$runpath,$sofile) =
            ExtUtils::Liblist->ext("$SEARCHPATH_S -l$libname", 0, 1);

        next unless ($sofile && ($sofile = $sofile->[0]) );
        
        print STDERR "\tfound shared object: $sofile \n";
        my %cl_opts = (
            %CHECKLIB_OPTIONS,
            lib => $libname,
            debug => 1,
            #libpath => "-Wl,$ldargs,$sofile",
        );

        if($runpath) {
            $ENV{LD_RUN_PATH} .= $runpath;
        }

        if($fn) {
            $cl_opts{function} = $fn;
        }
        print STDERR "\tCompiling test program\n";
        if(check_lib(%cl_opts, %extra)) {
            print STDERR "\tOK ($libname)\n";
            return 1;
        }
    }
    print STDERR "\tNOT FOUND\n";
    return 0;
}


sub insert_announcement {
    my $msg = shift;
    my @lines;
    my $line = "\t\$(NOECHO)\$(ECHO) ";
    push(@lines, $line . "~" x 60) for (0..2);
    push @lines, $line . $msg;
    push(@lines, $line . "~" x 60) for (0..2);
    if(wantarray) {
        return @lines;
    } else {
        return join("\n", @lines);
    }
}

sub create_buildscript_invocation {
    my ($mm,$build,$install,$deps) = @_;

    #mm is the parent Makefile, here
    
    # we need to make sure our flags match whatever Devel::CheckLib might have
    # used to determine an available dependency:
    
    my $script_cppflags = $mm->{INC};
    my $config_ccflags = $Config{ccflags};
    
    # Strip any -D's, -f's, -g, and -O from the flags. and remove -pthread
    
    $config_ccflags =~ s/-(?:D|f|O|M|g)\S+//g;
    
    #string excessive whitespace:
    $config_ccflags =~ s/\s+/ /g;
    
    $script_cppflags .= ' ' . $config_ccflags;
    
    
    $PLCBTopLevel::U_LibPath ||= "";
    
    my $script_ldflags = $mm->{LDLOADLIBS} . ' ' . $PLCBTopLevel::U_LibPath .
        ' ' . $Config{ldflags};
    
    my $java_arg = $PLCBTopLevel::HaveJava ? "--have-java" : "";
    
    my @lines = (

        #begin long commandline invocation:

        "\t".
        #'$(NOECHO) $(ECHO) '.
        '$(PERLRUN) ' .
        File::Spec->catfile('..', 'build_libraries.pl') . "\\",
        "\t".sprintf(" --build-prefix=%s \\\n\t\t--install-prefix=%s $java_arg",
                $mm->quote_literal($build),
                $mm->quote_literal($install)) . "\\",

        "\t".sprintf(" --env-cppflags=%s",
                $mm->quote_literal($script_cppflags)) . "\\",


        "\t".sprintf(" --env-libs=%s",
                $mm->quote_literal($script_ldflags)) . "\\",

        "\t".sprintf(" --rpath=%s",
                $mm->quote_literal($mm->{LD_RUN_PATH})) . "\\",
        "\t".join(" ", @$deps),

    );

    return @lines;

}


sub ldrunpath2rpath {
    my ($parent, $ld_run_path) = @_;
    # check if Perl has -rpath in its own flags:
    # inspired by Tony Cook:
    # http://git.imager.perl.org/imager.git/blob/HEAD:/lib/Imager/Probe.pm#l281

    return unless ($Config{lddlflags} =~ /([^ ]*-(?:rpath|R)[,=]?)([^ ]+)/
                   && -d $2);

    my $prefix = $1;
    my $existing_flags = $parent->{LDDLFLAGS};
    my @components = map { "$prefix$_" } split($Config{path_sep}, $ld_run_path);
    $parent->{LDDLFLAGS} =  join(" ", @components) . " " . $Config{lddlflags};
    printf STDERR ("\nFound RPATH directive in perl's linker flags.\n".
                   "Mangled compiler line now is: %s", $parent->{LDDLFLAGS});
}

sub mangle_parent_makefile {
    my ($parent,$deps) = @_;
    no strict 'refs';

    print STDERR ("Mangling parent MM methods for extra dependencies\n");

    my $libpath = File::Spec->catfile($Sharepath, 'lib');

    my $methname = ref($parent).'::dynamic_lib';
    my $old_meth = $parent->can('dynamic_lib');

    my $blib_dep_path = "\$(INST_LIB)\$(DFSEP)$Sharepath";
    my $dest_dep_path = "\$(DESTINSTALLSITELIB)\$(DFSEP)$Sharepath";

    my $dep = "$blib_dep_path\$(DFSEP)lib\$(DFSEP)$LIBCOUCHBASE.\$(SO)";

    $parent->{MYEXTLIB} = $dep;

    *{ref($parent) . "::dynamic_lib"} = sub {
        my ($mm,@args) = @_;
        my $ret = $old_meth->($mm,@args, INST_DYNAMIC_DEP => $dep);
        $ret = join("\n",
            "\$(MYEXTLIB) ::",
            "\t\ " . $mm->cd("src", '$(MAKE)'),
        ) . $ret;

        return $ret;
    };

    my $ldload = $parent->{LDLOADLIBS} || "";
    my $runpath = $parent->{LD_RUN_PATH} || "";

    $runpath = "$blib_dep_path\$(DFSEP)lib:" .
                "$dest_dep_path\$(DFSEP)lib".
                ":$runpath";
    $ldload = "-L$blib_dep_path\$(DFSEP)lib";


    {
        my $parent_dir = abs_path("..");
        $parent->{INST_LIB} = File::Spec->catfile($parent_dir,
                                                  $parent->{INST_LIB});
    }

    $parent->{LDLOADLIBS} = $ldload;
    $parent->{LD_RUN_PATH} = $runpath;

    ldrunpath2rpath($parent, $runpath);

    $parent->{INC} .= " -I$blib_dep_path\$(DFSEP)include";


    my $parent_inc = $parent->{INC};

    my $inc_oneliner = sprintf("PLCB_ConfUtil::write_tmpflags(qq{%s})",
                               $parent_inc);
    no warnings qw(redefine once);
    *MY::postamble = sub {
        my @lines = (
            "$dep:",
            (insert_announcement("will build for ultimate target $dep")),
            (create_buildscript_invocation($parent,
                    $blib_dep_path, $dest_dep_path, $deps)),
            (insert_announcement("dependencies done")),

            #now try to insert some constants.
            "\t".$parent->oneliner($inc_oneliner, ['-I../', '-MPLCB_ConfUtil']),
            "",
            "",


            "all :: $dep",
        );

        return join("\n", @lines);
    };
}

sub MM_Configure {
    my ($self,$h) = @_;
    my $parent = $ExtUtils::MakeMaker::Parent[0];
    $PLCBTopLevel::MM_TopLevel = $parent;

    $PARENT_MM = $parent;
    die("Must be run from within top-level Makefile.PL") unless $parent;
    my @to_build;

    if($ENV{PLCB_BUILD_ALL}) {
        log_err('build_all reuqested');
        @to_build = qw(VBUCKET COUCHBASE EVENT);
        goto GT_MANGLE;
    }
    
    printf STDERR ("\nWill run a few test programs to see ".
                   "if depencies are required\n");
    
    my $have_libcouchbase =
        check_dependency('couchbase',$LIBCOUCHBASE_CFUNC,
            header => ['sys/types.h', 'libcouchbase/couchbase.h'] );

    if($have_libcouchbase) {
        return $h; #nothing to do here.
    } else {
        push @to_build, qw(COUCHBASE VBUCKET);
    }

    if(!check_dependency(
        'event', $LIBEVENT_CFUNC, header => ['event.h', 'stdio.h'] )) {
        push @to_build, 'EVENT';
    }

    GT_MANGLE:
    my $errmsg = "\n".
                "Couchbase::Client needs to build the following dependencies:\n".
                "\t@to_build\n\n".
                "You may want to install dependencies from your package manager\n".
                "or install the bundled version.\n".
                "\n".
                "Installing the bundled version will (for better or worse) NOT\n".
                "affect applications which depend on those libraries\n".
                "\n".
                "Install bundled libraries?";
    my $promptval = prompt($errmsg, "y");
    
    if($promptval !~ /^y/i) {
        print STDERR "You have selected not to build and install the bundled\n".
                    "dependencies. Couchbase::Client will not be built\n";
        exit(0);
    }
    
    print STDERR "Will build: @to_build\n\n...";
    mangle_parent_makefile($parent, \@to_build);


    return $h;

}

$MM_Options{CONFIGURE} = \&MM_Configure;

WriteMakefile(%MM_Options);
