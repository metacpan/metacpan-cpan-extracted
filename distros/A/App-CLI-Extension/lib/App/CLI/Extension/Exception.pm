package App::CLI::Extension::Exception;

=pod

=head1 NAME

App::CLI::Extension::Exception - for App::CLI exception module

=head1 VERSION

1.421

=cut

use strict;
use base qw(Error::Simple);

our $VERSION = '1.421';

sub new {

	my($class, $message) = @_;
	chomp $message;

	#local $Error::Depth = $Error::Depth + 1;
	local $Error::Depth = $Error::Depth + 2;
	local $Error::Debug = 1;
	my $self = $class->SUPER::new($message);

	return $self;
}

1;

__END__

=head1 SEE ALSO

L<App::CLI::Exception> L<Error::Simple>

=head1 AUTHOR

Akira Horimoto

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Copyright (C) 2010 Akira Horimoto

=cut
