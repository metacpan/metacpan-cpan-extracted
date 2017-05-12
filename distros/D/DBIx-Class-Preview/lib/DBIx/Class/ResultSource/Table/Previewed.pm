package DBIx::Class::ResultSource::Table::Previewed;

use warnings;
use strict;

use DBIx::Class::ResultSource::Table::Preview;
use base qw/DBIx::Class::ResultSource::Table/;

sub schema {
  my $self = shift;

  if ( @_ && !$self->{schema} ) {    # only fire if we're getting schema set for first time
    my ($schema) = @_;

    my $new_source = DBIx::Class::ResultSource::Table::Preview->new({
			%$self,
			name           => $self->name . "_preview",
			_relationships => Storable::dclone( $self->_relationships ),
		});
    $new_source->add_column('dirty' => { data_type => 'integer', default_value => 0 });
    $new_source->add_column('deleted' => { data_type => 'integer', default_value => 0 });
    $new_source->preview_table($self->from . '_preview');
    my $target_class = $new_source->result_class . '::preview';
    $self->inject_base(
        $target_class => $new_source->result_class
        );
    $new_source->result_class( $target_class );
    $target_class->result_source_instance($new_source)
        if $target_class->can('result_source_instance');

    $new_source->relationship_info($_)->{attrs}{cascade_delete} = 0
			for $new_source->relationships;
    my $new_source_name =
			$self->source_name . '::preview';
    $schema->register_extra_source( $new_source_name => $new_source );
	}
  return $self->next::method(@_);
}

sub previewed {
  my ( $self ) = @_;

  my $schema = $self->schema || die "No schema";
  my $partition =
    $schema->source( $self->source_name . '::preview' );
  return $partition;
}


1;
