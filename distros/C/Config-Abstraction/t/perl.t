use strict;
use warnings;

use Test::Most;
use File::Spec;
use File::Slurp qw(write_file);

use Test::Needs 'Config::Abstract';
use Test::TempDir::Tiny;

BEGIN { use_ok('Config::Abstraction') }

my $test_dir = tempdir();

write_file(File::Spec->catdir($test_dir, 'test.pl'), <<'PERL');
$settings = {
   'book' => {
     'chapter1' => {
       'title' => 'The First Chapter, ever',
       'file' => 'book/chapter1.txt'
     },
     'title' => 'A book of chapters',
     'chapter2' => {
       'title' => 'The Next Chapter, after the First Chapter, ever',
       'file' => 'book/chapter2.txt'
     },
     'author' => 'Me, Myself and Irene'
   }
 };
PERL

my $config = Config::Abstraction->new(
	config_dirs => [$test_dir],
	config_file => 'test.pl'
);

ok(defined($config));
diag(Data::Dumper->new([$config->all()])->Dump()) if($ENV{'TEST_VERBOSE'});
$config = $config->all();
delete($config->{'config_path'});
cmp_deeply($config, {
	'book' => {
		'chapter1' => {
			'title' => 'The First Chapter, ever',
			'file' => 'book/chapter1.txt'
		}, 'title' => 'A book of chapters',
		'chapter2' => {
			'title' => 'The Next Chapter, after the First Chapter, ever',
			'file' => 'book/chapter2.txt'
		}, 'author' => 'Me, Myself and Irene'
	}
}, 'Loads configuration from a Perl file');

done_testing();
