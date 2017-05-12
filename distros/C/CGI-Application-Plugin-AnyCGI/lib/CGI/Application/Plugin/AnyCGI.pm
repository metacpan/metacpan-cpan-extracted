## -------------------------------------------------------------------
## C::A::Plugin
##--------------------------------------------------------------------

package CGI::Application::Plugin::AnyCGI;
use strict;
use warnings;

=pod

=head1 NAME

CGI::Application::Plugin::AnyCGI - Use your favourite CGI::* module
with CGI::Application (instead of CGI.pm)

=head1 VERSION

Version 0.02

=cut

$CGI::Application::Plugin::AnyCGI::VERSION = '0.02';

## to enable debugging, set this to "1" or any other "true" value
$CGI::Application::Plugin::AnyCGI::DEBUG = 0;

our ( @ISA, $AUTOLOAD );

=pod

=head1 SYNOPSIS

In your L<CGI::Application|CGI::Application>-based module:

    use base 'CGI::Application';
    use CGI::Application::Plugin::AnyCGI;

    sub cgiapp_get_query() {
        my $self = shift;
        return CGI::Application::Plugin::AnyCGI->new(
            cgi_modules => [ qw/ CGI::Minimal CGI::Simple / ],
            ## any other options given here are passed to the  
            ## loaded CGI::* module
        );
    }


=head1 DESCRIPTION

This module allows to use (nearly) any CGI.pm compatible CGI::* module 
with L<CGI::Application|CGI::Application>. Just give a list of your preferred modules by 
using the C<cgi_modules> option with L<new|new>(). The modules are checked 
in the same order they appear, so see it as a list of fallbacks.

If none of the modules in the C<cgi_modules> list can be loaded, the 
Plugin silently loads L<CGI.pm|CGI> as a final fallback.

If a method is called that is not provided by the module currently in 
use, it will be silently loaded from L<CGI.pm|CGI>. This may eat up 
the "performance boost" you could have expected by using any other 
CGI::* module for your application, but on the other hand you don't 
have to worry about incompatibilities. ;)


=head1 METHODS

=head2 new

This is the only (public) method C<C::A::P::AnyCGI> provides. The one 
and only parameter C<C::A::P::AnyCGI> uses is C<cgi_modules>.

=head3 Calling new() without any further options

If no additional options are passed, C<C::A::P::AnyCGI> returns an 
instance of itself, with the loaded module pushed at it's @ISA. (So, 
it acts as an empty subclass, just adding it's C<AUTOLOAD> method to 
it's parent.)

B<Example:>

    CGI::Application::Plugin::AnyCGI->new(
        cgi_modules => [ qw/ CGI::Minimal CGI::Simple / ]
    );

...returns an instance of CGI::Application::Plugin::AnyCGI, which 
inherits all methods of C<CGI::Minimal> or C<CGI::Simple> (or, as a
final fallback, of C<CGI>).

=head3 Calling new() with further options

If you pass any options, an instance of the loaded CGI::* module is 
created, passing all options (except C<cgi_modules>) to the 
constructor. C<C::A::P::AnyCGI> then imports it's C<AUTOLOAD> method 
to the loaded module, returning the instance it created.

Example:

    CGI::Application::Plugin::AnyCGI->new(
        cgi_modules => [ qw/ CGI::Simple / ],
        { 'foo'=>'1', 'bar'=>[2,3,4] }
    );

...creates an instance of C<CGI::Simple>, passing some params for
initializing, and returns this instance to the caller.

B<Warning:> As the different CGI::* modules don't take the same
arguments to C<new>, this may not work as expected, so it may be better
not to use this option.

=cut

