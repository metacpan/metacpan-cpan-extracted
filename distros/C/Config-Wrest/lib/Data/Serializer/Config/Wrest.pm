package Data::Serializer::Config::Wrest;
BEGIN { @Data::Serializer::Config::Wrest::ISA = qw(Data::Serializer) }
use strict;
use Config::Wrest;
use vars qw($VERSION @ISA);

$VERSION = sprintf('%d.%03d', q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/);

sub serialize {
	my ($self, $ref) = @_;

	TRACE(__PACKAGE__."::serialize");
	my $o = new Config::Wrest(%{$self->options()});
	return $o->serialize($ref);
}

sub deserialize {
	my ($self, $ref) = @_;

	TRACE(__PACKAGE__."::deserialize");
	my $o = new Config::Wrest(%{$self->options()});
	return $o->deserialize($ref);
}

sub options {
	return (shift)->{options};
}

sub TRACE {}
sub DUMP {}

1;

__END__

=head1 NAME

Data::Serializer::Config::Wrest - Creates bridge between Data::Serializer and Config::Wrest

=head1 SYNOPSIS

	use Data::Serializer;
	my $ser = Data::Serializer->new(
		serializer => 'Config::Wrest',
		options => {
			Escapes => 1,
			UseQuotes => 1,
			WriteWithEquals => 1,
		}
	);
	my $serialized = $ser->serialize({ foo => 'bar' });
	my $deserialized = $ser->deserialize($serialized);

=head1 DESCRIPTION

Module is used internally to Data::Serializer. Use it through the Data::Serializer constructor.

The 'options' hash reference is passed to the Config::Wrest constructor. Please see the documentation
for that module for details about the possible options and the defaults.

=head1 METHODS

=over 4

=item serialize( \%DATA )

For use by Data::Serializer. Serializes the hash reference into a string.

=item deserialize( $STRING )

For use by Data::Serializer. Deserializes the string into a hash reference.

=item options()

Retrieves the constructor options for Config::Wrest.

=back

=head1 CAVEAT

Base data structure to serialize must be a hash reference

=head1 SEE ALSO

L<Data::Serializer>, L<Config::Wrest>

=head1 VERSION

$Revision: 1.2 $ on $Date: 2005/09/23 10:30:23 $ by $Author: piersk $

=head1 AUTHOR

IF&L Software Engineers <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt 

=cut
