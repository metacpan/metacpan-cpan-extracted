#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#########################################################################
use strict;
use warnings;

use Test::More tests => 6;
BEGIN { use_ok('CTK::Helper') };

my $app = new_ok( 'CTK::Helper', [
        #debug => 1,
        #verbose => 1,
    ]);

my $status = $app->register_handler(
    handler     => "foo",
    description => "Foo CLI handler",
    parameters => {
            param1 => "foo",
            param2 => "bar",
            param3 => 123,
        },
    code => sub {
### CODE:
    my $self = shift;
    my $meta = shift;
    my @params = @_;
    note(explain({
            meta 	=> $meta,
            params 	=> [@params],
        })) if $self->debugmode;

    return 1;
});
ok($status, "Add foo handler");
my $handler = $app->lookup_handler("foo");
ok($handler, "Handler is ok");
ok(!$app->lookup_handler("foobarbazXXXYYYZZZ"), "Handler lookup failed");

ok($app->run("foo", (foo => "one", bar => 1)), "Run foo handler");

#note(explain($handler));

#my $ctkx = CTKx->instance(c => $c);
#my $h = CTK::Helper->new( -t => 'regular' );
#is($h->{class}, 'CTK::Helper::SkelRegular', 'Class for "regular" type');

1;

