# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..14\n"; }
END {print "not ok 1\n" unless $loaded;}
use Class::Skin;
use Log::LogLite;
use strict;
use vars qw($loaded);
use diagnostics;
use Cwd;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.
unlink("test.log");
my $log = new Log::LogLite("test.log");


############################### Test 1 ###################################
my $i = 777;
my $title = "Usage of Class::Skin";
my $tt;
my $output;

# create new Class::Skin object
$tt = new Class::Skin("templates/template1.txt", $log);

# read the template file 
$tt->read();

# parse the template and print the result. we send in anonymous 
# hash all the variables that we would like to use in the template
$output = $tt->parse({ title => $title,
		       i => $i,
		       condition1 => 1,
		       condition2 => 0,
		       condition3 => 1,
		       condition4 => 0,
		       condition5 => 1,
		       condition6 => 0,
		       condition7 => 1,
		       condition8 => 0,
		       condition9 => 1,
		       filepath   => "template2.txt",
		       func       => \&call_back_func});

if (clean_whites($output) eq clean_whites(q(
*** Usage of Class::Skin ***

Here two templates will be included:

--- start of template2 ---

included template 2 is here. Template 2 is inserted into the first template.
We can put use here all the variables like "Usage of Class::Skin".
---  end of template2  ---
--- start of template2 ---

included template 2 is here. Template 2 is inserted into the first template.
We can put use here all the variables like "Usage of Class::Skin".
---  end of template2  ---

Here we will put some conditions:

 condition1 is true
  condition3 is true (in condition1)
   condition5 is true (in condition3 that in condition1)
 condition5 is true
Here we will put a table where the rows are in a while loop.
Note that we use $a here, but $a is not defined in the calling script, so
it stays $a. Only in the last loop of the while we will define $a.

778: $a  condition7 is true inside the while loop. 

779: $a  condition7 is true inside the while loop. 

780: [this is a]  condition7 is true inside the while loop. ))) {
    print "ok 2\n";
}
else {
    print "not ok 2\n";
}
############################### Test 3 ###################################

# create new Class::Skin object
$tt = new Class::Skin("templates/template3.txt", $log);

# read the template file 
$tt->read();

# parse the template and print the result. we send in anonymous 
# hash all the variables that we would like to use in the template
$output = $tt->parse({ var => "first",
		       i => 0,
		       j => 0,
		       outer_loop => \&outer_loop,
		       inner_loop => \&inner_loop });

if (clean_whites($output) eq clean_whites(q(first
 
  second1
   
    third1
   
    third2
  
 
  second2))) {
    print "ok 3\n";
}
else {
    print "not ok 3\n";
}



############################### Test 4 ###################################

# create new Class::Skin object
$tt = new Class::Skin("templates/template4.txt", $log);

# read the template file 
$tt->read();

# parse the template and print the result. we send in anonymous 
# hash all the variables that we would like to use in the template
$output = $tt->parse({ j => 0,
		       inner_loop => \&inner_loop } );

if (clean_whites($output) eq 
    clean_whites(q(in template4.txt:
		   
		   <include src="template5.txt" skip="1">
		   
		   <include src="template5.txt" skip="1">
		   ))) {
    print "ok 4\n";
}
else {
    print "not ok 4\n";
}
############################### Test 5 ###################################

$tt->lines($output);
$output = $tt->parse({ j => 0,
		       inner_loop => \&inner_loop } );
#print $output."\n";
if (clean_whites($output) eq 
    clean_whites(q(in template4.txt:
		   
		   <include src="template5.txt" skip="0">
		   
		   <include src="template5.txt" skip="0">
		   ))) {
    print "ok 5\n";
}
else {
    print "not ok 5\n";
}
############################### Test 6 ###################################

$tt->lines($output);
$output = $tt->parse({ j => 0,
		       inner_loop => \&inner_loop } );
#print $output."\n";
if (clean_whites($output) eq 
    clean_whites(q(in template4.txt:
		   
		   *** template5.txt is included here ***
		   *** template5.txt is included here ***))) {
    print "ok 6\n";
}
else {
    print "not ok 6\n";
}


########################### TEST 7 #######################################
mkdir("templates/t");
mkdir("templates/t/a");
open(FILE, ">templates/t/a/included_template.txt");
print FILE "bla";
close(FILE);

# create new Class::Skin object
$tt = new Class::Skin("templates/template6.txt", $log);
# read the template file 
$tt->directory_list(cwd()."/templates/t,".cwd()."/templates/tmp,".cwd()."/templates/t/a");
$tt->read();
$output = $tt->parse({ a => 1 });
if ($output eq 'bla
<a href="#">linked_bla</a>') {
    print "ok 7\n";
}
else {
    print "not ok 7\n";
}
############################### Test 8 ###################################
# create new Class::Skin object
$tt = new Class::Skin("a/included_template.txt", $log);
# read the template file 
$tt->directory_list(cwd()."/templates/t,".cwd()."/templates/tmp");
$tt->read();
if (clean_whites($tt->parse()) eq "bla") {
    print "ok 8\n";
}
else {
    print "not ok 8\n";
}

############################### Test 9 ###################################

