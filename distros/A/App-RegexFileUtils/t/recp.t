use strict;
use warnings;
use Test::More tests => 11;
use File::Temp qw( tempdir );
use App::RegexFileUtils;
use File::Spec;

my $dir = tempdir( CLEANUP => 1);
chdir($dir) || die;

ok -d $dir, "dir = $dir";
mkdir 'perl';
mkdir 'perl/lib';

my @orig = qw( README foo.txt foo.pl Foo.pm );
for (@orig)
{ open my $fh, '>', $_; close $fh }

ok -e $_, "orig $_" for @orig;

App::RegexFileUtils->main('cp', '/\\.p[lm]$/', 'perl/lib');

ok -e $_, "orig $_" for @orig;
ok -e "perl/lib/foo.pl", "perl/lib/foo.pl";
ok -e "perl/lib/Foo.pm", "perl/lib/Foo.pm";

chdir(File::Spec->updir) || die;