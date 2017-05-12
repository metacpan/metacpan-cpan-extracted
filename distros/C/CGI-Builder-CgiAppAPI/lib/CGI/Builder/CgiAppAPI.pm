package CGI::Builder::CgiAppAPI ;
$VERSION = 1.27 ;
use strict ;

# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; no warnings 'redefine'
; use CGI::Carp
; $Carp::Internal{+__PACKAGE__}++
; our $hints
######### OLD CGI APP ############

; use CGI::Builder::Const qw| :all |

; BEGIN
   { *QUERY
   = *query
     = sub : lvalue
        { $hints && carp
          qq(Just change 'QUERY' or 'query' with 'cgi')
        ; shift()->cgi(@_)
        }
                            
   ; *PARAMS
   = sub
      { $hints && carp
        qq(Just change 'PARAMS' with 'param')
      ; shift()->param(@_)
      }

   ; *TMPL_PATH
   = *tmpl_path
   = sub : lvalue
      { $hints && carp
        qq(Just change 'TMPL_PATH' or 'tmpl_path' with 'page_path')
      ; shift()->page_path(@_)
      }

   ; *start_mode
   = *get_current_runmode
   = *runmode
   = sub : lvalue
      { $hints && carp
        qq(Just change 'start_mode', 'get_current_runmode' or 'runmode' )
      . qq(with 'page_name' and remember that the 'page_name' default )
      . qq(is 'index' instead of 'start')
      ; shift()->page_name(@_)
      }

   ; *prerun_mode
   = sub
      { $hints && carp
        qq(Just change 'prerun_mode' with 'switch_to')
      ; shift()->switch_to(@_)
      }

   ; *header_props
   = *header_add
   = sub
      { $hints && carp
        qq(Just change 'header_props' or 'header_add' with 'header')
      ; shift()->header(@_)
      }
                             

   ; *page
   = sub : lvalue
      { $hints && carp
        qq(Just change 'page' with 'page_content')
      ; shift()->page_content(@_)
      }
   
   ; *mode_param
    = sub : lvalue
       { $hints && carp
         qq(Change 'mode_param' with 'cgi_page_param' )
       . qq(and remember that the 'cgi_page_param' default )
       . qq(is 'p' instead of 'rm')
       ; shift()->cgi_page_param(@_)
       }
                                                 
   ; *run_modes
   = sub
      { $hints && carp
        qq(Change 'run_modes' with 'page_handler_map', )
      . qq(and be aware that this method could be unnecessary)
      ; shift()->page_handler_map(@_)
      }
   }

   
# alias to make the CGI_APP_RETURN_ONLY work
; sub run
   { my $s = shift
   ; $hints && carp
     qq(Just change 'run' with 'process')
   ; if ( $ENV{CGI_APP_RETURN_ONLY} )
      { $hints && carp
        qq('\$ENV{CGI_APP_RETURN_ONLY}' is an obsolete way to capture )
      . qq(the output: use 'capture()' method instead)
      ; ${$s->capture('process')}
      }
     else
      { $s->process(@_)
      }
   }
   
; sub get_page_name
   { my $s = shift
   ; my $p
   ; if ( ref $s->cgi_page_param eq 'CODE' )
      { $hints && carp
        qq(The 'cgi_page_param' property should not be a CODE ref; )
      . qq(in this case just override the 'get_page_name()' method)
      ; $p = $s->cgi_page_param->($s)
      }
     else
      { $p = $s->cgi->param($s->cgi_page_param)
      }
   ; $s->page_name($p) if defined $p && length $p
   }

; my $exec = \&CGI::Builder::_::exec


