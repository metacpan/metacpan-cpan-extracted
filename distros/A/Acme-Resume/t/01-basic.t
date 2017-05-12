use strict;
use warnings;

use Test::More;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

BEGIN {
    use_ok 'Acme::Resume';
}

use lib 't/01/lib';

use Acme::Resume::For::Tester;

my $resume = Acme::Resume::For::Tester->new;

is $resume->name, 'The Tester', 'Correct name';
is $resume->email, 'the.tester@example.com', 'Correct email';
is $resume->get_address(-1), 'USA', 'Correct country';

is $resume->get_education(1)->school, 'Owen Patterson High', 'Correct school on second education';

is $resume->get_job(0)->started->year, '1988', 'Correct year on first job';

done_testing;
