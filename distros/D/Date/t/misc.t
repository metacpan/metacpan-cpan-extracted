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

done_testing();

sub test ($&) {
    my ($name, $sub) = @_;
    tzset('Europe/Moscow');
    subtest $name => $sub;
}