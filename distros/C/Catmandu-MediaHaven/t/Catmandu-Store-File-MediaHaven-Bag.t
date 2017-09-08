use strict;
use warnings;
use Test::More;
use Test::Exception;
use IO::File;
use Catmandu::Store::File::MediaHaven;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Store::File::MediaHaven::Bag';
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

    my $store = Catmandu->store('File::MediaHaven',url => $url, username => $user, password => $pwd);

    ok $store , 'got a MediaHaven handle';

    my $index = $store->index();

    ok $index , 'got the index bag';

    my $array = $index->to_array;

    ok $array , 'list got a response';

    ok int(@$array) > 0 , 'got more than zero results';

    my $id0 = $array->[0]->{_id};

    ok $id0 , 'got at least one test result';

    my $files  = $index->files($id0);

    ok $files , "files($id0)";

    my $file_array = $files->to_array;

    ok $file_array  , 'bag list got a response';

    ok int(@$file_array ) == 1 , 'bag list got one response';

    my $filename = $file_array->[0]->{_id};

    ok $filename , "filename = $filename";

    ok $files->exists($filename) , "exists($filename)";

    my $file = $files->get($filename);

    ok $file , "get($filename)";

    is $file->{_id} , $filename , "_id = $filename";

    ok $file->{size} , "size = " . $file->{size};

    ok $file->{md5} , "md5 = " . $file->{md5};

    ok $file->{created} , "created = " . $file->{created};

    ok $file->{modified} , "modified = " . $file->{modified};

    ok $file->{content_type} , "content_type = " . $file->{content_type};

    ok ref($file->{_stream}) , "stream available";

    ok defined($files->stream(IO::File->new(">/dev/null"),$file)) , "stream($filename)";
}

done_testing;
