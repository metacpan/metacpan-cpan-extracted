use Test::More tests=>72;
use Data::Dumper;
use Catmandu::FedoraCommons;

my $host = $ENV{FEDORA_HOST} || "";
my $port = $ENV{FEDORA_PORT} || "";
my $user = $ENV{FEDORA_USER} || "";
my $pwd  = $ENV{FEDORA_PWD} || "";

SKIP: {
    skip "No Fedora server environment settings found (FEDORA_HOST,"
	 . "FEDORA_PORT,FEDORA_USER,FEDORA_PWD).", 
	72 if (! $host || ! $port || ! $user || ! $pwd);
	
    my $x = Catmandu::FedoraCommons->new("http://$host:$port/fedora",$user,$pwd);

    ok($res = $x->addDatastream(pid => 'demo:29', dsID => 'TEST' , file => 'README', mimeType => 'text/plain'), 'addDatastream(file)');
    ok($res->is_ok, 'is_ok');
    ok($obj = $res->parse_content, 'parse_content');
    ok($obj->{dsID} eq 'TEST','got a new dsID'); 
    ok($obj->{profile}->{dsMIME} eq 'text/plain','text/plain type');

    ok($res = $x->addDatastream(pid => 'demo:29', dsID => 'TEST2' , url => 'http://www.google.com', mimeType => 'text/html' , controlGroup => 'R'), 'addDatastream(url)');
    ok($res->is_ok, 'is_ok');
    ok($obj = $res->parse_content, 'parse_content');
    ok($obj->{dsID} eq 'TEST2','got a new dsID'); 
    ok($obj->{profile}->{dsControlGroup} eq 'R','got R as control group');

    ok($res = $x->addDatastream(pid => 'demo:29', dsID => 'TEST3' , file => 't/marc.xml', mimeType => 'text/xml' , controlGroup => 'X'), 'addDatastream(xml)');
    ok($res->is_ok, 'is_ok');
    ok($obj = $res->parse_content, 'parse_content');
    ok($obj->{dsID} eq 'TEST3','got a new dsID'); 
    ok($obj->{profile}->{dsControlGroup} eq 'X','got X as control group');

    ok($res = $x->purgeDatastream(pid => 'demo:29', dsID => 'TEST'),'purge TEST');
    ok($res = $x->purgeDatastream(pid => 'demo:29', dsID => 'TEST2'),'purge TEST2');
    ok($res = $x->purgeDatastream(pid => 'demo:29', dsID => 'TEST3'),'purge TEST3');

    ok($res = $x->addRelationship(pid => 'demo:29' , relation => [ 'info:fedora/demo:29' , 'http://my.org/name' , 'Peter']),'add relationship');
    ok($res->is_ok, 'is_ok');
    ok($res->parse_content, 'parse_content');

    ok($res = $x->getRelationships(pid => 'demo:29', relation => [ undef , 'http://my.org/name']),'get relationship');
    ok($res->is_ok,'is_ok');
    ok($model = $res->parse_content,'parse_content');
    ok(exists $model->as_hashref->{'info:fedora/demo:29'},'check model');

    ok($res = $x->purgeRelationship(pid => 'demo:29' , relation => [ 'info:fedora/demo:29' , 'http://my.org/name' , 'Peter']),'purge relationship');

    ok($res = $x->export(pid => 'demo:29'),'export');
    ok($res->is_ok,'is_ok');
    ok($obj = $res->parse_content,'parse_content');

    ok($res = $x->getDatastream(pid => 'demo:29', dsID => 'DC'),'getDatastream');
    ok($res->is_ok,'is_ok');
    ok($obj = $res->parse_content, 'parse_content');
    is($obj->{profile}->{dsFormatURI},'http://www.openarchives.org/OAI/2.0/oai_dc/','check model');

    ok($res = $x->getDatastreamHistory(pid => 'demo:29', dsID => 'DC'),'getDatastreamHistory');
    ok($res->is_ok,'is_ok');
    ok($obj = $res->parse_content, 'parse_content');
    ok(@{$obj->{profile}} == 1,'check model');

    ok($res = $x->getNextPID('changeme'),'getNextPID');
    ok($res->is_ok,'is_ok');
    ok($obj = $res->parse_content, 'parse_content');
    ok(@{$obj} == 1,'check model');

    ok($res = $x->getObjectXML(pid => 'demo:29'),'getObjectXML');
    ok($res->is_ok,'is_ok');
    ok($obj = $res->parse_content,'parse_content');

    ok($res = $x->ingest(pid => 'demo:40', file => 't/obj_demo_40.zip', format => 'info:fedora/fedora-system:ATOMZip-1.1'),'ingest demo:40');
    ok($res->is_ok,'is_ok');
    ok($obj = $res->parse_content, 'parse_content');

    ok($res = $x->purgeObject(pid => 'demo:40'),'purge demo:40');

    $res = $x->addDatastream(pid => 'demo:29', dsID => 'TEST' , file => 'README' , mimeType => 'text/plain');

    ok($res = $x->modifyDatastream(pid => 'demo:29', dsID => 'TEST' , file => 't/marc.xml', mimeType => 'text/xml'),'modifyDatastream');
    ok($res->is_ok,'is_ok');
    ok($obj = $res->parse_content, 'parse_content');

    ok($res = $x->purgeDatastream(pid => 'demo:29', dsID => 'TEST'),'purgeDatastream');
    ok($res->is_ok,'is_ok');
    ok($obj = $res->parse_content, 'parse_content');

    ok($res = $x->modifyObject(pid => 'demo:29' , state => 'I'),'modifyObject');
    ok($res->is_ok,'is_ok');
    ok($obj = $res->parse_content, 'parse_content');

    ok($res = $x->modifyObject(pid => 'demo:29' , state => 'A'),'modifyObject');
    ok($res->is_ok,'is_ok');
    ok($obj = $res->parse_content, 'parse_content');

    ok($res = $x->setDatastreamState(pid => 'demo:29' , dsID => 'url' , dsState => 'A'),'setDatastreamState');
    ok($res->is_ok,'is_ok');
    ok($obj = $res->parse_content, 'parse_content');

    ok($res = $x->setDatastreamVersionable(pid => 'demo:29' , dsID => 'url' , versionable => 'false'),'setDatastreamVersionable');
    ok($res->is_ok,'is_ok');
    ok($obj = $res->parse_content, 'parse_content');

    ok($res = $x->validate(pid => 'demo:29'),'validate');
    ok($res->is_ok,'is_ok');
    ok($obj = $res->parse_content, 'parse_content');

    ok($res = $x->upload(file => 't/marc.xml'),'upload');
    ok($res->is_ok,'is_ok');
    ok($obj = $res->parse_content, 'parse_content');
}
