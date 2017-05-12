package CGI::Builder::HTMLtmpl ;
$VERSION = 1.21 ;
use strict ;

# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; use HTML::Template
; use File::Spec
; $Carp::Internal{'HTML::Template'}++
; $Carp::Internal{+__PACKAGE__}++

; my $print_code
; BEGIN
   { $print_code = sub{ shift()->CGI::Builder::HTMLtmpl::_::ht_print(@_) }
   }

; use Object::props
      ( { name       => 'ht'
        , default    => sub{ shift()->ht_new(@_) }
        }
      , { name       => 'page_suffix'
        , default    => '.tmpl'
        }
      , { name       => 'page_content'
        , default    => sub{ $print_code }
        }
      )
      
; use Object::groups qw| ht_new_args ht_param |

; sub ht_new
   { my $s = shift
   ; HTML::Template->new( filename => $s->page_name . $s->page_suffix
                        , path     => [ $s->page_path ]
                        , %{$s->ht_new_args}
                        )
   }

; sub page_content_check
   { my $s  = shift
   ; $s->page_content eq $print_code   # managed by ht
     ? $s->CGI::Builder::HTMLtmpl::_::ht_exists
     : $s->CGI::Builder::page_content_check
   }

; sub CGI::Builder::HTMLtmpl::_::ht_print
   { my $s = shift
   ; $s->ht->param( %{$s->ht_param} )
   ; print $s->ht->output()
   }
   
# adapted from HTML::Template::_find_file
# it implements the same logic

; sub CGI::Builder::HTMLtmpl::_::ht_exists
   { my $s = shift
   ; my $filename =  $$s{ht_new_args}{filename}
                  || $s->page_name.$s->page_suffix
   ; my $path     =  $$s{ht_new_args}{path}
                  || [ $s->page_path ]
   # first check for a full path
   ; if ( File::Spec->file_name_is_absolute( $filename ) )
      { return 1 if -e $filename
      }
   # try pre-prending HTML_Template_Root
   ; if ( exists $ENV{HTML_TEMPLATE_ROOT} )
      { return 1 if -e File::Spec->catfile( $ENV{HTML_TEMPLATE_ROOT}
                                          , $filename
                                          )
      }
   # try "path" option list..
   ; foreach my $p ( @$path )
      { return 1 if -e File::Spec->catfile( $p
                                          , $filename
                                          )
      }
   # try even a relative path from the current directory...
   ; return 1 if -e $filename
   # try "path" option list with HTML_TEMPLATE_ROOT prepended...
   ; if ( exists $ENV{HTML_TEMPLATE_ROOT} )
      { foreach my $p ( @$path )
         { return 1 if -e File::Spec->catfile( $ENV{HTML_TEMPLATE_ROOT}
                                             , $p
                                             , $filename
                                             )
         }
      }
   ; return undef
   }
      
; 1
   
__END__

=pod

=head1 NAME

CGI::Builder::HTMLtmpl - CGI::Builder and HTML::Template integration

=head1 VERSION 1.21

To have the complete list of all the extensions of the CBF, see L<CGI::Builder/"Extensions List">

=head1 INSTALLATION

=over

=item Prerequisites

    CGI::Builder    >= 1.0
    HTML::Template  >= 2.6

=item CPAN

    perl -MCPAN -e 'install CGI::Builder::HTMLtmpl'

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
    qw| CGI::Builder::HTMLtmpl
        ...
      |;

=head1 DESCRIPTION

B<Note>: You should know L<CGI::Builder>.

This module transparently integrates C<CGI::Builder> and C<HTML::Template> in a very handy and flexible framework that can save you some coding. It provides you a mostly automatic template system based on HTML::Template: usually you will have just to supply the run time values to the object and this extension will manage automatically all the other tasks of the page production process (such as generating the output and setting the C<page_content> property).

