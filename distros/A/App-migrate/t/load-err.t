use strict;
use POSIX qw(locale_h); BEGIN { setlocale(LC_MESSAGES,'en_US.UTF-8') } # avoid UTF-8 in $!
use Test::More;
use Test::Exception;
use Path::Tiny qw( path tempdir tempfile );
use App::migrate;


my $migrate = App::migrate->new;
my $file    = tempfile('migrate.XXXXXX');

my $proj    = tempdir('migrate.project.XXXXXX');
my $guard   = bless {};
sub DESTROY { chdir q{/} }
chdir $proj or die "chdir($proj): $!";

throws_ok { $migrate->load('/dev/null') } qr/plain file/msi;
throws_ok { $migrate->load('/dev')      } qr/plain file/msi;

$file->remove;
throws_ok { $migrate->load($file) } qr/^open\b/msi;

$file->touch;
lives_ok  { $migrate->load($file) } 'empty file';

$file->spew_utf8(<<"MIGRATE");

# previous line is empty, next contain space symbols
  \t
MIGRATE
lives_ok  { $migrate->load($file) } 'empty lines and comments';

$file->spew_utf8(<<'MIGRATE');
 
MIGRATE
throws_ok { $migrate->load($file) } qr/bad token/msi, 'line with one space';

$file->spew_utf8(<<'MIGRATE');
 # comment
MIGRATE
throws_ok { $migrate->load($file) } qr/bad token/msi, 'line begins with one space';

$file->spew_utf8(<<"MIGRATE");
\t# comment
MIGRATE
throws_ok { $migrate->load($file) } qr/bad token/msi, 'line begins with tab';

$file->spew_utf8(<<'MIGRATE');
  true
MIGRATE
throws_ok { $migrate->load($file) } qr/data before operation/msi;

$file->spew_utf8(<<'MIGRATE');
VERSION "
MIGRATE
throws_ok { $migrate->load($file) } qr/bad operation param/msi;

$file->spew_utf8(<<'MIGRATE');
VERSION "1\.0"
MIGRATE
throws_ok { $migrate->load($file) } qr/bad operation param/msi;

$file->spew_utf8(<<'MIGRATE');
VERSION "1.0\"
MIGRATE
throws_ok { $migrate->load($file) } qr/bad operation param/msi;

$file->spew_utf8(<<'MIGRATE');
VERSION 1\.0
MIGRATE
throws_ok { $migrate->load($file) } qr/bad operation param/msi;

$file->spew_utf8(<<'MIGRATE');
VERSION     "1.0"
upgrade     echo " " "\"\\\t\r\n"
downgrade   echo
MIGRATE
lives_ok  { $migrate->load($file) } 'supported escapes';

$file->spew_utf8(<<'MIGRATE');
bad_op
MIGRATE
throws_ok { $migrate->load($file) } qr/unknown operation/msi;

$file->spew_utf8(<<'MIGRATE');
DEFINE alias
upgrade
alias
MIGRATE
throws_ok { $migrate->load($file) } qr/'alias' require command or data/msi;

$file->spew_utf8(<<'MIGRATE');
before_upgrade
MIGRATE
throws_ok { $migrate->load($file) } qr/'before_upgrade' require command or data/msi;

$file->spew_utf8(<<'MIGRATE');
upgrade
MIGRATE
throws_ok { $migrate->load($file) } qr/'upgrade' require command or data/msi;

$file->spew_utf8(<<'MIGRATE');
downgrade
MIGRATE
throws_ok { $migrate->load($file) } qr/'downgrade' require command or data/msi;

$file->spew_utf8(<<'MIGRATE');
after_downgrade
MIGRATE
throws_ok { $migrate->load($file) } qr/'after_downgrade' require command or data/msi;

$file->spew_utf8(<<'MIGRATE');
VERSION 1
upgrade true
RESTORE param
MIGRATE
throws_ok { $migrate->load($file) } qr/'RESTORE' must have no params/msi;

$file->spew_utf8(<<'MIGRATE');
VERSION 1
upgrade
  true
RESTORE
  param
MIGRATE
throws_ok { $migrate->load($file) } qr/no data allowed for 'RESTORE'/msi;

$file->spew_utf8(<<'MIGRATE');
VERSION
MIGRATE
throws_ok { $migrate->load($file) } qr/'VERSION' must have one param/msi;

$file->spew_utf8(<<'MIGRATE');
VERSION 1 2
MIGRATE
throws_ok { $migrate->load($file) } qr/'VERSION' must have one param/msi;

