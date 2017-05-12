#!/usr/bin/perl
# * Test assign_append, assign_addsection, save_file, reload.
# * Use array or hash references as the data parameters to _append
use strict;
use Test;

use lib '../lib';

BEGIN { plan tests => 8 }
use Asterisk::config;

my $file = "t/array_hash.conf";
open TRUNCATED_FILE, ">$file";
close TRUNCATED_FILE;

my $conf = new Asterisk::config(file => $file);

$conf->assign_addsection(section=>"test-array");
$conf->assign_append(section=>"test-array", point=>"foot",
        data=> [
                "a = b",
                "var = value",
        ]);
$conf->assign_addsection(section=>"test-hash");
$conf->assign_append(section=>"test-hash", point=>"foot",
        data=> {
                a => "b",
                var => "value",
        });

$conf->assign_append(point=>"up",
        data=> [
                "a = b",
                "var = value",
        ]);
$conf->assign_append(point=>"up",
        data=> {
                a1 => "b",
                var1 => "value",
        });



$conf->save_file();
$conf->reload();

ok(@{$conf->fetch_values_arrayref(section=>'test-array', key=>'a'  )}[0] eq 'b'    );
ok(@{$conf->fetch_values_arrayref(section=>'test-array', key=>'var')}[0] eq 'value');
ok(@{$conf->fetch_values_arrayref(section=>'test-hash',  key=>'a'  )}[0] eq 'b'    );
ok(@{$conf->fetch_values_arrayref(section=>'test-array', key=>'var')}[0] eq 'value');
ok(@{$conf->fetch_values_arrayref(section=>'[unsection]',key=>'a'   )}[0] eq 'b'    );
ok(@{$conf->fetch_values_arrayref(section=>'[unsection]',key=>'var' )}[0] eq 'value');
ok(@{$conf->fetch_values_arrayref(section=>'[unsection]',key=>'a1'  )}[0] eq 'b'    );
ok(@{$conf->fetch_values_arrayref(section=>'[unsection]',key=>'var1')}[0] eq 'value');
