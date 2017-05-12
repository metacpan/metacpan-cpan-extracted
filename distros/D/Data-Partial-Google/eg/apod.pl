#!perl
use strict;
use warnings;
use Data::Printer { class => { expand => 'all', show_methods => 'none' } };
use Data::Partial::Google;

my $filter = 'url,object(content,attachments/url)';
my $mask = Data::Partial::Google->new($filter);

&p($mask->filter);

my $in = {
	id => 'z12gtjhq3qn2xxl2o224exwiqruvtda0i',
	url => 'https://plus.google.com/102817283354809142195/posts/F97fqZwJESL',
	object => {
		objectType => 'note',
		content => 'A picture... of a space ship... launched from earth 40 years ago.',
		attachments => [{
			objectType => 'image',
			url => 'http://apod.nasa.gov/apod/ap110908.html',
			image => { height => 284, width => 506 },
		}]
	},
	provider => { title => 'Google+' }
};

my $out = $mask->mask($in);

&p($out);

