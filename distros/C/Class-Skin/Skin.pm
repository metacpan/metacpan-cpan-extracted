package Class::Skin;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

our $VERSION = '0.05';

use Carp;
use strict;
use Log::NullLogLite;
use bytes;
use Cwd;

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/ || $!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined Class::Skin macro $constname";
	}
    }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
	if ($] >= 5.00561) {
	    *$AUTOLOAD = sub () { $val };
	}
	else {
	    *$AUTOLOAD = sub { $val };
	}
    }
    goto &$AUTOLOAD;
}

bootstrap Class::Skin $VERSION;

# Preloaded methods go here.

#############################################################
# new()
# new($file_path) 
# new($file_path, $log) 
#############################################################
# the constructor
sub new {
    my $proto = shift; # get the class name
    my $class = ref($proto) || $proto;
    my $self  = {};
    # private data
    $self->{FILE_PATH} = shift;
    $self->{LOG} = shift || new Log::NullLogLite();
    $self->{LINES} = undef;
    $self->{SKIP_INCLUDES} = 0; # by deafult we process the includes
    $self->{CLEAN_EMPTY_LINES} = 1; # by deafult we clean empty lines
    $self->{CWD} = getcwd();
    # by default, contains the current directory
    $self->{DIRECTORY_LIST} = $self->{CWD};
    bless ($self, $class);
    return $self;
} # of new

####################################
# log()
####################################
sub log {
    my $self = shift;
    if (@_) { $self->{LOG} = shift }
    return $self->{LOG};
} # of log

####################################
# skip_includes()
####################################
sub skip_includes {
    my $self = shift;
    if (@_) { $self->{SKIP_INCLUDES} = shift }
    return $self->{SKIP_INCLUDES};
} # of skip_includes

####################################
# clean_empty_lines()
####################################
sub clean_empty_lines {
    my $self = shift;
    if (@_) { $self->{CLEAN_EMPTY_LINES} = shift }
    return $self->{CLEAN_EMPTY_LINES};
} # of clean_empty_lines

####################################
# file_path()
####################################
sub file_path {
    my $self = shift;
    if (@_) { $self->{FILE_PATH} = shift }
    return $self->{FILE_PATH};
} # of file_path

####################################
# directory_list()
####################################
sub directory_list {
    my $self = shift;
    if (@_) { $self->{DIRECTORY_LIST} = shift }
    return $self->{DIRECTORY_LIST};
} # of directory_list

####################################
# lines()
####################################
sub lines {
    my $self = shift;
    if (@_) { $self->{LINES} = shift }
    return $self->{LINES};
} # of lines

