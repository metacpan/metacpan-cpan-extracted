use Test::More;

if ( not $ENV{RELEASE_TESTING} ) {
    my $msg = 'Author test.  Set $ENV{RELEASE_TESTING} to a true value to run.';
    plan( skip_all => $msg );
}

eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD" if $@;

my @dirs = ( 'lib' );
if (-d '../t/') {       # we are inside t/
    @dirs = ('../lib');
}
else {                  # we are outside t/
    # add ./lib to include path if blib/lib is not there (e.g. we're not
    # run from Build test or the like)
    push @INC, './lib' if not grep { $_ eq 'blib/lib' } @INC;
}

# Don't test Builtin XSD types - they're undocumented on purpose
# Don't test WSDL datatypes - they're undocumented on purpose.
my @files = all_modules( @dirs );
plan tests => scalar @files;
foreach (@files) {
    pod_coverage_ok( $_ ,
    {
        private => [
           qr/^getter$/,
           qr/^setter$/,
           qr/^init$/,
           qr/^bootstrap$/,
           qr/^dl_load_flags$/,
           qr/^newxs_getter$/,
           qr/^newxs_setter$/
           ]
    });
}
