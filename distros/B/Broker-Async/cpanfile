requires 'Carp';
requires 'Class::Tiny';
requires 'Exporter';
requires 'Scalar::Util';
requires 'perl', '5.008';

on configure => sub {
    requires 'ExtUtils::MakeMaker';
};

on build => sub {
    requires 'ExtUtils::MakeMaker';
};

on test => sub {
    requires 'Future', '0.26';
    requires 'List::Util';
    requires 'Test::Fatal';
    requires 'Test::LeakTrace';
    requires 'Test::More';
    requires 'parent';
};

on develop => sub {
    requires 'AnyEvent::Future';
    requires 'AnyEvent::HTTP';
    requires 'CPAN::Meta';
    requires 'Future::HTTP';
    requires 'Future::Mojo';
    requires 'IO::Async';
    requires 'Module::CPANfile';
    requires 'Mojolicious';
    requires 'POE::Future';
    requires 'Pod::Markdown';
    requires 'Test::Pod', '1.00';
    requires 'Test::Strict';
};
