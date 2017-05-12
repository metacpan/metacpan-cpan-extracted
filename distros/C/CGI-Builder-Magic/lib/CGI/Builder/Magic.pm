package CGI::Builder::Magic ;
$VERSION = 1.31 ;
use strict ;

# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html
          
; use Carp
; $Carp::Internal{+__PACKAGE__}++
; $Carp::Internal{__PACKAGE__.'::_'}++

; use File::Spec
; use Template::Magic
; use Class::Util

; my $print_code
; BEGIN
   { $print_code = sub
                    { shift()->CGI::Builder::Magic::_::tm_print(@_)
                    }
   }
; use Class::groups
  ( { name       => 'tm_extra_value_handlers'
    , default    => { TableTiler => 1
                     , FillInForm => 1
                     }
    }
  , { name       => 'tm_new_args'
    , default    => { markers => 'HTML' }
    }
  )
        
; use Class::props
  ( { name       => 'tm'
    , default    => sub{ shift()->tm_new(@_) }
    }
  , { name       => 'tm_lookups_package'
    , default    => sub{ ref($_[0]) . '::Lookups' }
    }

  )
  
; use Object::props
  ( { name       => 'tm_template'
    , default    => sub
                     { File::Spec->catfile( $_[0]->page_name
                                          . $_[0]->page_suffix
                                          )
                     }
    }
  , { name       => 'page_suffix'
    , default    => '.html'
    }
  , { name       => 'page_content'
    , default    => sub{ $print_code }
    }
  , 'tm_lookups'
  , 'tm_container_template'
  )
   
; sub tm_new
   { my $s = shift
   ; { package CGI::Builder::Magic::Lookups
     ; no strict 'refs'
     ; *$CGI::Session::NAME = sub { shift()->cs->id }
                              if $s->isa('CGI::Builder::Session')
     ; *FillInForm          = sub { shift()->cgi }
     }
   ; my $lpk = $s->tm_lookups_package
   ; $lpk  &&= [ $lpk ] unless ref $lpk eq 'ARRAY'
   ; my $l   = $s->tm_new_args('lookups')
   ; $l    &&= [ $l ] unless ref $l eq 'ARRAY'
   ; push @$lpk, 'CGI::Builder::Magic::Lookups'
   ; push @$l, @$lpk
   ; my $tmxh = $s->tm_extra_value_handlers
   ; Template::Magic->new
     ( value_handlers => [ 'SCALAR'
                         , 'REF'
                         , $s->CGI::Builder::Magic::_::CODE($lpk)
                         , $$tmxh{TableTiler} ? 'TableTiler' : ()
                         , 'ARRAY'
                         , 'HASH'
                         , $$tmxh{FillInForm} ? 'FillInForm': ()
                         , 'OBJECT'
                         ]
     , paths          => [ $s->page_path ]
     , %{$s->tm_new_args}
     , lookups        => $l # overriding considerd before
     )
   }
   
; sub CGI::Builder::Magic::_::CODE # value handler
   { my ( $s, $lpk, @args ) = @_
   ; sub
      { my ($z) = @_
      ; my $v = $z->value
      ; if ( ref $v eq 'CODE' )
         { my $l = $z->location
         ; my $nv = (grep /$l/, @$lpk)  ? $v->( $z->tm->{CBB}, @_ )
                   : Class::Util::blessed( $l ) # if blessed obj
                     ? do { no strict 'refs'
                          ; $l->$v( ${ref($l).'::no_template_magic_zone'}
                                    ? ()
                                    : $z
                                  , @args
                                  )
                          }
                   : $v->( $z , @args )
         ; if ( $v ne ($nv||'') ) # avoid infinite loop
            { $z->value($nv)
            ; $z->value_process     # process the new value
            }
         ; 1
         }
      }
   }

; sub CGI::Builder::Magic::_::tm_print
   { my $s = shift
   ; $s->tm->{CBB} = $s
   ; my $tl = $s->tm_lookups || []
   ; $tl &&= [ $tl ] unless ref $tl eq 'ARRAY'
   ; $s->tm->nprint( template           => $s->tm_template
                   , container_template => $s->tm_container_template
                   , lookups            => [ @$tl, scalar $s->page_error ]
                   )
   ; delete $s->tm->{CBB} # allows $s destroyng
   }

