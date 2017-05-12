use ExtUtils::MakeMaker;
use Config;
use strict;
use DBI 1.00;
use DBI::DBD;

print "Configuring PgSPI\n";
print "Remember to actually read the README file !\n";

my $POSTGRES_HOME;

if (!$ENV{POSTGRES_HOME}) {
    
    die "please set environment variables POSTGRES_HOME!\n";
}
$POSTGRES_HOME=$ENV{POSTGRES_HOME};

my $os = $^O;
print "OS: $os\n";

my $dbi_arch_dir;
if ($os eq 'MSWin32') {
    $dbi_arch_dir = "\$(INSTALLSITEARCH)/auto/DBI";
} else {
    $dbi_arch_dir = dbd_dbi_arch_dir();
}

my %opts = (
    NAME         => 'DBD::PgSPI',
    VERSION_FROM => 'PgSPI.pm',
    INC          => "-I$POSTGRES_HOME/include -I$POSTGRES_HOME/backend -I$POSTGRES_HOME/interfaces/libpq -I$dbi_arch_dir",
    OBJECT       => "PgSPI\$(OBJ_EXT) dbdimp\$(OBJ_EXT)",
    LIBS         => [],
    AUTHOR       => 'Alex Pilosov (alex@pilosov.com)',
    ABSTRACT     => 'PostgreSQL database driver for the DBI module',
    OPTIMIZE     => "-g",
    dynamic_lib  => { OTHERLDFLAGS     => "-g", },
);

WriteMakefile(%opts);

exit(0);

# end of Makefile.PL
