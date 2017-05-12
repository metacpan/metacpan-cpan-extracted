package Alien::InteractiveBrokers;
#
#   Alien::InteractiveBrokers - Provides config info for IB API files
#
#   Copyright (c) 2010-2012 Jason McManus
#
#   Full POD documentation after __END__
#

use File::Spec::Functions qw( catdir catfile );
use Carp qw( croak confess );
use strict;
use warnings;

###
### Variables
###

use vars qw( @ISA @EXPORT_OK $VERSION $TRUE $FALSE );

BEGIN {
    require Exporter;
    @ISA        = qw( Exporter );
    @EXPORT_OK  = qw( path includes classpath version );
    $VERSION    = '9.6602';
}

*TRUE     = \1;
*FALSE    = \0;

my $versions = {
    '9.64' => {
        desc => 'IB API 9.64',
        url  => 'http://www.interactivebrokers.com/download/twsapi_unixmac_964.jar',
    },
    '9.65' => {
        desc => 'IB API 9.65',
        url  => 'http://www.interactivebrokers.com/download/twsapi_unixmac_965.jar',
    },
    '9.66' => {
        desc => 'IB API 9.66',
        url  => 'http://www.interactivebrokers.com/download/twsapi_unixmac_966.jar',
    },
    '9.65' => {
        desc => 'IB API 9.67 Beta',
        url  => 'http://www.interactivebrokers.com/download/twsapi_unixmac_967.jar',
    },
};

my $DEF_API_VERSION = '9.66';

# Global cache; either points to object ref, or just used as is.
# XXX: This may explode upon multiple Alien::SWIG objects being created,
# but we'll worry about that if anyone ever needs to actually do that.
our $CACHE = {};        # our, for testing

###
### Constructor
###

sub new
{
    my $class = shift;

    # Set up a default object
    my $self = {}; 

    # Instantiate the object.  sort of.
    bless( $self, $class );

    # Direct the global cache to us (see note above)
    $CACHE = $self;

    return( $self );
}

###
### Methods
###

sub path
{
    return( $CACHE->{path} )
        if( exists( $CACHE->{path} ) );

    my $base = $INC{ join( '/', 'Alien', 'InteractiveBrokers.pm' ) };
    $base =~ s{\.pm$}{};
    my $path = catfile( $base, 'IBJts' );

    croak( "Path $path doesn't appear to contain the IB API installation;" .
           " please re-install Alien::InteractiveBrokers." )
        unless( -d $path );

    $CACHE->{path} = $path;

    return( $path );
}

sub includes
{
    my @includes;

    if( exists( $CACHE->{includes} ) )
    {
        @includes = @{ $CACHE->{includes} };
    }
    else
    {
        my $base = path();

        for( qw( Shared PosixSocketClient ) )
        {
            my $incpath = catfile( $base, 'cpp', $_ );
            croak( "Cannot find $_ include directory under $base; please" .
                   " re-install Alien::InteractiveBrokers" )
                unless( -d $incpath );
            push( @includes, '-I' . $incpath );
        }

        $CACHE->{includes} = \@includes;
    }

    return( wantarray
              ? @includes
              : join( ' ', @includes ) );
}

sub classpath
{
    return( $CACHE->{classpath} )
        if( exists( $CACHE->{classpath} ) );

    my $jarfile = catfile( path(), 'jtsclient.jar' );

    croak( "Cannot find jtsclient.jar; please re-install" .
           " Alien::InteractiveBrokers." )
        unless( -f $jarfile );

    $CACHE->{classpath} = $jarfile;

    return( $jarfile );
}

sub version
{
    return( $CACHE->{version} )
        if( exists( $CACHE->{version} ) );

    my $verfile = catfile( path(), 'API_VersionNum.txt' );
    open my $fd, '<', $verfile or
        croak( "Cannot read API version file; please re-install" .
               " Alien::InteractiveBrokers." );
    my $contents = do { local $/; <$fd> };
    close( $fd );

    my( $vernum ) = ( $contents =~ m/API_Version=([\d\.]*)/mi );
    croak( "Could not read version number; please" .
           " reinstall Alien::InteractiveBrokers." )
        unless( defined( $vernum ) );

    $CACHE->{version} = $vernum;

    return( $vernum );
}

1;

__END__

=pod

=head1 NAME

Alien::InteractiveBrokers - Provides installation and config information for the InteractiveBrokers API

=head1 SYNOPSIS

    use Alien::InteractiveBrokers;

    my $IBAPI     = Alien::InteractiveBrokers->new();
    my $path      = $IBAPI->path();
    my $includes  = $IBAPI->includes();
    my $classpath = $IBAPI->classpath();
    my $version   = $IBAPI->version();

