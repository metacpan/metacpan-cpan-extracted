use Test::More tests => 7;
use Config::YAML::Tiny;

my $c = Config::YAML::Tiny->new( config => 't/test.yaml' );
is( $c->{clobber},   1, "This should always work if the previous tests did" );
is( $c->get_clobber, 1, "OO value retreival works" );
$c->set_clobber(5);
is( $c->get_clobber, 5, "OO value specification works" );

my $media = $c->get_media;
is( $media->[1], 'ogg', "get_ting data structures works" );

my @newmedia = qw(oil stucco acrylics latex);
$c->set_media( \@newmedia );
is( $c->{media}[1], 'stucco', "set_ting data structures works" );

$c->set_fnord(42);
is( $c->get_fnord,  42,    "creating new attribs works" );
is( $c->get_splort, undef, "getting nonexistent attribs returns undef" );
