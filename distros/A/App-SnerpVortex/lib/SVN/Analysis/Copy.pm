package SVN::Analysis::Copy;
BEGIN {
  $SVN::Analysis::Copy::VERSION = '1.000';
}
use Moose;

use Carp qw(croak);

has src_path  => ( is => 'ro', isa => 'Str', required => 1 );
has kind      => ( is => 'ro', isa => 'Str', required => 1 );

has src_rev => (
	is      => 'ro',
	isa     => 'Int',
	lazy    => 1,
	default => sub { croak "src_rev not defined" },
);

has seq => (
	is      => 'ro',
	isa     => 'Int',
	lazy    => 1,
	default => sub { croak "seq not defined" },
);

has dst_path => (
	is      => 'ro',
	isa     => 'Str',
	lazy    => 1,
	default => sub { croak "dst_path not defined" },
);

has dst_rev => (
	is      => 'ro',
	isa     => 'Int',
	lazy    => 1,
	default => sub { croak "dst_rev not defined" },
);

1;
