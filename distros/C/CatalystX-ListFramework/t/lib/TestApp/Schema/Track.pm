package TestApp::Schema::Track;
use strict;
use warnings;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('tracks');
__PACKAGE__->add_columns(
                            'id',
                            'tracktitle',
                            'tracklength',
                            'fromalbum',
                            'trackcopyright',
                            'tracksales',
                            'trackreleasedate',
                        );
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to(fromalbum => 'TestApp::Schema::Album');
__PACKAGE__->belongs_to(trackcopyright => 'TestApp::Schema::Copyright');

1;