; sub page_content_check
   { my $s  = shift
   ; unless ( $s->page_content eq $print_code )  # not managed by tm
      { $s->CGI::Builder::page_content_check
      }
     else
      { my $template
      # tm_template set for current page
      ; if ( $$s{tm_template} )
         { return 1 if ref($$s{tm_template}) =~ /(GLOB|SCALAR)/
         ; $template = $$s{tm_template}
         }
        # tm not set
        else
         { $template = $s->page_name
                     . $s->page_suffix
         }
      # check
      ; $s->tm->find_file( $template )
      }
   }
   
; 1

__END__

=pod

=head1 NAME

CGI::Builder::Magic - CGI::Builder and Template::Magic integration

=head1 VERSION 1.31

The latest versions changes are reported in the F<Changes> file in this distribution. To have the complete list of all the extensions of the CBF, see L<CGI::Builder/"Extensions List">

=head1 INSTALLATION

=over

=item Prerequisites

    CGI::Builder    >= 1.31
    Template::Magic >= 1.36

=item CPAN

    perl -MCPAN -e 'install CGI::Builder::Magic'

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

    # just include it in your build
    
    use CGI::Builder
    qw| CGI::Builder::Magic
      |;

=head1 DESCRIPTION

B<Note>: You should know L<CGI::Builder>.

This module transparently integrates C<CGI::Builder> and C<Template::Magic> in a very handy, powerful and flexible framework that can save you a lot of coding, time and resources.

With this module, you don't need to produce the C<page_content> within your page handlers anymore (unless you want to); you don't even need to manage a template system yourself (unless you want to).

If you use any template system on your own (i.e. not integrated in a CBF extension), you will have to write all this code explicitly:

=over

=item *

create a page handler for each page as usual

=item *

create a new template object and assign a new template file

=item *

find the runtime values and assign them to the template object

=item *

run the template process and set the C<page_content> to the produced output

=back

You can save all that by just including this module in your build, because it implements an internal transparent and automagic template system that even without your explicit intervention is capable of finding the correct template and the correct runtime values to fill it, and generates the page_content automagically. With this module you can even eliminate the page handlers that are just setting the page_content, because the page is auto-magically sent by the template system.

=head2 How to organize your CBB

Add these steps to the recommendations in L<CGI::Builder/"Design your application">:

=over

=item 1

Prepare a template for each page addressed by your application or prepare a Page Handler for those which will not have a template

=item 2

Define just the page handlers that needs to do something special

=item 3

Set the variables or the subs in the C<*::Lookups> package that the internal C<Template::Magic> object will look up (that could be picked up by one or more templates processing)

=back

=head1 The Template System

This module uses Template::Magic specially for these advantages:

=over

=item *

L<Template::Magic|Template::Magic> is a module that can auto-magically look up the runtime values in packages, hashes and blessed objects

=item *

It has the simplest possible template syntax (idiot-proof), and it is written in pure perl (no compiler needed), so it is perfect to be used by (commercial) user-customizable CGI applications.

=item *

It uses minimum memory because it prints the output while it is produced, avoiding to collect in memory the whole (and sometime huge) content.

=back

The integration with Template::Magic allows you to move all the output-related stuff out of the page handlers, producing a cleaner and easiest to maintain CBB.

B<Note>: All the CBF extensions are fully mod_perl 1 and 2 compatible (i.e. you can use them under both CGI and mod_perl). Anyway, an extremely powerful combination with this extension is the L<Apache::CGI::Builder|Apache::CGI::Builder>, that can easily implement a sort of L<Perl Side Include|"APACHE::CGI::Builder (Perl Side Include)"> (sort of easier, more powerful and flexible "Server Side Include").

=head2 How it works

This module implements a default value for the C<page_content> property: a CODE reference that produces and print the page content by using an internal C<Template::Magic> object with HTML syntax.

The default template file used to produce the output is the result of the concatenation (File::Spec->catfile) of the C<page_path>, C<page_name> and C<page_suffix> properties, but you can set it otherwise if you want to use a different template file.