; sub switch_to     # PHASE must be PRE_PROCESS or FIXUP
   { my ($s, $p, @args) = @_ ;
   ; local $SIG{__DIE__} = sub{$s->die_handler(@_)}

   ; $s->PHASE < PRE_PROCESS && croak
     qq(Too early to call switch_to())
   ; $s->PHASE > FIXUP && croak
     qq(Too late to call switch_to())
   ; defined $p && length $p  || croak qq(No page_name name passed)
   ; $s->page_name($p)

   ; $s->PHASE(SWITCH_HANDLER)
   ; my $shm    = $s->switch_handler_map
   ; my $switch_handler = $$shm{$p} || $s->can("SH_$p")
   ; $s->$switch_handler() if $switch_handler

   ; if ($s->PHASE < PRE_PAGE)
      { $s->PHASE(PRE_PAGE)
      ; $s->$exec('pre_page')
      }
   
   ; if ( $s->PHASE < PAGE_HANDLER )
      { $s->PHASE(PAGE_HANDLER)
      ; my $phm = $s->page_handler_map
      ; my $RM  = $s->RM_prefix
      ; my $al
      ; my $page_handler
        =  $$phm{$p}
        || $s->can("PH_$p")
        || do{ my $h = $s->can($RM.$p)
             ; $h && $hints && ($RM ne 'PH_') && carp
               qq(Your are using '$RM' as the prefix of your )
             . qq(run methods \(Page Handlers\). Change it with )
             . qq('PH_' in all the run methods that use it)
             ; $h
             }
        || do{ unless ($s->page_content_check)
                { my $h = $$phm{'AUTOLOAD'} || $s->can('PH_AUTOLOAD')
                ; $h && ++ $al && $h
                }
             }
      ; my $pc
      ; if ( $page_handler )
         { if ($al)
            { $hints && carp
              qq(Remember that the 'page_name' \(former run mode\) is no )
            . qq(longer passed as an argument to the AUTOLOAD page handler )
            . qq(\(former run method\); You should use the 'page_name' )
            . qq(property in place of the passed argument)
            ; unshift @args, $s->page_name
            }
         ; $pc = $s->$page_handler( @args )
         }
         
      ; unless ( length $s->page_content )
         { $hints && carp
           qq(A page handler \(former run method\) should set )
         . qq(the 'page_content' property with the value it is )
         . qq(returning right now)
         ; $page_handler
           || croak qq(No page handler found for page '${\$s->page_name}')
         ; $s->page($pc)
         }
      }
   }
 
; sub send_header
   { my $s = shift
   ; my $ht = $s->header_type
   ; if ($ht eq 'redirect')
      { $hints && carp
        qq(Change the 'redirect' header_type with the 'redirect()' method)
      ; $s->PHASE(REDIR)
      ; print $s->cgi->redirect( %{$s->header} )
      }
    elsif ($ht eq 'none')
      { $hints && carp
        qq(Change the 'none' 'header_type' with the 'dont_send_header' )
      . qq(boolean property set to 1)
      }
   ; print $s->cgi->header( %{$s->header} )
           unless (  $ht eq 'none'
                  || $s->dont_send_header
                  )
   }

   
# override to set old defaults
; use Object::props
      ( { name       => 'cgi_page_param'
        , default    => 'rm'
        }
      , { name       => 'page_name'
        , default    => sub
                         { $_[0]->isa('CGI::Builder::Magic')
                           ? 'index'
                           : 'start'
                         }
        }
      , { name       => 'header_type'
        , default    => 'header'
        , validation => sub{ /^(header|redirect|none)$/ }
        }
      , { name       => 'RM_prefix'
        , no_strict  => 1
        , validation => sub
                         { $hints && carp
                           qq(The 'RM_prefix' property is not supported: )
                         . qq(change the prefixes of your run modes with the )
                         . qq(constant prefix 'PH_' \(Page Handler\))
                         ; 1
                         }
        , default    => 'RM_'
        }
      )

# override to be same as the original
; use Object::groups
      (
      { name        => 'page_handler_map'
      , pre_process => sub
                         { if ( ref $_[1] eq 'ARRAY' )
                            { $_[1] = { map { $_=>$_ } @{$_[1]} }
                            }
                         }
        }
      ,
        { name       => 'qparam'
        , default    => sub
                         { $hints && carp
                           qq(The 'qparam' method is not supported. Use )
                         . qq(\$s->cgi->Vars or implement yours.)
                         ; eval{ scalar $_[0]->cgi->Vars }
                           || croak qq(The query object cannot 'Vars', )
                                  . qq(you cannot use the 'qparam' )
                                  . qq(property.)
                         }
        }

      )


