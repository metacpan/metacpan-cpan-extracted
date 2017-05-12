#!perl -T

use strict;
use warnings;
use Test::More tests => 2*13 + 1;
use FindBin '$Bin';
($Bin) = $Bin =~ /(.+)/;

our $Perl;
our $Dir;

require "$Bin/testlib.pl";
prepare_for_testing();

test_perlmv([1, 2, 3], {code=>'$_*4'}, [12, 4, 8], 'normal');
test_perlmv([1, 2, 3], {code=>'$_*4', dry_run=>1, verbose=>1}, [1, 2, 3], 'dry_run');
test_perlmv([1, 2, 3], {code=>'$_*4', compile=>1}, [1, 2, 3], 'compile');
test_perlmv([1, 2, 3], {code=>'"a"'}, ["a", "a.1", "a.2"], 'automatic .\d+ suffix on conflict');
test_perlmv([1, 2, 3], {code=>'"b"', overwrite=>1}, ["b"], 'overwrite');
test_perlmv(["a"], {code=>'"b/c/d"'}, ["a"], 'parents off');
test_perlmv(["a"], {code=>'"b/c/d"', parents=>1}, ["b"], 'parents on');
test_perlmv([1, 2, 3], {code=>'$_++'}, ["2.1", "3.1", "4"], 'reverse off');
test_perlmv([1, 2, 3], {code=>'$_++', reverse_order=>1}, ["2", "3", "4"], 'reverse on');

test_perlmv([qw/aab abb acb/], {codes=>[\'remove-common-prefix', \'remove-common-suffix']}, [qw/a b c/], 'multi (scriptlet+scriptlet)');
test_perlmv([qw/aab abb acb/], {codes=>[\'remove-common-prefix', '"file$_"', \'remove-common-suffix']}, [qw/filea fileb filec/], 'multi (scriptlet+eval+scriptlet)');

# [2, 3, 1] -> [3.1, 4, 2], but sorted by test_perlmv
test_perlmv([2, 3, 1], {code=>'$_+1'}, [2.1, 3.1, 4], 'no-sort off');
test_perlmv([2, 3, 1], {code=>'$_+1', no_sort=>1}, [2, 3.1, 4], 'no-sort on');

subtest "symlink to non-existing path" => sub {
    plan skip_all => "symlink() not available" unless eval { symlink "",""; 1 };

    test_perlmv([
        {name=>"x1", link_target=>"nonexisting"},
        {name=>"x2", link_target=>"nonexisting/2"},
    ], {code=>'s/x/y/'}, ['y1', 'y2'], 'normal');
};

DONE_TESTING:
end_testing();
