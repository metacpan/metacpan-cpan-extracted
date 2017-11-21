requires  'DBD::mysql', ">= 4.019";
requires 'Coro';
requires 'AnyEvent';
requires 'Coro::AnyEvent';
on 'test' => sub {
    requires 'Test::More';
    requires 'DBI';
    requires 'Test::mysqld';
    requires 'Time::HiRes';
};
on configure => sub {
    requires 'ExtUtils::MakeMaker';
};

