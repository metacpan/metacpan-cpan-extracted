package Apache::CGI::Builder ;
$VERSION = 1.3 ;
use strict ;
# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; use Carp
; $Carp::Internal{+__PACKAGE__}++
; use mod_perl
; our $usage = << ''
Apache2::CGI::Builder should be used INSTEAD of CGI::Builder and should not be included as an extension

; my $MP2

; BEGIN
   { require File::Basename
   ; if ( $MP2 = $mod_perl::VERSION >= 1.99 )
      { require Apache::RequestRec
      ; require Apache::Response
      ; require ModPerl::Util
      ; require Apache::Const
      ; Apache::Const->import( -compile => 'OK' )
      ; *PerlResponseHandler = sub { shift()->PerlHandler(@_) }
      ; *handler = sub : method
                    { shift()->Apache::CGI::Builder::_::dispatcher(@_)
                    }
      }
     else
      { require Apache::Constants
      ; Apache::Constants->import( 'OK' )
      ; *handler = sub ($$)
                    { shift()->Apache::CGI::Builder::_::dispatcher(@_)
                    }
      }
   }

; sub import
   { undef $usage
   ; require CGI::Builder
   ; unshift @_, 'CGI::Builder'
   ; goto &CGI::Builder::import
   }

; use Class::props
        { name       => 'no_page_content_status'
        , default    => '404 Not Found'
        }

; use Object::props
        { name     => 'r'
        , default  => sub{ Apache->request }
        }

; sub PerlHandler
   { my $s = shift
   ; $s = $s->new() unless ref $s
   ; $s->process()
   ; $MP2
     ? Apache::OK()
     : Apache::Constants::OK()
   }

; sub OH_init
   { my $s = shift
   ; $ENV{MOD_PERL}
     or croak 'Cannot use Apache::CGI::Builder without mod_perl, died'
   ; my $filename = $s->r->filename
   ; my ( $page_name, $page_path, $page_suffix )
   ; if (-d $filename)
      { $page_path = $filename
      }
     else
      { ( $page_name, $page_path, $page_suffix )
        = File::Basename::fileparse ( $filename
                                    , qr/\..+$/
                                    )
      }
   ; $s->page_name($page_name)     unless defined $$s{page_name}
   ; $s->page_path($page_path)     unless defined $$s{page_path}
   ; $s->page_suffix($page_suffix) unless defined $$s{page_suffix}
   }

; sub Apache::CGI::Builder::_::dispatcher
   { my ($s, $r) = @_
   ; my $cur = $MP2
               ? ModPerl::Util::current_callback()
               : $r->current_callback
   ; if ( my $h = $s->can($cur) )
      { $h->(@_)
      }
     else
      { croak sprintf '"%s" does not implement any "%s" method, died'
                    , ref $s
                    , $cur
      }
   }

; 1

__END__

=pod

=head1 NAME

Apache::CGI::Builder - CGI::Builder and Apache/mod_perl (1 and 2) integration

=head1 VERSION 1.3

The latest versions changes are reported in the F<Changes> file in this distribution. To have the complete list of all the extensions of the CBF, see L<CGI::Builder/"Extensions List">

=head1 INSTALLATION

=over

=item Prerequisites

    Apache/mod_perl 1 or 2 (PERL_METHOD_HANDLERS enabled)
    CGI::Builder >= 1.2

=item CPAN

    perl -MCPAN -e 'install Apache::CGI::Builder'

You have also the possibility to use the Bundle to install all the extensions and prerequisites of the CBF in just one step. Please, notice that the Bundle will install A LOT of modules that you might not need, so use it specially if you want to extensively try the CBF.

    perl -MCPAN -e 'install Bundle::CGI::Builder::Complete'

=item Standard installation

From the directory where this file is located, type:

    perl Makefile.PL
    make
    make test
    make install

=back

