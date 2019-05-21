#########################################################################
#
# Serz Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 09-configuration.t 215 2019-04-29 17:46:56Z minus $
#
#########################################################################
use strict;
use warnings;
use Test::More tests => 9;
use File::Spec;

BEGIN { use_ok('CTK::Configuration') };

# Satus is false
{
    my $config = new_ok( 'CTK::Configuration' );
    ok(!$config->status, "Status is false") or diag(explain($config));
    note($config->error) if $config->error;

}

# Satus is true
{
    my $config = new_ok( 'CTK::Configuration', [
            config => File::Spec->catfile("src", "test.conf"),
        ] );
    ok($config->status, "Status is true") or diag(explain($config));
    note($config->error) if $config->error;
    ok($config->get("flag"), "Flag is true");
    ok($config->set("test", 123), "Setter");
    is($config->get("test"), 123, "Getter");
    is(ref($config->getall), "HASH", "Get all as hash");
}

1;

__END__
