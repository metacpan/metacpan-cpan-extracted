use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;

catch_run("[misc]");

sub test ($&);

test 'magic string in ctor' => sub {
    my $str = "*** 2013-09-05 ***";
    die unless $str =~ /.+(\d\d\d\d-\d\d-\d\d).+/;
    my $date = Date->new($1);
    is $date, '2013-09-05';
};

test 'MEIACORE-1795' => sub {
    my $date = "2021-09-02 14:07:35 +0300";
    my $dt1 = Date->new(substr($date, 0, 10));
    is $dt1->epoch, 1630530000;
};

done_testing();

sub test ($&) {
    my ($name, $sub) = @_;
    tzset('Europe/Moscow');
    subtest $name => $sub;
}