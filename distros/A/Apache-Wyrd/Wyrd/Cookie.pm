package Apache::Wyrd::Cookie;
use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized redefine);
our $VERSION = '0.98';
use vars qw(@ISA);

my $have_apr = 1;

if ($ENV{AUTOMATED_TESTING}) {

	#If this is a smoker, the APR method is required.
	use base qw(Apache::Cookie);

} else {

	#set environment variables WYRD_USE_CGI or WYRD_USE_APR
	#to force the use of libapreq or CGI
	my $force_apr = 0;
	my $force_cgi = 0;
	if ($ENV{WYRD_USE_CGI}) {
		$force_cgi = 1;
	}
	if ($ENV{WYRD_USE_APR}) {
		$force_apr = 1;
	}
	
	my $init_error = '';
	if (!$force_cgi) {
		eval('use Apache::Cookie');
		if ($@) {
			$init_error = $@;
			die "$@" if ($force_apr);
		}
	}
	if ($init_error or $force_cgi) {
		eval('use CGI::Cookie');
		die "$@" if ($@);
		$have_apr = 0;
		push @ISA, 'CGI::Cookie';
	} else {
		push @ISA, 'Apache::Cookie';
	}

}

=pod

=head1 NAME

Apache::Wyrd::Cookie - Consistency wrapper for Apache::Cookie and CGI::Cookie

=head1 SYNOPSIS

	use Apache::Wyrd::Cookie;
	#$req is Apache request object
	my $cookie = Apache::Wyrd::Cookie->new(
		$req,
		-name=>'check_cookie',
		-value=>'checking',
		-domain=>$req->hostname,
		-path=>($auth_path || '/')
	);
	$cookie->bake;

	my %cookie = Apache::Wyrd::Cookie->fetch;
	my $g_value = $cookie{'gingerbread'};


=head1 DESCRIPTION

Wrapper for C<Apache::Cookie> or C<CGI:Cookie> cookies. This class is provided
for no other reason than to make the C<new> and C<bake> methods consistent in
their requirements between these modules, which they are not normally.
Otherwise, C<Apache::Wyrd::Cookie> behaves entirely like C<Apache::Cookie> or
C<CGI::Cookie> depending on which is installed and takes the same arguments to
its methods. Please refer to the documentation for those modules.

The normal behavior is to favor C<Apache::Cookie>.  If it is not installed, it
will attempt to use CGI.  Failing both, it will call C<die()>, causing a server
error.  You can force the use of C<Apache::Cookie> or C<CGI::Cookie> by setting
the WYRD_USE_CGI or WYRD_USE_APR environment variables.  If the forced module
fails to load, the module will C<die()>, causing a server error.  Note that
using these environement variables also affects the behavior of
C<Apache::Wyrd::Cookie>.

=cut

sub new {
	my $class = shift;
	my @caller = caller;
	return CGI::Cookie->new(@_) if ($caller[0] eq 'CGI::Cookie');
	my $req = shift;
	my $data = {};
	if ($have_apr) {
		$data = Apache::Cookie->new($req, @_);
	} else {
		$data = CGI::Cookie->new(@_);
		$data->{'_wyrd_req'} = $req;
	}
	bless $data, $class;
	return $data;
}

sub bake {
	my $self = shift;
	return $self->SUPER::bake if ($have_apr);
	my $req = $self->{'_wyrd_req'};
	die('Cannot determine the Apache object.  Perhaps you are attempting to bake a fetched cookie?')
		unless (UNIVERSAL::isa($req, 'Apache'));
	$req->err_headers_out->add("Set-Cookie" => ($self->as_string));
	$req->headers_out->add("Set-Cookie" => ($self->as_string));
}

=pod

=head1 BUGS/CAVEATS/RESERVED METHODS

UNKNOWN

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=item Apache::Cookie

Cookies under Apache

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;