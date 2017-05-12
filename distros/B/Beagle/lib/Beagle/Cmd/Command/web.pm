package Beagle::Cmd::Command::web;
use Beagle::Util;
use Any::Moose;
extends qw/Beagle::Cmd::Command/;

has admin => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'enable admin',
    traits        => ['Getopt'],
    default       => 0,
    lazy          => 1,
);

has all => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'enable all beagles',
    traits        => ['Getopt'],
    default       => 0,
    cmd_aliases   => 'a',
    lazy          => 1,
);

has names => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'names of beagles',
    traits        => ['Getopt'],
);

has 'command' => (
    isa           => 'Str',
    is            => 'rw',
    traits        => ['Getopt'],
    documentation => "command to run, e.g. plackup, starman, twiggy, etc.",
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;
    die "can't call web command in web term" if $ENV{BEAGLE_WEB_TERM};

    my $root = current_root('not die');
    if ( !$root && !$self->all && !$self->names ) {
        die "please specify beagle by --name or --root";
    }

    local $ENV{BEAGLE_NAME} = '';
    local $ENV{BEAGLE_ROOT} = $root;

    my $share_root = share_root();
    my $app = catfile( $share_root, 'app.psgi' );
    require Beagle::Web;
    local $ENV{BEAGLE_WEB_ADMIN} =
      exists $self->{admin} ? $self->admin : web_admin();
    local $ENV{BEAGLE_WEB_ALL} =
      exists $self->{all} ? $self->all : $ENV{BEAGLE_WEB_ALL};

    local $ENV{BEAGLE_WEB_NAMES} =
      $self->{names} ? encode( locale => $self->names ) : $ENV{BEAGLE_WEB_NAMES};

    require Plack::Runner;
    my $r = Plack::Runner->new;

    my @args;
    push @args, web_options(), @$args;

    if ( $self->command ) {
        system( $self->command, $app, @args );
    }
    else {
        $r->parse_options(@args);
        $r->{server} ||= 'Standalone';
        $r->run($app);
    }
}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::web - start web server

=head1 SYNOPSIS

    $ beagle web
    $ beagle web --port 8080
    $ beagle web --command starman
    $ beagle web --admin

=head1 DESCRIPTION

Besices options below, C<web> supports options of C<plackup> too, so you can
use C<--port>, C<--listen>, etc.

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

