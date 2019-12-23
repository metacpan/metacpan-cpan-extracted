use v5.12;
use strict;
use warnings;

package Data::Validate::CSV::Schema;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Moo;
use Data::Validate::CSV::Types -types;
use PerlX::Maybe;
use namespace::autoclean;

has columns => (
	is        => 'lazy',
	isa       => ArrayRef[Column],
	builder   => sub { [] },
	coerce    => 1,
);

has notes => (
	is        => 'lazy',
	isa       => ArrayRef[Note],
	builder   => sub { [] },
	coerce    => 1,
);

has primary_key => (
	is        => 'ro',
	isa       => ArrayRef->of(Str)->plus_coercions(Str, '[$_]'),
	coerce    => 1,
);

sub new_from_file {
	my $class = shift;
	require Path::Tiny;
	my $file = Path::Tiny::path(@_);
	$class->new_from_json( $file->slurp_utf8 );
}

sub new_from_json {
	my $class = shift;
	my ($str) = @_;
	require JSON::PP;
	$class->new_from_hashref( JSON::PP->new->decode(ref $str ? $$str : $str) );
}

sub new_from_hashref {
	my $class = shift;
	my ($schema) = @_;
	$class->new(
		notes             => $schema->{notes} || [],
		columns           => $schema->{tableSchema}{columns} || [],
		maybe primary_key => $schema->{tableSchema}{primaryKey},
	);
}

sub clone_columns {
	my $self = shift;
	require Storable;
	Storable::dclone($self->columns);
}

1;