#-------------------------------------------------------------------
# METHOD:     new
# + author:   Bianka Martinovic
# + reviewed: Bianka Martinovic
# + purpose:  
#-------------------------------------------------------------------
sub new {
    my $caller = shift;
    my $class  = ref($caller) || $caller;

    my %args   = (
        cgi_modules => [ 'CGI::Minimal' ], 
        @_ 
    );
    
    my $module;
    my $loaded;
    
    TRY:
    {
        foreach $module ( @{$args{'cgi_modules'}} ) {
        
            $CGI::Application::Plugin::AnyCGI::DEBUG and
                __PACKAGE__->_debug( "Trying module $module" );
            
            eval "use $module";
            
            if ( ! $@ ) {
                push @ISA, $module;
                $loaded = $module;
                $CGI::Application::Plugin::AnyCGI::DEBUG and
                    __PACKAGE__->_debug( "Loaded module $module" );
                last TRY;
            }
            
        }
    }   # TRY:
    
    unless ( $loaded ) {
        ## Fallback to CGI.pm (included in Perl Core)
        $CGI::Application::Plugin::AnyCGI::DEBUG and
            __PACKAGE__->_debug( "Fallback to CGI.pm" );
        eval "use CGI qw/:standard/";
        push @ISA, 'CGI';
        $loaded = 'CGI';
    }
    
    $CGI::Application::Plugin::AnyCGI::DEBUG and
        __PACKAGE__->_debug( "CGI module loaded: " . $loaded );
        
    delete $args{'cgi_modules'};
    
    if ( %args ) {
        my $self = $loaded->new( %args );
        no strict 'refs';
        *{ $loaded . '::AUTOLOAD' } = *CGI::Application::Plugin::AnyCGI::AUTOLOAD;
        return $self;        
    }
    else {
        return bless {}, $class;
    }
    
}   # --- end sub new ---


#-------------------------------------------------------------------
#                  + + + + + PRIVATE + + + + + 
#-------------------------------------------------------------------

=pod

=head1 DEBUGGING

This module provides some internal debugging. Any debug messages go to 
STDOUT, so beware of enabling debugging when running in a web 
environment. (This will end up with "Internal Server Error"s in most
cases.)

There are two ways to enable the debug mode:

=over 4

=item In the module

Find line

    $CGI::Application::Plugin::AnyCGI::DEBUG = 0;

and set it to any "true" value. ("1", "TRUE", ... )

=item From outside the module

Add this line B<before> calling C<new>:

    $CGI::Application::Plugin::AnyCGI::DEBUG = 1;

=back

=cut

#-------------------------------------------------------------------
# METHOD:     _debug
# + author:   Bianka Martinovic
# + reviewed: 07-11-14 Bianka Martinovic
# + purpose:  print out formatted _debug messages
#-------------------------------------------------------------------
sub _debug {
    my $self = shift;
    my $msg  = shift;
    
    my $dump;
    if ( @_ ) {
        if ( scalar ( @_ ) % 2 == 2 ) {
            %{ $dump } = ( @_ );
        }
        else {
            $dump = \@_;
        }
    }
    
    my ( $package, $line, $sub ) = (caller())[0,2,3];
    my ( $callerpackage, $callerline, $callersub ) 
        = (caller(1))[0,2,3]; 
    
    $sub ||= '-';
    
    print "\n",
          join( ' | ', $package, $line, $sub ),
          "\n\tcaller: ",
          join( ' | ', $callerpackage, $callerline, $callersub ),
          "\n\t$msg",
          "\n\n";
    
    #if ( $dump ) {
    #    print $self->_dump( $dump );
    #}
    
    return;
}   # --- end sub _debug ---

#-------------------------------------------------------------------
# METHOD:     AUTOLOAD
# + author:   Bianka Martinovic
# + reviewed: Bianka Martinovic
# + purpose:  autoloading methods missing in the current CGI module 
#             by using CGI.pm
#-------------------------------------------------------------------
sub AUTOLOAD {
    my $self = shift;
    my ($method) = $AUTOLOAD =~ /^.*::(.*)$/;
    return if ( $method =~ /^DESTROY$/ );
    no strict 'refs';
    eval "use CGI qw/$method/";
    &$method(@_);
}   # --- end sub AUTOLOAD ---

1;

__END__


=pod

=head1 PREREQUISITES

None.

While this plugin is made for use with 
L<CGI::Application|CGI::Application>, it should also work without it,
so you should be able to use it with any other application you wish to
be "CGI.pm independent".


=head1 AUTHOR

Bianka Martinovic, C< <<mab at cpan.org>> >

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-anycgi at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-AnyCGI>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Application::Plugin::AnyCGI

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-Application-Plugin-AnyCGI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-Application-Plugin-AnyCGI>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Application-Plugin-AnyCGI>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-Application-Plugin-AnyCGI>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Bianka Martinovic, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

