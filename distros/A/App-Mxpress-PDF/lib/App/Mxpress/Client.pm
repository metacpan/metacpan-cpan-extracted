package App::Mxpress::Client;

use Moo;
use Compiled::Params::OO qw/cpo/;
use Types::Standard qw/Object Str StrMatch Enum Optional HashRef Bool/;
use Future::HTTP;
use HTTP::CookieJar;
use JSON;

our ($validate, $session);
BEGIN {
	$validate = cpo(
		login => {
			username => Str,
			password => Str
		},
		generate => {
			name => Str,
			size => Str,
			params => Optional->of(HashRef),
			save => Optional->of(Str),
			filename => Optional->of(Str)
		},
		pod => {
			styles => Optional->of(HashRef),
        		type => Enum[qw/module distribution raw/],
        		module => Optional->of(StrMatch[ qr{([a-zA-Z0-9\-\:]*)} ]),
        		distribution => Optional->of(StrMatch[ qr{([a-zA-Z0-9\-\:]*)} ],),
			name => Optional->of(Str),
			raw => Optional->of(Str),
			save => Optional->of(Str),
			filename => Optional->of(Str)
		},
		save => [Object, Object, Str]
	);
}

has host => (
	is => 'ro',
	isa => Str,
	default => sub {
		return 'http://localhost:5000'
	}
);

has [qw/csrf/] => (
	is => 'rw',
	isa => Str
);

has json => (
	is => 'ro',
	default => sub {
		return JSON->new->allow_blessed->convert_blessed;
	}
);

has ua => (
	is => 'ro',
	default => sub {
		return Future::HTTP->new(
			cookie_jar => HTTP::CookieJar->new
		);
	}
);

sub session {
	my $self = shift;
	return $self->ua->http_get(
		sprintf("%s/api/session", $self->host),
		headers => {
			'Accept' => 'application/json'
		}
	)->then(sub {
		my ($body, $headers) = @_;
		$self->csrf($headers->{token});
		return Future->new->done($body);
	});
}

sub login {
	my $self = shift;
	my $params = $validate->login->(@_);
	$self->session->then(sub {
		return $self->ua->http_post(
			sprintf("%s/api/login", $self->host),
			$self->json->encode({%$params}),
			headers => {
				'Token' => $self->csrf,
				'Content-Type' => 'application/json',
				'Accept' => 'application/json'
			}
		)->then(sub {
			my ($body, $headers) = @_;
			$self->csrf($headers->{token});
			return Future->new->done($body);
		});
	})->get
}

sub templates {
	my $self = shift;
	$self->ua->http_get(
		sprintf("%s/api/templates", $self->host),
		headers => {
			'Accept' => 'application/json'
		}
	)->then(sub {
		my ($body, $headers) = @_;
		$body = $self->json->decode($body);
		return Future->new->done($body);
	})->else(sub {
		return Future->new->done($_[0]);
	})->get;
}

sub generate {
	my $self = shift;
	my $params = $validate->generate->(@_);
	$self->ua->http_post(
		sprintf("%s/api/generate/pdf", $self->host),
		$self->json->encode({
			name => $params->name,
			size => $params->size,
			params => $params->params
		}),
		headers => {
			'Token' => $self->csrf,
			'Content-Type' => 'application/json',
			'Accept' => 'application/json'
		}
	)->then(sub {
		my ($body, $headers) = @_;
		$self->csrf($headers->{token});
		if ($params->save) {
			return $self->save($params, $body);	
		}
		return Future->new->done($body);
	})->else(sub {
		return Future->new->done($_[0]);
	})->get;
}

sub pod {
	my $self = shift;
	my $params = $validate->pod->(@_);
	$params->{name} = $params->name 
		? $params->name
		: $params->{$params->type}; 
	$params->{styles} = {} if !$params->styles;
	$params->{styles} = $self->json->encode($params->styles);
	$self->ua->http_post(
		sprintf("%s/api/generate/pod", $self->host),
		$self->json->encode({ 
			styles => $params->styles,
        		type => $params->type,
        		module => $params->module,
        		distribution => $params->distribution,
			name => $params->name,
			raw => $params->raw,
		}),
		headers => {
			'Token' => $self->csrf,
			'Content-Type' => 'application/json',
			'Accept' => 'application/json'
		}
	)->then(sub {
		my ($body, $headers) = @_;
		$self->csrf($headers->{token});
		if ($params->save) {
			return $self->save($params, $body);	
		}
		return Future->new->done($body);
	})->else(sub {
		use Data::Dumper;
		warn Dumper $_[0];
		return Future->new->done($_[0]);
	})->get;
}

sub save {
	my ($self, $params, $body) = $validate->save->(@_);
	my $file = sprintf("%s/%s.pdf", $params->save, $params->filename || $params->name);
	open my $fh, '>', $file or die "cannot open file to write $file";
	print $fh $body;
	close $fh;
	return Future->new->done($file);
}

1;

__END__

=head1 NAME
 
App::Mxpress::Client - Client for App::Mxpress::PDF::API
 
=head1 VERSION
 
Version 0.22
 
=cut

=head1 SYNOPSIS

	use App::Mxpress::Client;

	my $client = App::Mxpress::Client->new;

	$client->login(
		username => 'admin',
		password => 'password'
	);

	$client->generate(
		save => './path/to/lib',
		name => 'demo',
		size => 'A4',
		params => {
			'placeholder' => 'Add some more text',
			'subtle' => 'A subtitle',
			'title' => 'A Title'
		}
	);

=cut

=head1 Methods

=head2 login

Authenticate to the api.

	$client->login(
		username => 'admin',
		password => 'password'
	);

=head2 templates

Return all templates.

	my $templates = $client->templates;

=head2 generate

Generate a pdf for the given template and params.

	my $pdfstring = $client->generate(
		save => './path/to/lib',
		name => 'demo',
		size => 'A4',
		params => {
			'placeholder' => 'Add some more text',
			'subtle' => 'A subtitle',
			'title' => 'A Title'
		}
	);

=head2 pod

Generate a pdf for the given module, distribution or raw text POD string.

	my $pod = $client->pod(
		type => 'module',
		module => 'Moo',
		save => './path/to/lib'
	);

=head1 AUTHOR
 
lnation, C<< <email at lnation.org> >>
 
=head1 BUGS
 
Please report any bugs or feature requests to C<bug-metacpan-client-pod-pdf at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Mxpress-PDF>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.
 
=head1 SUPPORT
 
You can find documentation for this module with the perldoc command.
 
        perldoc App::Mxpress::PDF
  
You can also look for information at:
 
=over 4
 
=item * RT: CPAN's request tracker (report bugs here)
 
L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Mxpress-PDF>
 
=item * Search CPAN
 
L<https://metacpan.org/release/App-Mxpress-PDF>
 
=back
 
=head1 ACKNOWLEDGEMENTS
 
=head1 LICENSE AND COPYRIGHT
 
This software is Copyright (c) 2020 by lnation.
 
This is free software, licensed under:
 
  The Artistic License 2.0 (GPL Compatible)
 
=cut