####################################
# read()
####################################
sub read {
    my $self = shift;
    my $path = shift || $self->{FILE_PATH};    
    my $path_dir = $path;
    if ($path =~ /\/[^\/]+$/) {
	$path_dir = $`;
    }
    $self->{DIRECTORY_LIST} .= ",$path_dir";

    # we use the other target lines reference in order to read the template
    # into other target then the lines of the object. this way we can call
    # the read method in order to read included templates.
    my $other_target_lines_ref = shift || 0;
    # check to see if $self->{FILE_PATH} is valid
    unless (-e $path) {
	# first check if it is relative or absolute path:
	unless (is_absolute_path($path)) { # relative path
	    foreach my $directory (split(/,/, $self->{DIRECTORY_LIST})) {
		if (-e $directory."/".$path) {
		    $path = $directory."/".$path;
		    last;
		}
	    }	    
	}
    }
    # open the file
    open(FILE, $path) || do {
	$self->{LOG}->write("Could not open to read the file ".
			    $path.": ".$! , 4);
	$self->{LOG}->write("the directories in the directory list are: ".
			    $self->{DIRECTORY_LIST}, 4);
	return 0;
    };

    # read the lines from the file
    if ($other_target_lines_ref) {
	read(FILE, $$other_target_lines_ref, -s FILE);
    }
    else {
	read(FILE, $self->{LINES}, -s FILE);
    }
    return 1; # success
} # of read

####################################
# $html = parse({ var1 => val1,
#                 var2 => val2,
#                 ...
#               })
####################################
sub parse {
    my $self = shift;
    my $variables = shift;
    my $lines = $self->{LINES};
    return xs_parse($self, $variables, $lines);    
}

################
# perl_write_log
################
sub perl_write_log {
    my $self = shift;
    my $message = shift;
    my $level = shift;
    $self->{LOG}->write($message, $level);
} # of perl_write_log

######################
# is_absolute_path
######################
sub is_absolute_path {
    my $path = shift;

    # Returns 1 if path supplied is an absolute path
    # Returns 0 if path is not absolute.
    unless (defined($path)) {
	return 0;
    }
    # the different Operating Systems
    my %operating_systems = ( "mswin32"  => '^(?:[a-zA-Z]:)?[\\\/]+',
			      "linux"    => '^\/',
			      "cygwin"   => '^([A-Za-z]:)|^(\/)');
    
    my $os = lc($^O);
    my $reg_expression = $operating_systems{$os} || 
	$operating_systems{'linux'};    
    return $path =~ /$reg_expression/;
} # is_absolute_path


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Class::Skin - Class for creating text out of text templates.

=head1 SYNOPSIS

  use Class::Skin;
  
  # create new Class::Skin object
  my $skin = new Class::Skin("template.txt");

  # read the template file 
  $skin->read(); 

  # parse the template and print the result. we send in anonymous 
  # hash all the variables that we would like to use in the template
  print $skin->parse({ title => $title,
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

=head1 DESCRIPTION

The elements that can be used in the templates:

=over 4

=item Comments 

Comments will just be removed from the template when the template is parsed.
                  <comment>
                    this is a comment
                  </comment> 


=item Perl Variables 

Variables will be sent to the Class::Skin object when parsing as reference 
to anonymous hash.
                  $name 

=item Including other files 

Includes will be parsed and included instead of the include tag.  
There is a way to avoid from including all the includes while parsing the 
template (see skip_includes method). This might be useful when parsing
the template will create yet another template that will be parsed again 
later. There is also a way to skip the including for certain include, for
certain times that that include is parsed (so that the parse method is called).
That is done by using the attribute skip. Every time the method parse is called
the value of the skip attribute will be decremented. If it is zero, the parse
will include the template that is defined in the src.

                  <include src="other_template.txt">
                  <include src="$name"> 
                  <include src="template.txt" skip="2">

The included template path can be absolute, or relative. If it is relative, 
it will be searched, relative to the host template path, or relative to the 
list of directories. This list is populated by default by the path of the 
current directory and the path of the hosted templates. It can be manipulated 
by the access method I<directory_list>.

=item If-elsif-else 

The condition blocks are solved using the values of the variables that are 
put as the conditions. Note that it is possible to have one block inside other.
                  <if condition="name1">
                    <h1> positive... </h1>
                  </if>
                  <elsif condition="name2">
                    <h1> Negative... </h1>
                  </elsif>
                  <else>
                    <h1> Zero... </h1>
                  </else> 
Any white characters betweeb a closing tag of if-elsif-else block and the 
next opening tag of yet the same block will be ignored.  

=item While loop 

While blocks will be executed as long as the callback function returns true. 
The callback function reference is sent as variable in the anonymous hash. 
The callback function must take as its only argument the same anonymous 
hash as the anonymous hash that is sent to the parse method. See the callback
function in the example.
                  <while condition="function_name">
                    <tr>
                      <td>$i</td>
                    </tr>
                  </while> 

=back

=head1 CONSTRUCTOR

=over 4

=item new ( [FILEPATH [, LOG ]] )

The constructor. If FILEPATH is defined, it will be taken as the file path 
of the template. If LOG is defined, it will be used as a Log object for 
logging errors. It is recommended to use the LOG as it helps finding errors
in using the class (like trying to include a file that is not found or
trying to use a while loop with call back function that does not exist).
Returns the new object. 

=back

=head1 METHODS

=over 4

=item read()

This method tries to open the template file (using the FILE_PATH data member)
and to read its content to the LINES data member.
Returns 1 on success, 0 on failure. 

=item parse( [ REFERENCE_TO_ANONYMOUS_HASH ] )

This method will parse the template using the anonymous hash variable that 
is sent to it as a parameter.
For details about the parsing rules see above.
Returns the parsed template on success or undef on failure. 

=item lines( [ LINES ] )

The access method to the LINES data member. This data member is a string 
that holds all the lines of a read template. If LINES is defined, its value 
will replace the current value of the LINES data member (as if we read a 
new template).
Returns the value of the LINES data member. 

=item log( [ LOG ] )

The access method to the LOG data member. If the LOG data member is defined, 
error messages will be logged using that Log object.
Returns the value of the LOG data member. 

=item skip_includes( [ BOOLEAN ] )

This access method control if we should skip includes while parsing the 
template. This can be useful when trying to create template of template - i.e.
when we create a template that when parsed will create other template. 
In this case we can put tags that we do not want to parse in the first pass
in the included templates, and of course, we should skip the includes by 
sending TRUE to this method.
Returns the value of the SKIP_INCLUDES data member.

=item clean_empty_lines( [ BOOLEAN ] ) B<NOT YET IMPLEMENTED>

This access method control if after parsing, empty lines will be cleaned.
This might be useful when creating HTMLs. Empty lines in HTMLs are not 
visible anyway, and can be cleaned. By sending TRUE to this method, we 
can set the object to clean empty lines.
Returns the value of the CLEAN_EMPTY_LINES data member.

=item file_path( [ FILEPATH ] )

The access method to the FILE_PATH data member. By using this method we
can change the path of the template that we are going to read.
Returns the value of the FILE_PATH data member.

=item directory_list( [ DIRECTORY_LIST ] )

The access method to the DIRECTORY_LIST data member. It holds a comma 
separated list of directories. When using the include tag, and the path of 
the included template is relative, it will be taken first relative to the 
path of the hosted template. If the included template will not be found 
there, it will be checked relative to the directories in the DIRECTORY_LIST.
The DIRECTORY_LIST is populated by default with the current working directory.
Returns the value of the DIRECTORY_LIST.

=back

=head1 EXAMPLE

Here is template1.txt:

 <comment> this comment will not be shown in the final html </comment>
 <comment> the title will be in "title"</comment>
 *** $title ***

 Here two templates will be included:
 <comment> including template with its filepath </comment>
 <include src="template2.txt">

 <comment> 
  including template that its path is in a variable called filepath 
 </comment>
 <include src="$filepath">

 Here we will put some conditions:
 <if condition="condition1">
  condition1 is true
  <if condition="condition2">
   condition2 is true (in condition1)
  </if>
  <if condition="condition3">
   condition3 is true (in condition1)
   <if condition="condition5">
    condition5 is true (in condition3 that in condition1)
   </if>
   <else>
    condition5 is false (in condition3 that in condition1)
   </else>
  </if>
 </if>
 <elsif condition="condition2">
  condition2 is true
 </elsif>
 <if condition="condition4">
  condition4 is true
 </if>
 <elsif condition="condition5">
  condition5 is true
 </elsif>
 <elsif condition="condition6">
  condition6 is true
 </elsif>
 <else>
  condition5,4,6 are false
 </else>

 Here we will put a table where the rows are in a while loop.
 Note that we use $a here, but $a is not defined in the calling script,
 so it stays $a. Only in the last loop of the while we will define $a.
 <while condition="func">
 $i: $a <if condition="condition7"> condition7 is true inside the while 
 loop. </if><else> condition7 is false inside the while loop. </else>
 </while> 

And template2.txt:

 --- start of template2 ---
 <comment> this is a comment in the included template </comment>
 included template 2 is here. Template 2 is inserted into the first 
 template.
 We can put use here all the variables like "$title".
 ---  end of template2  ---

The script:

 use Class::Skin;

 my $i = 777;
 my $title = "Usage of Class::Skin";

 # create new Class::Skin object
 my $skin = new Class::Skin("template1.txt");

 # read the template file 
 $skin->read();

 # parse the template and print the result. we send in anonymous 
 # hash all the variables that we would like to use in the template
 print $skin->parse({ title => $title,
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


The result:

 *** Usage of Class::Skin ***

 Here two templates will be included:

 --- start of template2 ---

 included template 2 is here. Template 2 is inserted into the first 
 template.
 We can put use here all the variables like "Usage of Class::Skin".
 ---  end of template2  ---
 --- start of template2 ---

 included template 2 is here. Template 2 is inserted into the first 
 template.
 We can put use here all the variables like "Usage of Class::Skin".
 ---  end of template2  ---

 Here we will put some conditions:

  condition1 is true
   condition3 is true (in condition1)
    condition5 is true (in condition3 that in condition1)
  condition5 is true
 Here we will put a table where the rows are in a while loop.
 Note that we use $a here, but $a is not defined in the calling script, 
 so it stays $a. Only in the last loop of the while we will define $a.

 778: $a  condition7 is true inside the while loop.  

 779: $a  condition7 is true inside the while loop. 

 780: [this is a]  condition7 is true inside the while loop. 



=head1 AUTHOR

Rani Pinchuk, rani@cpan.org

=head1 COPYRIGHT

Copyright (c) 2002 Ockham Technology N.V. & Rani Pinchuk. 
All rights reserved.  
This package is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Log::NullLogLite(3)>,
L<Log::LogLite(3)>


