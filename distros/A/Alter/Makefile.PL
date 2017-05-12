use 5.008000;
use ExtUtils::MakeMaker;

$linktype = check_cc() ? 'dynamic' : '';

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Alter',
    VERSION_FROM      => 'lib/Alter.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Alter.pm', # retrieve abstract from module
       AUTHOR         => 'Anno Siegel <anno@zrz.tu-berlin.de>') : ()),
    XS                => {},
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT          => '$(O_FILES)', # link all the C files too
    CCFLAGS           => '-Wuninitialized -Wunused -DDEBUGGING',
    # suppress xs part if compiler no workee
    linkext           => { LINKTYPE => $linktype },
);

use Config;
sub check_cc {
    my $try = 'try_cc';
    my $src = "$try.c";
    unlink glob "$try*";
    open my $out, '>', $src or return;
    print $out
        "int main(int argc, char *argv[]) {\n",
        "    return 0;\n",
        "}\n";
    close $out;
    my ( $cc, $ccflags, $ldflags) = @Config{ qw( cc ccflags ldflags)};
    my $res = do {
        local *STDERR;
        open STDERR, '>', "$try.err";
        0 == system( $cc =>
            -o => $try,
            split( ' ', $ccflags),
            split( ' ', $ldflags),
            $src,
        );
    };
    $res &&= 0 == system( "./$try");
    unlink glob "$try*";
    $res;
}
