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
use Test::More tests => 5;

use File::Spec;
use CTK::App;
use CTK::ConfGenUtil;

my $ctk = CTK::App->new(
        plugins     => [qw/test/],
        configfile  => File::Spec->catfile("src", "test.conf"),
        root        => "src",
        #debug => 1,
    );
ok($ctk->status, "CTK with plugins is ok");
note($ctk->error) unless $ctk->status;
my $msg = $ctk->foo;
ok(length($msg), "Check test method foo(). Length of response");
ok($ctk->conf("flag"), "Flag is true");
is(value($ctk->config(), "myinc/Test/val2"), "Blah-Blah-Blah", "myinc/Test/val2 eq Blah-Blah-Blah");

ok($ctk->configobj->status, "Congig status is ok") or diag($ctk->configobj->error);

if (-d '.svn' || -d '.git') {
    note(explain($ctk));
    note($ctk->foo);
}

#$ctk->gpg_decript("Blah-Blah-Blah");

1;

__END__
