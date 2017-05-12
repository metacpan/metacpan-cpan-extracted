use Test::More tests=>31;
use Data::Dumper;
use Catmandu::FedoraCommons;

my $host = $ENV{FEDORA_HOST} || "";
my $port = $ENV{FEDORA_PORT} || "";
my $user = $ENV{FEDORA_USER} || "";
my $pwd  = $ENV{FEDORA_PWD} || "";

SKIP: {
    skip "No Fedora server environment settings found (FEDORA_HOST,"
	 . "FEDORA_PORT,FEDORA_USER,FEDORA_PWD).", 
	31 if (! $host || ! $port || ! $user || ! $pwd);
	 
    my $x = Catmandu::FedoraCommons->new("http://$host:$port/fedora",$user,$pwd);

    ok($res = $x->findObjects(terms=>'*'),'findObjects');
    ok($res->is_ok,'is_ok');
    ok($obj = $res->parse_content,'parse_content');
    is(@{ $obj->{results} } , 20 , 'resultList');

    printf "[session = %s]\n" , $obj->{token};

    for my $hit (@{ $obj->{results} }) {
        printf "%s\n" , $hit->{pid};
    }

    ok($res = $x->resumeFindObjects(sessionToken => $obj->{token}), 'resumeFindObjects');
    ok($res->is_ok,'is_ok');
    ok($obj = $res->parse_content,'parse_content');
    is(@{ $obj->{results} } , 20 , 'resultList');

    printf "[session = %s]\n" , $obj->{token};

    for my $hit (@{ $obj->{results} }) {
        printf "%s\n" , $hit->{pid};
    }

    ok($res = $x->getDatastreamDissemination(pid => 'demo:5', dsID => 'THUMBRES_IMG'));
    ok($res->is_ok,'is_ok');
    ok(length $res->raw > 0, 'raw');
    ok($res = $x->getDatastreamDissemination(pid => 'demo:5', dsID => 'VERYHIGHRES', callback => \&process),'callback');

    ok($res = $x->getDissemination(pid => 'demo:29', sdefPid => 'demo:27' , method => 'resizeImage' , width => 100),'getDissemination');
    is($res->content_type, 'image/jpeg','content_type');
    ok($res->length > 3000, 'length');

    ok($res = $x->getObjectHistory(pid => 'demo:29'),'getObjectHistory');
    ok($res->is_ok,'is_ok');
    ok($obj = $res->parse_content, 'parse_content');
    is($obj->{objectChangeDate}->[0],'2008-07-02T05:09:43.234Z','objectChangeDate');

    ok($res = $x->getObjectProfile(pid => 'demo:29' ), 'getObjectProfile');
    ok($res->is_ok,'is_ok');
    ok($obj = $res->parse_content, 'parse_content');
    is($obj->{pid},'demo:29','pid');

    ok($res = $x->listDatastreams(pid => 'demo:29'), 'listDatastreams');
    ok($res->is_ok,'is_ok');
    ok($obj = $res->parse_content, 'parse_content');
    ok(@{ $obj->{datastream} } == 3, 'count datastreams');

    ok($res = $x->listMethods(pid => 'demo:29'));
    ok($res->is_ok,'is_ok');
    ok($obj = $res->parse_content, 'parse_content');
    ok(@{ $obj->{sDef} } == 2, 'count methods');
}

sub process {
    my ( $data, $response, $protocol ) = @_;
    ok($data, 'callback');
}