; sub load_tmpl
   { my $s = shift
   ; my ($tmpl_file, @extra_params) = @_
   ; $hints && carp
     qq(You should include 'CGI::Builder::HTMLtmpl' )
   . qq(in your build and use that integration instaead of 'load_tmpl')
   # add tmpl_path to path array of one is set, otherwise add a path arg
   ; if (my $tmpl_path = $s->page_path)
      { my $found = 0
      ; for( my $x = 0
           ; $x < @extra_params
           ; $x += 2
           )
         { if (   $extra_params[$x] eq 'path'
              and ref $extra_params[$x+1]
              and ref $extra_params[$x+1] eq 'ARRAY'
              )
            { unshift @{$extra_params[$x+1]}, $tmpl_path
            ; $found = 1
            ; last
            }
         }
      ; push ( @extra_params
             , path => [ $tmpl_path ]
             )
             unless $found
      }
   ; require HTML::Template
   ; my $t = HTML::Template->new_file( $tmpl_file
                                     , @extra_params
                                     )
   ; return $t
   }

; sub dump
   { my $s = @_
   ; $hints && not($s->isa('CGI::Builder::Test')) && carp
     qq(You should include 'CGI::Builder::Test' )
   . qq(in your build in order to use the 'dump()' method)
   ; require CGI::Builder::Test
   ; goto &CGI::Builder::Test::dump
   }

; sub dump_html
   { my $s = @_
   ; $hints && not($s->isa('CGI::Builder::Test')) && carp
     qq(You should include 'CGI::Builder::Test' )
   . qq(in your build in order to use the 'dump_html()' method)
   ; require CGI::Builder::Test
   ; goto &CGI::Builder::Test::dump_html
   }

      
; sub checkRM
      { my $s = @_
      ; if ( $hints )
         { $s->isa('CGI::Application::CheckRM') && carp
           qq(You should not use 'CGI::Application::CheckRM' in your build)
        
         ; not($s->isa('CGI::Builder::DFVCheck')) && carp
           qq(You should include 'CGI::Builder::DFVCheck' in your build)
        
         ; carp qq(Change 'checkRM' with 'dfv_check')
         }
      ; require CGI::Builder::DFVCheck
      ; goto &CGI::Builder::DFVCheck::dfv_check
      }
      
; sub tm_defaults
      { my $s = @_
      ; if ( $hints )
         { $s->isa('CGI::Application::Magic') && carp
           qq(You should not use 'CGI::Application::Magic' in your build)
        
         ; not($s->isa('CGI::Builder::Magic')) && carp
           qq(You should include 'CGI::Builder::Magic' in your build)
        
         ; carp qq(Change 'tm_defaults' with 'tm_new_args')
         }
      ; require CGI::Builder::Magic
      ; goto &CGI::Builder::Magic::tm_new_args
      }

; sub request
      { my $s = @_
      ; if ( $hints )
         { $s->isa('Apache::Application::Plus') && carp
           qq(You should not use 'Apache::Application::Plus' in your build)
        
        ; not($s->isa('Apache::CGI::Builder')) && carp
          qq(You should include 'Apache::CGI::Builder' in your build)
        
        ; carp qq(Change 'request' with 'r')
        }
      ; require Apache::CGI::Builder
      ; goto &Apache::CGI::Builder::r
      }

; sub setup
   { $_[0]->page_handler_map(start => \&dump_html)
   }
        
; sub OH_init
   { my $s = shift
   ; if ( $s->can('cgiapp_init') )
      { $hints && carp
        qq(Just change 'cgiapp_init' with 'OH_init')
      ; $s->cgiapp_init(@_)
      }
   ; no strict 'refs'
   ; if ( defined &{ref($s).'::setup'} )
      { $hints && carp
        qq(Just change 'setup' with 'OH_init')
      }
   ; $s->setup(@_)
   }
   
; sub OH_pre_process
   { my $s = shift
   ; if ( $s->can('cgiapp_prerun') )
      { $hints && carp
        qq(Just change 'cgiapp_prerun' with 'OH_pre_process')
      ; $s->cgiapp_prerun($s->page_name, @_)
      }
   }
   
