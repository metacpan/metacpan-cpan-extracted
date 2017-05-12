use strict;
use warnings;

use Test::More tests => 7;
require 't/util.pl';

package TestApp::NextLastRule;
use Class::AutoGenerate -base;

use Test::More;

requiring '**::Foo' => generates {
    my $prefix = $1;

    if ($prefix =~ /::Bar$/) {
        next_rule;
    }

    defines method1 => sub {};
};

requiring '**::Bar::Foo' => generates {
    defines method2 => sub {};
};

requiring '**::Bar' => generates {
    my $prefix = $1;

    if ($prefix =~ /::Foo$/) {
        last_rule;
    }

    defines method3 => sub {};
};

requiring '**::Foo::Bar' => generates { 
    defines method4 => sub {};
};

package main;
TestApp::NextLastRule->new;

require_ok('TestApp::Foo::Foo');
can_ok('TestApp::Foo::Foo', 'method1');

require_ok('TestApp::Bar::Foo');
can_ok('TestApp::Bar::Foo', 'method2');

require_ok('TestApp::Bar::Bar');
can_ok('TestApp::Bar::Bar', 'method3');

require_not_ok('TestApp::Foo::Bar');

