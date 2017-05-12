package Apache::Application::Plus ;
$VERSION = 1.21 ;
use strict ;

# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; use base 'CGI::Application::Plus'
; use mod_perl
; use constant MP2 => $mod_perl::VERSION >= 1.99

; BEGIN
   { require File::Basename
   ; if ( MP2 )
      { require Apache::RequestRec
      ; require Apache::Response
      ; require Apache::Const
      ; Apache::Const->import( -compile => 'OK' )
      ; *handler = sub : method { shift()->_mp_run(@_) }
      }
     else
      { require Apache::Constants
      ; Apache::Constants->import( 'OK' )
      ; *handler = sub ($$) { shift()->_mp_run(@_) }
      }
   }

; use Object::props
      ( { name     => 'request'
        , allowed  => qr/::new_object$/
        }
      )
      
; sub _mp_run
   { my ($s, $r) = @_
   ; $s = $s->new_object($r) unless ref $s
   ; $s->run()
   ; MP2 ? Apache::OK : Apache::Constants::OK
   }

; sub _split_filename
   { File::Basename::fileparse( $_[1]->filename
                              , qr/\.[^.]+$/
                              )
   }

; sub new_object
   { my ($c, $r) = @_
   ; my $RM = $c->_split_filename($r)
   ; $c->new( runmode => $RM
            , request => $r
            )
   }

; 1


__END__

=pod

=head1 NAME

Apache::Application::Plus - Apache/mod_perl integration for CGI::Application::Plus

=head1 VERSION 1.21

Included in CGI-Application-Plus 1.21 distribution.

The latest versions changes are reported in the F<Changes> file in this distribution.

The distribution includes:

=over

=item * CGI::Application::Plus

CGI::Application rewriting with several pluses

=item * Apache::Application::Plus

Apache/mod_perl integration for CGI::Application::Plus

=item * CGI::Application::Magic

Template based framework for CGI applications

=item * Apache::Application::Magic

Apache/mod_perl integration for CGI::Application::Magic

=item * CGI::Application::CheckRM

Checks run modes using Data::FormValidator

=back

=head1 INSTALLATION

=over

=item Prerequisites

    Apache/mod_perl 1 or 2
    Perl version >= 5.6.1
    OOTools      >= 1.6

=item CPAN

    perl -MCPAN -e 'install CGI::Application::Plus'

If you want to install also all the prerequisites to use C<CGI::Application::Magic>), all in one easy step:

    perl -MCPAN -e 'install Bundle::Application::Magic'

=item Standard installation

From the directory where this file is located, type:

    perl Makefile.PL
    make
    make test
    make install

=back

=head1 SYNOPSIS

   # used instead of CGI::Application::Plus
   use base 'Apache::Application::Plus' ;
   
   # direct interaction with the Apache request object
   $r = $self->request ;
   %headers = $r->headers_in ;
   
   # virtual run mode pages
   # instead of using this
   http://www.yourdomain.com/cgi-bin/appScript.pl?rm=aRunMode
   
   # you can use this
   http://www.yourdomain.com/aRunMode

=head1 DESCRIPTION

This module is a C<CGI::Application::Plus> sub class that supply a perl handler to integrate your application modules with the Apache/mod_perl server.

Use this module as base class instead of the C<CGI::Application::Plus>, if your application can take advantage from accessing the Apache request object (available as the C<request> property), and/or to run() your application in a handy and alternative way. If you don't need any of the above features, you can use the C<CGI::Application::Plus> module that is however fully mod_perl 1 and 2 compatible.

B<Note>: most of the interesting reading of how organize your application module are in L<CGI::Application::Plus>.

B<Note>: An extremely powerful alternative to this module is the L<Apache::Application::Magic|Apache::Application::Magic>, that can easily implement a sort of "Perl Side Include" (sort of easier, more powerful and flexible "Server Side Include").

=head2 No Instance Script needed

All the generic CGI applications I<(old, Plus and Magic)>, use an Instance Script to call the Application Module. The script is usually like this:

    #!/usr/bin/perl -w
    use MyWebApp;                   # the Application module
    my $webapp = MyWebApp->new();   # create a new instance
    $webapp->run();                 # run and produce the output page

With C<Apache::Application::Plus> the Apache/mod_perl server uses the Application module directly (throug the perl handler supplied by this module), without the need of any Instance Script.

=head2 The Perl Handler

