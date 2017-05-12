#!/usr/bin/perl

use strict;
use warnings;
use lib qw( t/lib );

use Test::More 'no_plan';
use JSON::XS;

# application loads
BEGIN {
    $ENV{AUTOCRUD_DEBUG} = 1;
    use_ok "Test::WWW::Mechanize::Catalyst" => "TestApp"
}
my $mech = Test::WWW::Mechanize::Catalyst->new;

# get metadata for the album table
$mech->get_ok( '/site/default/schema/dbic/source/album/dumpmeta', 'Get album autocrud metadata' );
is( $mech->ct, 'application/json', 'Metadata content type' );

my $response = JSON::XS::decode_json( $mech->content );

#use Data::Dumper;
#print STDERR Dumper $response;

my $expected_json = <<'END_JSON';
{
  "cpac":{
    "global":{
      "default_sort":"id",
      "frontend":"extjs2",
      "site":"default",
      "db":"dbic",
      "backend":"Model::AutoCRUD::StorageEngine::DBIC",
      "table":"album"
    },
    "conf":{
      "dbic":{
        "backend":"Model::AutoCRUD::StorageEngine::DBIC",
        "hidden":"no",
        "display_name":"Dbic",
        "t":{
          "album":{
            "headings":{
              "tracks":"Tracks",
              "sleeve_notes":"Sleeve Notes",
              "artist_id":"Artist",
              "copyright":"Copyrights",
              "title":"Custom Title",
              "recorded":"Recorded",
              "deleted":"Deleted",
              "id":"Id"
            },
            "display_name":"Album",
            "hidden_cols":{

            },
            "cols":[
              "id",
              "deleted",
              "recorded",
              "title",
              "artist_id",
              "sleeve_notes",
              "tracks",
              "copyright"
            ],
            "create_allowed":"yes",
            "delete_allowed":"yes",
            "update_allowed":"yes",
            "dumpmeta_allowed":"yes",
            "hidden":"no"
          },
          "artist":{
            "headings":{
              "pseudonym":"Pseudonym",
              "forename":"Forename",
              "born":"Born",
              "id":"Id",
              "albums":"Albums",
              "surname":"Surname"
            },
            "display_name":"Artist",
            "cols":[
              "id",
              "born",
              "forename",
              "pseudonym",
              "surname",
              "albums"
            ],
            "create_allowed":"yes",
            "delete_allowed":"yes",
            "update_allowed":"yes",
            "dumpmeta_allowed":"yes",
            "hidden":"no"
          },
          "sleeve_notes":{
            "headings":{
              "album_id":"Album",
              "text":"Custom Text",
              "id":"Id"
            },
            "display_name":"Sleeve Notes",
            "cols":[
              "id",
              "text",
              "album_id"
            ],
            "create_allowed":"yes",
            "delete_allowed":"yes",
            "update_allowed":"yes",
            "dumpmeta_allowed":"yes",
            "hidden":"no"
          },
          "track":{
            "headings":{
              "length":"Length",
              "parent_album":"Parent Album",
              "sales":"Sales",
              "copyright_id":"Copyright",
              "title":"Title",
              "id":"Id",
              "releasedate":"Releasedate"
            },
            "display_name":"Track",
            "cols":[
              "id",
              "length",
              "releasedate",
              "sales",
              "title",
              "copyright_id",
              "parent_album"
            ],
            "create_allowed":"yes",
            "delete_allowed":"yes",
            "update_allowed":"yes",
            "dumpmeta_allowed":"yes",
            "hidden":"no"
          },
          "copyright":{
            "headings":{
              "rights owner":"Rights Owner",
              "album":"Albums",
              "tracks":"Tracks",
              "copyright_year":"Copyright Year",
              "id":"Id"
            },
            "display_name":"Copyright",
            "cols":[
              "id",
              "copyright_year",
              "rights owner",
              "tracks",
              "album"
            ],
            "create_allowed":"yes",
            "delete_allowed":"yes",
            "update_allowed":"yes",
            "dumpmeta_allowed":"yes",
            "hidden":"no"
          }
        }
      }
    },
    "meta":{
      "display_name":"Test App Schema V 1 X",
      "t":{
        "artist":{
          "pks":[
            "id"
          ],
          "fields":[
            "id",
            "born",
            "forename",
            "pseudonym",
            "surname",
            "albums"
          ],
          "model":"AutoCRUD::DBIC::Artist",
          "f":{
            "pseudonym":{
              "extjs_xtype":"textarea",
              "display_name":"Pseudonym"
            },
            "forename":{
              "extjs_xtype":"textarea",
              "display_name":"Forename"
            },
            "id":{
              "extjs_xtype":"numberfield",
              "display_name":"Id"
            },
            "born":{
              "extjs_xtype":"datefield",
              "display_name":"Born"
            },
            "albums":{
              "ref_fields":[
                "artist_id"
              ],
              "fields":[
                "id"
              ],
              "extjs_xtype":"textfield",
              "is_reverse":"1",
              "display_name":"Albums",
              "ref_table":"album",
              "rel_type":"has_many"
            },
            "surname":{
              "extjs_xtype":"textarea",
              "display_name":"Surname"
            }
          },
          "display_name":"Artist"
        },
        "album":{
          "pks":[
            "id"
          ],
          "fields":[
            "id",
            "deleted",
            "recorded",
            "title",
            "artist_id",
            "sleeve_notes",
            "tracks",
            "copyright"
          ],
          "model":"AutoCRUD::DBIC::Album",
          "f":{
            "sleeve_notes":{
              "ref_fields":[
                "album_id"
              ],
              "fields":[
                "id"
              ],
              "extjs_xtype":"textfield",
              "is_reverse":"1",
              "display_name":"Sleeve Notes",
              "ref_table":"sleeve_notes",
              "rel_type":"might_have"
            },
            "tracks":{
              "ref_fields":[
                "album_id"
              ],
              "fields":[
                "id"
              ],
              "extjs_xtype":"textfield",
              "is_reverse":"1",
              "display_name":"Tracks",
              "ref_table":"track",
              "rel_type":"has_many"
            },
            "copyright":{
              "via":[
                "tracks",
                "copyright_id"
              ],
              "extjs_xtype":"textfield",
              "is_reverse":"1",
              "display_name":"Copyrights",
              "rel_type":"many_to_many"
            },
            "deleted":{
              "extjs_xtype":"checkbox",
              "display_name":"Deleted"
            },
            "artist_id":{
              "ref_fields":[
                "id"
              ],
              "fields":[
                "artist_id"
              ],
              "extjs_xtype":"numberfield",
              "rel_type":"belongs_to",
              "ref_table":"artist",
              "display_name":"Artist"
            },
            "recorded":{
              "extjs_xtype":"datefield",
              "display_name":"Recorded"
            },
            "title":{
              "extjs_xtype":"textarea",
              "display_name":"Custom Title"
            },
            "id":{
              "extjs_xtype":"numberfield",
              "display_name":"Id"
            }
          },
          "display_name":"Album"
        },
        "sleeve_notes":{
          "pks":[
            "id"
          ],
          "fields":[
            "id",
            "text",
            "album_id"
          ],
          "model":"AutoCRUD::DBIC::SleeveNotes",
          "f":{
            "album_id":{
              "ref_fields":[
                "id"
              ],
              "fields":[
                "album_id"
              ],
              "extjs_xtype":"numberfield",
              "rel_type":"belongs_to",
              "ref_table":"album",
              "display_name":"Album"
            },
            "text":{
              "extjs_xtype":"textarea",
              "display_name":"Custom Text"
            },
            "id":{
              "extjs_xtype":"numberfield",
              "display_name":"Id"
            }
          },
          "display_name":"Sleeve Notes"
        },
        "track":{
          "pks":[
            "id"
          ],
          "fields":[
            "id",
            "length",
            "releasedate",
            "sales",
            "title",
            "copyright_id",
            "parent_album"
          ],
          "model":"AutoCRUD::DBIC::Track",
          "f":{
            "length":{
              "extjs_xtype":"textarea",
              "display_name":"Length"
            },
            "album_id":{
              "masked_by":"parent_album",
              "extjs_xtype":"numberfield",
              "display_name":"Album Id"
            },
            "sales":{
              "extjs_xtype":"numberfield",
              "display_name":"Sales"
            },
            "parent_album":{
              "ref_fields":[
                "id"
              ],
              "fields":[
                "album_id"
              ],
              "extjs_xtype":"textfield",
              "display_name":"Parent Album",
              "ref_table":"album",
              "rel_type":"belongs_to"
            },
            "copyright_id":{
              "ref_fields":[
                "id"
              ],
              "fields":[
                "copyright_id"
              ],
              "extjs_xtype":"numberfield",
              "rel_type":"belongs_to",
              "ref_table":"copyright",
              "display_name":"Copyright"
            },
            "title":{
              "extjs_xtype":"textarea",
              "display_name":"Title"
            },
            "id":{
              "extjs_xtype":"numberfield",
              "display_name":"Id"
            },
            "releasedate":{
              "extjs_xtype":"datefield",
              "display_name":"Releasedate"
            }
          },
          "display_name":"Track"
        },
        "copyright":{
          "pks":[
            "id"
          ],
          "fields":[
            "id",
            "copyright_year",
            "rights owner",
            "tracks",
            "album"
          ],
          "model":"AutoCRUD::DBIC::Copyright",
          "f":{
            "rights owner":{
              "extjs_xtype":"textarea",
              "display_name":"Rights Owner"
            },
            "album":{
              "via":[
                "tracks",
                "parent_album"
              ],
              "extjs_xtype":"textfield",
              "is_reverse":"1",
              "display_name":"Albums",
              "rel_type":"many_to_many"
            },
            "tracks":{
              "ref_fields":[
                "copyright_id"
              ],
              "fields":[
                "id"
              ],
              "extjs_xtype":"textfield",
              "is_reverse":"1",
              "display_name":"Tracks",
              "ref_table":"track",
              "rel_type":"has_many"
            },
            "copyright_year":{
              "extjs_xtype":"numberfield",
              "display_name":"Copyright Year"
            },
            "id":{
              "extjs_xtype":"numberfield",
              "display_name":"Id"
            }
          },
          "display_name":"Copyright"
        }
      }
    }
  }
}
END_JSON

is_deeply( $response, JSON::XS::decode_json($expected_json), 'Metadata is as we expect' );
#use Data::Dumper;
#print STDERR Dumper [$response, $expected];
#warn $mech->content;
__END__
