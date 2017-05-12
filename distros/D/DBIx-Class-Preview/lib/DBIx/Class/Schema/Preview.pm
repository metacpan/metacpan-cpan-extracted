package DBIx::Class::Schema::Preview;

use warnings;
use strict;

use base qw/DBIx::Class/;

__PACKAGE__->mk_group_accessors( simple => 'preview_active' );

sub source {
    my $self   = shift;
    my $source = $self->next::method(@_);

	if (ref $self && $self->preview_active && $source->can('previewed') && (my $obj = $source->previewed())) {
		$source = $obj;
	}

    return $source;
}

sub unpreviewed {
	my $self = shift;

	my $clone = { (ref $self ? %$self : ()) };
	bless $clone, (ref $self || $self);
	$clone->preview_active(0);
	foreach my $moniker ($self->sources) {
		my $source = $clone->source($moniker);
		my $new = $source->new($source);
		$clone->register_extra_source($moniker => $new);
	}
	$clone->storage->set_schema($clone) if $clone->storage;
	return $clone;
}

# call this to move all dirty rows to the main table
sub publish {
	my $self = shift;

	unless ($self->preview_active) {
		warn 'preview mode not activated, can not publish';
		return;
	}
	my $schema = $self->unpreviewed;

sub with_deferred_fk_checks {
  my ($self, $sub) = @_;


  $sub->();
  $self->dbh->do('SET foreign_key_checks=1');
}

	$schema->txn_do(
		sub {
			$schema->storage->with_deferred_fk_checks(
				sub {
					foreach my $source_name ($schema->sources) {
						my $source = $schema->source($source_name);
						if ($source->can('previewed')) {
							my $original_rs = $schema->resultset($source->source_name);
							my $previewed_rs = $source->previewed->resultset;
							
							my $dirty_previewed_rs = $previewed_rs->search({ dirty => 1, deleted => 0 });
							while (my $dirty_row = $dirty_previewed_rs->next) {
								my $original_row = $original_rs->find($dirty_row->id);
								my %dirty_cols = $dirty_row->get_columns;
								delete $dirty_cols{dirty};
								delete $dirty_cols{deleted};
								
								if ($original_row) {
									$original_row->update(\%dirty_cols);
								} else {
									$original_rs->create(\%dirty_cols);
								}
							}
							$dirty_previewed_rs->update({ dirty => 0 });
							
							my $deleted_previewed_rs = $previewed_rs->search({ deleted => 1 });
							while (my $deleted_row = $deleted_previewed_rs->next) {
								my $original_row = $original_rs->find($deleted_row->id);
								$deleted_row->delete();
								if (defined $original_row) {$original_row->delete;}
							}
						}
					}
				}
			);
		}
	);
}

1;
