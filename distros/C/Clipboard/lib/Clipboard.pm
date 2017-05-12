package Clipboard;
our $VERSION = '0.13';
our $driver;

sub copy { my $self = shift; $driver->copy(@_); }
sub cut { goto &copy }
sub paste { my $self = shift; $driver->paste(@_); }

sub bind_os { my $driver = shift; map { $_ => $driver } @_; }
sub find_driver {
    my $self = shift;
    my $os = shift;
    my %drivers = (
        # list stolen from Module::Build, with some modifications (for
        # example, cygwin doesn't count as Unix here, because it will
        # use the Win32 clipboard.)
        bind_os(Xclip => qw(linux bsd$ aix bsdos dec_osf dgux
            dynixptx hpux irix dragonfly machten next os2 sco_sv solaris sunos
            svr4 svr5 unicos unicosmk)),
        bind_os(MacPasteboard => qw(darwin)),
        bind_os(Win32 => qw(mswin ^win cygwin)),
    );
    $os =~ /$_/i && return $drivers{$_} for keys %drivers;
    die "The $os system is not yet supported by Clipboard.pm.  Please email rking\@panoptic.com and tell him about this.\n";
}

sub import {
    my $self = shift;
    my $drv = Clipboard->find_driver($^O);
    require "Clipboard/$drv.pm";
    $driver = "Clipboard::$drv";
}

1;
=head1 NAME 

Clipboard - Copy and paste with any OS

=head1 SYNOPSIS

use Clipboard;
print Clipboard->paste;
Clipboard->copy('foo');

Clipboard->cut() is an alias for copy(). copy() is the preferred
method, because we're not really "cutting" anything.

Also see the scripts:
    clipaccumulate
    clipbrowse
    clipedit
    clipfilter
    clipjoin

=head1 DESCRIPTION

Who doesn't remember the first time they learned to copy and paste, and
generated an exponentially growing text document?   Yes, that's right,
clipboards are magical.

With Clipboard.pm, this magic is now trivial to access,
in a cross-platform-consistent API, from your Perl code.

=head1 STATUS

Seems to be working well for Linux, OSX, *BSD, and Windows.  I use it
every day on Linux, so I think I've got most of the details hammered out
(X selections are kind of weird).  Please let me know if you encounter
any problems in your setup.

=head1 AUTHOR

Ryan King <rking@panoptic.com>

=head1 COPYRIGHT

Copyright (c) 2010. Ryan King. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
# vi:tw=72
