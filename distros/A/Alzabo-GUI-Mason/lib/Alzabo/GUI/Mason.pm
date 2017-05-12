package Alzabo::GUI::Mason;

use strict;

use vars qw($VERSION);

$VERSION = 0.1201;

sub default_for_web {
    my $default = shift;

    return '' unless defined $default;
    return "''" if defined $default && ! length $default;

    return $default;
}

sub default_from_web {
    my $default = shift;

    return undef if $default eq '';
    return '' if $default eq "''";

    return $default;
}


1;

__END__

=pod

=head1 NAME

Alzabo::GUI::Mason - A GUI for Alzabo using Mason

=head1 SYNOPSIS

  install GUI and use it ;)

=head1 DESCRIPTION

This module exists primarily so CPAN will index this distribution.

All of the GUI functionality is implemented via Mason components (for
now, at least).

=head1 INSTALLATION

To install the interface, run the following commands:

 perl Build.PL

 ./Build install

The installation process is interactive.  You will need to tell the
installer where you want the Mason components installed.  If you are
not familiar with Mason, then you can just use your web server's
document root, or any directory underneath it.

To actually use this GUI you will need to set up your web server to
use Mason.  See the Mason documentation for details.

You'll want to make sure that JPEG files are not served by Mason in
whatever directory you install the data modelling tool.  For Apache
with mod_perl, you can use a configuration something like this:

  <Location /alzabo>
    SetHandler  perl-script
    PerlHandler HTML::Mason::ApacheHandler
  </Location>

  <LocationMatch "/alzabo/.*\.jpg$">
    SetHandler  default
  </Location>

=head1 AUTHORS

Dave Rolsky <autarch@urth.org>

John Skelton designed the interface <www.afrojet.com>

=cut
