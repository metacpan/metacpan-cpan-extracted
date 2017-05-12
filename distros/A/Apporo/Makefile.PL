use inc::Module::Install;
use Module::Install::XSUtil;

name 'Apporo';
all_from 'lib/Apporo.pm';

cc_src_paths qw/xs/;
#makemaker_args->{C} = ['xs/Apporo.cc'];
#makemaker_args->{XS}->{'xs/Apporo.xs'} = 'xs/Apporo.cc';

can_cc or die "This module requires a C compiler";

my @include_pathes = ();
if (-e "/usr/local/include/apporo.h") {
    push @include_pathes, "/usr/local/include";
}
elsif (-e "/usr/include/apporo.h") {
    push @include_pathes, "/usr/include";
}
else { push @include_pathes, "/usr/local/include"; }

cc_include_paths @include_pathes;

my @ld_pathes = ();
if (-e "/usr/lib64/libapporo.a") {
    push @ld_pathes, "-L/usr/lib64";
}
elsif (-e "/usr/lib32/libapporo.a") {
    push @ld_pathes, "-L/usr/lib32";
}
elsif (-e "/usr/lib/libapporo.a") {
    push @ld_pathes, "-L/usr/lib";
}
elsif (-e "/usr/local/lib64/libapporo.a") {
    push @ld_pathes, "-L/usr/local/lib64";
}
elsif (-e "/usr/local/lib32/libapporo.a") {
    push @ld_pathes, "-L/usr/local/lib32";
}
elsif (-e "/usr/local/lib/libapporo.a") {
    push @ld_pathes, "-L/usr/local/lib";
}
else { push @ld_pathes, "-L/usr/local/lib"; }
cc_append_to_libs @ld_pathes;

cc_append_to_ccflags qw/-g/;
makemaker_args->{CC} = 'g++';
makemaker_args->{LD} = 'g++';
makemaker_args->{OPTIMIZE} = '-O2';
makemaker_args->{XSOPT} = '-C++';
#makemaker_args->{LDDLFLAGS} = "-shared -O2 -fstack-protector ".$ld_pathes[0];
makemaker_args->{LDFLAGS} = "-fstack-protector ".$ld_pathes[0];
makemaker_args->{LIBS} = $ld_pathes[0]." -lapporo -ltsubomi";

=pod
makemaker_args(
#    CC => "g++",
#    LD => "g++",
#    INC => "-I/usr/local/include",
#    CCFLAGS => "-g",
#    LDFLAGS => "-L/usr/local/lib",
#    OPTIMIZE => "-O2",
    LIBS => ['-L/usr/local/lib -lapporo'],
    XSOPT => '-C++',
    #OBJECT => '$(O_FILES)',
    clean => {
        FILES => q{
            *.stackdump
            *.gcov *.gcda *.gcno
            *.out
            nytprof
            cover_db
        },
    },
);
=cut

tests 't/*.t';

build_requires 'Test::More';
build_requires 'Devel::CheckLib';

cc_warnings;
use_ppport  3.19;;
auto_include;
auto_set_repository;
WriteAll;