=head1 SYNOPSIS

   # use instead of the CGI::Builder
   use Apache::CGI::Builder
   qw| ... other inclusions ...
     |;
   
   # deprecated way of inclusion still working
   use CGI::Builder
   qw| Apache::CGI::Builder
       ... other inclusions ...
     |;
   
   # direct interaction with the Apache request object
   $r = $self->r ;
   %headers = $self->r->headers_in ;
   
   # virtual pages: instead of using this
   http://www.yourdomain.com/cgi-bin/IScript.cgi?p=a_page
   
   # you can use this
   http://www.yourdomain.com/a_page

=head1 DESCRIPTION

B<Note>: You should know L<CGI::Builder>.

This module is a subclass of C<CGI::Builder> that supply a perl method handler to integrate your CBB with the Apache/mod_perl server: most of the interesting reading about how to organize your CBB are in L<CGI::Builder>.

You should use this module B<instead of CGI::Builder> if your application can take advantage from accessing the Apache request object (available as the C<r> property), and/or to run your application in a handy and alternative way. If you don't need any of the above features, you can use the C<CGI::Builder> module that is however fully mod_perl 1 and 2 compatible.

B<Note>: An extremely powerful combination with this extension is the L<CGI::Builder::Magic|CGI::Builder::Magic>, that can easily implement a sort of L<Perl Side Include|CGI::Builder::Magic/"Perl Side Include"> (sort of easier, more powerful and flexible "Server Side Include").

B<IMPORTANT NOTE>: If you use 'mod_perl2' (new namespace), you must use the L<Apache2::CGI::Builder|Apache2::CGI::Builder> module, installed with this distribution.

=head1 DIFFERENCES

This module implements a few differences with the regular CGI::Builder module:

=head2 Passing the page_name

In a regular CBA the page_name usually comes from a query parameter or from code inside your application (if you have overridden the get_page_name() method). Both ways are still working with this extension, but you have another way: use the base filename of your links as the page_name.

E.g.: Providing that the RootDirectory of C<'yourdomain.com'> has been correctly configured to be handled by your CBB:

Instead of using this (good for any regular CBA):

    http://www.yourdomain.com/cgi-bin/IScript.pl?p=a_page

You can use this:

    http://www.yourdomain.com/a_page

Same thing with more query parameters:

    http://www.yourdomain.com/cgi-bin/IScript.pl?p=a_page&myField=aValue
    http://www.yourdomain.com/a_page?myField=aValue

B<Note>: Remember that this technique utilizes the default page_name. Default means that it is overridable by setting explicitly the page_name inside your code, or passing an explicit 'p' query parameter. (i.e. if you want to use the provided default, you have just to avoid to set it explicitly).

B<Warning>: This extension sets the C<page_name> property to the basename of the Apache filename variable, which is the result of the C<< URI -> filename >> translation. For this reason, on some systems, the C<page_name> could be not exactly the basename of the requested URI, and it could result in a string composed by all small caps characters, even if the requested URI was composed by all upper caps characters.

For example this URI:

    http:://www.yourdomain.com/aPage.html

could generate a C<page_name> equal to 'apage' which probably does not match with your C<SH_aPage> C<PH_aPage> handlers, so in order to avoid possible problems, I would suggest the most simple and compatible solution, which is: always use all small caps for page names, templates names, page and switch handlers, URLs, ...

=head2 No Instance Script

A regular CGI::Builder application, uses an Instance Script to make an instance of the CBB. With C<Apache::CGI::Builder> the Apache/mod_perl server uses the CBB directly (throug the perl method handler supplied by this module), without the need of any Instance Script.

=head2 Passing Arguments

You usually don't need to pass any argument to the new method, because this module internally creates the new object and executes the process at each request, but sometimes it may be useful to set some properties from outside the CBB. In order to do so, even if you don't have any instance script, you can however pass the arguments that your CBB needs from the Apache configuration files (see L<"Apache Configuration"> for more details).

=head1 Apache Configuration

This module provides a mod_perl 1 and 2 compatible method handler which internally creates the CBB object and produce the output page, after setting a few properties.

