package App::Midgen::Role::Options;

use Types::Standard qw( Bool Int );
use Moo::Role;

# Load time and dependencies negate execution time
# use namespace::clean -except => 'meta';

our $VERSION = '0.34';
$VERSION = eval $VERSION; ## no critic

use Carp;

#######
# cmd line options
#######

has 'core' => (
	is       => 'ro',
	isa      => Bool,
	default  => sub {0},
	required => 1,
);

has 'debug' => (
	is       => 'ro',
	isa      => Bool,
	default  => sub {0},
	required => 1,
);

has 'dual_life' => (
	is       => 'ro',
	isa      => Bool,
	default  => sub {0},
	required => 1,
);

has 'experimental' => (
	is       => 'ro',
	isa      => Bool,
	default  => sub {0},
	required => 1,
);

has 'format' => (
	is  => 'ro',
	isa => sub {
		my $format = {
			dsl      => 1,
			mi       => 1,
			mb       => 1,
			eumm     => 1,
			dist     => 1,
			cpanfile => 1,
			metajson => 1,
			infile   => 1
		};
		croak 'not a supported output format' unless defined $format->{ $_[0] };
		return;
	},
	default  => 'dsl',
	required => 1,
);

has 'quiet' => (
	is       => 'ro',
	isa      => Bool,
	default  => sub {0},
	required => 1,
);

has 'verbose' => (
	is       => 'ro',
	isa      => Int,
	default  => sub {1},
	required => 1,
);

has 'zero' => (
	is       => 'ro',
	isa      => Bool,
	default  => sub {0},
	required => 1,
);

around [qw( debug verbose )] => sub {
	my $orig    = shift;
	my $self    = shift;
	my $content = $self->$orig(@_);

	if (   ( $self->quiet == 1 && $self->experimental == 1 )
		|| ( $self->format eq 'infile' ) )
	{
		return 0;
	} else {
		return $content;
	}
};


no Moo::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Midgen::Role::Options - Package Options used by L<App::Midgen>

=head1 VERSION

version: 0.34

=head1 METHODS

none as such, but we do have

=head2 OPTIONS

=over 4

=item * core

=item * debug

=item * dual_life

=item * experimental

=item * format

=item * quiet

=item * verbose

 0 -> off
 1 -> default    # -v
 2 -> show files # -vv

=item * zero

=back

for more info see L<midgen>

=head1 SEE ALSO

L<App::Midgen>,

=head1 AUTHOR

See L<App::Midgen>

=head2 CONTRIBUTORS

See L<App::Midgen>

=head1 COPYRIGHT

See L<App::Midgen>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
