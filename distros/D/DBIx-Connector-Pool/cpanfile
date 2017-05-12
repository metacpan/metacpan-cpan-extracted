requires 'Coro';
requires 'AnyEvent';
requires 'Coro::AnyEvent';
requires 'Time::HiRes';
requires 'DBIx::Connector';

on 'test' => sub {
    requires 'Test::More';
    requires 'DBI';
    requires 'File::Temp';
    requires 'Time::HiRes';
    requires 'DBD::Pg', ">= 1.44";
    requires 'DBIx::PgCoroAnyEvent';
};

on configure => sub {
    requires 'ExtUtils::MakeMaker';
};

