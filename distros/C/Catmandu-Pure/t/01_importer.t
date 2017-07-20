use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Importer::Pure';
    use_ok $pkg or BAIL_OUT "Can't load $pkg";
}

my $DEFAULT_TEST_BASE = 'http://experts-us.demo.atira.dk/ws/rest';

my $base_url = $ENV{PURE_BASE};
my $user     = $ENV{PURE_USER};
my $password = $ENV{PURE_PASSWORD};

if ( !$base_url ) {
    $base_url = $DEFAULT_TEST_BASE;

    # note "Using default base '$base_url' for testing. This can be changed by
    # setting the environment variable PURE_BASE, and also if needed PURE_USER
    # and PURE_PASSWORD.";
}

my %connect_args = (
    base     => $base_url,
    user     => $user,
    password => $password,
);

throws_ok { $pkg->new( endpoint => 'publication' ) }
qr/Base URL and endpoint are required/, "required argument (base) missing";

throws_ok { $pkg->new( base => $DEFAULT_TEST_BASE ) }
qr/Base URL and endpoint are required/, "required argument (endpoint) missing";

lives_ok { $pkg->new( base => $DEFAULT_TEST_BASE, endpoint => 'publication' ) }
"required arguments supplied";

throws_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'publication',
        user     => 'user'
      )
} qr/Password is needed/, "password missing";

lives_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'publication',
        user     => 'user',
        password => 'password'
      )
} "user,password provided";

throws_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'publication',
        filter   => 'invalid'
      )
} qr/Invalid filter/, "invalid filter";

lives_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'publication',
        filter   => sub { 1 }
      )
} "filter provided";

lives_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'person',
        timeout  => 100
      )
} "timeout provided";

throws_ok {
    $pkg->new(
        base     => 'notvalid',
        endpoint => 'publication',
      )
} qr/Invalid base/, "invalid base";

lives_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'publication',
        options  => { 'window.size' => 1 },
      )
} "options";

lives_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'publication',
        handler  => 'raw'
      )
} "handler raw";

lives_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'publication',
        handler  => 'simple'
      )
} "handler simple";

lives_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'publication',
        handler  => 'struct'
      )
} "handler struct";

throws_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'publication',
        handler  => 'wrong'
      )
} qr/Unable to load handler/, "missing handler";

throws_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'publication',
        handler  => 12345
      )
} qr/Invalid handler/, "invalid handler - number";

throws_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'publication',
        handler  => [ 0, 5 ],
      )
} qr/Invalid handler/, "invalid handler - array";

lives_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'publication',
        handler  => sub { $_[0] }
      )
} "handler custom";

lives_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'publication',
        handler  => Catmandu::Importer::Pure::Parser::raw->new,
      )
} "handler class invocant";

lives_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'publication',
        handler  => '+Catmandu::Importer::Pure::Parser::raw',
      )
} "handler class";

lives_ok {
    $pkg->new(
        base      => $DEFAULT_TEST_BASE,
        endpoint  => 'publication',
        trim_text => 1,
      )
} "trim text";

my $importer =
  $pkg->new( base => $DEFAULT_TEST_BASE, endpoint => 'publication' );

isa_ok( $importer, $pkg );
can_ok( $importer, 'each' );
can_ok( $importer, 'first' );
can_ok( $importer, 'count' );
# Test invalid arguments
throws_ok {
    $pkg->new(
        base     => 'https://nothing.nowhere/x/x',
        endpoint => 'publication'
      )
} qr/Invalid base URL/, "invalid base URL";

throws_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'publication',
        timeout  => 'xxx'
      )
} qr/Invalid value for timeout/, "invalid value for timeout";

#bad furl
throws_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'publication',
        furl     => 'notfurl'
      )
} qr/Invalid furl/, "invalid value for furl";

lives_ok {
    $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'publication',
        furl     => Furl->new
      )
} "furl passed";

my $it;
lives_ok {
    $it = $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'publication',
        options  => {
            'source' => {
                'name'  => 'PubMed',
                'value' => [ '19838868', '11017075' ],
            },
        }
      )
} 'setting of options 1';

is_deeply(
    $it->options,
    {
        'source.name'  => 'PubMed',
        'source.value' => '19838868,11017075'
    },
    'flatting of options - list'
);

is(
    $it->url,
"$DEFAULT_TEST_BASE/publication?source.name=PubMed&source.value=19838868,11017075",
    "URL method"
);

lives_ok {
    $it = $pkg->new(
        base     => $DEFAULT_TEST_BASE,
        endpoint => 'publication',
        options  => {
            workflowStates => {
                workflowState => [
                    { '' => 'approved',  workflowName => 'publication' },
                    { '' => 'validated', workflowName => 'publication' },
                ]
            }
        }
      )
} 'setting of options 1';

is_deeply(
    $it->options,
    {
        'workflowStates.workflowState[0]'              => 'approved',
        'workflowStates.workflowState[0].workflowName' => 'publication',
        'workflowStates.workflowState[1]'              => 'validated',
        'workflowStates.workflowState[1].workflowName' => 'publication',
    },
    'flatting of options - workflow array'
);

