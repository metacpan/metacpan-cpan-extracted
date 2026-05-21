use strict;
use warnings;
use Test::More;

eval { require Test::CPAN::Changes; 1 }
    or plan skip_all => 'Test::CPAN::Changes required';

Test::CPAN::Changes::changes_file_ok('Changes');
done_testing;
