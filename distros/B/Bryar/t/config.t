use Test::More 'no_plan';
use_ok("Bryar::Config");

# Test constructor
my $object = Bryar::Config->new();
isa_ok($object, "Bryar::Config");
# Do all data members have the right value?


is_deeply($object->{source},  "Bryar::DataSource::FlatFile", 
    "Constructor set \$object->{source} OK");


is_deeply($object->{frontend},  "Bryar::Frontend::CGI", 
    "Constructor set \$object->{frontend} OK");


is_deeply($object->{name},  "My web log", 
    "Constructor set \$object->{name} OK");

is( $object->description, "Put a better description here" );
diag( $object->collector() );
diag( $object->recent() );

is_deeply($object->{baseurl}, '', 
    "Constructor set \$object->{baseurl} OK");


is_deeply($object->{datadir},  ".",
    "Constructor set \$object->{datadir} OK");


is_deeply($object->{depth},  1, 
    "Constructor set \$object->{depth} OK");


is_deeply($object->{renderer},  "Bryar::Renderer::TT", 
    "Constructor set \$object->{renderer} OK");


# Test the renderer accessor
{
my $stuff = $object->renderer();
is_deeply($stuff,  "Bryar::Renderer::TT", 
    q{renderer initially returns  "Bryar::Renderer::TT"});
}
# Test the frontend accessor
{
my $stuff = $object->frontend();
is_deeply($stuff,  "Bryar::Frontend::CGI", 
    q{frontend initially returns  "Bryar::Frontend::CGI"});
}
# Test the source accessor
{
my $stuff = $object->source();
is_deeply($stuff,  "Bryar::DataSource::FlatFile", 
    q{source initially returns  "Bryar::DataSource::FlatFile"});
}
# Test the datadir accessor
{
my $stuff = $object->datadir();
is_deeply($stuff,  ".",
    q{datadir initially returns  "."});
}
# Test the name accessor
{
my $stuff = $object->name();
is_deeply($stuff,  "My web log", 
    q{name initially returns  "My web log"});
}
# Test the depth accessor
{
my $stuff = $object->depth();
is_deeply($stuff,  1, 
    q{depth initially returns  1});
}
# Test the baseurl accessor
{
my $stuff = $object->baseurl();
is_deeply($stuff, '',
    q{baseurl initially returns undef});
}
# Test the load method exists
ok($object->can("load"), "We can call load");

