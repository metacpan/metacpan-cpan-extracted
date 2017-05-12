package MY::Build;

use strict;
use warnings;
use base qw(Module::Build);
use File::Copy qw(copy);
use File::Path qw(mkpath);
use File::Basename qw(basename);

sub ACTION_code {
    my $self = shift;
    $self->SUPER::ACTION_code;
    $self->fetch_carousel();
    $self->install_carousel();
}

sub carousel_files {
    return qw(carousel.js carousel.css);
}

sub carousel_dir {
    return '.';
}

sub carousel_target_dir {
    return 'blib/lib/Alien/Prototype/Carousel/';
}

sub carousel_urls {
    return qw(
        http://prototype-carousel.xilinus.com/javascripts/carousel.js
        http://prototype-carousel.xilinus.com/stylesheets/carousel.css
    );
}

sub fetch_carousel {
    my $self = shift;
    foreach my $url ($self->carousel_urls()) {
        my $file = basename($url);
        if (!-f $file) {
            require File::Fetch;
            print "Fetching Carousel component ($file)...\n";
            my $path = File::Fetch->new( 'uri' => $url )->fetch();
            die "unable to fetch" unless $path;
        }
    }
}

sub install_carousel {
    my $self = shift;
    return if (-d $self->carousel_target_dir());

    my $dst = $self->carousel_target_dir();
    mkpath( $dst ) || die "unable to create '$dst'; $!";

    print "Installing Carousel component...\n";
    foreach my $file ($self->carousel_files()) {
        copy( $file, $dst ) || die "unable to copy '$file' into '$dst'; $!";
    }
}

1;