Since the C<page_content> property is set to its own default value before the page handler is called, the page handler can completely (and usually should) avoid to produce any output.

    sub PH_myPage
    {
      ... do_something_useful ...
      ... no_need_to_set_page_content ...
      ... returned_value_will_be_ignored ...
    }

Since the CBF calls the Page Handler related with the C<page_name>, without expecting any returned value from it, an ideal organized Magic application uses the Page Handlers only if the application has something special to do for any particular page. The output production is usually handled auto-magically by the template system.

The output will be generated internally by the merger of the template file and the runtime values that are looked up from the C<FooBar::Lookup> package ('FooBar' is not literal, but stands for your application namespace plus the '::Lookups' string).

In simplest cases you can also avoid to create the page handler for certain pages: by default the template with the same page name will be used to produce the output.

This does not mean that you cannot do things otherwise when you need to. Just create a page handler and set there all the properties that you want to override:

   sub PH_mySpecialPage
   {
     my $s = shift ;
     $s->tm_lookups = { special_key => 'that' } ;
     $s->tm_template = '/that/special/template' ;
   }

Since the page handler sets the C<tm_lookups> and the C<tm_template> properties, the application will add your hash to the usual lookup, and the template system will print with a specific template and not with the default 'mySpecialPage.html'.

If some page handler needs to produce the output on its own (completely bypassing the template system) it can do so by setting the C<page_content> property as usual (i.e. with the page content or with a reference to it)

   sub PH_mySpecialPage
   {
     my $s = shift ;
      ... do_something_useful ...
     # will bypass the template system
     $s->page_content  = 'something';
     $s->page_content .= 'something more';
   }

For the 'mySpecialPage' page, the application will not use the template system at all, because the C<page_content> property was set to the output.

B<Note>: For former CGI::Application users: the returned value of any page handler will be ALWAYS ignored, so set explicitly the C<page_content> property when needed (or ignore it if you want to use the template system).

=head2 Lookups

Lookups are 'code locations' where the Template::Magic system will search the runtime values to substitute the labels in your template. (See L<Template::Magic/"lookups"> for details)

=head3 Special Labels

This module automatically adds to the Template::Magic object some useful lookups which make available several ready to use labels inside your templates. You don't need to write any code in your CBB in order to use these labels:

=over

=item * all the page_error keys

If your CBB or some other extensions (like the L<CGI::Builder::DFVCheck|CGI::Builder::DFVCheck>) set some C<page_error> key value pair, they will be available as labels in your template:

    $s->page_error( err_email => 'The email field is not valid' );

in your template you can use:

    <!--{err_email}-->

that will be substituted with 'The email field is not valid'.

=item * the FillInForm block label

The special block label 'FillInForm' is very useful to redisplay a HTML form that has some input error and re-filling all the fields with the values that the user has just submitted.

In order to do so, you have just to use it inside your template by making a block that surrounds the HTML form:

    <!--{FillInForm}-->
    <form action="tank_you_page" method="get">
    Name: <input name="name" type="text" value=""><br>
    Email: <input name="email" type="text" value=""><br>
    <input type="submit" name="submit" value="Submit">
    </form>
    <!--{/FillInForm}-->

=item * the CGISESSID label

When you include in your CBB the L<CGI::Builder::Session|CGI::Builder::Session> extension, you will have magically available a label that will be substituted with the current session id. The label identifier is the same name contained in the $CGI::Session::NAME variable which is usually 'CGISESSID', unless you have set it otherwise.

   <!--{CGISESSID}-->

E.g.: You can use it to set the value of an hidden field in your forms.

B<Note>: The simple use of this label in a template might internally create a CGI::Session object (C<cs> property) thus eventually generating a new session on its own if no session object has been used in your CBB yet.

=back

=head3 *::Lookups package

This is a special package that your application should define to allow the internal Template::Magic object to auto-magically look up the run time values you want to define.

The name of this package is contained in the L<"tm_lookups_package"> B<class property>. The default value for this property is 'FooBar::Lookup' where 'FooBar' is not literal, but stands for your CBB namespace plus the '::Lookups' string, so if you define a CBB package as 'WebApp' you should define a 'WebApp::Lookups' package too (or set the C<tm_lookup_package> property with the name of the package you will use as the lookup).

In this package you should define all the variables and subs needed to supply any runtime value that will be substituted in place of the matching label or block in any template.

