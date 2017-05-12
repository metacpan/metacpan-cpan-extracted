# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

### DESCRIPTION ###
# This is a very simple super class written just to understand
# how the handlers get called. You should integrate the
# comment of this file, with the CGI::Builder documentation

# With this super class we want just to add and executed a couple of
# hooks to the process so we define the OH_init and the OH_cleanup handlers.
# Then this super class will be included in a CBB with the use statement

# PLease notice that the order of execution of the OH_init and the OH_cleanup
# is reversed

# defines the super class package
; package SimpleSuperClass

# this handler is called internally by the new() method
# i.e. at each new instance creation, i.e. for every page process
; sub OH_init
   { warn "- Running SimpleSuperClass::OH_init"
   }

# this handler is called internally for every page process
; sub OH_cleanup
   { my $s = shift
   ; warn "- Running SimpleSuperClass::OH_cleanup"
   }

   
; 1
