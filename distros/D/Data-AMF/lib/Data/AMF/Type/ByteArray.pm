package Data::AMF::Type::ByteArray;
use strict;
use warnings;

sub new
{
	my $class = shift;
	my $self = bless { data => $_[0] }, $class;
	return $self;
}

sub data
{
	my $self = shift;
	
	if(@_)
	{
		$self->{'data'} = $_[0];
	}
	
	return $self->{'data'};
}

1;

__END__

=head1 NAME
 
Data::AMF::Type::ByteArray

=head1 SYNOPSIS

=head1 AUTHOR

Takuho Yoshizu <seagirl@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