# create new Class::Skin object
$tt = new Class::Skin("templates/template7.txt", $log);
# read the template file 
$tt->read();
$output = $tt->parse({url_path => "/htdocs/html" });
if (clean_whites($output) eq clean_whites('/htdocs/html
     <a href="#"><img src="/htdocs/html/images/spacer.gif" border="0"></a>')) {
    print "ok 9\n";
}
else {
    print "not ok 9\n";
}


############################### Test 10 ###################################

# create new Class::Skin object
$tt = new Class::Skin("templates/template8.txt", $log);
# read the template file 
$tt->read();
$output = "";
$output = $tt->parse({action => 
			   "/cgi-bin/projects/webiso/code/cgi_client.pl" });
if (clean_whites($output) eq clean_whites(q(
<HTML>
  <HEAD>
  <TITLE>Webiso</TITLE>
  </HEAD>

  <FRAMESET COLS="180,*" BORDER=1>
    <FRAMESET ROWS="350,*" BORDER=1>	
      <FRAME NAME="menu" 
             SRC="/cgi-bin/projects/webiso/code/cgi_client.pl?command=webiso_menu&extra_param=$extra_param&which_button=manual_structure_pushed" 
             SCROLLING=NO 
             MARGINHEIGHT=0 
             MARGINWIDTH=0>
      <FRAME NAME="messages"      
             SRC="/cgi-bin/projects/webiso/code/cgi_client.pl?command=dbot_show_empty" 
             SCROLLING=AUTO
             MARGINHEIGHT=0 
             MARGINWIDTH=0>
    </FRAMESET>              
    <FRAME NAME="main" 
           SRC="/cgi-bin/projects/webiso/code/cgi_client.pl?command=dbot&extra_param=$extra_param" 
           SCROLLING=AUTO 
           MARGINHEIGHT=0 
           MARGINWIDTH=0>
  </FRAMESET>
</HTML>
))) {
    print "ok 10\n";
}
else {
    print "not ok 10\n";
}

############################### Test 11 ###################################
# create new Class::Skin object
$tt = new Class::Skin("templates/template6.txt", $log);
# read the template file 
$tt->directory_list(cwd()."/templates/t,".cwd().",/templates/tmp,".cwd()."/templates/t/a");
$tt->skip_includes(1);
$tt->read();
$output = $tt->parse({ a => 1 });

if ($output eq '<include src="a/included_template.txt">
<a href="#">linked_bla</a>') {
    print "ok 11\n";
}
else {
    print "not ok 11\n";
}

###################################################################

############################### Test 12 ###################################
# create new Class::Skin object
$tt = new Class::Skin("templates/template10.txt", $log);
# read the template file 
$tt->read();
$output = $tt->parse({  });
open(FILE, ">output12.txt");
print FILE $output."\n";
close(FILE);
if (do_files_equal("output12.txt", "templates/result12.txt")) {
    print "ok 12\n";
}
else {
    print "not ok 12\n";
}

############################### Test 13 ###################################
# create new Class::Skin object
$tt = new Class::Skin("templates/template9.txt", $log);
# read the template file 
$tt->read();
$output = $tt->parse({ bla => "this is bla" });
if ($output eq q(this is bla
this is bla
$bla_this is bla
this is bla_this is bla
this is bla_this is bla
$
$$
$$this is bla
(this is bla)
$(bla there))) {
    print "ok 13\n";
}
else {
    print "not ok 13\n";
}

############################### Test 14 ###################################
# create new Class::Skin object
$tt = new Class::Skin("templates/template12.txt", $log);
# read the template file 
$tt->read();
$output = $tt->parse({ condition1 => 0,
		       condition2 => 0 });
if ($output eq q(
bar
)) {
     print "ok 14\n";
}
else {
    print "not ok 14\n";
}   

###################################################################

unlink("templates/t/a/included_template.txt");
rmdir("templates/t/a");
rmdir("templates/t");
#unlink("output12.txt");


# callback function. we will give a reference to that function as 
# one of the variables we sent with the parse method. callback 
# functions are used with the 'while' block. this function must
# return true or false (1 or 0). it is important that it will not 
# return always true (or else the while block will be repeated 
# infinite times).
sub call_back_func {
    my $variables = shift; # always a reference to the anonymous hash
    # that we send with the parse method is 
    # send to the callback functions.
    
    $variables->{i}++; # increment the value of i
    
    # toggle the value of condition9 according to the value of i
    if ($variables->{i} == 779) {
	$variables->{condition9} = 1;
    }
    else {
	$variables->{condition9} = 0;
    }
    
    if ($variables->{i} == 780) {
	$variables->{a} = "[this is a]";
    }
    else {
	$variables->{a} = undef;
    }

    # return true unless i > 780. 
    if ($variables->{i} <= 780) {
	return 1;
    }
    else {
	return 0;
    }
} # of call_back_func 

sub outer_loop {
    my $var = shift; # always a reference to the anonymous hash
    # that we send with the parse method is 
    # send to the callback functions.
    
    $var->{i}++; # increment the value of i
    
    $var->{var} = "second".$var->{i};
    if ($var->{i} < 3) {
	return 1;
    }
    else {
	return 0;
    }
} # of outer_loop

sub inner_loop {
    my $var = shift; # always a reference to the anonymous hash
    # that we send with the parse method is 
    # send to the callback functions.
    
    $var->{j}++; # increment the value of i
    
    $var->{var} = "third".$var->{j};
    if ($var->{j} < 3) {
	return 1;
    }
    else {
	return 0;
    }
} # of inner_loop


#######################
# clean_whites
#######################
sub clean_whites {
    my $str = shift;
    $str =~ s/\s+/ /goi;
    $str =~ s/^\s//;
    $str =~ s/\s$//;
    return $str;
} # of clean_whites


#####################
# do_file_equal
#####################
sub do_files_equal {
    my $path1 = shift;
    my $path2 = shift;
    open(FILE1, $path1);
    open(FILE2, $path2);
    while (1) {
	my $line1 = <FILE1>;
	my $line2 = <FILE2>;
	if (!defined($line1) && !defined($line2)) {
	    last;
	}
	chomp($line1);
	chomp($line2);
	if ($line1 ne $line2) {
	    close(FILE1);
	    close(FILE2);
	    return 0;
	}
    }
    close(FILE1);
    close(FILE2);
    return 1;
} # do_file_equal
