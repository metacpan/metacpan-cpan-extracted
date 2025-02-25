package App::CPAN::Get::MetaCPAN;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Cpanel::JSON::XS;
use English;
use Error::Pure qw(err);
use IO::Barf qw(barf);
use LWP::UserAgent;
use Readonly;
use Scalar::Util qw(blessed);
use URI;

Readonly::Scalar our $FASTAPI => qw(https://fastapi.metacpan.org/v1/download_url/);

our $VERSION = 0.14;

sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# LWP::User agent object.
	$self->{'lwp_user_agent'} = undef;

	# Process parameters.
	set_params($self, @params);

	if (defined $self->{'lwp_user_agent'}) {
		if (! blessed($self->{'lwp_user_agent'})
			|| ! $self->{'lwp_user_agent'}->isa('LWP::UserAgent')) {

			err "Parameter 'lwp_user_agent' must be a ".
				'LWP::UserAgent instance.';
		}
	} else {
		$self->{'lwp_user_agent'} = LWP::UserAgent->new;
		$self->{'lwp_user_agent'}->agent(__PACKAGE__.'/'.$VERSION);
	}

	return $self;
}

sub search {
	my ($self, $args_hr) = @_;

	if (! defined $args_hr
		|| ref $args_hr ne 'HASH') {

		err 'Bad search options.';
	}
	if (! exists $args_hr->{'package'}) {
		err "Package doesn't present.";
	}

	my $uri = $self->_construct_uri($args_hr);
	my $content = eval {
		$self->_fetch($uri);
	};
	if ($EVAL_ERROR) {
		if ($EVAL_ERROR =~ m/^Cannot fetch/ms) {
			err "Module '$args_hr->{'package'}' doesn't exist.";
		} else {
			err $EVAL_ERROR;
		}
	}
	my $content_hr = decode_json($content);

	return $content_hr;
}

sub save {
	my ($self, $uri, $file, $opts_hr) = @_;

	my $force = 0;
	if (defined $opts_hr
		&& exists $opts_hr->{'f'}
		&& $opts_hr->{'f'}) {

		$force = 1;
	}

	if (-r $file && ! $force) {
		err "File '$file' exists.";
	}

	my $content = $self->_fetch($uri);

	barf($file, $content);

	return;
}

sub _construct_uri {
	my ($self, $args_hr) = @_;

	my %query = ();
	if ($args_hr->{'include_dev'}) {
		$query{'dev'} = 1;
	}
	if ($args_hr->{'version'}) {
		$query{'version'} = '== '.$args_hr->{'version'};
	} elsif ($args_hr->{'version_range'}) {
		$query{'version'} = $args_hr->{'version_range'};
	}

	my $uri = URI->new($FASTAPI.$args_hr->{'package'});
	$uri->query_form(each %query);

	return $uri->as_string;
}

sub _fetch {
	my ($self, $uri) = @_;

	my $res = $self->{'lwp_user_agent'}->get($uri);
	if (! $res->is_success) {
		my $err_hr = {
			'HTTP code' => $res->code,
			'HTTP message' => $res->message,
		};
		if ($res->is_client_error) {
			err "Cannot fetch '$uri' URI.", %{$err_hr};
		} elsif ($res->is_server_error) {
			err "Cannot connect to CPAN server.", %{$err_hr};
		} else {
			err "Cannot fetch '$uri'.", %{$err_hr};
		}
	}

	return $res->content;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::CPAN::Get::MetaCPAN - Helper class to work with MetaCPAN distribution files.

=head1 SYNOPSIS

 use App::CPAN::Get::MetaCPAN;

 my $obj = App::CPAN::Get::MetaCPAN->new(%params);
 my $content_hr = $obj->search($args_hr);
 $obj->save($uri, $file);

=head1 METHODS

=head2 C<new>

 my $obj = App::CPAN::Get::MetaCPAN->new(%params);

Constructor.

=over 8

=item * C<lwp_user_agent>

LWP::User agent object.

Default value is undef.

=back

Returns instance of object.

=head2 C<search>

 my $content_hr = $obj->search($args_hr);

Search on MetaCPAN API.

Variable C<$args_hr> is reference to hash with keys:

=over 8

=item * include_dev

Flag that means development versions.

=item * package

Package name (e.g. App::Pod::Example).

=item * version

Version of package.

=item * version_range

Version range (e.g. >0.15,<0.17).

=back

Result is reference to hash with information about download URL.
Keys are checksum_md5, date, download_url, version, status, release and
checksum_sha256.

Returns reference to hash.

=head2 C<save>

 $obj->save($uri, $file);

Save URI to file.

Returns undef.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         Parameter 'lwp_user_agent' must be a 'LWP::UserAgent instance.

 search():
         Bad search options.
         Cannot connect to CPAN server.
         Module '%s' doesn't exist.
         Package doesn't present.

 save():
         Cannot connect to CPAN server.
                 HTTP code: %s
                 HTTP message: %s
         Cannot fetch '%s' URI.
                 HTTP code: %s
                 HTTP message: %s
         Cannot fetch '%s'.
                 HTTP code: %s
                 HTTP message: %s

=head1 EXAMPLE1

=for comment filename=search_module.pl

 use strict;
 use warnings;

 use App::CPAN::Get::MetaCPAN;
 use Data::Printer;

 my $obj = App::CPAN::Get::MetaCPAN->new;

 my $content_hr = $obj->search({
         'package' => 'App::Pod::Example',
         'version' => '0.20',
 });

 p $content_hr;

 # Output (2024/06/23):
 # {
 #     checksum_md5      "dcc4d6f0794c6fc985a6b3c9bd22f88d",
 #     checksum_sha256   "ca71d7d17fe5ea1cd710b9fce554a1219e911baefcaa8ce1ac9c09425f6ae445",
 #     date              "2023-03-29T09:57:36" (dualvar: 2023),
 #     download_url      "https://cpan.metacpan.org/authors/id/S/SK/SKIM/App-Pod-Example-0.20.tar.gz",
 #     release           "App-Pod-Example-0.20",
 #     status            "latest",
 #     version           0.2
 # }

=head1 EXAMPLE2

=for comment filename=search_module_versions.pl

 use strict;
 use warnings;

 use App::CPAN::Get::MetaCPAN;
 use Data::Printer;

 my $obj = App::CPAN::Get::MetaCPAN->new;

 my $content_hr = $obj->search({
         'package' => 'App::Pod::Example',
         'version_range' => '>0.18,<=0.40',
 });

 p $content_hr;

 # Output (2024/06/23):
 # {
 #     checksum_md5      "dcc4d6f0794c6fc985a6b3c9bd22f88d",
 #     checksum_sha256   "ca71d7d17fe5ea1cd710b9fce554a1219e911baefcaa8ce1ac9c09425f6ae445",
 #     date              "2023-03-29T09:57:36" (dualvar: 2023),
 #     download_url      "https://cpan.metacpan.org/authors/id/S/SK/SKIM/App-Pod-Example-0.20.tar.gz",
 #     release           "App-Pod-Example-0.20",
 #     status            "latest",
 #     version           0.2
 # }

=head1 DEPENDENCIES

L<Class::Utils>,
L<Cpanel::JSON::XS>,
L<English>,
L<Error::Pure>,
L<IO::Barf>,
L<LWP::UserAgent>,
L<Readonly>,
L<Scalar::Util>,
L<URI>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-CPAN-Get>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.14

=cut
