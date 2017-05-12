use ExtUtils::MakeMaker;

use lib qw(../lib);
use Apache::src ();
my $src = Apache::src->new;

WriteMakefile(
    DEFINE => '-g',
    NAME        => "Apache::SubProcess",
    VERSION_FROM => "SubProcess.pm",
    INC       => $src->inc,
    TYPEMAPS  => $src->typemaps,
);
