use Test::More;
use strict;
use warnings;

pass("dsn:$ENV{PERL_TEST_MYSQLPOOL_DSN}");

pipe my $reader, my $writer;

my $pid = fork;
die "failed to fork: $!" unless defined $pid;
if ($pid == 0) {
    close $reader;
    print $writer "dsn:$ENV{PERL_TEST_MYSQLPOOL_DSN}";
    close $writer;
    exit;
}
close $writer;
my $result = <$reader>;
wait;

pass($result);

done_testing;
