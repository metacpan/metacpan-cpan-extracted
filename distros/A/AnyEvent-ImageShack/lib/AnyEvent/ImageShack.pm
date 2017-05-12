package AnyEvent::ImageShack;

use strict;
use AnyEvent::HTTP;
use HTTP::Request::Common 'POST';
use base 'Exporter';
our $VERSION = '0.2';

our @EXPORT = qw(image_host);

sub image_host {
	my $file = shift;
	my $cb   = pop;
	my $url = '';
	
	if ($file =~ /^http:\/\//) {
		$url  = $file;
		$file = undef;
	}
	my $opt = ref $_[0] ? $_[0] : { @_ };
	
	$AnyEvent::HTTP::USERAGENT      = $opt->{'user_agent'} || 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_7; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.648.205 Safari/534.16';
	$AnyEvent::HTTP::MAX_PER_HOST ||= $opt->{'max_per_host'};
	$AnyEvent::HTTP::ACTIVE       ||= $opt->{'active'      };
	
	my $p = POST
		'http://www.imageshack.us/upload_api.php',
		Content_Type => 'multipart/form-data',
		Content      => [
			fileupload    => $file ? [ $file ] : [ '' ],
			url           => $url,
			tags          => $opt->{'tags'} || '',
			rembar        => $opt->{'remove_size'} || 1,
			optimage      => 1,
			key           => $opt->{'key'},
			optsize       => $opt->{'size'} || 'resample',
		]
	;
	
	http_post 
		$p->uri,
		$p->content,
		recurse => 0,
		headers => {
			map {
				$_ => $p->header($_)
			} $p->header_field_names
		},
		sub {
			$cb->($_[0] =~ /image_link>([^<>]+)</si);
		}
	;
}


=head1 NAME

AnyEvent::ImageShack - simple non-blocking client for image hosting ImageShack.us

=head1 VERSION

0.2

=head1 SYNOPSIS

   use AnyEvent::ImageShack;
   
   my $c = AnyEvent->condvar;
   image_host('url/or/path/to/image.png', key => 'developer_key123', sub { warn shift; $c->send });
   $c->recv;

=head1 METHODS

=over 4

=item image_host $image, option => value, ..., $callback

Host image C<$image> to ImageShack.us

=back

=head1 OPTIONS

=over 4

=item user_agent - UserAgent string

=item active - number of active connections for L<AnyEvent::HTTP>

=item max_per_host - maximum connections per one host for L<AnyEvent::HTTP>

=item key - developer key for ImageShack API

=item tags - tags for hosted image

=item remove_size - remove information about size from thumbnails (by default 1)

=item size - resize image to specified resolution (by default don't resize)

=item 

=back

=head1 SUPPORT

=over 4

=item * Repository

L<http://github.com/konstantinov/AnyEvent-ImageShack>

=item * ImageShack API

L<http://code.google.com/p/imageshackapi/>

=back

=head1 SEE ALSO

L<AnyEvent>, L<AnyEvent::HTTP>

=head1 COPYRIGHT & LICENSE

Copyright 2010-2012 Dmitry Konstantinov. All right reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.