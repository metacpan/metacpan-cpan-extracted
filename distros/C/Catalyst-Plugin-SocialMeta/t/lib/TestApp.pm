package TestApp;
use Moose;
use namespace::autoclean;
 
use Catalyst::Runtime 5.80;
 
use Catalyst qw/
        SocialMeta
/;
 
extends 'Catalyst';
 
our $VERSION = '0.01';
 
__PACKAGE__->config(
	name => 'TestApp',
	'Plugin::SocialMeta' => {
		meta_provider => 'all',
		card_type => 'featured_image',
		site => 'Lnation.org',
		site_name => 'Lnation',
		title => 'Social Meta Tag Generator',
		description => 'Demo UI for HTML::SocialMeta',
		image => 'https://lnation.org/static/images/social.png',
		fb_app_id => 'lnationorgnofb',
		url => 'https://lnation.org/socialmeta/demo'
	}
);
 
# Start the application
__PACKAGE__->setup();
 
1;
