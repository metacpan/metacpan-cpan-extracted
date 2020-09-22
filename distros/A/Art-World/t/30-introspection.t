use Test::More;
SKIP: {
    ok "Not implemented";
# use Data::Dump::Tree;
# use Art::Agent::Artist;


# my @art = <
#    '59d508e0c692281a381f044a'
#    '59d5094bc692281a381f044b'
#    '59dceb4f3a6416790eaf2036'
# >;

# ddt @art;

# my $artist = Art::Agent::Artist.new(
#     name => 'Seb Hu-Rillettes',
#     artworks => @art
# );

# ddt $artist;

# say $artist.^attributes;
# say $artist.^methods;

# can-ok $artist, 'introspect-attributes';

# my @attributes = $artist.introspect-attributes;

# # Check it don't contain an "Attribute" type and no sigils
# for @attributes -> $attribute {
#     isa-ok $attribute, Str;
#     ok $attribute !~~ m/ [ '$' || '@' || '!' ]  /,
#     'Regexp returned only attributes names';
#     say $attribute;
# }

# # See https://framagit.org/smonff/art-world/issues/10
# my @crud-attributes = $artist.introspect-crud-attributes;

# nok @crud-attributes.contains('database'),
# 'introspect-attributes() return bad types';
}

done_testing;
