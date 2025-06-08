package Catalyst::Plugin::SocialMeta;

use 5.006; use strict; use warnings; our $VERSION = '0.05';

use HTML::SocialMeta;

sub prepare {
	my $self = shift;

	my $c = $self->next::method(@_);

	my $config = $c->config->{'Plugin::SocialMeta'};

	return $c unless $config;

	$c->socialmeta();

	return $c;
}

sub socialmeta {
	my ($c, %data) = @_;

	my $return = delete $data{return};

	my $config = $c->config->{'Plugin::SocialMeta'} || {};
	%data = (%{$config}, %data);

	if (!$data{url}) {
		$data{url} = "" . $c->req->uri;
	}

	my $provider = defined $data{meta_provider}
		? delete $data{meta_provider}
		: 'all';

	my $card_type = defined $data{card_type}
		? delete $data{card_type}
		: 'summary';

	my $social_meta = HTML::SocialMeta->new(\%data);

	my $tags;
	if ($provider eq 'all') {
		$tags = $social_meta->create($card_type);
	} else {
		$tags = $social_meta->$provider->create($card_type);
	}

	if ($return) {
		return $tags;
	}
	
	$c->stash(socialmeta => $tags);

	return 1;
}

1;

__END__

=head1 NAME

Catalyst::Plugin::SocialMeta - Generate social media meta tags for your catalyst application.

=head1 VERSION

Version 0.05

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	... MyApp.pm ...

	package MyApp;
	use Moose;
	use namespace::autoclean;

	use Catalyst::Runtime 5.80;

	use Catalyst qw/
		SocialMeta
	/;

	extends 'Catalyst';

	our $VERSION = '0.01';

	__PACKAGE__->config(
		name => 'MyApp',
		'Plugin::SocialMeta' => {
			meta_provider => 'all',
			card_type => 'featured_image',
			site => 'Lnation.org',
			site_name => 'Lnation',
			title => 'Social Meta Tag Generator',
			description => 'Demo UI for HTML::SocialMeta',
			image => 'https://lnation.org/static/images/social.png',
			fb_app_id => 'lnationorgnofb',
		}
	);

	# Start the application
	__PACKAGE__->setup();

	.... Controller ...

	package MyApp::Controller::Foo;

	use Moose;
	use namespace::autoclean;
	BEGIN {
		extends 'Catalyst::Controller';
	}

	sub foo :Chained('/') :PathPart('foo') :Args(0) {
		my ($self, $c) = @_;
		... # uses default social meta tags from config
	}

	sub base :Chained('/') :PathPart('') :CaptureArgs(0) {
		my ($self, $c) = @_;

		$c->socialmeta(
			title => 'Changed Title',
			description => 'Demo UI for Changed::Title',
		);
	}

	sub bar :Chained('base') :PathPart('bar') :Args(0) {
		my ($self, $c) = @_;
		... # social meta tags from the config + the keys set in the base action
	}

`	... wrapper.tt ...

	<html>
		<head>
			[% socialmeta %]
		</head>
		<body>
			...
		</body>
	</html>

=head1 SUBROUTINES/METHODS

=head2 socialmeta

Set the social meta tags for the current action, you can pass the following keys, see L<HTML::SocialMeta> for more information.

=over

=item meta_provider

The meta provider you would like to generate the social meta tags for, this defaults to 'all'. twitter and opengraph are the other valid options.

=item card_type 

The type of social meta card see L<HTML::SocialMeta> documention for options.

=item card
 
OPTIONAL - if you always want the same card type you can set it 
 
=item site
 
The Twitter @username the card should be attributed to. Required for Twitter Card analytics. 
 
=item site_name
 
This is Used by Facebook, you can just set it as your organisations name.
 
=item title
 
The title of your content as it should appear in the card 
 
=item description
 
A description of the content in a maximum of 200 characters
 
=item image
 
A URL to a unique image representing the content of the page
 
=item image_alt
 
OPTIONAL - A text description of the image, for use by vision-impaired users
 
=item url
 
Required for OpenGraph. Allows you to specify an alternative url link you want the reader to be redirected
 
=item player
 
HTTPS URL to iframe player. This must be a HTTPS URL which does not generate active mixed content warnings in a web browser
 
=item player_width
 
Width of IFRAME specified in twitter:player in pixels
 
=item player_height
 
Height of IFRAME specified in twitter:player in pixels
 
=item operating_system
 
IOS or Android 
 
=item app_country      
 
UK/US ect
 
=item app_name   
 
The applications name
 
=item app_id 
 
String value, and should be the numeric representation of your app ID in the App Store (.i.e. 307234931)
 
=item app_url 
 
Application store url - direct link to App store page
 
=item fb_app_id
 
This field is required to use social meta with facebook, you must register your website/app/company with facebook.
They will then provide you with a unique app_id.
 
=back

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-plugin-socialmeta at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Plugin-SocialMeta>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Plugin::SocialMeta


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Plugin-SocialMeta>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Catalyst-Plugin-SocialMeta>

=item * Search CPAN

L<https://metacpan.org/release/Catalyst-Plugin-SocialMeta>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Catalyst::Plugin::SocialMeta
