
print STDERR "Using compatibility macros/routines for Perl 5.004\n"
    if ($] < 5.0045);



use ExtUtils::MakeMaker;


my $root = "../blib/arch/auto/libawperl";

use File::Path 'mkpath';
mkpath $root, 1, 0755 unless -d $root;

system "touch $root/libawperl.a";

use Cwd;
my $pwd = fastcwd;

$pwd =~ s/(\w+)$//;
$root =~ s/^\.\.//;
$root = $pwd.$root;


WriteMakefile(
	'NAME'		=> 'Aw',
	'VERSION_FROM'	=> '../lib/Aw.pm', # finds $VERSION
	'DEFINE'	=>
		( $] < 5.0045 ? '-DPERL5004_COMPAT -DAWXS_WARNS'
		: ( $] >= 5.008 ? '-DAWXS_WARNS -DPERL58_COMPAT' : '-DAWXS_WARNS') ),

	# 'PREREQ_PM' 	=> { 'CORBA::LongLong' => 0 },
	#
	# Uncomment for 3.0
	#
	# 'LIBS'	=> ['-L$root -lawperl -L/opt/active30/samples/adapter_devkit/c_lib -lcustcadk30 -L/opt/active30/lib -lawalog30 -lawl30 -lawc30 -lsocket -lnsl'],
	# 'INC'		=> '-I./../include -I/opt/active30/include -I/opt/active30/samples/adapter_devkit/c_lib',
	#
	# Uncomment for 4.0
	#
	'LIBS'	=> "-L$root -lawperl -L/opt/active40/samples/adapter_devkit/c_lib -lcustcadk31 -L/opt/active40/lib -lawcadk31 -lawalog40 -lawl40 -lawc40 -lsocket -lnsl",
	'INC'		=> '-I../include -I/opt/active40/include -I/opt/active40/samples/adapter_devkit/c_lib',
	'OBJECT'	=> '$(O_FILES)',
	'AUTHOR'	=> "Daniel Yacob <Yacob\@wMUsers.Com>",
	'ABSTRACT'	=> "Interface to the ActiveWorks Libraries.",
);


# unlink "$root/libawperl.a";
