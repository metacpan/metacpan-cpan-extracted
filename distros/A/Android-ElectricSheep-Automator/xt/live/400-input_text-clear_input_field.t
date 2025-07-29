#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

use strict;
use warnings;

#use utf8;

our $VERSION = '0.05';

use Test::More;
use Test::More::UTF8;
use FindBin;
use Test::TempDir::Tiny;
use Mojo::Log;

use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

use lib ($FindBin::Bin, 'blib/lib');

use Android::ElectricSheep::Automator;
use Android::ElectricSheep::Automator::AppProperties;

my $VERBOSITY = 0; # we need verbosity of 10 (max), so this is not used

my $curdir = $FindBin::Bin;

# if for debug you change this make sure that it has path in it e.g. ./xyz
#my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
#ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;

my $configfile = File::Spec->catfile($curdir, '..', '..', 't', 't-config', 'myapp.conf');
ok(-f $configfile, "config file exists ($configfile).") or BAIL_OUT;

my $mother = Android::ElectricSheep::Automator->new({
	'configfile' => $configfile,
	#'verbosity' => $VERBOSITY,
	# we have a device connected and ready to control
	'device-is-connected' => 1,
});
ok(defined($mother), 'Android::ElectricSheep::Automator->new()'." : called and got defined result.") or BAIL_OUT;

my $package = 'com.google.android.deskclock';
# open an app
my $res = $mother->open_app({
	'package' => $package
});
ok(defined($res), 'Android::ElectricSheep::Automator->open_app()'." : called and got good result.") or BAIL_OUT;
is(ref($res), 'HASH', 'Android::ElectricSheep::Automator->open_app()'." : called and got good result which is a HASHref.") or BAIL_OUT("no it is '".ref($res)."'");
for my $k (keys %$res){
	is(ref($res->{$k}), 'Android::ElectricSheep::Automator::AppProperties', 'Android::ElectricSheep::Automator->open_app()'." : called and got good result which is of type 'Android::ElectricSheep::Automator::AppProperties'.") or BAIL_OUT("no it is '".ref($res->{$k})."'");
}

sleep(1);

# dump the ui
my $ui = $mother->dump_current_screen_ui();
ok(defined($ui), 'dump_current_screen_ui()'." : got UI dump of the running app's screen.") or BAIL_OUT;
my $dom = $ui->{'XML::LibXML'};
my $xc = $ui->{'XML::LibXML::XPathContext'};
my $asel =
	'//node[@resource-id="com.google.android.deskclock:id/fab"'
	.' and matches(@class, \'Button\',"i")'
	.' and matches(@content-desc, \'city\',"i")'
	.']'
;
my @nodes = $xc->findnodes($asel);
#for my $anode (@nodes){ print $anode; } die 123;
my $N = scalar @nodes;
is($N, 1, "app clock : found + button from UI of the app with this selector: ${asel}") or BAIL_OUT(${ui}->{'raw'}."\nno it failed with above XML dump");
my $addbutton = $nodes[0];

# click the add-button found
my $boundstr = $addbutton->getAttribute('bounds');
ok(defined($boundstr), "bounds of the widget found: ${boundstr}") or BAIL_OUT;
ok($boundstr =~ /\[\s*(\d+)\s*,\s*(\d+)\]\s*\[\s*(\d+)\s*,\s*(\d+)\]/, "bounds of the widget parsed: ${boundstr}") or BAIL_OUT;
my $bounds = [[$1,$2],[$3,$4]];
is($mother->tap({'bounds'=>$bounds}), 0, 'add (+) button of the app has been clicked.') or BAIL_OUT(perl2dump($bounds)."no, failed to tap the add button with above bounds");

sleep(1);

# and now we have a text-edit widget

# dump the ui
$ui = $mother->dump_current_screen_ui();
ok(defined($ui), 'dump_current_screen_ui()'." : got UI dump of the running app's screen.") or BAIL_OUT;
$dom = $ui->{'XML::LibXML'};
$xc = $ui->{'XML::LibXML::XPathContext'};
$asel =
	'//node[@resource-id="com.google.android.deskclock:id/open_search_view_edit_text"'
	.' and matches(@class, \'Edit\',"i")'
	.' and matches(@text, \'city\',"i")'
	.']'
;
@nodes = $xc->findnodes($asel);
#for my $anode (@nodes){ print $anode; } die 123;
$N = scalar @nodes;
is($N, 1, "app clock : found text-edit widget from UI of the app with this selector: ${asel}") or BAIL_OUT(${ui}->{'raw'}."\nno it failed with above XML dump");
my $texteditbox = $nodes[0];

# click the add-button found
$boundstr = $texteditbox->getAttribute('bounds');
ok(defined($boundstr), "bounds of the widget found: ${boundstr}") or BAIL_OUT;
ok($boundstr =~ /\[\s*(\d+)\s*,\s*(\d+)\]\s*\[\s*(\d+)\s*,\s*(\d+)\]/, "bounds of the widget parsed: ${boundstr}") or BAIL_OUT;
$bounds = [ [$1,$2], [$3,$4] ];
my $text = 'hello%sworld';
is($mother->input_text({'bounds'=>$bounds, 'text'=>$text}), 0, "text ($text) has been entered in the text-edit widget.") or BAIL_OUT(perl2dump($bounds)."no, failed to input text ($text) in the text-edit widget with above bounds");

# now clear the text
is($mother->clear_input_field({
	'bounds'=>$bounds,
	'num-characters' => 15
}), 0, 'clear_input_field()'." : the text entered in the text field earlier must now be cleared.") or BAIL_OUT;

# close apps
$res = $mother->close_app({
	'package' => $package
});
ok(defined($res), 'Android::ElectricSheep::Automator->close_app()'." : called and got good result.") or BAIL_OUT;
is(ref($res), 'HASH', 'Android::ElectricSheep::Automator->close_app()'." : called and got good result which is a HASHref.") or BAIL_OUT("no it is '".ref($res)."'");
for my $k (keys %$res){
	is(ref($res->{$k}), 'Android::ElectricSheep::Automator::AppProperties', 'Android::ElectricSheep::Automator->close_app()'." : called and got good result which is of type 'Android::ElectricSheep::Automator::AppProperties'.") or BAIL_OUT("no it is '".ref($res->{$k})."'");
}

#diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;
# END
done_testing();
 
sleep(1);