B<Note>: Since the provided handler is a B<method handler>, your mod_perl must have PERL_METHOD_HANDLERS enabled in order to work. If your mod_perl is > 1.25 you can check the option by running the following code:

   $ perl -MApache::MyConfig \
   -e 'print $Apache::MyConfig::Setup{PERL_METHOD_HANDLERS};'
   1

The Apache configuration for mod-perl 1 or 2 is extremely simple. In order to use e.g. your F<FooBar.pm> CBB from any F<.htaccess> file or F<httpd.conf>, you have to follow these steps:

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

The only difference between mod_perl 1 and 2 configuration, is the mod_perl handler name C<'PerlHandler'> that becomes C<'PerlResponseHandler'> for the version 2.

For mod_perl 1:

    SetHandler perl-script
    PerlHandler FooBar

For mod_perl 2:

    SetHandler perl-script
    PerlResponseHandler FooBar

B<Note>: If you need to pass some arguments to the new object you can create and pass it as the handler:

   <perl>
       $My::Obj = FooBar->new ( my_param1 => 'value1' ,
                                my_param2 => 'value2' )
   </perl>
   
   SetHandler perl-script
   PerlHandler $My::Obj

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

This module adds a few internally used methods to your CBB. You don't need to use them directly, but you should know that they exist in order to avoid to unwittingly override them.

=over

=item handler

Generic method used as a method handler dispatcher

=item PerlHandler

This method is used as the response method handler

=item PerlResponseHandler

PerlHandler alias used by mod_perl 2

=back

=head2 OH_init

This method internally initializes the C<page_name>, C<page_path>, C<page_suffix> defaults.

=head1 PROPERTY ACCESSORS

=head2 r

This is the only property added to the standard C<CGI::Builder> properties. It is set to the Apache request object: use it to interact directly with all the Apache/mod_perl internal methods.

=head2 CBF changed property defaults

=head3 CBF page_name

The default page_name is set to the base name of the requested filename (e.g. being the requested filename F</path/to/file.mhtml>, the default page_name will be set to 'file'). This is an alternative and handy way to avoid to pass the page_name with the query.

B<Note>:In case you have to handle a file with a multiple suffix like 'file.tar.gz' the C<page_name> will be 'file'

=head3 CBF page_path

The default C<page_path> property is set to the directory that contains the requested file.

=head3 CBF page_suffix

The default C<page_suffix> property is set to the suffix of the requested filename (e.g. being the requested filename F</path/to/file.mhtml>, the default page_suffix will be set to '.mhtml').

B<Note>:In case you have to handle a file with a multiple suffix like 'file.tar.gz' the C<suffix> will be '.tar.gz'

=head1 CBF Overriding

=head2 CBF no_page_content_status

This extension overrides this class property by just changing the '204 No Content' (that the CBF sets when no page_content has been produced by the process), with a more consistent '404 Not Found' status. It does so because the client is requesting a simple not found page, which is a very different situation from a found CGI script that does not send any content (204 No Content).

=head1 Selfloading Perl*Handlers

The CBB that uses this module, will have a special feature: a sort of Selfloading of Perl*Handlers.

When you pass a CBB class (or an instance of the CBB) as a Perl*Handler, this module will use (as the method handler) the method called with the same name of the Perl*Handler. For example:

    PerlAnyHandler My::CBB

which normally would mean:

    PerlAnyHandler My::CBB->handler

get interpreted by this module as:

    PerlAnyHandler My::CBB->PerlAnyHandler

This means that if any extension needs to implement any handler, it could just define a Perl*Handler() method with the same name, and recommend the use of the CBB class as that particular Perl*Handler. This feature adds some encapsulation and simplify the use of the extension.

B<Note>: the user could explicitly bypass this feature by using explicit method handlers e.g.:

    PerlAnyHandler My::CBB->AnySpecialHandler

=head1 SUPPORT

See L<CGI::Builder/"SUPPORT">.

=head1 AUTHOR and COPYRIGHT

© 2004 by Domizio Demichelis (L<http://perl.4pro.net>)

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.

=cut
