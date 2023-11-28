use Test2::V0;
use Test2::Plugin::ExitSummary;

todo 'general list of todos' => sub {
    fail $_ for 
        'blocked_attributes';
};

done_testing;
