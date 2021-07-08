use v5.24;
use experimental 'signatures';
use Test::More;
use Test::Exception;
use File::Basename 'dirname';
use lib dirname(__FILE__);
use Helpers 'tpath';

use App::Easer;
my $loader = \&App::Easer::load_application;

my $target = {what => 'ever'};

is_deeply $loader->({what => 'ever'}), $target, 'hash';

is_deeply $loader->(\'my $x = {what => "ever"}'), $target, 'Perl code';
is_deeply $loader->(\'{"what": "ever"}'),         $target, 'JSON string';

is_deeply $loader->(tpath('example.pl')),   $target, 'Perl file';
is_deeply $loader->(tpath('example.json')), $target, 'JSON file';

is_deeply $loader->(\*DATA), $target, 'filehandle';

done_testing();

__DATA__
my $x = {lc('WHAT') => join('', qw< e v e r >), a => 0};
delete $x->{a};
$x;
