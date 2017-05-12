package App::Midgen::Role::AttributesX;

use Types::Standard qw( InstanceOf );
use Moo::Role;
use MetaCPAN::Client;
use Perl::PrereqScanner;

# Load time and dependencies negate execution time
# use namespace::clean -except => 'meta';

our $VERSION = '0.34';
$VERSION = eval $VERSION; ## no critic

use Carp;

#######
# some encapsulated -> attributes
#######

has 'mcpan' => (
	is      => 'ro',
	isa     => InstanceOf [ 'MetaCPAN::Client', ],
	lazy    => 1,
	builder => '_build_mcpan',
	handles => [qw( distribution module )],
);

sub _build_mcpan {
	my $self = shift;
	return MetaCPAN::Client->new();
}

has 'scanner' => (
	is      => 'ro',
	isa     => InstanceOf [ 'Perl::PrereqScanner', ],
	lazy    => 1,
	builder => '_build_scanner',
	handles => [qw( scan_ppi_document )],
);

sub _build_scanner {
	my $self = shift;
	return Perl::PrereqScanner->new();
}

no Moo::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Midgen::Role::AttributesX - Package Attributes used by L<App::Midgen>

=head1 VERSION

version: 0.34

=head1 METHODS

none as such, but we do have

=head2 ACCESSORS

=over 4

=item * mcpan

accessor to MetaCPAN::Clinet object

=item * scanner

accessor to Perl::PrereqScanner object

=back

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
