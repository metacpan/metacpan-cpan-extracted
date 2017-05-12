use Test::More 'no_plan';
use_ok("Bryar::Document");

# Test constructor
my $object = Bryar::Document->new();
isa_ok($object, "Bryar::Document");
# Do all data members have the right value?


is_deeply($object->{epoch}, undef, 
    "Constructor set \$object->{epoch} OK");


is_deeply($object->{content}, undef, 
    "Constructor set \$object->{content} OK");


is_deeply($object->{author}, undef, 
    "Constructor set \$object->{author} OK");


is_deeply($object->{category}, undef, 
    "Constructor set \$object->{category} OK");


is_deeply($object->{title}, undef, 
    "Constructor set \$object->{title} OK");


# Test the content accessor
{
my $stuff = $object->content();
is_deeply($stuff, undef, 
    q{content initially returns undef});
}
# Test the title accessor
{
my $stuff = $object->title();
is_deeply($stuff, undef, 
    q{title initially returns undef});
}
# Test the epoch accessor
{
my $stuff = $object->epoch();
is_deeply($stuff, undef, 
    q{epoch initially returns undef});
}
# Test the category accessor
{
my $stuff = $object->category();
is_deeply($stuff, undef, 
    q{category initially returns undef});
}
# Test the author accessor
{
my $stuff = $object->author();
is_deeply($stuff, undef, 
    q{author initially returns undef});
}
# Test the keywords method exists
ok($object->can("keywords"), "We can call keywords");

