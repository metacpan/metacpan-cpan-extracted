use strict;
use Test::More;
use Data::Generator::FromDDL;

sub _generate {
    my ($ddl, $n, $bytes_per_sql) = @_;
    my $generator = Data::Generator::FromDDL->new({ ddl => $ddl });
    open my $out_fh, '>', \my $output;
    $generator->generate($n, $out_fh, 'sql', 0, $bytes_per_sql);

    chomp $output;
    $output  =~ s/;\s+$//m;
    return $output;
}

subtest 'single sql statement' => sub {
    my $ddl = 'CREATE TABLE t (id int AUTO_INCREMENT);';

    # length('INSERT IGNORE INTO `t` (`id`) VALUES ;') => 38

    my $num_of_records = 1;
    my $bytes_per_sql = 41;
    my $got = _generate($ddl, $num_of_records, $bytes_per_sql);
    is scalar(split ';', $got), 1;

    $num_of_records = 2;
    $bytes_per_sql = 46;
    $got = _generate($ddl, $num_of_records, $bytes_per_sql);
    is scalar(split ';', $got), 1;
};

subtest 'abnormal bytes_per_sql value' => sub {
    my $ddl = 'CREATE TABLE t (id int AUTO_INCREMENT);';

    my $num_of_records = 1;
    my $bytes_per_sql = 0;
    my $got = _generate($ddl, $num_of_records, $bytes_per_sql);
    is scalar(split ';', $got), 1;

    $num_of_records = 1;
    $bytes_per_sql = -1;
    $got = _generate($ddl, $num_of_records, $bytes_per_sql);
    is scalar(split ';', $got), 1;
};

subtest 'divide into multiple sql statements' => sub {
    my $ddl = 'CREATE TABLE t (id int AUTO_INCREMENT);';

    # length('INSERT IGNORE INTO `t` (`id`) VALUES ;') => 38

    my $num_of_records = 2;
    my $bytes_per_sql = 41;
    my $got = _generate($ddl, $num_of_records, $bytes_per_sql);
    is scalar(split ';', $got), 2;

    $num_of_records = 6;
    $bytes_per_sql = 46;
    $got = _generate($ddl, $num_of_records, $bytes_per_sql);
    is scalar(split ';', $got), 3;
};

done_testing;
