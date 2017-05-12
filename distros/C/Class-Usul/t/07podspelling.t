use strict;
use warnings;
use File::Spec::Functions qw( catdir catfile updir );
use FindBin               qw( $Bin );
use lib               catdir( $Bin, updir, 'lib' );

use Test::More;

BEGIN {
   $ENV{AUTHOR_TESTING}
      or plan skip_all => 'POD spelling test only for developers';
}

use English qw( -no_match_vars );

eval "use Test::Spelling";

$EVAL_ERROR and plan skip_all => 'Test::Spelling required but not installed';

$ENV{TEST_SPELLING}
   or plan skip_all => 'Environment variable TEST_SPELLING not set';

my $checker = has_working_spellchecker(); # Aspell is prefered

if ($checker) { warn "Check using ${checker}\n" }
else { plan skip_all => 'No OS spell checkers found' }

add_stopwords( <DATA> );

all_pod_files_spelling_ok();

done_testing();

# Local Variables:
# mode: perl
# tab-width: 3
# End:

__DATA__
flanigan
anykey
api
appdir
appldir
argv
arrayref
async
backend
basename
brk
bson
bsonid
buildargs
canonicalise
canonicalised
changelog
classdir
classfile
classname
cli
coderef
combinator
config
cpan
daemonised
datetime
DBIC
DDL
dbattrs
debian
decrypt
decrypts
decrypted
Diffie
distmeta
distname
DSN
dsn
extns
fh
fqdn
fullname
gecos
gettext
getopts
hashref
Hellman
hostname
ids
io
installdeps
isa
json
lbrace
loc
localiser
localize
localizer
login
loginid
logname
lookup
merchantability
MSWin
multi
namespace
nul
pathname
perlbrew
plugins
popen
posix
PostgreSQL
prepends
RDBMSs
RDBMs
refactored
runtime
schemas
sep
sig
spc
stacktrace
stderr
stdin
stdout
str
stringifies
suid
svn
symlink
tempdir
tempname
Twofish
twofish
undef
unescape
uninstall
uninstalls
untaint
untaints
uri
uuid
vcs
yaml
yorn
