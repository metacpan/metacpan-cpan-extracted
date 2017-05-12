package App::CLI::Extension::Component::ErrorHandler;

=pod

=head1 NAME

App::CLI::Extension::Component::ErrorHandler - for App::CLI::Extension error module

=head1 VERSION

1.421

=cut

use strict;
use App::CLI::Extension::Exception;
use Error;

our $VERSION  = '1.421';

sub throw {

	my($self, $message) = @_;
	Error::throw App::CLI::Extension::Exception $message;
}

1;

__END__

=head1 SEE ALSO

L<App::CLI::Extension>

=head1 AUTHOR

Akira Horimoto

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Copyright (C) 2010 Akira Horimoto

=cut