=head1 DESCRIPTION

This module automates the installation of the InteractiveBrokers API files
and source code, and provides accessor functions to describe its location,
include paths, etc.

It was developed in conjunction with L<Finance::InteractiveBrokers::SWIG>
and L<POE::Component::Client::InteractiveBrokers>, as a way of simplifying
distribution and installation of these needed files.

Please see L<Alien> for an explanation of the Alien namespace.

=head1 IB API VERSIONS

This module can install (downloading if necessary) and provide an interface for the following InteractiveBrokers API versions:

=over 4

=item B<9.64>

=item B<9.65>

=item B<9.66>

=item B<9.67>

=back

It currently comes bundled with IB API v9.66 (the latest production release).

=head1 CONSTRUCTOR

=head2 new()

    my $IBAPI = Alien::InteractiveBrokers->new();

Create a new Alien::InteractiveBrokers object for querying the installed
configuration.

B<ARGUMENTS:> None.

B<RETURNS:> blessed C<$object>, or C<undef> on failure.

=head1 METHODS

=head2 path()

    my $path = $IBAPI->path();

Get the base install path of the uncompressed IBJts directory.

B<ARGUMENTS:> None.

B<RETURNS:> Directory C<$name>, with no trailing path separator.

=head2 includes()

    # As string
    my $includes = $IBAPI->includes();

    # As list
    my @includes = $IBAPI->includes();

Get the required C<-I> include directives for compiling against this library.

B<ARGUMENTS:> None.

B<RETURNS:> Depending on context, returns a C<$scalar> containing all the paths joined with spaces, as C<-I/path>, or an C<@array> containing all the paths, as C<-I/path>, one-per-element.

=head2 classpath()

    my $classpath = $IBAPI->classpath();

Get the Java C<CLASSPATH> value for the F<jtsclient.jar> file containing the
compiled com.ib.client classes.

B<ARGUMENTS:> None.

B<RETURNS:> Full path to F<jtsclient.jar>, ready for the environment.

=head2 version()

    my $api_version = $IBAPI->version();

Get the version of the installed IB API.

(Not to be confused with L<Alien::InteractiveBrokers> C<$VERSION>, which is
this Perl wrapper's version number.)

B<ARGUMENTS:> None.

B<RETURNS:> IB API version number, as read from C<$path/API_VersionNum.txt>

=head1 EXPORTS

    use Alien::InteractiveBrokers qw( path includes classpath version );

This module OPTIONALLY exports the following subs:

=over 4

=item * L</"path()">

=item * L</"includes()">

=item * L</"classpath()">

=item * L</"version()">

=back

=head1 SEE ALSO

L<POE::Component::Client::InteractiveBrokers>

L<Finance::InteractiveBrokers::API>

L<Finance::InteractiveBrokers::SWIG>

L<Finance::InteractiveBrokers::Java>

The L<POE> documentation, L<POE::Kernel>, L<POE::Session>

L<http://poe.perl.org/> - All about the Perl Object Environment (POE)

L<http://www.interactivebrokers.com/> - The InteractiveBrokers website

L<http://www.interactivebrokers.com/php/apiUsersGuide/apiguide.htm> - The IB API documentation

The F<examples/> directory of this module's distribution

=head1 AUTHORS

Jason McManus, C<< <infidel at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

Many of the build scripts in this module were modelled on L<Alien::IE7>.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-alien-interactivebrokers at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Alien-InteractiveBrokers>.  The authors will be notified, and then you'll
automatically be notified of progress on your bug as changes are made.

If you are sending a bug report, please include:

=over 4

=item * Your OS type, version, Perl version, and other similar information.

=item * The version of Alien::InteractiveBrokers you are using.

=item * The version of the InteractiveBrokers API you are using.

=item * If possible, a minimal test script which demonstrates your problem.

=back

This will be of great assistance in troubleshooting your issue.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Alien::InteractiveBrokers

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Alien-InteractiveBrokers>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Alien-InteractiveBrokers>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Alien-InteractiveBrokers>

=item * Search CPAN

L<http://search.cpan.org/dist/Alien-InteractiveBrokers/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010-2012 Jason McManus

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

The authors are not associated with InteractiveBrokers, and as such, take
no responsibility or provide no warranty for your use of this module or the
InteractiveBrokers service.  You do so at your own responsibility.  No
warranty for any purpose is either expressed or implied by your use of this
module suite.

The data from InteractiveBrokers are under an entirely separate license that
varies according to exchange rules, etc.  It is your responsibility to
follow the InteractiveBrokers and exchange license agreements with the data.

=cut

# END
