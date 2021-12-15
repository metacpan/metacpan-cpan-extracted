requires 'Class::XSAccessor' => '0.10';
requires 'Net::DNS';
requires 'Promise::ES6' => 0.11;
requires 'X::Tiny';
requires 'XSLoader' => 0.24;

test_requires 'Test::DescribeMe';
test_requires 'Test::More';
test_requires 'Test::FailWarnings';
test_requires 'Test::Exception';
test_requires 'Test::Deep';
test_requires 'Net::DNS::Nameserver';

recommends 'ExtUtils::PkgConfig';

configure_requires 'ExtUtils::MakeMaker::CPANfile';
configure_requires 'JSON::PP';

on develop => sub {
    requires 'AnyEvent';
    requires 'IO::Async';
    recommends 'Mojolicious';

    requires 'AnyEvent::XSPromises';
    requires 'Promise::XS';
};
