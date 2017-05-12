#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exports;

require_ok "Config::TinyDNS";

my @exp = qw/
    split_tdns_data join_tdns_data
    register_tdns_filters filter_tdns_data
/;
my @nexp = qw/
    _decode_filt _lookup_filt
/;

import_ok   "Config::TinyDNS";
cant_ok     @exp, @nexp, "import nothing";

for (@exp) {
    new_import_pkg;
    import_ok   "Config::TinyDNS", [$_];
    is_import   $_, "Config::TinyDNS", "import $_";
}

for (@nexp) {
    new_import_pkg;
    import_nok  "Config::TinyDNS", [$_];
}

new_import_pkg;
import_ok   "Config::TinyDNS", [":ALL"];
is_import   @exp, "Config::TinyDNS", "import :ALL";
cant_ok     @nexp, "...but don't import everything";

done_testing;
