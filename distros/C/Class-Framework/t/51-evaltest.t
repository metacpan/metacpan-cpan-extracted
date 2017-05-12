use warnings;
use strict;

use Test::More tests=>1;

my $demotest = `$^X t/evaltest.pl 2>/dev/null`;

my $HEX = qr/[0-9a-fA-F]/;

ok $demotest =~ m{\A
varthis:\sPTest2=ARRAY\(0x$HEX+\)\n
hatthis:\sPTest2=ARRAY\(0x$HEX+\)\n
varfields:\sa=>1\(2\),b=>2,cde=>3\n
hatfields:\sa=>1\(2\),b=>2,cde=>3\n
objfields:\sa=>1\(2\),b=>2,cde=>3\n
objaccess:\sa=>1\(2\),b=>2,cde=>3\n
hatargs:\sarg1=>5\n
hatfields:\sa=>1\(2\),b=>2,cde=>3,x=>4\n
objfields:\sa=>1\(2\),b=>2,cde=>3,x=>4\n
objaccess:\sa=>1\(2\),b=>2,cde=>3,x=>4\n
\n*\z}sx,"Demotest has correct output.";

# output on stderr (not yet checked!):
#Carping\.\.\.\sat\st/demotest\.pl\sline\s12\n
#Clucking\.\.\.\sat\s.*?PTest\.pm\sline\s22\n
#\s+PTest::mymeth\(\)\scalled\sat\s\(eval\s33\)\sline\s5\n
#\s+Class::MethodVars::__ANON__\('PTest2=ARRAY\(0x$HEX+\)',\s5\)\scalled\sat\s.*?PTest2\.pm\sline\s13\n
#\s+PTest2::meth2\(\)\scalled\sat\s\(eval\s37\)\sline\s5\n
#\s+Class::MethodVars::__ANON__\('PTest2=ARRAY\(0x$HEX\)',\s5\)\scalled\sat\st/demotest\.pl\sline\s12\n
