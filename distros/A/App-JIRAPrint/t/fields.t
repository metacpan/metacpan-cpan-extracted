#! perl -w

use Test::More;
use Test::MockModule;

use App::JIRAPrint;
# use Log::Any::Adapter qw/Stderr/;

my $j = App::JIRAPrint->new({ url => 'https://something.atlassian.net', username => 'blabla', password => 'blablabla', project => 'BLA', 'sprint' => '123' });
ok( $j->jira() , "Ok got jira client");

{
    my $jira = Test::MockModule->new('JIRA::REST');
    $jira->mock( GET =>  sub{ return [ { bla => 1 , foo => 'bar' }] ; } );
    ok( $j->fetch_fields() , "Ok got fields");
}

done_testing();