; sub OH_fixup
   { my $s = shift
   ; if ( $s->can('cgiapp_postrun') )
      { $hints && carp
        qq(Change 'cgiapp_postrun' with 'OH_fixup' )
      . qq(and use the 'page_content' instead of expecting )
      . qq(it to be passed as an argument)
      ; $s->page_content( \ ( my $p = $s->page_content ) )
                              unless ref $s->page_content
      ; $s->cgiapp_postrun($s->page_content, @_)
      }
   }
   
; sub OH_cleanup
   { my $s = shift
   ; if ( $s->can('teardown') )
      { $hints && carp
        qq(Just change 'teardown' with 'OH_cleanup')
      ; $s->teardown(@_)
      }
   }

; sub cgi_new
   { my $s = shift
   ; if ( $s->can('cgiapp_get_query') )
      { $hints && carp
        qq(Just change 'cgiapp_get_query' with 'cgi_new')
      ; $s->cgiapp_get_query(@_)
      }
     else
      { require CGI
      ; CGI->new()
      }
   }

######### CAPTURE ############

; my $output
; local *H

; sub start_capture  # starts to capture output
   { $hints && carp
     qq(Change both 'start_capture' and 'stop_capture' )
   . qq(with the single 'capture()' method)
   ; $output = ''
   ; *H = '*'.select()
   ; tie *H , 'CGI::Builder::Capt' , \ $output
   }

; sub stop_capture   # returns captured output
   { $hints && carp
     qq(Change both 'start_capture' and 'stop_capture' )
   . qq(with the single 'capture()' method)
   ; untie *H
   ; $output
   }

; package CGI::Builder::Capt

; sub TIEHANDLE
   { bless \@_, shift
   }
 
; sub PRINT
   { my $s = shift
   ; ${$$s[0]} .= join $,||'', map{defined $_? $_ : ''} @_
   }
   
; 1

__END__

=pod

=head1 NAME

CGI::Builder::CgiAppAPI - Use CGI::Application API with CGI::Builder

=head1 VERSION 1.27

The latest versions changes are reported in the F<Changes> file in this distribution. To have the complete list of all the extensions of the CBF, see L<CGI::Builder/"Extensions List">

=head1 INSTALLATION

=over

=item Prerequisites

    CGI::Builder >= 1.3
    

=item CPAN

    perl -MCPAN -e 'install CGI::Builder::CgiAppAPI'

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

   # In your old cgiapp implementation
   # change the follow line
   # use base qw( CGI::Application ) ; # or 'CGI::Application::Plus'
   
   # with this (to use the same cgiapp under CBF)
   use CGI::Builder
   qw| CGI::Builder::CgiAppAPI
     |;
   
   # this will provide you useful hints
   $CGI::Builder::CgiAppAPI::hints = 1 ;
   
   # when your migration is completed
   # just get rid of the CGI::Builder::CgiAppAPI
   use CGI::Builder ;
   

=head1 DESCRIPTION

B<Note>: You should know L<CGI::Builder>.

This module supplies an API compatible with the C<CGI::Application> or C<CGI::Application::Plus> APIs. It transparently provides all the aliases, defaults and method redefinition to make the old cgiapps work unchanged under CBF as well. Besides, it provides also very useful run-time hints that will suggest you what to change in your old code and what to read in this documentation in order to smoothly trasform your old cgiapp into a CGI::Builder application or simply learn the CBF faster.

B<WARNING>: This module is not intended to be used neither as an alternative API for the CBF nor in a production environment. You should use it only as:

=over

=item *

the glue-code to add new CBF methods and capability to your old cgiapps, thus temporarily running applications implementing mixed APIs

=item *

a substantial aid to the migration process from an old cgiapp to the CBF

=item *

a startup aid to learn (faster) the CBF API (just if you are familiar with the cgiapp API)

=back

B<IMPORTANT>: This API is compatible with the CGI::Application 3.1. The API of successive CGI::Application versions may or may not work as well; I have no plan to update this module to maintain API compatibility.

=head1 LEARNING WITH THIS API

If you are familiar with cgiapp API, you can use this module as an aid to quickly learn how to change your 'cgiapp abits'. Just build your application including it, and switch the hints ON:

   # define your build
   use CGI::Builder
   qw| CGI::Builder::CgiAppAPI
     |;
   
   # switch the hints ON
   $CGI::Builder::CgiAppAPI::hints = 1 ;

