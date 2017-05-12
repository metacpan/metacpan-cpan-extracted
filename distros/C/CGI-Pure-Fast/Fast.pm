package CGI::Pure::Fast;

# Pragmas.
use base qw(CGI::Pure);
use strict;
use warnings;

# Modules.
use FCGI;
use Readonly;

# Constants.
Readonly::Scalar my $FCGI_LISTEN_QUEUE_DEFAULT => 100;

# Version.
our $VERSION = 0.06;

# External request.
our $EXT_REQUEST;

# Workaround for known bug in libfcgi.
while (each %ENV) { }

# Constructor.
sub new {
	my ($class, @params) = @_;
	if (! defined $EXT_REQUEST) {
		if ($ENV{'FCGI_SOCKET_PATH'}) {
			my $path = $ENV{'FCGI_SOCKET_PATH'};
			my $backlog = $ENV{'FCGI_LISTEN_QUEUE'}
				|| $FCGI_LISTEN_QUEUE_DEFAULT;
			my $socket  = FCGI::OpenSocket($path, $backlog);
			$EXT_REQUEST = FCGI::Request(\*STDIN, \*STDOUT,
				\*STDERR, \%ENV, $socket, 1);
		} else {
			$EXT_REQUEST = FCGI::Request;
		}
	}
	if ($EXT_REQUEST->Accept < 0) {
		return;
	}
	return $class->SUPER::new(@params);
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

CGI::Pure::Fast - Fast Common Gateway Interface Class for CGI::Pure.

=head1 SYNOPSIS

 use CGI::Pure::Fast;
 my $cgi = CGI::Pure::Fast->new(%parameters);
 $cgi->append_param('par', 'value');
 my @par_value = $cgi->param('par');
 $cgi->delete_param('par');
 $cgi->delete_all_params;
 my $query_string = $cgi->query_string;
 $cgi->upload('filename', '~/filename');
 my $mime = $cgi->upload_info('filename', 'mime');
 my $query_data = $cgi->query_data;

=head1 METHODS

=over 8

=item C<new(%parameters)>

 Constructor.
 Extends CGI::Pure for FCGI.

=back

 Other methods are same as CGI::Pure.

=head1 EXAMPLE

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use CGI::Pure::Fast;
 use HTTP::Headers;

 # HTTP header.
 my $header = HTTP::Headers->new;
 $header->header('Content-Type' => 'text/html');

 # FCGI script.
 my $count = 1;
 while (my $cgi = CGI::Pure::Fast->new) {
         print $header->as_string."\n";
         print $count++."\n";
 }

 # Output in CGI mode:
 # Content-Type: text/html
 # 
 # 1
 # ...
 # Content-Type: text/html
 # 
 # 1
 # ...

 # Output in FASTCGI mode:
 # Content-Type: text/html
 # 
 # 1
 # ...
 # Content-Type: text/html
 # 
 # 2
 # ...

=head1 DEPENDENCIES

L<CGI::Pure>,
L<FCGI>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<CGI::Pure>

Common Gateway Interface Class.

=item L<CGI::Pure::Save>

Common Gateway Interface Class for loading/saving object in file.

=back

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2011-2015 Michal Špaček
 BSD 2-Clause License

=head1 VERSION

0.06

=cut
