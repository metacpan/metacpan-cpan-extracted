use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Importer::Pure';
    use_ok $pkg or BAIL_OUT "Can't load $pkg";
}

my $DEFAULT_TEST_BASE = 'http://notapurehost.com/ws/rest';

my $base_url = $ENV{PURE_BASE};
my $user     = $ENV{PURE_USER};
my $password = $ENV{PURE_PASSWORD};
my $apiKey   = $ENV{PURE_APIKEY};

if ( !$base_url ) {
    $base_url = $DEFAULT_TEST_BASE;

    # Note "Using default base '$base_url' for testing. This can be changed by
    # setting the environment variable PURE_BASE. PURE_APIKEY needs also to be set
    # and possibly also PURE_USER and PURE_PASSWORD.";
}

my %connect_args = (
    base     => $base_url,
    apiKey   => $apiKey,
    user     => $user,
    password => $password,
);

throws_ok { $pkg->new( endpoint => 'research-outputs', apiKey => '1234' ) }
qr/Base URL.+ required/, "required argument (base) missing";

throws_ok { $pkg->new( endpoint => 'research-outputs', base => $base_url) }
qr/apiKey.+ required/, "required argument (apiKey) missing";

throws_ok { $pkg->new( base => $DEFAULT_TEST_BASE ) }
qr/endpoint.+required/, "required argument (endpoint) missing";

lives_ok { $pkg->new( base => $DEFAULT_TEST_BASE, apiKey => '1234', endpoint => 'research-outputs' ) }
"required arguments supplied";

throws_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        apiKey   => '1234',
        endpoint => 'research-outputs',
        user     => 'user'
      )
} qr/Password is needed/, "password missing";

lives_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'research-outputs',
        apiKey => '1234',
        user     => 'user',
        password => 'password'
      )
} "user,password provided";

throws_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'research-outputs',
        apiKey => '1234',
        filter   => 'invalid'
      )
} qr/Invalid filter/, "invalid filter";

lives_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'research-outputs',
        apiKey => '1234',
        filter   => sub { 1 }
      )
} "filter provided";

lives_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        apiKey => '1234',
        endpoint => 'persons',
        timeout  => 100
      )
} "timeout provided";

throws_ok {
    $pkg->new(
        base     => 'notvalid',
        endpoint => 'research-outputs',
        apiKey => '1234',
      )
} qr/Invalid base/, "invalid base";

lives_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'research-outputs',
        options  => { 'size' => 1 },
        apiKey => '1234',
      )
} "options";

lives_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'research-outputs',
        handler  => 'raw',
        apiKey => '1234',
      )
} "handler raw";

lives_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'research-outputs',
        handler  => 'simple',
        apiKey => '1234',
      )
} "handler simple";

lives_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'research-outputs',
        handler  => 'struct',
        apiKey => '1234',
      )
} "handler struct";

throws_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'research-outputs',
        apiKey => '1234',
        handler  => 'wrong'
      )
} qr/Unable to load handler/, "missing handler";

throws_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'research-outputs',
        apiKey => '1234',
        handler  => 12345
      )
} qr/Invalid handler/, "invalid handler - number";

throws_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'research-outputs',
        apiKey => '1234',
        handler  => [ 0, 5 ],
      )
} qr/Invalid handler/, "invalid handler - array";

lives_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'research-outputs',
        apiKey => '1234',
        handler  => sub { $_[0] }
      )
} "handler custom";

lives_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'research-outputs',
        apiKey => '1234',
        handler  => Catmandu::Importer::Pure::Parser::raw->new,
      )
} "handler class invocant";

lives_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'research-outputs',
        apiKey => '1234',
        handler  => '+Catmandu::Importer::Pure::Parser::raw',
      )
} "handler class";

lives_ok {
    $pkg->new(
        base      => $DEFAULT_TEST_BASE,
        endpoint  => 'research-outputs',
        apiKey => '1234',
        trim_text => 1,
      )
} "trim text";

my $importer =
  $pkg->new( base => $DEFAULT_TEST_BASE, apiKey => '1234', endpoint => 'research-outputs' );

isa_ok( $importer, $pkg );
can_ok( $importer, 'each' );
can_ok( $importer, 'first' );
can_ok( $importer, 'count' );
# Test invalid arguments
throws_ok {
    $pkg->new(
        base     => 'https://nothing.nowhere/x/x',
        endpoint => 'research-outputs',
        apiKey => '1234',
      )
} qr/Invalid base URL/, "invalid base URL";