if ( $ENV{RELEASE_TESTING} ) {
############# everything below needs a Pure server

    #Test get results
    my $rec = eval { $pkg->new( %connect_args, endpoint => 'publication' )->first };
    ok( !$@ && $rec, "get results" )
      or BAIL_OUT "Failed to get any results from base URL $connect_args{base}"
      . ( $connect_args{user} ? "(user=$connect_args{user})" : '' );
    
    my %bad_base = %connect_args;
    $bad_base{base} =~ s|/rest|/xrest|;
    
    throws_ok { $pkg->new( %bad_base, endpoint => 'person' )->first }
    qr/Status code: 405/, "invalid base path";
    
    #Check REST errors
    throws_ok { $pkg->new( %connect_args, endpoint => '_nothing_' )->first }
    qr/Pure REST Error/, "invalid endpoint";
    
    throws_ok {
        $pkg->new(
            %connect_args,
            endpoint => 'publication',
            options  => { 'window.size' => 'a10' }
          )->first
    } qr/Pure REST Error/, "invalid option";
    
    throws_ok {
        $pkg->new(
            %connect_args,
            user     => undef,
            password => undef,
            endpoint => 'uploaddownloadinformationrequest.current'
          )->first
    } qr/Pure REST Error/, "Needs authentication";
    
    #Test handlers
    $rec = $pkg->new(
        %connect_args,
        handler  => 'raw',
        endpoint => 'publication',
        options  => { 'window.size' => 1 }
    )->first;
    
    like( $rec, qr/^</, "raw handler" );
    
    $rec = $pkg->new(
        %connect_args,
        handler  => 'struct',
        endpoint => 'publication',
        options  => { 'window.size' => 1 }
    )->first;
    
    ok( $rec->[0] && $rec->[0] eq 'core:content', 'struct handler' );
    
    $rec = $pkg->new(
        %connect_args,
        handler  => sub             { 'success' },
        endpoint => 'publication',
        options  => { 'window.size' => 1 }
    )->first;
    
    is( $rec, 'success', "custom handler" );
    
    #Test empty response
    my $count = $pkg->new(
        %connect_args,
        endpoint => 'publication',
        options  => { searchString => '(sdfkjasewrwe)' }
    )->count;
    
    is( $count, 0, "empty results" );
    
    $count = $pkg->new(
        %connect_args,
        endpoint     => 'organisation',
        fullResponse => 1,
        options      => { window => { offset => 1, 'size' => 2 } }
    )->count;
    
    is( $count, 1, 'full response with window offset and size' );
    
    # organizationCount
    $count = $pkg->new(
        %connect_args,
        endpoint     => 'organisation',
        fullResponse => 1,
        options      => { 'window.size' => 0 }
    )->first->{GetOrganisationResponse}[0]{count};
    ok( $count > 1, 'count organizations' );
    
    my $offset = $count - 5;
    my $pcount = $pkg->new(
        %connect_args,
        endpoint => 'organisation',
        options  => { window => { offset => $offset } }
    )->count;
    ok( $count == $pcount + $offset, 'get organisations from offset' );
    
    $count = $pkg->new(
        %connect_args,
        endpoint     => 'organisation',
        fullResponse => 1,
        options      => { window => { offset => 10, 'size' => 2 } }
    )->count;
    
    is( $count, 1, 'full response with window offset and size' );
    
    $rec = $pkg->new( %connect_args, endpoint => 'allowedfamilies' )->first;
    ok( $rec->{family}, 'endpoint allowedfamilies' );
    
    $rec = $pkg->new(
        %connect_args,
        endpoint => 'organisation',
        options  => { 'window.size' => 1 }
    )->first;    # size
    
    ok( $rec->{content}, 'endpoint organisation' );
    
    $rec = $pkg->new( %connect_args, endpoint => 'classificationschemes' )->first;
    
    ok( $rec->{content}, 'endpoint classificationschemes' );
    
    $rec = $pkg->new(
        %connect_args,
        endpoint => 'changes.current',
        options  => { fromDate => '1990-01-22' }
    )->slice( 100, 1 )->first;
    ok( $rec->{change}, 'endpoint changes.current' );
    
    $rec = $pkg->new( %connect_args, endpoint => 'serverMeta', fullResponse => 1 )
      ->first;
    ok( $rec->{GetServerMetaResponse}, 'endpoint serverMeta' );
    
    #Test filter
    $rec = $pkg->new(
        %connect_args,
        endpoint => 'allowedfamilies',
        filter   => sub { ${ $_[0] } =~ s/family/myfamily/g }
    )->first;
    ok( $rec->{myfamily}, 'endpoint allowedfamilies' );
    
    my $recs = $pkg->new(
        %connect_args,
        endpoint => 'organisation',
        options  => { 'window.size' => 1 }
    )->slice( 0, 2 )->to_array;
    
    ok(
        $recs->[0]{content}
          && $recs->[1]{content}
          && ( $recs->[0]{content}[0]{uuid} ne $recs->[1]{content}[0]{uuid} ),
        'multi-requests'
    );
}

done_testing;
