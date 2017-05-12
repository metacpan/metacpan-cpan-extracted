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
    $self->fetch_prototype();
    $self->install_prototype();
}

sub prototype_files {
    return qw(prototype.js);
}

sub prototype_dir {
    return '.';
}

sub prototype_target_dir {
    return 'blib/lib/Alien/Prototype/';
}

sub prototype_urls {
    return qw(
        http://www.prototypejs.org/assets/2007/8/15/prototype.js
        );
}

sub fetch_prototype {
    my $self = shift;
    foreach my $url ($self->prototype_urls()) {
        my $file = basename($url);
        if (!-f $file) {
            require File::Fetch;
            print "Fetching Prototype ($file)...\n";
            my $path = File::Fetch->new( 'uri' => $url )->fetch();
            die "unable to fetch" unless $path;
        }
    }
}

sub install_prototype {
    my $self = shift;
    return if (-d $self->prototype_target_dir());

    my $dst = $self->prototype_target_dir();
    mkpath( $dst ) || die "unable to create '$dst'; $!";

    print "Installing Prototype...\n";
    foreach my $file ($self->prototype_files()) {
        copy( $file, $dst ) || die "unable to copy '$file' into '$dst'; $!";
    }
}

1;
