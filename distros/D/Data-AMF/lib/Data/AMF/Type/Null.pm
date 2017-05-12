package Data::AMF::Type::Null;
use strict;
use warnings;

sub new
{
	my $class = shift;
	my $self = bless { }, $class;
	return $self;
}

1;

__END__

=head1 NAME
 
Data::AMF::Type::NULL

=head1 SYNOPSIS

=head1 AUTHOR

Takuho Yoshizu <seagirl@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
