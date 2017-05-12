package App::Gnuget;
use Net::FTP;

our $VERSION = 1.935;

sub new {
    my $class = shift;
    $class = ref($class) || $class;
    my $self = { ftp => Net::FTP->new("ftp.gnu.org") };
    return bless($self, $class);
}

sub log {
    my ($self, $msg) = @_;
    print("[$$] $msg\n");
}

sub buildFtpCnx {
    my $self = shift;
    $self->{ftp}->login("anonymous", '-anonymous@')
        or die $self->{ftp}->message;
    $self->log("connected to GNU ftp");
    $self->{ftp}->cwd('/gnu') and $self->log("cwd() in gnu/");
}

sub download {
    my $self = shift;
    $self->{ftp}->cwd($self->{software}) 
	and $self->log("cwd() in $self->{software}/");
    $self->{ftp}->get($self->{archive})
	or $self->log("cannot download $self->{archive}");
    exit(1) if (! -e $self->{archive});
    $self->log("$self->{archive}'s download successful");
}

sub populate {
    my ($self, $name, $version) = @_;
    $self->{software} = $name;
    $self->{version} = $version;
    $self->{archive} = $self->{software}."-".$self->{version}.".tar.gz";
}


sub clean {
    my $self = shift;
    unlink($self->{archive})
        or $self->log("Cannot erase $self->{archive}");
    $self->log("$self->{archive} cleaned");
    $self->{ftp}->quit();
    $self->log("disconnected from GNU ftp");
}

sub uncompress {
    my $self = shift;
    system("tar xf $self->{archive} 2>/dev/null")
        and $self->log("cannot unpack archive");
    $self->log("$self->{archive} unpacked");
}

1;

__END__

=pod

=head1 NAME

App::Gnuget - Main module for gnuget tool

=head1 VERSION

version 1.935

=head1 SYNOPSIS

    # Create object
    my $getter = new App::Gnuget;

    # Setup informations
    my ($software, $version) = ('make', '3.82');

    # Give informations to the object
    $getter->populate($software, $version);

    # Build Ftp connexion
    $getter->buildFtpCnx();

    # Download the archive
    $getter->download();

    # Unpack the archive
    $getter->uncompress();

    # Clean env
    $getter->clean()

=head1 DESCRIPTION

This module is the main module for gnuget software. It implements all functions needed by it, see the example above, which is basically the gnuget operation.

=head1 AUTHOR

Sandro CAZZANIGA <cazzaniga.sandro@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Sandro CAZZANIGA.

This is free software; you can redistribute it and/or modify it 
under the terms of GNU GPL version 3.