Then start to code as you already know (i.e. use the old cgiapp API), and run your code as soon as it is ready to be tried. You will receive the warnings that will 'teach' you the new API, and will suggest you what to change and what to read in the documentation.

When you have learned enough, just get rid of this module, and use the CBF API alone.

=head1 MIGRATING

=head2 Step by step instructions

=over

=item 1 Define the CBB including this API

As the first step just change the old dependency with the new one. For example:

    # take off this statement
    use base qw(CGI::Application);
    
    # and substitute it with the following one
    use CGI::Builder
    qw| CGI::Builder::CgiAppAPI
      |;

These are all the possible configurations for all the possible modules covered by this API. Use the one that apply:

=over

=item CGI::Application

   use CGI::Builder
   qw| CGI::Builder::CgiAppAPI
     |;

=item CGI::Application::Plus

   use CGI::Builder
   qw| CGI::Builder::CgiAppAPI
     |;

=item Apache::Application::Plus

   use Apache::CGI::Builder
   qw| CGI::Builder::CgiAppAPI
     |;

=item CGI::Application::Magic

   use CGI::Builder
   qw| CGI::Builder::Magic
       CGI::Builder::CgiAppAPI
     |;

=item Apache::Application::Magic

   use Apache::CGI::Builder
   qw| CGI::Builder::Magic
       CGI::Builder::CgiAppAPI
     |;

=item CGI::Application::CheckRM

Just add CGI::Builder::DFVCheck to some of the previous configurations:

   use CGI::Builder
   qw| ...
       CGI::Builder::DFVCheck
       CGI::Builder::CgiAppAPI
     |;

=back

=item 2 Check it

Try to run your application. It should run without errors, but if you have some problem, please refer to the L<"COMPATIBILITY"> section before continuing.

=item 3 Include the hints

This module provides all the hints that you need in order to change your code to the new API. Just add this line:

   $CGI::Builder::CgiAppAPI::hints = 1 ;

From now on, when you run your application you will receive a ton of warnings :-), telling you things such as "Just change "this" with "that" ....". Don't worry, you are about to change everything in a very short time.

=item 3 Get rid of warnings

Every single old API statement is producing a warning, but this does not mean that you have to go through every single line in your code one by one. Most warnings can be eliminated just by doing a "Serch and Replace" in your code.

You can recognize these warning because they start with "Just change...", so take the first one of them and do a "Search and Replace" in your code as suggested. Then re-run your application and take the next "Just change..." hint, do another "Search and Replace" with its suggested changes and so on.

In very few steps, the hints will be reduced to a very few. Please, remember that the hints explain you just the basics about the needed change, but you should take a look to the specific details in the section L<"CHANGES">.

B<Known Issue>: Although the description hint is always right, the indication of the line that needs to be changed in your code might be incorrect for a few handlers.

=item 4 Get rid of this API

When you will not receive any warning any more, you will have done with the migration and with this module. Just take off the 'CGI::Builder::CgiAppAPI' from the build list.

=item 5 Use the new defaults

at this point your CBB is running with the new CBF defaults, so remember that:

=over

=item *

The default C<page_name> is now 'index' instead of 'start'

=item *

The default prefix for your page handlers is 'PH_' instead of 'RM_'

=item *

The default C<cgi_page_param> (former mode_param) is now 'p' instead of 'rm'

=back

=back

=head1 COMPATIBILITY

B<Note>: An old cgiapp implementation should run unchanged under C<CGI::Builder::CgiAppAPI> as well, but the compatibility could be compromised if your application uses some dirty hack that bypass accessors i.e. some statements that interacts with the internal hash structure of the old class, something like C<< $self->{__PARAMS} >>, because C<CGI::Builder> implements a more consistent but different internal structure (see L<CGI::Builder/"The Internal Structure">).

=head2 param() ( CGI::Application specific )

CGI::Builder::CgiAppAPI implements on purpose a little but useful difference that could eventually break your old cgiapp code but ONLY in the rare case that your code rely on the returned value of the param() method in scalar context.

