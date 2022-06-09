use v5.14;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use Data::Dumper;

use lib '.';
use t::Util;
$Script::lib    = File::Spec->rel2abs('lib');
$Script::script = File::Spec->rel2abs('script/week');

{
    local %ENV = %ENV;
    $ENV{LANG} = $ENV{LC_ALL} = 'C';

    for my $opt (
	'-Mnpb',
	'-Mnpb --lions',
	'-Mnpb --lions-rev',
	'-Molympic',
	'-Molympic --tokyo2020',
	'-Molympic --tokyo2020-rev',
	'-Molympic --para2020',
    ) {
	my @opt = split ' ', $opt;
	my $command = Script->new(\@opt)->run;
	print $command->result;
	is($command->status, 0, $opt);
    }
}

done_testing;