This module provide a mod_perl 1 and 2 compatible handler that internally creates and run() the Application object, after setting a couple of object properties:

=over

=item * request

This property is set to the Apache request object. Use it to interact directly with all the Apache/mod_perl internal methods.

=item * runmode

The default runmode is set to the base name of the requested filename (e.g. being the requested filename F</path/to/file.mhtml>, the default runmode will be set to 'file'). Use it as an alternative and handy way to pass the runmode.

=back

B<Note>: Usually you don't need to use neither the perl handler nor these properties, because they are all internally managed.

=head3 How to pass the runmode

In a generic CGI Application the run mode usually comes from a query parameter or from code inside your application. Both ways are still working with this module, but you have another way: use the base filename of your links as the runmode.

E.g.: Providing that the RootDirectory of C<'yourdomain.com'> has been correctly configured to be handled by your Application module:

Instead of using this (good for any generic CGI application):

    http://www.yourdomain.com/cgi-bin/appScript.pl?rm=aRunMode

You can use this:

    http://www.yourdomain.com/aRunMode

Same thing with more query parameters:

    http://www.yourdomain.com/cgi-bin/appScript.pl?rm=aRunMode&myField=aValue
    http://www.yourdomain.com/aRunMode?myField=aValue

B<Note>: Remember that this technique utilize the default runmode. Default means that it is overridable by setting explicitly the runmode inside your code, or passing an explicit 'rm' query parameter. (i.e. if you want to use the provided default, you have just to avoid to set it explicitly).

=head1 Apache configuration

The Apache configuration for mod-perl 1 or 2 is extremely simple. In order to use e.g. your F<FooBar.pm> Application module, you have to follow these steps:

=over

=item 1 tell mod_perl to load FooBar.pm

You can do this in several ways.

In the F<startup.pl> file (or equivalent) you can simply add:

    use FooBar () ;

or you can tell mod_perl to load it from inside any configuration files:

    PerlModule FooBar

or if your F<FooBar.pm> file is not in the mod_perl C<@INC> this will work as well from any Apache configuration file:

   PerlRequire /path/to/FooBar.pm

=item 2 tell mod_perl to use it as a (response) handler

In F<.htaccess> file

For mod_perl 1:

    SetHandler perl-script
    PerlHandler FooBar

For mod_perl 2:

    SetHandler perl-script
    PerlResponseHandler FooBar

B<Note>: In order to use this module, the only difference between mod_perl 1 and 2 configuration, is the mod_perl handler name C<'PerlHandler'> that becomes C<'PerlResponseHandler'> for the version 2.

=item 3 restrict its use to fit your needs

Use the Apache configuration sections C<Location>, C<Directory>, C<DirectoryMatch>, C<Files>, C<FilesMatch> etc. to restrict the use of the handler (see also the Apache Directive documentation)

   # example 1: httpd.conf
   # only if runs under mod_perl
   <IfModule mod_perl.c>
        PerlModule FooBar
        # limited to the dir /some/path
        <Directory /some/path>
            SetHandler perl-script
            PerlHandler FooBar
        </Directory>
   </IfModule>

   # example 2: /some/path/.htaccess file
   # only if runs under mod_perl
   <IfModule mod_perl.c>
        PerlModule FooBar
        SetHandler perl-script
        PerlHandler FooBar
   </IfModule>

=back

B<Note>: see also the F</magic_examples/perl_side_include/.htaccess> file in this distribution.

=head1 METHODS

This module adds just one method to the standard C<CGI::Application::Plus> methods.

=head2 new_object()

This method initializes and returns the internal C<Apache::Application::Plus> object. You can override it if you know what you are doing, or you can simply ignore it ;-).

B<Note>: This method is here just if you need to override the way the module generates the object. Think about this method as it were an included Instance Script that could create the object by setting different properties and/or parameters. Anyway you have alternative methods to change the object properties, such as e.g. the setup() and cgiapp_init() methods.

=head1 PROPERTY ACCESSORS

This module adds just one property to the standard C<CGI::Application::Plus> properties.  

=head2 request

This property allows you to access the request Apache object.

=head1 SUPPORT and FEEDBACK

If you need support or if you want just to send me some feedback or request, please use this link: http://perl.4pro.net/?Apache::Application::Plus.

=head1 AUTHOR and COPYRIGHT

© 2004 by Domizio Demichelis.

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.

=cut
