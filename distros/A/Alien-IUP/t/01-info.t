#!perl

use Test::More tests => 2;
use Data::Dumper;

use_ok( 'Alien::IUP' );
use_ok( 'Alien::IUP::ConfigData' );

diag "This test shows misc debug info";

diag "Build details:";
diag ">> Platform    : $^O";
diag ">> IUP src     : " . Alien::IUP::ConfigData->config('iup_url') || 'n.a.';
diag ">> IM src      : " . Alien::IUP::ConfigData->config('im_url') || 'n.a.';
diag ">> CD src      : " . Alien::IUP::ConfigData->config('cd_url') || 'n.a.';
diag ">> IUP targets : ". join(' ', @{Alien::IUP::ConfigData->config('info_iuptargets')}) if Alien::IUP::ConfigData->config('info_iuptargets');
diag ">> IM targets  : ". join(' ', @{Alien::IUP::ConfigData->config('info_imtargets')})  if Alien::IUP::ConfigData->config('info_imtargets');
diag ">> CD targets  : ". join(' ', @{Alien::IUP::ConfigData->config('info_cdtargets')})  if Alien::IUP::ConfigData->config('info_cdtargets');
diag ">> MAKEOPTS    : ". join(' ', @{Alien::IUP::ConfigData->config('info_makeopts')})   if Alien::IUP::ConfigData->config('info_makeopts');
diag ">> GUI DRIVER  : ". Alien::IUP::ConfigData->config('info_gui_driver')               if Alien::IUP::ConfigData->config('info_gui_driver');

my $h = Alien::IUP::ConfigData->config('info_has');
my $l = Alien::IUP::ConfigData->config('info_lib_details');
diag "Detected libraries/headers:";
if ($h) {
  foreach (sort keys %$h) {
    my $detail = '';
    if (defined $l->{$_}) {
      $detail .= "; version=" . $l->{$_}->{version} if $l->{$_}->{version};
      $detail .= "; prefix="  . $l->{$_}->{prefix}  if $l->{$_}->{prefix};
    }
    diag ">> haslib=$h->{$_} : name=$_" . $detail;
  }
}
else {
  diag " N/A";
}

my $d = Alien::IUP::ConfigData->config('info_done');
diag "Build/make results per target:";
if ($d) {
  diag ">> makeresult=$d->{$_} : $_" foreach (sort keys %$d);
}
else {
  diag " N/A";
}
