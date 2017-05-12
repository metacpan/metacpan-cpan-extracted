package CGI::Application::Magic ;
$VERSION = 1.21 ;
use strict ;

# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; use base 'CGI::Application::Plus'

; use Carp
; use File::Spec
; use Template::Magic qw| -compile
                          TableTiler
                          FillInForm
                        |

; use Object::groups
      ( { name       => 'tm_defaults'
        , no_strict  => 1
        }
      )

; *tm_path = sub : lvalue { shift()->tmpl_path(@_) }

; use Object::props
      ( { name       => 'tm_lookups'
        }
      , { name       => 'tm_template'
        , default    => sub
                         { $_[0]->runmode
                         . $_[0]->tm_suffix
                         }
        }
      , { name       => 'tm_lookups_package'
        , default    => sub{ ref($_[0]) . '::Lookups' }
        }
      , { name       => 'tm_suffix'
        , default    => '.html'
        }
      , { name       => 'page'
        , default    => sub
                         { sub    # _tm_print is overridable
                            { shift()->_tm_print(@_)
                            }
                         }
        }
      , { name       => 'tm_object'
        , default    => sub{ shift()->tm_new_object(@_) }
        }
      )
      
; sub tm_new_object
   { my ($s) = @_
   ; Template::Magic
     ->new( lookups        => [ $s->tm_lookups_package ]
          , value_handlers => [ $s->lookup_CODE()
                              , 'HTML'
                              ]
          , markers        => 'HTML'
          , defined $s->tm_defaults ? %{$s->tm_defaults} : ()
          )
   }
             
; sub _tm_print
   { my ($s) = @_
   ; my $t = $s->tm_template
   ; my $lkps = $s->tm_lookups
   ; $lkps &&= [ $lkps ] unless ref $lkps eq 'ARRAY'
   ; my $err = eval{$s->dfv_results->msgs}
   ; $s->tm_object
       ->nprint( template => File::Spec
                             ->file_name_is_absolute( $t )
                             ? $t
                             : File::Spec->catfile( $s->tm_path
                                                  , $t
                                                  )
               , lookups  => [ defined $lkps ? @$lkps : ()
                             , defined $err  ? $err   : ()
                             ]
               )

   }
   
; sub lookup_CODE     # value handler
   { my ($s) = @_
   ; sub
      { my ($z) = @_
      ; if ( ref $z->value eq 'CODE'
           && $z->location eq $s->tm_lookups_package
           )
         { $z->value = $z->value->($s, @_)
         ; $z->value_process
         ; 1
         }
      }
   }
   
; sub setup {}

; 1

__END__

=pod

=head1 NAME

CGI::Application::Magic - Template based framework for CGI applications

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

    Perl version    >= 5.6.1
    OOTools         >= 1.6
    Template::Magic >= 1.0

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

    package WebApp ;
    use base 'CGI::Application::Magic' ;
    
    # optional runmethod
    sub RM_myRunMmode
    {
      ... do_something_useful ...
      ... no_need_to_set_page ...
      ... returned_value_will_be_ignored ...
    }
    
    # package where Template::Magic will looks up
    package WebApp::Lookups ;
    
    # this value will be substituted to each
    # 'app_name' label in each template that include it
    our $app_name = 'WebApp 1.0' ;
    
    # same for each 'Time' label
    sub Time { scalar localtime }
    
    # and same for each 'ENV_table' block
    sub ENV_table
    {
      my ($self,        # $self is your WebApp object
          $zone) = @_ ; # $zone is the Template::Magic::Zone object
      my @table ;
      while (my @line = each %ENV)
      {
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


See also the F<'magic_example'> directory in this distribution

=head1 DESCRIPTION

This module transparently integrates C<CGI::Application::Plus> and C<Template::Magic> in a very handy, powerful and flexible framework that can save you a lot of coding, time and resources.

B<Note>: Knowing L<CGI::Application::Plus> and L<Template::Magic> could help to better understand this documentation ;-).

B<IMPORTANT NOTE>: If you write any script that rely on this module, you better send me an e-mail so I will inform you in advance about eventual planned changes, new releases, and other relevant issues that could speed-up your work. 

=head2 Why CGI::Application::Plus and Template::Magic?

=over

=item *

L<Template::Magic|Template::Magic> is a module that can auto-magically look up the runtime values in packages, hashes and blessed objects

=item *

It has the simplest possible template syntax (idiot-proof), and it is written in pure perl (no compiler needed), so it is perfect to be used by (commercial) user-customizable CGI applications.

=item *

It uses minimum memory because it prints the output while it is produced, avoiding to collect in memory the whole (and sometime huge) content.

=item *

L<CGI::Application::Plus|CGI::Application::Plus> allows maximum flexibility of the CGI application structure. Without it this framework wouldn't be possible.

=back

=head2 Concept

The C<CGI::Application> philosophy is very simple: each runmethod is organized to produce its own output page. Very easy to understand concept, but not so flexible to utilize. In real world jobs, if your runmethods use templates to produce the output, they usually will have to set an hash with a key for each template label, and pass it to the template object (to be created/loaded somewhere) to have returned the final output page.

A CGI application can have a lot of run modes, and you have to creates a lot of different run methods, a lot of different templates, set a different hash for each one of them to discover very soon that sometimes the hashes share 50% of keys and values (and not always the same) with the hashes of other runmethods.

Another stupid and redundant thing is that frequently you have a runmode named e.g. C<'foo'>, its relative run method named C<foo()> and its relative template file named F<'foo.html'>. May be this happens because you have a too simple mind and you should use always different base names to be more creative, so configuring e.g the C<'foo'> run mode to point at the C<bar()> run method that uses the F<'baz.html'> template :-))). Anyway, if you are not so creative :-), you have to set all that identical names again and again in the code: I hate that!

