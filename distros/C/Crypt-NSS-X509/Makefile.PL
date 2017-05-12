use inc::Module::Install;
use Alien::NSS;

# my @searchpaths = (
# 	'/opt/local',
# 	'/usr/local',
# 	'/usr',
# 	'/opt',
#
# 	# the advantages of being the module author...
# 	'/home/johanna/nss',
# );
#
# my @inc_paths;
# my @lib_paths;
#
# for my $path ( @searchpaths ) {
# 	push ( @inc_paths, "$path/include");
# 	push ( @inc_paths, "$path/include/nspr");
# 	push ( @inc_paths, "$path/include/nss");
#
# 	push ( @lib_paths, "$path/lib" );
# 	push ( @lib_paths, "$path/lib/nspr" );
# 	push ( @lib_paths, "$path/lib/nss" );
# }
#
# unless ( search_header(@inc_paths) && search_lib(@lib_paths) ) {
# 	# Trying
# }
#
# my @l_lib_paths = map { "-L$_" } @lib_paths;

name('Crypt-NSS-X509');
license('mozilla');
perl_version('5.10.1');
all_from('X509.pm');

requires 'autodie' => 2.10;
requires 'MIME::Base64' => 3.13;
requires 'Exporter' => 5.60;
requires 'Encode' => 2.40;
requires 'Alien::NSS' => 0.05;
test_requires 'Test::More' => 0.98;
configure_requires 'Alien::NSS' => 0.05;

homepage 'https://github.com/0xxon/perl-nss';
bugtracker 'https://github.com/0xxon/perl-nss/issues';
repository 'git://github.com/0xxon/perl-nss.git';

my $cflags= Alien::NSS->cflags;
my $ldflags = Alien::NSS->libs;

requires_external_cc();

inc $cflags;
libs $ldflags;

cc_optimize_flags('-O2 -g -Wall -std=c99');

auto_install();
sign;
WriteAll();

# sub search_header {
# 	# let's see if we find one of nss's header files.
# 	for my $path (@_) {
# 		return 1 if ( -f "$path/certt.h" );
# 	}
#
# 	print "Could not find certt.h in include dirs.";
# 	return 0;
# }
#
# sub search_lib {
# 	# and check for the library. a bit more complicated,
# 	# but well
#
# 	for my $path (@_) {
# 		my @nsslibs = <$path/libnss*>;
#
# 		return 1 if ( scalar @nsslibs > 0 );
# 	}
#
# 	print "Could not find libnss* in lib dirs.";
# 	return 0;
# }
