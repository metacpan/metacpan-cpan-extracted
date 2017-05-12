use strict;
use Test::More;
use Data::Generator::FromDDL;

sub _generate {
    my $ddl = shift;
    my $generator = Data::Generator::FromDDL->new({ ddl => $ddl });
    open my $out_fh, '>', \my $output;
    $generator->generate(1, $out_fh);
    return $output;
}

subtest 'datatype bigint' => sub {
    my $ddl = 'CREATE TABLE t (`id` bigint);';
    my $expect = qr/INSERT IGNORE INTO `t` \(`id`\) VALUES \((.+)\);/;
    my $got = _generate($ddl);
    if ($got =~ $expect) {
        ok $1 >= - 2**63 && $1 <= 2**63;
    } else {
        fail;
    }
};

subtest 'datatype int(integer)' => sub {
    my $ddl = 'CREATE TABLE t (`id` int);';
    my $expect = qr/INSERT IGNORE INTO `t` \(`id`\) VALUES \((-?[\d]+)\);/;
    my $got = _generate($ddl);
    if ($got =~ $expect) {
        ok $1 >= - 2**31 && $1 <= 2**31;
    } else {
        fail;
    }
};

subtest 'datatype mediumint' => sub {
    my $ddl = 'CREATE TABLE t (`id` mediumint);';
    my $expect = qr/INSERT IGNORE INTO `t` \(`id`\) VALUES \((-?[\d]+)\);/;
    my $got = _generate($ddl);
    if ($got =~ $expect) {
        ok $1 >= - 2**23 && $1 <= 2**23;
    } else {
        fail;
    }
};

subtest 'datatype smallint' => sub {
    my $ddl = 'CREATE TABLE t (`id` smallint);';
    my $expect = qr/INSERT IGNORE INTO `t` \(`id`\) VALUES \((-?[\d]+)\);/;
    my $got = _generate($ddl);
    if ($got =~ $expect) {
        ok $1 >= - 2**15 && $1 <= 2**15;
    } else {
        fail;
    }
};

subtest 'datatype tinyint' => sub {
    my $ddl = 'CREATE TABLE t (`id` tinyint);';
    my $expect = qr/INSERT IGNORE INTO `t` \(`id`\) VALUES \((-?[\d]+)\);/;
    my $got = _generate($ddl);
    if ($got =~ $expect) {
        ok $1 >= - 2**7 && $1 <= 2**7;
    } else {
        fail;
    }
};

subtest 'datatype float(double)' => sub {
    my $ddl = 'CREATE TABLE t (`lat` float(8, 8));';
    my $expect = qr/INSERT IGNORE INTO `t` \(`lat`\) VALUES \((-?\d+\.\d+)\);/;
    my $got = _generate($ddl);
    if ($got =~ $expect) {
        ok $1 < 1;
    } else {
        fail;
    }

    $ddl = 'CREATE TABLE t (`lat` double(4, 1));';
    $expect = qr/INSERT IGNORE INTO `t` \(`lat`\) VALUES \((-?\d+\.\d+)\);/;
    $got = _generate($ddl);
    if ($got =~ $expect) {
        ok $1 < 1000;
    } else {
        fail;
    }
};

subtest 'datatype boolean(bool)' => sub {
    my $ddl = 'CREATE TABLE t (`is_valid` boolean);';
    my $expect = qr/INSERT IGNORE INTO `t` \(`is_valid`\) VALUES \(([\d]+)\);/;
    my $got = _generate($ddl);
    if ($got =~ $expect) {
        ok ($1 == 0 or $1 == 1);
    } else {
        fail;
    }
};

subtest 'datatype timestamp' => sub {
    my $ddl = 'CREATE TABLE t (`date` timestamp);';
    my $expect = qr/INSERT IGNORE INTO `t` \(`date`\) VALUES \('\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d\'\);/;
    my $got = _generate($ddl);
    like $got, $expect;
};

subtest 'datatype char(varchar, tinytext, text, mediumtext)' => sub {
    my $ddl = 'CREATE TABLE t (`name` char(4));';
    my $expect = "INSERT IGNORE INTO `t` (`name`) VALUES ('nam1');\n";
    my $got = _generate($ddl);
    is $got, $expect;
};

subtest 'datatype enum' => sub {
    my $ddl = "CREATE TABLE t (`name` enum('foo', 'bar'));";
    my $expect = qr/INSERT IGNORE INTO `t` \(`name`\) VALUES \('(\S+)'\);/;
    my $got = _generate($ddl);
    if ($got =~ $expect) {
        ok (($1 eq 'foo') or ($1 eq 'bar'));
    } else {
        fail;
    }
};

done_testing;