B<Note>: With this extension you don't need to explicitly set the C<page_content> to the output of your template object (C<< ht->output() >>) in your Page Handlers, because it will be automatically set. You should explicitly set the C<page_content> property just in case you want to bypass the template system:
   
    # in order to produce the output with the template 'myPage.tmpl',
    # usually you just need to pass the param to the object
    sub PH_myPage {
        my $s = shift;
        $s->ht_param( something => 'something' );
    }
    
    # but if you want to completely bypass the template system
    # just set the page_content
    sub PH_myPage {
        my $s = shift;
        $s->page_content = 'some content';
    }

B<Note>: This extension is not as magic and memory saving as the L<CGI::Builder::Magic|CGI::Builder::Magic> template extension, because HTML::Template requires a specific input data structure (i.e. does not allow call back subs unless you use the HTML::Template::Expr), and does not allow to print the output during the process. On the other hand it should be a few milliseconds faster than CGI::Builder::Magic in producing the output.

=head1 EXAMPLES

=head2 Simple CBB (all defaults)

This is a complete CBB that uses all the default to load the './tm/index.tmpl'template and fill it with a couple of run time values and automatically send the C<page_content> to the client.

    package My::WebApp
    use CGI::Builder
    qw| CGI::Builder::HTMLtmpl
      |;
      
    sub PH_index {
        my $s = shift;
        $s->ht_param( myVar      => 'my Variable',
                      myOtherVar => 'other Variable');
    }
    
    1;

=head2 More complex CBB (overriding defaults)

This is a more complex complete CBB that will automatically send the C<page_content> to the client:

    package My::WebApp
    use CGI::Builder
    qw| CGI::Builder::HTMLtmpl
      |;
    
    # this will init some properties overriding the default
    # and adding some option to the ht creation
    sub OH_init {
        my $s = shift;
        $s->page_suffix = '.html';               # override defaults
        $s->ht_new_args( path => ['/my/path'],   # override defaults
                         die_on_bad_params => 0,
                         cache => 1 );
    }
    
    # this will be called for page 'index' or if no page is specified
    # it will load the '/my/path/index.html' file (since page_suffix is '.html')
    # and will fill it with the following variables and send the output()
    sub PH_index {
        my $s = shift;
        $s->ht_param( myVar      => 'my Variable',
                      myOtherVar => 'other Variable');
    }
    
    # this will override the default template for this handler
    # (i.e. '/my/path/specialPage.html') so loading '/my/path/special.tmp'
    # template, filling and sending the output as usual
    sub PH_specialPage {
        my $s = shift;
        $s->ht_new_args( filename => 'special.tmp')     # override defaults
        $s->ht_param( mySomething => 'something' );
    }
    
    1;

=head1 PROPERTY and GROUP ACCESSORS

This module adds some template properties (all those prefixed with 'ht_') to the standard CBF properties. The default of these properties are usually smart enough to do the right job for you, but you can fine-tune the behaviour of your CBB by setting them to the value you need.

=head2 ht_new_args( arguments )

This property group accessor handles the HTML::Template constructor arguments that are used in the creation of the internal HTML::Template object. Use it to change or add the argument you need to the creation of the new object.

It uses the following defaults:

=over

=item * filename

This option is set to the C<page_name> value plus the C<page_suffix> value.

    filename => $s->page_name.$s->page_suffix
    
    # when the page_name is 'myPage'
    # and the page_suffix is the default '.tmpl'
    # it will be expanded to;
    filename => 'myPage.tmpl'

=item * path

This option is set to the C<page_path> value.

   path => [ $s->page_path ]

=back

You should use C<ht_new_args> at the very beginning of the process, for any argument but 'filename'.

    # set args in the new instance statement
    my $webapp = My::WebApp
                ->new( ht_new_args => { path => ['/my/path'],  # override defaults
                                        die_on_bad_params => 0,
                                        cache => 1
                                      }
                       .....
                     );
                                 
    # or in the OH_init handler
    sub OH_init {
        my $s = shift;
        $s->ht_new_args( path => ['/my/path'],   # override defaults
                         die_on_bad_params => 0,
                         cache => 1 );
    }

