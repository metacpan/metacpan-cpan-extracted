#!perl
#
# This file is part of Convert-TBX-Basic
#
# This software is copyright (c) 2016 by Alan K. Melby.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use strict;
use warnings;

use Test::More 0.96 tests => 2;
use_ok('Test::CPAN::Changes');
subtest 'changes_ok' => sub {
    changes_file_ok('Changes');
};
done_testing();
