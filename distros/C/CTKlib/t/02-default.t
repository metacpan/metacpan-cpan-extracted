#########################################################################
#
# Serz Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 02-default.t 217 2019-04-30 09:15:34Z minus $
#
#########################################################################
use strict;
use warnings;
use Test::More tests => 5;
BEGIN { use_ok('CTK', qw/ :constants /); };

# Default object
my $ctk = new_ok( 'CTK', [(prefix => "test")] );
ok($ctk->status, "Status is true") or diag(explain($ctk));
note($ctk->error) if $ctk->error;
ok($ctk->revision, "Revision");
is(PREFIX, "ctk", "CTK prefix");
if (-d '.svn' || -d '.git') {
	note(sprintf("Revision: %s", $ctk->revision));
	note(explain($ctk));
}

1;

__END__
