#! perl

package App::Packager;

use strict;
use warnings;
use Carp;

# Implementation agnostic packager support.

our $VERSION   = "1.420";
our $PACKAGED  = 0 ;

sub import {

    # PAR::Packer.

    if ( $ENV{PAR_0} ) {
	require PAR;
	$VERSION          = $PAR::VERSION;
	$PACKAGED	  = 1;
	*IsPackaged       = sub { 1 };
	*GetScriptCommand = sub { $ENV{PAR_PROGNAME} };
	*GetAppRoot       = sub { $ENV{PAR_TEMP} };
	*GetResourcePath  = sub { $ENV{PAR_TEMP} . "/inc/res" };
	*GetResource      = sub { $ENV{PAR_TEMP} . "/inc/res/" . $_[0] };
	*GetUserFile      = sub { $ENV{PAR_TEMP} . "/inc/user/" . $_[0] };
	*Packager         = sub { "PAR" };
	*Version          = sub { "$PAR::VERSION" };
	return;
    }

    if ( $Cava::Packager::PACKAGED ) {
	$VERSION    = $Cava::Packager::VERSION;
	$PACKAGED   = 1;
	*Packager   = sub { "Cava Packager" };
	*Version    = sub { "$VERSION" };
	*IsPackaged = sub { 1 };
    }
    else {
	*Packager   = sub { return };
	*Version    = sub { "N/A" };
	*IsPackaged = sub { return };
    }

}

# Cava::Packager provides packaged and non-packaged functions.

our $AUTOLOAD;

sub AUTOLOAD {
    my $sub = $AUTOLOAD;
    $sub =~ s/^App\:\:Packager\:\://;

    eval { require Cava::Packager } unless $Cava::Packager::PACKAGED;
    my $can = Cava::Packager->can($sub);
    unless ( $can ) {
	require Carp;
	Carp::croak("Undefined subroutine \&$AUTOLOAD called");
    }

    no strict 'refs';
    *{'App::Packager::'.$sub} = $can;
    goto &$AUTOLOAD;
}

1;

=head1 NAME

App::Packager - Abstraction for Packagers

=head1 SYNOPSIS

App::Packager provides an abstract interface to a number of common
packagers, trying to catch as much common behaviour as possible.

The main purpose is to have uniform access to application specific
resources.

Supported packagers are PAR::Packer, Cava::Packager and unpackaged. In
the latter case, the packager functions are emulated via
Cava::Packager which provides fallback for unpackaged use.

For example:

    use App::Packager;
    print "My packager is: ", App::Packager::Packager(), "\n";

=head1 EXPORT

No functions are exported, they must be called with explicit package
name.

=head1 FUNCTIONS

=head2 App::Packager::Packager

Returns the name of the actual packager, or undef if unpackaged.

=head2 App::Packager::Version

Returns the version of the actual packager, or "N/A" if unpackaged.

=head2 App::Packager::IsPackaged

Returns true if the application was packaged.

Note that it is usually easier, and safer, to use
$App::Packager::PACKAGED for testing since that will work even if
App::Packager is not available.

=head1 App::Packager::GetResourcePath

Returns the path name of the application resources directory.

=head1 App::Packager::GetResource($rsc)

Returns the file name of the application resource.

=head1 App::Packager::GetUserFile($rsc)

Returns the file name of the user specific resource.

=cut

=head1 AUTHOR

Johan Vromans, C<< <JV at CPAN dot org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-packager at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Packager>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

Development of this module takes place on GitHub:
L<https://github.com/sciurius/perl-App-Packager>.

You can find documentation for this module with the perldoc command.

    perldoc App::Packager

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Packager>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Packager>

=back

=head1 ACKNOWLEDGEMENTS

This module was inspired by Mark Dootson;s Cava packager.

=head1 COPYRIGHT & LICENSE

Copyright 2017 Johan Vromans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
