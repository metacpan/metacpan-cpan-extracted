package TestApp::Schema::Album;
use strict;
use warnings;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('albums');
__PACKAGE__->add_columns(
                            'id',
                            'title',
                            'artist',
                            'recorded',
                        );
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many(tracks => 'TestApp::Schema::Track', {'foreign.album' => 'self.id'});
__PACKAGE__->belongs_to(artist => 'TestApp::Schema::Artist');

package TestApp::Model::TestModel::Album;
use overload '""' => sub { # for when selecting us from a dropdown
      my $self = shift;
      return $self->id . ' : ' . $self->title . ' by ' . $self->artist;
  }, fallback => 1;


1;