B<Note about custom filenames>: it is preferable to avoid to explicitly set the filename argument and let the default do it for you. Anyway if you still need to set the filename, you must know that you have to reset it if you C<switch_to()> another page AFTER setting it.

    # and/or in a Page Handler
    sub PH_specialPage {
        my $s = shift;
        $s->ht_new_args( filename => 'special.tmp')     # override defaults
        $s->ht_param( mySomething => 'something' );
    }


B<Note>: You can completely override the creation of the internal object by overriding the C<ht_new()> method.

=head2 ht_param

This property group accessor handles the HTML::Template parameters that are internally passed to the C<ht> object before the output production. Use it to collect the params that will be passed to the object.

B<Note>: This group accessor has been added in the 1.21 version in order to avoid to use the C<ht> property:

   # deprecated
   $s->ht->param(...)
   # OK
   $s->ht_param(...)

=head2 ht

This property is used internally, so you usually don't need to use it directly in your code. In the rare case you need to use it (e.g. if you need to use C<HTML::Template::query()> method), you should use it after any other C<switch_to()> calls, or you should explicitly undef it just before the C<switch_to()> call.

B<Note>: You can change the default arguments that are internally used to create the object by using the C<ht_new_args> group accessor, or you can completely override the creation of the internal object by overriding the C<ht_new()> method.

B<Advanced Note>: Unlike other template object, the C<HTML::Template> object needs to know the filename at the moment of its creation. That restriction considerably limits the possibility to switch_to another page if and when the C<ht> property has been already used (i.e. the C<HTML::Template> object has been already created). For this reason, the C<ht> property is preferably used only as an ending point (i.e. after we know what is the ultimate page to serve).

=head2 CBF changed property defaults

=head3 CBF page_suffix

This module sets the default of the C<page_suffix> to the traditional '.tmpl'. You can override it by just setting another suffix of your choice.

=head3 CBF page_content

This module sets the default of the C<page_content> to the template output produced by using the internal C<< ht->output() >>. If you want to bypass the template system in any Page Handler, just explicitly set the C<page_content> to the content you want to send.

=head1 METHODS

=head2 ht_new()

This method is not intended to be used directly in your CBB. It is used internally to initialize and returns the C<HTML::Template> object, but you need to know how it does its job. If you need some more customization you can redefine the method in your CBB.

=head2 switch_to overriding

If (and only if) your application has to switch_to after using the C<ht> property quite often, it may be handy to implement the following C<switch_to()> in your own CBB:

  sub switch_to {
      my $s = shift;
      $s->ht_new_args( {filename => $_[0].$s->page_suffix} )
          if $s{ht_new_args}{filename};
      $s->ht = undef;
      $s->CGI::Builder::switch_to(@_);
  }

=head2 CBF overridden methods

=head3 page_content_check

This extension use this method to check if the template file exists before using its template print method, thus avoiding a fatal error when the requested page is not found.

B<Note>: You don't need to directly use this method since it's internally called at the very start of the RESPONSE phase. You don't need to override it if you want just to send a different header status, since the CBF sets the status just if it is not defined yet.

=head1 AVOIDING MISTAKES

=over

=item *

Don't use the C<ht_new_args> in all the Page Handlers: it is intended to be used once e.g. in an OH_init OR as an exceptional case in any Page Handler just to allow overriding (e.g. a different filename just for that particular Page Handler).

=item *

Don't explicitly set the C<page_content> property unless you want to bypass the template system: this extension set it for you.

=back

=head1 SUPPORT

See L<CGI::Builder/"SUPPORT">.

=head1 AUTHOR and COPYRIGHT

© 2004 by Domizio Demichelis (L<http://perl.4pro.net>)

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.

=head1 CREDITS

Thanks to Rob Arnold for his testing and suggestions.

=cut

