use strict;
use warnings;
use Test::More;
use Test::Exception;
use Cpanel::JSON::XS;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Exporter::MediaHaven';
    use_ok $pkg;
}
require_ok $pkg;

my $url  = $ENV{MEDIAHAVEN_URL} || "";
my $user = $ENV{MEDIAHAVEN_USER} || "";
my $pwd  = $ENV{MEDIAHAVEN_PWD} || "";

SKIP: {
    skip "No Mediahaven server environment settings found (MEDIAHAVEN_URL,"
	 . "MEDIAHAVEN_USER,MEDIAHAVEN_PWD).",
	100 if (! $url || ! $user || ! $pwd);

    my $exporter = Catmandu->exporter(
                        'MediaHaven',
                        url => $url ,
                        username => $user ,
                        password => $pwd ,
                        json_key => 'description');

    ok $exporter , 'got an exporter';

    ok $exporter->mediahaven , 'got a connection';

    my $res = $exporter->mediahaven->search();

    ok $res , 'got search result';

    my $fragmentId = $res->{mediaDataList}->[1]->{fragmentId};

    ok $fragmentId , "got one record $fragmentId";

    my $record = { _id => $fragmentId , date => time , test => [qw(1 2 3)]};

    ok $exporter->add($record) , "updated record $fragmentId";

    ok $exporter->commit , "can do a commit";

    sleep(20);
    
    my $record2 = $exporter->mediahaven->record($fragmentId);

    ok $record2 , 'got the record back';

    my $description = $record2->{description};

    ok $description , "got a description: $description";

    my $json_rec = decode_json $description;

    ok $json_rec  , "got json";

    is_deeply $record , $json_rec  , "update was a success";
}

done_testing;
