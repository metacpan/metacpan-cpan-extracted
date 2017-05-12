package DBIx::Class::ResultSource::Table::Preview;

use warnings;
use strict;

use Scalar::Util ();
use base qw/DBIx::Class::ResultSource::Table/;

__PACKAGE__->mk_group_accessors( simple => qw/preview_table/ );

sub from { return shift->preview_table }
sub is_preview_source { 1 };

sub resultset {
  my $self = shift;

  my $rs = $self->next::method(@_);
  return ($self->schema->preview_active()) ?
    $rs->search({ 'me.deleted' => 0 }) :
      $rs;
}

1;
