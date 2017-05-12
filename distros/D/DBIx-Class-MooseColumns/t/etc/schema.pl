{
  schema_class  => 'TestSchema',
  fixture_sets  => {
    basic => {
      'Artist'  => [
        [ 'artist_id', 'name', 'title', 'phone',  'address',      'birthday',   'initials', 'is_active', 'favourite_color' ],
        [ 1,           'foo',  'Dr',    '123456', 'Some where 1', '2010-06-21', 'DF',       0,           'GREEN'           ],
      ],
    },
  },
}