The lookup is confined to the C<*::Lookups> package on purpose. It would be simpler to use the same CBB package, but this would extend the lookup to all the properties, methods and handlers of your CBB and this might cause conflict and security holes. So, by just adding one line to your CBB, (e.g. 'package FooBar::Lookups;') you can separate your CBB from the lookup-allowed part of it.

B<Note>: If for any reason you need to use more than one *::Lookup package, you can set the C<tm_lookups_package> to a reference to an ARRAY of packages names. Obviously you can also put each lookups package in its own '.pm' file, thus making them simply loadable from different CBBs.

=head3 *::Lookups subs

The subs in the C<*::Lookups> package(s) are executed by the template lookup whenever a label with the same identifier is found. They receive your application object ($self) in $_[0], so even if they are defined in a different package, they are just like the other methods in your CBB class.

The subs will receive the C<Template::Magic::Zone> object as $_[1], so you can interact with the zone as usual (see L<Template::Magic>)

B<Important Note>: Usually a sub in any *::Lookups package is an ending point and should not need to call any other subs in the same *::Lookups package. If you feel the need to do otherwise, you probably should re-read L<Template::Magic> because you are trying to do something that Template::Magic is already doing auto-magically. Anyway, if you found some esoteric situation that I never thinked about, you can do *::Lookups subs callable from the same package by just making your CBB package a subclass of *::Lookups package by adding a simple C<push our @ISA, 'FooBar::Lookups';> statement in it.

=head3 How to add lookup locations

If you want the C<Template::Magic> object to look up in some more location, e.g. if you want the object to loookup in the param hash and in %ENV, you can choose beetween a couple of solutions: if your need is temporary (i.e. just for some specific Page Handler) you can use the C<tm_lookups> property or if your need is application-wide (i.e. for all the pages) you can use the C<tm_new_args> B<class group property>.

This is the first option which will add the lookups only for the 'some_special_page':

    sub PH_some_special_page {
        $s->tm_lookups = [ scalar $s->param ,      # param hash ref
                           \%ENV  ] ;              # %ENV ref
    }

This is the second option, which will add the lookups for all the pages processed by the template system:

    __PACKAGE__->tm_new_args
      ( lookups => [ scalar $s->param ,      # param hash ref
                     \%ENV  ]);              # %ENV ref

B<Note>: The first option uses the temporary lookups capability of Template::Magic, while the second one uses the constructor array lookups. They have almost the same effect on the single output, but the first is cleared after each template process, while the second is stored into the object itself (thus used for all the successive template process). See L<Template::Magic> for more details.

B<Warning>: The C<tm_new_args()> accessor is a class accessor, and is used ONLY when a new Template::Magic object is about to be created. This means that if you write something like this:

    sub PH_some_special_page {
        __PACKAGE__->tm_new_args
          ( lookups => [ scalar $s->param ,      # param hash ref
                         \%ENV  ]);              # %ENV ref
    }

Probably the effect will not be what you might espect. More specifically, if the C<tm> object has been used before the 'some_special_page' has been requested, the statement has simply no effect, since the C<tm> object is already created and stored. If the C<tm> object has not been used before the 'some_special_page' has been requested, then the statement will have its effect but the object will contain the lookup locations for all the successive requests.

=head2 The template syntax

This module implements a C<Template::Magic::HTML> object, so the used C<markers> are the default HTML markers e.g.:

    <!--{a_block_label}--> content <!--{/a_block_label}-->

and the I<value handlers> are the default HTML handler, so including C<TableTiler> and C<FillInForm> handlers by default. Please, read L<Template::Magic> and L<Template::Magic::HTML>.

=head2 Example

    package WebApp ;
    use CGI::Builder
    qw| CGI::Builder::Magic
      | ;
    
    # no need to setup page handlers to set the page_content
    # just setup the package where Template::Magic will looks up
    # the run time valuess
    
    package WebApp::Lookups ;
    
    # this value will be substituted to each
    # 'app_name' label in EACH TEMPLATE that include it
    our $app_name = 'WebApp 1.0' ;
    
    # same for each 'Time' label
    sub Time { scalar localtime }
    
    # and same for each 'ENV_table' block
    sub ENV_table {
        my ($self,        # $self is your WebApp object
            $zone) = @_ ; # $zone is the Template::Magic::Zone object
        my @table ;
        while (my @line = each %ENV) {
          push @table, \@line
        }
        \@table ;
    }

