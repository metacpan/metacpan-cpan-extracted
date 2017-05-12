#!/usr/bin/perl -I../lib/

use Benchmark qw(:all);
use DTL::Fast qw(get_template);
use Storable qw(freeze thaw);
use Compress::Zlib;

#
# In order to test Dotiac without caching, you need to modify Dotiac::DTL module
# and make %cache variable our instead of my
#
my $context = {
    'var1' => 'This',
    'var2' => 'is',
    'var3' => 'SPARTA',
    'var4' => 'GREEKS',
    'var5' => 'GO HOME!',
    'array1' => [qw( this is a text string as array )],
};

my @params = (
    'root.txt',
    'dirs' => [ './tpl' ]
);

my $tpl;
my $serialized;
my $compressed;

dtl_parse();
dtl_serialize();
dtl_compress();
    
sub dtl_render
{
   $tpl->render($context);
}

sub dtl_serialize
{
    $serialized = freeze($tpl);
}

sub dtl_compress
{
    $compressed = Compress::Zlib::memGzip($serialized);
}

sub dtl_decompress
{
    $serialized = Compress::Zlib::memGunzip($compressed);
}

sub dtl_deserialize
{
    $tpl = thaw($serialized);
}

sub dtl_cache_key
{
    DTL::Fast::_get_cache_key(@params);
}

sub dtl_validate
{
    $DTL::Fast::RUNTIME_CACHE->validate_template($tpl);
}

sub dtl_parse
{
    $tpl = get_template( 
        @params, 
        'no_cache' => 1,
    );
}

print "This is a test for optimisation iterations\n";

timethese( 100000, {
    '1 Cache key  ' => \&dtl_cache_key,
    '2 Decompress ' => \&dtl_decompress,
    '3 Serialize  ' => \&dtl_serialize,
    '4 Deserialize' => \&dtl_deserialize,
    '5 Compress   ' => \&dtl_compress,
    '6 Validate   ' => \&dtl_validate,
});

timethese( 1000, {
    '7 Parse      ' => \&dtl_parse,
    '8 Render     ' => \&dtl_render,
});