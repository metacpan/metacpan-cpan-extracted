package Crop;

our $VERSION = '0.1.27';

=pod

=head1 NAME

Crop - Creazilla on Perl (Crop) Framework

=head1 SYNOPSIS

    use Crop;
    my $config = Crop->C;
    my $server = Crop->S;

=head1 DESCRIPTION

Creazilla on Perl (Crop) is a Perl framework designed to make writing web scripts much easier. It hides the SQL-layer from the programmer and requires no wide experience to write top-level scripts.

Crop implements:

=over 4

=item * Class attributes inheritance

=item * Automatic object synchronization with warehouse

=item * HTTP request routing and parameter parsing

=item * Multiple warehouses of different type at the same time

=item * Role-based access system

=back

Crop has a lightweight, simple, and clear architecture, making changes to Crop itself simple. It uses common Perl syntax, and only generates getters/setters implicitly, making debugging easy.

=head1 INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

=head1 DEPENDENCIES

The following Perl modules are required to use Crop:

=over 4

=item * XML::LibXML

=item * Time::Stamp

=item * Clone

=item * XML::LibXSLT

=item * JSON

=item * CGI::Cookie

=item * CGI::Fast

=back

=head1 METHODS

=head2 C

    my $config = Crop->C;

Returns the configuration data as a hash reference.

=head2 I_can

    $self->I_can(%privileges);

Checks rights. All privileges must be present in the current client rights. Returns true if OK, false otherwise.

=head2 S

    my $server = Crop->S;

Accessor to the Crop::Server. Returns the server object if running, or 'Crop' otherwise.

=head1 CONTRIBUTING

To contribute to Crop, follow these steps:

=over 4

=item 1. Fork the repository on GitHub.

=item 2. Clone your fork locally.

=item 3. Install dependencies using cpan or cpanm.

=item 4. Run tests using make test.

=item 5. Submit a pull request with your changes.

=back

=head1 CHANGELOG

See the README.md for the full changelog.

=head1 SPONSORS

Creazilla on Perl has been sponsored by L<Creazilla.com|https://creazilla.com/>.

=head1 AUTHORS

Euvgenio (Core Developer)

Alex (Contributor)

=head1 COPYRIGHT AND LICENSE

Apache 2.0

=head1 SEE ALSO

L<https://creazilla.com/pages/creazilla-on-perl>
L<https://github.com/alextech7/crop>

=cut

use v5.14;
use warnings;

use Crop::Config;

=begin nd
Method: C ( )
	Get config data.
	
Returns:
	A hash of configuration values:
(start code)
config = {
	install => {
		path => '/home/cz/back/install',
	},
	warehouse => {
		db => {
			main => {
				name => 'cz',
				server => {
					host => 'localhost',
					port => 5432,
				},
				driver => 'Pg',
				role   => {
					admin => {
						login => 'cz_admin',
						pass  => 'secret1',
					},
					user => {
						pass  => 'cz_user',
						login => 'secret2',
					},
				},
			},
		},
		relation => {
			http => 'main',
			item => 'main',
		},
	},
	logLevel  => 'WARNING',
	debug => {
		layer => [
			'APP'
		],
		output => 'On'
	},
};
(end code)
=cut
sub C { Crop::Config->data }

=begin nd
Method: I_can (%privileges)
	Check Rights.
	
	All %privileges must present in current client Rights.
	
Parameters:
	%privileges - hash {READ => 'Crop', ...}
	
Returns:
	true  - if ok
	false - otherwise
=cut
sub I_can {
	my ($self, %priv) = @_;
	
	my $server = $Crop::Server::Server;
	
	$server->rights->ok(%priv);
}

=begin nd
Method: S ()
	Accessor to the <Crop::Server>.
	
	Since an access to database by Server class is imposible if code is not running by FastCGI:
> $self->S->D
	go to replace intermediate class to 'Crop' to get access by this top-level class.

Returns:
	Server object - if is running
	'Crop' string - otherwise

TODO:
	The D() method.
=cut
sub S { $Crop::Server::Server or 'Crop' }

1;
