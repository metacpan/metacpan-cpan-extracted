# Name:
#   find.t.
#
# Author:
#   Ron Savage <ron@savage.net.au>
#   http://savage.net.au/index.html

use strict;

my($original_purpose);


BEGIN {
    use CGI::Session;
    use Test::More;

    if (CGI::Session->can('find') )
    {
        plan tests => 7;

        # Remove any other test sessions, so sub find is called once,
        # which means the test count above is correct, since every extra
        # session would mean sub find executed 2 extra tests.

        unlink <t/cgisess*>;

        $original_purpose = "Create session simply to test deleting it with CGI::Session's sub find()";
    }

    else
    {
        plan skip_all => "Requires a version of CGI::Session with method 'find()'";
    }
};

# Create a block so $s goes out of scope before we try to access the session.
# Without the block we will only see sessions created by previous runs of the program.

{
    my($s) = CGI::Session->new(undef, undef, {Directory => 't'} );

    ok($s, 'The test session has been created');

    # Set the expiry time so it does not get deleted somehow before we delete it.

    $s->expire(5);

    ok($s->id, "The test session's id has been set");

    $s->param(purpose => $original_purpose);

    ok($s->param('purpose'), "The test session's parameter called 'purpose' has been set");
}

sub callback {
    my($session) = @_;

    isa_ok($session, 'CGI::Session', 'CGI::Session::find() found a session whose class');
    ok($session->param('purpose'), "The found session's param called 'purpose' has a true value");
    is($original_purpose, $session->param('purpose'), "The found session's param called 'purpose' has the expected value");
    $session->delete();
    $session->flush();
    diag 'The found session has been deleted and flushed';

}   

CGI::Session->find(undef, \&callback, {Directory => 't'});
is(CGI::Session->errstr, '', 'find() returned no errors');