throws_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'research-outputs',
        apiKey => '1234',
        timeout  => 'xxx',
      )
} qr/Invalid value for timeout/, "invalid value for timeout";

#bad furl
throws_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'research-outputs',
        apiKey => '1234',
        furl     => 'notfurl'
      )
} qr/Invalid furl/, "invalid value for furl";

lives_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'research-outputs',
        apiKey => '1234',
        furl     => Furl->new
      )
} "furl passed";

my $it;
lives_ok {
    $it = $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'research-outputs',
        apiKey => '1234',
        options  => {
            'source' => {
                'name'  => 'PubMed',
                'value' => [ '19838868', '11017075' ],
            },
        }
      )
} 'setting of options 1';

lives_ok {
    $it = $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'research-outputs',
        apiKey   => '1234',
        options  => {
            offset => 1000,
        }
      )
} 'setting of options 2';

if ( $ENV{RELEASE_TESTING} ) {
############# everything below needs a Pure server

    #Test get results
    my $rec = eval { $pkg->new( %connect_args, endpoint => 'research-outputs' )->first };
    ok( !$@ && $rec, "get results" )
      or BAIL_OUT "Failed to get any results from base URL $connect_args{base}"
      . ( $connect_args{user} ? "(user=$connect_args{user})" : '' );
    
    my %bad_base = %connect_args;
    $bad_base{base} .= '/invalid/invalid';
    
    throws_ok { $pkg->new( %bad_base, endpoint => 'persons' )->first }
    qr/HTTP 404 Not Found/, "invalid base path";

    throws_ok {
        $pkg->new(
            %connect_args,
            apiKey => 'wrong key',
            endpoint => 'research-outputs',
          )->first
    } qr/Status code: 401/, "invalid API key";
    
    #Check REST errors
    throws_ok { $pkg->new( %connect_args, endpoint => '_nothing_' )->first }
    qr/Pure REST Error/, "invalid endpoint";
    
    throws_ok {
        $pkg->new(
            %connect_args,
            endpoint => 'research-outputs',
            options  => { 'size' => 'a10' }
          )->first
    } qr/Pure REST Error/, "invalid option";
    
    
    #Test handlers
    $rec = $pkg->new(
        %connect_args,
        handler  => 'raw',
        endpoint => 'research-outputs',
        options  => { 'size' => 1 }
    )->first;
    
    like( $rec, qr/^</, "raw handler" );
    
    $rec = $pkg->new(
        %connect_args,
        handler  => 'struct',
        endpoint => 'persons',
        options  => { 'size' => 1 }
    )->first;
    
    ok( $rec->[0] && $rec->[0] eq 'person', 'struct handler' );
    
    $rec = $pkg->new(
        %connect_args,
        handler  => sub { 'success' },
        endpoint => 'research-outputs',
        options  => { 'size' => 1 }
    )->first;
    
    is( $rec, 'success', "custom handler" );
    
    #Test empty response
    my $count = $pkg->new(
        %connect_args,
        endpoint => 'research-outputs',
        options  => { q => 'sdfkjasewrwe' }
    )->count;
    
    is( $count, 0, "empty results" );
    
    $count = $pkg->new(
        %connect_args,
        endpoint     => 'organisational-units',
        fullResponse => 1,
        options      => { 'offset' => 1, 'size' => 2 }
    )->count;
    
    is( $count, 1, 'full response with offset and size' );
    
    $count = $pkg->new(
        %connect_args,
        endpoint     => 'organisational-units',
        fullResponse => 1,
        options      => { 'size' => 0 }
    )->first->{result}[0]{count};
    ok( $count > 1, 'count organisations' );
    
    my $offset = $count - 5;
    my $pcount = $pkg->new(
        %connect_args,
        endpoint => 'organisational-units',
        options  => { offset => $offset }
    )->count;

    ok( $count == $pcount + $offset, 'get organisational-units from offset' );
    
    $rec = $pkg->new( %connect_args, endpoint => 'classification-schemes' )->first;
    ok( $rec->{classificationScheme}, 'endpoint classification-schemes' );
    
    $rec = $pkg->new(
        %connect_args,
        endpoint => 'changes',
        path  => '2002-01-22',
    )->slice( 100, 1 )->first;
    ok( $rec->{contentChange}, 'endpoint changes' );
}

done_testing;