An auto-magically used template (it contains the 'ENV_table block', and the 'app_name' and 'Time' labels)

    <html>
    
    <head>
    <meta http-equiv=content-type content="text/html;charset=iso-8859-1">
    <title>ENVIRONMENT</title>
    <style media=screen type=text/css><!--
    td   { font-size: 9pt; font-family: Arial }
    --></style>
    </head>
    
    <body bgcolor=#ffffff>
    <table border=0 cellpadding=3 cellspacing=1 width=100%>
    <tr><td bgcolor=#666699 nowrap colspan=2><font size=3 color=white><b>ENVIRONMENT</b></font></td></tr>
    <!--{ENV_table}-->
    <tr valign=top>
    <td bgcolor=#d0d0ff nowrap><b>the key goes here</b></td>
    <td bgcolor=#e6e6fa width=100%>the value goes here</td>
    </tr>
    <!--{/ENV_table}-->
    </table>
    Generated by <!--{app_name}--> - <!--{Time}-->
    </body>
    
    </html>

=head1 SPECIAL INTEGRATIONS

This extension will add some special features to your CBB when some specific extension is included.

=head2 Apache::CGI::Builder (Perl Side Include)

SSI (Server Side Includes) are directives that are placed in HTML pages, and evaluated on the server while the pages are being served. The Apache server uses the C<mod_include> Apache module to process the pages, but you can configure it to process the pages by using your own CBB, that can easily implement a lot of more custom 'directives' in the form of simple labels.

In other words: your own CBB transparently process the pages of a web dir, supplying the dinamic content that will be included in the page just before they are served.

With this technique B<your application does not need to handle neither page names, nor page handlers, nor template managements>: all that is auto-magically handled by the combination of C<Apache::CGI::Builder> and C<CGI::Builder::Magic> extensions.

Please, take a look at the 'perl_side_include' example in this distribution to understand all the advantages offered by this technique.

=head2 CGI::Builder::Session

When you include in your CBB the L<CGI::Builder::Session|CGI::Builder::Session> extension, you will have magically available a label that will be substituted with the current session id. See L<the CGISESSID label|"item_the_CGISESSID_label"> for details.

=head2 CGI::Builder::DFVCheck

The CGI::Builder::DFVCheck extension sets the CBF C<page_error> property with the errors found in your forms. CGI::Builder::Magic adds that property to its lookups, so each error found will have its own label defined. See L< CGI::Builder::DFVCheck> for more details.

=head1 PROPERTY and GROUP ACCESSORS

This module adds some template properties (all those prefixed with 'tm_') to the standard CBF properties. The default of these properties are usually smart enough to do the right job for you, but you can fine-tune the behaviour of your CBB by setting them to the value you need.

=head2 tm_lookups

This property allows you to access and set the 'lookups' argument passed to the Template::Magic::nprint() method (see L<Template::Magic/"nprint ( arguments )">). It is undefined by default.

=head2 tm_template

This property allows you to access and set the 'template' argument passed to the Template::Magic::nprint() method (see L<Template::Magic/"nprint ( arguments )">). Its default is the concatenation (File::Spec->catfile) of the C<page_path>, C<page_name> and C<page_suffix> properties, but you can set it otherwise if you want to use a different template file.

=head2 tm_container_template

This property allows you to access and set the 'container_template' argument passed to the Template::Magic::nprint() method (see L<Template::Magic/"nprint ( arguments )">).

=head2 CBF changed property defaults

=head3 CBF page_suffix

This module sets the default of the C<page_suffix> to '.html'. If this extension is used under C<Apache::CGI::Application> the C<page_suffix> will be set to the real file name suffix. (see L<Apache::CGI::Builder>)

You can override it by just setting another suffix of your choice.

=head3 CBF page_content

This module sets the default of the C<page_content> to a CODE reference that produces the page content by using an internal Template::Magic object with HTML syntax (see also L<"How it works">). If you want to bypass the template system in any Page Handler, just explicitly set the C<page_content> to the content you want to send.

=head1 ADVANCED FEATURES

