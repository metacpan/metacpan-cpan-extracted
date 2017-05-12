use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

{

    package TestApp;
    use Dancer2;

    get '/' => sub {

        my $iter = [
            { code => "first",  received_check => '1', },
            { code => "second", received_check => '1' }
        ];

        template( checkbox => { items => $iter } );
    };
}

my $test = Plack::Test->create( TestApp->to_app );

my $res = $test->request( GET '/' );
ok $res->is_success, "GET / successful";

my $expected = <<'OUT';
<li class="list">
<span class="received-check">
<input class="received" name="received" type="checkbox" value="first" />
</span>
</li>
<li class="list">
<span class="received-check">
<input class="received" name="received" type="checkbox" value="second" />
</span>
</li>
OUT
$expected =~ s/\n//g;

like $res->content, qr/\Q$expected\E/, "got checkboxes as expected";

done_testing;
