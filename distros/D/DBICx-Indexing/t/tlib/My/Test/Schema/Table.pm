package My::Test::Schema::Table;
our $VERSION = '0.002';

use strict;
use warnings;
use base 'DBIx::Class::ResultSource';

__PACKAGE__->load_components('+DBICx::Indexing', 'Core');
__PACKAGE__->table('table');

for my $col (qw( a b c d e f g )) {
  __PACKAGE__->add_column($col => {data_type => 'integer'});
}

__PACKAGE__->set_primary_key(qw(a b c));
__PACKAGE__->add_unique_constraint(un => [qw( d )],);

__PACKAGE__->indices(
  idx1 => 'a',
  idx2 => ['a', 'c'],
  idx3 => ['d', 'a'],
  idx4 => ['e', 'f'],
);

sub sqlt_deploy_hook {
  my $self = shift;
  my ($table) = @_;
  
  $table->add_index(
    name   => 'ix',
    fields => [qw(e f)],
  );

  $self->next::method(@_) if $self->next::can;
}

1;