Well, you understand the problem... the code grows too much with too much redundancy, maintaining it may be very difficult, sometimes it becomes a real mess, and usually you have no enough time to think about how to organize things in a different way :-).

This module organizes the output production in a far more flexible and simpler way and wipes out each stressing redundancy making smart use of defaults (always overridable).

=head2 Run modes

This module allows you to move all the template-related stuff out of the runmethods so that B<the output production can be not only runmode driven, but also template and label driven>. In other words: a runmode is not the output production center anymore unless you want it to be so. This is the most important concept to understand.

These are the points that explain you the concept:

=over

=item *

A C<CGI::Application::Magic> implementation (i.e. your application module using this one as a base class) can completely avoid to create the template object because it is internally created and managed (anyway you can override its constructor by completely customizing the default as you need).

=item *

A runmethod does not need to set any hash to pass its runtime values, because they can be automagically found by the lookup of the template system, (anyway you can decide to produce the values that are exclusive for that particular runmethod and pass just them to the template system).

=item *

The runmethod does not need even to set the template name, because the run mode base name will be used to find a template with the same name, (anyway you can pass a different name as you need).

=item *

The runmethod does not even need to exist, because the template system will manage the output production on its own, if a template with the same base name of the runmode is found.

=back

This concept allows you to create and use just the runmethos that need to do something special, leaving all the possibly shared stuff out of them.

=head2 How it works

This module is a sub class of C<CGI::Application::Plus> and implements a default value for the C<page> cgiapp property: a CODE reference that produces and print the page content by using an internal C<Template::Magic> object with HTML syntax.

Since the C<page> property is set to its own default value even before the runmethod is called, the runmethod can completely (and usually should) avoid to produce any output.

    sub RM_myRunMmode
    {
      ... do_something_useful ...
      ... no_need_to_set_page ...
      ... returned_value_will_be_ignored ...
    }

This module just call the runmethod related with the run mode, but it does not expect anything from it.

An ideal organized Magic application uses the runmethod only if the application has something special to do for any particular run mode. The output production is usually handled auto-magically by the template system.

The output will be generated internally by the merger of the template file and the runtime values that are looked up from the C<FooBar::Lookup> package ('FooBar' is not literal, but stands for your application namespace plus the '::Lookups' string).

In simplest cases you can also avoid to create the runmethod for certain run modes: by default the template with the same runmode name will be used to produce the output.

This does not mean that you cannot do things otherwise when you need to. Just create a runmode and set there all the properties that you want to override:

   sub RM_mySpecialTempRunMode
   {
     my $s = shift ;
     $s->tm_lookups = { special_key => 'that' }
     $s->tm_template = '/that/special/template'
   }

When it runs in 'RM_mySpecialTempRunMode' run mode, since the runmethod set the C<tm_lookups> property the application will add a special hash to the usual lookup. Since the runmethod set the C<tm_template> property, the template system will print with a specific template and not with the default 'mySpecialRunMode.html'.

If some runmethod needs to produce the output on its own (bypassing the template system) it can do so by setting the C<page> property as usual (i.e. with the page content or with a reference to it)

   sub RM_mySpecialRunMode
   {
     my $s = shift ;
      ... do_something_useful ...
     # will bypass the template system
     $s->page  = 'something'
     $s->page .= 'something more'
   }

When it runs in 'RM_mySpecialRunMode' run mode, the application will not use the template system at all, because the C<page> property was set to the output.

B<Note>: The returned value of any run_mode will be ALWAYS ignored, so set explicitly the C<page> property when needed.

=head2 Lookups

=head3 *::Lookups package

This is a special package that your application should define to allow the internal Template::Magic object to auto-magically look up the run time values.

The name of this package is contained in the L<"tm_lookups_package> property. The default value for this property is 'FooBar::Lookup' where 'FooBar' is not literal, but stands for your application namespace plus the '::Lookups' string, so if you define a package application as 'WebApp' you should define a 'WebApp::Lookups' package too.

In this package you should define all the variables and subs needed to supply any runtime value that will be substituted in place of the matching label or block in any template.

B<Note>: The lookup is limited to the C<*::Lookups> package on purpose. It would be simpler to use the same application package, but this would extend the lookup to all the properties, methods and runmethods of your application and this could cause conflict and security holes. So, by just adding one line to your application, (e.g. 'package FooBar::Lookups;') you can separate your application from the lookup-allowed part of it.

