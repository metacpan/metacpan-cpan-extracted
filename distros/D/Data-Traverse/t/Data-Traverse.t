use Test::More tests => 5;

# load module
BEGIN { use_ok('Data::Traverse', 'traverse'), };

# basic traverse
my $struct = [ 2, 3, { foo => 4 }, [ 5, [ 6, { bar => 7, baz => 8, quux => [ { foo => 1 }, { foo => 2 } ] } ] ] ];

my @types;

traverse { push @types, $_ } $struct;

is_deeply( \@types, [ 'ARRAY', 'ARRAY', 'HASH', 'ARRAY', 'ARRAY', 'HASH', 'HASH', 'HASH', 'HASH' ] );

# fail on regex ref
my $struct2 = [ 1, 2, 3, qr/foobar/, 5 ];

eval { 
    traverse { $_ } $struct2;
};

like( $@, qr/unsupported type/ );

# try some objects
my $objs = [ (bless [ 42 ], 'A::Class'),
             { foo => 'bar' },
             (bless { narf => 'blatz' }, 'A::Class') ];

my @obj_types;
traverse { push @obj_types, $_ } $objs;
is_deeply( \@obj_types, [ 'ARRAY', 'HASH', 'HASH' ] );

# try ignoring regex refs
Data::Traverse->ignore_unsupported_refs( 1 );

my @foo;
traverse { push @foo, $_ } $struct2;

ok( @foo == 4 );
