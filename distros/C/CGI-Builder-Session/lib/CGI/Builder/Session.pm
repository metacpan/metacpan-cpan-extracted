package CGI::Builder::Session ;
$VERSION = 1.26 ;
use strict ;

# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; use CGI::Session
; $Carp::Internal{+__PACKAGE__}++
; $Carp::Internal{'CGI::Session'}++
; use File::Spec

; use Object::props
      ( { name       => 'cs'
        , default    => sub{ shift()->cs_new(@_) }
        }
      )
      
; use Object::groups
      ( { name       => 'cs_new_args'
        , default
          => sub
              { return { DSN       => undef
                       , SID       => $_[0]->cgi
                       , DSN_param => { Directory => File::Spec->tmpdir }
                       }
              }
        }
      )
      
; sub cs_new
   { my $s    = shift
   ; my $args = $s->cs_new_args
   ; my $cso  = CGI::Session->new( @$args{qw| DSN
                                              SID
                                              DSN_param
                                            |
                                         }
                                 )
   ; $s->cs_init($cso)
   ; if ($cso->is_new)
      { if ( my $new_session_init = $$args{new_session_init} )
         { $s->$new_session_init($cso)
         }
      }
   ; if ( my $session_init = $$args{session_init} )
      { $s->$session_init($cso)
      }
   ; $cso
   }
   
; sub cs_init
   { my ($s, $cso) = @_
   ; if ( $cso->is_new ) # new session
      { my $cs_cookie = $s->cgi->cookie($CGI::Session::NAME => $cso->id)
      ; my $cookie_header = $s->header('-cookie')
      ; $s->header(-cookie => ref $cookie_header eq 'ARRAY'
                              ? do{ push @$cookie_header, $cs_cookie
                                  ; $cookie_header
                                  }
                              : $cookie_header
                                ? [ $cookie_header, $cs_cookie ]
                                : $cs_cookie
                  )
      ; $s->cgi->param($CGI::Session::NAME => $cso->id)
      }
   }

; 1

__END__

=pod

=head1 NAME

CGI::Builder::Session - CGI::Builder and CGI::Session integration

=head1 VERSION 1.26

The latest versions changes are reported in the F<Changes> file in this distribution. To have the complete list of all the extensions of the CBF, see L<CGI::Builder/"Extensions List">

=head1 INSTALLATION

=over

=item Prerequisites

    CGI::Builder >= 1.2
    CGI::Session >= 3.95
    File::Spec   >  0

=item CPAN

    perl -MCPAN -e 'install CGI::Builder::Session'

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

    use CGI::Builder
    qw| CGI::Builder::Session
        ...
      |;

=head1 DESCRIPTION

B<Note>: You should know L<CGI::Builder>.

This module transparently integrates C<CGI::Builder> and C<CGI::Session> in a very handy and flexible framework that can save you some coding. It provides you a mostly automatic and ready to use CGI::Session object (C<cs> property) useful to maintain the state of your application between requests. Please refer to L<CGI::Session> for more documentation about sessions.

=head2 How it works

This extension creates a CGI::Session object automatically, using the old session id if it is found as a cookie or as a query param. If no session id is found, it creates a new session and automatically adds a session id cookie and a session id param that will be automatically used to send the id to the client

In simple cases you can avoid to init, update and flush the session: just use it and it will work as expected; if you need more customization you can override every single argument, property or even method.

B<Note>: When you include in your CBB the L<CGI::Builde::Magic|CGI::Builde::Magic> extension, you will have magically available a label that will be substituted with the current session id.

=head1 PROPERTY and GROUP ACCESSORS

This module adds some session properties (all those prefixed with 'cs_') to the standard CBF properties. The default of these properties are usually smart enough to do the right job for you, but you can fine-tune the behaviour of your CBB by setting them to the value you need.

=head2 cs