=head3 *::Lookups subs

The subs in the C<*::Lookups> package are executed by the template lookup whenever a label with the same identifier is found. They receive your application object ($self) in $_[0], so even if they are defined in a different package, they are just like the other methods in your class.

The subs will receive the C<Template::Magic::Zone> object as $_[1], so you can interact with the zone as usual (see L<Template::Magic>)

Usually a sub in the *::Lookup package is an ending point and should not need to call any other subs in the same *::Lookup package. If you feel the need to do otherwise, you probably should re-read L<Template::Magic> because you are trying to do something that Template::Magic is already doing auto-magically. Anyway, if you found some esoteric situation that I never think about, you can do *::Lookup subs callable from the same package by just making your application package a subclass of *::Lookup package by adding a simple C<push our @ISA, 'FooBar::Lookups';> statement in it.

=head3 How to add lookup locations

If you want the C<Template::Magic> object to look up in some more locaion, e.g. if you want the object to loookup in the param hash and %ENV too, you can add this statement anywhere before the runmethod exits (i.e. in the setup(), cgiapp_prerun() and in the runmethod method itself)

    $self->tm_defaults
      ( lookups => [ $self->tm_lookups_package, # remember the *::Lookups pkg
                     scalar $self->param        # param hash ref
                     \%ENV  ]);                 # %ENV ref


=head2 The template syntax

This module implements a C<Template::Magic::HTML> object, so the used C<markers> are the default HTML markers e.g.:

    <!--{a_block_label}--> content <!--{/a_block_label}-->

and the I<value handlers> are the default HTML handler, so including C<TableTiler> and C<FillInForm> handlers by default. Please, read L<Template::Magic> and L<Template::Magic::HTML>. 

=head2 How to organize the application module

=over

=item 1

Set all the actions common to all run modes in the setup() (as usual)

=item 2

Prepare a template for each runmode

=item 3

Set the variables or the subs in the C<*::Lookups> package that the internal C<Template::Magic> object will look up (that could be picked up by one or more templates processing)

=item 4

Define just the runmethods that needs to do something special

=item 5

Use the properties defaults value, that can save you a lot of time ;-)

=back

=head2 mod_perl

C<CGI::Application::Magic> is fully mod_perl 1 and 2 compatible (i.e. you can use it under both CGI and mod_perl). Anyway, if your application runs under mod_perl, you should consider to integrates it with Apache by using the L<Apache::Application::Magic|Apache::Application::Magic> module, that can easily implement a sort of "Perl Side Include" (sort of easier, more powerful and flexible "Server Side Include").                             .

=head1 METHODS

=head2 tm_new_object()

This method initializes and returns the internal C<Template::Magic> object. You can override it if you know what you are doing, or you can simply ignore it ;-).

=head1 PROPERTY and GROUP ACCESSORS

This module adds some template properties to the standard C<CGI::Application::Plus> properties. The default of these properties are usually smart enough to do the right job for you, but you can fine-tune the behaviour of your CGI application by setting them to the value you need.

=head2 tm_path

This property is just a more consistent alias for the C<tmpl_path> property (see L<CGI::Application::Plus/"tmpl_path">)

=head2 tm_suffix

This property allows you to access and set the template file name suffix that will be used to find the template file. The default for this property is '.html'.

=head2 tm_lookups_package

This property allows you to access and set the name of the package where the Template::Magic object will look up by default. The default value for this property is'FooBar::Lookup' where 'FooBar' is not literal, but stands for your application namespace plus the '::Lookups' string. (i.e. 'WebApp::Lookup').

B<Note>: The 'lookups' argument of the C<tm_defaults> group will override this property.

=head2 tm_lookups

This property allows you to access and set the 'lookups' argument passed to the Template::Magic::nprint() method (see L<Template::Magic/"nprint ( arguments )">)

=head2 tm_template

This property allows you to access and set the 'template' argument passed to the Template::Magic::nprint() method (see L<Template::Magic/"nprint ( arguments )">). Set This property to an absolute path if you want bypass the C<tm_path> property.

=head2 tm_object

This property returns the internal C<Template::Magic> object.

This is not intended to be used to generate the page output - that is generated automagically - but it could be useful to generate other outputs (e.g. messages for sendmail) by using the same template object, thus preserving the same arguments.

B<Note>: You can change the default arguments of the object by using the C<tm_defaults> property, or you can completely override creation of the internal object by overriding the C<tm_new_object()> method.

=head2 tm_defaults( arguments )

This group accessor handles the Template::Magic constructor arguments that are used in the creation of the internal Template::Magic object. Use it to add some more lookups your application could need, or finetune the behaviour if you know what are doing (see L<"How to add lookup locations"> and L<Template::Magic/"new ( [constructor_arrays] )">).

B<Note>: You can completely override the creation of the internal object by overriding the C<tm_new_object()> method.

=head1 SUPPORT and FEEDBACK

If you need support or if you want just to send me some feedback or request, please use this link: http://perl.4pro.net/?CGI::Application::Magic.

=head1 AUTHOR and COPYRIGHT

© 2004 by Domizio Demichelis.

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.

=cut
