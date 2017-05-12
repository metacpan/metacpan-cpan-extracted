# AnyEvent-MyPeopleBot-Client #

AnyEvent-MyPeopleBot-Client is a highlevel MyPeopleBot API wrapper.

[MyPeopleBot](http://dna.daum.net/apis/mypeople) is like mobile instant
messaging service by [daum](http://daum.net) corporation.

## SYNOPSIS ##

```perl
use AnyEvent::HTTPD;
use AnyEvent::Mepeople::Client;
my $client = AnyEvent::MyPeopleBot::Client->new(
    apikey => 'xxxx',
);

my $httpd = AnyEvent::HTTPD->new(port => 8080);
$httpd->reg_cb(
    '/' => sub {
        my $action  = $req->parm('action');
        my $buddyId = $req->parm('buddyId');
        my $groupId = $req->parm('groupId');
        my $content = $req->parm('content');

        $req->respond({ content => [ 'text/plain', "AnyEvent::MyPeopleBot::Client" ]});
        if ($action =~ /^sendFrom/) {
            $client->send($buddyId || $groupId, 'hi', sub {
                my $json = shift;
                print "$json\n";
            });
        }
    }
);

$httpd->run;
```
