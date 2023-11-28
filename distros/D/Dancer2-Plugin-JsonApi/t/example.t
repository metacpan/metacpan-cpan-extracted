use 5.32.0;

use Test2::V0;

use Clone qw/ clone /;

use Dancer2::Plugin::JsonApi::Registry;

use experimental qw/ signatures /;

# example taken straight from https://www.npmjs.com/package/json-api-serializer

my $data = [
    {   id      => "1",
        title   => "JSON API paints my bikeshed!",
        body    => "The shortest article. Ever.",
        created => "2015-05-22T14:56:29.000Z",
        updated => "2015-05-22T14:56:28.000Z",
        author  => {
            id        => "1",
            firstName => "Kaley",
            lastName  => "Maggio",
            email     => "Kaley-Maggio\@example.com",
            age       => "80",
            gender    => "male"
        },
        tags   => [ "1", "2" ],
        photos => [
            "ed70cf44-9a34-4878-84e6-0c0e4a450cfe",
            "24ba3666-a593-498c-9f5d-55a4ee08c72e",
            "f386492d-df61-4573-b4e3-54f6f5d08acf"
        ],
        comments => [
            {   _id     => "1",
                body    => "First !",
                created => "2015-08-14T18:42:16.475Z"
            },
            {   _id     => "2",
                body    => "I Like !",
                created => "2015-09-14T18:42:12.475Z"
            },
            {   _id     => "3",
                body    => "Awesome",
                created => "2015-09-15T18:42:12.475Z"
            }
        ]
    }
];

my $registry = Dancer2::Plugin::JsonApi::Registry->new;

$registry->add_type(
    'article',
    {   top_level_meta => sub ( $data, $xtra ) {
            return +{
                count => $xtra->{count},
                total => 0 + @$data,
            };
        },
        top_level_links => { self => '/articles', },
        links           => {
            self => sub ( $data, @ ) {
                return "/articles/" . $data->{id};
            },
        },
        relationships => {
            'tags'     => { type => 'tag' },
            'comments' => { type => 'comment' },
            photos     => { type => 'photo' },
            author     => {
                type  => "people",
                links => sub ( $data, @ ) {
                    return +{
                        self => "/articles/"
                          . $data->{id}
                          . "/relationships/author",
                        related => "/articles/" . $data->{id} . "/author"
                    };
                }
            },
        }
    }
);

$registry->add_type('tag');
$registry->add_type('photo');
$registry->add_type( 'comment',
    { id => '_id', allowed_attributes => ['body'] } );
$registry->add_type(
    'people',
    {   links => sub ( $data, @ ) { +{ self => '/peoples/' . $data->{id} } }
    }
);

my $output = $registry->serialize( 'article', $data, { count => 2 } );

like $output->{data}[0]{relationships}{author},
  { links => {
        "self"    => "/articles/1/relationships/author",
        "related" => "/articles/1/author"
    }
  };

like $output->{data}[0]{relationships}{author},
  { links => {
        "self"    => "/articles/1/relationships/author",
        "related" => "/articles/1/author"
    }
  };

like $output => {
    "jsonapi" => { "version" => "1.0" },
    "meta"    => {
        "count" => 2,
        "total" => 1
    },
    "links" => { "self" => "/articles" },
    "data"  => [
        {   "type"       => "article",
            "id"         => "1",
            "attributes" => {
                "title"   => "JSON API paints my bikeshed!",
                "body"    => "The shortest article. Ever.",
                "created" => "2015-05-22T14:56:29.000Z"
            },
            "relationships" => {
                "author" => {
                    "data" => {
                        "type" => "people",
                        "id"   => "1"
                    },
                    "links" => {
                        "self"    => "/articles/1/relationships/author",
                        "related" => "/articles/1/author"
                    }
                },
                "tags" => {
                    "data" => [
                        {   "type" => "tag",
                            "id"   => "1"
                        },
                        {   "type" => "tag",
                            "id"   => "2"
                        }
                    ]
                },
                "photos" => {
                    "data" => [
                        {   "type" => "photo",
                            "id"   => "ed70cf44-9a34-4878-84e6-0c0e4a450cfe"
                        },
                        {   "type" => "photo",
                            "id"   => "24ba3666-a593-498c-9f5d-55a4ee08c72e"
                        },
                        {   "type" => "photo",
                            "id"   => "f386492d-df61-4573-b4e3-54f6f5d08acf"
                        }
                    ]
                },
                "comments" => {
                    "data" => [
                        {   "type" => "comment",
                            "id"   => "1"
                        },
                        {   "type" => "comment",
                            "id"   => "2"
                        },
                        {   "type" => "comment",
                            "id"   => "3"
                        }
                    ]
                }
            },
            "links" => { "self" => "/articles/1" }
        }
    ],
};

is $output->{included}, bag {
    item($_)
      for (
        {   "type"       => "people",
            "id"         => "1",
            "attributes" => {
                "firstName" => "Kaley",
                "lastName"  => "Maggio",
                "email"     => "Kaley-Maggio\@example.com",
                "age"       => "80",
                "gender"    => "male"
            },
            "links" => { "self" => "/peoples/1" },
        },
        {   "type"       => "comment",
            "id"         => "1",
            "attributes" => { "body" => "First !" }
        },
        {   "type"       => "comment",
            "id"         => "2",
            "attributes" => { "body" => "I Like !" }
        },
        {   "type"       => "comment",
            "id"         => "3",
            "attributes" => { "body" => "Awesome" }
        }
      );
};

subtest 'comments only have the body attribute' => sub {
    for
      my $comment ( grep { $_->{type} eq 'comment' } $output->{included}->@* )
    {
        my @attr = keys $comment->{attributes}->%*;
        is( \@attr => ['body'], "only the body for comments" );
    }
};

subtest 'deserialize' => sub {
    my $roundtrip = $registry->deserialize($output);

    my $expected = clone($data);
    delete $_->{created} for $expected->[0]{comments}->@*;

    like $roundtrip => $expected;
};

done_testing;
