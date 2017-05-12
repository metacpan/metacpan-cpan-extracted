use strict;
use Test::More;
use Data::Generator::FromDDL::CLI;
use File::Temp;

sub _setup {
    my $cli = Data::Generator::FromDDL::CLI->new;

    my ($out_fh) = File::Temp->new(UNLINK => 1);
    my ($ddl_fh) = File::Temp->new(UNLINK => 1);
    print $ddl_fh <<'END_DDL';
CREATE TABLE T1 (a int unsigned NOT NULL PRIMARY KEY);
CREATE TABLE T2 (a int unsigned NOT NULL PRIMARY KEY);
END_DDL
    close ($ddl_fh);

    return $cli, $out_fh, $ddl_fh;
}

sub _get_result {
    my $filename = shift;
    return do {
        local $/;
        open my $fh, '<', $filename;
        <$fh>;
    };
}

subtest 'parse_byte_string' => sub {
    my $cli = Data::Generator::FromDDL::CLI->new;

    is $cli->parse_byte_string('12'), 12;
    is $cli->parse_byte_string('12KB'), 12 * 1024;
    is $cli->parse_byte_string('12kb'), 12 * 1024;
    is $cli->parse_byte_string('12k'), 12 * 1024;
    is $cli->parse_byte_string('12MB'), 12 * 1024 * 1024;
    is $cli->parse_byte_string('12GB'), 12 * 1024 * 1024 * 1024;
};

subtest 'cli with all options' => sub {
    my ($cli, $out_fh, $ddl_fh) = _setup;

    my @args = qw(--num=1 --format=sql --parser=mysql --include=T1 --pretty);
    push @args, '-o', $out_fh->filename, $ddl_fh->filename;

    $cli->run(@args);

    is _get_result($out_fh->filename), <<'END_EXPECT';
INSERT IGNORE INTO
    `T1` (`a`)
VALUES
    (1);
END_EXPECT
};

done_testing;
