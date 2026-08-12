
use strict;
use warnings;

package Context::Singleton::Exception::Invalid;
$Context::Singleton::Exception::Invalid::VERSION = '1.0.7';
use Exception::Class ( __PACKAGE__ );

sub new {
	my ($self, @params) = @_;

	$self->SUPER::new (error => q (Invalid value), @params);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Context::Singleton::Exception::Invalid - Context::Singleton exception

=head1 DESCRIPTION

This exception is thrown when invalid value is provided

=head1 AUTHOR

Branislav Zahradník <barney.cpan@gmail.com>

=head1 COPYRIGHT AND LICENCE

This module is part of L<Context::Singleton> distribution.

=cut