for my $c (q{ }, "\t", "\r", qw( \\\\ / ? * ` \" ' )) {
    $file->spew_utf8(<<"MIGRATE");
VERSION "1${c}2"
MIGRATE
    throws_ok { $migrate->load($file) } qr/bad value for 'VERSION'/msi;
}

$file->spew_utf8(<<'MIGRATE');
VERSION 1
  2
MIGRATE
throws_ok { $migrate->load($file) } qr/no data allowed for 'VERSION'/msi;


for my $define (qw( DEFINE DEFINE2 DEFINE4 )) {
    $file->spew_utf8(<<"MIGRATE");
$define one two
MIGRATE
    throws_ok { $migrate->load($file) } qr/'\Q$define\E' must have one param/msi;
    $file->spew_utf8(<<"MIGRATE");
$define "bug/macro name"
MIGRATE
    throws_ok { $migrate->load($file) } qr/bad name for '\Q$define\E'/msi;
    $file->spew_utf8(<<"MIGRATE");
$define one
  two
MIGRATE
    throws_ok { $migrate->load($file) } qr/no data allowed for '\Q$define\E'/msi;
    $file->spew_utf8(<<"MIGRATE");
$define upgrade
MIGRATE
    throws_ok { $migrate->load($file) } qr/can't redefine keyword/msi;
    $file->spew_utf8(<<"MIGRATE");
DEFINE2 only_upgrade
upgrade
downgrade true
$define only_upgrade
MIGRATE
    throws_ok { $migrate->load($file) } qr/already defined/msi;
}

$file->spew_utf8(<<'MIGRATE');
DEFINE name
MIGRATE
throws_ok { $migrate->load($file) } qr/need operation after 'DEFINE'/msi;

$file->spew_utf8(<<'MIGRATE');
DEFINE name
RESTORE
MIGRATE
throws_ok { $migrate->load($file) } qr/first operation after 'DEFINE' must be/msi;

$file->spew_utf8(<<'MIGRATE');
DEFINE2 name
MIGRATE
throws_ok { $migrate->load($file) } qr/need two operations after 'DEFINE2'/msi;

$file->spew_utf8(<<'MIGRATE');
DEFINE2 name
RESTORE
RESTORE
MIGRATE
throws_ok { $migrate->load($file) } qr/first operation after 'DEFINE2' must be/msi;

$file->spew_utf8(<<'MIGRATE');
DEFINE2 name
upgrade
RESTORE
MIGRATE
throws_ok { $migrate->load($file) } qr/second operation after 'DEFINE2' must be/msi;

$file->spew_utf8(<<'MIGRATE');
DEFINE4 name
MIGRATE
throws_ok { $migrate->load($file) } qr/need four operations after 'DEFINE4'/msi;

$file->spew_utf8(<<'MIGRATE');
DEFINE4 name
RESTORE
RESTORE
RESTORE
RESTORE
MIGRATE
throws_ok { $migrate->load($file) } qr/first operation after 'DEFINE4' must be/msi;

$file->spew_utf8(<<'MIGRATE');
DEFINE4 name
before_upgrade
RESTORE
RESTORE
RESTORE
MIGRATE
throws_ok { $migrate->load($file) } qr/second operation after 'DEFINE4' must be/msi;

$file->spew_utf8(<<'MIGRATE');
DEFINE4 name
before_upgrade
upgrade
RESTORE
RESTORE
MIGRATE
throws_ok { $migrate->load($file) } qr/third operation after 'DEFINE4' must be/msi;

$file->spew_utf8(<<'MIGRATE');
DEFINE4 name
before_upgrade
upgrade
downgrade
RESTORE
MIGRATE
throws_ok { $migrate->load($file) } qr/fourth operation after 'DEFINE4' must be/msi;

$file->spew_utf8(<<'MIGRATE');
VERSION 1
downgrade true
MIGRATE
throws_ok { $migrate->load($file) } qr/need .* before 'downgrade'/msi;

$file->spew_utf8(<<'MIGRATE');
VERSION 1
upgrade true
MIGRATE
throws_ok { $migrate->load($file) } qr/need .* after 'upgrade'/msi;

$file->spew_utf8(<<'MIGRATE');
VERSION 1
before_upgrade true
upgrade true
MIGRATE
throws_ok { $migrate->load($file) } qr/need .* after 'before_upgrade'/msi;

$file->spew_utf8(<<'MIGRATE');
upgrade true
MIGRATE
throws_ok { $migrate->load($file) } qr/need 'VERSION' before/msi;


### old bugs

$file->spew_utf8(<<'MIGRATE');
DEFINE4 bug/define4_order
before_upgrade
upgrade
downgrade
after_downgrade
VERSION 0
bug/define4_order true
VERSION 1
MIGRATE
lives_ok  { $migrate->load($file) } 'bug: DEFINE4 order';

$file->spew_utf8(<<'MIGRATE');
DEFINE #bug/macro_name
upgrade
VERSION 0
#bug/macro_name
VERSION 1
MIGRATE
throws_ok { $migrate->load($file) } qr/bad name for 'DEFINE'/msi, 'bug: macro name start with #';

$file->spew_utf8(<<'MIGRATE');
DEFINE "#bug/macro_name"
upgrade
VERSION 0
#bug/macro_name
VERSION 1
MIGRATE
throws_ok { $migrate->load($file) } qr/bad name for 'DEFINE'/msi, 'bug: macro name start with #';


done_testing;
