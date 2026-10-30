use FindBin;

use lib $FindBin::Bin.'/../thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../lib';
use lib $FindBin::Bin.'/lib';

use Mojo::Base -strict;

use Test::More;
use CallBackery::GuiPlugin::Abstract;

my $yesNo = CallBackery::GuiPlugin::Abstract->createRxValidator('yes|no','bad');
my $number = CallBackery::GuiPlugin::Abstract->createRxValidator('\d+','bad');

is $yesNo->('no'), undef, 'a listed value is accepted';
is $yesNo->('yes; extra'), 'bad', 'an alternation is anchored at both ends';
is $number->("42\n"), 'bad', 'a trailing newline is refused';

done_testing();
