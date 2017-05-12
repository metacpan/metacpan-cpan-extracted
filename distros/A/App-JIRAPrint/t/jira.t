#! perl -w

use Test::More;

use App::JIRAPrint;

my $j = App::JIRAPrint->new({ url => 'https://something.atlassian.net', username => 'blabla', password => 'blablabla' });
ok( $j->jira() , "Ok got jira client");

done_testing();
