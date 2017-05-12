#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use Test::More;
use Path::Class;
use Catalyst::Plugin::ErrorCatcher::Email;

can_ok('Catalyst::Plugin::ErrorCatcher::Email', qw/_munge_path/)
    or die "_munge_path() method not implemented";

my @tests = (
    { # unix-y path
        for         => 'linux',
        input       => '/X/.build/Y/t/lib/TestApp/Controller/Foo.pm',
        expected    => Path::Class::dir(qw/TestApp Controller Foo.pm/)->stringify,
    },
    { # unix-y path - somehow has no lib or script
      # - test we DTRT if things go wrong
        for         => 'linux',
        input       => '/X/.build/Y/t/blibble/TestApp/Controller/Foo.pm',
        expected    => Path::Class::dir(qw[/ X .build Y t blibble TestApp Controller Foo.pm])->stringify,
    },
    { # windows-y path; from http://www.cpantesters.org/cpan/report/6c4e926e-77db-1014-9ca9-8abd9bd6a865
        for         => 'MSWin32',
        input       => 'C:\Perl\cpan\build\Catalyst-Plugin-ErrorCatcher-0.0.8.4-R4oSOi\t\lib\TestApp\Controller\Foo.pm',
        expected    => Path::Class::dir('TestApp', 'Controller', 'Foo.pm')->stringify,
    },
    { # windows-y path; from http://www.cpantesters.org/cpan/report/6c4e926e-77db-1014-9ca9-8abd9bd6a865
        for         => 'MSWin32',
        input       => 'C:\Perl\XXX\t\lib\TestApp\Controller\Foo.pm',
        expected    => Path::Class::dir('TestApp', 'Controller', 'Foo.pm')->stringify,
    },
);

# run the appropriate tests for the current OS
foreach my $test (@tests) {
    SKIP: {
        skip "not testing $test->{for} path on $^O system", 1
            if ($test->{for} ne $^O);
        my $result = Catalyst::Plugin::ErrorCatcher::Email::_munge_path(
            $test->{input}
        );
        is(
            $result,
            $test->{expected},
            'munged ' . $test->{for} . ' path to ' .  $test->{expected}
        );
    }
}

done_testing;
