use Test::More tests => 7;
use Alien::WiX ':ALL';

ok(wix_version() ne '', 'wix_version');
ok(wix_version_number() ne 0, 'wix_version_number');
ok(defined(wix_binary('candle')), 'wix_binary');
ok(defined(wix_library('WixFirewall')), 'wix_library'); 
ok(defined(wix_bin_candle()), 'wix_bin_candle');
ok(defined(wix_bin_light()), 'wix_bin_light');
ok(defined(wix_lib_wixui()), 'wix_lib_wixui');