This are the differences:

    # CGI::Application param() in scalar context
    $par = $s->param() ;                  # $par == number of params || undef
    $par = $s->param(myPar =>'myPARAM') ; # $par eq 'myPARAM'
    $par = $s->param(myPar1=>'myPARAM1',  # $par is undef
                     myPar2=>'myPARAM2') ;
    $par = $s->param('myPar') ;           # $par eq 'myPARAM'
    @params = $s->param()                 # keys %$par
    
    # CGI::Builder::CgiAppAPI::param() in scalar context
    $par = $s->param() ;                  # ref $par eq 'HASH'
    $par = $s->param(myPar =>'myPARAM') ; # ref $par eq 'HASH'
    $par = $s->param(myPar1=>'myPARAM1',  # ref $par eq 'HASH'
                     myPar2=>'myPARAM2') ;
    $par = $s->param('myPar') ;           # $par eq 'myPARAM'
    %params = $s->param()                 # dereferenced

As you see, in scalar context the C<param()> method returns the reference to the underlying hash containing the parameters. This allows you to interact directly with the whole hash, or checking and deleting single parameters very easily:

    $P = $s->param ;
    while ( my ($p, $v) = each %$P )
    { do_something_useful }
    
    # check if exists a parameter
    exists $s->param->{myPar} ;
    
    # delete a parameter
    delete $s->param->{myPar} ;

In list context the param() returns a copy of the parameter hash.

=head1 API CONVERSION TABLE (quick reference)

    CGI::Application[::Plus]      CGI::Builder
    ========================      ============
    mode_param [default:'rm']     cgi_page_param [default:'p']
    start_mode [default:'start']  page_name  [default:'index']
    get_current_runmode           page_name
    QUERY                         cgi
    query                         cgi
    cgiapp_get_query              cgi_new
    PARAMS                        param
    TMPL_PATH                     page_path
    tmpl_path                     page_path
    prerun_mode                   switch_to
    header_prop                   header
    header_add                    header
    header_type                   redirect | dont_send_header | -
    run_modes                     page_handler_map
    run                           process
    cgiapp_init                   OH_init
    startup                       OH_init
    cgiapp_prerun                 OH_pre_process
    cgiapp_postrun                OH_fixup
    teardown                      OH_cleanup
    dump                          CGI::Builder::Test::dump
    dump_html                     CGI::Builder::Test::dump_html
    load_tmpl                     - | CGI::Builder::HTMLtmpl
    $ENV{CGI_APP_RETURN_ONLY}     capture('process')

    CGI::Application::Plus        CGI::Builder
    ======================        ============
    runmode [default:'start']     page_name [default:'index']
    RM_prefix [default:'RM_']     'PH_' (constant value)
    page                          page_content
    start_capture                 capture
    stop_capture                  capture
    qparam                        --

=head1 CHANGES

The CBF implements a different metaphor based on 'processing pages' instead of 'running applications'. This should be simpler to understand (specially for beginners) because it is more consistent with the specific task that a CGI::Builder application performs.

Even if the internal implementation of similar methods is greatly improved and has a completely different internal code, from the user point of view most changes here don't require more than a simple translation of identifier from one concept to the other, while just a few changes need little more attention.

The CGI::Application philosophy is very simple: the application defines several run methods, and each run method is organized to produce and return its own output page. You have to set a map in the application to define what run method has to be called for each run mode (the C<runmodes()> method does that map). This creates a pretty rigid structure.

The CBF let you organize your application in a far more flexible way, it just need to find some C<page_content> to send to the client: it does not matter what method or handler has set it during the process, (and the C<page_content> itself might even be a reference to some CODE that will print the output on its own).

This flexible structure open several handy and powerful possibilities to your application and to the extension system. If you want to know some more details about that, you could read L<CGI::Application::Plus/"Exclusive Features and Improvements"> which is the ancestor of the CBF framework.

B<Note>: The changes reported below are needed just if you want to completely convert your old cgiapp to the CBF. Until you include this API in your build, they are transparently added to your application.

=head2 mode_param

Change it with C<cgi_page_param>.

C<mode_param> is used to define the query parameter that holds the run mode, and its default is 'rm'. The CGI::Builder property to use is the C<cgi_page_param> and its default is 'p', so if your old cgiapp rely on the default, you should either set exlicitly the C<cgi_page_param> property to the old default 'rm', or change all the links to the new default 'p'.

    # (simpler) solution 1: put this line in the OH_init()
    $s->cgi_page_param = 'rm';
    
    # solution 2: change the links like: '/webapp.cgi?rm=myRunmode'
    # to '/webapp.cgi?p=myRunmode'

Besides, the old C<mode_param> accepted as well a CODE reference returning the page name, while C<cgi_page_param> doesn't. In this case - if you want to generate the page name by some sub - you should just override the C<get_page_name()> method, and set explicitly the C<page_name> property:

    sub get_page_name {
        my $s= shift;
        ... your code to get the page name ...
        $s->page_name = $resulting_page_name
    }

=head2 start_mode, get_current_runmode, runmode

Change them with C<page_name> (i.e. the cgiapp runmode).

C<start_mode>, C<get_current_runmode> (and C<runmode> in CGI::Application::Plus) are used to set and get the (start) run mode (i.e. the CGI::Builder page name). You should use the C<page_name> property instead.

    $s->page_name = 'mystart'
    $s->page_name  # always returns the current page name

B<Important Note>: Remember that the default C<page_name> is 'index' while the default run mode was 'start' so if you get rid of this API after a migration you should consider this new default.

=head2 QUERY and query

Change them with C<cgi>.

C<QUERY> (and C<query> in CGI::Application::Plus) are used to pass a cgi object with the C<new()> method. You should use C<cgi> property instead.

    $webapp = WebApp->new(cgi=>CGI->new) ;
    # or
    $s->cgi = CGI->new ;

=head2 cgiapp_get_query

Just change it with C<cgi_new>.

=head2 PARAMS

Change them with C<param>.

C<PARAMS> is used to pass a reference to an hash containing some param with the C<new()> method or to set some application param. The CBF accessor to set and retrieve your application param is the C<param()> property group accessor, you should use it instead.

=head2 TMPL_PATH and tmpl_path

Change them with C<page_path>.

C<TMPL_PATH> (and C<tmpl_path> in CGI::Application::Plus) are used to pass a template path with the C<new()> method. You should use C<page_path> property instead

    $webapp = WebApp->new(page_path=>'/mypath')

=head2 prerun_mode

Just change it with C<switch_to>.

Used to set the prerun mode. You should use C<switch_to()> method instead.

    $s->switch_to('myRunmode')

=head2 header_prop and header_add

Change it with C<header()>.

C<header_prop()> and C<header_add()> are used to manage header. You should use the C<header()> property group accessor instead. With it you can add, delete, retrieve, check for existance, ...

=head2 header_type

Used to set the type of header among 'header', 'redirect' and 'none'. You don't need to use it anymore. When you want to redirect you should use the C<redirect(url)> method, and if you don't want to send any header, just set the C<dont_send_header> property to a true value.

=head2 run_modes

Change it with C<page_handler_map>.

C<run_modes> is used to define a run method for each run mode, but since the CGI::Builder uses the Page Handler prefix (default 'PH_') to find and execute the page handler for each page_name, you need to use C<page_handler_map> just if you want to map some page_name to a specific page handler. For example:

    # this page Handler (run method) does not need to be
    # declared with page_handler_map()  and will be
    # executed automatically by page_name 'myPage'
    
    sub PH_myPage {
        do_something_useful
    }

    # the 'some_special_handler' method will be executed
    # when the page_name will be 'mySpecialPage'
    $s->page_handler_map(mySpecialPage => 'some_special_handler')

=head2 run

Just change it with C<process>.

=head2 cgiapp_init and startup

Just change them with C<OH_init>.

=head2 cgiapp_prerun

Just change it with C<OH_pre_process>.

=head2 cgiapp_postrun

Change it with C<OH_fixup>.

Under CGI::Builder::CgiAppAPI the C<cgiapp_postrun> will receive the reference to the output content in $_[1] as usual, but the CGI::Builder C<OH_fixup()> will not receive that parameter, so it should handle this by using the C<page_content> property.

    sub OH_fixup {
       # my ($s) = @_ ;
       my $content = $s->page_content ;
    }

=head2 teardown

Just change it with C<OH_cleanup>.

=head2 dump and dump_html

You should include CGI::Builder::Test in order to use C<dump> and C<dump_html> methods:

    use CGI::Builder
    qw| CGI::Builder::Test
        ... other inclusions ...
      |;

=head2 load_tmpl

This module supply the old C<load_tmpl> method, but you should include the CGI::Builder::HTMLtmpl in your CBB that offers a more powerful integration with HTML::Template.

    use CGI::Builder
    qw| CGI::Builder::HTMLtmpl
        ... other inclusions ...
      |;

=head2 $ENV{CGI_APP_RETURN_ONLY}

This works only with C<run()> and not with C<process()>: use the C<capture> method if you need to test the output.

    $webapp = WebApp->new();
    $ref_to_output = $webapp->capture('process')

=head2 AUTOLOAD runmode

Under CGI::Builder the AUTOLOAD run method will not receive the runmode as the argument because it is always available with the C<page_name> property, so you should use that property instead:

    sub myAutoloadRM {
       # my ($s, $runmode) = @_ ;
       # previous line changed with the following two lines
       my ($s) = @_ ;
       my $runmode = $s->page_name ;
    }

=head1 CHANGES (CGI::Application::Plus Specific)

The changes reported in this section are specific for CGI::Application::Plus only: i.e. they don't apply to simple CGI::Application.

=head2 RM_prefix

This property accessor is not supported by the CBF which uses the 'PH_' constant prefix instead. You should change the prefix of all your methods to the 'PH_' constant:
   
    # sub RM_foo { ... }
    # become
    sub PH_foo { ... }

=head2 page

Just change it with C<page_content>.

=head2 start_capture and stop_capture

Use C<capture> instead.

C<start_capture> and C<stop_capture> methods are used to capture the output, either for testing purpose or in a cgiapp_postrun method. You should use the new CGI::Builder method C<capture> that does the same in a simpler and efficient way.

    # old way
    $s->start_capture() ;
    $s->run();                       # CBF process()
    $$captured = $s->stop_capture ;
    # now $captured is the ref to the captured output
    
    # becomes
    $captured = $s->capture('process')
    # now $captured is the ref to the captured output

Used in a cgiapp_postrun it was:

    sub cgiapp_postrun
    {
      my ($s, $ref) = @_ ;         # $ref always the same as $s->page
      if (ref $ref eq 'CODE')
      {
        $s->start_capture() ;
        $ref->($s) ;               # executes $ref CODE (print)
        $$ref = $s->stop_capture ; # now $ref is the ref to the content
      }
      # do something with $ref as usual
    }


Now, used in a CGI::Builder OH_fixup becomes more explicitly:

  sub OH_fixup {
      my $s = shift ;
      if (ref $s->page_content eq 'CODE')  {
          # executes the referenced CODE and captures the output
          $s->page_content = $s->capture($s->page_content)
      }
      # do something with $s->page_content as usual
  }


=head2 qparam

This property group accessor is not supported by the CBF. You can use the C<< $s->cgi->param() >>, the C<< $s->cgi->Vars() >> methods or - if you really like it - you can implement it in your own CBB by just adding these lines:

    use Object::groups
        ( { name    => 'qparam',
            default => sub { eval{ scalar $_[0]->cgi->Vars }
                              || croak qq(The cgi object cannot "Vars", you )
                                     . qq(cannot use the "qparam" property.)
                           }
          }
        );

=head2 checkRM

Change the C<checkRM()> method provided by C<CGI::Application::CheckRM> with the C<dfv_check()> method provided by C<CGI::Builder::DFVCheck>.

=head2 tm_defaults

Change the C<tm_defaults()> group accessor provided by C<CGI::Application::Magic> with the C<tm_new_args()> group accessor provided by C<CGI::Builder::Magic>.

=head2 request

Change the C<request()> property accessor provided by C<Apache::Application::Plus> with the C<r> property accessor provided by C<Apache::CGI::Builder>.

=head1 SUPPORT

See L<CGI::Builder/"SUPPORT">.

=head1 AUTHOR and COPYRIGHT

© 2004 by Domizio Demichelis (L<http://perl.4pro.net>)

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.

=cut
