package MY::Build;

use strict;
use warnings;
use base qw(Module::Build);
use File::Copy qw(copy);

sub ACTION_code {
    my $self = shift;
    $self->SUPER::ACTION_code;
    $self->fetch_lightbox();
    $self->install_lightbox();
}

sub lightbox_archive {
    return 'lightbox2.03.3.zip';
}

sub lightbox_dir {
    return '';
}

sub lightbox_target_dir {
    'blib/lib/Alien/Lightbox/';
}

sub lightbox_url {
    my $self = shift;
    return 'http://www.huddletogether.com/projects/lightbox2/releases/' .  $self->lightbox_archive();
}

sub fetch_lightbox {
    my $self = shift;
    return if (-f $self->lightbox_archive());

    require File::Fetch;
    print "Fetching Lightbox...\n";
    my $path = File::Fetch->new( 'uri' => $self->lightbox_url() )->fetch();
    die "Unable to fetch archive" unless $path;
}

sub install_lightbox {
    my $self = shift;
    return if (-d $self->lightbox_target_dir());

    require Archive::Zip;
    print "Installing lightbox...\n";
    my $zip = Archive::Zip->new();
    unless ($zip->read($self->lightbox_archive()) == Archive::Zip::AZ_OK()) {
        die "unable to open Lightbox zip archive\n";
    }
    my $src = $self->lightbox_dir();
    my $dst = $self->lightbox_target_dir();
    unless ($zip->extractTree($src,$dst) == Archive::Zip::AZ_OK()) {
        die "unable to extract Lightbox zip archive\n";
    }
}

1;
