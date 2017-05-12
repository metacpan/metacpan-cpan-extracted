#!perl -w
use strict ;
use Test::More;

BEGIN{ chdir '..' }

eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
all_pod_coverage_ok(
{ trustme => [qr/^(OH_cleanup|OH_fixup|OH_init|OH_pre_process|cgi_new|get_page_name|header_props|send_header|setup|switch_to)$/] } 
);



