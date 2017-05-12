package Bio::SFF::Index;
{
  $Bio::SFF::Index::VERSION = '0.007';
}

use Moo;

has manifest => (
	is => 'ro',
	required => 1,
);

has _offsets => (
	is => 'ro',
	isa => sub { ref($_[0]) eq 'HASH' },
	init_arg => 'offsets',
	required => 1,
);

sub offset_of {
	my ($self, $name) = @_;
	return $self->_offsets->{$name};
}

1;

#ABSTRACT: SFF index object

__END__

=pod

=head1 NAME

Bio::SFF::Index - SFF index object

=head1 VERSION

version 0.007

=head1 DESCRIPTION

This class represents the index of an SFF file.

=head1 METHODS

=head2 manifest()

This returns the (XML) manifest as a bytestring.

=head2 offset_of($name)

This returns the offset of a specific entry in the SFF file.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans, Utrecht University.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