This property returns the internal C<CGI::Session> object that is automatically created just before you use it. It is already initialized with the existing session or with a new session if there are no existing session yet. Anyway, you can directly use it in your code without any other initialization.

    # check some flag
    sub OH_pre_process {
        my $s = shift;
        $s->cs->param('logged')
           || switch_to('login');
    }

    # saves cgi parameter for later use
    sub PH_myPage1 {
        my $s = shift;
        $s->cs->save_param($s->cgi, "category");
    }

    # retrieve a session parameter saved in a previous request
    sub PH_myPage2 {
        my $s = shift;
        my $categ = $s->cs->param("category");
    }

B<Note>: You can change the default arguments that are internally used to create the object by using the C<cs_new_args> group accessor, or you can completely override the creation of the internal object by overriding the C<cs_new()> method.

=head2 cs_new_args( arguments )

This property group accessor handles the CGI::Session constructor arguments that are used in the creation of the internal CGI::Session object. Use it to change the argument you need to the creation of the new object. B<Note>: use it BEFORE using the C<cs> object or your arguments will be ignored.

It uses the following defaults:

=over

=item * DSN

Data Source Name: this argument is set to the undef value by default (i.e. DSN equal to File).

=item * SID

Session ID: this argument is set by default to the cookie, or to the query param named $CGI::Session::NAME (usually 'CGISESSID'), or to the undef value if neither the cookie nor the param are found.

=item * DSN_param

Data Source Name param This argument is referring to the File DSN, and is set by default to:

    { Directory => File::Spec->tmpdir }

=item * new_session_init

A method name or a CODE reference which will be executed only if the session is new (i.e. if it has been created in the current request). The sub will receive the WebApp object in $_[0], and the session object in $_[1]. You can use it to add options to the session object:

   new_session_init => 'any_method'
   new_session_init => \&any_sub
   new_session_init => sub{ ... }

A tipical usage could be:

   new_session_init => sub{ my ($s, $session) = @_ ;
                            $session->expires("+1y"); }

=item * session_init

A method name or a CODE reference which will be executed each time the session is created and regardless the session is new or not. The sub will receive the WebApp object in $_[0], and the session object in $_[1]. Use it as an alternative instead of overriding the C<cs_init()> method when you have just to add some initialization and you don't want to change the default behaviour.

   session_init => 'any_method'
   session_init => \&any_sub
   session_init => sub{ ... }

=back

These defaults produce the most compatible and multiplatform CGI::Session object which is equal to:

    CGI::Session->new( undef,    # DNS equal to File
                       $s->cgi , # SID equal to cookie or param $CGI::Session::NAME
                       { Directory => File::Spec->tmpdir } # DSN_param for File
                     );

B<Note>: You should change just the argument that you need to customize, i.e. usually just DSN and DSN_param and maybe new_session_init:

   $s->cs_new_args( DSN => .... ,
                    DSN_param => .... ,
                    new_session_init => sub{ ... },
                  );

=head1 METHODS

=head2 cs_new()

This method is not intended to be used directly in your CBB. It is used internally to initialize and return the C<CGI::Session> object. You usually don't need even to override it since you can customize the C<cs> object by using the C<cs_new_args> group accessor, or eventually override the C<cs_init> method.

=head2 cs_init

This method is internally called by the C<cs_new()> method, so you don't need to know about it unless you need to override it. The purpose of this method is adding the session id cookie to the headers. Besides it adds also the session id query param to the query. (B<Note>: those operations are done only if the session is new and using the $CGI::Session::NAME as the name of the cookie and query param, so you can set that variable as usual to set a different session id name.)

You should override this method only if you need to pass the new session id by any other mean (in this case you should also accordingly update the 'SID' argument of the C<cs_new_args>).

B<Overriding Note>: At the moment this method is executed, the C<cs> property is not set yet, but the CGI::Session object is already created and available as $_[1].

=head1 SUPPORT

See L<CGI::Builder/"SUPPORT">.

=head1 AUTHOR and COPYRIGHT

© 2004 by Domizio Demichelis (L<http://perl.4pro.net>)

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.

=cut
