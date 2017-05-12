package SVN::Analysis::Dir;
BEGIN {
  $SVN::Analysis::Dir::VERSION = '1.000';
}
use Moose;

has seq           => ( is => 'ro', isa => 'Int', required => 1 );
has ent_name      => ( is => 'ro', isa => 'Maybe[Str]' );
has ent_type      => ( is => 'ro', isa => 'Maybe[Str]' );
has is_active     => ( is => 'ro', isa => 'Bool' );
has is_add        => ( is => 'ro', isa => 'Bool', required => 1 );
has is_copy       => ( is => 'ro', isa => 'Bool', required => 1 );
has is_modified   => ( is => 'ro', isa => 'Bool' );
has op_first      => ( is => 'ro', isa => 'Str' );
has op_last       => ( is => 'ro', isa => 'Str' );
has path          => ( is => 'ro', isa => 'Str', required => 1 );
has path_lop      => ( is => 'ro', isa => 'Maybe[Str]' );
has path_prepend  => ( is => 'ro', isa => 'Maybe[Str]' );
has rel_path      => ( is => 'ro', isa => 'Maybe[Str]' );
has rev_first     => ( is => 'ro', isa => 'Int' );
has revision      => ( is => 'ro', isa => 'Int' );
has rev_last      => ( is => 'ro', isa => 'Int' );
has src_path      => ( is => 'ro', isa => 'Maybe[Str]' );
has src_rev       => ( is => 'ro', isa => 'Maybe[Int]' );

has is_entity => (
	is      => 'ro',
	isa     => 'Bool',
	lazy    => 1,
	default => sub {
		my $self = shift;
		return $self->path() eq $self->path_lop();
	},
);

sub fix_path {
	my ($self, $path) = @_;

	my $path_lop = $self->path_lop();
	my $path_prepend = $self->path_prepend();

	$path =~ s!^\Q$path_lop\E(?:/|$)!! if (
		defined $path_lop and length $path_lop
	);

	return($path_prepend . $path) if (
		defined $path_prepend and length $path_prepend
	);

	return $path;
}

1;
