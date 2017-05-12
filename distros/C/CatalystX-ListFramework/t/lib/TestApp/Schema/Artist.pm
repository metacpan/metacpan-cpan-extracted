package TestApp::Schema::Artist;
use strict;
use warnings;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('artists');
__PACKAGE__->add_columns(
                            'id',
                            'artist_fname',
                            'artist_sname',
                            'artist_pseudonym',
                            'born',
                        );
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many(albums => 'TestApp::Schema::Album', {'foreign.artist' => 'self.id'});

package TestApp::Model::TestModel::Artist;
use overload '""' => sub { # for when selecting us from a dropdown
      my $self = shift;
      return $self->id . ' : ' . $self->artist_fname . ' ' . $self->artist_sname . ' (AKA '.$self->artist_pseudonym.')';
  }, fallback => 1;


1;
