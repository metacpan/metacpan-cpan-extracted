package CloudHealth::API::Call::UpdateTagsForSingleAsset;
  use Moo;
  use MooX::StrictConstructor;
  use Types::Standard qw/Dict Str ArrayRef Int/;

  our $tags_cons = Dict[key => Str, value => Str];
  our $tag_group_cons = Dict[asset_type => Str, ids => ArrayRef[Int], tags => ArrayRef[$tags_cons]];
  has tag_groups => (is => 'ro', isa => ArrayRef[$tag_group_cons], required => 1);

  sub _body_params { [
    { name => 'tag_groups' },
  ] }
  sub _query_params { [ ] }
  sub _url_params { [ ] }
  sub _method { 'POST' }
  sub _url { 'https://chapi.cloudhealthtech.com/v1/custom_tags' }

1;
