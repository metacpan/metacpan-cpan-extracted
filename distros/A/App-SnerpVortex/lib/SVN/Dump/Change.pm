package SVN::Dump::Change;
BEGIN {
  $SVN::Dump::Change::VERSION = '1.000';
}

use Moose;
use SVN::Analysis::Dir;

has path      => ( is => 'ro', isa => 'Str', required => 1 );
has operation => ( is => 'ro', isa => 'Str' );

has analysis  => (
	is      => 'rw',
	isa     => 'SVN::Analysis::Dir',
	handles => {
		# exposed method => Dir method
		entity_type   => 'ent_type',
		entity_name   => 'ent_name',
		is_entity     => 'is_entity',
		path_lop      => 'path_lop',
		path_prepend  => 'path_prepend',
	},
);

has 'rel_path' => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	default => sub {
		my $self = shift;

		my $path = $self->path();

		if (length(my $lop = $self->path_lop())) {
			$path =~ s!^\Q$lop\E(?:/|$)!! || die "$path doesn't begin with $lop";
		}

		if (length(my $prepend = $self->path_prepend())) {
			$path =~ s!^/*!$prepend/!;
		}

		return $path;
	},
);

1;
