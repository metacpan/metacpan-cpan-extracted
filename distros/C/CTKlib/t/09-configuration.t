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
    #note(explain($config));
    #sleep 5;
    #note(explain($config->reload));
}



1;

__END__
