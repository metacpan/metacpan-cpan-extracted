package SVN::Dump::Change::Copy;
BEGIN {
  $SVN::Dump::Change::Copy::VERSION = '1.000';
}

use Moose;
extends 'SVN::Dump::Change';

has src_path => ( is => 'ro', isa => 'Str', required => 1 );
has src_rev  => ( is => 'ro', isa => 'Int', required => 1 );

has src_analysis  => (
	is      => 'rw',
	isa     => 'SVN::Analysis::Dir',
	handles => {
		# exposed method => Dir method
		src_entity_type   => 'ent_type',
		src_entity_name   => 'ent_name',
		src_is_entity     => 'is_entity',
		src_path_lop      => 'path_lop',
		src_path_prepend  => 'path_prepend',
	},
);

has 'src_rel_path' => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	default => sub {
		my $self = shift;

		my $path = $self->src_path();

		if (length(my $lop = $self->src_path_lop())) {
			$path =~ s!^\Q$lop\E(?:/|$)!! || die "$path doesn't begin with $lop";
		}

		if (length(my $prepend = $self->src_path_prepend())) {
			$path =~ s!^/*!$prepend/!;
		}

		return $path;
	},
);

1;
