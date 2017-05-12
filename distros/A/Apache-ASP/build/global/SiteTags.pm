package site;

use Image::Size qw(html_imgsize);

use strict;
use vars qw(@XMLSubsPages);

@XMLSubsPages = qw( box testimonial testimonials );

for my $page ( @XMLSubsPages ) {
    eval "sub $page {  \$main::Response->Include(\"$page.inc\", \@_) }";
    $@ && die("can't eval page sub for $page: $@");
}

sub img {
    my $args = shift;
    my $file = "../site/$args->{src}";
    my $size = '';
    
    if(-e $file) {
	$size = html_imgsize($file);
    }

    print qq(<img src="$args->{src}" $size alt="$args->{alt}" border="0">);
}

1;

