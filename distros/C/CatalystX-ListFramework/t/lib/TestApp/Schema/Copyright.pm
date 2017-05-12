package TestApp::Schema::Copyright;
use strict;
use warnings;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('copyright');
__PACKAGE__->add_columns(
                            'id',
                            'rights_owner',
                            'copyright_year',
                        );
__PACKAGE__->set_primary_key('id');

package TestApp::Model::TestModel::Copyright;
use overload '""' => sub { # for when selecting us from a dropdown
      my $self = shift;
      return $self->id . ' : ' . $self->rights_owner . ' ' . $self->copyright_year;
  }, fallback => 1;


1;
