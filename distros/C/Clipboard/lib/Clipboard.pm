package Clipboard;
$Clipboard::VERSION = '0.28';
use strict;
use warnings;

our $driver;

sub copy { my $self = shift; $driver->copy(@_); }
sub copy_to_all_selections {
    my $self = shift;
    my $meth = $driver->can('copy_to_all_selections');
    return $meth ? $meth->($driver, @_) : $driver->copy(@_);
}

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
            dynixptx gnu hpux irix dragonfly machten next os2 sco_sv solaris
            sunos svr4 svr5 unicos unicosmk)),
        bind_os(MacPasteboard => qw(darwin)),
    );

    if ($os =~ /^(?:mswin|win|cygwin)/i) {
        # If we are connected to windows through ssh, and xclip is
        # available, use it.
        if (exists $ENV{SSH_CONNECTION}) {
            local $SIG{__WARN__} = sub {};
            require Clipboard::Xclip;

            return 'Xclip' if Clipboard::Xclip::xclip_available();
        }

        return 'Win32';
    }

    $os =~ /$_/i && return $drivers{$_} for keys %drivers;

    # use xclip on unknown OSes that seem to have a DISPLAY
    return 'Xclip' if exists $ENV{DISPLAY};

    die "The $os system is not yet supported by Clipboard.pm.  Please email rking\@panoptic.com and tell him about this.\n";
}

sub import {
    my $self = shift;
    my $drv = Clipboard->find_driver($^O);
    require "Clipboard/$drv.pm";
    $driver = "Clipboard::$drv";
}

1;
# vi:tw=72

__END__

=pod

=encoding UTF-8

=head1 NAME

Clipboard - Copy and paste with any OS

=head1 VERSION

version 0.28

=head1 SYNOPSIS

    use Clipboard;
    print Clipboard->paste;
    Clipboard->copy('foo');
    # Same as copy on non-X / non-Xclip systems
    Clipboard->copy_to_all_selections('text_to_copy');

Clipboard->cut() is an alias for copy(). copy() is the preferred
method, because we're not really "cutting" anything.

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

=head1 SEE ALSO

L<clipaccumulate(1)>, L<clipbrowse(1)>, L<clipedit(1)>,
L<clipfilter(1)>, L<clipjoin(1)>

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Clipboard>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Clipboard>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Clipboard>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/C/Clipboard>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Clipboard>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Clipboard>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-clipboard at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Clipboard>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/Clipboard>

  git clone git://github.com/shlomif/Clipboard.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/Clipboard/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Ryan King <rking@panoptic.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
