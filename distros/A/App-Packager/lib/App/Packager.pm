#! perl

package App::Packager;

use strict;
use warnings;
use Carp;

use parent qw(Exporter);
our @EXPORT_OK = qw( GetUserFile GetResource SetResourceName );

# Implementation agnostic packager support.

our $VERSION   = "1.440";
our $PACKAGED  = 0;
our $RESNAME   = "";

### Establish access methods depending on the packer.

# Check for PAR::Packer.
if ( $ENV{PAR_0} ) {
    require PAR;
    $VERSION          = $PAR::VERSION;
    $PACKAGED         = 1;
    *IsPackaged       = sub { 1 };
    *GetScriptCommand = sub { $ENV{PAR_PROGNAME} };
    *GetAppRoot       = sub { $ENV{PAR_TEMP} };
    *GetResourcePath  = sub { $ENV{PAR_TEMP} . "/inc/res" };
    *GetResource      = sub { $ENV{PAR_TEMP} . "/inc/res/"  . $_[0] };
    *GetUserFile      = sub { $ENV{PAR_TEMP} . "/inc/user/" . $_[0] };
    *Packager         = sub { "PAR" };
    *Version          = sub { "$PAR::VERSION" };
}

elsif ( $ENV{PPL_PACKAGED} ) {
    $VERSION          = $ENV{PPL_PACKAGED};
    $PACKAGED         = 1;
    *Packager         = sub { "PPL" };
    *Version          = sub { "$VERSION" };
    *IsPackaged       = sub { 1 };
    *GetResourcePath  = \&U_GetResourcePath;
    *GetResource      = \&U_GetResource;
    *GetUserFile      = \&U_GetUserFile;
}

elsif ( $ENV{DOCKER_PACKAGED} ) {
    $VERSION          = $ENV{DOCKER_PACKAGED};
    $PACKAGED         = 1;
    *Packager         = sub { "Docker" };
    *Version          = sub { "$VERSION" };
    *IsPackaged       = sub { 1 };
    *GetResourcePath  = \&U_GetResourcePath;
    *GetResource      = \&U_GetResource;
    *GetUserFile      = \&U_GetUserFile;
}

elsif ( $ENV{APPIMAGE_PACKAGED} ) {
    $VERSION          = $ENV{APPIMAGE_PACKAGED};
    $PACKAGED         = 1;
    *Packager         = sub { "AppImage" };
    *Version          = sub { "$VERSION" };
    *IsPackaged       = sub { 1 };
    *GetResourcePath  = \&U_GetResourcePath;
    *GetResource      = \&U_GetResource;
    *GetUserFile      = \&U_GetUserFile;
}

# Cava::Packager.
elsif ( $Cava::Packager::PACKAGED ) {
    $VERSION          = $Cava::Packager::VERSION;
    $PACKAGED         = 1;
    *Packager         = sub { "Cava Packager" };
    *Version          = sub { "$VERSION" };
    *IsPackaged       = sub { 1 };
}

# Unpackaged, use file system.
else {
    *Packager         = sub { "App Packager" };
    *Version          = sub { "$VERSION" };
    *IsPackaged       = sub { return };
    *GetResourcePath  = \&U_GetResourcePath;
    *GetResource      = \&U_GetResource;
    *GetUserFile      = \&U_GetUserFile;
}

#### Optional packaged, mandatory if unpackaged.

sub SetResourceName {
    $RESNAME = shift;
    $RESNAME =~ s;::;/;g;
    $RESNAME =~ s;/+$;;;
}

sub GetResourceName {
    $RESNAME;
}

#### Resource routines for the unpacked case.

sub U_GetUserFile {
    return if $RESNAME eq "";
    my $file = shift;
    foreach ( @INC ) {
	return "$_/$RESNAME/user/$file" if -e "$_/$RESNAME/user/$file";
    }
    undef;
}

sub U_GetResource {
    return if $RESNAME eq "";
    my $file = shift;
    foreach ( @INC ) {
	return "$_/$RESNAME/res/$file" if -e "$_/$RESNAME/res/$file";
    }
    foreach ( @INC ) {
	return "$_/$RESNAME/$file" if -e "$_/$RESNAME/$file";
    }
    undef;
}

sub U_GetResourcePath {
    return if $RESNAME eq "";
    foreach ( @INC ) {
	return "$_/$RESNAME/res" if -d "$_/$RESNAME/res";
    }
    undef;
}

#### Usually, this is all what is needed.

sub getresource {
    my ( $file ) = @_;

    my $found = App::Packager::GetUserFile($file);
    return $found if defined($found) && -e $found;
    $found = App::Packager::GetResource($file);
    return $found if defined($found) && -e $found;
    return unless $App::Packager::PACKAGED;
    return if $RESNAME eq "";

    foreach ( @INC ) {
	return "$_/$RESNAME/user/$file" if -e "$_/$RESNAME/user/$file";
	return "$_/$RESNAME/res/$file"  if -e "$_/$RESNAME/res/$file";
	return "$_/$RESNAME/$file"      if -e "$_/$RESNAME/$file";
    }

    return;
}

#### Import handling.
#
# Bij default, the getresource routine is exported, but its name
# can be changed by using ":rsc" => "alternative name".

sub import {
    my $pkg = shift;

    my @syms = ();		# symbols to import
    my $rsc = "getresource";

    while ( @_ ) {
	$_ = shift;
	if ( $_ eq ':name' ) {
	    SetResourceName(shift) if @_ > 0;
	    next;
	}
	if ( $_ eq ':rsc' ) {
	    $rsc = shift if @_ > 0;
	    next;
	}
	push( @syms, $_ );
    }

    if ( $rsc ) {
	my $pkg = (caller)[0];
	no strict 'refs';
	*{ $pkg . "::" . $rsc } = \&getresource;
    }

    # Dispatch to super.
    $pkg->export_to_level( 1, $pkg, @syms );
}

# Unknown routines are dispatched to Cava::Packager, which provides
# packaged and non-packaged functions.

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
the latter case, resources are looked up in @PATH, and the name of the
application package must be passed to the first C<use> of
App::Packager.

For example:

    use App::Packager qw(:name My::App);
    print "My packager is: ", App::Packager::Packager(), "\n";
    print getresource("README.txt");

=head1 EXPORT

By default, function C<getresource> is exported. It can be exported
under a different name by providing an alternative name as follows:

    use App::Packager( ':rsc' => '...alternative name...' );

=head1 FUNCTIONS

=head2 App::Packager::Packager

Returns the name of the actual packager, or C<App Packager> if unpackaged.

=head2 App::Packager::Version

Returns the version of the packager.

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

=head1 SUPPORT

Development of this module takes place on GitHub:
L<https://github.com/sciurius/perl-App-Packager>.

You can find documentation for this module with the perldoc command.

    perldoc App::Packager

Please report any bugs or feature requests using the issue tracker on
GitHub.

=back

=head1 ACKNOWLEDGEMENTS

This module was inspired by Mark Dootson's Cava packager.

=head1 COPYRIGHT & LICENSE

Copyright 2017,2018 Johan Vromans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
