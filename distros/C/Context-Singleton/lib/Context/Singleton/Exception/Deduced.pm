
use strict;
use warnings;

package Context::Singleton::Exception::Deduced;
$Context::Singleton::Exception::Deduced::VERSION = '1.0.9';
use Exception::Class ( __PACKAGE__ );

sub new {
	my ($self, $singleton) = @_;

	$self->SUPER::new (error => qq (Already deduced: $singleton));
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Context::Singleton::Exception::Deduced - Context::Singleton exception

=head1 DESCRIPTION

This exception is thrown when singleton already has a value in current frame.

=head1 AUTHOR

Branislav Zahradník <barney.cpan@gmail.com>

=head1 COPYRIGHT AND LICENCE

This module is part of L<Context::Singleton> distribution.

=cut

