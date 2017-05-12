package MY::Build;

use strict;
use warnings;
use base qw(Module::Build);
use File::Copy qw(copy);

sub ACTION_code {
    my $self = shift;
    $self->SUPER::ACTION_code;
    $self->fetch_ie7();
    $self->install_ie7();
}

sub ie7_archive {
    return 'IE7_0_9.zip';
}

sub ie7_dir {
    return 'IE7_0_9';
}

sub ie7_target_dir {
    return 'blib/lib/Alien/IE7/';
}

sub ie7_url {
    my $self = shift;
    return 'http://superb-east.dl.sourceforge.net/sourceforge/ie7/' .  $self->ie7_archive();
}

sub fetch_ie7 {
    my $self = shift;
    return if (-f $self->ie7_archive());

    require File::Fetch;
    print "Fetching IE7...\n";
    my $path = File::Fetch->new( 'uri' => $self->ie7_url() )->fetch();
    die "Unable to fetch archive" unless $path;
}

sub install_ie7 {
    my $self = shift;
    return if (-d $self->ie7_target_dir());

    require Archive::Zip;
    print "Installing IE7...\n";
    my $zip = Archive::Zip->new();
    unless ($zip->read($self->ie7_archive()) == Archive::Zip::AZ_OK()) {
        die "unable to open IE7 zip archive\n";
    }
    my $src = $self->ie7_dir();
    my $dst = $self->ie7_target_dir();
    unless ($zip->extractTree($src,$dst) == Archive::Zip::AZ_OK()) {
        die "unable to extract IE7 zip archive\n";
    }
}

1;
