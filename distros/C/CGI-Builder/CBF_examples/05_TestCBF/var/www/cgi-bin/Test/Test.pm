package
 Test;
 
use CGI;
use CGI::Builder
    qw(
       CGI::Builder::Session
       CGI::Builder::Magic
       CGI::Builder::DFVCheck
       );

# create a new property for the class 
# the default returns a filehandle to the log file
use Class::props {
    name    => fh_log,
    default => sub {
	open my $fh_tmp, ">>/tmp/test.log";
	print $fh_tmp "FH_LOG opened\n";
	$fh_tmp;
    }
};

# my subs begin with "_"
sub _get_counter {
    my $s = shift;
    return $s->cs->param("counter");
}

# my subs begin with "_"
sub _inc_counter {
    my $s = shift;
    $s->cs->param("counter",$s->cs->param("counter")+1);
}

# init phase
sub OH_init {
    my $s = shift;

    # set page_path for Template::Magic
    $s->page_path = "./tm";

    # log
    print {$s->fh_log} "OH_init\n";
}

# ---> the Main page have no "sub PH_Main"
# ---> It's just a template in /tm!


# in $s->page_content the page content of the page 
# http://localhost/cgi-bin/Test/test.pl?p=Hello
sub PH_Hello {
    my $s = shift;
    print {$s->fh_log} "PH_Hello\n";
    $s->page_content = "Hello world!";
}

# in $s->page_content the page content of the page 
# http://localhost/cgi-bin/Test/test.pl?p=NiceHello
sub PH_NiceHello {
    my $s = shift;
    print {$s->fh_log} "PH_NiceHello\n";
    $s->page_content = "This is a nice HeLlO WoRlD! :-)";
}
  
# the TmHello page has a template in /tm dir and here I set
# some vars to display using the mark <!---{VARNAME}--> in the template
sub PH_TmHello {
    my $s = shift;
    print {$s->fh_log} "PH_TmHello\n";
    # tm_lookups entry to display vars in the template
    $s->tm_lookups = { 
	a=>1 ,
	b=>2 ,
	c=>3 ,
    };
}
  
# executed just before Form1: it can be used to verify user values
# if the x param is equal to XXX then ok, goto Form1_Res;
# else repeat insertion; 
# used <!--FillInForm--> to automatically reinsert previous user values in the form
sub SH_Form1 {
    my $s = shift;
    print {$s->fh_log} "SH_Form1\n";

    if (defined $s->cgi->param('x') && $s->cgi->param('x') eq "XXX") {
	$s->switch_to('Form1_Res');
    }
    # else repeat Form1 insertion 
}
  
# display Form1
# the PH_Form1 sub is used to increment and set the "counter",
# a session stored value
# with CGI::Builder::Magic I can omit a sub if the template exists
# and I've no value to set
sub PH_Form1 {
    my $s = shift;
    print {$s->fh_log} "PH_Form1\n";
    _inc_counter($s);
    $s->tm_lookups = { 
	z=>_get_counter($s),
    };
}
  
# this sub is called to display inserted values
# The only valid value for x is "XXX"
sub PH_Form1_Res {
    my $s = shift;
    print {$s->fh_log} "PH_Form1_Res\n";
    _inc_counter($s);
    $s->tm_lookups = { 
	x=>$s->cgi->param('x') ,
	y=>$s->cgi->param('y') ,
	z=>_get_counter($s),
    };
}

# ---> No need for "sub PH_Form2"!
# ---> just the template in /tm

sub SH_Form2_Res {
    my $s = shift ;
    $s->dfv_check({ required => 'city',
		    constraints => {
			email => 'email',
		    },
		    msgs => {
			
			# set a custom error prefix, defaults to none
			prefix => 'err_',
			
                        # Error messages, keyed by constraint name
                        # Your constraints must be named to use this
			constraints => {
			    'email' => 'Insert a right email format!',
			},			
		    },
		})
	# return to input form
        || $s->switch_to('Form2'); 

    $s->tm_lookups = { 
	email=>$s->cgi->param('email') ,
	city=>$s->cgi->param('city') ,
    };

    print {$s->fh_log} "SH_Form2_Res\n";
}

# ---> No need for "sub PH_Form2_Res"!
# ---> just the template in /tm

# called after the PAGE_HANDLER Phase 
sub OH_fixup {
    my $s = shift;
    print {$s->fh_log} "OH_fixup\n";
}

# called at the end of the process to allow cleanup
sub OH_cleanup {
    my $s = shift;
    print {$s->fh_log} "OH_cleanup\n\n";
    # close the file
    close $s->fh_log
}

1;
