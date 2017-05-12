
use Authen::Challenge::Basic;

$|=1;

print "1..2\n";

$server = Authen::Challenge::Basic->new ('Secret' => 'tanganyika',
				         'Timeout' => 20,
					 'Sync' => 10);

$client = Authen::Challenge::Basic->new ('Secret' => 'tanganyika',
				         'Timeout' => 20,
				         'Sync' => 10);


$c = $server->Challenge;
$r = $client->Response($c);

if ($server->Validate($c, $r)) {
    print "ok 1\n";
}
else
{
    print "not ok 1\n";
}

sleep 11;			# Have the challenge/response expire

if (!$server->Validate($c, $r)) {
    print "ok 2\n";
}
else
{
    print "not ok 2\n";
}


