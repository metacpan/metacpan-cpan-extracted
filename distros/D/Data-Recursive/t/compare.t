use 5.012;
use warnings;
use blib;
use Data::Recursive 'compare';
use Test::More;

# check hashes and arrays

subtest 'basic' => sub {
    my $h1d = {a => 1, b => 2, c => 3, d => 4};
    my $h1s = {c => 'c', d => 'd', e => 'e', f => 'f'};
    ok !compare($h1d,$h1s);
    ok compare($h1d,$h1d);
};

subtest 'more' => sub {
    my $s1  = '{"max_qid"=>11,"clover"=>{"fillup_multiplier"=>"1.3","finish_date"=>12345676}}';
    my $s2  = '{"clover"=>{"finish_date"=>12345676,"fillup_multiplier"=>"1.3"},"max_qid"=>11}';
    my $s3  = '{"clover"=>{"finish_date"=>12345676,"fillup_multiplier"=>1.3},"max_qid"=>11}';
    my $s4  = '{"max_qid"=>11}';
    my $s5  = '{"max_qid"=>11,"no_arrays_yet"=>[1,2,3]}';
    my $s6  = '{"max_qid"=>11,"no_arrays_yet"=>[1,2,3]}';
    my $s7  = '{"max_qid"=>11,"no_arrays_yet"=>[1,undef,3]}';
    my $s8  = '{"max_qid"=>11,"no_arrays_yet"=>[1,{"fuck"=>"dick"},3]}';
    my $s9  = '{"max_qid"=>11,"no_arrays_yet"=>[1,{"fuck"=>"dick"},3]}';
    my $s10 = '{"hours"=>[15],"templ"=>{"marker"=>"nf1","subjects"=>"{\\"l10n\\"=>\\"test [% l10n.col.auto.5 %]\\"}","bodies"=>"{\\"l10n\\"=>\\"test\\"}","title"=>"Templ Name","l10n"=>1},"mode"=>0,"active"=>1,"type"=>9,"condition"=>"{\\"lastvisit\\"=>[0,1],\\"level\\"=>[2,50],\\"custom\\"=>\\"game.recipient.return_bonus_date != undef\\",\\"regago\\"=>[2,4]}"}';
    my $s11 = '{"hours"=>[15],"templ"=>{"marker"=>"nf1","subjects"=>"{\\"l10n\\"=>\\"test [% l10n.col.auto.5 %]\\"}","bodies"=>"{\\"l10n\\"=>\\"test2\\"}","title"=>"Templ Name","l10n"=>1},"mode"=>0,"active"=>1,"type"=>9,"condition"=>"{\\"lastvisit\\"=>[0,1],\\"level\\"=>[2,50],\\"custom\\"=>\\"game.recipient.return_bonus_date != undef\\",\\"regago\\"=>[2,4]}"}';

    ok compare(eval($s1), eval($s2));
    ok compare(eval($s1), eval($s3)), "type float against type string";
    
    ok !compare("FUCK",{}), "primitive VS ref";
    
    ok compare({},{});
    ok !compare(eval($s1), eval($s4));
    ok !compare(eval($s1), eval($s5));
    ok compare(eval($s5), eval($s6));
    ok !compare(eval($s6), eval($s7));
    ok compare(eval($s8), eval($s9));
    ok compare({a => \'a1'}, {a=>\'a1'});
    ok compare({a => \1}, {a=>\1});
    ok compare({a => \1.1}, {a=>\1.1});
    ok !compare(eval($s10), eval($s11));
};

subtest 'arrayrefs' => sub {
    my $arr1 = [1,2,3];
    my $arr2 = [1,2,3];
    my $arr3 = [1,2,4];
    my $arr4 = ["1", 2, 3.0];
    ok compare($arr1, $arr2);
    ok compare($arr1, $arr4);
    ok !compare($arr1, $arr3);
};

subtest 'empty slots' => sub {
    my $arr5 = [1..10];
    my $arr6 = [1..10];
    $#$arr5 = 1000;
    $#$arr6 = 1000;
    $arr5->[500] = 1;
    ok !compare($arr5, $arr6), "must not core dump";
};

subtest 'primitives' => sub {
    ok compare(1, 1);
    ok compare(1, "1");
    ok !compare(1, "1.0");
    ok !compare(1, "1a");
    ok compare(1.1, "1.1");
    ok compare(1.1 - 0.1, 1);
};

subtest 'coderefs' => sub {
    my $sub = sub {};
    my $sub2 = $sub;
    ok !compare($sub, sub {});
    ok compare($sub, $sub2);
};

subtest 'globs' => sub {
    ok compare(*compare, *compare);
    ok compare(\*compare, \*compare);
    ok !compare(*compare, *is);
};

subtest 'regexps' => sub {
    ok compare(qr/abc/, qr/abc/);
    ok !compare(qr/abc/, qr/abc1/);
    ok !compare(qr/abc/, qr/abc/i);
};

subtest 'IO' => sub {
    my $io1 = *STDIN{IO};
    my $io2 = *STDIN{IO};
    my $io3 = *STDOUT{IO};
    ok compare($io1, $io2);
    ok !compare($io1, $io3);
};

subtest 'undefs' => sub {
    ok compare(undef, undef);
    ok compare(my $f = undef, my $s = undef);
    ok !compare(undef, 0);
    ok !compare(undef, "");
    ok !compare(0, undef);
    ok !compare("", undef);
};

subtest 'refs' => sub {
    ok compare(\1, \1);
    ok compare(\\1, \\1);
    ok compare(\\\1, \\\1);
    ok !compare(\\\1, \\1);
    ok !compare(\1, \\1);
    ok !compare(1, \1);
    my $a = [];
    my $b = [];
    ok compare([\\\\\\\\\\\\\\\\\\\\\\\$a], [\\\\\\\\\\\\\\\\\\\\\\\$b]);
};

subtest 'objects without overloads' => sub {
    { package O1; }
    my $o1 = bless {a => 1, b => 2}, 'O1';
    my $o2 = bless {a => 1, b => 2}, 'O1';
    my $o3 = bless {a => 1, b => 3}, 'O1';
    my $o4 = bless {a => 1, b => 2}, 'O0';
    my $no = {a => 1, b => 2};
    ok compare($o1, $o2);
    ok !compare($o1, $o3);
    ok !compare($o1, $o4);
    ok !compare($o1, $no);
};

subtest 'objects with overloads' => sub {
    {
        package O2;
        use overload '==' => \&myeq;
        sub myeq { return $_[0][0] == $_[1][0] }
    }
    my $oo1 = bless [1, 2], 'O2';
    my $oo2 = bless [1, 2], 'O2';
    my $oo3 = bless [1, 3], 'O2';
    my $oo4 = bless [2, 2], 'O2';
    my $oo5 = bless [1, 2], 'O1';
    my $noo = [1, 2];
    ok compare($oo1, $oo2);
    ok compare($oo1, $oo3);
    ok !compare($oo1, $oo4);
    ok !compare($oo1, $oo5);
    ok !compare($oo1, $noo);
};

done_testing;
