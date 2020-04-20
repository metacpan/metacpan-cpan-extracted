package App::Mxpress::PDF;
use Dancer2;
use App::Mxpress::PDF::API;
our $VERSION = '0.21';

prefix undef;

get '/' => sub {
    template 'index' => { 'title' => 'App::Mxpress::PDF' };
};

true;

=head1 NAME
 
App::Mxpress::PDF - A utility application for generating PDFs
 
=head1 VERSION
 
Version 0.21
 
=cut

=head1 SYNOPSIS

	plackup `which app-mxpress-pdf.psgi'

=cut

=head1 routes

=head2 '/'

Returns the html - single page application.

=head2 /api/login

Authenticate to the api, the default username and password is username and password. This can be updated
inside of the conf.yml file.
	
	header('Token', $csrf_token);
	post('/api/login', {
		username => Types::Standard::Optional->of(Str),
		password => Types::Standard::Optional->of(Str)
	});

=head2 /api/logout

Logout of the session.

	header('Token', $csrf_token);
	post('/api/logout')

=head2 /api/session

Check whether the current session is valid.

	get('/api/session')

=head2 /api/generate/pod

Generate a pdf from pod.

	header('Token', $csrf_token);
	post('/api/generate/pod', {
		styles => Str,
		type => Enum[qw/module distribution raw/],
		name => StrMatch[ qr{([a-zA-Z0-9\-\:]+)} ],
		module => Types::Standard::Optional->of(StrMatch[ qr{([a-zA-Z0-9\-\:]*)} ]),
		distribution => Types::Standard::Optional->of(StrMatch[ qr{([a-zA-Z0-9\-\:]*)} ],),
		raw => Types::Standard::Optional->of(Str)
	});

=head2 /api/generate/pdf

Generate a pdf from a template

	header('Token', $csrf_token);
	post('/api/generate/pdf', {
		params => HashRef,
		name => StrMatch[ qr{([a-zA-Z0-9\-\:]+)} ],
		styles => Types::Standard::Optional->of(Str),
		size => Types::Standard::Optional->of(Enum[qw/A1 A2 A3 A4 A5 A6/]),
		template => Types::Standard::Optional->of(Str)
	});

=head2 /api/templates

	get('/api/templates')

=head2 /api/create/template

	header('Token', $csrf_token);
	post('/api/create/template', {
		name => StrMatch[ qr{([a-zA-Z0-9\-\:]+)} ],
		styles => Str,
		size => Enum[qw/A1 A2 A3 A4 A5 A6/],
		template => Str
	});

=head2 /api/delete/template

	header('Token', $csrf_token);
	post('/api/delete/template', {
		name => StrMatch[ qr{([a-zA-Z0-9\-\:]+)} ],
		size => Enum[qw/A1 A2 A3 A4 A5 A6/],
	})

=head2

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
 
=item * AnnoCPAN: Annotated CPAN documentation
 
L<http://annocpan.org/dist/App-Mxpress-PDF>
 
=item * CPAN Ratings
 
L<https://cpanratings.perl.org/d/App-Mxpress-PDF>
 
=item * Search CPAN
 
L<https://metacpan.org/release/App-Mxpress-PDF>
 
=back
 
=head1 ACKNOWLEDGEMENTS
 
=head1 LICENSE AND COPYRIGHT
 
This software is Copyright (c) 2020 by lnation.
 
This is free software, licensed under:
 
  The Artistic License 2.0 (GPL Compatible)
 
=cut

