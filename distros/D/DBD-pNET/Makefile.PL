use ExtUtils::MakeMaker;
use Config;

$| = 1;
print "Checking for DBI, 0.86 or later ... ";
$@ = '';
eval "use DBI 0.86 (); use DBI::DBD";
if ($@) {
    print STDERR "\nYou must have installed the 'DBI' module, version",
	"0.86 or later.\n";
    print STDERR "You get it at the CPAN. See 'man CPAN' or 'perldoc CPAN'";
    print STDERR "for more info.\n";
    exit 10;
}
print "ok\n";
print "Checking for Storable ... ";
$@ = '';
eval "use Storable ();";
if ($@) {
    print STDERR "\nYou must have installed the 'Storable' module.\n";
    print STDERR "You get it at the CPAN. See 'man CPAN' or 'perldoc CPAN'";
    print STDERR "for more info.\n";
    exit 10;
}
print "ok\n";
print "Checking for RPC::pServer ... ";
$@ = '';
eval "use RPC::pServer (); use RPC::pClient ();";
if ($@) {
    print STDERR "\nYou must have installed the pRPC-modules.\n";
    print STDERR "You can get them at the CPAN or at the same place,\n";
    print STDERR "where this module came from.\n";
    exit 10;
}
print "ok\n";


$inc = '-I' . $Config{'installsitearch'} . '/auto/DBI';

if ($ENV{HOSTNAME} eq 'laptop.ispsoft.de'  &&  $ENV{'LOGNAME'} eq 'joe') {
    $def = ' -Wall -Wno-comment -Wpointer-arith'
	. ' -Wcast-align -Wtraditional -Wcast-qual';
}

WriteMakefile(
    'NAME'	=> 'DBD::pNET',
    'VERSION_FROM' => 'pNET.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> $def,   # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> $inc,   # e.g., '-I/usr/include/other'
    'OPTIMIZE'  => $ENV{'OPTIMIZE'},
    'EXE_FILES' => [qw(pNETagent)],
    'OBJECT'    => '$(O_FILES)',
    'dist'      => { SUFFIX   => '.gz', DIST_DEFAULT => 'all tardist',
		     COMPRESS => 'gzip -9f' },
    'clean'     => { FILES    => "pNETagent *.xsi perl" }
);




sub MY::postamble {
    return dbd_postamble();
}
