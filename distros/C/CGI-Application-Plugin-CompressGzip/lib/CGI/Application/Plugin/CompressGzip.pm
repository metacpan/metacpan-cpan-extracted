package CGI::Application::Plugin::CompressGzip;
our $VERSION = '1.02';


use 5.006;
use strict;
use warnings;

use CGI::Application 3.21;
use CGI::Compress::Gzip 0.19;

use base qw/Exporter/;

our @EXPORT = qw(
    cgiapp_get_query
);

sub cgiapp_get_query {
    return CGI::Compress::Gzip->new();
}

1;

__END__

=head1 NAME

CGI::Application::Plugin::CompressGzip - Add gzip compression to CGI::Application

=head1 VERSION

version 1.02

=head1 SYNOPSIS

	package My::App;

	use base qw/CGI::Application/;
    use CGI::Application::Plugin::CompressGzip;

	sub some_run_mode {
		my $self = shift;
	    my $query = $self->query;
	}
  
=head1 DESCRIPTION

This plugin automatically enables gzip content encoding in your CGI::Application
program where appropriate. This reduces bandwidth, which is good for your server,
and for your site's responsiveness. You "use" it once in your base class, and
the rest is transparent.

It does its work by overriding cgiapp_get_query, which returns a new
CGI::Compress::Gzip object instead of the default CGI object.

=head1 EXPORTS

=over

=item cgiapp_get_query

	Returns a subclassed CGI object.

=back

=head1 SEE ALSO

L<CGI::Application>, L<CGI::Compress::Gzip>

=head1 AUTHOR

Rhesa Rozendaal E<lt>rhesa@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Rhesa Rozendaal

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut