# TrackProcess CBB

# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

### DESCRIPTION ###
# This is a very simple CBB written just to understand
# how the handlers get called. You should integrate the
# comment of this file, with the CGI::Builder documentation

# With this CBB we want to generate a very simple page_content for page1,
# page2 and page3.
# We also want to print a warning for the execution of each handler, thus
# printing a sort of handler log in the server log

# Please keep in mind the "Process Phases" and the "HANDLERS" sections
# in the doc to have a more detailed overview of the whole process, and more
# details about each handlers. Feel free to add more information to the
# warning strings, in order to better understand the process.

# Feel free to add more features to this CBB in order to better understand
# the documentation

############ CBB START ###########

# defines the CBB package
; package TrackProcess

########## BUILD INCLUSION #########
# with this statement this CBB will inherit the CBF capabilities
# and methods. In this CBB, we include the SimpleSuperClass super class
# to better understand the overrunning concept
; use CGI::Builder
  qw| SimpleSuperClass
    |


########## OVERRUNNING HANDLERS ##########
# Usually you don't need to define each handler in your CBB, but just the ones
# you need. Obviously, here we need them all in order to track them all.

# this handler is called internally by the new() method
# i.e. at each new instance creation, i.e. for every page process
; sub OH_init
   { warn "- Running OH_init"
   }

# this handler is called internally for every page process
; sub OH_pre_process
   { warn "- Running OH_pre_process"
   }

# this handler is called internally for every page process
; sub OH_pre_page
   { my $s = shift
   ; my $page_name = $s->page_name
   ; warn "- Running OH_pre_page (page_name: \"$page_name\")"
   }

# this handler is called internally for every page process
; sub OH_fixup
   { warn "- Running OH_fixup"
   }

# this handler is called internally for every page process
; sub OH_cleanup
   { my $s = shift
   ; warn "- Running OH_cleanup"
   }

########## END OVERRUNNING HANDLERS ##########

######### METHOD OVERRIDING ###########

# This overriding section is defined here just for tracking purpose.
# A regular CBB will rarely need to override these methods.

# even if we don't need to override the way the CBF gets the page_name
# we override the get_page_name method in this CBB just to track its execution
; sub get_page_name
   { my $s = shift
   ; $s->SUPER::get_page_name      # executes the process as usual
   ; my $page_name = $s->page_name
   ; warn "- Running get_page_name (page_name is now: \"$page_name\")"
   }

# even if we don't need to override the way the CBF sends the page_content
# to the client we override the following 3 methods just to track their execution

; sub page_content_check
   { my $s = shift
   ; warn "- Checking the page content"
   ; $s->SUPER::page_content_check     # executing the CBF method as usual
   }

; sub send_header
   { my $s = shift
   ; warn "- Sending the header"
   ; $s->SUPER::send_header            # executing the CBF method as usual
   }
 
; sub send_content
   { my $s = shift
   ; warn "- Sending the page content"
   ; $s->SUPER::send_content           # executing the CBF method as usual
   }
######### END METHOD OVERRIDING ###########
   
############## PER-PAGE HANDLERS ################

# These are the handlers called on a per page basis,
# i.e. each per Page Handler is called ONLY for a certain requested page.
# Unless you use some extension that sets the page_content on its own,
# you usually need one PH_* handler per page in order to set the page_content

# This CBB implements just 3 page handlers

# this handler should switch to another page in a regular CBB
# but we don't use the switch_to() statement here, because we just want
# to track its execution
# this handler is called just for page 'page1'
; sub SH_page1
   { warn "- Running SH_page1 (we don't switch)"
   }
   
# this handler is called just for page 'page1'
; sub PH_page1
   { my $s = shift
   ; warn "- Running PH_page1"
   ; $s->page_content = "This is the content of page1\n"
   }
   
# this handler is called just for page 'page2'
# it will unconditionally switch_to page3, thus the PH_page2
# will never get executed
; sub SH_page2
   { my $s = shift
   ; warn "- Running SH_page2 (we switch to \"page3\")"
   ; $s->switch_to('page3')
   }
   
# this handler is called just for page 'page2'
; sub PH_page2
   { my $s = shift
   ; warn "- Running PH_page2 (never executed)"
   ; $s->page_content = "This is the content of page2\n"
   }
   
# this handler should switch to another page in a regular CBB
# but we don't use the switch_to() statement here, because we just want
# to track its execution
# this handler is called just for page 'page3'
; sub SH_page3
   { warn "- Running SH_page3 (we don't switch)"
   }
   
# this handler is called just for page 'page3'
; sub PH_page3
   { my $s = shift
   ; warn "- Running PH_page3"
   ; $s->page_content = "This is the content of page3\n"
   }

############## END PER-PAGE HANDLERS ################

############## PLEASE IGNORE THIS ###################

# This is an addiction to track the PHASE too. You will never
# need it, so please just ignore it.

; use CGI::Builder::Const qw(:all)

; use Class::constr
        { init       => sub{ warn '### CB_INIT PHASE'
                           ; my $s = shift
                           ; local $SIG{__DIE__} = sub{$s->die_handler(@_)}
                           ; $s->CGI::Builder::_::exec('init', @_)
                           }
        , no_strict  => 1
        }

; use Object::props
        { name       => 'PHASE'
        , default    => CB_INIT
        , validation => sub
                         { my ($s, $phase_num) = @_
                         ; my $phase = $CGI::Builder::Const::phase[$phase_num]
                         ; warn "### $phase PHASE"
                         ; 1
                         }
        , allowed    => qr/^CGI::Builder/  # only settable from CBF
        }

   
; 1
