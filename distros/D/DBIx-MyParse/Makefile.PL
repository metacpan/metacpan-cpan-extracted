use ExtUtils::MakeMaker;

use strict;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $default_mysql_path ='/usr/src/mysql-5.0.45';

print "Please provide the path to your MySQL source tree [$default_mysql_path]: ";
my $mysql_path = <STDIN>;
$mysql_path =~ s{[\r\n]}{};

$mysql_path = $default_mysql_path if ($mysql_path eq '');

$mysql_path = $mysql_path.'/';
my $check_file = $mysql_path."libmysqld/libmysqld.a";
if (! -e $check_file) {
	print "File $check_file does not exist: $!. Please try again.\n";
	exit;
}

my $makefile_path = $mysql_path.'/libmysql/Makefile';

my $libmysqld_path = $mysql_path.'/libmysqld/libmysqld.a';

if (! -e $libmysqld_path) {
	print "$libmysqld_path does not exist. Did you run ./configure --with-embedded-server && make ? \n";
	exit;
}

#
# CCFLAGS must be taken from the flags used to compile libmysqld. The reason for that is that if the flags are not
# identical, the THD class behaves differently in libmysqld than it does in my_parse_cc.cc, namely, the thd->command
# member is located in a different place in memory. No attempt was made to determine which compile flag causes this behavoir.
#
# Also, if we compile our stuff with DDEBUG and libmysqld.so is not compiled with DDEBUG, crap will result.


my $ccflags = `grep "^CXXFLAGS =" $makefile_path`;

$ccflags =~ s{^CXXFLAGS = }{}sio;
$ccflags =~ s{[\r\n\t]}{}sio;
$ccflags .= " -DNO_EMBEDDED_ACCESS_CHECKS ";
print "CCFLAGS = $ccflags\n";


my $libs = '-L'.$mysql_path.'/libmysql -L'.$mysql_path.'/libmysqld -lmysqld -lz -lpthread -lcrypt -lnsl -lm -lpthread -lc -lnss_files -lnss_dns -lresolv -lc -lnss_files -lnss_dns -lresolv -lrt';

print "LIBS = $libs\n";

WriteMakefile(
	NAME		=> 'DBIx::MyParse',
	VERSION_FROM	=> 'lib/DBIx/MyParse.pm', # finds $VERSION
	ABSTRACT_FROM	=> 'lib/DBIx/MyParse.pm',
	AUTHOR		=> 'Philip Stoev <philip@stoev.org>',
	LIBS            => qq{-L$mysql_path/libmysqld -L$mysql_path/libmysql -lmysqld -lz }.$libs,
	'INC'		=> qq{-I. -I$mysql_path -I$mysql_path/sql -I$mysql_path/include -I$mysql_path/regex},

	CCFLAGS		=> '-DEMBEDDED_LIBRARY -DMYSQL_SERVER -Wall '.$ccflags,
	OBJECT		=> 'my_enum.o my_define.o my_parse_c.o my_parse_cc.o MyParse.o',
	LD		=> 'g++',
	CC		=> 'g++',
    depend => {
	'my_parse_cc.cc' => 'my_parse.h',
	'my_parse_cc.cc' => 'my_define.h',
	'my_parse_cc.cc' => 'my_enum.h',
	'my_enum.o' => 'my_enum.c',
	'my_enum.o' => 'my_enum.h',
	'my_enum.0' => ' my_parse.h',
	'my_define.o' => 'my_define.h',
	'my_define.o' => 'my_define.c',
	'my_define.o' => 'my_parse.h',

	'my_enum.h' => "parse_enum.pl
	perl parse_enum.pl $mysql_path
",
	'my_enum_priv.h' => "parse_enum.pl
	perl parse_enum.pl $mysql_path
",
	'my_define.h' => "parse_define.pl
	perl parse_define.pl $mysql_path
",
	'my_define.c' => "parse_define.pl
	perl parse_define.pl $mysql_path
",
	'my_enum.c' => "parse_define.pl
	perl parse_enum.pl $mysql_path
"},
	clean => 
	  {FILES => "my_enum_priv.h my_enum.h my_define.h my_define.c my_enum.c"}

);