In this section you can find all the most advanced or less used features that document all the details of this module. In most cases you don't need to use them, anyway, knowing them will not hurt.

=head2 Class Accessors

This extension implements a Template::Magic system that is "persistent" under mod_perl (no persistency is available under normal CGI environment).

The persistency is implemented by storing the object (and the other variables that concur to its creation) in package variables, which are persistent under mod_perl. (see also L<CGI::Builder/"Global Varibales Persistence">)

This technique allows to save some processing time by creating the Template::Magic object just once -the first time it is accessed- and using the same object for all the successive requests that involve template processing.

The package variables used for the template system are accessed by the following OOTools class accessors:

=head3 tm

This B<class property> returns the internal C<Template::Magic> object.

This is not intended to be used to generate the page output - which is automagically generated - but it could be useful to generate other outputs (e.g. messages for sendmail) by using the same template object, thus preserving the same arguments.

   # way to access the tm_object
   $tm_obj = __PACKAGE__->tm ;
   $tm_obj = My::CBB->tm ;
   $tm_obj = $s->tm ;

B<Note>: You can change the default arguments of the object by using the C<tm_new_args> property group, or you can completely override the creation of the internal object by overriding the C<tm_new()> method.

=head3 tm_new_args( arguments )

This B<class group accessor> handles the Template::Magic constructor arguments that are used in the creation of the internal Template::Magic object. Use it to add some more lookups your application might need, or finetune the behaviour if you know what you are doing (see L<"How to add lookup locations"> and L<Template::Magic/"new ( [constructor_arrays] )">).

   __PACKAGE__->tm_new_args(...) ;

B<Note>: You can completely override the creation of the internal object by overriding the C<tm_new()> method.

=head3 tm_lookups_package

This B<class property> allows you to access and set the name of the package where the Template::Magic object will look up by default. The default value for this property is'FooBar::Lookup' where 'FooBar' is not literal, but stands for your application namespace plus the '::Lookups' string. (i.e. 'WebApp::Lookup').

   __PACKAGE__->tm_lookups_package('My::Special::Lookups') ;

If you need to use more than one *::Lookups package, you can also set this property to a reference to an ARRAY of packages names, and all the subs in each package will receive the reference to the CBB object in $_[0].

   __PACKAGE__->tm_lookups_package([ 'My::Special::Lookups',
                                     'My::Other::Lookups'  ] ) ;

=head2 tm_extra_value_handlers

This B<class group accessor> handles the 'TableTiler' and 'FillInForm' value handlers. You must explicitly exclude them in order to save some loading and execution time (if your application doesn't use them):

   __PACKAGE__->tm_extra_value_handlers( 'FillInForm' => 0
                                       , 'TableTiler' => 0
                                       );

=head2 Advanced methods

=head3 tm_new()

This method is not intended to be used directly in your CBB. It is used internally to initialize and return the C<Template::Magic> object. You can override it if you know what you are doing, or you can simply ignore it ;-).

B<Note>: This method will add to the object lookups the C<tm_lookups_package> package(s), plus an internal CGI::Builder::Magic::Lookups special package, used for the Special Integration features. This last package is added as the latest lookup location, thus allowing you to eventually override its methods in your own *::Lookups package(s).

=head2 CBF overridden methods

=head3 page_content_check

This extension use this method to check if the template file exists before using its template print method, thus avoiding a fatal error when the requested page is not found.

B<Note>: You don't need to directly use this method since it's internally called at the very start of the RESPONSE phase. You don't need to override it if you want just to send a different header status, since the CBF sets the status just if it is not defined yet.

=head1 EFFICIENCY

You should add a couple of optional statements to your CBB in order to load at compile time the TableTiler and the FillInForm autoloaded handlers (just if you use them in your templates):

    use CGI (); # as recommended in the C::B manpage
    use Template::Magic qw( -compile TableTiler FillInForm );

If you can do so, you could also put the statements directly in the F<startup.pl> file. See also L<Template::Magic/"The -compile pragma">.

=head1 SUPPORT

See L<CGI::Builder/"SUPPORT">.

=head1 AUTHOR and COPYRIGHT

© 2004 by Domizio Demichelis (L<http://perl.4pro.net>)

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.

=cut
