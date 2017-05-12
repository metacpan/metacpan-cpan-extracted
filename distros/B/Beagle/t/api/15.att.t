use Test::More;
use Beagle::Model::Attachment;

my $att = Beagle::Model::Attachment->new();

isa_ok( $att, 'Beagle::Model::Attachment' );

for my $attr (qw/root path parent_id name is_raw content_file mime_type/) {
    can_ok( $att, $attr );
}

for my $method (qw/serialize type full_path size content/) {
    can_ok( $att, $method );
}

done_testing();
