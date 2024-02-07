#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2024 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#########################################################################
use strict;
use utf8;
use Test::More;

use_ok qw/Acme::Crux/;

# Direct
{
    my $app = new_ok( 'Acme::Crux' => [(
        project => 'MyApp',
        preload => [], # Disable plugins
    )] );
    ok(!$app->error, 'No errors') or diag($app->error);
}

1;

package MyApp;

use parent 'Acme::Crux';

__PACKAGE__->register_handler; # default

__PACKAGE__->register_handler(
    handler     => "foo",
    aliases     => "one, two",
    description => "Foo handler",
    params => {
        param1 => "test",
        param2 => 123,
    },
    code => sub {
### CODE:
    my ($self, $meta, @args) = @_;

    print Acrux::Util::dumper({
        name => 'foo',
        meta => $meta,
        args => \@args,
    });

    return 1;
});

__PACKAGE__->register_handler(
    handler     => "bar",
    aliases     => "aaa, bbb",
    description => "Bar handler",
    code => sub {
### CODE:
    my ($self, $meta, @args) = @_;

    print Acrux::Util::dumper({
        name => 'bar',
        meta => $meta,
        args => \@args,
    });

    return 1;
});

1;

package main;

# MyApp
my $app = new_ok( 'MyApp' => [(
    project => 'MyApp',
    preload => [], # Disable plugins
)] ); #  => \@args

# Run defult handler
ok($app->run, "Default handler returns 1") or diag $app->error;

# And again
ok($app->run, "Default handler returns 1 (retry)") or diag $app->error;

#my $handler = $app->lookup_handler( 'foo' );
#note explain $handler;

#my $handlers = $app->handlers(1);
#note explain $handlers;

#my $res = $app->run('one', abc => 123, def => 456);
#note explain $res;

#note explain \%Acme::Crux::Sandbox::HANDLERS;

done_testing;

1;

__END__

prove -lv t/10-app-min.t
