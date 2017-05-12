package Business::Intelligence::MicroStrategy::CommandManager;
use Carp;

use warnings;
use strict;

=head1 NAME

Business::Intelligence::MicroStrategy::CommandManager - The MicroStrategy Command Manager module

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

use Business::Intelligence::MicroStrategy::CommandManager;

my $foo = Business::Intelligence::MicroStrategy::CommandManager->new();

my $fh;
my $script = "script.scp";
open( $fh, ">", $script ) or die( $?, $! );

print $fh $foo->alter_report(
    REPORT       => "Sample Report",
    LOCATION     => '\Public Objects\Reports',
    ENABLECACHE  => "DEFAULT",
    NEW_NAME     => "Modified Sample Report",
    NEW_LOCATION => '\Public Objects\Reports\Sample Reports',
    HIDDEN       => "FALSE",
    PROJECT      => "MicroStrategy Tutorial"
  ),
  "\n";

$foo->set_connect(
    PROJECTSOURCENAME => "DEV_ISERVER_5",
    USERNAME          => "joe101",
    PASSWORD          => "abc123"
);

$foo->set_inputfile($script);
$foo->set_break;
$foo->run_script;

=head1 EXPORT

Nothing exported by default.

=head1 DESCRIPTION

Use this module to create or execute MicroStrategy Command Manager scripts.  Every Command Manager command is represented in this module.  The syntax is for MicroStrategy Command Manager version 8.1.1 Hotfix 3.  The documentation for every method includes the 8.1.1 HF3 Command Manager syntax for the command.  If you are using a different version of Command Manager, please verify that your version's syntax matches the 8.1.1 HF3 syntax.  The standard installation for Command Manager is C:\Program Files\MicroStrategy\Administrator\Command Manager.  There is an Outlines folder in this directory.  Within the Outlines folder, there is a file that corresponds to each Command Manager command.  This file shows the correct syntax for your installed version of Command Manager.  
  
=cut

=head1 LISTS OF MICROSTRATEGY OBJECTS USED IN COMMAND MANAGER SCRIPTS

=head2 List of Configuration Object Types

DBINSTANCE, DBCONNECTION, DBLOGIN, SCHEDULE, USER, GROUP, EVENT

=cut

=head2 List of Project Object Types

REPORT, DOCUMENT, PROMPT, SECFILTER, CONSOLIDATION, CUSTOMGROUP, DRILLMAP, FILTER, METRIC, SEARCH, TEMPLATE, FACT, HIERARCHY, ATTRIBUTE, FUNCTION, PARTITION, TABLE, TRANSFORMATION, SUBTOTAL, AUTOSTYLE

=cut

=head2 List of Special Object Types

FOLDER

=cut

=head2 List of Access Rights

VIEW, MODIFY, FULLCONTROL, DENIEDALL, DEFAULT, CUSTOM

=cut

=head2 List of Custom Access Rights

BROWSE, READ, WRITE, DELETE, CONTROL, USE, EXECUTE

{ 	BROWSE => "GRANT" | "DENY", 
	READ => "GRANT" | "DENY",
	WRITE => "GRANT" | "DENY",
	DELETE => "GRANT" | "DENY",
	CONTROL => "GRANT" | "DENY",
	USE  => "GRANT" | "DENY",
	EXECUTE => "GRANT" | "DENY",
};

=cut

=head2 List of Form Types

NUMBER, TEXT, DATETIME, DATE, TIME, URL, EMAIL, HTML, PICTURE, BIGDECIMAL 

=cut

=head1 FUNCTIONS

=head2 new

Instantiates new object.

example:
my $foo = Business::Intelligence::MicroStrategy::CommandManager->new;

=cut

sub new {
	my $class = shift;
	my $self = {};
	bless ($self, $class);
	$self->{CMDMGR_EXE} =  "C:\\PROGRA~1\\MicroStrategy\\Administrator\\Comman~1\\CMDMGR.exe";
	return $self;
}


my $q = '"';

=head2 set_cmdmgr_exe

Set location of command manager executable.

$foo->set_cmdmgr_exe("path_to_executable");

=cut

sub set_cmdmgr_exe {
	my $self = shift;
	$self->{CMDMGR_EXE} = shift;
	if(!defined($self->{CMDMGR_EXE})) { croak("Required parameter not defined: CMDMGR_EXE\n"); }
}

=head2 get_cmdmgr_exe

Get location of command manager executable.

$foo->get_cmdmgr_exe;

=cut

sub get_cmdmgr_exe {
	my $self = shift;
	return $self->{CMDMGR_EXE};
}

=head2 set_connect

Sets the project source name, the user name, and the password

	$foo->set_connect(
	    PROJECTSOURCENAME => "project_source_name", 
	    USERNAME          => "userid", 
	    PASSWORD          => "password"
	);

=cut

sub set_connect { 
	my $self = shift;
	my %parms = @_;
	$self->{PROJECTSOURCENAME} = "-n " . $parms{PROJECTSOURCENAME};
	$self->{USERNAME} = "-u " . $parms{USERNAME};
	$self->{PASSWORD} = "-p " . $parms{PASSWORD};
	for(qw(PROJECTSOURCENAME USERNAME PASSWORD)){
		if(!defined($self->{$_})) { croak("Required parameter not defined: " , $_, "\n"); }
	}
}


=head2 set_project_source_name

Sets the project source name

$foo->set_project_source_name("project_source_name");

=cut

sub set_project_source_name { 
	my $self = shift;
	$self->{PROJECTSOURCENAME} = "-n " . shift;
	if(!defined($self->{PROJECTSOURCENAME})) { croak("Required parameter not defined: PROJECTSOURCENAME\n"); }
}

=head2 get_project_source_name

Gets the project source name

$foo->get_project_source_name;

=cut

sub get_project_source_name { 
	my $self = shift;
	return $self->{PROJECTSOURCENAME};
}

=head2 set_user_name

sets the user name to be used in authenticating the command manager script

$foo->set_user_name("user_name");

=cut

sub set_user_name { 
	my $self = shift;
	$self->{USERNAME} = "-u " . shift;
	if(!defined($self->{USERNAME})) { croak("Required parameter not defined: USERNAME\n"); }
}

=head2 get_user_name

$foo->get_user_name;

=cut

sub get_user_name { 
	my $self = shift;
	return $self->{USERNAME};
}

=head2 set_password

Set password

Password = Provides the password for the username. 

$foo->set_password("foobar");

=cut

sub set_password { 
	my $self = shift;
	$self->{PASSWORD} = "-p " . shift;
	if(!defined($self->{PASSWORD})) { croak("Required parameter not defined: PASSWORD\n"); }
}

=head2 get_password

Get password

$foo->get_password;

=cut

sub get_password { 
	my $self = shift;
	return $self->{PASSWORD};
}

=head2 get_connect

Get ProjectSourceName, Username, Password

$foo->get_connect;

=cut

sub get_connect {
	my $self = shift;
	return $self->{PROJECTSOURCENAME}, $self->{USERNAME}, $self->{PASSWORD};
}

=head2 set_inputfile

Inputfile = Identifies the name, and the full path if necessary, of the script file (.scp) to be executed. 

If this argument is omitted, the Command Manager GUI will be launched.  Probably not the behaviour you want from your script.  In almost all cases, you should set this.

$foo->set_inputfile("input_file");

=cut

sub set_inputfile { 
	my $self = shift;
	$self->{INPUTFILE} = "-f " . shift;
	if(!defined($self->{INPUTFILE})) { croak("Required parameter not defined: INPUTFILE\n"); }
}

=head2 get_inputfile

Inputfile = Identifies the name, and the full path if necessary, of the script file (.scp) to be executed. 

gets the input file

$foo->get_inputfile;

=cut

sub get_inputfile {
	my $self = shift;
	return $self->{INPUTFILE};
}

=head2 set_outputfile

Outputfile = Logs results, status messages, and error messages associated with the script. 

Use of the output file switch precludes use of break switch and the results file switch.

$foo->set_outputfile("output_file");

=cut

sub set_outputfile {
	my $self = shift;
	$self->{OUTPUTFILE} = "-o " . shift;
	if(!defined($self->{OUTPUTFILE})) { croak("Required parameter not defined: OUTPUTFILE\n"); }
}

=head2 get_outputfile

Outputfile = Logs results, status messages, and error messages associated with the script. 

Use of the output file switch precludes use of break switch and the results file switch.

$foo->get_outputfile;

=cut

sub get_outputfile {
	my $self = shift;
	return $self->{OUTPUTFILE};
}

=head2 set_resultsfile

RESULTSFILE = Results log file name. Use of the results file precludes use of output file switch and the break switch.

FAILFILE = Error log file name. You may only use the fail file with results file switch.  

SUCCESSFILE = Success log file name. You may only use success file with the results file switch.

	$foo->set_resultsfile(
	    RESULTSFILE => "results file",
	    FAILFILE    => "fail file",
	    SUCCESSFILE => "success file"
	);

=cut

sub set_resultsfile {
	my $self = shift;
	my %parms = @_;
	$self->{RESULTSFILE} = "-or " . $parms{RESULTSFILE};
	$self->{FAILFILE} = "-of " . $parms{FAILFILE};
       	$self->{SUCCESSFILE} = "-os " . $parms{SUCCESSFILE};
	for(qw(RESULTSFILE FAILFILE SUCCESSFILE)){
		if(!defined($self->{$_})) { croak("Required parameter not defined: " , $_, "\n"); }
	}
}
       
=head2 get_resultsfile

$foo->get_resultsfile;

=cut

sub get_resultsfile {
	my $self = shift;
	return $self->{RESULTSFILE}, $self->{FAILFILE}, $self->{SUCCESSFILE};
}
	
=head2 set_instructions

Displays instructions in the console and in the log files.

$foo->set_instructions;

=cut

sub set_instructions {
	my $self = shift;
	$self->{INSTRUCTIONS} = "-i ";
	if(!defined($self->{INSTRUCTIONS})) { croak("Required parameter not defined: INSTRUCTIONS\n"); }
}

=head2 set_header

Displays header in the log files.

$foo->set_header;

=cut

sub set_header {
	my $self = shift;
	$self->{HEADER} = "-h ";
	if(!defined($self->{HEADER})) { croak("Required parameter not defined: HEADER\n"); }
}

=head2 set_showoutput

Displays output on the console.

$foo->set_showoutput;

=cut

sub set_showoutput {
	my $self = shift;
	$self->{SHOWOUTPUT} = "-showoutput ";
	if(!defined($self->{SHOWOUTPUT})) { croak("Required parameter not defined: SHOWOUTPUT\n"); }
}

=head2 set_stoponerror

Stops the execution on error.

$foo->set_stoponerror;

=cut

sub set_stoponerror {
	my $self = shift;
	$self->{STOPONERROR} = "-stoponerror ";
	if(!defined($self->{STOPONERROR})) { croak("Required parameter not defined: STOPONERROR\n"); }
}

=head2 set_skipsyntaxcheck

Skips instruction syntax checking on a script prior to execution.

$foo->set_skipsyntaxcheck;

=cut

sub set_skipsyntaxcheck {
	my $self = shift;
	$self->{SKIPSYNTAXCHECK} = "-skipsyntaxcheck ";
	if(!defined($self->{SKIPSYNTAXCHECK})) { croak("Required parameter not defined: SKIPSYNTAXCHECK\n"); }
}

=head2 set_error

Displays error and exit codes on the console and in the log file.

$foo->set_error;

=cut

sub set_error {
	my $self = shift;
	$self->{ERROR} = "-e ";
	if(!defined($self->{ERROR})) { croak("Required parameter not defined: ERROR\n"); }
}

=head2 set_break

break = Separates the output into three files with the following default file names: CmdMgrSuccess.log, CmdMgrFail.log, and CmdMgrResults.log. Use of the -break switch precludes use of -o and -or, -of, and -os.

$foo->set_break;

=cut

sub set_break {
	my $self = shift;
	$self->{BREAK} = "-break ";
	if(!defined($self->{BREAK})) { croak("Required parameter not defined: BREAK\n"); }
}


=head2 display

Displays the contents of a Business::Intelligence::MicroStrategy::Cmdmgr object. 

=cut

sub display {
	my $self = shift;
        my @keys = @_ ? @_ : sort keys %$self;
        for my $key (@keys) {
            print "\t$key => $self->{$key}\n";
        }
}

=head2 run_script

Executes command manager script.

$foo->run_script;

=cut

sub run_script {
        my $self = shift;
	my $args;
	for my $req(qw(CMDMGR_EXE PROJECTSOURCENAME USERNAME PASSWORD)) {
		if($self->{$req}) { $args .= " " . $self->{$req}; } else { croak("Required parameter not set: $req\n"); }
	}
	for my $option(qw(INPUTFILE OUTPUTFILE BREAK RESULTSFILE FAILFILE SUCCESSFILE INSTRUCTIONS HEADER SHOWOUTPUT
		STOPONERROR SKIPSYNTAXCHECK ERROR)) {
		if($self->{$option}) { $args .= " " . $self->{$option}; } 
	}
	system($args)==0 or carp("Command Manager script returned an error:\n");  
};



=head2 custom_access_rights

internal use only

=cut

sub custom_access_rights {
	my $access_rights = shift;
	my $result;
	my ($grant, $deny, $default);
	for my $acc_right (sort keys %$access_rights) {
		if($access_rights->{$acc_right} =~ /GRANT/i) { 
			$grant .= " " . $acc_right . ","; 
			next;
		}
		if($access_rights->{$acc_right} =~ /DENY/i) { 
			$deny .= " " . $acc_right . ","; 
			next;
		}
		$default .= " " . $acc_right . ",";
	}
	my @strings;
	if($grant) {
		chop($grant);
		$grant = "GRANT" . $grant;
		push @strings, $grant;
	}
	if($deny) {
		chop($deny);
		$deny =  "DENY" . $deny;
		push @strings, $deny;
	}
	if($default) {
		chop($default);
		$default =  "DEFAULT" . $default;
		push @strings, $default;
	}
	$result = join(" ", @strings);
	return $result;
}

=head2 join_objects

internal use only

=cut

sub join_objects { 
	my ($self, $key, $exp) = @_;
	my ($tmp, $cnt, $size);
	$size = @{$self->{$key}};	
	for (@{$self->{$key}}) {
		$cnt++;
		$tmp .= $q . $_ . $q; 
		if($cnt == $size) { last; }
		$tmp .= ", ";
	}
	return $exp . " " . $tmp . " ";
};


=head2 add_attribute_child

$foo->add_attribute_child(
    ATTRIBUTECHILD   => "attributechild_name",
    RELATIONSHIPTYPE => "ONETOONE" | "ONETOMANY" | "MANYTOMANY",
    ATTRIBUTE        => "attribute_name",
    LOCATION         => "location_path",
    PROJECT          => "project_name"
);

ADD ATTRIBUTECHILD "<attributechild_name>" RELATIONSHIPTYPE (ONETOONE | ONETOMANY | MANYTOMANY) TO ATTRIBUTE "<attribute_name>" IN FOLDER "<location_path>" FOR PROJECT "<project_name>";

ADD ATTRIBUTECHILD "Day" RELATIONSHIPTYPE ONETOMANY TO ATTRIBUTE "Month" IN FOLDER "\Schema Objects\Attributes" FOR PROJECT "MicroStrategy Tutorial";

$foo->add_attribute_child(	
	ATTRIBUTECHILD 		=> "Day", 
	RELATIONSHIPTYPE 	=> "ONETOMANY", 
	ATTRIBUTE 		=> "Month", 
	LOCATION 		=> "\\Schema Objects\\Attributes", 
	PROJECT 		=> "MicroStrategy Tutorial"
);

=cut

sub add_attribute_child {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(ATTRIBUTECHILD RELATIONSHIPTYPE ATTRIBUTE LOCATION PROJECT);
my @required = qw(ATTRIBUTECHILD RELATIONSHIPTYPE ATTRIBUTE LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/ATTRIBUTECHILD$/ && do { $result .= "ADD ATTRIBUTECHILD " . $q . $self->{ATTRIBUTECHILD} . $q . " " ;};
	/RELATIONSHIPTYPE/ && do { $result .= "RELATIONSHIPTYPE " . $self->{RELATIONSHIPTYPE} . " ";};
	/ATTRIBUTE$/ && do { $result .= "TO ATTRIBUTE " . $q . $self->{ATTRIBUTE} . $q . " "; };
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "; };
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"; };
}

return $result;
}

=head2 add_attribute_form_expression

$foo->add_attribute_form_expression(	
	ATTRIBUTEFORMEXP   => "expression", 
	EXPSOURCETABLES    => ["sourcetable1", "sourcetable2", sourcetableN"], 
	LOOKUPTABLE 	   => "lookup_table", 
	OVERWRITE 	   => "TRUE" | "FALSE", 
	ATTRIBUTEFORM	   => "form_name", 
	ATTRIBUTE 	   => "attribute_name", 
	LOCATION	   => "location_path", 
	PROJECT 	   => "project_name"
);

Optional parameters: 	
	EXPSOURCETABLES => [ "<sourcetable1>" , "<sourcetable2>" , "<sourcetableN>"], 
	LOOKUPTABLE => "<lookup_table>", 
	OVERWRITE => "TRUE" | "FALSE"				  

ADD ATTRIBUTEFORMEXP "<expression>" [EXPSOURCETABLES "<sourcetable1>" [, "<sourcetable2>" [, "<sourcetableN>"]]] [LOOKUPTABLE "<lookup_table>"] [OVERWRITE] TO ATTRIBUTEFORM "<form_name>" FOR ATTRIBUTE "<attribute_name>" IN FOLDER "<location_path>" FOR PROJECT "<project_name>";


ADD ATTRIBUTEFORMEXP "ORDER_DATE" TO ATTRIBUTEFORM "ID" FOR ATTRIBUTE "Day" IN FOLDER "\Schema Objects\Attributes" FOR PROJECT "MicroStrategy Tutorial";

$foo->add_attribute_form_expression(	
	ATTRIBUTEFORMEXP => "ORDER_DATE", 
	ATTRIBUTEFORM 	 => "ID", ATTRIBUTE => "Day", 
	LOCATION         => "\\Schema Objects\\Attributes", 
	PROJECT          => "MicroStrategy Tutorial"
				   
);

=cut

sub add_attribute_form_expression {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(ATTRIBUTEFORMEXP EXPSOURCETABLES LOOKUPTABLE OVERWRITE ATTRIBUTEFORM ATTRIBUTE LOCATION PROJECT);
my @required = qw(ATTRIBUTEFORMEXP ATTRIBUTEFORM ATTRIBUTE LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/ATTRIBUTEFORMEXP$/ && do { $result .= "ADD ATTRIBUTEFORMEXP " . $q . $self->{ATTRIBUTEFORMEXP} . $q . " "};
	/EXPSOURCETABLES/ && do { $result .= $self->join_objects($_, $_); };
	/LOOKUPTABLE/ && do { $result .= "LOOKUPTABLE " . $q . $self->{LOOKUPTABLE} . $q . " "};
	/OVERWRITE/ && do { if($self->{OVERWRITE} =~ /(F|0)/i) { next; }  $result .=  "OVERWRITE "};
	/ATTRIBUTEFORM$/ && do { $result .= "TO ATTRIBUTEFORM " . $q . $self->{ATTRIBUTEFORM} . $q . " "};
	/ATTRIBUTE$/ && do { $result .= "FOR ATTRIBUTE " . $q . $self->{ATTRIBUTE} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 add_attribute_form

ADD ATTRIBUTEFORM "<form_name>" [FORMDESC "<form_description>"] FORMCATEGORY "<category_name>" FORMTYPE (NUMBER | TEXT | DATETIME | DATE | TIME | URL | EMAIL | HTML | PICTURE | BIGDECIMAL) [SORT (NONE | ASC | DESC)] EXPRESSION "<form_expression>" [EXPSOURCETABLES "<sourcetable1>" [, "<sourcetable2>" [, ... "<sourcetableN>"]]] LOOKUPTABLE "<lookup_table>" TO ATTRIBUTE "<attribute_name>" IN FOLDER "<location_path>" FOR PROJECT "<project_name>";

$foo->add_attribute_form(	
	ATTRIBUTEFORM   => "form_name", 
	FORMDESC        => "form_description", 
	FORMCATEGORY    => "category_name", 
	FORMTYPE        => "formtype", 
	SORT            => (NONE | ASC | DESC), 
	EXPRESSION      => "form_expression", 
	EXPSOURCETABLES =>  ["sourcetable1", "sourcetable2", "sourcetableN"], 
	LOOKUPTABLE     => "lookup_table", 
	ATTRIBUTE       => "attribute_name", 
	LOCATION        => "location_path", 
	PROJECT         => "project_name"
);

Optional parameters: 
	FORMDESC => "<form_description>", 
	SORT => (NONE | ASC | DESC), 
	EXPSOURCETABLES => ["<sourcetable1>" , "<sourcetable2>" , "<sourcetableN>"]

ADD ATTRIBUTEFORM "Last Name" FORMDESC "Last Name Form" FORMCATEGORY "DESC" FORMTYPE TEXT SORT DESC EXPRESSION "[CUST_LAST_NAME]" LOOKUPTABLE "LU_CUSTOMER" TO ATTRIBUTE "Customer" IN FOLDER "\Schema Objects\Attributes" FOR PROJECT "MicroStrategy Tutorial";

$foo->add_attribute_form(
	ATTRIBUTEFORM => "Last Name", 
	FORMDESC      => "Last Name Form", 
	FORMCATEGORY  => "DESC", 
	FORMTYPE      => "TEXT", 
	SORT          => "DESC", 
	EXPRESSION    => "[CUST_LAST_NAME]", 
	LOOKUPTABLE   => "LU_CUSTOMER", 
	ATTRIBUTE     => "Customer", 
	LOCATION      => "\\Schema Objects\\Attributes", 
	PROJECT       => "MicroStrategy Tutorial"
);

=cut

sub add_attribute_form {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(ATTRIBUTEFORM FORMDESC FORMCATEGORY FORMTYPE SORT EXPRESSION EXPSOURCETABLES LOOKUPTABLE ATTRIBUTE LOCATION PROJECT);
my @required = qw(ATTRIBUTEFORM FORMCATEGORY FORMTYPE EXPRESSION LOOKUPTABLE ATTRIBUTE LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/ATTRIBUTEFORM$/ && do { $result .= "ADD ATTRIBUTEFORM " . $q . $self->{ATTRIBUTEFORM} . $q . " "};
	/FORMDESC/ && do { $result .= "FORMDESC " . $q . $self->{FORMDESC} . $q . " "};
	/FORMCATEGORY/ && do { $result .= "FORMCATEGORY " . $q . $self->{FORMCATEGORY} . $q . " "};
	/FORMTYPE/ && do { $result .= "FORMTYPE " . $self->{FORMTYPE} . " "};
	/SORT/ && do { $result .= "SORT " . $self->{SORT} . " "};
	/EXPRESSION/ && do { $result .= "EXPRESSION " . $q . $self->{EXPRESSION} . $q . " "};
	/EXPSOURCETABLES/ && do { $result .= $self->join_objects($_, $_); };
	/LOOKUPTABLE/ && do { $result .= "LOOKUPTABLE " . $q . $self->{LOOKUPTABLE} . $q . " "};
	/ATTRIBUTE$/ && do { $result .= "TO ATTRIBUTE " . $q . $self->{ATTRIBUTE} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 add_attribute_parent

ADD ATTRIBUTEPARENT "<attributeparent_name>" RELATIONSHIPTYPE (ONETOONE | MANYTOONE | MANYTOMANY) TO ATTRIBUTE "<attribute_name>" IN FOLDER "<location_path>" FOR PROJECT "<project_name>";

$foo->add_attribute_parent(	
	ATTRIBUTEPARENT   => "attributeparent_name", 
	RELATIONSHIPTYPE  => "ONETOONE" | "MANYTOONE" | "MANYTOMANY", 
	ATTRIBUTE         => "attribute_name", 
	LOCATION          => "location_path", 
	PROJECT           => "project_name"
);

ADD ATTRIBUTEPARENT "Month of Year" RELATIONSHIPTYPE MANYTOONE TO ATTRIBUTE "Month" IN FOLDER "\Schema Objects\Attributes" FOR PROJECT "MicroStrategy Tutorial";

$foo->add_attribute_parent(	
	ATTRIBUTEPARENT => "Month of Year", 
	RELATIONSHIPTYPE => "MANYTOONE", 
	ATTRIBUTE => "Mont", 
	LOCATION => '\Schema Objects\Attributes', 
	PROJECT => "MicroStrategy Tutorial"
);

=cut

sub add_attribute_parent {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(ATTRIBUTEPARENT RELATIONSHIPTYPE ATTRIBUTE LOCATION PROJECT);
my @required = qw(ATTRIBUTEPARENT RELATIONSHIPTYPE ATTRIBUTE LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/ATTRIBUTEPARENT$/ && do { $result .= "ADD ATTRIBUTEPARENT " . $q . $self->{ATTRIBUTEPARENT} . $q . " "};
	/RELATIONSHIPTYPE/ && do { $result .= "RELATIONSHIPTYPE " . $self->{RELATIONSHIPTYPE} . " "};
	/ATTRIBUTE$/ && do { $result .= "TO ATTRIBUTE " . $q . $self->{ATTRIBUTE} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 add_configuration_ace

ADD ACE FOR conf_object_type "<object_name>" (USER | GROUP) "<user_login_or_group_name>" ACCESSRIGHTS (VIEW | MODIFY | FULLCONTROL | DENIEDALL | DEFAULT | CUSTOM [GRANT <accessright1> [, <accessright2> [,... <accessrightN>]] [DENY <accessright1> [, <accessright2> [,... <accessrightN>]]]);

$foo->add_configuration_ace(	
	CONF_OBJECT_TYPE => "conf_object_type", 
	OBJECT_NAME => "object_name", 
	USER_OR_GROUP => (USER | GROUP), 
	USER_LOGIN_OR_GROUP_NAME => "user_login_or_group_name", 
	ACCESSRIGHTS => (VIEW | MODIFY | FULLCONTROL | DENIEDALL | DEFAULT | CUSTOM ), 
	ACCESSRIGHTS_CUSTOM => { 
				BROWSE  => "GRANT" | "DENY", 
				READ    => "GRANT" | "DENY",
				WRITE   => "GRANT" | "DENY",
				DELETE  => "GRANT" | "DENY",
				CONTROL => "GRANT" | "DENY",
				USE     => "GRANT" | "DENY",
				EXECUTE => "GRANT" | "DENY",
			       }
);

Optional parameters: 
ACCESSRIGHTS_CUSTOM 

ADD ACE FOR SCHEDULE "All the time" USER "Developer" ACCESSRIGHTS FULLCONTROL;

$foo->add_configuration_ace(	
	CONF_OBJECT_TYPE         => "SCHEDULE", 
	OBJECT_NAME              => "All the time", 
	USER_OR_GROUP            => "USER", 
	USER_LOGIN_OR_GROUP_NAME => "Developer", 
	ACCESSRIGHTS             => "FULLCONTROL"
);

ADD ACE FOR SCHEDULE "All the time" USER "Developer" ACCESSRIGHTS DENIEDALL;

$foo->add_configuration_ace(
	CONF_OBJECT_TYPE         => "SCHEDULE", 
	OBJECT_NAME              => "All the time", 
	USER_OR_GROUP            => "USER", 
	USER_LOGIN_OR_GROUP_NAME => "Developer", 
	ACCESSRIGHTS             => "DENIEDALL"
);

ADD ACE FOR GROUP "Developers" GROUP "Web Users" ACCESSRIGHTS DENIEDALL;

$foo->add_configuration_ace(	
	CONF_OBJECT_TYPE         => "GROUP", 
	OBJECT_NAME              => "Developers", 
	USER_OR_GROUP            => "GROUP", 
	USER_LOGIN_OR_GROUP_NAME => "Web Users", 
	ACCESSRIGHTS             => "DENIEDALL"
);

ADD ACE FOR SCHEDULE "All the time" USER "Developers" ACCESSRIGHTS CUSTOM GRANT BROWSE, READ, WRITE DENY DELETE, CONTROL, USE, EXECUTE;

$foo->add_configuration_ace(	
	CONF_OBJECT_TYPE         => "SCHEDULE", 
	OBJECT_NAME              => "All the time", 
	USER_OR_GROUP            => "USER", 
	USER_LOGIN_OR_GROUP_NAME => "Developers", 
	ACCESSRIGHTS             => "CUSTOM", 
	ACCESSRIGHTS_CUSTOM =>	{ 
		BROWSE   => "GRANT", 
		READ     => "GRANT", 
		WRITE    => "GRANT", 
		DELETE   => "DENY", 
		CONTROL  => "DENY", 
		USE      => "DENY", 
		EXECUTE  => "DENY"
	}
);

=cut

sub add_configuration_ace {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(CONF_OBJECT_TYPE OBJECT_NAME USER_OR_GROUP USER_LOGIN_OR_GROUP_NAME ACCESSRIGHTS ACCESSRIGHTS_CUSTOM);
my @required = qw(CONF_OBJECT_TYPE OBJECT_NAME USER_OR_GROUP USER_LOGIN_OR_GROUP_NAME ACCESSRIGHTS);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/CONF_OBJECT_TYPE/ && do { $result .= "ADD ACE FOR " . $self->{CONF_OBJECT_TYPE} . " "};
	/OBJECT_NAME/ && do { $result .=  $q . $self->{OBJECT_NAME} . $q . " "};
	/USER_OR_GROUP/ && do { $result .= $self->{USER_OR_GROUP} . " "};
	/USER_LOGIN_OR_GROUP_NAME/ && do { $result .= $q . $self->{USER_LOGIN_OR_GROUP_NAME} . $q . " "};
	/ACCESSRIGHTS$/ && do { $result .= "ACCESSRIGHTS " . $self->{ACCESSRIGHTS} . " " };
	/ACCESSRIGHTS_CUSTOM$/ && do { $result .= custom_access_rights($self->{ACCESSRIGHTS_CUSTOM}) };
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 add_custom_group_element

ADD ELEMENT "<element_name>" [(SHOWELEMENTNAME  | SHOWITEMSINELEMENT | SHOWITEMSINELEMENTANDEXPAND | SHOWALLANDEXPAND)] EXPRESSION "<expression>" [BREAKAMBIGUITY FOLDER "<local_symbol_folder>" ] [BANDNAMES "<name1>", "<name2>", "<nameN>"] [OUTPUTLEVEL "<attribute_name1>", "<attribute_name2>", "<attributenameN>"  IN FOLDERS "<outputlevel_location_path1>", "<outputlevel_location_path2>", "<outputlevel_location_pathN>"] TO CUSTOMGROUP "<customgroup_name>" IN FOLDER "<location_path>" FOR PROJECT "<project_name>";

$foo->add_custom_group_element(	
	ELEMENT                     => "element_name", 
	SHOWELEMENTNAME             => "TRUE" | "FALSE", 
	SHOWITEMSINELEMENT          => "TRUE" | "FALSE", 
	SHOWITEMSINELEMENTANDEXPAND => "TRUE" | "FALSE", 
	SHOWALLANDEXPAND            => "TRUE" | "FALSE", 
	EXPRESSION                  => "expression", 
	BREAKAMBIGUITY_FOLDER       => "local_symbol_folder", 
	BANDNAMES                   => ["name1", "nameN"], 
	OUTPUTLEVEL                 => ["attribute_name1", "attributenameN"], 
	LOCATIONS                   => [ "outputlevel_location_path1", "outputlevel_location_pathN"], 
	CUSTOMGROUP                 => "customgroup_name", 
	LOCATION                    => "location_path", 
	PROJECT                     => "project_name"
);

Optional parameters: SHOWELEMENTNAME => TRUE | FALSE, SHOWITEMSINELEMENT => TRUE | FALSE, SHOWITEMSINELEMENTANDEXPAND => TRUE | FALSE, SHOWALLANDEXPAND  => TRUE | FALSE, BREAKAMBIGUITY_FOLDER => "local_symbol_folder", BANDNAMES => ["name1", "nameN"], OUTPUTLEVEL => ["attribute_name1", "attributenameN"], OUTPUTLEVEL_LOCATIONS => [ "outputlevel_location_path1", "outputlevel_location_pathN"])

ADD ELEMENT "25-35" EXPRESSION "([Customer Age]@ID Between 25.0 And 35.0)" TO CUSTOMGROUP "Copy of Age Groups" IN FOLDER "\Public Objects\Custom Groups" FOR PROJECT "MicroStrategy Tutorial";

$foo->add_custom_group_element(	
	ELEMENT     => "25-35", 
	EXPRESSION  => '([Customer Age]@ID Between 25.0 And 35.0)', 
	CUSTOMGROUP => "Copy of Age Groups", 
	LOCATION    => "\\Public Objects\\Custom Groups", 
	PROJECT     => "MicroStrategy Tutorial"
);

ADD ELEMENT "36-45" SHOWELEMENTNAME EXPRESSION "([Customer Age]@ID Between 36.0 And 45.0)" BANDNAMES "Group1", "Group2" TO CUSTOMGROUP "Copy of Age Groups" IN FOLDER "\Public Objects\Custom Groups" FOR PROJECT "MicroStrategy Tutorial";

$foo->add_custom_group_element(	
	ELEMENT         => "36-45", 
	SHOWELEMENTNAME => "TRUE" , 
	EXPRESSION      => '([Customer Age]@ID Between 36.0 And 45.0)', 
	BANDNAMES       => ["Group1", "Group2"], 
	CUSTOMGROUP     => "Copy of Age Groups", 
	LOCATION        => "\\Public Objects\\Custom Groups", 
	PROJECT         => "MicroStrategy Tutorial"
);

Following is how to create different types of custom groups using expression text.
Notes:
[] are used to define a name of an object; the name can include the full path to the object.
^ is used as the escape character to specify a string constant inside an expression.
{} are used to indicate a pair of join element list qualification.
When it comes to ambiguous objects within an expression, there are two ways to solve it:
	a. To specify the object with its full path
	b. Place all of the ambiguous objects in a single folder and specify this folder in the command using the BREAKAMBIGUITY reserved word.
When specifying the percentage value using Rank<ByValue=False>, please specify a fraction value between 0 and 1 that corresponds to the percentage value. For example, forty percent (40%) should be specified as 0.4.
Examples of different qualitications:
1. Attribute qualification:
	[\Schema Objects\Attributes\Time\Year]@ID IN ("2003, 2004")
	[\Schema Objects\Attributes\Time\Year]@ID =2003
	[\Schema Objects\Attributes\Products\Category]@DESC IN ("Books", "Movies", "Music", "Electronics")
2. Set Qualification
	For Metric Qualifications, you need to specify the output level at which this metric is calculated.
	Three types of functions: 
		Metric Values: [\Public Objects\Metrics\Sales Metrics\Profit] >= 10
		Bottom Rank: Rank([\Public Objects\Metrics\Sales Metrics\Profit]) <=  3
		Top Rank: Rank<ASC=False>([Revenue Contribution to All Products Abs.]) <= 5
		Percent: Rank<ByValue=False>([\Public Objects\Metrics\Sales Metrics\Profit]) <= 0.1
	*Note for Rank function: There are two parameters that control its behavior. ASC and ByValue.
			         When ASC is set to true, the ranking results are sorted in ascending order; when its value is set to false, the ranking results are sorted in descending order.
			         When ByValue is set to true, the ranking results represent their value order; whereas, when ByValue is set to false, the ranking results represent their percentage order.
3. Shortcut to a Report Qualification
	Just specify the report name:
	[Revenue vs. Forecast] or
	[\Public Objects\Reports\Revenue vs. Forecast]
4. Shortcut to a Filter
	Just specify the filter name:
	[Top 5 Customers by Revenue]
	([\Public Objects\Filters\Top 5 Customers by Revenue])
5. Banding Qualification
	You need to specify the output level. In addition, you may want to specify the band names. 
	Three types of bandings:
		Band Size: Banding(Cost, 1.0, 1000.0, 100.0) 
		Band Point: BandingP(Discount, 1.0, 10.0, 15.0, 20.0)
		Banding Counts: BandingC(Profit, 1.0, 1000.0, 100.0) 
	BandingP(Rank<ByValue=False>([\Public Objects\Metrics\Sales Metrics\Revenue]),0,0.1,0.5,1)
	Banding([Running Revenue Contribution to All Customers Abs.],0.0,1.0,0.2)
6. Advance Qualification
	Join Element List Qualification
	{Year@ID, Category@DESC} IN ({2004, "Books"}, {2005, "Movies"})

=cut

sub add_custom_group_element {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(ELEMENT SHOWELEMENTNAME SHOWITEMSINELEMENT SHOWITEMSINELEMENTANDEXPAND SHOWALLANDEXPAND EXPRESSION BREAKAMBIGUITY_FOLDER BANDNAMES OUTPUTLEVEL OUTPUTLEVEL_LOCATIONS CUSTOMGROUP LOCATION PROJECT);
my @required = qw(ELEMENT EXPRESSION CUSTOMGROUP LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/^ELEMENT$/ && do { $result .= "ADD ELEMENT " . $q . $self->{ELEMENT} . $q . " "};
	/^SHOWELEMENTNAME$/ && do {
		if($self->{SHOWELEMENTNAME} =~ /(F|0)/i) { 
			next; 
		} 
		$result .= "SHOWELEMENTNAME ";  
	};
	/^SHOWITEMSINELEMENT$/ && do { 
		if($self->{SHOWITEMSINELEMENT} =~ /(F|0)/i) { 
			next; 
		} 
		$result .= "SHOWITEMSINELEMENT ";  
	};
	/^SHOWITEMSINELEMENTANDEXPAND$/ && do { 
		if($self->{SHOWITEMSINELEMENTANDEXPAND} =~ /(F|0)/i) { 
			next; 
		} 
		$result .= "SHOWITEMSINELEMENTANDEXPAND ";  
	};
	/SHOWALLANDEXPAND/ && do { 
		if($self->{SHOWALLANDEXPAND} =~ /(F|0)/i) {
			next; 
		} 
		$result .= "SHOWALLANDEXPAND ";  
	};
	/EXPRESSION/ && do { $result .= "EXPRESSION " . $q . $self->{EXPRESSION} . $q . " "};
	/BREAKAMBIGUITY_FOLDER/ && do { $result .= "BREAKAMBIGUITY FOLDER " . $q . $self->{BREAKAMBIGUITY_FOLDER} . $q . " "};
	/BANDNAMES/ && do { $result .= $self->join_objects($_, $_); };
	/^OUTPUTLEVEL$/ && do { $result .= $self->join_objects($_, $_); };
	/^OUTPUTLEVEL_LOCATIONS$/ && do { $result .= $self->join_objects($_, "IN FOLDERS"); };
	/CUSTOMGROUP/ && do { $result .= "TO CUSTOMGROUP " . $q . $self->{CUSTOMGROUP} . $q . " "};
	/^LOCATION$/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 add_dbinstance

ADD DBINSTANCE "<DBInstance_name>" TO PROJECT "<project_name>";

$foo->add_dbinstance(	
	DBINSTANCE => "DBInstance_name", 
	PROJECT    => "project_name"
);

ADD DBINSTANCE "Extra Tutorial Data" TO PROJECT "MicroStrategy Tutorial";

$foo->add_dbinstance(	
	DBINSTANCE => "Extra Tutorial Data", 
	PROJECT    => "MicroStrategy Tutorial"
);

=cut

sub add_dbinstance {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(DBINSTANCE PROJECT);
my @required = qw(DBINSTANCE PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/DBINSTANCE/ && do { $result .= "ADD DBINSTANCE " . $q . $self->{DBINSTANCE} . $q . " "};
	/PROJECT/ && do { $result .= "TO PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 add_fact_expression

$foo->add_fact_expression(	
	EXPRESSION      => "expression", 
	EXPSOURCETABLES => ["sourcetable1", "sourcetableN"], 
	OVERWRITE       => "TRUE" | "FALSE", 
	FACT            => "fact_name", 
	LOCATION        => "location_path", 
	PROJECT         => "project_name"
);

Optional parameters: EXPSOURCETABLES => ["<sourcetable1>", "<sourcetable2>" , "<sourcetableN>"], OVERWRITE => (TRUE | FALSE)

ADD EXPRESSION "<expression>" [EXPSOURCETABLES "<sourcetable1>", [, "<sourcetable2>" [, "<sourcetableN>"]]] [OVERWRITE] TO FACT "<fact_name>" IN FOLDER "<location_path>" FOR PROJECT "<project_name>";

Specify EXPSOURCETABLES and the table names for manual mapping. If EXPSOURCETABLES is not used, the expression is mapped automatically.
	If one or more candidate tables of this expression are already used by another expression, specify OVERWRITE to map the overlapping tables with this expression. When OVERWRITE is not used, Command Manager only maps those tables that are not overlapping.
/* Fact Profit*/
ADD EXPRESSION "([QTY_SOLD] * (([UNIT_PRICE] - DISCOUNT) - [UNIT_COST]))" EXPSOURCETABLES "ORDER_DETAIL" TO FACT "Profit" IN FOLDER "\Public Objects" FOR PROJECT "Microstrategy Tutorial";

$foo->add_fact_expression(	
	EXPRESSION      => '([QTY_SOLD] * (([UNIT_PRICE] - DISCOUNT) - [UNIT_COST]))', 
	EXPSOURCETABLES => ["ORDER_DETAIL"], 
	FACT            => "Profit", 
	LOCATION        => "\\Public Objects", 
	PROJECT         => "MicroStrategy Tutorial"
);

ADD EXPRESSION "ORDER_AMT - ORDER_COST" TO FACT "Profit" IN FOLDER "\Public Objects" FOR PROJECT "MicroStrategy Tutorial";

$foo->add_fact_expression(	
	EXPRESSION => 'ORDER_AMT - ORDER_COST', 
	FACT       => "Profit", 
	LOCATION   => "\\Public Objects", 
	PROJECT    => "MicroStrategy Tutorial"
);

ADD EXPRESSION "ORDER_ID" EXPSOURCETABLES "RUSH_ORDER" OVERWRITE TO FACT "Profit" IN FOLDER "\Public Objects" FOR PROJECT "MicroStrategy Tutorial";

$foo->add_fact_expression(	
	EXPRESSION      => 'ORDER_ID', 
	EXPSOURCETABLES => ["RUSH_ORDER"], 
	OVERWRITE       => "TRUE", FACT => "Profit", 
	LOCATION        => "\\Public Objects", 
	PROJECT         => "MicroStrategy Tutorial"
);

/*Fact Cost*/
ADD EXPRESSION "([QTY_SOLD] * [UNIT_COST])" TO FACT "Cost" IN FOLDER "\Public Objects" FOR PROJECT "MicroStrategy Tutorial";

ADD EXPRESSION "ORDER_COST" TO FACT "Cost" IN FOLDER "\Public Objects" FOR PROJECT "MicroStrategy Tutorial";

ADD EXPRESSION "ITEM_ID" OVERWRITE TO FACT "Cost" IN FOLDER "\Public Objects" FOR PROJECT "Microstrategy Tutorial";

=cut

sub add_fact_expression {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(EXPRESSION EXPSOURCETABLES OVERWRITE FACT LOCATION PROJECT);
my @required = qw(EXPRESSION FACT LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/EXPRESSION/ && do { $result .= "ADD EXPRESSION " . $q . $self->{EXPRESSION} . $q . " "};
	/EXPSOURCETABLES/ && do { $result .= $self->join_objects($_, $_); };
	/OVERWRITE/ && do { if($self->{OVERWRITE} =~ /(F|0)/i) { next; }  $result .=  "OVERWRITE "};
	/FACT/ && do { $result .= "TO FACT " . $q . $self->{FACT} . $q ." "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 add_folder_ace

$foo->add_folder_ace(	
	FOLDER                      => "folder_name", 
	LOCATION                    => "location_path", 
	USER_OR_GROUP               => "USER" | "GROUP", 
	USER_LOGIN_OR_GROUP_NAME    => "user_login_or_group_name", 
	ACCESSRIGHTS                => "VIEW" | "MODIFY" | "FULLCONTROL" | "DENIEDALL" | "DEFAULT" | "CUSTOM", 
	ACCESSRIGHTS_CUSTOM         =>  { 
						BROWSE   => "GRANT" | "DENY", 
						READ     => "GRANT" | "DENY", 
						WRITE    => "GRANT" | "DENY", 
						DELETE   => "GRANT" | "DENY", 
						CONTROL  => "GRANT" | "DENY", 
						USE      => "GRANT" | "DENY", 
						EXECUTE  => "GRANT" | "DENY", 
					},
	CHILDRENACCESSRIGHTS        => "VIEW" | "MODIFY" | "FULLCONTROL" | "DENIEDALL" | "DEFAULT" | "CUSTOM", 		
	CHILDRENACCESSRIGHTS_CUSTOM =>	{ 
						BROWSE   => "GRANT" | "DENY", 
						READ     => "GRANT" | "DENY", 
						WRITE    => "GRANT" | "DENY", 
						DELETE   => "GRANT" | "DENY", 
						CONTROL  => "GRANT" | "DENY", 
						USE      => "GRANT" | "DENY", 
						EXECUTE  => "GRANT" | "DENY", 
					},
	PROJECT 		    => "project_name"
);

Optional parameters: 	
ACCESSRIGHTS_CUSTOM         =>  { 
						BROWSE   => "GRANT" | "DENY", 
						READ     => "GRANT" | "DENY",  
						WRITE    => "GRANT" | "DENY",  
						DELETE   => "GRANT" | "DENY", 
						CONTROL  => "GRANT" | "DENY", 
						USE      => "GRANT" | "DENY", 
						EXECUTE  => "GRANT" | "DENY", 
				},
CHILDRENACCESSRIGHTS_CUSTOM =>	{ 
						BROWSE   => "GRANT" | "DENY", 
						READ     => "GRANT" | "DENY", 
						WRITE    => "GRANT" | "DENY", 
						DELETE   => "GRANT" | "DENY", 
						CONTROL  => "GRANT" | "DENY", 
						USE      => "GRANT" | "DENY", 
						EXECUTE  => "GRANT" | "DENY", 
				}

ADD ACE FOR FOLDER "<folder_name>" IN FOLDER "<location_path>" (USER | GROUP) "<user_login_or_group_name>" ACCESSRIGHTS (VIEW | MODIFY | FULLCONTROL | DENIEDALL | DEFAULT | CUSTOM [GRANT <accessright1> [, <accessright2> [,... <accessrightN>]]] [DENY <accessright1> [, <accessright2> [,... <accessrightN>]]]) CHILDRENACCESSRIGHTS (VIEW | MODIFY | FULLCONTROL | DENIEDALL | DEFAULT | CUSTOM [GRANT <accessright1> [, <accessright2> [,... <accessrightN>]]] [DENY <accessright1> [, <accessright2> [,... <accessrightN>]]]) FOR PROJECT "<project_name>";

ADD ACE FOR FOLDER "Subtotals" IN FOLDER "\Project Objects" USER "Developer" ACCESSRIGHTS FULLCONTROL CHILDRENACCESSRIGHTS MODIFY FOR PROJECT "MicroStrategy Tutorial";

$foo->add_folder_ace(
	FOLDER                   => "Subtotals", 
	LOCATION                 => "\\Project Objects", 
	USER_OR_GROUP            => "USER", 
	USER_LOGIN_OR_GROUP_NAME => "Developer", 
	ACCESSRIGHTS             => "FULLCONTROL", 
	CHILDRENACCESSRIGHTS     => "MODIFY", 
	PROJECT                  => "MicroStrategy Tutorial"
);

ADD ACE FOR FOLDER "Subtotals" IN FOLDER "\Project Objects" USER "Developer" ACCESSRIGHTS CUSTOM GRANT BROWSE, WRITE, DELETE DENY CONTROL, USE, EXECUTE CHILDRENACCESSRIGHTS MODIFY FOR PROJECT "MicroStrategy Tutorial";

$foo->add_folder_ace(FOLDER => "Subtotals", LOCATION => "\\Project Objects", USER_OR_GROUP => "USER", USER_LOGIN_OR_GROUP_NAME => "Developer", ACCESSRIGHTS => "CUSTOM", ACCESSRIGHTS_CUSTOM => { BROWSE => "GRANT", READ => "GRANT", WRITE => "GRANT", DELETE => "GRANT", CONTROL => "DENY", USE  => "DENY", EXECUTE => "DENY"}, CHILDRENACCESSRIGHTS => "MODIFY", PROJECT => "MicroStrategy Tutorial");

ADD ACE FOR FOLDER "Subtotals" IN FOLDER "\Project Objects" USER "Developer" ACCESSRIGHTS CUSTOM GRANT BROWSE, READ, WRITE DENY CONTROL, DELETE, EXECUTE, USE CHILDRENACCESSRIGHTS FULLCONTROL FOR PROJECT "MicroStrategy Tutorial";

$foo->add_folder_ace(	
	FOLDER                   => "Subtotals", 
	LOCATION                 => "\\Project Objects", 
	USER_OR_GROUP            => "USER", 
	USER_LOGIN_OR_GROUP_NAME => "Developer", 
	ACCESSRIGHTS             => "CUSTOM", 
	ACCESSRIGHTS_CUSTOM      => { 
					BROWSE => "GRANT", 
					READ => "GRANT", 
					WRITE => "GRANT", 
					DELETE => "DENY", 
					CONTROL => "DENY", 
					USE  => "DENY", 
					EXECUTE => "DENY"
				   }, 
	CHILDRENACCESSRIGHTS     => "FULLCONTROL", 
	PROJECT                  => "MicroStrategy Tutorial"
);

ADD ACE FOR FOLDER "Subtotals" IN FOLDER "\Project Objects" USER "Developer" ACCESSRIGHTS MODIFY CHILDRENACCESSRIGHTS CUSTOM GRANT BROWSE, READ, WRITE DENY CONTROL, DELETE, EXECUTE, USE FOR PROJECT "MicroStrategy Tutorial";

$foo->add_folder_ace(	
	FOLDER                      => "Subtotals", 
	LOCATION                    => "\\Project Objects", 
	USER_OR_GROUP               => "USER", 
	USER_LOGIN_OR_GROUP_NAME    => "Developer", 
	ACCESSRIGHTS                => "MODIFY", 
	CHILDRENACCESSRIGHTS        => "CUSTOM", 
	CHILDRENACCESSRIGHTS_CUSTOM => { 
						BROWSE  => "GRANT", 
						READ    => "GRANT", 
						WRITE   => "GRANT", 
						DELETE  => "DENY", 
						CONTROL => "DENY", 
						USE     => "DENY", 
						EXECUTE => "DENY"
					}, 
	PROJECT                      => "MicroStrategy Tutorial"
);

ADD ACE FOR FOLDER "Subtotals" IN FOLDER "\Project Objects" USER "Developer" ACCESSRIGHTS CUSTOM GRANT BROWSE, READ, WRITE DENY CONTROL, DELETE, EXECUTE, USE CHILDRENACCESSRIGHTS CUSTOM GRANT CONTROL, DELETE, EXECUTE, USE DENY BROWSE, READ, WRITE FOR PROJECT "MicroStrategy Tutorial";

$foo->add_folder_ace(	
	FOLDER                     => "Subtotals", 
	LOCATION                   => "\\Project Objects", 
	USER_OR_GROUP              => "USER",
	USER_LOGIN_OR_GROUP_NAME   => "Developer", 
	ACCESSRIGHTS               => "CUSTOM", 
	ACCESSRIGHTS_CUSTOM =>  { 
					BROWSE => "GRANT", 
					READ => "GRANT", 
					WRITE => "GRANT", 
					DELETE => "DENY", 
					CONTROL => "DENY", 
					USE  => "DENY", 
					EXECUTE => "DENY"
				}, 
	CHILDRENACCESSRIGHTS        => "CUSTOM",
	CHILDRENACCESSRIGHTS_CUSTOM => { 
						BROWSE  => "DENY", 
						READ    => "DENY", 
						WRITE   => "DENY", 
						DELETE  => "GRANT", 
						CONTROL => "GRANT", 
						USE     => "GRANT", 
						EXECUTE => "GRANT"
					}, 
	PROJECT                      => "MicroStrategy Tutorial"
);

=cut

sub add_folder_ace {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(FOLDER LOCATION USER_OR_GROUP USER_LOGIN_OR_GROUP_NAME ACCESSRIGHTS ACCESSRIGHTS_CUSTOM CHILDRENACCESSRIGHTS CHILDRENACCESSRIGHTS_CUSTOM PROJECT);
my @required = qw();
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/FOLDER/ && do { $result .= "ADD ACE FOR FOLDER " . $q . $self->{FOLDER} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/USER_OR_GROUP/ && do { $result .= $self->{USER_OR_GROUP} . " "};
	/USER_LOGIN_OR_GROUP_NAME/ && do { $result .= $q . $self->{USER_LOGIN_OR_GROUP_NAME} . $q . " "};
	/^ACCESSRIGHTS$/ && do { $result .= "ACCESSRIGHTS " . $self->{ACCESSRIGHTS} . " " };
	/^ACCESSRIGHTS_CUSTOM$/ && do { $result .= custom_access_rights($self->{ACCESSRIGHTS_CUSTOM}) . " " };
	/^CHILDRENACCESSRIGHTS$/ && do { $result .= "CHILDRENACCESSRIGHTS " . $self->{CHILDRENACCESSRIGHTS} . " "};
	/^CHILDRENACCESSRIGHTS_CUSTOM$/ && do { $result .= custom_access_rights($self->{CHILDRENACCESSRIGHTS_CUSTOM}) . " " };
	/PROJECT/i && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 add_project_ace

ADD ACE FOR <project_object_type> "<object_name>" IN FOLDER "<location_path>" (USER | GROUP) "<user_login_or_group_name>" ACCESSRIGHTS (VIEW | MODIFY | FULLCONTROL | DENIEDALL | DEFAULT | CUSTOM [GRANT <accessright1> [, <accessright2> [,... <accessrightN>]]] [DENY <accessright1> [, <accessright2> [,... <accessrightN>]]]) FOR PROJECT "<project_name>";

$foo->add_project_ace(
    PROJECT_OBJECT_TYPE      => "project_object_type",
    OBJECT_NAME              => "object_name",
    LOCATION                 => "location_path",
    USER_OR_GROUP            => "USER" | "GROUP",
    USER_LOGIN_OR_GROUP_NAME => "user_login_or_group_name",
    ACCESSRIGHTS => "VIEW" | "MODIFY" | "FULLCONTROL" | "DENIEDALL" |
      "DEFAULT" | "CUSTOM",
    ACCESSRIGHTS_CUSTOM => {
        BROWSE  => "GRANT" | "DENY",
        READ    => "GRANT" | "DENY",
        WRITE   => "GRANT" | "DENY",
        DELETE  => "GRANT" | "DENY",
        CONTROL => "GRANT" | "DENY",
        USE     => "GRANT" | "DENY",
        EXECUTE => "GRANT" | "DENY"
    },
    PROJECT => "project_name"
);

ADD ACE FOR FACT "MyFact" IN FOLDER "\\Schema Objects\\Facts" "USER" "Developer" ACCESSRIGHTS VIEW FOR PROJECT "MicroStrategy Tutorial";

$foo->add_project_ace(
    PROJECT_OBJECT_TYPE      => "FACT",
    OBJECT_NAME              => "MyFact",
    LOCATION                 => "\\Schema Objects\\Facts",
    USER_OR_GROUP            => "USER",
    USER_LOGIN_OR_GROUP_NAME => "Developer",
    ACCESSRIGHTS             => "VIEW",
    PROJECT                  => "MicroStrategy Tutorial"
);

List of Project Object Types:
REPORT, DOCUMENT, PROMPT, SECFILTER, CONSOLIDATION, CUSTOMGROUP, DRILLMAP, FILTER, METRIC, SEARCH, TEMPLATE, FACT, HIERARCHY, ATTRIBUTE, FUNCTION, PARTITION, TABLE, TRANSFORMATION, SUBTOTAL, AUTOSTYLE

Optional parameters: 
ACCESSRIGHTS_CUSTOM => {
        BROWSE  => "GRANT" | "DENY",
        READ    => "GRANT" | "DENY",
        WRITE   => "GRANT" | "DENY",
        DELETE  => "GRANT" | "DENY",
        CONTROL => "GRANT" | "DENY",
        USE     => "GRANT" | "DENY",
        EXECUTE => "GRANT" | "DENY"
    },

=cut

sub add_project_ace {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(PROJECT_OBJECT_TYPE OBJECT_NAME LOCATION USER_OR_GROUP USER_LOGIN_OR_GROUP_NAME ACCESSRIGHTS ACCESSRIGHTS_CUSTOM PROJECT);
my @required = qw(PROJECT_OBJECT_TYPE OBJECT_NAME LOCATION USER_OR_GROUP USER_LOGIN_OR_GROUP_NAME ACCESSRIGHTS PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/PROJECT_OBJECT_TYPE$/ && do { $result .= "ADD ACE FOR " . $self->{PROJECT_OBJECT_TYPE} . " "};
	/OBJECT_NAME/ && do { $result .= $q . $self->{OBJECT_NAME} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/USER_OR_GROUP/ && do { $result .= $self->{USER_OR_GROUP} . " "};
	/USER_LOGIN_OR_GROUP_NAME/ && do { $result .= $q . $self->{USER_LOGIN_OR_GROUP_NAME} . $q . " "};
	/^ACCESSRIGHTS$/ && do { $result .= "ACCESSRIGHTS " . $self->{ACCESSRIGHTS} . " " };
	/^ACCESSRIGHTS_CUSTOM$/ && do { $result .= custom_access_rights($self->{ACCESSRIGHTS_CUSTOM}) . " " };
	/PROJECT$/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 add_server_cluster

ADD SERVER "<server_name>" TO CLUSTER;

$foo->add_server_cluster(SERVER => "server_name");

This command can be used only in 3-tier Project Source Names. 

ADD SERVER "PROD_SRV" TO CLUSTER;

$foo->add_server_cluster(SERVER => "PROD_SRV");

=cut

sub add_server_cluster {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(SERVER);
my @required = qw(SERVER);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/SERVER/ && do { $result .= "ADD SERVER " . $q . $self->{SERVER} . $q . " TO CLUSTER;"; };
}

return $result;
}

=head2 add_user

ADD USER "<login_name>" [TO] GROUP "<Group_name_1>" , "<Group_name_2>";

$foo->add_user(
    USER  => "login_name",
    GROUP => [ "Group_name_1", "Group_name_2" ]
);

ADD USER "palcazar" TO GROUP "Managers";

$foo->add_user(
    USER  => "login_name",
    GROUP => ["Managers"]
);

=cut

sub add_user {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(USER GROUP);
my @required = qw(USER GROUP);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/USER/ && do { $result .= "ADD USER " . $q . $self->{USER} . $q . " "};
	/GROUP/ && do { $result .= $self->join_objects($_, "TO GROUP"); };
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 add_whtable

ADD WHTABLE "<warehouse_table_name>" [PREFIX "<prefix_name>"] [AUTOMAPPING (TRUE | FALSE)] [CALTABLELOGICALSIZE (TRUE | FALSE)] [COLMERGEOPTION (RECENT | MAXDENOMINATOR | NOMERGE)] TO PROJECT "<project_name>";

$foo->add_whtable(
    WHTABLE             => "warehouse_table_name",
    PREFIX              => "prefix_name",
    AUTOMAPPING         => "TRUE" | "FALSE",
    CALTABLELOGICALSIZE => "TRUE" | "FALSE",
    COLMERGEOPTION      => "RECENT" | "MAXDENOMINATOR" | "NOMERGE",
    PROJECT             => "project_name"
);

Optional parameters: PREFIX => "<prefix_name>",AUTOMAPPING => (TRUE | FALSE),CALTABLELOGICALSIZE => (TRUE | FALSE),COLMERGEOPTION => (RECENT | MAXDENOMINATOR | NOMERGE)

This sample illustrates the manipulation of tables.
Warehouse Partition Table and Non_Relational Table are not supported.
Warehouse table names are case sensitive; logical table names are not case sensitive
Note when you add a warehouse table:
	1. Prefix option is similar to that of setting a default prefix in warehouse catalog. If Prefix exists, Command Manager uses it; otherwise, Command Manager creates a new one.
	2. Automapping option: If automapping is set to TRUE, the new table will have all the attributes, facts that use one of its columns mapped to it.
	3. CalTableLogicalSize: Allows users to calculate the logical size of this table once facts and attributes have been mapped.
	4. ColMergeOption
	   RECENT: If a column is discovered in the warehouse, which has the same name as that of an existing column but different data types, the column in the project is updated to have the data type found in the warehouse. 
	   MAXDENOMINATOR: Columns with the same name are always treated as the same object if they have compatible data types (i.e., all numeric, all string-text, etc.). The resulting column in the project has a maximum common data type for all the corresponding physical columns.
	   NOMERGE: Two columns having the same name but different data types are treated as two different columns in the project.
	5. Default Options: AUTOMAPPING is set to TRUE, CALTABLELOGICALSIZE is set to TRUE, and COLMERGEOPTION is set to RECENT.
	6. When adding a new warehouse table into a project, make sure this project has at least one associated DBRole.

ADD WHTABLE "DT_QUARTER" PREFIX "Tutorial" AUTOMAPPING TRUE CALTABLELOGICALSIZE TRUE COLMERGEOPTION MAXDENOMINATOR TO PROJECT "MicroStrategy Tutorial";

$foo->add_whtable(
    WHTABLE             => "DT_QUARTER",
    PREFIX              => "Tutorial",
    AUTOMAPPING         => "TRUE",
    CALTABLELOGICALSIZE => "TRUE",
    COLMERGEOPTION      => "MAXDENOMINATOR",
    PROJECT             => "MicroStrategy Tutorial"
);

ADD WHTABLE "DT_YEAR" COLMERGEOPTION MAXDENOMINATOR TO PROJECT "MicroStrategy Tutorial";

$foo->add_whtable(
    WHTABLE        => "DT_YEAR",
    COLMERGEOPTION => "MAXDENOMINATOR",
    PROJECT        => "MicroStrategy Tutorial"
);

=cut

sub add_whtable {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(WHTABLE PREFIX AUTOMAPPING CALTABLELOGICALSIZE COLMERGEOPTION PROJECT);
my @required = qw(WHTABLE PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/WHTABLE/ && do { $result .= "ADD WHTABLE " . $q . $self->{WHTABLE} . $q . " "};
	/PREFIX/ && do { $result .= "PREFIX " . $q . $self->{PREFIX} . $q . " "};
	/AUTOMAPPING/ && do { $result .= "AUTOMAPPING " . $self->{AUTOMAPPING} . " "};
	/CALTABLELOGICALSIZE/ && do { $result .= "CALTABLELOGICALSIZE " . $self->{CALTABLELOGICALSIZE} . " "};
	/COLMERGEOPTION/ && do { $result .= "COLMERGEOPTION " . $self->{COLMERGEOPTION} . " "};
	/PROJECT/ && do { $result .= "TO PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 alter_attribute_form_expression

ALTER ATTRIBUTEFORMEXP "<expression>" [OVERWRITE] [LOOKUPTABLE "<lookup_table>"] MAPPINGMODE (AUTOMATIC | EXPSOURCETABLES "<sourcetable1>", [, "<sourcetable2>" [,  "<sourcetableN>"]]) TO ATTRIBUTEFORM "<form_name>" FOR ATTRIBUTE "<attribute_name>" IN FOLDER "<location_path>" FOR PROJECT "<project_name>";

$foo->alter_attribute_form_expression(
    ATTRIBUTEFORMEXP => "expression",
    OVERWRITE        => "TRUE" | "FALSE",
    LOOKUPTABLE      => "lookup_table",
    MAPPINGMODE      => ["AUTOMATIC"] |
      [ "sourcetable1", "sourcetable2", "sourcetableN" ],
    ATTRIBUTEFORM => "form_name",
    ATTRIBUTE     => "attribute_name",
    LOCATION      => "location_path",
    PROJECT       => "project_name"
);


Optional parameters: 
	OVERWRITE        => "TRUE" | "FALSE",
	LOOKUPTABLE      => "lookup_table",

ALTER ATTRIBUTEFORMEXP "ORDER_DATE" MAPPINGMODE AUTOMATIC FOR ATTRIBUTEFORM "ID" FOR ATTRIBUTE "Day" IN FOLDER "\Schema Objects\Attributes" FOR PROJECT "MicroStrategy Tutorial";

$foo->alter_attribute_form_expression(
    ATTRIBUTEFORMEXP => "ORDER_DATE",
    MAPPINGMODE      => "AUTOMATIC",
    ATTRIBUTEFORM    => "ID",
    ATTRIBUTE        => "Day",
    LOCATION         => "\\Schema Objects\\Attributes",
    PROJECT          => "MicroStrategy Tutorial"
);

ALTER ATTRIBUTEFORMEXP "ORDER_DATE" MAPPINGMODE EXPSOURCETABLES "ORDER_DETAIL", "ORDER_FACT" FOR ATTRIBUTEFORM "ID" FOR ATTRIBUTE "Day" IN FOLDER "\Schema Objects\Attributes" FOR PROJECT "MicroStrategy Tutorial";

$foo->alter_attribute_form_expression(
    ATTRIBUTEFORMEXP => "ORDER_DATE",
    MAPPINGMODE      => [ "ORDER_DETAIL", "ORDER_FACT" ],
    ATTRIBUTEFORM    => "ID",
    ATTRIBUTE        => "Day",
    LOCATION         => "\\Schema Objects\\Attributes",
    PROJECT          => "MicroStrategy Tutorial"
);

=cut

sub alter_attribute_form_expression {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(ATTRIBUTEFORMEXP OVERWRITE LOOKUPTABLE MAPPINGMODE ATTRIBUTEFORM ATTRIBUTE LOCATION PROJECT);
my @required = qw(ATTRIBUTEFORMEXP MAPPINGMODE ATTRIBUTEFORM ATTRIBUTE LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/^ATTRIBUTEFORMEXP$/ && do { $result .= "ALTER ATTRIBUTEFORMEXP " . $q . $self->{ATTRIBUTEFORMEXP} . $q . " "};
	/OVERWRITE/ && do { if($self->{OVERWRITE} =~ /(F|0)/i) { next; }  $result .=  "OVERWRITE "};
	/LOOKUPTABLE/ && do { $result .= "LOOKUPTABLE " . $q . $self->{LOOKUPTABLE} . $q . " "};
	/MAPPINGMODE/ && do { 
		$result .= "MAPPINGMODE ";
		if ($self->{MAPPINGMODE} =~ /ARRAY/) {  
			$result .= $self->join_objects($_, "EXPSOURCETABLES");
			next;
		}
		$result .= "AUTOMATIC "; 
	};
	/^ATTRIBUTEFORM$/ && do { $result .= "FOR ATTRIBUTEFORM " . $q . $self->{ATTRIBUTEFORM} . $q . " "};
	/^ATTRIBUTE$/ && do { $result .= "FOR ATTRIBUTE " . $q . $self->{ATTRIBUTE} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 alter_attribute

ALTER ATTRIBUTE "<attribute_name>" IN FOLDER "<location_path>" [HIDDEN TRUE | FALSE] [NAME "<new_attribute_name>"] [DESCRIPTION "<description>"] [FOLDER "<new_location_path>"] [REPORTDISPLAYFORMS ("<form1>" [, "<form2>" [,.. "<formN>"]] | NONE)] BROWSEDISPLAYFORMS ("<form1>" [, "<form2>" [,.. "<formN>"]] | NONE)] [ELEMDISPLAY (LOCKED | UNLOCKED | LIMIT <number_of_forms>)] [SECFILTERSTOELEMBROWSING (TRUE | FALSE)] [ENABLEELEMCACHING (TRUE | FALSE)] FOR PROJECT "<project_name>";

$foo->alter_attribute(
    ATTRIBUTE                => "attribute_name",
    LOCATION                 => "location_path",
    HIDDEN                   => "TRUE" | "FALSE",
    NEW_NAME                 => "new_attribute_name",
    DESCRIPTION              => "description",
    NEW_LOCATION             => "new_location_path",
    REPORTDISPLAYFORMS       => [ "form1", "form2", "formN" ] | "NONE",
    BROWSEDISPLAYFORMS       => [ "form1", "form2", "formN" ] | "NONE",
    ELEMDISPLAY              => "LOCKED" | "UNLOCKED" | "LIMIT number_of_forms",
    SECFILTERSTOELEMBROWSING => "TRUE" | "FALSE",
    ENABLEELEMCACHING        => "TRUE" | "FALSE",
    PROJECT                  => "project_name"
);

Optional parameters: HIDDEN => TRUE | FALSE, NEW_NAME => "<new_attribute_name>", DESCRIPTION => "<description>" NEW_LOCATION => "<new_location_path>",REPORTDISPLAYFORMS => ("<form1>" , "<form2>" ,.. "<formN>" | NONE),, => "<form2>" ,.. "<formN>",ELEMDISPLAY => (LOCKED | UNLOCKED | LIMIT <number_of_forms>),SECFILTERSTOELEMBROWSING => (TRUE | FALSE),ENABLEELEMCACHING => (TRUE | FALSE)

ALTER ATTRIBUTE "Day" IN FOLDER "\Schema Objects\Attributes" NAME "Duplicate_Day" FOLDER "\Schema Objects\Attributes\Time" REPORTDISPLAYFORMS "ID" BROWSEDISPLAYFORMS "ID" ELEMDISPLAY UNLOCKED SECFILTERSTOELEMBROWSING TRUE ENABLEELEMCACHING TRUE FOR PROJECT "MicroStrategy Tutorial";

$foo->alter_attribute(
    ATTRIBUTE                => "Day",
    LOCATION                 => '\Schema Objects\Attributes',
    NEW_NAME                 => "Duplicate_Day",
    NEW_LOCATION             => '\Schema Objects\Attributes\Time',
    REPORTDISPLAYFORMS       => ["ID"],
    BROWSEDISPLAYFORMS       => ["ID"],
    ELEMDISPLAY              => "UNLOCKED",
    SECFILTERSTOELEMBROWSING => "TRUE",
    ENABLEELEMCACHING        => "TRUE",
    PROJECT                  => "MicroStrategy Tutorial"
);

ALTER ATTRIBUTE "Day" IN FOLDER "\Schema Objects\Attributes" NAME "Duplicate_Day" FOLDER "\Schema Objects\Attributes\Time" REPORTDISPLAYFORMS NONE BROWSEDISPLAYFORMS "ID" ELEMDISPLAY UNLOCKED SECFILTERSTOELEMBROWSING TRUE ENABLEELEMCACHING TRUE FOR PROJECT "MicroStrategy Tutorial";

$foo->alter_attribute(
    ATTRIBUTE                => "Day",
    LOCATION                 => '\Schema Objects\Attributes',
    NEW_NAME                 => "Duplicate_Day",
    NEW_LOCATION             => '\Schema Objects\Attributes\Time',
    REPORTDISPLAYFORMS       => "NONE",
    BROWSEDISPLAYFORMS       => ["ID"],
    ELEMDISPLAY              => "UNLOCKED",
    SECFILTERSTOELEMBROWSING => "TRUE",
    ENABLEELEMCACHING        => "TRUE",
    PROJECT                  => "MicroStrategy Tutorial"
);

ALTER ATTRIBUTE "Copy of Day" IN FOLDER "\Schema Objects\Attributes" HIDDEN FALSE FOR PROJECT "MicroStrategy Tutorial";
UPDATE SCHEMA REFRESHSCHEMA RECALTABLEKEYS RECALTABLELOGICAL RECALOBJECTCACHE FOR PROJECT "MicroStrategy Tutorial";


=cut

sub alter_attribute {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(ATTRIBUTE LOCATION HIDDEN NEW_NAME DESCRIPTION NEW_LOCATION REPORTDISPLAYFORMS BROWSEDISPLAYFORMS ELEMDISPLAY SECFILTERSTOELEMBROWSING ENABLEELEMCACHING PROJECT);
my @required = qw(ATTRIBUTE LOCATION BROWSEDISPLAYFORMS PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/ATTRIBUTE/ && do { $result .= "ALTER ATTRIBUTE " . $q . $self->{ATTRIBUTE} . $q . " "};
	/^LOCATION$/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/HIDDEN/ && do { $result .= "HIDDEN " . $self->{HIDDEN} . " "};
	/NEW_NAME/ && do { $result .= "NAME " . $q . $self->{NEW_NAME} . $q . " "};
	/DESCRIPTION/ && do { $result .= "DESCRIPTION " . $q . $self->{DESCRIPTION} . $q . " "};
	/^NEW_LOCATION$/ && do { $result .= "FOLDER " . $q . $self->{NEW_LOCATION} . $q . " "};
	/REPORTDISPLAYFORMS/ && do { $result .= 
		ref($self->{REPORTDISPLAYFORMS})
		? $self->join_objects($_, $_)
		: "REPORTDISPLAYFORMS " . $self->{REPORTDISPLAYFORMS} . " ";
	};
	/BROWSEDISPLAYFORMS/ && do { $result .= 
		ref($self->{BROWSEDISPLAYFORMS})
		? $self->join_objects($_, $_)
		: "BROWSEDISPLAYFORMS " . $self->{BROWSEDISPLAYFORMS} . " ";
	};
	/ELEMDISPLAY/ && do { $result .= "ELEMDISPLAY " . $self->{ELEMDISPLAY} . " "};
	/SECFILTERSTOELEMBROWSING/ && do { $result .= "SECFILTERSTOELEMBROWSING " . $self->{SECFILTERSTOELEMBROWSING} . " "};
	/ENABLEELEMCACHING/ && do { $result .= "ENABLEELEMCACHING " . $self->{ENABLEELEMCACHING} . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 alter_configuration_ace

ALTER ACE FOR <conf_object_type> "<object_name>" [(USER | GROUP) "<user_login_or_group_name>" ACCESSRIGHTS (VIEW | MODIFY | FULLCONTROL | DENIEDALL | DEFAULT | CUSTOM [GRANT <accessright1> [, <accessright2> [,... <accessrightN>]]] [DENY <accessright1> [, <accessright2> [,... <accessrightN>]]] [DEFAULT accessright1 [, accessright2 [, accessrightn]]])];

$foo->alter_configuration_ace(
    CONF_OBJECT_TYPE         => "conf_object_type",
    OBJECT_NAME              => "object_name",
    USER_OR_GROUP            => "USER" | "GROUP",
    USER_LOGIN_OR_GROUP_NAME => "user_login_or_group_name",
    ACCESSRIGHTS => "VIEW" | "MODIFY" | "FULLCONTROL" | "DENIEDALL" |
      "DEFAULT" | "CUSTOM",
    ACCESSRIGHTS_CUSTOM => {
        BROWSE  => "GRANT" | "DENY",
        READ    => "GRANT" | "DENY",
        WRITE   => "GRANT" | "DENY",
        DELETE  => "GRANT" | "DENY",
        CONTROL => "GRANT" | "DENY",
        USE     => "GRANT" | "DENY",
        EXECUTE => "GRANT" | "DENY"
    }
);


Optional parameters: (USER => | GROUP) "<user_login_or_group_name>" ACCESSRIGHTS (VIEW | MODIFY | FULLCONTROL | DENIEDALL | DEFAULT | CUSTOM GRANT <accessright1> , <accessright2> ,... <accessrightN> DENY <accessright1> , <accessright2> ,... <accessrightN> DEFAULT accessright1 , accessright2 , accessrightn)

List of Configuration Object Types:
DBINSTANCE, DBCONNECTION, DBLOGIN, SCHEDULE, USER, GROUP, EVENT


=cut

sub alter_configuration_ace {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(CONF_OBJECT_TYPE OBJECT_NAME USER_OR_GROUP USER_LOGIN_OR_GROUP_NAME ACCESSRIGHTS ACCESSRIGHTS_CUSTOM);
my @required = qw(CONF_OBJECT_TYPE OBJECT_NAME USER_OR_GROUP USER_LOGIN_OR_GROUP_NAME ACCESSRIGHTS);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/CONF_OBJECT_TYPE/ && do { $result .= "ALTER ACE FOR " . $self->{CONF_OBJECT_TYPE} . " "};
	/OBJECT_NAME/ && do { $result .= $q . $self->{OBJECT_NAME} . $q . " "};
	/USER_OR_GROUP/ && do { $result .= $self->{USER_OR_GROUP} . " "};
	/USER_LOGIN_OR_GROUP_NAME/ && do { $result .= $q . $self->{USER_LOGIN_OR_GROUP_NAME} . $q . " "};
	/^ACCESSRIGHTS$/ && do { $result .= "ACCESSRIGHTS " . $self->{ACCESSRIGHTS} . " " };
	/^ACCESSRIGHTS_CUSTOM$/ && do { $result .= custom_access_rights($self->{ACCESSRIGHTS_CUSTOM}) . " " };
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 alter_connection_map

ALTER CONNECTION MAP FOR USER "<login_name>" DBINSTANCE "<dbinstance_name>" [DBCONNECTION "<dbConnection_name>"] [DBLOGIN "<dblogin_name>"] ON PROJECT "<project_name>";

    $foo->alter_connection_map(
        USER         => "login_name",
        DBINSTANCE   => "dbinstance_name",
        DBCONNECTION => "dbConnection_name",
        DBLOGIN      => "dblogin_name",
        PROJECT      => "project_name"
    );

Optional parameters: 
        DBCONNECTION => "dbConnection_name",
        DBLOGIN      => "dblogin_name"


ALTER CONNECTION MAP FOR USER "Developer" DBINSTANCE "Tutorial Data" DBLOGIN "Data" ON PROJECT "MicroStrategy Tutorial";

    $foo->alter_connection_map(
        USER       => "Developer",
        DBINSTANCE => "Tutorial Data",
        DBLOGIN    => "Data",
        PROJECT    => "MicroStrategy Tutorial"
    );

ALTER CONNECTION MAP FOR USER "jsmith" DBINSTANCE "MSI_DB" DBCONNECTION "MSI_DB_Conn" DBLOGIN "MSI_USER" ON PROJECT "MicroStrategy Tutorial";

    $foo->alter_connection_map(
        USER         => "jsmith",
        DBINSTANCE   => "MSI_DB",
        DBCONNECTION => "MSI_DB_Conn",
        DBLOGIN      => "MSI_USER",
        PROJECT      => "MicroStrategy Tutorial"
    );


=cut

sub alter_connection_map {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(USER DBINSTANCE DBCONNECTION DBLOGIN PROJECT);
my @required = qw(USER DBINSTANCE PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/USER/ && do { $result .= "ALTER CONNECTION MAP FOR USER " . $q . $self->{USER} . $q . " "};
	/DBINSTANCE/ && do { $result .= "DBINSTANCE " . $q . $self->{DBINSTANCE} . $q . " "};
	/DBCONNECTION/ && do { $result .= "DBCONNECTION " . $q . $self->{DBCONNECTION} . $q . " "};
	/DBLOGIN/ && do { $result .= "DBLOGIN " . $q . $self->{DBLOGIN} . $q . " "};
	/PROJECT/ && do { $result .= "ON PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 alter_custom_group

ALTER CUSTOMGROUP "<customgroup_name>" IN FOLDER "<location_path>" [NAME "<new_customgroup_name>"] [DESCRIPTION "<new_description>"] [FOLDER "<new_location_path>"] [ENABLEHIERARCHICALDISPLAY (TRUE | FALSE)] [ENABLESUBTOTALDISPLAY (TRUE | FALSE)] [ELEMENTHEADERPOSITION (ABOVE | BELOW)] [HIDDEN (TRUE | FALSE)] FOR PROJECT "<project_name>";

    $foo->alter_custom_group(
        CUSTOMGROUP               => "customgroup_name",
        LOCATION                  => "location_path",
        NEW_NAME                  => "new_customgroup_name",
        DESCRIPTION               => "new_description",
        NEW_LOCATION              => "new_location_path",
        ENABLEHIERARCHICALDISPLAY => "TRUE" | "FALSE",
        ENABLESUBTOTALDISPLAY     => "TRUE" | "FALSE",
        ELEMENTHEADERPOSITION     => "TRUE" | "FALSE",
        HIDDEN                    => "TRUE" | "FALSE",
        PROJECT                   => "project_name"
    );


Optional parameters: 
        NEW_NAME                  => "new_customgroup_name",
        DESCRIPTION               => "new_description",
        NEW_LOCATION              => "new_location_path",
        ENABLEHIERARCHICALDISPLAY => "TRUE" | "FALSE",
        ENABLESUBTOTALDISPLAY     => "TRUE" | "FALSE",
        ELEMENTHEADERPOSITION     => "TRUE" | "FALSE",
        HIDDEN                    => "TRUE" | "FALSE",

ALTER CUSTOMGROUP "My Custom Groups" IN FOLDER "\Public Objects\Custom Groups" NAME "Modified My Custom Groups" DESCRIPTION "Modified Copy of My Custom Groups" FOLDER "\Public Objects\Custom Groups\Modified Custom Groups" ENABLEHIERARCHICALDISPLAY FALSE ENABLESUBTOTALDISPLAY TRUE ELEMENTHEADERPOSITION ABOVE HIDDEN FALSE FOR PROJECT "MicroStrategy Tutorial";

    $foo->alter_custom_group(
        CUSTOMGROUP => "My Custom Groups",
        LOCATION    => '\Public Objects\Custom Groups',
        NEW_NAME    => "Modified My Custom Groups",
        NEW_DESCRIPTION => "Modified Copy of My Custom Groups",
        NEW_LOCATION => '\Public Objects\Custom Groups\Modified Custom Groups',
        ENABLEHIERARCHICALDISPLAY => "FALSE",
        ENABLESUBTOTALDISPLAY     => "TRUE",
        ELEMENTHEADERPOSITION     => "ABOVE",
        HIDDEN                    => "FALSE",
        PROJECT                   => "MicroStrategy Tutorial"
    );

ALTER CUSTOMGROUP "Copy of Age Groups" IN FOLDER "\Public Objects\Custom Groups" NAME "Modified Age Groups" DESCRIPTION "Modified copy of Age Groups" ENABLEHIERARCHICALDISPLAY TRUE ENABLESUBTOTALDISPLAY TRUE ELEMENTHEADERPOSITION BELOW HIDDEN TRUE FOR PROJECT "MicroStrategy Tutorial";

    $foo->alter_custom_group(
        CUSTOMGROUP               => "Copy of Age Groups",
        LOCATION                  => '\Public Objects\Custom Groups',
        NEW_NAME                  => "Modified Age Groups",
        NEW_DESCRIPTION           => "Modified copy of Age Groups",
        ENABLEHIERARCHICALDISPLAY => "TRUE",
        ENABLESUBTOTALDISPLAY     => "TRUE",
        ELEMENTHEADERPOSITION     => "BELOW",
        HIDDEN                    => "TRUE",
        PROJECT                   => "MicroStrategy Tutorial"
    );


=cut

sub alter_custom_group {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(CUSTOMGROUP LOCATION NEW_NAME NEW_DESCRIPTION NEW_LOCATION ENABLEHIERARCHICALDISPLAY ENABLESUBTOTALDISPLAY ELEMENTHEADERPOSITION HIDDEN PROJECT);
my @required = qw(CUSTOMGROUP LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/CUSTOMGROUP/ && do { $result .= "ALTER CUSTOMGROUP " . $q . $self->{CUSTOMGROUP} . $q . " "};
	/^LOCATION$/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/NEW_NAME/ && do { $result .= "NAME " . $q . $self->{NEW_NAME} . $q . " "};
	/NEW_DESCRIPTION/ && do { $result .= "DESCRIPTION " . $q . $self->{NEW_DESCRIPTION} . $q . " "};
	/^NEW_LOCATION$/ && do { $result .= "FOLDER " . $q . $self->{NEW_LOCATION} . $q . " "};
	/ENABLEHIERARCHICALDISPLAY/ && do { $result .= "ENABLEHIERARCHICALDISPLAY " . $self->{ENABLEHIERARCHICALDISPLAY} . " "};
	/ENABLESUBTOTALDISPLAY/ && do { $result .= "ENABLESUBTOTALDISPLAY " . $self->{ENABLESUBTOTALDISPLAY} . " "};
	/ELEMENTHEADERPOSITION/ && do { $result .= "ELEMENTHEADERPOSITION " . $self->{ELEMENTHEADERPOSITION} . " "};
	/HIDDEN/ && do { $result .= "HIDDEN " . $self->{HIDDEN} . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 alter_dbconnection

ALTER DBCONNECTION "<dbconnection_name>" [NAME "<new_dbconn_name>" ] [ODBCDSN "<new_odbc_datasource_name>"] [DEFAULTLOGIN "<new_default_login>"] [DRIVERMODE (MULTIPROCESS | MULTITHREADED)] [EXECMODE (SYNCHRONOUS | ASYNCHRONOUS (CONNECTION | STATEMENT))] [USEEXTENDEDFETCH (TRUE | FALSE)] [USEPARAMQUERIES (TRUE | FALSE)] [MAXCANCELATTEMPT <new_number_of_seconds>] [MAXQUERYEXEC <new_number_of_seconds>] [MAXCONNATTEMPT <new_number_of_seconds>] [CHARSETENCODING (MULTIBYTE | UTF8)] [TIMEOUT <new_number_of_seconds>] [IDLETIMEOUT <new_number_of_seconds>];

    $foo->alter_dbconnection(
        DBCONNECTION => "dbconnection_name",
        NEW_NAME     => "new_dbconn_name",
        ODBCDSN      => "new_odbc_datasource_name",
        DEFAULTLOGIN => "new_default_login",
        DRIVERMODE   => "MULTIPROCESS | MULTITHREADED",
        EXECMODE     => "SYNCHRONOUS | ASYNCHRONOUS( CONNECTION | STATEMENT )",
        USEEXTENDEDFETCH => "TRUE" | "FALSE",
        USEPARAMQUERIES  => "TRUE" | "FALSE",
        MAXCANCELATTEMPT => "new_number_of_seconds",
        MAXQUERYEXEC     => "new_number_of_seconds",
        MAXCONNATTEMPT   => "new_number_of_seconds",
        CHARSETENCODING  => "MULTIBYTE" | "UTF8",
        TIMEOUT          => "new_number_of_seconds",
        IDLETIMEOUT      => "new_number_of_seconds"
    );


Optional parameters: NEW_NAME => "<new_dbconn_name>" ,ODBCDSN => "<new_odbc_datasource_name>",DEFAULTLOGIN => "<new_default_login>",DRIVERMODE => (MULTIPROCESS | MULTITHREADED),EXECMODE => (SYNCHRONOUS | ASYNCHRONOUS (CONNECTION | STATEMENT)),USEEXTENDEDFETCH => (TRUE | FALSE),USEPARAMQUERIES => (TRUE | FALSE),MAXCANCELATTEMPT => <new_number_of_seconds>,MAXQUERYEXEC => <new_number_of_seconds>,MAXCONNATTEMPT => <new_number_of_seconds>,CHARSETENCODING => (MULTIBYTE | UTF8),TIMEOUT => <new_number_of_seconds>,IDLETIMEOUT => <new_number_of_seconds>

ALTER DBCONNECTION "DBConn1" NAME "DBConnection2" ODBCDSN "MSI_ODBC" DEFAULTLOGIN "MSI_USER" DRIVERMODE MULTIPROCESS EXECMODE SYNCHRONOUS USEEXTENDEDFETCH TRUE USEPARAMQUERIES TRUE MAXCANCELATTEMPT 100 MAXQUERYEXEC 100 MAXCONNATTEMPT 100 CHARSETENCODING MULTIBYTE TIMEOUT 100 IDLETIMEOUT 100;

    $foo->alter_dbconnection(
        DBCONNECTION     => "DBConn1",
        NEW_NAME         => "DBConnection2",
        ODBCDSN          => "MSI_ODBC",
        DEFAULTLOGIN     => "MSI_USER",
        DRIVERMODE       => "MULTIPROCESS",
        EXECMODE         => "SYNCHRONOUS",
        USEEXTENDEDFETCH => "TRUE",
        USEPARAMQUERIES  => "TRUE",
        MAXCANCELATTEMPT => "100",
        MAXQUERYEXEC     => "100",
        MAXCONNATTEMPT   => "100",
        CHARSETENCODING  => "MULTIBYTE",
        TIMEOUT          => "100",
        IDLETIMEOUT      => "100"
    );

ALTER DBCONNECTION "DBConn1" TIMEOUT 100;

    $foo->alter_dbconnection( DBCONNECTION => "DBConn1", TIMEOUT => "100" );

=cut

sub alter_dbconnection {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(DBCONNECTION NEW_NAME ODBCDSN DEFAULTLOGIN DRIVERMODE EXECMODE USEEXTENDEDFETCH USEPARAMQUERIES MAXCANCELATTEMPT MAXQUERYEXEC MAXCONNATTEMPT CHARSETENCODING TIMEOUT IDLETIMEOUT);
my @required = qw(DBCONNECTION);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/DBCONNECTION/ && do { $result .= "ALTER DBCONNECTION " . $q . $self->{DBCONNECTION} . $q . " "};
	/NEW_NAME/ && do { $result .= "NAME " . $q . $self->{NEW_NAME} . $q . " "};
	/ODBCDSN/ && do { $result .= "ODBCDSN " . $q . $self->{ODBCDSN} . $q . " "};
	/DEFAULTLOGIN/ && do { $result .= "DEFAULTLOGIN " . $q . $self->{DEFAULTLOGIN} . $q . " "};
	/DRIVERMODE/ && do { $result .= "DRIVERMODE " . $self->{DRIVERMODE} . " "};
	/EXECMODE/ && do { $result .= "EXECMODE " . $self->{EXECMODE} . " "};
	/USEEXTENDEDFETCH/ && do { $result .= "USEEXTENDEDFETCH " . $self->{USEEXTENDEDFETCH} . " "};
	/USEPARAMQUERIES/ && do { $result .= "USEPARAMQUERIES " . $self->{USEPARAMQUERIES} . " "};
	/MAXCANCELATTEMPT/ && do { $result .= "MAXCANCELATTEMPT " . $self->{MAXCANCELATTEMPT} . " "};
	/MAXQUERYEXEC/ && do { $result .= "MAXQUERYEXEC " . $self->{MAXQUERYEXEC} . " "};
	/MAXCONNATTEMPT/ && do { $result .= "MAXCONNATTEMPT " . $self->{MAXCONNATTEMPT} . " "};
	/CHARSETENCODING/ && do { $result .= "CHARSETENCODING " . $self->{CHARSETENCODING} . " "};
	/^TIMEOUT$/ && do { $result .= "TIMEOUT " . $self->{TIMEOUT} . " "};
	/^IDLETIMEOUT$/ && do { $result .= "IDLETIMEOUT " . $self->{IDLETIMEOUT} . " "};
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 alter_dbinstance

    $foo->alter_dbinstance(
        DBINSTANCE        => "dbinstance_name",
        NEW_NAME          => "new_dbinstance_name",
        DBCONNTYPE        => "new_dbconnection_type",
        DBCONNECTION      => "dbconnection_name",
        DESCRIPTION       => "description",
        DATABASE          => "database_name",
        TABLESPACE        => "tablespace_name",
        PRIMARYDBINSTANCE => "dbinstance_name",
        DATAMART          => "dbinstance_name",
        TABLEPREFIX       => "table_prefix",
        HIGHTHREADS       => "no_high_conns",
        MEDIUMTHREADS     => "no_medium_conns",
        LOWTHREADS        => "no_low_conns"
    );

Optional parameters: 
        NEW_NAME          => "new_dbinstance_name",
        DBCONNTYPE        => "new_dbconnection_type",
        DBCONNECTION      => "dbconnection_name",
        DESCRIPTION       => "description",
        DATABASE          => "database_name",
        TABLESPACE        => "tablespace_name",
        PRIMARYDBINSTANCE => "dbinstance_name",
        DATAMART          => "dbinstance_name",
        TABLEPREFIX       => "table_prefix",
        HIGHTHREADS       => "no_high_conns",
        MEDIUMTHREADS     => "no_medium_conns",
        LOWTHREADS        => "no_low_conns"


ALTER DBINSTANCE "<dbinstance_name>" [NAME "<new_dbinstance_name>"] [DBCONNTYPE "<new_dbconnection_type>"] [DBCONNECTION "<dbconnection_name>"] [DESCRIPTION "<description>"] [DATABASE "<database_name>"] [TABLESPACE "<tablespace_name>"] [PRIMARYDBINSTANCE "<dbinstance_name>"] [DATAMART "<dbinstance_name>"] [TABLEPREFIX "<table_prefix>"] [HIGHTHREADS <no_high_conns>] [MEDIUMTHREADS <no_medium_conns>][LOWTHREADS <no_low_conns>];

ALTER DBINSTANCE "Production Database" DBCONNTYPE "Oracle 8i" DATABASE "Production" TABLESPACE "managers" HIGHTHREADS 8;

=cut

sub alter_dbinstance {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(DBINSTANCE NEW_NAME DBCONNTYPE DBCONNECTION DESCRIPTION DATABASE TABLESPACE PRIMARYDBINSTANCE DATAMART TABLEPREFIX HIGHTHREADS MEDIUMTHREADS LOWTHREADS);
my @required =  qw(DBINSTANCE);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/^DBINSTANCE$/ && do { $result .= "ALTER DBINSTANCE " . $q . $self->{DBINSTANCE} . $q . " "};
	/NEW_NAME/ && do { $result .= "NAME " . $q . $self->{NEW_NAME} . $q . " "};
	/DBCONNTYPE/ && do { $result .= "DBCONNTYPE " . $q . $self->{DBCONNTYPE} . $q . " "};
	/DBCONNECTION/ && do { $result .= "DBCONNECTION " . $q . $self->{DBCONNECTION} . $q . " "};
	/DESCRIPTION/ && do { $result .= "DESCRIPTION " . $q . $self->{DESCRIPTION} . $q . " "};
	/DATABASE/ && do { $result .= "DATABASE " . $q . $self->{DATABASE} . $q . " "};
	/TABLESPACE/ && do { $result .= "TABLESPACE " . $q . $self->{TABLESPACE} . $q . " "};
	/^PRIMARYDBINSTANCE$/ && do { $result .= "PRIMARYDBINSTANCE " . $q . $self->{PRIMARYDBINSTANCE} . $q . " "};
	/DATAMART/ && do { $result .= "DATAMART " . $q . $self->{DATAMART} . $q . " "};
	/TABLEPREFIX/ && do { $result .= "TABLEPREFIX " . $q . $self->{TABLEPREFIX} . $q . " "};
	/HIGHTHREADS/ && do { $result .= "HIGHTHREADS " . $self->{HIGHTHREADS} . " "};
	/MEDIUMTHREADS/ && do { $result .= "MEDIUMTHREADS " . $self->{MEDIUMTHREADS} . " "};
	/LOWTHREADS/ && do { $result .= "LOWTHREADS " . $self->{LOWTHREADS} . " "};
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 alter_dblogin

This command applies the changes in a 3-tier PSN without having to restart the server.

ALTER DBLOGIN "<dblogin_name>" [NAME "<new_dblogin_name>"] [LOGIN "<new_database_login>"] [PASSWORD "<new_database_pwd>"];

    $foo->alter_dblogin(
        DBLOGIN      => "dblogin_name",
        NEW_NAME     => "new_dblogin_name",
        NEW_LOGIN    => "new_database_login",
        NEW_PASSWORD => "new_database_pwd"
    );

Optional parameters: 
        NEW_NAME     => "new_dblogin_name",
        NEW_LOGIN    => "new_database_login",
        NEW_PASSWORD => "new_database_pwd"


ALTER DBLOGIN "MSI_USER" NAME "MSI_USER2" LOGIN "MSI_USER_login" PASSWORD "resu_ism";

    $foo->alter_dblogin(
        DBLOGIN      => "MSI_USER",
        NEW_NAME     => "MSI_USER2",
        NEW_LOGIN    => "MSI_USER_login",
        NEW_PASSWORD => "resu_ism"
    );

'ALTER DBLOGIN "Data" LOGIN "dbadmin" PASSWORD "dbadmin";

    $foo->alter_dblogin(
        DBLOGIN      => "Data",
        NEW_LOGIN    => "dbadmin",
        NEW_PASSWORD => "dbadmin"
    );


=cut

sub alter_dblogin {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(DBLOGIN NEW_NAME NEW_LOGIN NEW_PASSWORD);
my @required = qw(DBLOGIN);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/^DBLOGIN$/ && do { $result .= "ALTER DBLOGIN " . $q . $self->{DBLOGIN} . $q . " "};
	/NEW_NAME/ && do { $result .= "NAME " . $q . $self->{NEW_NAME} . $q . " "};
	/^NEW_LOGIN$/ && do { $result .= "LOGIN " . $q . $self->{NEW_LOGIN} . $q . " "};
	/NEW_PASSWORD/ && do { $result .= "PASSWORD " . $q . $self->{NEW_PASSWORD} . $q . " "};
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 alter_element_caching

This command can be used only in 3-tier Project Source Names.

ALTER ELEMENT CACHING IN [PROJECT] "<project_name>" [MAXRAMUSAGE <number_of_Kb>] [MAXRAMUSAGECLIENT <number_of_kb>] [CREATECACHESPERDBLOGIN (TRUE | FALSE)] [CREATECACHESPERDBCONN (TRUE | FALSE)];

    $foo->alter_element_caching(
        PROJECT                => "project_name",
        MAXRAMUSAGE            => "number_of_Kb",
        MAXRAMUSAGECLIENT      => "number_of_kb",
        CREATECACHESPERDBLOGIN => "TRUE" | "FALSE",
        CREATECACHESPERDBCONN  => "TRUE" | "FALSE",
    );

Optional parameters: 
        MAXRAMUSAGE            => "number_of_Kb",
        MAXRAMUSAGECLIENT      => "number_of_kb",
        CREATECACHESPERDBLOGIN => "TRUE" | "FALSE",
        CREATECACHESPERDBCONN  => "TRUE" | "FALSE",


ALTER ELEMENT CACHING IN PROJECT "MicroStrategy Tutorial" MAXRAMUSAGE 10240 MAXRAMUSAGECLIENT 512 CREATECACHESPERDBLOGIN TRUE CREATECACHESPERDBCONN TRUE;

    $foo->alter_element_caching(
        PROJECT                => "MicroStrategy Tutorial",
        MAXRAMUSAGE            => "10240",
        MAXRAMUSAGECLIENT      => "512",
        CREATECACHESPERDBLOGIN => "TRUE",
        CREATECACHESPERDBCONN  => "TRUE"
    );

ALTER ELEMENT CACHING IN PROJECT "MicroStrategy Tutorial" MAXRAMUSAGE 10240 MAXRAMUSAGECLIENT 512;

    $foo->alter_element_caching(
        PROJECT           => "MicroStrategy Tutorial",
        MAXRAMUSAGE       => "10240",
        MAXRAMUSAGECLIENT => "512"
    );


=cut

sub alter_element_caching {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(PROJECT MAXRAMUSAGE MAXRAMUSAGECLIENT CREATECACHESPERDBLOGIN CREATECACHESPERDBCONN);
my @required = qw(PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/PROJECT/ && do { $result .= "ALTER ELEMENT CACHING IN PROJECT " . $q . $self->{PROJECT} . $q . " "};
	/^MAXRAMUSAGE$/ && do { $result .= "MAXRAMUSAGE " . $self->{MAXRAMUSAGE} . " "};
	/^MAXRAMUSAGECLIENT$/ && do { $result .= "MAXRAMUSAGECLIENT " . $self->{MAXRAMUSAGECLIENT} . " "};
	/CREATECACHESPERDBLOGIN/ && do { $result .= "CREATECACHESPERDBLOGIN " . $self->{CREATECACHESPERDBLOGIN} . " "};
	/CREATECACHESPERDBCONN/ && do { $result .= "CREATECACHESPERDBCONN " . $self->{CREATECACHESPERDBCONN} . " "};
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 alter_event

ALTER EVENT "<event_name>" [NAME "<new_event_name>"] [DESCRIPTION "<new_description>"];

    $foo->alter_event(
        EVENT           => "event_name",
        NEW_NAME        => "new_event_name",
        NEW_DESCRIPTION => "new_description"
    );

Optional parameters: 
        NEW_NAME        => "new_event_name",
        NEW_DESCRIPTION => "new_description"

ALTER EVENT "Database Load" NAME "DBMS Load";

    $foo->alter_event( EVENT => "Database Load", NEW_NAME => "DBMS_Load" );

ALTER EVENT "Database Load" NAME "DBMS Load" DESCRIPTION "Modified Database Load";

    $foo->alter_event(
        EVENT           => "Database Load",
        NEW_NAME        => "DBMS_Load",
        NEW_DESCRIPTION => "Modified Database Load"
    );


=cut

sub alter_event {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(EVENT NEW_NAME NEW_DESCRIPTION);
my @required = qw(EVENT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/EVENT/ && do { $result .= "ALTER EVENT " . $q . $self->{EVENT} . $q . " "};
	/NEW_NAME/ && do { $result .= "NAME " . $q . $self->{NEW_NAME} . $q . " "};
	/NEW_DESCRIPTION/ && do { $result .= "DESCRIPTION " . $q . $self->{NEW_DESCRIPTION} . $q . " "};
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 alter_fact

ALTER FACT "<fact_name>" IN FOLDER "<location_path>" [NAME "<new_fact_name>"] [DESCRIPTION "<new_description>"]  [FOLDER "<new_location_path>"] [HIDDEN (TRUE | FALSE)] FOR PROJECT "<project_name>";

    $foo->alter_fact(
        FACT        => "fact_name",
        LOCATION    => "location_path",
        NAME        => "new_fact_name",
        DESCRIPTION => "new_description",
        FOLDER      => "new_location_path",
        HIDDEN      => "TRUE" | "FALSE",
        PROJECT     => "project_name"
    );


Optional parameters: 
        NAME        => "new_fact_name",
        DESCRIPTION => "new_description",
        FOLDER      => "new_location_path",
        HIDDEN      => "TRUE" | "FALSE",
        PROJECT     => "project_name"

ALTER FACT "Revenue" IN FOLDER "\Public Objects" NAME "Copy Revenue" DESCRIPTION "Altered Revenue" FOLDER "\Project Objects" HIDDEN TRUE FOR PROJECT "MicroStrategy Tutorial";

    $foo->alter_fact(
        FACT        => "Revenue",
        LOCATION    => 'Public Objects',
        NAME        => "Copy Revenue",
        DESCRIPTION => "Altered Revenue",
        FOLDER      => '\Project Objects',
        HIDDEN      => "TRUE",
        PROJECT     => "MicroStrategy Tutorial"
    );


=cut

sub alter_fact {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(FACT LOCATION NEW_NAME NEW_DESCRIPTION NEW_LOCATION HIDDEN PROJECT);
my @required = qw(FACT LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/FACT/ && do { $result .= "ALTER FACT " . $q . $self->{FACT} . $q . " "};
	/^LOCATION$/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/NEW_NAME/ && do { $result .= "NAME " . $q . $self->{NEW_NAME} . $q . " "};
	/NEW_DESCRIPTION/ && do { $result .= "DESCRIPTION " . $q . $self->{NEW_DESCRIPTION} . $q . " "};
	/^NEW_LOCATION$/ && do { $result .= "FOLDER " . $q . $self->{NEW_LOCATION} . $q . " "};
	/HIDDEN/ && do { $result .= "HIDDEN " . $self->{HIDDEN} . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 alter_filter

ALTER FILTER "<filter_name>" IN [FOLDER] "<location_path>" [NAME "<new_filter_name>"] [EXPRESSION "<new_expression>"] [DESCRIPTION "<new_description>"] [LOCATION "<new_location_path>"] [HIDDEN (TRUE | FALSE)] ON PROJECT "<project_name>";

   $foo->alter_filter(
        FILTER          => "filter_name",
        LOCATION        => "location_path",
        NEW_NAME        => "new_filter_name",
        NEW_EXPRESSION  => "new_expression",
        NEW_DESCRIPTION => "new_description",
        NEW_LOCATION    => "new_location_path",
        HIDDEN          => "TRUE" | "FALSE",
        PROJECT         => "project_name"
    );


Optional parameters: NEW_NAME => "new_filter_name", NEW_EXPRESSION => "new_expression", NEW_DESCRIPTION => "new_description", NEW_LOCATION => "new_location_path", HIDDEN => (TRUE | FALSE)

ALTER FILTER "South Region" IN FOLDER "\Public Objects\Filters" NAME "Southeast Region" EXPRESSION "Region@ID=3" DESCRIPTION "Modified South Region filter" LOCATION "\Public Objects\Filters\South Region" HIDDEN FALSE ON PROJECT "MicroStrategy Tutorial";

    $foo->alter_filter(
        FILTER          => "South Region",
        LOCATION        => '\Public Objects\Filters',
        NEW_NAME        => "Southeast Region",
        NEW_EXPRESSION  => 'Region@ID=3',
        NEW_DESCRIPTION => "Modified South Region filter",
        NEW_LOCATION    => '\Public Objects\Filters\South Region',
        HIDDEN          => "FALSE",
        PROJECT         => "MicroStrategy Tutorial"
    );

ALTER FILTER "On Promotion(CM)" IN "\Public Objects\Filters" HIDDEN FALSE ON PROJECT "MicroStrategy Tutorial";

    $foo->alter_filter(
        FILTER   => 'On Promotion(CM)',
        LOCATION => '\Public Objects\Filters',
        HIDDEN   => "FALSE",
        PROJECT  => "MicroStrategy Tutorial"
    );

ALTER FILTER "West Region" IN "\Public Objects\Filters" NAME "East Region" EXPRESSION "Region@ID=2" ON PROJECT "MicroStrategy Tutorial";

    $foo->alter_filter(
        FILTER   => "West Region",
        LOCATION => 'Public Objects\Filters',
        NEW_NAME       => "East Region",
        NEW_EXPRESSION => 'Region@ID=2',
        PROJECT        => "MicroStrategy Tutorial"
    );



=cut

sub alter_filter {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(FILTER LOCATION NEW_NAME NEW_EXPRESSION NEW_DESCRIPTION NEW_LOCATION HIDDEN PROJECT);
my @required = qw(FILTER LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/FILTER/ && do { $result .= "ALTER FILTER " . $q . $self->{FILTER} . $q . " "};
	/^LOCATION$/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/NEW_NAME/ && do { $result .= "NAME " . $q . $self->{NEW_NAME} . $q . " "};
	/NEW_EXPRESSION/ && do { $result .= "EXPRESSION " . $q . $self->{NEW_EXPRESSION} . $q . " "};
	/NEW_DESCRIPTION/ && do { $result .= "DESCRIPTION " . $q . $self->{NEW_DESCRIPTION} . $q . " "};
	/^NEW_LOCATION$/ && do { $result .= "LOCATION " . $q . $self->{NEW_LOCATION} . $q . " "};
	/HIDDEN/ && do { $result .= "HIDDEN " . $self->{HIDDEN} . " "};
	/PROJECT/ && do { $result .= "ON PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 alter_folder_ace

ALTER ACE FOR FOLDER "<folder_name>" IN FOLDER "<location_path>" [(USER | GROUP) "<user_login_or_group_name>" ACCESSRIGHTS (VIEW | MODIFY | FULLCONTROL | DENIEDALL | DEFAULT | CUSTOM [GRANT <accessright1> [, <accessright2> [,... <accessrightN>]]] [DENY <accessright1> [, <accessright2> [,... <accessrightN>]]] [DEFAULT accessright1 [, accessright2 [, accessrightn]]]) [CHILDRENACCESSRIGHTS (VIEW | MODIFY | FULLCONTROL | DENIEDALL | DEFAULT | CUSTOM [GRANT <accessright1> [, <accessright2> [,... <accessrightN>]]] [DENY <accessright1> [, <accessright2> [,... <accessrightN>]]] [DEFAULT accessright1 [, accessright2 [, accessrightn]]])]] FOR PROJECT "<project_name>";

    $foo->alter_folder_ace(
        FOLDER                   => "folder_name",
        LOCATION                 => "location_path",
        USER_OR_GROUP            => "USER" | "GROUP",
        USER_LOGIN_OR_GROUP_NAME => "user_login_or_group_name",
        ACCESSRIGHTS => "VIEW" | "MODIFY" | "FULLCONTROL" | "DENIEDALL" |
          "DEFAULT" | "CUSTOM",
        ACCESSRIGHTS_CUSTOM => {
            BROWSE  => "GRANT" | "DENY",
            READ    => "GRANT" | "DENY",
            WRITE   => "GRANT" | "DENY",
            DELETE  => "GRANT" | "DENY",
            CONTROL => "GRANT" | "DENY",
            USE     => "GRANT" | "DENY",
            EXECUTE => "GRANT" | "DENY"
        },
        CHILDRENACCESSRIGHTS => "VIEW" | "MODIFY" | "FULLCONTROL" |
          "DENIEDALL" | "DEFAULT" | "CUSTOM",
        CHILDRENACCESSRIGHTS_CUSTOM => {
            BROWSE  => "GRANT" | "DENY",
            READ    => "GRANT" | "DENY",
            WRITE   => "GRANT" | "DENY",
            DELETE  => "GRANT" | "DENY",
            CONTROL => "GRANT" | "DENY",
            USE     => "GRANT" | "DENY",
            EXECUTE => "GRANT" | "DENY"
        },
        PROJECT => "project_name"
    );


Optional parameters: 
       ACCESSRIGHTS_CUSTOM => {
            BROWSE  => "GRANT" | "DENY",
            READ    => "GRANT" | "DENY",
            WRITE   => "GRANT" | "DENY",
            DELETE  => "GRANT" | "DENY",
            CONTROL => "GRANT" | "DENY",
            USE     => "GRANT" | "DENY",
            EXECUTE => "GRANT" | "DENY"
        },
        CHILDRENACCESSRIGHTS_CUSTOM => {
            BROWSE  => "GRANT" | "DENY",
            READ    => "GRANT" | "DENY",
            WRITE   => "GRANT" | "DENY",
            DELETE  => "GRANT" | "DENY",
            CONTROL => "GRANT" | "DENY",
            USE     => "GRANT" | "DENY",
            EXECUTE => "GRANT" | "DENY"
        },
     
=cut

sub alter_folder_ace {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(FOLDER LOCATION USER_OR_GROUP USER_LOGIN_OR_GROUP_NAME ACCESSRIGHTS ACCESSRIGHTS_CUSTOM CHILDRENACCESSRIGHTS CHILDRENACCESSRIGHTS_CUSTOM PROJECT);
my @required = qw();
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/FOLDER/i && do { $result .= "ALTER ACE FOR FOLDER " . $q . $self->{FOLDER} . $q . " "};
	/LOCATION/i && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/USER_OR_GROUP/i && do { $result .= $self->{USER_OR_GROUP} . " "};
	/USER_LOGIN_OR_GROUP_NAME/i && do { $result .= $q .$self->{USER_LOGIN_OR_GROUP_NAME} . $q . " "};
	/^ACCESSRIGHTS$/ && do { $result .= "ACCESSRIGHTS " . $self->{ACCESSRIGHTS} . " " };
	/^ACCESSRIGHTS_CUSTOM$/ && do { $result .= custom_access_rights($self->{ACCESSRIGHTS_CUSTOM}) . " " };
	/^CHILDRENACCESSRIGHTS$/ && do { $result .= "CHILDRENACCESSRIGHTS " . $self->{CHILDRENACCESSRIGHTS} . " "};
	/^CHILDRENACCESSRIGHTS_CUSTOM$/ && do { $result .= custom_access_rights($self->{CHILDRENACCESSRIGHTS_CUSTOM}) . " " };
	/PROJECT/i && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 alter_folder_acl

   $foo->alter_folder_acl(
        FOLDER              => "folder_name",
        LOCATION            => "location_path",
        PROPAGATE_OVERWRITE => "TRUE" | "FALSE",
        RECURSIVELY         => "TRUE" | "FALSE",
        PROJECT             => "project_name"
    );

 
Optional parameters: 
        PROPAGATE_OVERWRITE => "TRUE" | "FALSE",
        RECURSIVELY         => "TRUE" | "FALSE",



ALTER ACL FOR FOLDER "<folder_name>" IN FOLDER "<location_path>" [PROPAGATE OVERWRITE [RECURSIVELY]] FOR PROJECT "<project_name>";

ALTER ACL FOR FOLDER "Subtotals" IN FOLDER "\Project Objects" PROPAGATE OVERWRITE RECURSIVELY FOR PROJECT "MicroStrategy Tutorial";

=cut

sub alter_folder_acl {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(FOLDER LOCATION PROPAGATE_OVERWRITE RECURSIVELY PROJECT);
my @required = qw(FOLDER LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/FOLDER/ && do { $result .= "ALTER ACL FOR FOLDER " . $q . $self->{FOLDER} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROPAGATE_OVERWRITE/ && do { 
		if($self->{PROPAGATE_OVERWRITE} =~ /(F|0)/i) { 	next; }  
		$result .= "PROPAGATE OVERWRITE "; 
	};
	/RECURSIVELY/ && do { 
		if($self->{RECURSIVELY} =~ /(F|0)/i) { 	next; }  
		$result .= "RECURSIVELY ";
	};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 alter_folder

   $foo->alter_folder(
        FOLDER          => "folder_name",
        LOCATION        => "location_path",
        NEW_NAME        => "new_folder_name",
        NEW_DESCRIPTION => "new_description",
        HIDDEN          => "TRUE" | "FALSE",
        NEW_LOCATION    => "new_location_path",
        PROJECT         => "project_name"
    );


Optional parameters: 
        NEW_NAME        => "new_folder_name",
        NEW_DESCRIPTION => "new_description",
        HIDDEN          => "TRUE" | "FALSE",
        NEW_LOCATION    => "new_location_path",


ALTER FOLDER "<folder_name>" IN "<location_path>" [NAME "<new_folder_name>"] [DESCRIPTION "<new_description>"] [HIDDEN (TRUE | FALSE)] [LOCATION "<new_location_path>"] FOR PROJECT "<project_name>";

=cut

sub alter_folder {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(FOLDER LOCATION NEW_NAME NEW_DESCRIPTION HIDDEN NEW_LOCATION PROJECT);
my @required = qw(FOLDER LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/FOLDER/i && do { $result .= "ALTER FOLDER " . $q . $self->{FOLDER} . $q . " "};
	/^LOCATION$/i && do { $result .= "IN " . $q . $self->{LOCATION} . $q . " "};
	/NEW_NAME/i && do { $result .= "NAME " . $q . $self->{NEW_NAME} . $q . " "};
	/NEW_DESCRIPTION/i && do { $result .= "DESCRIPTION " . $q . $self->{NEW_DESCRIPTION} . $q . " "};
	/HIDDEN/i && do { $result .= "HIDDEN " . $self->{HIDDEN} . " "};
	/^NEW_LOCATION$/i && do { $result .= "LOCATION " . $q . $self->{NEW_LOCATION} . $q . " "};
	/PROJECT/i && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 alter_metric

    $foo->alter_metric(
        METRIC          => "metric_name",
        LOCATION        => "location_path",
        NEW_NAME        => "new_metric_name",
        NEW_EXPRESSION  => "new_expression",
        NEW_DESCRIPTION => "new_description",
        NEW_LOCATION    => "new_location_path",
        HIDDEN          => "TRUE" | "FALSE",
        PROJECT         => "project_name"
    );


Optional parameters: 
        LOCATION        => "location_path",
        NEW_NAME        => "new_metric_name",
        NEW_EXPRESSION  => "new_expression",
        NEW_DESCRIPTION => "new_description",
        NEW_LOCATION    => "new_location_path",
        HIDDEN          => "TRUE" | "FALSE",


ALTER METRIC "<metric_name>" IN [FOLDER] "<location_path>" [NAME "<new_metric_name>"] [EXPRESSION "<new_expression>"] [DESCRIPTION "<new_description>"] [LOCATION "<new_location_path>"] [HIDDEN (TRUE | FALSE)] ON PROJECT "<project_name>";

=cut

sub alter_metric {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(METRIC LOCATION NEW_NAME NEW_EXPRESSION NEW_DESCRIPTION NEW_LOCATION HIDDEN PROJECT);
my @required = qw(METRIC LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/METRIC/ && do { $result .= "ALTER METRIC " . $q . $self->{METRIC} . $q . " "};
	/^LOCATION$/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/NEW_NAME/ && do { $result .= "NAME " . $q . $self->{NEW_NAME} . $q . " "};
	/NEW_EXPRESSION/ && do { $result .= "EXPRESSION " . $q . $self->{NEW_EXPRESSION} . $q . " "};
	/NEW_DESCRIPTION/ && do { $result .= "DESCRIPTION " . $q . $self->{NEW_DESCRIPTION} . $q . " "};
	/^NEW_LOCATION$/ && do { $result .= "LOCATION " . $q . $self->{NEW_LOCATION} . $q . " "};
	/HIDDEN/ && do { $result .= "HIDDEN " . $self->{HIDDEN} . " "};
	/PROJECT/ && do { $result .= "ON PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 alter_object_caching

This command can be used only in 3-tier Project Source Names.

    $foo->alter_object_caching(
        PROJECT           => "project_name",
        MAXRAMUSAGE       => "number_of_Kb",
        MAXRAMUSAGECLIENT => "number_of_kb"
    );


Optional parameters: 
        MAXRAMUSAGE       => "number_of_Kb",
        MAXRAMUSAGECLIENT => "number_of_kb"


ALTER OBJECT CACHING IN [PROJECT] "<project_name>" [MAXRAMUSAGE <number_of_Kb>] [MAXRAMUSAGECLIENT <number_of_kb>];

=cut

sub alter_object_caching {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(PROJECT MAXRAMUSAGE MAXRAMUSAGECLIENT);
my @required = qw(PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/PROJECT/ && do { $result .= "ALTER OBJECT CACHING IN PROJECT " . $q . $self->{PROJECT} . $q . " "};
	/^MAXRAMUSAGE$/ && do { $result .= "MAXRAMUSAGE " . $self->{MAXRAMUSAGE} . " "};
	/^MAXRAMUSAGECLIENT$/ && do { $result .= "MAXRAMUSAGECLIENT " . $self->{MAXRAMUSAGECLIENT} . " "};
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 alter_project_ace

    $foo->alter_project_ace(
        PROJECT_OBJECT_TYPE      => "project_object_type",
        OBJECT_NAME              => "object_name",
        LOCATION                 => "location_path",
        USER_OR_GROUP            => "USER" | "GROUP",
        USER_LOGIN_OR_GROUP_NAME => "user_login_or_group_name",
        ACCESSRIGHTS => "VIEW" | "MODIFY" | "FULLCONTROL" | "DENIEDALL" |
          "DEFAULT" | "CUSTOM",
        AACCESSRIGHTS_CUSTOM => {
            BROWSE  => "GRANT" | "DENY",
            READ    => "GRANT" | "DENY",
            WRITE   => "GRANT" | "DENY",
            DELETE  => "GRANT" | "DENY",
            CONTROL => "GRANT" | "DENY",
            USE     => "GRANT" | "DENY",
            EXECUTE => "GRANT" | "DENY"
        },
        PROJECT => "project_name"
    );


Optional parameters: 
        USER_OR_GROUP            => "USER" | "GROUP",
        USER_LOGIN_OR_GROUP_NAME => "user_login_or_group_name",
        ACCESSRIGHTS => "VIEW" | "MODIFY" | "FULLCONTROL" | "DENIEDALL" |
          "DEFAULT" | "CUSTOM",
        AACCESSRIGHTS_CUSTOM => {
            BROWSE  => "GRANT" | "DENY",
            READ    => "GRANT" | "DENY",
            WRITE   => "GRANT" | "DENY",
            DELETE  => "GRANT" | "DENY",
            CONTROL => "GRANT" | "DENY",
            USE     => "GRANT" | "DENY",
            EXECUTE => "GRANT" | "DENY"
        },
 

ALTER ACE FOR <project_object_type> "<object_name>" IN FOLDER "<location_path>" [(USER | GROUP) "<user_login_or_group_name>" ACCESSRIGHTS (VIEW | MODIFY | FULLCONTROL | DENIEDALL | DEFAULT | CUSTOM [GRANT <accessright1> [, <accessright2> [,... <accessrightN>]]] [DENY <accessright1> [, <accessright2> [,... <accessrightN>]]] [DEFAULT accessright1 [, accessright2 [, accessrightn]]])] FOR PROJECT "<project_name>";

List of Project Object Types:
REPORT, DOCUMENT, PROMPT, SECFILTER, CONSOLIDATION, CUSTOMGROUP, DRILLMAP, FILTER, METRIC, SEARCH, TEMPLATE, FACT, HIERARCHY, ATTRIBUTE, FUNCTION, PARTITION, TABLE, TRANSFORMATION, SUBTOTAL, AUTOSTYLE

=cut

sub alter_project_ace {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(PROJECT_OBJECT_TYPE OBJECT_NAME LOCATION USER_OR_GROUP USER_LOGIN_OR_GROUP_NAME ACCESSRIGHTS ACCESSRIGHTS_CUSTOM PROJECT);
my @required = qw(PROJECT_OBJECT_TYPE OBJECT_NAME LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/^PROJECT_OBJECT_TYPE$/ && do { $result .= "ALTER ACE FOR " . $self->{PROJECT_OBJECT_TYPE} . " "};
	/OBJECT_NAME/ && do { $result .= $q . $self->{OBJECT_NAME} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/USER_OR_GROUP/ && do { $result .= $self->{USER_OR_GROUP} . " "};
	/USER_LOGIN_OR_GROUP_NAME/ && do { $result .= $q . $self->{USER_LOGIN_OR_GROUP_NAME} . $q . " "};
	/^ACCESSRIGHTS$/ && do { $result .= "ACCESSRIGHTS " . $self->{ACCESSRIGHTS} . " "};
	/^ACCESSRIGHTS_CUSTOM$/ && do { $result .= custom_access_rights($self->{ACCESSRIGHTS_CUSTOM}) . " " };
	/^PROJECT$/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 alter_project_config

    $foo->alter_project_config(
        DESCRIPTION            => "Project_description",
        WAREHOUSE              => "WH_name",
        STATUS                 => "html_input_file",
        SHOWSTATUS             => "TRUE" | "FALSE",
        STATUSONTOP            => "TRUE" | "FALSE",
        DOCDIRECTORY           => "folder_path",
        MAXNOATTRELEMS         => "no_attribute_elems",
        USEWHLOGINEXEC         => "TRUE" | "FALSE",
        ENABLEOBJECTDELETION   => "TRUE" | "FALSE",
        MAXREPORTEXECTIME      => "no_seconds",
        MAXNOREPORTRESULTROWS  => "no_rows",
        MAXNOELEMROWS          => "no_rows",
        MAXNOINTRESULTROWS     => "no_rows",
        MAXJOBSUSERACCT        => "no_jobs",
        MAXJOBSUSERSESSION     => "no_jobs",
        MAXEXECJOBSUSER        => "no_jobs",
        MAXJOBSPROJECT         => "no_jobs",
        MAXUSERSESSIONSPROJECT => "no_user_sessions",
        PROJDRILLMAP           => "drill_map",
        DRILLMAP_LOCATION      => "drill_map_location_path",
        REPORTTPL              => "report_template",
        REPORTSHOWEMPTYTPL     => "TRUE" | "FALSE",
        TEMPLATETPL            => "template_template",
        TEMPLATESHOWEMPTYTPL   => "TRUE" | "FALSE",
        METRICTPL              => "metric_template",
        METRICSHOWEMPTYTPL     => "TRUE" | "FALSE",
        PROJECT                => "project_name"
    );


Optional parameters: 
        DESCRIPTION            => "Project_description",
        WAREHOUSE              => "WH_name",
        STATUS                 => "html_input_file",
        SHOWSTATUS             => "TRUE" | "FALSE",
        STATUSONTOP            => "TRUE" | "FALSE",
        DOCDIRECTORY           => "folder_path",
        MAXNOATTRELEMS         => "no_attribute_elems",
        USEWHLOGINEXEC         => "TRUE" | "FALSE",
        ENABLEOBJECTDELETION   => "TRUE" | "FALSE",
        MAXREPORTEXECTIME      => "no_seconds",
        MAXNOREPORTRESULTROWS  => "no_rows",
        MAXNOELEMROWS          => "no_rows",
        MAXNOINTRESULTROWS     => "no_rows",
        MAXJOBSUSERACCT        => "no_jobs",
        MAXJOBSUSERSESSION     => "no_jobs",
        MAXEXECJOBSUSER        => "no_jobs",
        MAXJOBSPROJECT         => "no_jobs",
        MAXUSERSESSIONSPROJECT => "no_user_sessions",
        PROJDRILLMAP           => "drill_map",
        DRILLMAP_LOCATION      => "drill_map_location_path",
        REPORTTPL              => "report_template",
        REPORTSHOWEMPTYTPL     => "TRUE" | "FALSE",
        TEMPLATETPL            => "template_template",
        TEMPLATESHOWEMPTYTPL   => "TRUE" | "FALSE",
        METRICTPL              => "metric_template",
        METRICSHOWEMPTYTPL     => "TRUE" | "FALSE",


This command can be used only in 3-tier Project Source Names.

ALTER PROJECT CONFIGURATION [DESCRIPTION "<Project_description>"] 
                            [WAREHOUSE "<WH_name>"] 
                            [STATUS "<html_input_file>"] 
                            [SHOWSTATUS (TRUE | FALSE)] 
                            [STATUSONTOP (TRUE | FALSE)] 
                            [DOCDIRECTORY "<folder_path>"] 
                            [MAXNOATTRELEMS <no_attribute_elems>] 
                            [USEWHLOGINEXEC (TRUE | FALSE)] 
                            [ENABLEOBJECTDELETION (TRUE | FALSE)] 
                            [MAXREPORTEXECTIME <no_seconds>] 
                            [MAXNOREPORTRESULTROWS <no_rows>] 
                            [MAXNOELEMROWS <no_rows>] 
                            [MAXNOINTRESULTROWS <no_rows>] 
                            [MAXJOBSUSERACCT <no_jobs>] 
                            [MAXJOBSUSERSESSION <no_jobs>] 
                            [MAXEXECJOBSUSER <no_jobs>] 
                            [MAXJOBSPROJECT <no_jobs>] 
                            [MAXUSERSESSIONSPROJECT <no_user_sessions>] 
                            [PROJDRILLMAP "<drill_map>" [IN FOLDER <drill_map_location_path>"]] 
                            [REPORTTPL "<report_template>"] 
                            [REPORTSHOWEMPTYTPL (TRUE | FALSE)] 
                            [TEMPLATETPL "<template_template>"] 
                            [TEMPLATESHOWEMPTYTPL (TRUE | FALSE)] 
                            [METRICTPL "<metric_template>"] 
                            [METRICSHOWEMPTYTPL (TRUE | FALSE)] 
IN PROJECT "<project_name>";

=cut

sub alter_project_config {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(DESCRIPTION WAREHOUSE STATUS SHOWSTATUS STATUSONTOP DOCDIRECTORY MAXNOATTRELEMS USEWHLOGINEXEC ENABLEOBJECTDELETION MAXREPORTEXECTIME MAXNOREPORTRESULTROWS MAXNOELEMROWS MAXNOINTRESULTROWS MAXJOBSUSERACCT MAXJOBSUSERSESSION MAXEXECJOBSUSER MAXJOBSPROJECT MAXUSERSESSIONSPROJECT PROJDRILLMAP DRILLMAP_LOCATION REPORTTPL REPORTSHOWEMPTYTPL TEMPLATETPL TEMPLATESHOWEMPTYTPL METRICTPL METRICSHOWEMPTYTPL PROJECT);
my @required = qw(PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
$result .= "ALTER PROJECT CONFIGURATION ";
for(@selected) {
	/DESCRIPTION/ && do { $result .= "DESCRIPTION " . $q . $self->{DESCRIPTION} . $q . " "};
	/WAREHOUSE/ && do { $result .= "WAREHOUSE " . $q . $self->{WAREHOUSE} . $q . " "};
	/^STATUS$/ && do { $result .= "STATUS " . $q . $self->{STATUS} . $q . " "};
	/^SHOWSTATUS$/ && do { $result .= "SHOWSTATUS " . $self->{SHOWSTATUS} . " "};
	/^STATUSONTOP$/ && do { $result .= "STATUSONTOP " . $self->{STATUSONTOP} . " "};
	/DOCDIRECTORY/ && do { $result .= "DOCDIRECTORY " . $q . $self->{DOCDIRECTORY} . $q . " "};
	/MAXNOATTRELEMS/ && do { $result .= "MAXNOATTRELEMS " . $self->{MAXNOATTRELEMS} . " "};
	/USEWHLOGINEXEC/ && do { $result .= "USEWHLOGINEXEC " . $self->{USEWHLOGINEXEC} . " "};
	/ENABLEOBJECTDELETION/ && do { $result .= "ENABLEOBJECTDELETION " . $self->{ENABLEOBJECTDELETION} . " "};
	/MAXREPORTEXECTIME/ && do { $result .= "MAXREPORTEXECTIME " . $self->{MAXREPORTEXECTIME} . " "};
	/MAXNOREPORTRESULTROWS/ && do { $result .= "MAXNOREPORTRESULTROWS " . $self->{MAXNOREPORTRESULTROWS} . " "};
	/MAXNOELEMROWS/ && do { $result .= "MAXNOELEMROWS " . $self->{MAXNOELEMROWS} . " "};
	/MAXNOINTRESULTROWS/ && do { $result .= "MAXNOINTRESULTROWS " . $self->{MAXNOINTRESULTROWS} . " "};
	/MAXJOBSUSERACCT/ && do { $result .= "MAXJOBSUSERACCT " . $self->{MAXJOBSUSERACCT} . " "};
	/MAXJOBSUSERSESSION/ && do { $result .= "MAXJOBSUSERSESSION " . $self->{MAXJOBSUSERSESSION} . " "};
	/MAXEXECJOBSUSER/ && do { $result .= "MAXEXECJOBSUSER " . $self->{MAXEXECJOBSUSER} . " "};
	/^MAXJOBSPROJECT$/ && do { $result .= "MAXJOBSPROJECT " . $self->{MAXJOBSPROJECT} . " "};
	/^MAXUSERSESSIONSPROJECT$/ && do { $result .= "MAXUSERSESSIONSPROJECT " . $self->{MAXUSERSESSIONSPROJECT} . " "};
	/PROJDRILLMAP/ && do { $result .= "PROJDRILLMAP " . $q . $self->{PROJDRILLMAP} . $q . " "};
	/DRILLMAP_LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{DRILLMAP_LOCATION} . $q . " "};
	/REPORTTPL/ && do { $result .= "REPORTTPL " . $q . $self->{REPORTTPL} . $q . " "};
	/REPORTSHOWEMPTYTPL/ && do { $result .= "REPORTSHOWEMPTYTPL " . $self->{REPORTSHOWEMPTYTPL} . " "};
	/^TEMPLATETPL$/i && do { $result .= "TEMPLATETPL " . $q . $self->{TEMPLATETPL} . $q . " "};
	/^TEMPLATESHOWEMPTYTPL$/ && do { $result .= "TEMPLATESHOWEMPTYTPL " . $self->{TEMPLATESHOWEMPTYTPL} . " "};
	/METRICTPL/ && do { $result .= "METRICTPL " . $q . $self->{METRICTPL} . $q . " "};
	/METRICSHOWEMPTYTPL/ && do { $result .= "METRICSHOWEMPTYTPL " . $self->{METRICSHOWEMPTYTPL} . " "};
	/^PROJECT$/ && do { $result .= "IN PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 alter_report_caching

    $foo->alter_report_caching(
        PROJECT                  => "project_name",
        ENABLED                  => "ENABLED" | "DISABLED",
        CACHEFILEDIR             => "cache_file_directory",
        MAXRAMUSAGE              => "number_of_Kb",
        MAXNOCACHES              => "number_of_Caches",
        LOADCACHESONSTARTUP      => "TRUE" | "FALSE",
        ENABLEPROMPTEDCACHING    => "TRUE" | "FALSE",
        ENABLENONPROMPTEDCACHING => "TRUE" | "FALSE",
        CREATECACHESPERUSER      => "TRUE" | "FALSE",
        CREATECACHESPERDBLOGIN   => "TRUE" | "FALSE",
        CREATECACHESPERDBCONN    => "TRUE" | "FALSE",
        CACHEEXP                 => "NEVER" | "IN number_of_hours HOURS"
    );


Optional parameters: 
        ENABLED                  => "ENABLED" | "DISABLED",
        CACHEFILEDIR             => "cache_file_directory",
        MAXRAMUSAGE              => "number_of_Kb",
        MAXNOCACHES              => "number_of_Caches",
        LOADCACHESONSTARTUP      => "TRUE" | "FALSE",
        ENABLEPROMPTEDCACHING    => "TRUE" | "FALSE",
        ENABLENONPROMPTEDCACHING => "TRUE" | "FALSE",
        CREATECACHESPERUSER      => "TRUE" | "FALSE",
        CREATECACHESPERDBLOGIN   => "TRUE" | "FALSE",
        CREATECACHESPERDBCONN    => "TRUE" | "FALSE",
        CACHEEXP                 => "NEVER" | "IN number_of_hours HOURS"
  
This command can be used only in 3-tier Project Source Names.

ALTER REPORT CACHING IN [PROJECT] "<project_name>" 
	[(ENABLED | DISABLED)] 
	[CACHEFILEDIR "<cache_file_directory>"] 
	[MAXRAMUSAGE <number_of_Kb>] 
	[MAXNOCACHES <number_of_Caches>] 
	[LOADCACHESONSTARTUP (TRUE | FALSE)] 
	[ENABLEPROMPTEDCACHING (TRUE | FALSE)] 
	[ENABLENONPROMPTEDCACHING (TRUE | FALSE)] 
	[CREATECACHESPERUSER (TRUE | FALSE)] 
	[CREATECACHESPERDBLOGIN (TRUE | FALSE)] 
	[CREATECACHESPERDBCONN (TRUE | FALSE)] 
	[CACHEEXP (NEVER | [IN] <number_of_hours> HOURS)];

ALTER REPORT CACHING IN PROJECT "MicroStrategy Tutorial" ENABLED CACHEFILEDIR ".\Caches\RAVALOS4" MAXRAMUSAGE 10240 CREATECACHESPERUSER FALSE CACHEEXP IN 24 HOURS MAXNOCACHES 10000;

=cut

sub alter_report_caching {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(PROJECT ENABLED CACHEFILEDIR MAXRAMUSAGE MAXNOCACHES LOADCACHESONSTARTUP ENABLEPROMPTEDCACHING ENABLENONPROMPTEDCACHING CREATECACHESPERUSER CREATECACHESPERDBLOGIN CREATECACHESPERDBCONN CACHEEXP);
my @required = qw(PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/PROJECT/ && do { $result .= "ALTER REPORT CACHING IN PROJECT " . $q . $self->{PROJECT} . $q . " "};
	/^ENABLED$/ && do { $result .= $self->{ENABLED} . " "};
	/CACHEFILEDIR/ && do { $result .= "CACHEFILEDIR " . $q . $self->{CACHEFILEDIR} . $q ." "};
	/MAXRAMUSAGE/ && do { $result .= "MAXRAMUSAGE " . $self->{MAXRAMUSAGE} . " "};
	/MAXNOCACHES/ && do { $result .= "MAXNOCACHES " . $self->{MAXNOCACHES} . " "};
	/LOADCACHESONSTARTUP/ && do { $result .= "LOADCACHESONSTARTUP " . $self->{LOADCACHESONSTARTUP} . " "};
	/^ENABLEPROMPTEDCACHING$/ && do { $result .= "ENABLEPROMPTEDCACHING " . $self->{ENABLEPROMPTEDCACHING} . " "};
	/^ENABLENONPROMPTEDCACHING$/ && do { $result .= "ENABLENONPROMPTEDCACHING " . $self->{ENABLENONPROMPTEDCACHING} . " "};
	/CREATECACHESPERUSER/ && do { $result .= "CREATECACHESPERUSER " . $self->{CREATECACHESPERUSER} . " "};
	/CREATECACHESPERDBLOGIN/ && do { $result .= "CREATECACHESPERDBLOGIN " . $self->{CREATECACHESPERDBLOGIN} . " "};
	/CREATECACHESPERDBCONN/ && do { $result .= "CREATECACHESPERDBCONN " . $self->{CREATECACHESPERDBCONN} . " "};
	/CACHEEXP/ && do { $result .= "CACHEEXP " . $self->{CACHEEXP} . " "};
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 alter_report

    $foo->alter_report(
        REPORT              => "report_name",
        LOCATION            => "location_path",
        ENABLECACHE         => "TRUE" | "FALSE" | "DEFAULT",
        NEW_NAME            => "new_report_name",
        NEW_LONGDESCRIPTION => "new_long_description",
        NEW_DESCRIPTION     => "new_description",
        NEW_LOCATION        => "new_location_path",
        HIDDEN              => "TRUE" | "FALSE",
        PROJECT             => "project_name"
    );


Optional parameters: 	
        ENABLECACHE         => "TRUE" | "FALSE" | "DEFAULT",
        NEW_NAME            => "new_report_name",
        NEW_LONGDESCRIPTION => "new_long_description",
        NEW_DESCRIPTION     => "new_description",
        NEW_LOCATION        => "new_location_path",
        HIDDEN              => "TRUE" | "FALSE",
        PROJECT             => "project_name"


ALTER REPORT "<report_name>" IN FOLDER "<location_path>" 
	[ENABLECACHE (TRUE | FALSE | DEFAULT)] 
	[NAME "<new_report_name>"] 
	[LONGDESCRIPTION "<new_long_description>"] 
	[DESCRIPTION "<new_description>"]  
	[FOLDER "<new_location_path>"] 
	[HIDDEN (TRUE | FALSE)] 
FOR PROJECT "<project_name>";

=cut

sub alter_report {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(REPORT LOCATION ENABLECACHE NEW_NAME NEW_LONGDESCRIPTION NEW_DESCRIPTION NEW_LOCATION HIDDEN PROJECT);
my @required = qw(REPORT LOCATION HIDDEN PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/REPORT/ && do { $result .= "ALTER REPORT " . $q . $self->{REPORT} . $q . " "};
	/^LOCATION$/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/ENABLECACHE/ && do { $result .= "ENABLECACHE " . $self->{ENABLECACHE} . " "};
	/NEW_NAME/ && do { $result .= "NAME " . $q . $self->{NEW_NAME} . $q . " "};
	/^NEW_LONGDESCRIPTION$/ && do { $result .= "LONGDESCRIPTION " . $q . $self->{NEW_LONGDESCRIPTION} . $q . " "};
	/^NEW_DESCRIPTION$/ && do { $result .= "DESCRIPTION " . $q . $self->{NEW_DESCRIPTION} . $q . " "};
	/^NEW_LOCATION$/ && do { $result .= "FOLDER " . $q . $self->{NEW_LOCATION} . $q . " "};
	/HIDDEN/ && do { $result .= "HIDDEN " . $self->{HIDDEN} . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 alter_schedule

    $foo->alter_schedule(
        SCHEDULE    => "schedule_name",
        NEW_NAME    => "new_name",
        DESCRIPTION => "new_description",
        STARTDATE   => "new_start_date",
        ENDDATE     => "new_end_date" | "NEVER",
        TYPE        => "EVENTTRIGGERED" | "TIMETRIGGERED",
        EVENTNAME   => "<new_event_name>",
        DAILY       => "EVERY (<new_number> DAYS | WEEKDAY)",
        WEEKLY      => "EVERY
    <new_number> WEEKS ON day_of_week1 [, day_of_week2 [,...
    day_of_week7]]", MONTHLY => "(DAY <new_number> OF EVERY <new_number>
    MONTHS (FIRST | SECOND | THIRD | FOURTH | LAST) (day_of_week1 |
    day_of_week2 | ... | day_of_week7) OF EVERY <new_number> MONTHS)",
        YEARLY => "((month_of_year1 | month_of_year2 | ... | month_of_year12)
    <new_number> (FIRST | SECOND | THIRD | FOURTH | LAST) (day_of_week1 |
    day_of_week2 | ... | day_of_week7) OF (month_of_year1 | month_of_year2 |
    ... | month_of_year12))" EXECUTE_TIME_OF_DAY => "new_time_of_day",
        EXECUTE_ALL_DAY => "EVERY <new_number> (MINUTES | HOURS [START AFTER
    MIDNIGHT <number> MINUTES] )",
    );

ALTER SCHEDULE "<schedule_name>" [NAME "<new_name>" [DESCRIPTION "<new_description>"] [STARTDATE <new_start_date>] [ENDDATE (<new_end_date> | NEVER)] [TYPE (EVENTTRIGGERED EVENTNAME "<new_event_name>" | TIMETRIGGERED (DAILY EVERY (<new_number> DAYS | WEEKDAY) | WEEKLY EVERY <new_number> WEEKS ON day_of_week1 [, day_of_week2 [,... day_of_week7]] | MONTHLY (DAY <new_number> OF EVERY <new_number> MONTHS | (FIRST | SECOND | THIRD | FOURTH | LAST) (day_of_week1 | day_of_week2 | ... | day_of_week7) OF EVERY <new_number> MONTHS) | YEARLY ((month_of_year1 | month_of_year2 | ... | month_of_year12) <new_number> | (FIRST | SECOND | THIRD | FOURTH | LAST) (day_of_week1 | day_of_week2 | ... | day_of_week7) OF (month_of_year1 | month_of_year2 | ... | month_of_year12))) [EXECUTE (<new_time_of_day> | ALL DAY EVERY <new_number> (MINUTES | HOURS [START AFTER MIDNIGHT <number> MINUTES]))])];

ALTER SCHEDULE "Schedule1" NAME "NewSchedule1" DESCRIPTION "NewSchedule1 Desc" STARTDATE 09/10/2002 ENDDATE NEVER TYPE TIMETRIGGERED YEARLY LAST WEDNESDAY OF MAY EXECUTE 15:30;

$foo->alter_schedule(	SCHEDULE => "Schedule1",
			NEW_NAME => "NewSchedule1", 
			DESCRIPTION => "NewSchedule1 Desc",
			STARTDATE => '09/10/2002',
			ENDDATE => "NEVER",
			TYPE => "TIMETRIGGERED",
			YEARLY => "LAST WEDNESDAY OF MAY",
			EXECUTE_TIME_OF_DAY => '15:30'
		    );

ALTER SCHEDULE "Database Load" STARTDATE 09/10/2002 ENDDATE NEVER TYPE EVENTTRIGGERED EVENTNAME "Database Load";
		    
    $foo->alter_schedule(
        SCHEDULE  => "Database Load",
        STARTDATE => '09/10/2002',
        ENDDATE   => "NEVER",
        TYPE      => "EVENTTRIGGERED",
        EVENTNAME => "Database Load"
    );

ALTER SCHEDULE "Schedule3" STARTDATE 09/10/2002 ENDDATE NEVER TYPE TIMETRIGGERED DAILY EVERY 5 DAYS EXECUTE 10:00;

    $foo->alter_schedule(
        SCHEDULE            => "Schedule3",
        STARTDATE           => '09/10/2002',
        ENDDATE             => "NEVER",
        TYPE                => "TIMETRIGGERED",
        DAILY               => "EVERY 5 DAYS",
        EXECUTE_TIME_OF_DAY => '10:00'
    );

ALTER SCHEDULE "Schedule4" STARTDATE 09/10/2002 ENDDATE NEVER TYPE TIMETRIGGERED DAILY EVERY WEEKDAY EXECUTE ALL DAY EVERY 5 MINUTES;

    $foo->alter_schedule(
        SCHEDULE        => "Schedule4",
        STARTDATE       => '09/10/2002',
        ENDDATE         => "NEVER",
        TYPE            => "TIMETRIGGERED",
        DAILY           => "EVERY WEEKDAY",
        EXECUTE_ALL_DAY => "EVERY 5 MINUTES"
    );

ALTER SCHEDULE "Schedule5" STARTDATE 09/10/2002 ENDDATE NEVER TYPE TIMETRIGGERED WEEKLY EVERY 5 WEEKS ON MONDAY, TUESDAY, WEDNESDAY EXECUTE 18:00;

    $foo->alter_schedule(
        SCHEDULE            => "Schedule5",
        STARTDATE           => '09/10/2002',
        ENDDATE             => "NEVER",
        TYPE                => "TIMETRIGGERED",
        WEEKLY              => "EVERY 5 WEEKS ON MONDAY, TUESDAY, WEDNESDAY",
        EXECUTE_TIME_OF_DAY => '18:00',
    );

ALTER SCHEDULE "Schedule6" STARTDATE 09/10/2002 ENDDATE 09/27/02 TYPE TIMETRIGGERED MONTHLY DAY 3 OF EVERY 5 MONTHS EXECUTE ALL DAY EVERY 5 HOURS START AFTER MIDNIGHT 10 MINUTES;

   $foo->alter_schedule(
        SCHEDULE        => "Schedule6",
        STARTDATE       => '09/10/2002',
        ENDDATE         => '09/27/02',
        TYPE            => "TIMETRIGGERED",
        MONTHLY         => "DAY 3 OF EVERY 5 MONTHS",
        EXECUTE_ALL_DAY => "EVERY 5 HOURS START AFTER MIDNIGHT 10 MINUTES",
    );

ALTER SCHEDULE "Schedule7" STARTDATE 09/10/2002 ENDDATE NEVER TYPE TIMETRIGGERED MONTHLY FIRST THURSDAY OF EVERY 10 MONTHS EXECUTE 13:00;

    $foo->alter_schedule(
        SCHEDULE            => "Schedule7",
        STARTDATE           => '09/10/2002',
        ENDDATE             => "NEVER",
        TYPE                => "TIMETRIGGERED",
        MONTHLY             => "FIRST THURSDAY OF EVERY 10 MONTHS",
        EXECUTE_TIME_OF_DAY => "13:00",
    );

ALTER SCHEDULE "Schedule8" STARTDATE 09/10/2002 ENDDATE NEVER TYPE TIMETRIGGERED YEARLY MARCH 10 EXECUTE 17:00;

    $foo->alter_schedule(
        SCHEDULE            => "Schedule8",
        STARTDATE           => '09/10/2002',
        ENDDATE             => "NEVER",
        TYPE                => "TIMETRIGGERED",
        YEARLY              => "MARCH 10",
        EXECUTE_TIME_OF_DAY => "17:00",
    );

ALTER SCHEDULE "Schedule9" STARTDATE 09/10/2002 ENDDATE NEVER TYPE TIMETRIGGERED YEARLY SECOND SATURDAY OF MAY EXECUTE 09:00;
		    
    $foo->alter_schedule(
        SCHEDULE            => "Schedule9",
        STARTDATE           => "09/10/2002",
        ENDDATE             => "NEVER",
        TYPE                => "TIMETRIGGERED",
        YEARLY              => "SECOND SATURDAY OF MAY",
        EXECUTE_TIME_OF_DAY => "09:00",
    );

=cut

sub alter_schedule {
	my $self = shift;
	$self->{SCHEDULE_ACTION} = "ALTER SCHEDULE ";
	$self->schedule(@_);
}

=head2 alter_security_filter

    $foo->alter_security_filter(
        SECURITY_FILTER       => "sec_filter_name",
        LOCATION              => "location_path",
        HIDDEN                => "TRUE" | "FALSE",
        PROJECT               => "project_name",
        NEW_NAME              => "new_sec_filter_name",
        FILTER                => "FILTER_NAME",
        FILTER_LOCATION       => "FILTER_LOCATION_PATH",
        EXPRESSION            => "NEW_EXPRESSION",
        TOP_ATTRIBUTE_LIST    => [ "top_attr_name1", "top_attr_nameN" ],
        BOTTOM_ATTRIBUTE_LIST => [ "bottom_attr_name1", "bottom_attr_nameN" ]
    );

Optional parameters: 
        LOCATION              => "location_path",
        HIDDEN                => "TRUE" | "FALSE",
        NEW_NAME              => "new_sec_filter_name",
        FILTER                => "FILTER_NAME",
        FILTER_LOCATION       => "FILTER_LOCATION_PATH",
        EXPRESSION            => "NEW_EXPRESSION",
        TOP_ATTRIBUTE_LIST    => [ "top_attr_name1", "top_attr_nameN" ],
        BOTTOM_ATTRIBUTE_LIST => [ "bottom_attr_name1", "bottom_attr_nameN" ]

ALTER SECURITY FILTER "<sec_filter_name>" [FOLDER "<location_path>"] [HIDDEN (TRUE | FALSE)] IN [PROJECT] "<project_name>" [NAME "<new_sec_filter_name>"] [(FILTER "<filter_name>" [IN FOLDER "<filter_location_path>"] | EXPRESSION "<new_expression>")] [TOP ATTRIBUTE LIST "<top_attr_name1>" [, "<top_attr_name2>" [, ... "<top_attr_nameN>"]]] [BOTTOM ATTRIBUTE LIST "<bottom_attr_name1>" [, "<bottom_attr_name2>" [, ... "<bottom_attr_nameN>"]]];

=cut

sub alter_security_filter {
	my $self = shift;
	$self->{ACTION} = "ALTER ";
	$self->security_filter(@_);
}



=head2 alter_security_role

    $foo->alter_security_role(
        SECURITY_ROLE => "sec_role_name",
        NAME          => "new_sec_role_name",
        DESCRIPTION   => "sec_role_description"
    );

Optional parameters: 
        NAME          => "new_sec_role_name",
        DESCRIPTION   => "sec_role_description"


ALTER SECURITY ROLE "<sec_role_name>" [NAME "<new_sec_role_name>"] [DESCRIPTION "<sec_role_description>"];

=cut

sub alter_security_role {
	my $self = shift;
	$self->{ACTION} = "ALTER ";
	$self->security_role(@_);
}

=head2 alter_server_config

This command can be used only in 3-tier Project Source Names.

    $foo->alter_server_config(
        DESCRIPTION              => "description",
        MAXCONNECTIONTHREADS     => "number_of_threads",
        BACKUPFREQ               => "number_of_minutes",
        USEPERFORMANCEMON        => "TRUE" | "FALSE",
        USEMSTRSCHEDULER         => "TRUE" | "FALSE",
        SCHEDULERTIMEOUT         => "seconds",
        BALSERVERTHREADS         => "TRUE" | "FALSE",
        CACHECLEANUPFREQ         => "seconds",
        LICENSECHECKTIME         => "time_of_day",
        HISTORYDIR               => "folder_path",
        MAXNOMESSAGES            => "number_of_messages",
        MESSAGELIFETIME          => "days",
        MAXNOJOBS                => "number_of_jobs",
        MAXNOCLIENTCONNS         => "number_of_client_conns",
        IDLETIME                 => "number_of_seconds",
        WEBIDLETIME              => "number_of_seconds",
        MAXNOXMLCELLS            => "number_of_xml_cells",
        MAXNOXMLDRILLPATHS       => "number_of_xml_drill_paths",
        MAXMEMXML                => "number_MBytes",
        MAXMEMPDF                => "number_MBytes",
        MAXMEMEXCEL              => "number_MBytes",
        ENABLEWEBTHROTTLING      => "TRUE" | "FALSE",
        MAXMEMUSAGE              => "percentage",
        MINFREEMEM               => "percentage",
        ENABLEMEMALLOC           => "TRUE" | "FALSE",
        MAXALLOCSIZE             => "number_MBytes",
        ENABLEMEMCONTRACT        => "TRUE" | "FALSE",
        MINRESERVEDMEM           => "NUMBER_MBYTES",
        MINRESERVEDMEMPERCENTAGE => "PERCENTAGE",
        MAXVIRTUALADDRSPACE      => "percentage",
        MEMIDLETIME              => "seconds",
        WORKSETDIR               => "folder_path",
        MAXRAMWORKSET            => "number_KBytes"
    );

Optional parameters: ALL PARAMETERS ARE OPTIONAL.

ALTER SERVER CONFIGURATION 
	[DESCRIPTION "<description>"] 
	[MAXCONNECTIONTHREADS <number_of_threads>] 
	[BACKUPFREQ <number_of_minutes>] 
	[USEPERFORMANCEMON (FALSE | TRUE)] 
	[USEMSTRSCHEDULER (FALSE | TRUE)] 
	[SCHEDULERTIMEOUT <seconds>] 
	[BALSERVERTHREADS (FALSE | TRUE)] 
	[CACHECLEANUPFREQ <seconds>] 
	[LICENSECHECKTIME <time_of_day>] 
	[HISTORYDIR "<folder_path>"] 
	[MAXNOMESSAGES <number_of_messages>] 
	[MESSAGELIFETIME <days>] 
	[MAXNOJOBS <number_of_jobs>] 
	[MAXNOCLIENTCONNS <number_of_client_conns>] 
	[IDLETIME <number_of_seconds>] 
	[WEBIDLETIME <number_of_seconds>] 
	[MAXNOXMLCELLS <number_of_xml_cells>] 
	[MAXNOXMLDRILLPATHS <number_of_xml_drill_paths>] 
	[MAXMEMXML number_MBytes] 
	[MAXMEMPDF number_MBytes] 
	[MAXMEMEXCEL number_MBytes] 
	[ENABLEWEBTHROTTLING (TRUE | FALSE)] 
	[MAXMEMUSAGE <percentage>] 
	[MINFREEMEM <percentage>] 
	[ENABLEMEMALLOC (TRUE | FALSE)] 
	[MAXALLOCSIZE <number_MBytes>] 
	[ENABLEMEMCONTRACT (TRUE | FALSE)] 
	[(MINRESERVEDMEM <number_MBytes> | MINRESERVEDMEMPERCENTAGE <percentage>)] 
	[MAXVIRTUALADDRSPACE <percentage>] 
	[MEMIDLETIME <seconds>] 
	[WORKSETDIR "<folder_path>"] 
	[MAXRAMWORKSET <number_KBytes>];

ALTER SERVER CONFIGURATION MAXCONNECTIONTHREADS 5 BACKUPFREQ 0 USEPERFORMANCEMON TRUE USEMSTRSCHEDULER TRUE BALSERVERTHREADS FALSE HISTORYDIR ".\INBOX\dsmith" MAXNOMESSAGES 10 MAXNOJOBS 10000 MAXNOCLIENTCONNS 500 WEBIDLETIME 0 MAXNOXMLCELLS 500000 MAXNOXMLDRILLPATHS 100 MINFREEMEM 0;

=cut

sub alter_server_config {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(DESCRIPTION MAXCONNECTIONTHREADS BACKUPFREQ USEPERFORMANCEMON USEMSTRSCHEDULER SCHEDULERTIMEOUT BALSERVERTHREADS CACHECLEANUPFREQ LICENSECHECKTIME HISTORYDIR MAXNOMESSAGES MESSAGELIFETIME MAXNOJOBS MAXNOCLIENTCONNS IDLETIME WEBIDLETIME MAXNOXMLCELLS MAXNOXMLDRILLPATHS MAXMEMXML MAXMEMPDF MAXMEMEXCEL ENABLEWEBTHROTTLING MAXMEMUSAGE MINFREEMEM ENABLEMEMALLOC MAXALLOCSIZE ENABLEMEMCONTRACT MINRESERVEDMEM MINRESERVEDMEMPERCENTAGE MAXVIRTUALADDRSPACE MEMIDLETIME WORKSETDIR MAXRAMWORKSET);
my @required = qw();
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/DESCRIPTION/ && do { $result .= "ALTER SERVER CONFIGURATION DESCRIPTION " . $q . $self->{DESCRIPTION} . $q . " "};
	/MAXCONNECTIONTHREADS/ && do { $result .= "MAXCONNECTIONTHREADS " . $self->{MAXCONNECTIONTHREADS} . " "};
	/BACKUPFREQ/ && do { $result .= "BACKUPFREQ " . $self->{BACKUPFREQ} . " "};
	/USEPERFORMANCEMON/ && do { $result .= "USEPERFORMANCEMON " . $self->{USEPERFORMANCEMON} . " "};
	/USEMSTRSCHEDULER/ && do { $result .= "USEMSTRSCHEDULER " . $self->{USEMSTRSCHEDULER} . " "};
	/SCHEDULERTIMEOUT/ && do { $result .= "SCHEDULERTIMEOUT " . $self->{SCHEDULERTIMEOUT} . " "};
	/BALSERVERTHREADS/ && do { $result .= "BALSERVERTHREADS " . $self->{BALSERVERTHREADS} . " "};
	/CACHECLEANUPFREQ/ && do { $result .= "CACHECLEANUPFREQ " . $self->{CACHECLEANUPFREQ} . " "};
	/LICENSECHECKTIME/ && do { $result .= "LICENSECHECKTIME " . $self->{LICENSECHECKTIME} . " "};
	/HISTORYDIR/ && do { $result .= "HISTORYDIR " . $q . $self->{HISTORYDIR} . $q . " "};
	/MAXNOMESSAGES/ && do { $result .= "MAXNOMESSAGES " . $self->{MAXNOMESSAGES} . " "};
	/MESSAGELIFETIME/ && do { $result .= "MESSAGELIFETIME " . $self->{MESSAGELIFETIME} . " "};
	/MAXNOJOBS/ && do { $result .= "MAXNOJOBS " . $self->{MAXNOJOBS} . " "};
	/MAXNOCLIENTCONNS/ && do { $result .= "MAXNOCLIENTCONNS " . $self->{MAXNOCLIENTCONNS} . " "};
	/^IDLETIME$/ && do { $result .= "IDLETIME " . $self->{IDLETIME} . " "};
	/^WEBIDLETIME$/ && do { $result .= "WEBIDLETIME " . $self->{WEBIDLETIME} . " "};
	/MAXNOXMLCELLS/ && do { $result .= "MAXNOXMLCELLS " . $self->{MAXNOXMLCELLS} . " "};
	/MAXNOXMLDRILLPATHS/ && do { $result .= "MAXNOXMLDRILLPATHS " . $self->{MAXNOXMLDRILLPATHS} . " "};
	/MAXMEMXML/ && do { $result .= "MAXMEMXML " . $self->{MAXMEMXML} . " "};
	/MAXMEMPDF/&& do { $result .= "MAXMEMPDF " . $self->{MAXMEMPDF} . " "};
	/MAXMEMEXCEL/&& do { $result .= "MAXMEMEXCEL " . $self->{MAXMEMEXCEL} . " "};	
	/ENABLEWEBTHROTTLING/ && do { $result .= "ENABLEWEBTHROTTLING " . $self->{ENABLEWEBTHROTTLING} . " "};
	/MAXMEMUSAGE/ && do { $result .= "MAXMEMUSAGE " . $self->{MAXMEMUSAGE} . " "};
	/MINFREEMEM/ && do { $result .= "MINFREEMEM " . $self->{MINFREEMEM} . " "};
	/ENABLEMEMALLOC/ && do { $result .= "ENABLEMEMALLOC " . $self->{ENABLEMEMALLOC} . " "};
	/MAXALLOCSIZE/ && do { $result .= "MAXALLOCSIZE " . $self->{MAXALLOCSIZE} . " "};
	/ENABLEMEMCONTRACT/ && do { $result .= "ENABLEMEMCONTRACT " . $self->{ENABLEMEMCONTRACT} . " "};
	/^MINRESERVEDMEM$/ && do { $result .= "MINRESERVEDMEM " . $self->{MINRESERVEDMEM} . " "};
	/^MINRESERVEDMEMPERCENTAGE$/ && do { $result .= "MINRESERVEDMEMPERCENTAGE " . $self->{MINRESERVEDMEMPERCENTAGE} . " "};
	/MAXVIRTUALADDRSPACE/ && do { $result .= "MAXVIRTUALADDRSPACE " . $self->{MAXVIRTUALADDRSPACE} . " "};
	/MEMIDLETIME/ && do { $result .= "MEMIDLETIME " . $self->{MEMIDLETIME} . " "};
	/WORKSETDIR/ && do { $result .= "WORKSETDIR " . $q . $self->{WORKSETDIR} . $q . " "};
	/MAXRAMWORKSET/ && do { $result .= "MAXRAMWORKSET " . $self->{MAXRAMWORKSET} . " "};
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 alter_shortcut

    $foo->alter_shortcut(
        LOCATION              => "location_path",
        PROJECT_CONFIG_OBJECT => "project_config_object",
        SHORTCUT_NAME         => "shortcut_name",
        NEW_LOCATION          => "new_location_path",
        HIDDEN                => "TRUE" | "FALSE",
        PROJECT               => "project_name"
    );

Optional parameters: FOLDER => "<new_location_path>",HIDDEN => (TRUE | FALSE)

ALTER SHORTCUT IN FOLDER "<location_path>"  FOR (FOLDER | CONSOLIDATION | DOCUMENT | FILTER | METRIC | PROMPT | REPORT | SEARCH | TEMPLATE | ATTRIBUTE | FACT | FUNCTION | HIERARCHY | TABLE | TRANSFORMATION | DRILLMAP | SECFILTER | AUTOSTYLE | BASEFORMULA) "<shortcut_name>" [FOLDER "<new_location_path>"] [HIDDEN (TRUE | FALSE)] FOR PROJECT "<project_name>" ;

Note: This is the object hierarchy used in shortcut management. To create a shortcut off any object at lower hierarchy, just specify the name of the object at the top level.
TABLE:
·	LOGICAL TABLE
·	WAREHOUSE PARTITION TABLE
·	METADATA PARTITION TABLE
METRIC:
·	SUBTOTAL
·	PREDICTIVE METRIC
FILTER:
·	CUSTOMGROUP
REPORT:
·	GRID
·	GRAPH
·	GRIDGRAPH
·	DATAMART
·	SQL
DOCUMENT:
·	REPORTSERVICE DOCUMENT
·	HTML DOCUMENT

=cut

sub alter_shortcut {
	my $self = shift;
	$self->{ACTION} = "ALTER ";
	$self->shortcut(@_);
}


=head2 alter_statistics

    $foo->alter_statistics(
        DBINSTANCE      => "stats_dbinstance",
        ENABLED         => "ENABLED" | "DISABLED",
        USERSESSIONS    => "TRUE" | "FALSE",
        PROJECTSESSIONS => "TRUE" | "FALSE",
        BASICDOCJOBS    => "TRUE" | "FALSE",
        DETAILEDDOCJOBS => "TRUE" | "FALSE",
        BASICREPJOBS    => "TRUE" | "FALSE",
        CACHES          => "TRUE" | "FALSE",
        SCHEDULES       => "TRUE" | "FALSE",
        COLUMNSTABLES   => "TRUE" | "FALSE",
        DETAILEDREPJOBS => "TRUE" | "FALSE",
        JOBSQL          => "TRUE" | "FALSE",
        SECFILTERS      => "TRUE" | "FALSE",
        PROJECT         => "project_name"
    );

Optional parameters: 
        DBINSTANCE      => "stats_dbinstance",
        USERSESSIONS    => "TRUE" | "FALSE",
        PROJECTSESSIONS => "TRUE" | "FALSE",
        BASICDOCJOBS    => "TRUE" | "FALSE",
        DETAILEDDOCJOBS => "TRUE" | "FALSE",
        BASICREPJOBS    => "TRUE" | "FALSE",
        CACHES          => "TRUE" | "FALSE",
        SCHEDULES       => "TRUE" | "FALSE",
        COLUMNSTABLES   => "TRUE" | "FALSE",
        DETAILEDREPJOBS => "TRUE" | "FALSE",
        JOBSQL          => "TRUE" | "FALSE",
        SECFILTERS      => "TRUE" | "FALSE"


This command can be used only in 3-tier Project Source Names.

ALTER STATISTICS [DBINSTANCE "<stats_dbinstance>"] (ENABLED | DISABLED) [USERSESSIONS (TRUE | FALSE)] [PROJECTSESSIONS (TRUE | FALSE)] [BASICDOCJOBS (TRUE | FALSE)] [DETAILEDDOCJOBS (TRUE | FALSE) [BASICREPJOBS (TRUE | FALSE)] [CACHES (TRUE | FALSE)] [SCHEDULES (TRUE | FALSE)] [COLUMNSTABLES (TRUE | FALSE)] [DETAILEDREPJOBS (TRUE | FALSE)] [JOBSQL (TRUE | FALSE)]
[SECFILTERS (TRUE | FALSE)] IN PROJECT "<project_name>";

ALTER STATISTICS DBINSTANCE "Tutorial Data" ENABLED USERSESSIONS TRUE PROJECTSESSIONS TRUE BASICDOCJOBS TRUE DETAILEDDOCJOBS TRUE BASICREPJOBS TRUE CACHES TRUE SCHEDULES TRUE COLUMNSTABLES TRUE DETAILEDREPJOBS TRUE JOBSQL TRUE SECFILTERS TRUE IN PROJECT "MT";

    $foo->alter_statistics(
        DBINSTANCE      => "Tutorial Data",
        ENABLED         => "ENABLED",
        USERSESSIONS    => "TRUE",
        PROJECTSESSIONS => "TRUE",
        BASICDOCJOBS    => "TRUE",
        DETAILEDDOCJOBS => "TRUE",
        BASICREPJOBS    => "TRUE",
        CACHES          => "TRUE",
        SCHEDULES       => "TRUE",
        COLUMNSTABLES   => "TRUE",
        DETAILEDREPJOBS => "TRUE",
        JOBSQL          => "TRUE",
        SECFILTERS      => "TRUE",
        PROJECT         => "MT"
    );

			
=cut

sub alter_statistics {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(DBINSTANCE ENABLED USERSESSIONS PROJECTSESSIONS BASICDOCJOBS DETAILEDDOCJOBS BASICREPJOBS CACHES SCHEDULES COLUMNSTABLES DETAILEDREPJOBS JOBSQL SECFILTERS PROJECT);
my @required = qw(PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("Required parameter not defined: " , $_); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/DBINSTANCE/ && do { $result .= "ALTER STATISTICS DBINSTANCE " . $q . $self->{DBINSTANCE} . $q . " "};
	/ENABLED/ && do { $result .= $self->{ENABLED} . " "};
	/USERSESSIONS/ && do { $result .= "USERSESSIONS " . $self->{USERSESSIONS} . " "};
	/^PROJECTSESSIONS$/ && do { $result .= "PROJECTSESSIONS " . $self->{PROJECTSESSIONS} . " "};
	/BASICDOCJOBS/ && do { $result .= "BASICDOCJOBS " . $self->{BASICDOCJOBS} . " "};
	/DETAILEDDOCJOBS/ && do { $result .= "DETAILEDDOCJOBS " . $self->{DETAILEDDOCJOBS} . " "};
	/BASICREPJOBS/ && do { $result .= "BASICREPJOBS " . $self->{BASICREPJOBS} . " "};
	/CACHES/ && do { $result .= "CACHES " . $self->{CACHES} . " "};
	/SCHEDULES/ && do { $result .= "SCHEDULES " . $self->{SCHEDULES} . " "};
	/COLUMNSTABLES/ && do { $result .= "COLUMNSTABLES " . $self->{COLUMNSTABLES} . " "};
	/DETAILEDREPJOBS/i && do { $result .= "DETAILEDREPJOBS " . $self->{DETAILEDREPJOBS} . " "};
	/JOBSQL/ && do { $result .= "JOBSQL " . $self->{JOBSQL} . " "};
	/SECFILTERS/ && do { $result .= "SECFILTERS " . $self->{SECFILTERS} . " "};
	/^PROJECT$/ && do { $result .= "IN PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 alter_table

    $foo->alter_table(
        TABLE               => "table_name",
        NEW_NAME            => "new_table_name",
        NEW_DESCRIPTION     => "new_description",
        NEW_LOCATION        => "new_location_path",
        HIDDEN              => "TRUE" | "FALSE",
        LOGICALSIZE         => "logical_size",
        PRESERVELOGICALSIZE => "TRUE" | "FALSE",
        PROJECT             => "project_name"
    );


Optional parameters: 
        NEW_NAME            => "new_table_name",
        NEW_DESCRIPTION     => "new_description",
        NEW_LOCATION        => "new_location_path",
        HIDDEN              => "TRUE" | "FALSE",
        LOGICALSIZE         => "logical_size",
        PRESERVELOGICALSIZE => "TRUE" | "FALSE",

ALTER TABLE "<table_name>" [NAME "<new_table_name>"] [DESCRIPTION "<new_description>"] [FOLDER "<new_location_path>"] [HIDDEN (TRUE | FALSE)] [LOGICALSIZE <logical_size>] [PRESERVELOGICALSIZE (TRUE | FALSE)] FOR PROJECT "<project_name>";

Warehouse Partition Table and Non_Relational Table are not supported.

Note that the keyword FOLDER in ALTER TABLE specifies the location where a table is going to be moved to not the location where the table is currently located.

Warehouse table names are case sensitive; logical table names are not case sensitive.

ALTER TABLE "DT_QUARTER" NAME "2" DESCRIPTION "1" FOLDER "\Schema Objects\Tables\New Tables" HIDDEN FALSE LOGICALSIZE 10 PRESERVELOGICALSIZE TRUE FOR PROJECT "MT";

    $foo->alter_table(
        TABLE           => "DT_QUARTER",
        NEW_NAME        => "2",
        NEW_DESCRIPTION => "1",
        NEW_LOCATION    => '\Schema Objects\Tables\New Tables',
        HIDDEN              => "FALSE",
        LOGICALSIZE         => 10,
        PRESERVELOGICALSIZE => "TRUE",
        PROJECT             => "MT"
      );

=cut

sub alter_table {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(TABLE NEW_NAME NEW_DESCRIPTION NEW_LOCATION HIDDEN LOGICALSIZE PRESERVELOGICALSIZE PROJECT);
my @required = qw(TABLE PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/TABLE/ && do { $result .= "ALTER TABLE " . $q . $self->{TABLE} . $q . " "};
	/NEW_NAME/ && do { $result .= "NAME " . $q . $self->{NEW_NAME} . $q . " "};
	/NEW_DESCRIPTION/ && do { $result .= "DESCRIPTION " . $q . $self->{NEW_DESCRIPTION} . $q . " "};
	/NEW_LOCATION/ && do { $result .= "FOLDER " . $q . $self->{NEW_LOCATION} . $q . " "};
	/HIDDEN/ && do { $result .= "HIDDEN " . $self->{HIDDEN} . " "};
	/^LOGICALSIZE$/ && do { $result .= "LOGICALSIZE " . $self->{LOGICALSIZE} . " "};
	/^PRESERVELOGICALSIZE$/ && do { $result .= "PRESERVELOGICALSIZE " . $self->{PRESERVELOGICALSIZE} . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 alter_user_group

    $foo->alter_user_group(
        USER_GROUP   => "user_group_name",
        NEW_NAME     => "new_user_group_name",
        DESCRIPTION  => "user_group_desc",
        LDAPLINK     => "ldap_user_id",
        MEMBERS      => [ "login_name1", "login_nameN" ],
        PARENT_GROUP => "parent_group"
    );

Optional parameters: NAME => "<new_user_group_name>",DESCRIPTION => "<user_group_desc>",LDAPLINK => "<ldap_user_id>",MEMBERS => "<login_name1>" , "<login_name2>" , ... "<login_nameN>",GROUP => "<parent_group>"

ALTER USER GROUP "<user_group_name>" [NAME "<new_user_group_name>"] [DESCRIPTION "<user_group_desc>"] [LDAPLINK "<ldap_user_id>"] [MEMBERS "<login_name1>" [, "<login_name2>" [, ... "<login_nameN>"]]] [GROUP "<parent_group>"];

ALTER USER GROUP "Managers" DESCRIPTION "Managers of XYZ Company";

=cut

sub alter_user_group {
	my $self = shift;
	$self->{ACTION} = "ALTER ";
	$self->user_group(@_);
}

=head2 alter_user

    $foo->alter_user(
        USER           => "login_name",
        NAME           => "new_login_name",
        NTLINK         => "nt_user_id",
        PASSWORD       => "user_password",
        FULLNAME       => "user_fullname",
        DESCRIPTION    => "user_description",
        LDAPLINK       => "ldap_user_id",
        WHLINK         => "warehouse_login",
        WHPASSWORD     => "warehouse_password",
        ALLOWCHANGEPWD => "TRUE" | "FALSE",
        ALLOWSTDAUTH   => "TRUE" | "FALSE",
        CHANGEPWD      => "TRUE" | "FALSE",
        PASSWORDEXP    => "NEVER" | "IN new_number_of_days DAYS" | "ON expiration_date",
        PASSWORDEXPFREQ => "number",
        ENABLED         => "ENABLED" | "DISABLED",
        GROUP           => "user_group_name"
    );

Optional parameters: 
        NAME           => "new_login_name",
        NTLINK         => "nt_user_id",
        PASSWORD       => "user_password",
        FULLNAME       => "user_fullname",
        DESCRIPTION    => "user_description",
        LDAPLINK       => "ldap_user_id",
        WHLINK         => "warehouse_login",
        WHPASSWORD     => "warehouse_password",
        ALLOWCHANGEPWD => "TRUE" | "FALSE",
        ALLOWSTDAUTH   => "TRUE" | "FALSE",
        CHANGEPWD      => "TRUE" | "FALSE",
        PASSWORDEXP    => "NEVER" | "IN new_number_of_days DAYS" | "ON expiration_date",
        PASSWORDEXPFREQ => "number",
        ENABLED         => "ENABLED" | "DISABLED",
        GROUP           => "user_group_name"


ALTER USER "<login_name>" 	[NAME "<new_login_name>"] 
				[NTLINK "<nt_user_id>"] 
				[PASSWORD "<user_password>"] 
				[FULLNAME "<user_fullname>"] 
				[DESCRIPTION "<user_description>"] 
				[LDAPLINK "<ldap_user_id>"] 
				[WHLINK "<warehouse_login>"] 
				[WHPASSWORD "<warehouse_password>"] 
				[ALLOWCHANGEPWD (TRUE | FALSE)] 
				[ALLOWSTDAUTH (TRUE | FALSE)] 
				[CHANGEPWD (TRUE | FALSE)] 
				[PASSWORDEXP (NEVER | IN new_number_of_days DAYS | ON <expiration_date>)] 
				[PASSWORDEXPFREQ <number> DAYS] 
				[ENABLED | DISABLED] 
				[IN GROUP "<user_group_name>"];

=cut

sub alter_user {
	my $self = shift;
	$self->{ACTION} = "ALTER ";
	$self->user(@_);
}

=head2 alter_users

    $foo->alter_users(
        USER_GROUP     => "user_group_name",
        PASSWORD       => "new_password",
        DESCRIPTION    => "new_user_description",
        ALLOWCHANGEPWD => "TRUE" | "FALSE",
        ALLOWSTDAUTH   => "TRUE" | "FALSE",
        CHANGEPWD      => "TRUE" | "FALSE",
        PASSWORDEXP    => "NEVER" | "new_number_of_days" | "new_expiration_date",
        PASSWORDEXPFREQ => "number_of_days",
        ENABLED         => "ENABLED | DISABLED",
        GROUP           => "new_user_group"
    );


Optional parameters: 
        PASSWORD       => "new_password",
        DESCRIPTION    => "new_user_description",
        ALLOWCHANGEPWD => "TRUE" | "FALSE",
        ALLOWSTDAUTH   => "TRUE" | "FALSE",
        CHANGEPWD      => "TRUE" | "FALSE",
        PASSWORDEXP    => "NEVER" | "new_number_of_days" | "new_expiration_date",
        PASSWORDEXPFREQ => "number_of_days",
        ENABLED         => "ENABLED | DISABLED",
        GROUP           => "new_user_group"

ALTER USERS IN USER GROUP "<user_group_name>" 	
		[PASSWORD "<new_password>"] 
		[DESCRIPTION "<new_user_description>"] 
		[ALLOWCHANGEPWD (TRUE | FALSE)] 
		[ALLOWSTDAUTH (TRUE | FALSE)] 
		[CHANGEPWD (TRUE | FALSE)] 
		[PASSWORDEXP (NEVER | [IN] <new_number_of_days> DAYS |[ON] <new_expiration_date>] 
		[PASSWORDEXPFREQ <number> DAYS] 
		[(ENABLED | DISABLED] 
		[GROUP "<new_user_group>"];

ALTER USERS IN USER GROUP "Managers" PASSWORD "test" CHANGEPWD TRUE PASSWORDEXP IN 5 DAYS PASSWORDEXPFREQ 90 DAYS;

=cut

sub alter_users {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(USER_GROUP PASSWORD DESCRIPTION ALLOWCHANGEPWD ALLOWSTDAUTH CHANGEPWD PASSWORDEXP PASSWORDEXPFREQ ENABLED GROUP);
my @required = qw(USER_GROUP);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/^USER_GROUP$/ && do { $result .= "ALTER USERS IN USER GROUP " . $q . $self->{USER_GROUP} . $q . " "};
	/^PASSWORD$/ && do { $result .= "PASSWORD " . $q . $self->{PASSWORD} . $q . " "};
	/DESCRIPTION/ && do { $result .= "DESCRIPTION " . $q . $self->{DESCRIPTION} . $q . " "};
	/ALLOWCHANGEPWD/ && do { $result .= "ALLOWCHANGEPWD " . $self->{ALLOWCHANGEPWD} . " "};
	/ALLOWSTDAUTH/ && do { $result .= "ALLOWSTDAUTH " . $self->{ALLOWSTDAUTH} . " "};
	/CHANGEPWD/ && do { $result .= "CHANGEPWD " . $self->{CHANGEPWD} . " "};
	/^PASSWORDEXP$/ && do { $result .= "PASSWORDEXP " . $self->{PASSWORDEXP} . " "};
	/^PASSWORDEXPFREQ$/ && do { $result .= "PASSWORDEXPFREQ " . $self->{PASSWORDEXPFREQ} . " "};
	/ENABLED/ && do { $result .= $self->{ENABLED} . " "};
	/^GROUP$/ && do { $result .= "IN GROUP " . $q . $self->{GROUP} . $q . " "};
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 apply_run_time_settings;

$foo->apply_run_time_settings;

This command can be used only in 3-tier Project Source Names. 

APPLY RUN TIME SETTINGS;

=cut

sub apply_run_time_settings { return "APPLY RUN TIME SETTINGS;"; }

=head2 apply_security_filter

    $foo->apply_security_filter(
        SECURITY_FILTER          => "sec_filter_name",
        LOCATION                 => "location_path",
        USER_OR_GROUP            => "USER" | "GROUP",
        USER_LOGIN_OR_GROUP_NAME => "login_name_or_group_name",
        PROJECT                  => "project_name"
    );


Optional parameters: 
        LOCATION                 => "location_path",
        USER_OR_GROUP            => "USER" | "GROUP",
        USER_LOGIN_OR_GROUP_NAME => "login_name_or_group_name"

APPLY SECURITY FILTER "<sec_filter_name>" [FOLDER "<location_path>"] TO ([USER] "<login_name>" | [USER] GROUP "<group_name>") ON [PROJECT] "<project_name>";

=cut

sub apply_security_filter {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(SECURITY_FILTER LOCATION USER_OR_GROUP USER_LOGIN_OR_GROUP_NAME PROJECT);
my @required = qw(SECURITY_FILTER USER_OR_GROUP USER_LOGIN_OR_GROUP_NAME PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/SECURITY_FILTER/ && do { $result .= "APPLY SECURITY FILTER " . $q . $self->{SECURITY_FILTER} . $q . " "};
	/LOCATION/ && do { $result .= "FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/USER_OR_GROUP/ && do { $result .= "TO " . $self->{USER_OR_GROUP} . " "};
	/USER_LOGIN_OR_GROUP_NAME/ && do { $result .= $q . $self->{USER_LOGIN_OR_GROUP_NAME} . $q . " "};
	/PROJECT/ && do { $result .= "ON PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 create_attribute

    $foo->create_attribute(
        ATTRIBUTE       => "attribute_name",
        DESCRIPTION     => "description",
        LOCATION        => "location_path",
        HIDDEN          => "TRUE" | "FALSE",
        ATTRIBUTEFORM   => "form_name",
        FORMDESC        => "form_description",
        FORMTYPE        => "formtype",
        SORT            => "NONE | ASC | DESC",
        EXPRESSION      => "form_expression",
        EXPSOURCETABLES => [ "sourcetable1", "sourcetableN" ],
        LOOKUPTABLE     => "lookup_table",
        PROJECT         => "project_name"
    );


Optional parameters: 	
        DESCRIPTION     => "description",
        HIDDEN          => "TRUE" | "FALSE",
        FORMDESC        => "form_description",
        FORMTYPE        => "formtype",
        SORT            => "NONE | ASC | DESC",
        EXPSOURCETABLES => [ "sourcetable1", "sourcetableN" ],

CREATE ATTRIBUTE "<attribute_name>" [DESCRIPTION "<description>"] IN FOLDER "<location_path>" [HIDDEN TRUE | FALSE] ATTRIBUTEFORM "<form_name>" [FORMDESC "<form_description>"] [FORMTYPE (NUMBER | TEXT | DATETIME | DATE | TIME | URL | EMAIL | HTML | PICTURE | BIGDECIMAL)] [SORT (NONE | ASC | DESC)] EXPRESSION "<form_expression>" [EXPSOURCETABLES "<sourcetable1>" [, "<sourcetable1> [, ..."<sourcetableN>"]]] LOOKUPTABLE "<lookup_table>" FOR PROJECT "<project_name>";

CREATE ATTRIBUTE "Day" DESCRIPTION "Duplicate of Day Attribute from folder \Time" IN FOLDER "\Schema Objects\Attributes" ATTRIBUTEFORM "ID" FORMDESC "Basic ID form" FORMTYPE TEXT SORT ASC EXPRESSION "[DAY_DATE]" LOOKUPTABLE "LU_DAY" FOR PROJECT "MicroStrategy Tutorial";

CREATE ATTRIBUTE "Copy of Day" DESCRIPTION "Duplicate of Day Attribute from folder \Time" IN FOLDER "\Schema Objects\Attributes" HIDDEN TRUE ATTRIBUTEFORM "ID" FORMDESC "Basic ID form" FORMTYPE TEXT SORT ASC EXPRESSION "[DAY_DATE]" LOOKUPTABLE "LU_DAY" FOR PROJECT "MicroStrategy Tutorial";

=cut

sub create_attribute {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(ATTRIBUTE DESCRIPTION LOCATION HIDDEN ATTRIBUTEFORM FORMDESC FORMTYPE SORT EXPRESSION EXPSOURCETABLES LOOKUPTABLE PROJECT);
my @required = qw(ATTRIBUTE LOCATION ATTRIBUTEFORM EXPRESSION LOOKUPTABLE PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/^ATTRIBUTE$/ && do { $result .= "CREATE ATTRIBUTE " . $q . $self->{ATTRIBUTE} . $q . " "};
	/DESCRIPTION/ && do { $result .= "DESCRIPTION " . $q . $self->{DESCRIPTION} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/HIDDEN/ && do { $result .= "HIDDEN " . $self->{HIDDEN} . " "};
	/^ATTRIBUTEFORM$/ && do { $result .= "ATTRIBUTEFORM " . $q . $self->{ATTRIBUTEFORM} . $q . " "};
	/FORMDESC/ && do { $result .= "FORMDESC " . $q . $self->{FORMDESC} . $q . " "};
	/FORMTYPE/ && do { $result .= "FORMTYPE " . $self->{FORMTYPE} . " "};
	/SORT/ && do { $result .= "SORT " . $self->{SORT} . " "};
	/EXPRESSION/ && do { $result .= "EXPRESSION " . $q . $self->{EXPRESSION} . $q . " "};
	/EXPSOURCETABLES/ && do { $result .= $self->join_objects($_, $_) }; 
	/LOOKUPTABLE/ && do { $result .= "LOOKUPTABLE " . $q . $self->{LOOKUPTABLE} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 create_connection_map

    $foo->create_connection_map(
        USER         => "login_name",
        DBINSTANCE   => "dbinstance_name",
        DBCONNECTION => "dbConnection_name",
        DBLOGIN      => "dblogin_name",
        PROJECT      => "project_name"
    );


CREATE CONNECTION MAP FOR USER "<login_name>" DBINSTANCE "<dbinstance_name>" DBCONNECTION "<dbConnection_name>" DBLOGIN "<dblogin_name>" ON PROJECT "<project_name>";

=cut

sub create_connection_map {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(USER DBINSTANCE DBCONNECTION DBLOGIN PROJECT);
my @required = qw(USER DBINSTANCE DBCONNECTION DBLOGIN PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/USER/ && do { $result .= "CREATE CONNECTION MAP FOR USER " . $q . $self->{USER} . $q . " "};
	/DBINSTANCE/ && do { $result .= "DBINSTANCE " . $q . $self->{DBINSTANCE} . $q . " "};
	/DBCONNECTION/ && do { $result .= "DBCONNECTION " . $q . $self->{DBCONNECTION} . $q . " "};
	/DBLOGIN/ && do { $result .= "DBLOGIN " . $q . $self->{DBLOGIN} . $q . " "};
	/PROJECT/ && do { $result .= "ON PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 create_custom_group

    $foo->create_custom_group(
        CUSTOMGROUP                 => "customgroup_name",
        DESCRIPTION                 => "description",
        ENABLEHIERARCHICALDISPLAY   => "TRUE" | "FALSE",
        ENABLESUBTOTALDISPLAY       => "TRUE" | "FALSE",
        ELEMENTHEADERPOSITION       => "ABOVE" | "BELOW",
        HIDDEN                      => "TRUE" | "FALSE",
        ELEMENT                     => "element_name",
        SHOWELEMENTNAME             => "TRUE" | "FALSE",
        SHOWITEMSINELEMENT          => "TRUE" | "FALSE",
        SHOWITEMSINELEMENTANDEXPAND => "TRUE" | "FALSE",
        SHOWALLANDEXPAND            => "TRUE" | "FALSE",
        EXPRESSION                  => "expression",
        BREAKAMBIGUITY_FOLDER       => "local_symbol_folder",
        BANDNAMES                   => [ "name1", "nameN" ],
        OUTPUTLEVEL                 => [ "attribute_name1", "attributenameN" ],
        OUTPUTLEVEL_LOCATIONS       =>
          [ "outputlevel_location_path1", "outputlevel_location_pathN" ],
        LOCATION => "location_path",
        PROJECT  => "project_name"
    );


Optional parameters: 
       DESCRIPTION                 => "description",
        ENABLEHIERARCHICALDISPLAY   => "TRUE" | "FALSE",
        ENABLESUBTOTALDISPLAY       => "TRUE" | "FALSE",
        ELEMENTHEADERPOSITION       => "ABOVE" | "BELOW",
        HIDDEN                      => "TRUE" | "FALSE",
        ELEMENT                     => "element_name",
        SHOWELEMENTNAME             => "TRUE" | "FALSE",
        SHOWITEMSINELEMENT          => "TRUE" | "FALSE",
        SHOWITEMSINELEMENTANDEXPAND => "TRUE" | "FALSE",
        SHOWALLANDEXPAND            => "TRUE" | "FALSE",
        EXPRESSION                  => "expression",
        BREAKAMBIGUITY_FOLDER       => "local_symbol_folder",
        BANDNAMES                   => [ "name1", "nameN" ],
        OUTPUTLEVEL                 => [ "attribute_name1", "attributenameN" ],
        OUTPUTLEVEL_LOCATIONS       =>
          [ "outputlevel_location_path1", "outputlevel_location_pathN" ]

CREATE CUSTOMGROUP "<customgroup_name>" 
	[DESCRIPTION "<description>"] 
	[ENABLEHIERARCHICALDISPLAY (TRUE | FALSE)] 
	[ENABLESUBTOTALDISPLAY (TRUE | FALSE)]  
	[ELEMENTHEADERPOSITION (ABOVE | BELOW)] 
	[HIDDEN (TRUE | FALSE)] ELEMENT "<element_name>" 
	[(SHOWELEMENTNAME  | SHOWITEMSINELEMENT | SHOWITEMSINELEMENTANDEXPAND  | SHOWALLANDEXPAND)] 
	EXPRESSION "<expression>" 
	[BREAKAMBIGUITY FOLDER "<local_symbol_folder>"] 
	[BANDNAMES "<name1>", "<name2>", "<nameN>"] 
	[OUTPUTLEVEL  "<attribute_name1>", "<attribute_name2>", "<attributenameN>" IN FOLDERS "<outputlevel_location_path1>", "<outputlevel_location_path2>", "<outputlevel_location_pathN>"] 
	IN FOLDER  "<location_path>" 
	FOR PROJECT "<project_name>";


Following is how to create different types of custom groups using expression text.
Notes:
[] are used to define a name of an object; the name can include the full path to the object.
^ is used as the escape character to specify a string constant inside an expression.
{} are used to indicate a pair of join element list qualification.
When it comes to ambiguous objects within an expression, there are two ways to solve it:
	a. To specify the object with its full path
	b. Place all of the ambiguous objects in a single folder and specify this folder in the command using the BREAKAMBIGUITY reserved word.
When specifying the percentage value using Rank<ByValue=False>, please specify a fraction value between 0 and 1 that corresponds to the percentage value. For example, forty percent (40%) should be specified as 0.4.
Examples of different qualitications:
1. Attribute qualification:
	[\Schema Objects\Attributes\Time\Year]@ID IN ("2003, 2004")
	[\Schema Objects\Attributes\Time\Year]@ID =2003
	[\Schema Objects\Attributes\Products\Category]@DESC IN ("Books", "Movies", "Music", "Electronics")
2. Set Qualification
	For Metric Qualifications, you need to specify the output level at which this metric is calculated.
	Three types of functions: 
		Metric Values: [\Public Objects\Metrics\Sales Metrics\Profit] >= 10
		Bottom Rank: Rank([\Public Objects\Metrics\Sales Metrics\Profit]) <=  3
		Top Rank: Rank<ASC=False>([Revenue Contribution to All Products Abs.]) <= 5
		Percent: Rank<ByValue=False>([\Public Objects\Metrics\Sales Metrics\Profit]) <= 0.1
	*Note for Rank function: There are two parameters that control its behavior. ASC and ByValue.
			         When ASC is set to true, the ranking results are sorted in ascending order; when its value is set to false, the ranking results are sorted in descending order.
			         When ByValue is set to true, the ranking results represent their value order; whereas, when ByValue is set to false, the ranking results represent their percentage order.
3. Shortcut to a Report Qualification
	Just specify the report name:
	[Revenue vs. Forecast] or
	[\Public Objects\Reports\Revenue vs. Forecast]
4. Shortcut to a Filter
	Just specify the filter name:
	[Top 5 Customers by Revenue]
	([\Public Objects\Filters\Top 5 Customers by Revenue])
5. Banding Qualification
	You need to specify the output level. In addition, you may want to specify the band names. 
	Three types of bandings:
		Band Size: Banding(Cost, 1.0, 1000.0, 100.0) 
		Band Point: BandingP(Discount, 1.0, 10.0, 15.0, 20.0)
		Banding Counts: BandingC(Profit, 1.0, 1000.0, 100.0) 
	BandingP(Rank<ByValue=False>([\Public Objects\Metrics\Sales Metrics\Revenue]),0,0.1,0.5,1)
	Banding([Running Revenue Contribution to All Customers Abs.],0.0,1.0,0.2)
6. Advance Qualification
	Join Element List Qualification
	{Year@ID, Category@DESC} IN ({2004, "Books"}, {2005, "Movies"})

=cut

sub create_custom_group {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(CUSTOMGROUP DESCRIPTION ENABLEHIERARCHICALDISPLAY ENABLESUBTOTALDISPLAY ELEMENTHEADERPOSITION HIDDEN ELEMENT SHOWELEMENTNAME SHOWITEMSINELEMENT SHOWITEMSINELEMENTANDEXPAND SHOWALLANDEXPAND EXPRESSION BREAKAMBIGUITY_FOLDER BANDNAMES OUTPUTLEVEL OUTPUTLEVEL_LOCATIONS LOCATION PROJECT);
my @required = qw(CUSTOMGROUP EXPRESSION LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	
	/CUSTOMGROUP/ && do { $result .= "CREATE CUSTOMGROUP " . $q . $self->{CUSTOMGROUP} . $q . " "};
	/DESCRIPTION/ && do { $result .= "DESCRIPTION " . $q . $self->{DESCRIPTION} . $q . " "};
	/ENABLEHIERARCHICALDISPLAY/i && do { $result .= "ENABLEHIERARCHICALDISPLAY " . $self->{ENABLEHIERARCHICALDISPLAY} . " "};
	/ENABLESUBTOTALDISPLAY/ && do { $result .= "ENABLESUBTOTALDISPLAY " . $self->{ENABLESUBTOTALDISPLAY} . " "};
	/ELEMENTHEADERPOSITION/ && do { $result .= "ELEMENTHEADERPOSITION " . $self->{ELEMENTHEADERPOSITION} . " "};
	/HIDDEN/ && do { $result .= "HIDDEN " . $self->{HIDDEN} . " "};
	/^ELEMENT$/ && do { $result .= "ELEMENT " . $q . $self->{ELEMENT} . $q . " "};
	/^SHOWELEMENTNAME$/ && do {
		if($self->{SHOWELEMENTNAME} =~ /(F|0)/i) { next; } 
		$result .= "SHOWELEMENTNAME ";  
	};
	/^SHOWITEMSINELEMENT$/ && do { 
		if($self->{SHOWITEMSINELEMENT} =~ /(F|0)/i) { next; } 
		$result .= "SHOWITEMSINELEMENT ";  
	};
	/^SHOWITEMSINELEMENTANDEXPAND$/ && do { 
		if($self->{SHOWITEMSINELEMENTANDEXPAND} =~ /(F|0)/i) { 	next; } 
		$result .= "SHOWITEMSINELEMENTANDEXPAND ";  
	};
	/SHOWALLANDEXPAND/ && do { 
		if($self->{SHOWALLANDEXPAND} =~ /(F|0)/i) { next; } 
		$result .= "SHOWALLANDEXPAND ";  
	};
	/EXPRESSION/ && do { $result .= "EXPRESSION " . $q . $self->{EXPRESSION} . $q . " "};
	/BREAKAMBIGUITY_FOLDER/ && do { $result .= "BREAKAMBIGUITY FOLDER " . $q . $self->{BREAKAMBIGUITY_FOLDER} . $q . " "};
	/BANDNAMES/ && do { $result .= $self->join_objects($_, $_); };
	/^OUTPUTLEVEL$/ && do { $result .= $self->join_objects($_, $_); };
	/^OUTPUTLEVEL_LOCATIONS$/ && do { $result .= $self->join_objects($_, "IN FOLDERS"); };
	/^LOCATION$/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 create_dbconnection

    $foo->create_dbconnection(
        DBCONNECTION => "dbconnection_name",
        ODBCDSN      => "odbc_datasource_name",
        DEFAULTLOGIN => "default_login",
        DRIVERMODE   => "MULTIPROCESS | MULTITHREADED",
        EXECMODE     => "SYNCHRONOUS | ASYNCHRONOUS (CONNECTION | STATEMENT)",
        USEEXTENDEDFETCH => "TRUE" | "FALSE",
        USEPARAMQUERIES  => "TRUE" | "FALSE",
        MAXCANCELATTEMPT => "number_of_seconds",
        MAXQUERYEXEC     => "number_of_seconds",
        MAXCONNATTEMPT   => "number_of_seconds",
        CHARSETENCODING  => "MULTIBYTE | UTF8",
        TIMEOUT          => "number_of_seconds",
        IDLETIMEOUT      => "number_of_seconds"
    );


Optional parameters: 
        DRIVERMODE   => "MULTIPROCESS | MULTITHREADED",
        EXECMODE     => "SYNCHRONOUS | ASYNCHRONOUS (CONNECTION | STATEMENT)",
        USEEXTENDEDFETCH => "TRUE" | "FALSE",
        USEPARAMQUERIES  => "TRUE" | "FALSE",
        MAXCANCELATTEMPT => "number_of_seconds",
        MAXQUERYEXEC     => "number_of_seconds",
        MAXCONNATTEMPT   => "number_of_seconds",
        CHARSETENCODING  => "MULTIBYTE | UTF8",
        TIMEOUT          => "number_of_seconds",
        IDLETIMEOUT      => "number_of_seconds"
 
CREATE DBCONNECTION "<dbconnection_name>" ODBCDSN "<odbc_datasource_name>" DEFAULTLOGIN "<default_login>" [DRIVERMODE (MULTIPROCESS | MULTITHREADED)] [EXECMODE (SYNCHRONOUS | ASYNCHRONOUS (CONNECTION | STATEMENT))] [USEEXTENDEDFETCH (TRUE | FALSE)] [USEPARAMQUERIES (TRUE | FALSE)] [MAXCANCELATTEMPT <number_of_seconds>] [MAXQUERYEXEC <number_of_seconds>] [MAXCONNATTEMPT <number_of_seconds>] [CHARSETENCODING (MULTIBYTE | UTF8)] [TIMEOUT <number_of_seconds] [IDLETIMEOUT <number_of_seconds>];

=cut

sub create_dbconnection {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(DBCONNECTION ODBCDSN DEFAULTLOGIN DRIVERMODE EXECMODE USEEXTENDEDFETCH USEPARAMQUERIES MAXCANCELATTEMPT MAXQUERYEXEC MAXCONNATTEMPT CHARSETENCODING TIMEOUT IDLETIMEOUT);
my @required = qw();
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/DBCONNECTION/ && do { $result .= "CREATE DBCONNECTION " . $q . $self->{DBCONNECTION} . $q . " "};
	/ODBCDSN/ && do { $result .= "ODBCDSN " . $q . $self->{ODBCDSN} . $q . " "};
	/DEFAULTLOGIN/ && do { $result .= "DEFAULTLOGIN " . $q . $self->{DEFAULTLOGIN} . $q . " "};
	/DRIVERMODE/ && do { $result .= "DRIVERMODE " . $self->{DRIVERMODE} . " "};
	/EXECMODE/ && do { $result .= "EXECMODE " . $self->{EXECMODE} . " "};
	/USEEXTENDEDFETCH/ && do { $result .= "USEEXTENDEDFETCH " . $self->{USEEXTENDEDFETCH} . " "};
	/USEPARAMQUERIES/ && do { $result .= "USEPARAMQUERIES " . $self->{USEPARAMQUERIES} . " "};
	/MAXCANCELATTEMPT/ && do { $result .= "MAXCANCELATTEMPT " . $self->{MAXCANCELATTEMPT} . " "};
	/MAXQUERYEXEC/ && do { $result .= "MAXQUERYEXEC " . $self->{MAXQUERYEXEC} . " "};
	/MAXCONNATTEMPT/ && do { $result .= "MAXCONNATTEMPT " . $self->{MAXCONNATTEMPT} . " "};
	/CHARSETENCODING/ && do { $result .= "CHARSETENCODING " . $self->{CHARSETENCODING} . " "};
	/^TIMEOUT$/ && do { $result .= "TIMEOUT " . $self->{TIMEOUT} . " "};	
	/^IDLETIMEOUT$/ && do { $result .= "IDLETIMEOUT " . $self->{IDLETIMEOUT} . " "};
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 create_dbinstance

    $foo->create_dbinstance(
        DBINSTANCE        => "dbinstance_name",
        DBCONNTYPE        => "dbconnection_type",
        DBCONNECTION      => "dbconnection_name",
        DESCRIPTION       => "description",
        DATABASE          => "database_name",
        TABLESPACE        => "tablespace_name",
        PRIMARYDBINSTANCE => "dbinstance_name",
        DATAMART          => "dbinstance_name",
        TABLEPREFIX       => "table_prefix",
        HIGHTHREADS       => "no_high_conns",
        MEDIUMTHREADS     => "no_medium_conns",
        LOWTHREADS        => "no_low_conns"
    );

Optional parameters: 
        DESCRIPTION       => "description",
        DATABASE          => "database_name",
        TABLESPACE        => "tablespace_name",
        PRIMARYDBINSTANCE => "dbinstance_name",
        DATAMART          => "dbinstance_name",
        TABLEPREFIX       => "table_prefix",
        HIGHTHREADS       => "no_high_conns",
        MEDIUMTHREADS     => "no_medium_conns",
        LOWTHREADS        => "no_low_conns"


CREATE DBINSTANCE "<dbinstance_name>" DBCONNTYPE "<dbconnection_type>" DBCONNECTION "<dbconnection_name>" [DESCRIPTION "<description>"] [DATABASE "<database_name>"] [TABLESPACE "<tablespace_name>"] [PRIMARYDBINSTANCE "<dbinstance_name>"] [DATAMART 
"<dbinstance_name>"] [TABLEPREFIX "<table_prefix>"] [HIGHTHREADS <no_high_conns>] [MEDIUMTHREADS <no_medium_conns>] [LOWTHREADS <no_low_conns>];

=cut

sub create_dbinstance {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(DBINSTANCE DBCONNTYPE DBCONNECTION DESCRIPTION DATABASE TABLESPACE PRIMARYDBINSTANCE DATAMART TABLEPREFIX HIGHTHREADS MEDIUMTHREADS LOWTHREADS);
my @required = qw(DBINSTANCE DBCONNTYPE DBCONNECTION);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/^DBINSTANCE$/ && do { $result .= "CREATE DBINSTANCE " . $q . $self->{DBINSTANCE} . $q . " "};
	/DBCONNTYPE/ && do { $result .= "DBCONNTYPE " . $q . $self->{DBCONNTYPE} . $q . " "};
	/DBCONNECTION/ && do { $result .= "DBCONNECTION " . $q . $self->{DBCONNECTION} . $q . " "};
	/DESCRIPTION/ && do { $result .= "DESCRIPTION " . $q . $self->{DESCRIPTION} . $q . " "};
	/DATABASE/ && do { $result .= "DATABASE " . $q . $self->{DATABASE} . $q . " "};
	/TABLESPACE/ && do { $result .= "TABLESPACE " . $q . $self->{TABLESPACE} . $q . " "};
	/^PRIMARYDBINSTANCE$/ && do { $result .= "PRIMARYDBINSTANCE " . $q . $self->{PRIMARYDBINSTANCE} . $q . " "};
	/DATAMART/ && do { $result .= "DATAMART " . $q . $self->{DATAMART} . $q . " "};
	/TABLEPREFIX/ && do { $result .= "TABLEPREFIX " . $q . $self->{TABLEPREFIX} . $q . " "};
	/HIGHTHREADS/ && do { $result .= "HIGHTHREADS " . $self->{HIGHTHREADS} . " "};
	/MEDIUMTHREADS/ && do { $result .= "MEDIUMTHREADS " . $self->{MEDIUMTHREADS} . " "};
	/LOWTHREADS/ && do { $result .= "LOWTHREADS " . $self->{LOWTHREADS} . " "};
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 create_dblogin

    $foo->create_dblogin(
        DBLOGIN  => "dblogin_name",
        LOGIN    => "database_login",
        PASSWORD => "database_pwd"
    );


Optional parameters: 
        LOGIN    => "database_login",
        PASSWORD => "database_pwd"

CREATE DBLOGIN "<dblogin_name>" [LOGIN "<database_login>"] [PASSWORD "<database_pwd>"];

=cut

sub create_dblogin {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(DBLOGIN LOGIN PASSWORD);
my @required = qw(DBLOGIN);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/^DBLOGIN$/ && do { $result .= "CREATE DBLOGIN " . $q . $self->{DBLOGIN} . $q . " "};
	/^LOGIN$/ && do { $result .= "LOGIN " . $q . $self->{LOGIN} . $q . " "};
	/PASSWORD/ && do { $result .= "PASSWORD " . $q . $self->{PASSWORD} . $q . " "};
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 create_event

    $foo->create_event(
        EVENT       => "event_name",
        DESCRIPTION => "description"
    );


Optional parameters: 
        DESCRIPTION => "description"


CREATE EVENT "<event_name>" [DESCRIPTION "<description>"];

=cut

sub create_event {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(EVENT DESCRIPTION);
my @required = qw();
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/EVENT/ && do { $result .= "CREATE EVENT " . $q . $self->{EVENT} . $q . " "};
	/DESCRIPTION/ && do { $result .= "DESCRIPTION " . $q . $self->{DESCRIPTION} . $q . " "};
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 create_fact

    $foo->create_fact(
        FACT            => "fact_name",
        DESCRIPTION     => "description",
        LOCATION        => "location_path",
        HIDDEN          => "TRUE" | "FALSE",
        EXPRESSION      => "expression",
        EXPSOURCETABLES => [ "sourcetable1", "sourcetableN" ],
        PROJECT         => "project_name"
    );

Optional parameters: 
        DESCRIPTION     => "description",
        HIDDEN          => "TRUE" | "FALSE",
        EXPRESSION      => "expression",
        EXPSOURCETABLES => [ "sourcetable1", "sourcetableN" ]

CREATE FACT "<fact_name>" [DESCRIPTION "<description>"] IN FOLDER "<location_path>" [HIDDEN (TRUE | FALSE)] EXPRESSION "<expression>" [EXPSOURCETABLES "<sourcetable1>" [, "<sourcetable2>" [, "<sourcetableN>"]]] FOR PROJECT "<project_name>";

=cut

sub create_fact {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(FACT DESCRIPTION LOCATION HIDDEN EXPRESSION EXPSOURCETABLES PROJECT);
my @required = qw(FACT LOCATION EXPRESSION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/FACT/ && do { $result .= "CREATE FACT " . $q . $self->{FACT} . $q . " "};
	/DESCRIPTION/ && do { $result .= "DESCRIPTION " . $q . $self->{DESCRIPTION} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/HIDDEN/ && do { $result .= "HIDDEN " . $self->{HIDDEN} . " "};
	/EXPRESSION/ && do { $result .= "EXPRESSION " . $q . $self->{EXPRESSION} . $q . " "};
	/EXPSOURCETABLES/ && do { $result .= $self->join_objects($_, $_) }; 
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 create_filter_oultine

    $foo->create_filter_oultine(
           FILTER      => "filter_name", 
	   LOCATION    => "location_path", 
	   EXPRESSION  => "expression", 
	   DESCRIPTION => "description", 
	   HIDDEN      => "TRUE", 
	   PROJECT     => "project_name"
    );

Optional parameters: 
 	   DESCRIPTION => "description", 
	   HIDDEN      => "TRUE"

CREATE FILTER "<filter_name>" IN [FOLDER] "<location_path>" EXPRESSION "<expression>" [DESCRIPTION "<description>"] [HIDDEN (TRUE | FALSE)] ON PROJECT "<project_name>";

=cut

sub create_filter_oultine {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(FILTER LOCATION EXPRESSION DESCRIPTION HIDDEN PROJECT);
my @required = qw(FILTER LOCATION EXPRESSION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/FILTER/ && do { $result .= "CREATE FILTER " . $q . $self->{FILTER} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/EXPRESSION/ && do { $result .= "EXPRESSION " . $q . $self->{EXPRESSION} . $q ." "};
	/DESCRIPTION/ && do { $result .= "DESCRIPTION " .  $q. $self->{DESCRIPTION} . $q . " "};
	/HIDDEN/ && do { $result .= "HIDDEN " . $self->{HIDDEN} . " "};
	/PROJECT/ && do { $result .= "ON PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 create_folder

    $foo->create_folder(
        FOLDER      => "folder_name",
        LOCATION    => "location_path",
        DESCRIPTION => "description",
        HIDDEN      => "TRUE" | "FALSE",
        PROJECT     => "project_name"
    );

Optional parameters: 
        DESCRIPTION => "description",
        HIDDEN      => "TRUE" | "FALSE",

CREATE FOLDER "<folder_name>" IN "<location_path>" [DESCRIPTION "<description>"] [HIDDEN (TRUE | FALSE)] FOR PROJECT "<project_name>";

=cut

sub create_folder {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(FOLDER LOCATION DESCRIPTION HIDDEN PROJECT);
my @required = qw();
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/FOLDER/ && do { $result .= "CREATE FOLDER " . $q . $self->{FOLDER} . $q . " "};
	/LOCATION/ && do { $result .= "IN " . $q . $self->{LOCATION} . $q . " "};
	/DESCRIPTION/ && do { $result .= "DESCRIPTION " . $q . $self->{DESCRIPTION} . $q . " "};
	/HIDDEN/ && do { $result .= "HIDDEN " . $self->{HIDDEN} . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 create_metric_oultine

    $foo->create_metric_oultine(
        METRIC      => "metric_name",
        LOCATION    => "location_path",
        EXPRESSION  => "expression",
        DESCRIPTION => "description",
        HIDDEN      => "TRUE" | "FALSE",
        PROJECT     => "project_name"
    );

Optional parameters: 
        DESCRIPTION => "description",
        HIDDEN      => "TRUE" | "FALSE",

CREATE METRIC "<metric_name>" IN [FOLDER] "<location_path>" EXPRESSION "<expression>" [DESCRIPTION "<description>"] [HIDDEN (TRUE | FALSE)] ON PROJECT "<project_name>";

=cut

sub create_metric_oultine {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(METRIC LOCATION EXPRESSION DESCRIPTION HIDDEN PROJECT);
my @required = qw(METRIC LOCATION EXPRESSION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/METRIC/ && do { $result .= "CREATE METRIC " . $q . $self->{METRIC} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/EXPRESSION/ && do { $result .= "EXPRESSION " . $q . $self->{EXPRESSION} . $q . " "};
	/DESCRIPTION/ && do { $result .= "DESCRIPTION " . $q . $self->{DESCRIPTION} . $q . " "};
	/HIDDEN/ && do { $result .= "HIDDEN " . $self->{HIDDEN} . " "};
	/PROJECT/ && do { $result .= "ON PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 create_schedule

    $foo->create_schedule(
        SCHEDULE    => "schedule_name",
        NEW_NAME    => "new_name",
        DESCRIPTION => "new_description",
        STARTDATE   => "new_start_date",
        ENDDATE     => ( "new_end_date" | "NEVER" ),
        TYPE        => ( "EVENTTRIGGERED" | "TIMETRIGGERED" ),
        EVENTNAME   => "<new_event_name>",
        DAILY       => "EVERY (<new_number> DAYS | WEEKDAY)",
        WEEKLY      => "EVERY <new_number> WEEKS ON day_of_week1 [, day_of_week2 [,...
    day_of_week7]]", MONTHLY => "(DAY <new_number> OF EVERY <new_number>
    MONTHS (FIRST | SECOND | THIRD | FOURTH | LAST) (day_of_week1 |
    day_of_week2 | ... | day_of_week7) OF EVERY <new_number> MONTHS)",
        YEARLY => "((month_of_year1 | month_of_year2 | ... | month_of_year12)
    <new_number> (FIRST | SECOND | THIRD | FOURTH | LAST) (day_of_week1 |
    day_of_week2 | ... | day_of_week7) OF (month_of_year1 | month_of_year2 |
    ... | month_of_year12))",
        EXECUTE_TIME_OF_DAY => "new_time_of_day",
        EXECUTE_ALL_DAY     => "EVERY <new_number> (MINUTES | HOURS [START AFTER
    MIDNIGHT <number> MINUTES] )",
    );

CREATE SCHEDULE "<schedule_name>" [DESCRIPTION "<description>"] STARTDATE <start_date> ENDDATE (<end_date> | NEVER) TYPE (EVENTTRIGGERED EVENTNAME "<event_name>" | TIMETRIGGERED (DAILY EVERY (<number> DAYS | WEEKDAY) | WEEKLY EVERY <number> WEEKS ON day_of_week1 [, day_of_week2 [,... day_of_week7]] | MONTHLY (DAY <number> OF EVERY <number> MONTHS | (FIRST | SECOND | THIRD | FOURTH | LAST) (day_of_week1 | day_of_week2 | ... | day_of_week7) OF EVERY <number> MONTHS) | YEARLY ((month_of_year1 | month_of_year2 | ... | month_of_year12) <number> | (FIRST | SECOND | THIRD | FOURTH | LAST) (day_of_week1 | day_of_week2 | ... | day_of_week7) OF (month_of_year1 | month_of_year2 | ... | month_of_year12))) EXECUTE (<time_of_day> | ALL DAY EVERY <number> (MINUTES | HOURS [START AFTER MIDNIGHT <number> MINUTES])));

Event-Triggered Schedule
CREATE SCHEDULE "<schedule_name>" [DESCRIPTION "<description>"] STARTDATE <start_date> ENDDATE (<end_date> | NEVER) TYPE EVENTTRIGGERED EVENTNAME "<event_name>";

Daily Time-Triggered Schedule
CREATE SCHEDULE "<schedule_name>" [DESCRIPTION "<description>"] STARTDATE <start_date> ENDDATE (<end_date> | NEVER) TYPE TIMETRIGGERED DAILY EVERY (<number> DAYS | WEEKDAY) EXECUTE (<time_of_day> | ALL DAY EVERY <number> (MINUTES | HOURS [START AFTER MIDNIGHT <number> MINUTES]));

Weekly Time-Triggered Schedule
CREATE SCHEDULE "<schedule_name>" [DESCRIPTION "<description>"] STARTDATE <start_date> ENDDATE (<end_date> | NEVER) TYPE TIMETRIGGERED WEEKLY EVERY <number> WEEKS ON day_of_week1 [, day_of_week2 [,... day_of_week7]] EXECUTE (<time_of_day> | ALL DAY EVERY <number> (MINUTES | HOURS [START AFTER MIDNIGHT <number> MINUTES]));

Monthly Time-Triggered Schedule
CREATE SCHEDULE "<schedule_name>" [DESCRIPTION "<description>"] STARTDATE <start_date> ENDDATE (<end_date> | NEVER) TYPE TIMETRIGGERED MONTHLY (DAY <number> OF EVERY <number> MONTHS | (FIRST | SECOND | THIRD | FOURTH | LAST) (day_of_week1 | day_of_week2 | ... | day_of_week7) OF EVERY <number> MONTHS) EXECUTE (<time_of_day> | ALL DAY EVERY <number> (MINUTES | HOURS [START AFTER MIDNIGHT <number> MINUTES]));

Yearly Time-Triggered Schedule
CREATE SCHEDULE "<schedule_name>" [DESCRIPTION "<description>"] STARTDATE <start_date> ENDDATE (<end_date> | NEVER) TYPE TIMETRIGGERED YEARLY ((month_of_year1 | month_of_year2 | ... | month_of_year12) <number> | (FIRST | SECOND | THIRD | FOURTH | LAST) (day_of_week1 | day_of_week2 | ... | day_of_week7) OF (month_of_year1 | month_of_year2 | ... | month_of_year12)) EXECUTE (<time_of_day> | ALL DAY EVERY <number> (MINUTES | HOURS [START AFTER MIDNIGHT <number> MINUTES]));

CREATE SCHEDULERELATION SCHEDULE "Schedule1" USER "jen" REPORT "rep_or_doc_name" IN "location_path" IN PROJECT "project_name" CREATEMSGHIST TRUE ENABLEMOBILEDELIVERY OVERWRITE UPDATECACHE;

$foo->create_schedule_relation(
        SCHEDULE                 => "Schedule1",
        USER_OR_GROUP            => "USER",
        USER_LOGIN_OR_GROUP_NAME => "jen",
        REPORT                   => "rep_or_doc_name",
        LOCATION                 => "location_path",
        PROJECT                  => "project_name",
        CREATEMSGHIST            => "TRUE",
        ENABLEMOBILEDELIVERY     => "TRUE",
        OVERWRITE                => "TRUE",
        UPDATECACHE              => "TRUE",
    );

=cut

sub create_schedule {
	my $self = shift;
	$self->{SCHEDULE_ACTION} = "CREATE SCHEDULE ";
	$self->schedule(@_);
}

=head2 create_schedule_relation

    $foo->create_schedule_relation(
        SCHEDULE                 => "schedule_name",
        USER_OR_GROUP            => "USER | GROUP",
        USER_LOGIN_OR_GROUP_NAME => "user_login_or_group_name",
        REPORT                   => "rep_or_doc_name",
        LOCATION                 => "location_path",
        PROJECT                  => "project_name",
        CREATEMSGHIST            => "TRUE" | "FALSE",
        ENABLEMOBILEDELIVERY     => "TRUE" | "FALSE",
        OVERWRITE                => "TRUE" | "FALSE",
        UPDATECACHE              => "TRUE" | "FALSE";
    );

This command can be used only in 3-tier Project Source Names.

CREATE SCHEDULERELATION SCHEDULE "<schedule_name>" (USER | GROUP) "<user_login_or_group_name>" REPORT "<rep_or_doc_name>" IN "<location_path>" IN PROJECT "<project_name>" [CREATEMSGHIST (TRUE | FALSE) | [ENABLEMOBILEDELIVERY [OVERWRITE] | UPDATECACHE ];

=cut

sub create_schedule_relation {
	my $self = shift;
	$self->{ACTION} = "CREATE ";
	$self->schedule_relation(@_);
}

=head2 create_security_filter

    $foo->create_security_filter(
        SECURITY_FILTER       => "sec_filter_name",
        LOCATION              => "location_path",
        HIDDEN                => "TRUE" | "FALSE",
        PROJECT               => "project_name",
        FILTER                => "FILTER_NAME",
        FILTER_LOCATION       => "FILTER_LOCATION_PATH",
        EXPRESSION            => "EXPRESSION",
        TOP_ATTRIBUTE_LIST    => [ "top_attr_name1", "top_attr_nameN" ],
        BOTTOM_ATTRIBUTE_LIST => [ "bottom_attr_name1", "bottom_attr_nameN" ]
    );

Optional parameters: 	        
	LOCATION              => "location_path",
        HIDDEN                => "TRUE" | "FALSE",
        FILTER                => "FILTER_NAME",
        FILTER_LOCATION       => "FILTER_LOCATION_PATH",
        EXPRESSION            => "EXPRESSION",
        TOP_ATTRIBUTE_LIST    => [ "top_attr_name1", "top_attr_nameN" ],
        BOTTOM_ATTRIBUTE_LIST => [ "bottom_attr_name1", "bottom_attr_nameN" ]

CREATE SECURITY FILTER "<sec_filter_name>" [FOLDER "<location_path>"] [HIDDEN (TRUE | FALSE)] IN [PROJECT] "<project_name>" (FILTER "<filter_name>" [IN FOLDER "<filter_location_path>"] | EXPRESSION "<expression>") [TOP ATTRIBUTE LIST "<top_attr_name1>" [, "<top_attr_name2>" [, ... "<top_attr_nameN>"]]] [BOTTOM ATTRIBUTE LIST "<bottom_attr_name1>" [, "<bottom_attr_name2>" [, ... "<bottom_attr_nameN>"]]];

=cut

sub create_security_filter {
	my $self = shift;
	$self->{ACTION} = "CREATE ";
	$self->security_filter(@_);
}

=head2 create_security_role

    $foo->create_security_role(
        SECURITY_ROLE => "sec_role_name",
        DESCRIPTION   => "sec_role_description"
    );

Optional parameters: 
        DESCRIPTION   => "sec_role_description"

CREATE SECURITY ROLE "<sec_role_name>" [DESCRIPTION "<sec_role_description>"];

=cut

sub create_security_role {
	my $self = shift;
	$self->{ACTION} = "CREATE ";
	$self->security_role(@_);
}

=head2 create_shortcut

    $foo->create_shortcut(
        SHORTCUT_LOCATION    => "location_path",
        PROJECT_CONFIG_OJECT => "project_config_object",
        OBJECT_NAME          => "object_name",
        LOCATION             => "object_location_path",
        HIDDEN               => "TRUE" | "FALSE",
        PROJECT              => "project_name"
    );

Optional parameters: 
       HIDDEN               => "TRUE" | "FALSE",


CREATE SHORTCUT IN FOLDER "<location_path>" FOR (FOLDER | CONSOLIDATION | DOCUMENT | FILTER | METRIC | PROMPT | REPORT | SEARCH | TEMPLATE | ATTRIBUTE | FACT | FUNCTION | HIERARCHY | TABLE | TRANSFORMATION | DRILLMAP | SECFILTER | AUTOSTYLE | BASEFORMULA) "<object_name>" IN FOLDER "<object_location_path>" [HIDDEN (TRUE | FALSE)] FOR PROJECT "<project_name>";



=cut

sub create_shortcut {
my $self = shift;
$self->{ACTION} = "CREATE ";
$self->shortcut(@_);
}

=head2 create_user_group

    $foo->create_user_group(
        USER_GROUP   => "user_group_name",
        DESCRIPTION  => "user_group_desc",
        LDAPLINK     => "ldap_user_id",
        MEMBERS      => [ "login_name1", "login_nameN" ],
        PARENT_GROUP => "parent_user_group_name"
    );

Optional parameters: 
        DESCRIPTION  => "user_group_desc",
        LDAPLINK     => "ldap_user_id",
        MEMBERS      => [ "login_name1", "login_nameN" ],
        PARENT_GROUP => "parent_user_group_name"

CREATE USER GROUP "<user_group_name>" [DESCRIPTION "<user_group_desc>"] [LDAPLINK "<ldap_user_id>"]
[MEMBERS "<login_name1>" [, "<login_name2>" [,... "<login_nameN>"]]] [[IN] GROUP "<parent_user_group_name>"];

=cut

sub create_user_group {
	my $self = shift;
	$self->{ACTION} = "CREATE ";
	$self->user_group(@_);
}

=head2 create_user

    $foo->create_user(
        USER           => "login_name" | "nt_user_id",
        IMPORTWINUSER  => "TRUE" | "FALSE",
        NAME           => "new_login_name",
        NTLINK         => "nt_user_id",
        PASSWORD       => "user_password",
        FULLNAME       => "user_fullname",
        DESCRIPTION    => "user_description",
        LDAPLINK       => "ldap_user_id",
        WHLINK         => "warehouse_login",
        WHPASSWORD     => "warehouse_password",
        ALLOWCHANGEPWD => "TRUE" | "FALSE",
        ALLOWSTDAUTH   => "TRUE" | "FALSE",
        CHANGEPWD      => "TRUE" | "FALSE",
        PASSWORDEXP    => "NEVER" | "IN new_number_of_days DAYS" |
          "ON expiration_date",
        PASSWORDEXPFREQ => "number",
        ENABLED         => "ENABLED" | "DISABLED",
        GROUP           => "user_group_name"
    );

CREATE USER (IMPORTWINUSER "<nt_user_id>" | "<login_name>" [FULLNAME "<user_full_name>"] [DESCRIPTION "<user_description>"] [NTLINK "<nt_user_id>"]) [PASSWORD "<user_password>"] [LDAPLINK "<ldap_user_id>"] [WHLINK "<warehouse_login>"] [WHPASSWORD "<warehouse_password>"] [ALLOWCHANGEPWD (TRUE | FALSE)] [ALLOWSTDAUTH (TRUE | FALSE)] [CHANGEPWD (TRUE | FALSE)] [PASSWORDEXP (NEVER | IN number_of_days DAYS | ON <expiration_date>)] [PASSWORDEXPFREQ <number> DAYS] [ENABLED | DISABLED] [IN GROUP "<user_group_name>"];

=cut

sub create_user {
	my $self = shift;
	$self->{ACTION} = "CREATE ";
	$self->user(@_);
}

=head2 create_user_profile

    $foo->create_user_profile(
        USER     => "login_name",
        LOCATION => "location_path",
        PROJECT  => "project_name"
    );

Optional parameters:  
        LOCATION => "location_path"

CREATE [USER] PROFILE [FOR [USER]] "<login_name>" [IN FOLDER "<location_path>"] FOR [PROJECT] "<project_name>";

=cut

sub create_user_profile {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(USER LOCATION PROJECT);
my @required = qw(USER PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/USER/ && do { $result .= "CREATE USER PROFILE FOR USER " . $q . $self->{USER} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 delete_attribute

    $foo->delete_attribute(
        ATTRIBUTE => "attribute_name",
        LOCATION  => "location_path",
        PROJECT   => "project_name"
    );


DELETE ATTRIBUTE "<attribute_name>" IN FOLDER "<location_path>" FOR PROJECT "<project_name>";

=cut

sub delete_attribute {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(ATTRIBUTE LOCATION PROJECT);
my @required = qw(ATTRIBUTE LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/ATTRIBUTE/ && do { $result .= "DELETE ATTRIBUTE " . $q . $self->{ATTRIBUTE} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 delete_connection_map

    $foo->delete_connection_map(
        USER       => "login_name",
        DBINSTANCE => "dbinstance_name",
        PROJECT    => "project_name"
    );


DELETE CONNECTION MAP FOR USER "<login_name>" DBINSTANCE "<dbinstance_name>" ON PROJECT "<project_name>";

=cut

sub delete_connection_map {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(USER DBINSTANCE PROJECT);
my @required = qw(USER DBINSTANCE PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/USER/ && do { $result .= "DELETE CONNECTION MAP FOR USER " . $q . $self->{USER} . $q . " "};
	/DBINSTANCE/ && do { $result .= "DBINSTANCE " . $q . $self->{DBINSTANCE} . $q . " "};
	/PROJECT/ && do { $result .= "ON PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 delete_custom_group

    $foo->delete_custom_group(
        CUSTOMGROUP => "customgroup_name",
        LOCATION    => "location_path",
        PROJECT     => "project_name"
    );


DELETE CUSTOMGROUP "<customgroup_name>" IN FOLDER "<location_path>" FROM PROJECT "<project_name>";

=cut

sub delete_custom_group {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(CUSTOMGROUP LOCATION PROJECT);
my @required = qw(CUSTOMGROUP LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/CUSTOMGROUP/ && do { $result .= "DELETE CUSTOMGROUP " . $q . $self->{CUSTOMGROUP} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FROM PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 delete_dbconnection

    $foo->delete_dbconnection( DBCONNECTION => "dbConnection_name" );

DELETE DBCONNECTION "<dbConnection_name>";

=cut

sub delete_dbconnection {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(DBCONNECTION);
my @required = qw(DBCONNECTION);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/DBCONNECTION/ && do { $result .= "DELETE DBCONNECTION " . $q . $self->{DBCONNECTION} . $q . ";"};
}

return $result;
}

=head2 delete_dbinstance

$foo->delete_dbinstance( DBINSTANCE => "dbinstance_name" );

DELETE DBINSTANCE "<dbinstance_name>";

=cut

sub delete_dbinstance {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(DBINSTANCE);
my @required = qw(DBINSTANCE);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/DBINSTANCE/ && do { $result .= "DELETE DBINSTANCE " . $q . $self->{DBINSTANCE} . $q . ";"};
}

return $result;
}

=head2 delete_dblogin

$foo->delete_dblogin( DBLOGIN => "dblogin_name" );

DELETE DBLOGIN "<dblogin_name>";

DELETE DBLOGIN "Data";

=cut

sub delete_dblogin {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(DBLOGIN);
my @required = qw(DBLOGIN);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/DBLOGIN/ && do { $result .= "DELETE DBLOGIN " . $q . $self->{DBLOGIN} . $q . ";"};
}

return $result;
}

=head2 delete_event

    $foo->delete_event( EVENT => "event_name" );

DELETE EVENT "<event_name>";

=cut

sub delete_event {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(EVENT);
my @required = qw(EVENT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/EVENT/ && do { $result .= "DELETE EVENT " . $q . $self->{EVENT} . $q . ";"};
}

return $result;
}

=head2 delete_fact

    $foo->delete_fact(
        FACT     => "fact_name",
        LOCATION => "location_path",
        PROJECT  => "project_name"
    );

DELETE FACT "<fact_name>" IN FOLDER "<location_path>" FOR PROJECT "<project_name>";

=cut

sub delete_fact {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(FACT LOCATION PROJECT);
my @required = qw(FACT LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/FACT/ && do { $result .= "DELETE FACT " . $q . $self->{FACT} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 delete_filter

    $foo->delete_filter(
        FILTER   => "filter_name",
        LOCATION => "location_path",
        PROJECT  => "project_name"
    );
 
DELETE FILTER "<filter_name>" IN [FOLDER] "<location_path>" FROM PROJECT "<project_name>";

=cut

sub delete_filter {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(FILTER LOCATION PROJECT);
my @required = qw(FILTER LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/FILTER/ && do { $result .= "DELETE FILTER " . $q . $self->{FILTER} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FROM PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 delete_folder

    $foo->delete_folder(
        FOLDER   => "folder_name",
        LOCATION => "location_path",
        PROJECT  => "project_name"
    );


DELETE FOLDER "<folder_name>" IN "<location_path>" FROM PROJECT "<project_name>";

DELETE FOLDER "Sales Reports" IN "\Public Objects" FROM PROJECT "MicroStrategy Tutorial";

=cut

sub delete_folder {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(FOLDER LOCATION PROJECT);
my @required = qw(FOLDER LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/FOLDER/ && do { $result .= "DELETE FOLDER " . $q . $self->{FOLDER} . $q . " "};
	/LOCATION/ && do { $result .= "IN " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FROM PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 delete_metric

    $foo->delete_metric(
        METRIC   => "metric_name",
        LOCATION => "location_path",
        PROJECT  => "project_name"
    );

DELETE METRIC "<metric_name>" IN [FOLDER] "<location_path>" FROM PROJECT "<project_name>";

=cut

sub delete_metric {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(METRIC LOCATION PROJECT);
my @required = qw(METRIC LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/METRIC/ && do { $result .= "DELETE METRIC " . $q . $self->{METRIC} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FROM PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 delete_project

    $foo->delete_project("project_name");

DELETE PROJECT "<project_name>";

=cut

sub delete_project {
my $self = shift;
$self->{PROJECT} = shift;
if(!defined($self->{PROJECT})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
return "DELETE PROJECT " . $q . $self->{PROJECT} . $q . ";";
}

=head2 delete_report_cache

    $foo->delete_report_cache(
        INVALID      => "TRUE" | "FALSE",
        REPORT_CACHE => "ALL" | "cache_name",
        PROJECT      => "project_name" | [ "project_name1", "project_nameN" ],
    );

This command can be used only in 3-tier Project Source Names.

DELETE ([ALL] [INVALID] REPORT CACHES | REPORT CACHE "<cache_name>") [IN (PROJECT(S) "<project_name1>", ["<projectname2>" [, "<project_namen>"]]];

To specify one project, use 'PROJECT'
To specify more than one project, use 'PROJECTS'

DELETE REPORT CACHE "Customer List" IN PROJECT "MicroStrategy Tutorial";

DELETE ALL INVALID REPORT CACHES;
DELETE INVALID REPORT CACHES IN PROJECT "MicroStrategy Tutorial";
DELETE INVALID REPORT CACHES IN PROJECTS "MicroStrategy Tutorial", "Customer Analysis Module";

=cut

sub delete_report_cache {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(REPORT_CACHE PROJECT);
my @required = qw();
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
$result .= "DELETE ";
for(@selected) {
	/REPORT_CACHE/ && do { 
		if($self->{REPORT_CACHE} =~ /ALL/i) { 
			$result .= "ALL ";
			if($self->{INVALID} eq 'TRUE') {
				$result .= "INVALID ";
			}
			$result .= "REPORT CACHES "; 
			next;
		}
		$result .= "REPORT CACHE " . $q . $self->{REPORT_CACHE} . $q . " ";
	};
	/PROJECT/ && do { if($self->{PROJECT} =~ /ARRAY/) {
			$result .= $self->join_objects($_, "IN PROJECTS");
		      	next;
			}	
			$result .= "IN PROJECT " . $q . $self->{PROJECT} . $q . " ";
	};
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 delete_report

    $foo->delete_report(
        REPORT   => "report_name",
        LOCATION => "location_path",
        PROJECT  => "project_name"
    );

DELETE REPORT "<report_name>" IN FOLDER "<location_path>" FROM PROJECT "<project_name>";

=cut

sub delete_report {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(REPORT LOCATION PROJECT);
my @required = qw(REPORT LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/REPORT/ && do { $result .= "DELETE REPORT " . $q . $self->{REPORT} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FROM PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 delete_schedule

$foo->delete_schedule("schedule_name");

DELETE SCHEDULE "<schedule_name>";

=cut

sub delete_schedule {
	my $self = shift;
	$self->{SCHEDULE} = shift;
	if(!defined($self->{SCHEDULE})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
	return "DELETE SCHEDULE " . $q . $self->{SCHEDULE} . $q . ";";
}

=head2 delete_schedule_relation

    $foo->delete_schedule_relation(
        DELETE_MULTIPLE          => "TRUE" | "FALSE",
        USER_OR_GROUP            => "USER" | "GROUP",
        USER_LOGIN_OR_GROUP_NAME => "user_login" | "group_name",
        SCHEDULE                 => "schedule_name",
        REPORT                   => "rep_or_doc_name",
        LOCATION                 => "location_path",
        PROJECT                  => "project_name"
    );


This command can be used only in 3-tier Project Source Names.

DELETE ([ALL] SCHEDULERELATIONS [FOR ((USER | GROUP) "<user_login_or_group_name>" | REPORT "<rep_or_doc_name>" IN "<location_path>" | SCHEDULE "<schedule_name>") | SCHEDULERELATION SCHEDULE "<schedule_name>" (USER | GROUP) "<user_login_or_group_name>" REPORT "<rep_or_doc_name>" IN "<location_path>"]) FROM PROJECT "<project_name>";


Optional parameters: 
        USER_OR_GROUP            => "USER" | "GROUP",
        USER_LOGIN_OR_GROUP_NAME => "user_login" | "group_name",
        SCHEDULE                 => "schedule_name",
        REPORT                   => "rep_or_doc_name",
        LOCATION                 => "location_path",


DELETE ALL SCHEDULERELATIONS FOR REPORT "Revenue vs. Forecast" IN "\Public Objects\Reports\Subject Areas\Sales and Profitability Analysis" FROM PROJECT "MicroStrategy Tutorial";

    $foo->delete_schedule_relation(
        DELETE_MULTIPLE => "TRUE",
        REPORT          => "Revenue vs. Forecast",
        LOCATION =>
'\Public Objects\Reports\Subject Areas\Sales and Profitability Analysis',
        PROJECT => "MicroStrategy Tutorial"
    );

DELETE ALL SCHEDULERELATIONS FOR USER "crosie" FROM PROJECT "MicroStrategy Tutorial";

    $foo->delete_schedule_relation(
        DELETE_MULTIPLE          => "TRUE",
        USER_OR_GROUP            => "USER",
        USER_LOGIN_OR_GROUP_NAME => "crosie",
        PROJECT                  => "MicroStrategy Tutorial"
    );

DELETE ALL SCHEDULERELATIONS FOR SCHEDULE "All The Time" FROM PROJECT "MicroStrategy Tutorial";

    $foo->delete_schedule_relation(
        DELETE_MULTIPLE => "TRUE",
        SCHEDULE        => "All The Time",
        PROJECT         => "MicroStrategy Tutorial"
    );

DELETE ALL SCHEDULERELATIONS FROM PROJECT "MicroStrategy Tutorial";

    $foo->delete_schedule_relation(
        DELETE_MULTIPLE => "TRUE",
        PROJECT         => "MicroStrategy Tutorial"
    );

DELETE SCHEDULERELATION SCHEDULE "All The Time" USER "crosie" REPORT "rep_or_doc_name" IN "location_path" FROM PROJECT "project_name";

    $foo->delete_schedule_relation(
        DELETE_MULTIPLE          => "FALSE",
        USER_OR_GROUP            => "USER",
        USER_LOGIN_OR_GROUP_NAME => "crosie",
        SCHEDULE                 => "All The Time",
        REPORT                   => "rep_or_doc_name",
        LOCATION                 => "location_path",
        PROJECT                  => "project_name"
    );

=cut

sub delete_schedule_relation {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
if($self->{DELETE_MULTIPLE} eq "FALSE") { 
	$self->{ACTION} = "DELETE ";
	return $self->schedule_relation(@_);
}
my $result;
my @order = qw(DELETE_MULTIPLE USER_OR_GROUP USER_LOGIN_OR_GROUP_NAME SCHEDULE REPORT LOCATION PROJECT);
my @required = qw(PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/DELETE_MULTIPLE/ && do { $result .= "DELETE ALL SCHEDULERELATIONS ";  };
	/USER_OR_GROUP/ && do { $result .= "FOR " . $self->{USER_OR_GROUP} . " "; };
	/USER_LOGIN_OR_GROUP_NAME/ && do { $result .= $q . $self->{USER_LOGIN_OR_GROUP_NAME} . $q . " "; };
	/SCHEDULE/&& do { $result .= "FOR SCHEDULE " . $q . $self->{SCHEDULE} . $q . " "; };
	/REPORT/ && do { $result .= "FOR REPORT " . $q . $self->{REPORT} . $q . " "; };
	/LOCATION/ && do { $result .= "IN " . $q . $self->{LOCATION} . $q . " "; };
	/PROJECT/ && do { $result .= "FROM PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 delete_security_filter

    $foo->delete_security_filter(
        SECURITY_FILTER => "sec_filter_name",
        LOCATION        => "location_path",
        PROJECT         => "project_name"
    );

Optional parameters: 
        LOCATION        => "location_path"

DELETE SECURITY FILTER "<sec_filter_name>" [FOLDER "<location_path>"] FROM PROJECT "<project_name>";

=cut

sub delete_security_filter {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(SECURITY_FILTER LOCATION PROJECT);
my @required = qw(SECURITY_FILTER PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/SECURITY_FILTER/ && do { $result .= "DELETE SECURITY FILTER " . $q . $self->{SECURITY_FILTER} . $q . " "};
	/LOCATION/ && do { $result .= "FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FROM PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 delete_security_role

    $foo->delete_security_role("sec_role_name");

DELETE SECURITY ROLE "<sec_role_name>";

=cut

sub delete_security_role {
	my $self = shift;
	$self->{SECURITY_ROLE} = shift;
	if(!defined($self->{SECURITY_ROLE})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
	return "DELETE SECURITY ROLE " . $q . $self->{SECURITY_ROLE} . $q . ";";
}

=head2 delete_shortcut

    $foo->delete_shortcut(
        LOCATION              => "location_path",
        PROJECT_CONFIG_OBJECT => "project_config_object",
        NAME                  => "shortcut_name",
        PROJECT               => "project_name"
    );


DELETE SHORTCUT IN FOLDER "<location_path>" FOR (FOLDER | CONSOLIDATION | DOCUMENT | FILTER | METRIC | PROMPT | REPORT | SEARCH | TEMPLATE | ATTRIBUTE | FACT | FUNCTION | HIERARCHY | TABLE | TRANSFORMATION | DRILLMAP | SECFILTER | AUTOSTYLE | BASEFORMULA) "<shortcut_name>" FOR PROJECT "<project_name>"; 

DELETE SHORTCUT IN FOLDER "\Project Objects" FOR FOLDER "Drill Maps" FOR PROJECT "MicroStrategy Tutorial";

    $foo->delete_shortcut(
        LOCATION              => '\Project Objects',
        PROJECT_CONFIG_OBJECT => "FOLDER",
        NAME                  => "Drill Maps",
        PROJECT               => "MicroStrategy Tutorial"
    );

=cut

sub delete_shortcut {
my $self = shift;
$self->{ACTION} = "DELETE ";
$self->shortcut(@_);
}

=head2 delete_user_group

    $foo->delete_user_group("user_group");

DELETE USER GROUP "<user_group>";

=cut

sub delete_user_group {
	my $self = shift;
	$self->{USER_GROUP} = shift;
	my $result;
	if(!defined($self->{USER_GROUP})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
	return "DELETE USER GROUP " . $q . $self->{USER_GROUP} . $q . ";";
}

=head2 delete_user

    $foo->delete_user( USER => "login_name", CASCADE => "TRUE" | "FALSE" );

Optional parameters: 
	CASCADE => "TRUE" | "FALSE"

DELETE USER "<login_name>" [CASCADE PROFILES];

=cut

sub delete_user {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(USER CASCADE);
my @required = qw(USER);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/USER/ && do { $result .= "DELETE USER " . $q . $self->{USER} . $q . " "};
	/CASCADE/ && do { if($self->{CASCADE} eq "TRUE") {$result .= "CASCADE PROFILES "; } };
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 delete_user_profile

    $foo->delete_user_profile(
        USER_PROFILE => "login_name",
        PROJECT      => "project_name"
    );


Optional parameters: USER => ,PROJECT => 

DELETE [USER] PROFILE "<login_name>" FROM [PROJECT] "<project_name>";

=cut

sub delete_user_profile {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(USER_PROFILE PROJECT);
my @required = qw(USER_PROFILE PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/USER_PROFILE/ && do { $result .= "DELETE USER PROFILE " . $q . $self->{USER_PROFILE} . $q . " "};
	/PROJECT/ && do { $result .= "FROM PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 disconnect_database_connection

    $foo->disconnect_database_connection(
        CONNECTION => "ALL" | "connection_id" );

This command can be used only in 3-tier Project Source Names.

DISCONNECT ([ALL] DATABASE CONNECTIONS | DATABASE CONNECTION <connection_id>);

=cut

sub disconnect_database_connection {
my $self = shift;
$self->{CONNECTION} = shift;
my $result;
$result .= $self->{CONNECTION} eq "ALL" 
		? "DISCONNECT ALL DATABASE CONNECTIONS;" 
		: "DISCONNECT DATABASE CONNECTION " . $self->{CONNECTION} . ";";

return $result;
}

=head2 disconnect_user

    $foo->disconnect_user(
        USER         => "login_name",
        SESSIONID    => "sessionid",
        PROJECT      => "project_name",
        ALL_SESSIONS => "TRUE" | "FALSE"
    );

This command can be used only in 3-tier Project Source Names. 

DISCONNECT ([ALL] USER SESSIONS [FROM PROJECT "<project_name>"] | USER "<login_name>" | USER SESSIONID <sessionid>);

=cut

sub disconnect_user {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(ALL_SESSIONS USER SESSIONID PROJECT);
my @required = qw();
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
$result .= "DISCONNECT ";
for(@selected) {
	/ALL_SESSIONS/ && do { $result .= "ALL USER SESSIONS "; };
	/USER/ && do { $result .= "USER " . $q . $self->{USER} . $q . " "; };
	/SESSIONID/ && do { $result .= "USER SESSIONID " . $self->{SESSIONID} . " "; };
	/PROJECT/ && do { $result .= "FROM PROJECT " . $q . $self->{PROJECT} . $q . " "; };

}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 expire_report_cache

    $foo->expire_report_cache(
        REPORT_CACHE => "ALL" | "cache_name",
        PROJECT      => "project_name"
    );

This command can be used only in 3-tier Project Source Names.

EXPIRE ([ALL] REPORT CACHES | REPORT CACHE "<cache_name>") IN PROJECT "<project_name>";

=cut

sub expire_report_cache {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(REPORT_CACHE PROJECT);
my @required = qw();
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/REPORT_CACHE/ && do { $result .= "EXPIRE " . $self->{EXPIRE} . " "};
	/PROJECT/ && do { $result .= "IN PROJECT " . $self->{PROJECT} . " "};
}

return $result;
}

=head2 get_attribute_candidates

internal routine

=cut

sub get_attribute_candidates {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(ATTRIBUTE LOCATION PROJECT);
my @required = qw(ATTRIBUTE LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/ATTRIBUTE/ && do { $result .= $self->{ACTION} . "CANDIDATES FOR ATTRIBUTE " . $q . $self->{ATTRIBUTE} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}


=head2 get_attribute_child_candidates

    $foo->get_attribute_child_candidates(
        ATTRIBUTE => "attribute_name",
        LOCATION  => "location_path",
        PROJECT   => "project_name"
    );

GET CHILD CANDIDATES FOR ATTRIBUTE "<attribute_name>" IN [FOLDER] "<location_path>" FOR PROJECT "<project_name>";

=cut

sub get_attribute_child_candidates {
	my $self = shift;
	$self->{ACTION} = "GET CHILD ";
	$self->get_attribute_candidates(@_);
}


=head2 get_attribute_parent_candidates

    $foo->get_attribute_parent_candidates(
        ATTRIBUTE => "attribute_name",
        LOCATION  => "location_path",
        PROJECT   => "project_name"
    );

GET PARENT CANDIDATES FOR ATTRIBUTE "<attribute_name>" IN [FOLDER] "<location_path>" FOR PROJECT "<project_name>";

=cut

sub get_attribute_parent_candidates {
	my $self = shift;
	$self->{ACTION} = "GET PARENT ";
	$self->get_attribute_candidates(@_);
}


=head2 get_object_property

    $foo->get_object_property(
        PROPERTIES            => [ "property1", "propertyN" ],
        PROJECT_CONFIG_OBJECT => "project_config_object",
        OBJECT_NAME           => "object_name",
        LOCATION              => "location_path",
        PROJECT               => "project_name"
    );

GET PROPERTIES "<property1>", "<property2>", ... "<propertyN>" FROM (FOLDER | CONSOLIDATION | DOCUMENT | FILTER | METRIC | PROMPT | REPORT | SEARCH | TEMPLATE | ATTRIBUTE | FACT | FUNCTION | HIERARCHY | TABLE | TRANSFORMATION | DRILLMAP | SECFILTER | AUTOSTYLE | BASEFORMULA | SHORTCUT) "<object_name>" IN FOLDER "<location_path>" FOR PROJECT "<project_name>";

Note: This is the object hierarchy used in property management. To identify an object at a lower hierarchy, just specify the name of the object at the top level.

Some information provided by this statement is similar to that of "LIST PROPERTIES..." command, however, GET statement is much more flexible and customizable than LIST ALL PROPERTIES statement. Using GET statement, you can get any of the common properties, such as name, id, description, location, creation time, modification time, owner, long description, hidden from any object (folder, consolidation, filter,...).

TABLE = LOGICAL TABLE, WAREHOUSE PARTITION TABLE, METADATA PARTITION TABLE
METRIC = SUBTOTAL, PREDICTIVE METRIC
FILTER = CUSTOMGROUP
REPORT = GRID, GRAPH, GRIDGRAPH, DATAMART, SQL
DOCUMENT = REPORTSERVICE DOCUMENT, HTML DOCUMENT
PROPERTIES = NAME , ID, DESCRIPTION, LOCATION, CREATIONTIME, MODIFICATIONTIME, OWNER, LONGDESCRIPTION, HIDDEN

Note:  When two or more shortcuts in a folder have the same name, GET/SET command will treat all of them equally. This means the SET command will set all of them to either hidden or visible. The GET command will show the specified property for all of them.

=cut

sub get_object_property {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(PROPERTIES PROJECT_CONFIG_OBJECT OBJECT_NAME LOCATION PROJECT);
my @required = qw(PROPERTIES PROJECT_CONFIG_OBJECT OBJECT_NAME LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/PROPERTIES/ && do { $result .= "GET PROPERTIES " . join(", ", @{$self->{PROPERTIES}}) . " "};
	/^PROJECT_CONFIG_OBJECT$/ && do { $result .= "FROM " . $self->{PROJECT_CONFIG_OBJECT} . " "};
	/OBJECT_NAME/ && do { $result .= $q . $self->{OBJECT_NAME} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/^PROJECT$/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 get_tables_from_expression

    $foo->get_tables_from_expression(
        EXPRESSION => "expression",
        PROJECT    => "project_name"
    );

GET TABLES FROM EXPRESSION "<expression>" IN PROJECT "<project_name>";

=cut

sub get_tables_from_expression {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(EXPRESSION PROJECT);
my @required = qw(EXPRESSION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/EXPRESSION/ && do { $result .= "GET TABLES FROM EXPRESSION " . $q . $self->{EXPRESSION} . $q . " "};
	/PROJECT/ && do { $result .= "IN PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 grant_privileges

    $foo->grant_privileges(
        PRIVILEGE     => [ "privilege1", "privilegeN" ],
        USER          => "login_name",
        GROUP         => "user_group_name",
        SECURITY_ROLE => "sec_role_name"
    );


GRANT <privilege1> [, <privilege2> [, ... <privilegeN>]]] TO ([USER] "<login_name>" | [USER] GROUP "<user_group_name>" | SECURITY ROLE "<sec_role_name>");

GRANT CREATESCHEMAOBJECTS, SCHEDULEREQUEST, USEOBJECTMANAGER, USEVLDBEDITOR TO USER "Developer";

    $foo->grant_privileges(
        PRIVILEGE => [
            qw(CREATESCHEMAOBJECTS
              SCHEDULEREQUEST USEOBJECTMANAGER USEVLDBEDITOR)
        ],
        USER => "Developer"
    );

			
GRANT WEBDRILLING, WEBEXPORT, WEBOBJECTSEARCH, WEBSORT, WEBUSER, WEBADMIN TO GROUP "Managers";

    $foo->grant_privileges(
        PRIVILEGE => [
            qw(WEBDRILLING WEBEXPORT
              WEBOBJECTSEARCH WEBSORT WEBUSER WEBADMIN)
        ],
        GROUP => "Managers"
    );

GRANT USESERVERCACHE, USECUSTOMGROUPEDITOR, USEMETRICEDITOR TO SECURITY ROLE "Normal Users";

    $foo->grant_privileges(
        PRIVILEGE => [
            qw(USESERVERCACHE
              USECUSTOMGROUPEDITOR USEMETRICEDITOR)
        ],
        SECURITY_ROLE => "Normal Users"
    );

=cut

sub grant_privileges {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(PRIVILEGE USER GROUP SECURITY_ROLE);
my @required = qw(PRIVILEGE);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/PRIVILEGE/ && do { $result .= "GRANT " . join(", ", @{$self->{PRIVILEGE}}) . " "};
	/USER/ && do { $result .= "TO USER " . $q . $self->{USER} . $q . " "};
	/GROUP/ && do { $result .= "TO GROUP " . $q . $self->{GROUP} . $q . " "};
	/SECURITY_ROLE/ && do { $result .= "TO SECURITY ROLE " . $q . $self->{SECURITY_ROLE} . $q . " "};

}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 grant_security_roles

    $foo->grant_security_roles(
        SECURITY_ROLE => "sec_role_name",
        USER          => "login_name",
        GROUP         => "user_group_name",
        PROJECT       => "project_name"
    );

Optional parameters: 
        USER          => "login_name",
        GROUP         => "user_group_name"


GRANT [SECURITY ROLE] "<sec_role_name>" TO [USER] ("<login_name>" | GROUP "<user_group_name>") ON [PROJECT] "<project_name>";

=cut

sub grant_security_roles {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(SECURITY_ROLE USER GROUP PROJECT);
my @required = qw(SECURITY_ROLE PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/SECURITY_ROLE/ && do { $result .= "GRANT SECURITY ROLE " . $q . $self->{SECURITY_ROLE} . $q . " "};
	/USER/ && do { $result .= "TO USER " . $q . $self->{USER} . $q . " "};
	/GROUP/ && do { $result .= "TO GROUP " . $q . $self->{GROUP} . $q . " "};
	/PROJECT/ && do { $result .= "ON PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 idle_project

    $foo->idle_project(
        PROJECT => "project_name",
        MODE => "REQUEST" | "EXECUTION" | "FULL" | "PARTIAL" | "WAREHOUSEEXEC"
    );

This command can be used only in 3-tier Project Source Names.

IDLE PROJECT "<project_name>" MODE (REQUEST | EXECUTION | FULL | PARTIAL | WAREHOUSEEXEC);

=cut

sub idle_project {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(PROJECT MODE);
my @required = qw(PROJECT MODE);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/PROJECT/ && do { $result .= "IDLE PROJECT " . $q . $self->{PROJECT} . $q . " "};
	/MODE/ && do { $result .= "MODE " . $self->{MODE} . ";"};
}

return $result;
}

=head2 invalidate_report_cache

	$foo->invalidate_report_cache(
        	REPORT_CACHE => "ALL" | "cache_name",
		WHTABLE      => "WH_Table_name",
		PROJECT      => "project_name"
	);

Optional parameters: 
		WHTABLE => "<WH_Table_name>"

This command can be used only in 3-tier Project Source Names.

INVALIDATE ([ALL] REPORT CACHES [WHTABLE "<WH_Table_name>"] | REPORT CACHE "<cache_name>") IN PROJECT "<project_name>";

=cut

sub invalidate_report_cache {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(REPORT_CACHE WHTABLE PROJECT);
my @required = qw(REPORT_CACHE PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/REPORT_CACHE/ && do { 
		$result .= "INVALIDATE ";
	        $result .= $self->{REPORT_CACHE} eq "ALL"
	       	        ? ("ALL REPORT CACHES ")
			: ("REPORT CACHE " . $q . $self->{REPORT_CACHE} . $q . " ");
	};
	/WHTABLE/ && do { $result .= "WHTABLE " . $q . $self->{WHTABLE} . $q . " "};
	/PROJECT/ && do { $result .= "IN PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 kill_job

    $foo->kill_job( JOB => "job_id", USER => "login_name" );

Optional parameters: ALL => ,FOR => USER "<login_name>"

This command can be used only in 3-tier Project Source Names.

KILL (JOB <job_id> | [ALL] JOBS [FOR [USER] "<login_name>"]);

=cut

sub kill_job {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(JOB USER);
my @required = qw();
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
$result = "KILL ";
for(@selected) {
	/JOB/ && do { $result .= "JOB " . $self->{JOB} . ";"};
	/USER/ && do { $result .= "ALL JOBS FOR USER " . $q . $self->{USER} . $q . ";"};
}

return $result;
}

=head2 list_acl_properties

    $foo->list_acl_properties(
        OBJECT_TYPE => "configuration_object_type" | "project_object_type" |
          "FOLDER",
        OBJECT_NAME => "object_name",
        LOCATION    => "location_path",
        PROJECT     => "project_name"
    );


LIST [ALL] PROPERTIES FOR ACL FROM (<conf_object_type> "<object_name>" | (<project_object_type> "<object_name>" | FOLDER "<folder_name>") IN FOLDER "<location_path>" FOR PROJECT "<project_name>");

=cut

sub list_acl_properties {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(OBJECT_TYPE OBJECT_NAME LOCATION PROJECT);
my @required = qw(OBJECT_NAME);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
$result = "LIST ALL PROPERTIES FOR ACL FROM ";
for(@selected) {
	/OBJECT_TYPE/ && do { $result .= $self->{OBJECT_TYPE} . " "};
	/OBJECT_NAME/ && do { $result .= $q . $self->{OBJECT_NAME} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " .  $q . $self->{PROJECT} . $q . " "};
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 list_all_connection_maps

    $foo->list_all_connection_maps("project_name");

LIST ALL CONNECTION MAP FOR PROJECT "<project_name>";

=cut

sub list_all_connection_maps {
	my $self = shift;
	$self->{PROJECT} = shift;
	if(!defined($self->{PROJECT})) { croak("\nRequired parameter not defined: PROJECT\n"); }
	return "LIST ALL CONNECTION MAP FOR PROJECT " . $q . $self->{PROJECT} . $q . ";";
}

=head2 list_all_dbconnections

    $foo->list_all_dbconnections;

LIST [ALL] (DBCONNECTIONS | DBCONNS);

LIST ALL DBCONNECTIONS;

=cut

sub list_all_dbconnections { return "LIST ALL DBCONNECTIONS;"; }

=head2 list_all_dbinstances

    $foo->list_all_dbinstances;

LIST [ALL] DBINSTANCES;


=cut

sub list_all_dbinstances { return "LIST ALL DBINSTANCES;" }

=head2 list_all_dblogins

    $foo->list_all_dblogins;

LIST ALL DBLOGINS;

=cut

sub list_all_dblogins { return "LIST ALL DBLOGINS;" }

=head2 list_all_servers

    $foo->list_all_servers;

LIST ALL SERVERS;

=cut

sub list_all_servers { return "LIST ALL SERVERS;"; }

=head2 list_attribute_properties

    $foo->list_attribute_properties(
        ATTRIBUTE => "attribute_name",
        LOCATION  => "location_path",
        PROJECT   => "project_name"
    );

LIST [ALL] PROPERTIES FOR ATTRIBUTE "<attribute_name>" IN FOLDER "<location_path>" FOR PROJECT "<project_name>";

=cut

sub list_attribute_properties {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(ATTRIBUTE LOCATION PROJECT);
my @required = qw(ATTRIBUTE LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/ATTRIBUTE/ && do { $result .= "LIST ALL PROPERTIES FOR ATTRIBUTE " . $q . $self->{ATTRIBUTE} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 list_attributes

    $foo->list_attributes(
        LOCATION => "location_path",
        PROJECT  => "project_name"
    );

Optional parameters:
        LOCATION => "location_path"

LIST [ALL] ATTRIBUTES [IN FOLDER "<location_path>"] FOR PROJECT "<project_name>";

=cut

sub list_attributes {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(LOCATION PROJECT);
my @required = qw(PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/LOCATION/ && do { $result .= "LIST ALL ATTRIBUTES IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 list_caching_properties

    $foo->list_caching_properties(
        CACHE_TYPE => "REPORT" | "OBJECT" | "ELEMENT",
        PROJECT    => "project_name"
    );

Optional parameters: 
	  CACHE_TYPE => "REPORT" | "OBJECT" | "ELEMENT"
      
This command can be used only in 3-tier Project Source Names.

LIST [ALL] PROPERTIES FOR [(REPORT | OBJECT | ELEMENT)] CACHING IN [PROJECT] "<project_name>";

=cut

sub list_caching_properties {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(CACHE_TYPE PROJECT);
my @required = qw(PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
$result .= "LIST ALL PROPERTIES FOR ";
for(@selected) {
	/CACHE_TYPE/ && do { $result .=  $self->{CACHE_TYPE} . " " };
	/PROJECT/ && do { $result .= "CACHING IN PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 list_custom_group_properties

    $foo->list_custom_group_properties(
        CUSTOMGROUP => "customgroup_name",
        LOCATION    => "location_path",
        PROJECT     => "project_name"
    );


LIST [ALL] PROPERTIES FOR CUSTOMGROUP "<customgroup_name>" IN FOLDER "<location_path>" FOR PROJECT "<project_name>";

=cut

sub list_custom_group_properties {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(CUSTOMGROUP LOCATION PROJECT);
my @required = qw(CUSTOMGROUP LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/CUSTOMGROUP/ && do { $result .= "LIST ALL PROPERTIES FOR CUSTOMGROUP " . $q . $self->{CUSTOMGROUP} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 list_custom_groups

    $foo->list_custom_groups(
        LOCATION => "location_path",
        PROJECT  => "project_name"
    );


Optional parameters: 
        LOCATION => "location_path"

LIST [ALL] CUSTOMGROUPS [IN FOLDER "<location_path>"] FOR PROJECT "<project_name>";

=cut

sub list_custom_groups {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(LOCATION PROJECT);
my @required = qw(PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/LOCATION/ && do { $result .= "LIST ALL CUSTOMGROUPS IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 list_dbconnection_properties

    $foo->list_dbconnection_properties(
        PROPERTIES   => "ALL" | [ "property_name1", "property_nameN" ],
        DBCONNECTION => "dbConnection_name"
    );

LIST ([ALL] PROPERTIES | <property_name1> [, <property_name2> [, ... <property_nameN>]]) FOR DBCONNECTION "<dbConnection_name>";

PROPERTIES: ID, NAME, ODBCDSN, DEFAULTLOGIN, DRIVERMODE, EXECMODE, MAXCANCELATTEMPT, MAXQUERYEXEC, CHARSETENCODING, TIMEOUT, IDLETIMEOUT

=cut

sub list_dbconnection_properties {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(PROPERTIES DBCONNECTION);
my @required = qw(PROPERTIES DBCONNECTION);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/PROPERTIES/ && do { 
		$result .= "LIST ";
		$result .= $self->{PROPERTIES} eq "ALL"
		        ?  "ALL PROPERTIES "
			: ( join(", ", @{$self->{PROPERTIES}}) . " ");
	};
	/DBCONNECTION/ && do { $result .= "FOR DBCONNECTION " . $q . $self->{DBCONNECTION} . $q . ";"};
}

return $result;
}

=head2 list_dbinstance_properties

    $foo->list_dbinstance_properties("dbinstance_name");

LIST [ALL] PROPERTIES FOR DBINSTANCE "<dbinstance_name>";

=cut

sub list_dbinstance_properties {
	my $self = shift;
	$self->{DBINSTANCE} = shift;
	if(!defined($self->{DBINSTANCE})) { croak("\nRequired parameter not defined: DBINSTANCE\n"); }
	return "LIST ALL PROPERTIES FOR DBINSTANCE " . $q . $self->{DBINSTANCE} . $q . ";";
}

=head2 list_dblogin_properties

    $foo->list_dblogin_properties(
        PROPERTIES => "ALL" | [ "property_name1", "property_nameN" ],
        DBLOGIN    => "dblogin_name"
    );


LIST ([ALL] PROPERTIES | <property_name1> [, <property_name2> [, ... <property_nameN>]]) FOR DBLOGIN "<dblogin_name>";

PROPERTIES: ID NAME LOGIN

LIST NAME, LOGIN FOR DBLOGIN "Data";

=cut

sub list_dblogin_properties {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(PROPERTIES DBLOGIN);
my @required = qw(PROPERTIES DBLOGIN);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/PROPERTIES/ && do { 
		$result .= "LIST ";
		$result .= $self->{PROPERTIES} eq "ALL"
		        ?  "ALL PROPERTIES "
			: ( join(", ", @{$self->{PROPERTIES}}) . " ");
	};
	/DBLOGIN/ && do { $result .= "FOR DBLOGIN " . $q . $self->{DBLOGIN} . $q . ";"};
}

return $result;
}

=head2 list_database_connection_properties

    $foo->list_database_connection_properties("connection_id");

This command can be used only in 3-tier Project Source Names.

LIST [ALL] PROPERTIES FOR DATABASE CONNECTION <connection_id>;

=cut

sub list_database_connection_properties {
	my $self = shift;
	$self->{CONNECTION} = shift;
	if(!defined($self->{CONNECTION})) { croak("\nRequired parameter not defined: CONNECTION"); }
	return "LIST ALL PROPERTIES FOR DATABASE CONNECTION " . $self->{CONNECTION} . ";";
}

=head2 list_database_connections

    $foo->list_database_connections( "ALL" | "ACTIVE" );

This command can be used only in 3-tier Project Source Names.

LIST [ALL | ACTIVE] DATABASE CONNECTIONS;

=cut

sub list_database_connections {
	my $self = shift;
	$self->{TYPE} = shift; 
	if(!defined($self->{TYPE})) { croak("\nRequired parameter not defined: TYPE\n"); }
	return "LIST " . $self->{TYPE} . " DATABASE CONNECTIONS;";
}

=head2 list_events

    $foo->list_events;

LIST [ALL] EVENTS;

=cut

sub list_events{ return "LIST ALL EVENTS;"; }

=head2 list_fact_properties

    $foo->list_fact_properties(
        FACT     => "fact_name",
        LOCATION => "location_path",
        PROJECT  => "project_name"
    );

LIST [ALL] PROPERTIES FOR FACT "<fact_name>" IN FOLDER "<location_path>" FOR PROJECT "<project_name>";

=cut

sub list_fact_properties {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(FACT LOCATION PROJECT);
my @required = qw(FACT LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/FACT/ && do { $result .= "LIST ALL PROPERTIES FOR FACT " . $q . $self->{FACT} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 list_facts

    $foo->list_facts(
        LOCATION => "location_path",
        PROJECT  => "project_name"
    );

Optional parameters: 
        LOCATION => "location_path"

LIST [ALL] FACTS [IN FOLDER "<location_path>"] FOR PROJECT "<project_name>";

=cut

sub list_facts {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(LOCATION PROJECT);
my @required = qw(PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/LOCATION/ && do { $result .= "LIST ALL FACTS IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 list_filter_properties

    $foo->list_filter_properties(
        FILTER   => "filter_name",
        LOCATION => "location_path",
        PROJECT  => "project_name"
    );

LIST [ALL] PROPERTIES FOR FILTER "<filter_name>" IN [FOLDER] "<location_path>" FROM PROJECT "<project_name>";

=cut

sub list_filter_properties {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(FILTER LOCATION PROJECT);
my @required = qw(FILTER LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/FILTER/ && do { $result .= "LIST ALL PROPERTIES FOR FILTER " . $q . $self->{FILTER} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FROM PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 list_filters

    $foo->list_filters(
        LOCATION => "location_path",
        OWNER    => "login_name",
        PROJECT  => "project_name"
    );

Optional parameters: 
        OWNER    => "login_name",

LIST [ALL] FILTERS [IN [FOLDER] "<location_path>"] [FOR OWNER "<login_name>"] FOR PROJECT "<project_name>";

=cut

sub list_filters {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(LOCATION OWNER PROJECT);
my @required = qw(LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/LOCATION/ && do { $result .= "LIST ALL FILTERS IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/OWNER/ && do { $result .= "FOR OWNER " . $q . $self->{OWNER} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 list_folder_properties

    $foo->list_folder_properties(
        FOLDER   => "folder_name",
        LOCATION => "location_path",
        PROJECT  => "project_name"
    );

LIST [ALL] PROPERTIES FOR FOLDER "<folder_name>" IN "<location_path>" FOR PROJECT "<project_name>";

=cut

sub list_folder_properties {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(FOLDER LOCATION PROJECT);
my @required = qw(FOLDER LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/FOLDER/ && do { $result .= "LIST ALL PROPERTIES FOR FOLDER " . $q . $self->{FOLDER} . $q . " "};
	/LOCATION/ && do { $result .= "IN " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 list_folders

    $foo->list_folders(
        LOCATION => "location_path",
        PROJECT  => "project_name"
    );

LIST [ALL] FOLDERS IN "<location_path>" FOR PROJECT "<project_name>";

=cut

sub list_folders {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(LOCATION PROJECT);
my @required = qw(LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/LOCATION/ && do { $result .= "LIST ALL FOLDERS IN " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 list_job_properties

    $foo->list_job_properties("job_id");

This command can be used only in 3-tier Project Source Names.

LIST [ALL] PROPERTIES FOR JOB <job_id>;

=cut

sub list_job_properties {
	my $self = shift;
	$self->{JOB} = shift;
	if(!defined($self->{JOB})) { croak("\nRequired parameter not defined: JOB\n"); }
	return "LIST ALL PROPERTIES FOR JOB " . $self->{JOB} . ";";
}

=head2 list_jobs

    $foo->list_jobs( TYPE => "ALL" | "ACTIVE", USER => "login_name" );

Optional parameters: 
	USER => "login_name"

This command can be used only in 3-tier Project Source Names.

LIST [ALL | ACTIVE] JOBS [FOR USER "<login_name>"];

=cut

sub list_jobs {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(TYPE USER);
my @required = qw(TYPE);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/TYPE/ && do { $result .= "LIST " . $self->{TYPE} . " JOBS "};
	/USER/ && do { $result .= "FOR USER " . $q . $self->{USER} . $q . " "};
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 list_lock_properties

    $foo->list_lock_properties("project_name");

Optional parameters: "project_name" 

LIST [ALL] PROPERTIES FOR LOCK IN (CONFIGURATION | PROJECT "<project_name>");

LIST ALL PROPERTIES FOR LOCK IN PROJECT "MicroStrategy Tutorial";

    $foo->list_lock_properties("MicroStrategy Tutorial");

LIST ALL PROPERTIES FOR LOCK IN CONFIGURATION;
    
    $foo->list_lock_properties;

=cut

sub list_lock_properties {
	my $self = shift;
	$self->{PROJECT} = shift;
	return ($self->{PROJECT}) 
		? ("LIST ALL PROPERTIES FOR LOCK IN PROJECT " . $q . $self->{PROJECT} . $q . ";") 
		: ("LIST ALL PROPERTIES FOR LOCK IN CONFIGURATION;");
}

=head2 list_metric_properties

    $foo->list_metric_properties(
        METRIC   => "metric_name",
        LOCATION => "location_path",
        PROJECT  => "project_name"
    );

LIST [ALL] PROPERTIES FOR METRIC "<metric_name>" IN [FOLDER] "<location_path>" FROM PROJECT "<project_name>";

=cut

sub list_metric_properties {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(METRIC LOCATION PROJECT);
my @required = qw(METRIC LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/METRIC/ && do { $result .= "LIST ALL PROPERTIES FOR METRIC " . $q . $self->{METRIC} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FROM PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 list_metrics

    $foo->list_metrics(
        LOCATION => "location_path",
        OWNER    => "login_name",
        PROJECT  => "project_name"
    );

Optional parameters:
        LOCATION => "location_path",
        OWNER    => "login_name"

LIST [ALL] METRICS [IN [FOLDER] "<location_path>"] [FOR OWNER "<login_name>"] FOR PROJECT "<project_name>";

=cut

sub list_metrics {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(LOCATION OWNER PROJECT);
my @required = qw(PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
$result .= "LIST ALL METRICS ";
for(@selected) {
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/OWNER/ && do { $result .= "FOR OWNER " . $q . $self->{OWNER} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 list_project_config_properties

    $foo->list_project_config_properties("project_name");

This command can be used only in 3-tier Project Source Names.

LIST [ALL] PROPERTIES FOR PROJECT CONFIGURATION FROM PROJECT "<project_name>";

=cut

sub list_project_config_properties {
	my $self = shift;
	$self->{PROJECT} = shift;
	if(!defined($self->{PROJECT})) { croak("\nRequired parameter not defined: PROJECT\n"); }
	return "LIST ALL PROPERTIES FOR PROJECT CONFIGURATION FROM PROJECT " . $q . $self->{PROJECT} . $q . ";";
}

=head2 list_project_properties

    $foo->list_project_properties(
        PROPERTIES => "ALL" | [ "prop_name1", "prop_nameN" ],
        PROJECT    => "project_name"
    );


LIST ([ALL] PROPERTIES | <prop_name1> [, <prop_name2> [, ... <prop_nameN>]]) FOR PROJECT "<project_name>";

PROPERTIES: DESCRIPTION NAME ID CREATIONTIME MODIFICATIONTIME 

=cut

sub list_project_properties {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(PROPERTIES PROJECT);
my @required = qw(PROPERTIES PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/PROPERTIES/ && do { 
		$result .= "LIST ";
		$result .= $self->{PROPERTIES} eq "ALL"
		        ?  "ALL PROPERTIES "
			: ( join(", ", @{$self->{PROPERTIES}}) . " ");
	};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 list_projects_cluster

    $foo->list_projects_cluster;

This command can be used only in 3-tier Project Source Names.

LIST [ALL] PROJECTS FOR CLUSTER; 

This List command only returns the project(s) that is(are) loaded either on a server or on all servers. 
To see a list of the available project(s) on the cluster, please use the LIST PROJECTS command. 

=cut

sub list_projects_cluster { return "LIST ALL PROJECTS FOR CLUSTER;"; }

=head2 list_projects

    $foo->list_projects( "ALL" | "REGISTERED" | "UNREGISTERED" );

LIST [(ALL | REGISTERED | UNREGISTERED)] PROJECTS;

=cut

sub list_projects {
	my $self = shift;
	$self->{TYPE} = shift;
	if(!defined($self->{TYPE})) { croak("\nRequired parameter not defined: ALL | REGISTERED | UNREGISTERED\n"); }
	return "LIST " . $self->{TYPE} . " PROJECTS;";
}

=head2 list_report_cache_properties

    $foo->list_report_cache_properties(
        REPORT_CACHE => "cache_name",
        PROJECT      => "project_name"
    );

This command can be used only in 3-tier Project Source Names.

LIST [ALL] PROPERTIES FOR REPORT CACHE "<cache_name>" IN PROJECT "<project_name>";

=cut

sub list_report_cache_properties {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(REPORT_CACHE PROJECT);
my @required = qw(REPORT_CACHE PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/REPORT_CACHE/ && do { $result .= "LIST ALL PROPERTIES FOR REPORT CACHE " . $q. $self->{REPORT_CACHE} . $q . " "};
	/PROJECT/ && do { $result .= "IN PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 list_report_caches

    $foo->list_report_caches("project_name");

This command can be used only in 3-tier Project Source Names.

LIST [ALL] REPORT CACHES [FOR PROJECT "<project_name>"];

=cut

sub list_report_caches {
	my $self = shift;
	$self->{PROJECT} = shift;
	if(!defined($self->{PROJECT})) { croak("\nRequired parameter not defined: PROJECT" ); }
	return "LIST ALL REPORT CACHES FOR PROJECT " . $q . $self->{PROJECT} . $q . ";";
}

=head2 list_report_properties

    $foo->list_report_properties(
        REPORT   => "report_name",
        LOCATION => "location_path",
        PROJECT  => "project_name"
    );

LIST [ALL] PROPERTIES FOR REPORT "<report_name>" IN FOLDER "<location_path>" FOR PROJECT "<project_name>";

=cut

sub list_report_properties {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(REPORT LOCATION PROJECT);
my @required = qw(REPORT LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/REPORT/ && do { $result .= "LIST ALL PROPERTIES FOR REPORT " . $q . $self->{REPORT} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 list_reports

    $foo->list_reports(
        LOCATION => "location_path",
        PROJECT  => "project_name"
    );

Optional parameters: 
	LOCATION => "<location_path>"

LIST [ALL] REPORTS [IN FOLDER "<location_path>"] FOR PROJECT "<project_name>";

=cut

sub list_reports {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(LOCATION PROJECT);
my @required = qw(PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/LOCATION/ && do { $result .= "LIST ALL REPORTS IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 list_schedule_properties

    $foo->list_schedule_properties("schedule_name");

LIST [ALL] PROPERTIES FOR SCHEDULE "<schedule_name>";

=cut

sub list_schedule_properties {
	my $self = shift;
	$self->{SCHEDULE} = shift;
	if(!defined($self->{SCHEDULE})) { croak("\nRequired parameter not defined: SCHEDULE\n"); }
	return "LIST ALL PROPERTIES FOR SCHEDULE " . $q . $self->{SCHEDULE} . $q . ";";
}

=head2 list_schedule_relations

    $foo->list_schedule_relations(
        SCHEDULE                 => "schedule_name",
        USER_OR_GROUP            => "USER" | "GROUP",
        USER_LOGIN_OR_GROUP_NAME => "user_login_or_group_name",
        REPORT                   => "rep_or_doc_name",
        LOCATION                 => "location_path",
        PROJECT                  => "project_name"
    );
			      );

This command can be used only in 3-tier Project Source Names.

LIST [ALL] SCHEDULERELATIONS [FOR (SCHEDULE "<schedule_name>" | (USER | GROUP) "<user_login_or_group_name>" | REPORT "<rep_or_doc_name>" IN "<location_path>")] IN PROJECT "<project_name>";

=cut

sub list_schedule_relations {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(SCHEDULE USER_OR_GROUP USER_LOGIN_OR_GROUP_NAME REPORT LOCATION PROJECT);
my @required = qw(PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);}
$result .= "LIST ALL SCHEDULERELATIONS ";
for(@selected) {
	/SCHEDULE/&& do { $result .= "FOR SCHEDULE " . $q . $self->{SCHEDULE} . $q . " "; };
	/USER_OR_GROUP/ && do { $result .= "FOR " . $self->{USER_OR_GROUP} . " "; };
	/USER_LOGIN_OR_GROUP_NAME/ && do { $result .= $q . $self->{USER_LOGIN_OR_GROUP_NAME} . $q . " "; };
	/REPORT/ && do { $result .= "FOR REPORT " . $q . $self->{REPORT} . $q . " "; };
	/LOCATION/ && do { $result .= "IN " . $q . $self->{LOCATION} . $q . " "; };
	/PROJECT/ && do { $result .= "IN PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 list_schedules

    $foo->list_schedules;

LIST [ALL] SCHEDULES;

=cut

sub list_schedules { return "LIST ALL SCHEDULES;"; }

=head2 list_security_filter_properties

    $foo->list_security_filter_properties(
        PROPERTIES      => "ALL" | [ "property_name1", "property_nameN" ],
        SECURITY_FILTER => "sec_filter_name",
        LOCATION        => "location_path",
        PROJECT         => "project_name"
    );


Optional parameters: ALL => ,, => <property_name2> , ... <property_nameN>,FOLDER => "<location_path>"

LIST ([ALL] PROPERTIES | <property_name1> [, <property_name2> [, ... <property_nameN>]]]) FOR SECURITY FILTER "<sec_filter_name>" [FOLDER "<location_path>"] OF PROJECT "<project_name>";

PROPERTIES: NAME, ID, TOP ATTRIBUTE LIST, BOTTOM ATTRIBUTE LIST, FILTER

=cut

sub list_security_filter_properties {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(PROPERTIES SECURITY_FILTER LOCATION PROJECT);
my @required = qw(PROPERTIES SECURITY_FILTER PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/PROPERTIES/ && do { 
		$result .= "LIST ";
		$result .= $self->{PROPERTIES} eq "ALL"
		        ?  "ALL PROPERTIES "
			: ( join(", ", @{$self->{PROPERTIES}}) . " ");
	};
	/SECURITY_FILTER/ && do { $result .= "FOR SECURITY FILTER " . $q . $self->{SECURITY_FILTER} . $q . " "};
	/LOCATION/ && do { $result .= "FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "OF PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 list_security_filters

    $foo->list_security_filters(
        USER_OR_GROUP            => "USER" | "GROUP",
        USER_LOGIN_OR_GROUP_NAME => "user_login_or_group_name",
        LOCATION                 => "location_path",
        PROJECT                  => "project_name"
    );


LIST [ALL] SECURITY FILTERS [(USER | GROUP) "<user_login_or_group_name>"] [FOLDER "<location_path>"] FOR PROJECT "<project_name>";

=cut

sub list_security_filters {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(USER_OR_GROUP USER_LOGIN_OR_GROUP_NAME LOCATION PROJECT);
my @required = qw(PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
$result .= "LIST ALL SECURITY FILTERS ";
for(@selected) {
	/USER_OR_GROUP/ && do { $result .= $self->{USER_OR_GROUP} . " "};
	/USER_LOGIN_OR_GROUP_NAME/ && do { $result .= $q . $self->{USER_LOGIN_OR_GROUP_NAME} . $q . " "};
	/LOCATION/ && do { $result .= "FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}
return $result;
}


=head2 list_security_role_properties

    $foo->list_security_role_properties(
        PROPERTIES    => "ALL" | [ "property_name1", "property_nameN" ],
        SECURITY_ROLE => "sec_role_name"
    );


LIST ([ALL] PROPERTIES | <property_name1>, [, <property_name2> [, ... <property_nameN>]]) FOR [SECURITY] ROLE "<sec_role_name>";

PROPERTIES: NAME ID DESCRIPTION

=cut

sub list_security_role_properties {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(PROPERTIES SECURITY_ROLE);
my @required = qw(PROPERTIES SECURITY_ROLE);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/PROPERTIES/ && do { 
		$result .= "LIST ";
		$result .= $self->{PROPERTIES} eq "ALL"
		        ?  "ALL PROPERTIES "
			: ( join(", ", @{$self->{PROPERTIES}}) . " ");
	};
	/SECURITY_ROLE/ && do { $result .= "FOR SECURITY ROLE " . $q . $self->{SECURITY_ROLE} . $q . ";"};
}

return $result;
}

=head2 list_security_role_privileges

    $foo->list_security_role_privileges("sec_role_name");

LIST [ALL] PRIVILEGES FOR SECURITY ROLE "<sec_role_name>";

=cut

sub list_security_role_privileges {
	my $self = shift;
	$self->{SECURITY_ROLE} = shift;
	if(!defined($self->{SECURITY_ROLE})) { croak("\nRequired parameter not defined: SECURITY ROLE\n"); }
	return "LIST ALL PRIVILEGES FOR SECURITY ROLE " . $q . $self->{SECURITY_ROLE} . $q . ";";
}

=head2 list_security_roles

    $foo->list_security_roles;

LIST [ALL] SECURITY ROLES;

=cut

sub list_security_roles { return "LIST ALL SECURITY ROLES;"; }

=head2 list_server_config_properties


    $foo->list_server_config_properties(
        "ALL" | [ "property_name1", "property_nameN" ] );

This command can be used only in 3-tier Project Source Names.

LIST ([ALL] PROPERTIES | property_name1 [, property_name2 [,...property_nameN]]) FOR SERVER CONFIGURATION;

PROPERTIES: MAXCONNECTIONTHREADS  BACKUPFREQ  USENTPERFORMANCEMON USEMSTRSCHEDULER  BALSERVERTHREADS  HISTORYDIR  MAXNOMESSAGES MAXNOJOBS MAXNOCLIENTCONNS IDLETIME WEBIDLETIME MAXNOXMLCELLS MAXNOXMLDRILLPATHS MAXMEMUSAGE MINFREEMEM DESCRIPTION CACHECLEANUPFREQ MESSAGELIFETIME ENABLEWEBTHROTTLING ENABLEMEMALLOC MAXALLOCSIZE ENABLEMEMCONTRACT MINRESERVEDMEM MINRESERVEDMEMPERCENTAGE MAXVIRTUALADDRSPACE MEMIDLETIME WORKSETDIR MAXRAMWORKSET LICENSECHECKTIME SCHEDULERTIMEOUT MAXMEMXML MAXMEMPDF MAXMEMEXCEL 

LIST ALL PROPERTIES FOR SERVER CONFIGURATION;

=cut

sub list_server_config_properties {
	my $self = shift;
	$self->{PROPERTIES} = shift;
	if(!defined($self->{PROPERTIES})) { croak("\nRequired parameter not defined: PROPERTIES\n"); }
	return ref($self->{PROPERTIES})
		? ("LIST " . join(", ", @{$self->{PROPERTIES}}) . " FOR SERVER CONFIGURATION;")
		: ("LIST ALL PROPERTIES FOR SERVER CONFIGURATION;");
}

=head2 list_server_properties

    $foo->list_server_properties("machine_name");

LIST [ALL] PROPERTIES FOR SERVER "<machine_name>";

=cut

sub list_server_properties {
	my $self = shift;
	$self->{SERVER} = shift;
	if(!defined($self->{SERVER})) { croak("\nRequired parameter not defined: SERVER"); }
	return "LIST ALL PROPERTIES FOR SERVER " . $q . $self->{SERVER} . $q . ";";
}

=head2 list_servers_cluster

    $foo->list_servers_cluster;

This command can be used only in 3-tier Project Source Names.

LIST ALL SERVERS IN CLUSTER;

=cut

sub list_servers_cluster { return "LIST ALL SERVERS IN CLUSTER;"; }

=head2 list_shortcut_properties

    $foo->list_shortcut_properties(
        LOCATION            => "location_path",
        PROJECT_CONFIG_TYPE => "project_config_type",
        NAME                => "shortcut_name",
        PROJECT             => "project_name"
    );

PROJECT_CONFIG_TYPES: FOLDER, CONSOLIDATION, DOCUMENT, FILTER, METRIC, PROMPT, REPORT, SEARCH, TEMPLATE, ATTRIBUTE, FACT, FUNCTION, HIERARCHY, TABLE, TRANSFORMATION, DRILLMAP, SECFILTER, AUTOSTYLE, BASEFORMULA 

LIST [ALL] PROPERTIES FOR SHORTCUT IN FOLDER "<location_path>" FOR (FOLDER | CONSOLIDATION | DOCUMENT | FILTER | METRIC | PROMPT | REPORT | SEARCH | TEMPLATE | ATTRIBUTE | FACT | FUNCTION | HIERARCHY | TABLE | TRANSFORMATION | DRILLMAP | SECFILTER | AUTOSTYLE | BASEFORMULA) "<shortcut_name>" FOR PROJECT "<project_name>";

=cut

sub list_shortcut_properties {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(LOCATION PROJECT_CONFIG_TYPE NAME PROJECT);
my @required = qw(LOCATION PROJECT_CONFIG_TYPE NAME PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/LOCATION/ && do { $result .= "LIST ALL PROPERTIES FOR SHORTCUT IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/^PROJECT_CONFIG_TYPE$/ && do { $result .= "FOR " . $self->{PROJECT_CONFIG_TYPE} . " "};
	/NAME/ && do { $result .= $q . $self->{NAME} . $q . " "};
	/^PROJECT$/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 list_shortcuts

    $foo->list_shortcuts(
        LOCATION => "location_path",
        PROJECT  => "project_name"
    );

Optional parameters: ALL => ,IN => FOLDER "<location_path>"

LIST [ALL] SHORTCUTS [IN FOLDER "<location_path>"] FOR PROJECT "<project_name>";

=cut

sub list_shortcuts {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(LOCATION PROJECT);
my @required = qw(PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/LOCATION/ && do { $result .= "LIST ALL SHORTCUTS IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 list_statistics_properties

    $foo->list_statistics_properties("project_name");

This command can be used only in 3-tier Project Source Names.

LIST [ALL] PROPERTIES FOR STATISTICS FROM PROJECT "<project_name>";

=cut

sub list_statistics_properties {
	my $self = shift;
	$self->{PROJECT} = shift;
	if(!defined($self->{PROJECT})) { croak("\nRequired parameter not defined: PROJECT\n"); }
	return "LIST ALL PROPERTIES FOR STATISTICS FROM PROJECT " . $q . $self->{PROJECT} . $q . ";";
}

=head2 list_table_properties

    $foo->list_table_properties(
        TABLE   => "table_name",
        PROJECT => "project_name"
    );

LIST [ALL] PROPERTIES FOR TABLE "<table_name>" FOR PROJECT "<project_name>";

MicroStrategy Notes: 
1. Warehouse Partition Table and Non_Relational Table are not supported.  
2. Warehouse table names are case sensitive; logical table names are not case sensitive.
3.  When listing available warehouse table for a project, make sure this project has at least one associated DBRole.

=cut

sub list_table_properties {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(TABLE PROJECT);
my @required = qw(TABLE PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/TABLE/ && do { $result .= "LIST ALL PROPERTIES FOR TABLE " . $q . $self->{TABLE} . $q. " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 list_tables

    $foo->list_tables(
        LOCATION => "location_path",
        PROJECT  => "project_name"
    );

Optional parameters: 
	LOCATION => "<location_path>"

LIST [ALL] TABLES [IN FOLDER "<location_path>"] FOR PROJECT "<project_name>";

MicroStrategy Notes: 
1. Warehouse Partition Table and Non_Relational Table are not supported.  
2. Warehouse table names are case sensitive; logical table names are not case sensitive.
3.  When listing available warehouse table for a project, make sure this project has at least one associated DBRole.

=cut

sub list_tables {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(LOCATION PROJECT);
my @required = qw(PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/LOCATION/ && do { $result .= "LIST ALL TABLES IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 list_user_conn_properties

    $foo->list_user_conn_properties(
        USER      => "login_name",
        SESSIONID => "sessionID"
    );

This command can be used only in 3-tier Project Source Names.

LIST [ALL] PROPERTIES FOR USER CONNECTION ("<login_name>" | SESSIONID <sessionID>);

=cut

sub list_user_conn_properties {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(USER SESSIONID);
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
$result .= "LIST ALL PROPERTIES FOR USER CONNECTION ";
for(@selected) {
	/USER/ && do { $result .= $q . $self->{USER} . $q . ";"};
	/SESSIONID/ && do {  $result .= "SESSIONID " . $self->{SESSIONID} . ";"};
}
return $result;
}

=head2 list_user_connections

    $foo->list_user_connections( "ALL" | "ACTIVE" );

This command can be used only in 3-tier Project Source Names.

LIST [ALL | ACTIVE] USER CONNECTIONS;

=cut

sub list_user_connections {
	my $self = shift;
	$self->{TYPE} = shift;
	if(!defined($self->{TYPE})) { croak("\nRequired parameter not defined: ALL | ACTIVE\n"); }
	return "LIST " . $self->{TYPE} . " USER CONNECTIONS;";
}

=head2 list_user_group_members

$foo->list_user_group_members("user_group_name");

LIST MEMBERS FOR USER GROUP "<user_group_name>";

LIST MEMBERS FOR USER GROUP "Managers";

=cut

sub list_user_group_members {
	my $self = shift;
	$self->{USER_GROUP} = shift;
	if(!defined($self->{USER_GROUP})) { croak("\nRequired parameter not defined: USER GROUP\n"); }
	return "LIST MEMBERS FOR USER GROUP " . $q . $self->{USER_GROUP} . $q . ";";
}

=head2 list_user_group_privileges

    $foo->list_user_group_members("user_group_name");

LIST [ALL] PRIVILEGES FOR USER GROUP "<user_group_name>";

=cut

sub list_user_group_privileges {
my $self = shift;
	$self->{USER_GROUP} = shift;
	if(!defined($self->{USER_GROUP})) { croak("\nRequired parameter not defined: USER GROUP\n"); }
	return "LIST ALL PRIVILEGES FOR USER GROUP " . $q . $self->{USER_GROUP} . $q . ";";
}

=head2 list_user_group_properties

    $foo->list_user_group_properties(
        PROPERTIES => [ "property_name1", "property_nameN" ],
        USER_GROUP => "user_group_name"
    );

LIST ([ALL] PROPERTIES | <property_name1> [, <property_name2> [, ... <property_nameN>]]]) FOR USER GROUP "<user_group_name>";

PROPERTIES: DESCRIPTION NAME ID LDAPLINK MEMBERS  

=cut

sub list_user_group_properties {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(PROPERTIES USER_GROUP);
my @required = qw(PROPERTIES USER_GROUP);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/PROPERTIES/ && do { 
		$result .= "LIST ";
		$result .= $self->{PROPERTIES} eq "ALL"
		        ?  "ALL PROPERTIES "
			: ( join(", ", @{$self->{PROPERTIES}}) . " ");
	};
	/USER_GROUP/ && do { $result .= "FOR USER GROUP " . $q . $self->{USER_GROUP} . $q . ";"};
}

return $result;
}

=head2 list_user_groups

    $foo->list_user_groups;


LIST [ALL] [USER] GROUPS;

=cut

sub list_user_groups { return "LIST ALL USER GROUPS;" }

=head2 list_user_privileges

    $foo->list_user_privileges(
        TYPE => "ALL | INHERITED | GRANTED",
        USER => "login_name"
    );

Optional parameters: 
       TYPE => "ALL | INHERITED | GRANTED"


LIST [(ALL | INHERITED | GRANTED)] PRIVILEGES FOR USER "<login_name>";

=cut

sub list_user_privileges {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(TYPE USER);
my @required = qw(USER);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/TYPE/ && do { $result .= "LIST " . $self->{TYPE} . " "};
	/USER/ && do { $result .= "PRIVILEGES FOR USER " . $q . $self->{USER} . $q . ";"};
}

return $result;
}

=head2 list_user_profiles

    $foo->list_user_profiles(
        USER    => "login_name" | "ALL",
        GROUP   => "group_name" | [ "group_name1", "group_nameN" ],
        PROJECT => "project_name" | [ "project_name1", "project_nameN" ]
    );


Optional parameters:
        GROUP   => "group_name" | [ "group_name1", "group_nameN" ],
        PROJECT => "project_name" | [ "project_name1", "project_nameN" ]


LIST [ALL] PROFILES FOR (USER "<login_name>" | USERS [IN GROUP(S) "<group_name1>" [, "<group_name2>" [, "<groupnamen>"]]]) [FOR PROJECT(S) "<project_name1>" [, "<projectname2>"[, "<projectnamen>"]]];

=cut

sub list_user_profiles {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(USER GROUP PROJECT);
my @required = qw(USER);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/USER/ && do { $result .= "LIST ALL PROFILES FOR ";
		$result .= ($self->{USER} eq 'ALL')
			? ("USERS ")
			: ( "USER " . $q . $self->{USER} . $q . " " );
	};
	/GROUP/ && do { 
		$result .= ref $self->{GROUP} 
			? ($self->join_objects($_, "IN GROUPS"))
			: ( "IN GROUP " . $q . $self->{GROUP} . $q . " " );
	};
	/PROJECT/ && do { 
		$result .= ref $self->{PROJECT} 
			? ($self->join_objects($_, "FOR PROJECTS"))
			: ( "FOR PROJECT " . $q . $self->{PROJECT} . $q . " " );
	};
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 list_user_properties

    $foo->list_user_properties(
        PROPERTIES => [ "property_name1", "property_nameN" ],
        USER       => "login_name",
        USER_GROUP => "user_group_name"
    );

LIST ([ALL] PROPERTIES | property_name1 [, property_name2 [,...property_namen]]) FOR (USER "<login_name>" | USERS IN GROUP "<user_group_name>");

PROPERTIES: FULLNAME ENABLED NTLINK LDAPLINK WHLINK DESCRIPTION ALLOWCHANGEPWD ALLOWSTDAUTH PASSWORDEXP PASSWORDEXPFREQ NAME 
ID GROUPS CHANGEPWD

=cut

sub list_user_properties {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(PROPERTIES USER USER_GROUP);
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
if(!$self->{PROPERTIES}) { $result .= "LIST ALL PROPERTIES "; }
for(@selected) {
	/PROPERTIES/ && do { $result .= "LIST " . join(", ", @{$self->{PROPERTIES}}) . " "};
	/^USER$/ && do { $result .= "FOR USER " . $q . $self->{USER} . $q . ";"};
	/^USER_GROUP$/ && do { $result .= "FOR USERS IN GROUP " . $q . $self->{USER_GROUP} . $q . ";"};
}

return $result;
}

=head2 list_whtables

    $foo->list_whtables("project_name");

LIST [ALL] AVAILABLE WHTABLES FOR PROJECT "<project_name>";

MicroStrategy Notes:
1. Warehouse Partition Table and Non_Relational Table are not supported.
2. Warehouse table names are case sensitive; logical table names are not case sensitive.
3. When listing available warehouse tables for a project, make sure this project has at least one associated DBRole.
4. That listing available warehouse tables may return Warehouse Partition Tables, but Command Manager does not currently support manipulating Warehouse Partition Tables.

=cut

sub list_whtables {
	my $self = shift;
	$self->{PROJECT} = shift;
	if(!defined($self->{PROJECT})) { croak("\nRequired parameter not defined: PROJECT\n"); }
	return "LIST ALL AVAILABLE WHTABLES FOR PROJECT " . $q . $self->{PROJECT} . $q . ";";
}

=head2 load_project

    $foo->load_project("project_name");

This command can be used only in 3-tier Project Source Names.

LOAD PROJECT "<project_name>";

LOAD PROJECT "MicroStrategy Tutorial";

=cut

sub load_project {
	my $self = shift;
	$self->{PROJECT} = shift;
	if(!defined($self->{PROJECT})) { croak("Required parameter not defined: PROJECT" ); }
	return "LOAD PROJECT " . $q . $self->{PROJECT} . $q . ";";
}

=head2 load_projects_cluster

    $foo->load_projects_cluster(
        PROJECT => "project_name",
        SERVERS => "ALL" | [ "server_name1", "server_nameN" ]
    );

This command can be used only in 3-tier Project Source Names.

LOAD PROJECT "<project_name>" TO CLUSTER  (ALL SERVERS | SERVERS "<server_name1>" [, "<server_name2>" [, "<server_nameN>" ]]);

You can load a project into a server, some servers, or all servers in a cluster. Be aware that changes will take effect immediately.  You will need to unload a project from each individual node before attempting on loading this project to all servers in a cluster.

=cut

sub load_projects_cluster {
	my $self = shift;
	$self->{ACTION} = "LOAD ";
	$self->{DIRECTION} = "TO ";
	$self->project_cluster(@_);
}


=head2 lock_configuration

    $foo->lock_configuration("FORCE");

Optional: FORCE

LOCK CONFIGURATION [FORCE];

=cut

sub lock_configuration { 
	my $self = shift;
	$self->{FORCE} = shift;
	my $result = "LOCK CONFIGURATION ";
	if( defined $self->{FORCE} ) { $result .= "FORCE "; }
	$result =~ s/\s+$//;
	$result .= ";";
	return $result;
}

=head2 lock_project

    $foo->lock_project(
        PROJECT => "project_name",
        FORCE   => "TRUE" | "FALSE"
    );

LOCK PROJECT "<project_name>" [FORCE];

=cut

sub lock_project {
	my $self = shift;
	my %parms = @_;
	@$self{keys %parms} = values %parms;
	my $result;
	my @order = qw(PROJECT FORCE);
	my @required = qw(PROJECT);
	for(@required){
		if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
	}
	my @selected;
	for(@order) { 
		push(@selected, $_) if exists $parms{$_}; 
	}
	for(@selected) {
		/PROJECT/ && do { $result .= "LOCK PROJECT " . $q . $self->{PROJECT} . $q . " "};
		/FORCE/ && ($self->{FORCE} eq "TRUE") && do { $result .= "FORCE " };
	}
	$result =~ s/\s+$//;
	$result .= ";";
	return $result;
}




=head2 log_event

    $foo->log_event(
        MESSAGE => "event_message",
        TYPE    => "ERROR" | "INFORMATION" | "WARNING"
    );

LOG EVENT "<event_message>" TYPE (ERROR | INFORMATION | WARNING);

This sample illustrates the logging of events to the Windows Event Log.
LOG EVENT "Error Custom Message" TYPE ERROR;
LOG EVENT "Info Custom Message" TYPE INFORMATION;
LOG EVENT "Warning Custom Message" TYPE WARNING;

=cut

sub log_event {
	my $self = shift;
	my %parms = @_;
	@$self{keys %parms} = values %parms;
	my $result;
	my @order = qw(MESSAGE TYPE);
	my @required = qw(MESSAGE TYPE);
	for(@required){
		if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
	}
	my @selected;
	for(@order) { 
		push(@selected, $_) if exists $parms{$_}; 
	}
	for(@selected) {
		/MESSAGE/ && do { $result .= "LOG EVENT " . $q . $self->{MESSAGE} . $q . " "};
		/TYPE/ && do { $result .= "TYPE " . $self->{TYPE} . ";"};
	}

	return $result;
}

=head2 privileges_list

    $foo->privileges_list(
        "privilege_group" | [ "privilege_group1", "privilege_groupN" ] );

privilege_groups: web_reporter, web_analyst, web_professional, web_mmt_option, common_privileges, office, desktop_analyst,
desktop_designer, architect, microstrategy_administrator, integrity_manager, administration

=cut

sub privileges_list {
	my $self = shift;
	$self->{PRIVILEGE_GROUP} = shift;
	my $privilege_groups = {
	web_reporter => [ qw(WEBEXECUTEDOCUMENT WEBCHANGEUSEROPTIONS WEBCHANGEVIEWMODE WEBCREATEEMAILADDRESS WEBEXPORT WEBEXPORTTOFILENOW WEBNORMALDRILLING WEBOBJECTSEARCH WEBPRINTMODE WEBPRINTNOW WEBREEXECUTEREPORTAGAINSTWH WEBSCHEDULEEMAIL WEBSCHEDULEDEXPORTTOFILE WEBSCHEDULEDPRINTING WEBSCHEDULEREPORT WEBSENDNOW WEBSORT WEBSWITCHPAGEBY WEBUSER WEBVIEWHISTORYLIST)],
	web_analyst => [ qw(WEBMODIFYGRIDLEVELINDOC WEBCREATEDERIVEDMETRICS WEBNUMBERFORMATTING WEBUSEREPORTOBJECTSWINDOW WEBUSEVIEWFILTEREDITOR WEBADDTOHISTORYLIST WEBADVANCEDDRILLING WEBALIASOBJECTS WEBCHOOSEATTRFORMDISPLAY WEBCONFIGURETOOLBARS WEBCREATEFILELOCATION WEBCREATENEWREPORT WEBCREATEPRINTLOCATION WEBDRILLONMETRICS WEBEXECUTEBULKEXPORT WEBEXECDATAMARTREPORTS WEBFILTERSELECTIONS WEBMANAGEOBJECTS WEBMODIFYSUBTOTALS WEBPIVOTREPORT WEBREPORTDETAILS WEBREPORTSQL WEBSAVEREPORT WEBSAVESHAREDREPORT WEBSIMPLEGRAPHFORMATTING WEBSIMULTANEOUSEXEC WEBUSELOCKEDHEADERS )],
	web_professional => [ qw(WEBDOCDESIGN WEBMANAGEDOCDATASETS WEBDEFINEOLAPCUBEREP WEBFORMATGRIDANDGRAPH WEBMODIFYREPORTLIST WEBSAVETEMPLATEFILTER WEBSETCOLUMNWIDTHS WEBUSEDESIGNMODE WEBUSEREPORTFILTEREDITOR)],
	web_mmt_option => [qw(WEBENABLEMMTACCESS) ],
	common_privileges => [ qw(DRILLWITHINTELLIGENTCUBE CREATEAPPOBJECTS CREATENEWFOLDER CREATESCHEMAOBJECTS CREATESHORTCUT SCHEDULEREQUEST USESERVERCACHE) ],
	office => [ qw(USEOFFICE)],
	mobile => [ qw(USEMSTRMOBILE MOBILEVIEWDOCUMENT)],
	desktop_analyst => [ qw(CREATEDERIVEDMETRICS USEREPORTOBJECTSWINDOW USEVIEWFILTEREDITOR EXECUTEDOCUMENT ALIASOBJECTS CHANGEUSERPREFERENCES CHOOSEATTRIBUTEDISPLAY CONFIGURETOOLBARS MODIFYSUBTOTALS MODIFYSORTING PIVOTREPORT REEXECUTEREPORTAGAINSTWH SAVECUSTOMAUTOSTYLE SENDTOEMAIL USEDATAEXPLORER USEDESKTOP USEGRIDOPTIONS USEHISTORYLIST USEREPORTDATAOPTIONS USEREPORTEDITOR USESEARCHEDITOR USETHRESHOLDSEDITOR VIEWSQL)],
	desktop_designer => [ qw(USEDOCUMENTEDITOR DEFINEFREEFORMSQLREPORT DEFINEOLAPCUBEREPORT DEFINEQUERYBUILDERREP FORMATGRAPH MODIFYREPORTOBJECTLIST USECONSOLIDATIONEDITOR USECUSTOMGROUPEDITOR USEDATAMARTEDITOR USEDESIGNMODE USEDRILLMAPEDITOR USEFINDANDREPLACEDIALOG USEFORMATTINGEDITOR USEHTMLDOCUMENTEDITOR USEMETRICEDITOR USEPROJECTDOCUMENTATION USEPROMPTEDITOR USEREPORTFILTEREDITOR USESUBTOTALSEDITOR USETEMPLATEEDITOR USEVLDBEDITOR VIEWETLINFO)],
	architect => [ qw(BYPASSSCHEMAACCESSCHECKS IMPORTFUNCTION IMPORTOLAPCUBE USEARCHITECTEDITORS)],
	microstrategy_administrator => [ qw(USECOMMANDMANAGER USEOBJECTMANAGER )],
	integrity_manager => [ qw(USEINTEGRITYMANAGER) ],
	administration => [ qw(ADMINBYPASSALLCHECKS CREATECONFIGOBJECT SCHEDULEADMIN PERFCOUNTERMONITORING USECACHEMONITOR USECLUSTERMONITOR USEDBCONNMONITOR USEDBINSTANCEMANAGER USEJOBMONITOR USEPROJECTMONITOR USEPROJECTSTATUSEDITOR USESCHEDULEMANAGER USESCHEDULEMONITOR USESECURITYFILTERMANAGER USEUSERCONNMONITOR USEUSERMANAGER WEBADMIN) ], };
	my $result = [];
	@$result = map { @{ $privilege_groups->{$_} } } ref $self->{PRIVILEGE_GROUP} 
							?  @{ $self->{PRIVILEGE_GROUP} }
							: $self->{PRIVILEGE_GROUP};
	return $result;
}

=head2 project_cluster

internal routine

=cut

sub project_cluster {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(PROJECT SERVERS);
my @required = qw(PROJECT SERVERS);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/PROJECT/ && do { $result .= $self->{ACTION} . "PROJECT " . $q . $self->{PROJECT} . $q . " "};
	/SERVERS/ && do { $result .= $self->{DIRECTION} . "CLUSTER ";
	       		$result .= 
			($self->{SERVERS} eq "ALL") 
			? ("ALL SERVERS ")
			: ( $self->join_objects($_, $_) );			
	};
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 purge_caching

    $foo->purge_caching(
        TYPE    => "ALL | OBJECT | ELEMENT | REPORT",
        PROJECT => "project_name" | "ALL"
    );

This command can be used only in 3-tier Project Source Names.

PURGE [(ALL | OBJECT | ELEMENT | REPORT)] CACHING IN ( [ALL] PROJECTS | [PROJECT] "<project_name>");

=cut

sub purge_caching {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(TYPE PROJECT);
my @required = qw(TYPE PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/TYPE/ && do { $result .= "PURGE " . $self->{TYPE} . " "};
	/PROJECT/ && do { 
		$result .= "CACHING IN "; 
		$result .=
		($self->{PROJECT} eq "ALL")
		? "ALL PROJECTS;"
		: "PROJECT " . $q . $self->{PROJECT} . $q . ";";
	};
}

return $result;
}

=head2 purge_statistics

    $foo->purge_statistics(
        START_DATE => "start_date",
        END_DATE   => "end_date",
        TIMEOUT    => "seconds"
    );

Optional parameters: 
	TIMEOUT => <seconds>

This command can be used only in 3-tier Project Source Names.

PURGE STATISTICS FROM <start_date> TO <end_date> [TIMEOUT <seconds>];

=cut

sub purge_statistics {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(START_DATE END_DATE TIMEOUT);
my @required = qw(START_DATE END_DATE);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/START_DATE/ && do { $result .= "PURGE STATISTICS FROM " . $self->{START_DATE} . " "};
	/END_DATE/ && do { $result .= "TO " . $self->{END_DATE} . " "};
	/TIMEOUT/ && do { $result .= "TIMEOUT " . $self->{TIMEOUT} . " "};
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 register_project

    $foo->register_project(
        PROJECT => "project_name" AUTOLOAD => "TRUE" | "FALSE" );

Optional parameters: 
	AUTOLOAD => "TRUE" | "FALSE"

This command can be used only in 3-tier Project Source Names.

REGISTER PROJECT "<project_name>" [NOAUTOLOAD];

=cut

sub register_project {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(PROJECT AUTOLOAD);
my @required = qw(PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/PROJECT/ && do { $result .= "REGISTER PROJECT " . $q . $self->{PROJECT} . $q . " "};
	/AUTOLOAD/ && ($self->{AUTOLOAD} eq "FALSE" ) && do { $result .= "NOAUTOLOAD "; };
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 remove_attribute_child

    $foo->remove_attribute_child(
        ATTRIBUTECHILD => "attributechild_name",
        ATTRIBUTE      => "attribute_name",
        LOCATION       => "location_path",
        PROJECT        => "project_name"
    );


REMOVE ATTRIBUTECHILD "<attributechild_name>" FROM ATTRIBUTE "<attribute_name>" IN FOLDER "<location_path>" FOR PROJECT "<project_name>";

=cut

sub remove_attribute_child {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(ATTRIBUTECHILD ATTRIBUTE LOCATION PROJECT);
my @required = qw();
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/^ATTRIBUTECHILD$/ && do { $result .= "REMOVE ATTRIBUTECHILD " . $q . $self->{ATTRIBUTECHILD} . $q . " "};
	/^ATTRIBUTE$/ && do { $result .= "FROM ATTRIBUTE " . $q . $self->{ATTRIBUTE} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 remove_attribute_form_expression
    
    $foo->remove_attribute_form_expression(
        ATTRIBUTEFORMEXP => "expression",
        ATTRIBUTEFORM    => "form_name",
        ATTRIBUTE        => "attribute_name",
        LOCATION         => "location_path",
        PROJECT          => "project_name"
    );

REMOVE ATTRIBUTEFORMEXP "<expression>" FROM ATTRIBUTEFORM "<form_name>" FOR ATTRIBUTE "<attribute_name>" IN FOLDER "<location_path>" FOR PROJECT "<project_name>";


=cut

sub remove_attribute_form_expression {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(ATTRIBUTEFORMEXP ATTRIBUTEFORM ATTRIBUTE LOCATION PROJECT);
my @required = qw(ATTRIBUTEFORMEXP ATTRIBUTEFORM ATTRIBUTE LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/^ATTRIBUTEFORMEXP$/ && do { $result .= "REMOVE ATTRIBUTEFORMEXP " . $q . $self->{ATTRIBUTEFORMEXP} . $q . " "};
	/^ATTRIBUTEFORM$/ && do { $result .= "FROM ATTRIBUTEFORM " . $q . $self->{ATTRIBUTEFORM} . $q . " "};
	/^ATTRIBUTE$/ && do { $result .= "FOR ATTRIBUTE " . $q . $self->{ATTRIBUTE} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 remove_attribute_form

    $foo->remove_attribute_form(
        ATTRIBUTEFORM => "form_name",
        ATTRIBUTE     => "attribute_name",
        LOCATION      => "location_path",
        PROJECT       => "project_name"
    );

REMOVE ATTRIBUTEFORM "<form_name>" FROM ATTRIBUTE "<attribute_name>" IN FOLDER "<location_path>" FOR PROJECT "<project_name>";

=cut

sub remove_attribute_form {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(ATTRIBUTEFORM ATTRIBUTE LOCATION PROJECT);
my @required = qw(ATTRIBUTEFORM ATTRIBUTE LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/^ATTRIBUTEFORM$/ && do { $result .= "REMOVE ATTRIBUTEFORM " . $q . $self->{ATTRIBUTEFORM} . $q . " "};
	/^ATTRIBUTE$/ && do { $result .= "FROM ATTRIBUTE " . $q . $self->{ATTRIBUTE} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 remove_attribute_parent

    $foo->remove_attribute_parent(
        ATTRIBUTEPARENT => "attributeparent_name",
        ATTRIBUTE       => "attribute_name",
        LOCATION        => "location_path",
        PROJECT         => "project_name"
    );

REMOVE ATTRIBUTEPARENT "<attributeparent_name>" FROM ATTRIBUTE "<attribute_name>" IN FOLDER "<location_path>" FOR PROJECT "<project_name>";

=cut

sub remove_attribute_parent {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(ATTRIBUTEPARENT ATTRIBUTE LOCATION PROJECT);
my @required = qw(ATTRIBUTEPARENT ATTRIBUTE LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/^ATTRIBUTEPARENT$/ && do { $result .= "REMOVE ATTRIBUTEPARENT " . $q . $self->{ATTRIBUTEPARENT} . $q . " "};
	/^ATTRIBUTE$/ && do { $result .= "FROM ATTRIBUTE " . $q . $self->{ATTRIBUTE} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 remove_configuration_ace

    $foo->remove_configuration_ace(
        CONF_OBJECT_TYPE         => "conf_object_type",
        OBJECT_NAME              => "object_name",
        USER_OR_GROUP            => "USER" | "GROUP",
        USER_LOGIN_OR_GROUP_NAME => "user_login_or_group_name"
    );

REMOVE ACE FROM <conf_object_type> "<object_name>" (USER | GROUP) "<user_login_or_group_name>";

List of Configuration Object Types:
DBINSTANCE, DBCONNECTION, DBLOGIN, SCHEDULE, USER, GROUP, EVENT

=cut

sub remove_configuration_ace {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(CONF_OBJECT_TYPE OBJECT_NAME USER_OR_GROUP USER_LOGIN_OR_GROUP_NAME);
my @required = qw(CONF_OBJECT_TYPE OBJECT_NAME USER_OR_GROUP USER_LOGIN_OR_GROUP_NAME);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/CONF_OBJECT_TYPE/ && do { $result .= "REMOVE ACE FROM " . $self->{CONF_OBJECT_TYPE} . " "};
	/OBJECT_NAME/ && do { $result .= $q . $self->{OBJECT_NAME} . $q . " "};
	/USER_OR_GROUP/ && do { $result .= $self->{USER_OR_GROUP} . " "};
	/USER_LOGIN_OR_GROUP_NAME/ && do { $result .= $q . $self->{USER_LOGIN_OR_GROUP_NAME} . $q . ";"};
}

return $result;
}

=head2 remove_custom_group_element

    $foo->remove_custom_group_element(
        ELEMENT     => "element_name",
        CUSTOMGROUP => "customgroup_name",
        LOCATION    => "location_path",
        PROJECT     => "project_name"
    );


REMOVE ELEMENT "<element_name>" FROM CUSTOMGROUP "<customgroup_name>" IN FOLDER "<location_path>" FOR PROJECT "<project_name>";

=cut

sub remove_custom_group_element {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(ELEMENT CUSTOMGROUP LOCATION PROJECT);
my @required = qw(ELEMENT CUSTOMGROUP LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/ELEMENT/ && do { $result .= "REMOVE ELEMENT " . $q . $self->{ELEMENT} . $q . " "};
	/CUSTOMGROUP/ && do { $result .= "FROM CUSTOMGROUP " . $q . $self->{CUSTOMGROUP} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 remove_dbinstance

    $foo->remove_dbinstance(
        DBINSTANCE => "DBInstance_name",
        PROJECT    => "project_name"
    );

REMOVE DBINSTANCE "<DBInstance_name>" FROM PROJECT "<project_name>";

REMOVE DBINSTANCE "Tutorial Data" FROM PROJECT "MicroStrategy Tutorial";

=cut

sub remove_dbinstance {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(DBINSTANCE PROJECT);
my @required = qw(DBINSTANCE PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/DBINSTANCE/ && do { $result .= "REMOVE DBINSTANCE " . $q . $self->{DBINSTANCE} . $q . " "};
	/PROJECT/ && do { $result .= "FROM PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 remove_fact_expression

    $foo->remove_fact_expression(
        EXPRESSION => "expression",
        FACT       => "fact_name",
        LOCATION   => "location_path",
        PROJECT    => "project_name"
    );

REMOVE EXPRESSION "<expression>" FROM FACT "<fact_name>" IN FOLDER "<location_path>" FOR PROJECT "<project_name>";

=cut

sub remove_fact_expression {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(EXPRESSION FACT LOCATION PROJECT);
my @required = qw(EXPRESSION FACT LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/EXPRESSION/ && do { $result .= "REMOVE EXPRESSION " . $q . $self->{EXPRESSION} . $q . " "};
	/FACT/ && do { $result .= "FROM FACT " . $q . $self->{FACT} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 remove_folder_ace

    $foo->remove_folder_ace(
        FOLDER                   => "folder_name",
        LOCATION                 => "location_path",
        USER_OR_GROUP            => "USER" | "GROUP",
        USER_LOGIN_OR_GROUP_NAME => "user_login_or_group_name",
        PROJECT                  => "project_name"
    );

REMOVE ACE FROM FOLDER "<folder_name>" IN FOLDER "<location_path>" (USER | GROUP) "<user_login_or_group_name>" FOR PROJECT "<project_name>";

=cut

sub remove_folder_ace {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(FOLDER LOCATION USER_OR_GROUP USER_LOGIN_OR_GROUP_NAME PROJECT);
my @required = qw(FOLDER LOCATION USER_OR_GROUP USER_LOGIN_OR_GROUP_NAME PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/FOLDER/ && do { $result .= "REMOVE ACE FROM FOLDER " . $q . $self->{FOLDER} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/USER_OR_GROUP/ && do { $result .= $self->{USER_OR_GROUP} . " "};
	/USER_LOGIN_OR_GROUP_NAME/ && do { $result .= $q . $self->{USER_LOGIN_OR_GROUP_NAME} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 remove_project_ace

    $foo->remove_project_ace(
        PROJECT_OBJECT_TYPE      => "project_object_type",
        OBJECT_NAME              => "object_name",
        LOCATION                 => "location_path",
        USER_OR_GROUP            => "USER" | "GROUP",
        USER_LOGIN_OR_GROUP_NAME => "user_login_or_group_name",
        PROJECT                  => "project_name"
    );

REMOVE ACE FROM <project_object_type> "<object_name>" IN FOLDER "<location_path>" (USER | GROUP) "<user_login_or_group_name>" FOR PROJECT "<project_name>";

=cut

sub remove_project_ace {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(PROJECT_OBJECT_TYPE OBJECT_NAME LOCATION USER_OR_GROUP USER_LOGIN_OR_GROUP_NAME PROJECT);
my @required = qw(PROJECT_OBJECT_TYPE OBJECT_NAME LOCATION USER_OR_GROUP USER_LOGIN_OR_GROUP_NAME PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/^PROJECT_OBJECT_TYPE$/ && do { $result .= "REMOVE ACE FROM " . $self->{PROJECT_OBJECT_TYPE} . " "};
	/OBJECT_NAME/ && do { $result .= $q . $self->{OBJECT_NAME} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/USER_OR_GROUP/ && do { $result .= $self->{USER_OR_GROUP} . " "};
	/USER_LOGIN_OR_GROUP_NAME/ && do { $result .= $q . $self->{USER_LOGIN_OR_GROUP_NAME} . $q . " "};
	/^PROJECT$/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 remove_server_cluster

    $foo->remove_server_cluster("server_name");

This command can be used only in 3-tier Project Source Names.
REMOVE SERVER "<server_name>" FROM CLUSTER;

=cut

sub remove_server_cluster {
	my $self = shift;
	$self->{SERVER} = shift;
	if(!defined($self->{SERVER})) { croak("\nRequired parameter not defined: SERVER\n"); }
	return "REMOVE SERVER " . $q . $self->{SERVER} . $q . " FROM CLUSTER;";
}

=head2 remove_user

    $foo->remove_user(
        USER  => "login_name",
        GROUP => "group_name" | [ "group_name1", "group_nameN" ]
    );


REMOVE USER "<login_name>" [FROM] GROUP "<group_name1>" [, "<group_name2>" [, ... "<group_nameN>"]];

=cut

sub remove_user {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(USER GROUP);
my @required = qw(USER GROUP);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/USER/ && do { $result .= "REMOVE USER " . $q . $self->{USER} . $q . " "};
	/GROUP/ && do { 
		$result .=
		ref $self->{GROUP} 
		? ( $self->join_objects($_, "FROM GROUP") )
		: ("FROM GROUP " . $q . $self->{GROUP} . $q . " ");
	};
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 remove_whtable

    $foo->remove_whtable(
        WHTABLE => "warehouse_table_name" TABLE => "table_name",
        PROJECT => "project_name"
    );


REMOVE (WHTABLE "<warehouse_table_name>" | TABLE "<table_name>") FROM PROJECT "<project_name>";

Note when you remove a table 
	1. If you remove a warehouse table from a project, all of its depending table(s) is/are removed too. 
	2. If you remove the only logical table of a warehouse table, the warehouse table is removed too.
	3. Make sure the logical table does not have any dependent object(s).

Suppose that we have a table alias of "DT_YEAR" named "DT_YEAR1": 

This statement by itself will only remove DT_YEAR1. 
REMOVE TABLE "DT_YEAR1" FROM PROJECT "MicroStrategy Tutorial";

This statement by itself will remove both DT_YEAR and DT_YEAR1.
REMOVE WHTABLE "DT_YEAR" FROM PROJECT "MicroStrategy Tutorial";

=cut

sub remove_whtable {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(WHTABLE TABLE PROJECT);
my @required = qw(PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/^WHTABLE$/ && do { $result .= "REMOVE WHTABLE " . $q . $self->{WHTABLE} . $q . " "};
	/^TABLE$/ && do { $result .= "REMOVE TABLE " . $q . $self->{TABLE} . $q . " "};
	/PROJECT/ && do { $result .= "FROM PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 restart_server

    $foo->restart_server("machine_name");

RESTART SERVER [IN] "<machine_name>";

=cut

sub restart_server {
	my $self = shift;
	$self->{SERVER} = shift;
	if(!defined($self->{SERVER})) { croak("\nRequired parameter not defined: SERVER\n"); }
	return "RESTART SERVER IN " . $q . $self->{SERVER} . $q . ";";
}


=head2 resume_project

    $foo->resume_project("project_name");

This command can be used only in 3-tier Project Source Names.

RESUME PROJECT "<project_name>";

=cut

sub resume_project {
	my $self = shift;
	$self->{PROJECT} = shift;
	if(!defined($self->{PROJECT})) { croak("\nRequired parameter not defined: PROJECT\n"); }
	return "RESUME PROJECT " . $q . $self->{PROJECT} . $q . ";";
}


=head2 revoke_privileges

    $foo->revoke_privileges(
        PRIVILEGE => "ALL" | [ "privilege1", "privilegeN" ],
        USER      => "login_name",
        GROUP     => "user_group_name",
        SECURITY_ROLE => "sec_role_name"
    );

REVOKE ([ALL] PRIVILEGES | <privilege1> [, <privilege2> [, ... <privilegeN>]]) FROM ([USER] "<login_name>" | [USER] GROUP
"<group_name>" | SECURITY ROLE "<security_role_name>");

=cut

sub revoke_privileges {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(PRIVILEGE USER GROUP SECURITY_ROLE);
my @required = qw(PRIVILEGE);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/PRIVILEGE/ && do { 
		$result .= "REVOKE "; 
		$result .= 
		($self->{PRIVILEGE} eq "ALL")
		? ("ALL PRIVILEGES ")
		: ( join(", ", @{ $self->{PRIVILEGE} } ) . " ");
	};
	/USER/ && do { $result .= "FROM USER " . $q . $self->{USER} . $q . " "};
	/GROUP/ && do { $result .= "FROM GROUP " . $q . $self->{GROUP} . $q . " "};
	/SECURITY_ROLE/ && do { $result .= "FROM SECURITY ROLE " . $q . $self->{SECURITY_ROLE} . $q . " "};

}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}


=head2 revoke_security_filter

    $foo->revoke_security_filter(
        SECURITY_FILTER          => "sec_filter_name",
        LOCATION                 => "location_path",
        USER_OR_GROUP            => "USER" | "GROUP",
        USER_LOGIN_OR_GROUP_NAME => "login_or_group_name",
        PROJECT                  => "project_name"
    );

Optional parameters: LOCATION => "<location_path>"

REVOKE SECURITY FILTER "<sec_filter_name>" [FOLDER "<location_path>"] FROM (USER | GROUP) "<login_or_group_name>" ON [PROJECT] "<project_name>";

=cut

sub revoke_security_filter {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(SECURITY_FILTER LOCATION USER_OR_GROUP USER_LOGIN_OR_GROUP_NAME PROJECT);
my @required = qw(SECURITY_FILTER USER_OR_GROUP USER_LOGIN_OR_GROUP_NAME PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/SECURITY_FILTER/ && do { $result .= "REVOKE SECURITY FILTER " . $q . $self->{SECURITY_FILTER} . $q . " "};
	/LOCATION/ && do { $result .= "FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/USER_OR_GROUP/ && do { $result .= "FROM " . $self->{USER_OR_GROUP} . " "};
	/USER_LOGIN_OR_GROUP_NAME/ && do { $result .= $q . $self->{USER_LOGIN_OR_GROUP_NAME} . $q . " "};
	/PROJECT/ && do { $result .= "ON PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 revoke_security_roles

    $foo->revoke_security_roles(
        SECURITY_ROLE            => "sec_role_name",
        USER_OR_GROUP            => "USER" | "GROUP",
        USER_LOGIN_OR_GROUP_NAME => "user_login" | "user_group_name",
        PROJECT                  => "project_name"
    );

REVOKE [SECURITY ROLE] "<sec_role_name>" FROM [USER] ("<login_name>" | GROUP "<user_group_name>") ON [PROJECT] "<project_name>";

=cut

sub revoke_security_roles {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(SECURITY_ROLE USER_OR_GROUP USER_LOGIN_OR_GROUP_NAME PROJECT);
my @required = qw(SECURITY_ROLE USER_OR_GROUP USER_LOGIN_OR_GROUP_NAME PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/SECURITY_ROLE/ && do { $result .= "REVOKE SECURITY ROLE " . $q . $self->{SECURITY_ROLE} . $q . " "};
	/USER_OR_GROUP/ && do { $result .= "FROM " . $self->{USER_OR_GROUP} . " "};
	/USER_LOGIN_OR_GROUP_NAME/ && do { $result .= $q . $self->{USER_LOGIN_OR_GROUP_NAME} . $q . " "};
	/PROJECT/ && do { $result .= "ON PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 run_command

    $foo->run_command("executable_program");

RUN COMMAND "<executable_program>";

=cut

sub run_command {	
	my $self = shift;
	$self->{COMMAND} = shift;
	if(!defined($self->{COMMAND})) { croak("\nRequired parameter not defined: COMMAND\n"); }
	return "RUN COMMAND " . $q . $self->{COMMAND} . $q . ";";
}



=head2 schedule

internal use only

=cut

sub schedule {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(SCHEDULE NEW_NAME DESCRIPTION STARTDATE ENDDATE TYPE EVENTNAME DAILY WEEKLY MONTHLY YEARLY EXECUTE_TIME_OF_DAY EXECUTE_ALL_DAY);
my @required = qw(SCHEDULE TYPE);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: ", $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/SCHEDULE/ && do { $result .= $self->{SCHEDULE_ACTION} . $q . $self->{SCHEDULE} . $q . " "};
	/NEW_NAME/ && do { $result .= "NAME " . $q . $self->{NEW_NAME} . $q . " "};
	/DESCRIPTION/ && do { $result .= "DESCRIPTION " . $q . $self->{DESCRIPTION} . $q . " "};
	/STARTDATE/ && do { $result .= "STARTDATE " . $self->{STARTDATE} . " "};
	/ENDDATE/ && do { $result .= "ENDDATE " . $self->{ENDDATE} . " "};
	/TYPE/ && do { $result .= "TYPE " . $self->{TYPE} . " "};
	/EVENTNAME/ && do { $result .= "EVENTNAME " . $q . $self->{EVENTNAME} . $q . " "};
	/DAILY/ && do { $result .= "DAILY " . $self->{DAILY} . " "}; 
	/WEEKLY/ && do { $result .= "WEEKLY " . $self->{WEEKLY} . " "}; 
	/MONTHLY/ && do { $result .= "MONTHLY " . $self->{MONTHLY} . " " }; 
	/YEARLY/ && do { $result .= "YEARLY " . $self->{YEARLY} . " "}; 
	/EXECUTE_TIME_OF_DAY/ && do {$result .=  "EXECUTE " . $self->{EXECUTE_TIME_OF_DAY} . " "}; 
	/EXECUTE_ALL_DAY/ && do { $result .=  "EXECUTE ALL DAY " . $self->{EXECUTE_ALL_DAY} . " "};
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 schedule_relation

internal routine

=cut

sub schedule_relation {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(SCHEDULE USER_OR_GROUP USER_LOGIN_OR_GROUP_NAME REPORT LOCATION PROJECT CREATEMSGHIST ENABLEMOBILEDELIVERY OVERWRITE UPDATECACHE);
my @required = qw(SCHEDULE USER_OR_GROUP USER_LOGIN_OR_GROUP_NAME REPORT LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/SCHEDULE/ && do { $result .= $self->{ACTION} . "SCHEDULERELATION SCHEDULE " . $q . $self->{SCHEDULE} . $q . " "};
	/USER_OR_GROUP/ && do { $result .= $self->{USER_OR_GROUP} . " "};
	/USER_LOGIN_OR_GROUP_NAME/ && do { $result .= $q . $self->{USER_LOGIN_OR_GROUP_NAME} . $q . " "};
	/REPORT/ && do { $result .= "REPORT " . $q . $self->{REPORT} . $q . " "};
	/LOCATION/ && do { $result .= "IN " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { 
		$result .= ($self->{ACTION} eq "DELETE ") ? "FROM " : "IN ";
		$result .= "PROJECT " . $q . $self->{PROJECT} . $q . " "};
	/CREATEMSGHIST/ && do { $result .= "CREATEMSGHIST " . $self->{CREATEMSGHIST} . " "};
	/ENABLEMOBILEDELIVERY/ && do { 
		if($self->{ENABLEMOBILEDELIVERY} =~ /(F|0)/i) { next; } 
		$result .= "ENABLEMOBILEDELIVERY ";
	};
	/OVERWRITE/ && do { 
		if($self->{OVERWRITE} =~ /(F|0)/i) { next; } 
		$result .= "OVERWRITE "; 
	};
	/UPDATECACHE/ && do { 
		if($self->{UPDATECACHE} =~ /(F|0)/i) { next; } 
		$result .= "UPDATECACHE "; 
	};
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}


=head2 security_filter

internal routine

=cut

sub security_filter {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(SECURITY_FILTER LOCATION HIDDEN PROJECT NEW_NAME FILTER FILTER_LOCATION EXPRESSION TOP_ATTRIBUTE_LIST BOTTOM_ATTRIBUTE_LIST );
my @required = qw(SECURITY_FILTER PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/^SECURITY_FILTER$/ && do { 
		$result .= $self->{ACTION} . "SECURITY FILTER " . $q . $self->{SECURITY_FILTER} . $q . " ";	
	};
	/^LOCATION$/ && do { $result .= "FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/HIDDEN/ && do { $result .= "HIDDEN " . $self->{HIDDEN} . " "};
	/PROJECT/ && do { $result .= "IN PROJECT " . $q . $self->{PROJECT} . $q . " "};
	/NEW_NAME/ && do { $result .= "NAME " . $q . $self->{NEW_NAME} . $q . " "};
	/^FILTER$/ && do { $result .= "FILTER " . $q . $self->{FILTER} . $q . " "};
	/^FILTER_LOCATION$/ && do { $result .= "IN FOLDER " . $q . $self->{FILTER_LOCATION} . $q . " "};
	/EXPRESSION/ && do { $result .= "EXPRESSION " . $q . $self->{EXPRESSION} . $q . " "};
	/TOP_ATTRIBUTE_LIST/i && do { $result .= $self->join_objects($_, "TOP ATTRIBUTE LIST") };
	/BOTTOM_ATTRIBUTE_LIST/ && do { $result .= $self->join_objects($_, "BOTTOM ATTRIBUTE LIST") };
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 security_role

internal routine

=cut

sub security_role {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(SECURITY_ROLE NAME DESCRIPTION);
my @required = qw(SECURITY_ROLE);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/SECURITY_ROLE/ && do { $result .= $self->{ACTION} . "SECURITY ROLE " . $q . $self->{SECURITY_ROLE} . $q . " "};
	/NAME/ && do { $result .= "NAME " . $q . $self->{NAME} . $q . " "};
	/DESCRIPTION/ && do { $result .= "DESCRIPTION " . $q . $self->{DESCRIPTION} . $q . " "};
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 send_message

    $foo->send_message(
        MESSAGE => "message",
        USER    => "login_name" | "ALL"
    );

This command can be used only in 3-tier Project Source Names.

SEND MESSAGE "<message>" TO (USER "<login_name>" | [ALL] USERS);

=cut

sub send_message {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(MESSAGE USER);
my @required = qw(MESSAGE USER);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/MESSAGE/ && do { $result .= "SEND MESSAGE " . $q . $self->{MESSAGE} . $q . " "};
	/USER/ && do { 
		$result .= "TO "; 
		$result .= 
		($self->{USER} eq "ALL")
		? ("ALL USERS;")
		: ("USER " . $q . $self->{USER} . $q . ";");
	};
}

return $result;
}

=head2 set_property_hidden

    $foo->set_property_hidden(
        HIDDEN              => "TRUE" | "FALSE",
        PROJECT_CONFIG_TYPE => "project_configuration_type",
        OBJECT_NAME         => "object_name",
        LOCATION            => "location_path",
        PROJECT             => "project_name"
    );

SET PROPERTY HIDDEN (TRUE | FALSE) FOR (FOLDER | CONSOLIDATION | DOCUMENT | FILTER | METRIC | PROMPT | REPORT | SEARCH | TEMPLATE | ATTRIBUTE | FACT | FUNCTION | HIERARCHY | TABLE | TRANSFORMATION | DRILLMAP | SECFILTER | AUTOSTYLE | BASEFORMULA | SHORTCUT) "<object_name>" IN FOLDER "<location_path>" FOR PROJECT "<project_name>";

When two or more shortcuts in a folder have the same name, GET/SET command will treat all of them equally. This means the SET command will set all of them to either hidden or visible. The GET command will show hidden property for all of them.

=cut

sub set_property_hidden {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(HIDDEN PROJECT_CONFIG_TYPE OBJECT_NAME LOCATION PROJECT);
my @required = qw(HIDDEN PROJECT_CONFIG_TYPE OBJECT_NAME LOCATION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/HIDDEN/ && do { $result .= "SET PROPERTY HIDDEN " . $self->{HIDDEN} . " "};
	/^PROJECT_CONFIG_TYPE$/ && do { $result .= "FOR " . $self->{PROJECT_CONFIG_TYPE} . " "};
	/OBJECT_NAME/ && do { $result .= $q . $self->{OBJECT_NAME} . $q . " "};
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/^PROJECT$/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}


=head2 shortcut

internal routine

=cut

sub shortcut {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(LOCATION PROJECT_CONFIG_OBJECT NAME OBJECT_LOCATION NEW_LOCATION HIDDEN PROJECT);
my @required = qw(LOCATION PROJECT_CONFIG_OBJECT NAME PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_ , "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/^LOCATION$/ && do { $result .= $self->{ACTION} . "SHORTCUT IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/^PROJECT_CONFIG_OBJECT$/ && do { $result .= "FOR " . $self->{PROJECT_CONFIG_OBJECT} . " "};
	/NAME/ && do { $result .= $q . $self->{NAME} . $q . " "};
	/^OBJECT_LOCATION$/ && do { $result .= "IN FOLDER " . $q . $self->{OBJECT_LOCATION} . $q . " "};
	/^NEW_LOCATION$/ && do { $result .= "FOLDER " . $q . $self->{NEW_LOCATION} . $q . " "};
	/HIDDEN/ && do { $result .= "HIDDEN " . $self->{HIDDEN} . " "};
	/^PROJECT$/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}


=head2 start_server

    $foo->start_server("machine_name");

START SERVER [IN] "<machine_name>";

=cut

sub start_server {
	my $self = shift;
	$self->{SERVER} = shift;
	if(!defined($self->{SERVER})) { croak("\nRequired parameter not defined: SERVER\n"); }
	return "START SERVER IN " . $q . $self->{SERVER} . $q . ";";
}

=head2 start_service

    $foo->start_service(
        SERVICE => "service_name",
        SERVER  => "machine_name"
    );

START SERVICE "<service_name>" IN "<machine_name>";

MicroStrategy Enterprise Manager Data Loader:
START SERVICE "MAEMETLS" IN "HOST_MSTR";

MicroStrategy Listener:
START SERVICE "MAPING" IN "HOST_MSTR";

=cut

sub start_service {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(SERVICE SERVER);
my @required = qw(SERVICE SERVER);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/SERVICE/ && do { $result .= "START SERVICE " . $q . $self->{SERVICE} . $q . " "};
	/SERVER/ && do { $result .= "IN " . $q . $self->{SERVER} . $q . ";"};
}

return $result;
}

=head2 stop_server

    $foo->stop_server("machine_name");

MicroStrategy Command Manager does not currently support manipulating a MicroStrategy Intelligence Server installed in a UNIX machine.

=cut

sub stop_server {
	my $self = shift;
	$self->{SERVER} = shift;
	if(!defined($self->{SERVER})) { croak("\nRequired parameter not defined: SERVER\n"); }
	return "STOP SERVER IN " . $q . $self->{SERVER} . $q . ";";
}

=head2 stop_service

    $foo->stop_service(
        SERVICE => "service_name",
        SERVER  => "machine_name"
    );

STOP SERVICE "<service_name>" IN "<machine_name>";

MicroStrategy Enterprise Manager Data Loader:
STOP SERVICE "MAEMETLS" IN "HOST_MSTR";

MicroStrategy Listener:
STOP SERVICE "MAPING" IN "HOST_MSTR";

=cut

sub stop_service {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(SERVICE SERVER);
my @required = qw(SERVICE SERVER);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/SERVICE/ && do { $result .= "STOP SERVICE " . $q . $self->{SERVICE} . $q . " "};
	/SERVER/ && do { $result .= "IN " . $q . $self->{SERVER} . $q . ";"};
}

return $result;
}


=head2 take_ownership

    $foo->take_ownership(
        OBJECT_TYPE => "conf_object_type" | "project_object_type" | "FOLDER",
        OBJECT_NAME => "object_name",
        RECURSIVELY => "TRUE" | "FALSE",    # for FOLDER only
        LOCATION    => "location_path",
        PROJECT     => "project_name"
    );


Optional parameters: 
	RECURSIVELY => "TRUE" | "FALSE"

TAKE OWNERSHIP FOR (<conf_object_type> "<object_name>" | (<project_object_type> "<object_name>" | FOLDER "<folder_name>" [RECURSIVELY]) IN FOLDER "<location_path>" FOR PROJECT "<project_name>");

TAKE OWNERSHIP FOR FOLDER "Subtotals" RECURSIVELY IN FOLDER "\Project Objects" FOR PROJECT "MicroStrategy Tutorial";

=cut

sub take_ownership {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(OBJECT_TYPE OBJECT_NAME RECURSIVELY LOCATION PROJECT);
my @required = qw(OBJECT_TYPE OBJECT_NAME);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/OBJECT_TYPE/ && do { $result .= "TAKE OWNERSHIP FOR " . $self->{OBJECT_TYPE} . " "};
	/OBJECT_NAME/ && do { $result .= $q . $self->{OBJECT_NAME} . $q . " "};
	/RECURSIVELY/ && ($self->{RECURSIVELY} eq "TRUE") && do { $result .= "RECURSIVELY "; };
	/LOCATION/ && do { $result .= "IN FOLDER " . $q . $self->{LOCATION} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . " "};
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head2 trigger_event

    $foo->trigger_event("event_name");

This command can be used only in 3-tier Project Source Names.
TRIGGER EVENT "<event_name>";

=cut

sub trigger_event {
	my $self = shift;
	$self->{EVENT} = shift;
	if(!defined($self->{EVENT})) { croak("\nRequired parameter not defined: EVENT NAME\n"); }
	return "TRIGGER EVENT " . $q . $self->{EVENT} . $q . ";";
}

=head2 unload_project

    $foo->unload_project("project_name");

This command can be used only in 3-tier Project Source Names.

UNLOAD PROJECT "<project_name>";

=cut

sub unload_project {
	my $self = shift;
	$self->{PROJECT} = shift;
	if(!defined($self->{PROJECT})) { croak("\nRequired parameter not defined: PROJECT\n"); }
	return "UNLOAD PROJECT " . $q . $self->{PROJECT} . $q . ";";
}

=head2 unload_projects_cluster

    $foo->unload_projects_cluster(
        PROJECT => "project_name",
        SERVERS => "ALL" | [ "server_name1", "server_nameN" ]
    );


This command can be used only in 3-tier Project Source Names.

UNLOAD PROJECT "<project_name>" FROM CLUSTER (ALL SERVERS | SERVERS "<server_name1>" [, "<server_name2>"[, "<server_nameN>" ]]);

You can unload a project into a server, some servers, or all servers in a cluster. Be aware that changes will take effect immediately.  Note you can only use UNLOAD from ALL SERVERS if you previously used LOAD to ALL SERVERS.

=cut

sub unload_projects_cluster {
	my $self = shift;
	$self->{ACTION} = "UNLOAD ";
	$self->{DIRECTION} = "FROM ";
	$self->project_cluster(@_);
}


=head2 unlock_configuration

    $foo->unlock_configuration;

UNLOCK CONFIGURATION FORCE;

=cut

sub unlock_configuration { return "UNLOCK CONFIGURATION FORCE;"; }

=head2 unlock_project

    $foo->unlock_project("project_name");

UNLOCK PROJECT "<project_name>" FORCE;

UNLOCK PROJECT "MicroStrategy Tutorial" FORCE;

=cut

sub unlock_project {
	my $self = shift;
	$self->{PROJECT} = shift;
	if(!defined($self->{PROJECT})) { croak("\nRequired parameter not defined: PROJECT\n"); }
	return "UNLOCK PROJECT " . $q . $self->{PROJECT} . $q . " FORCE;";
}

=head2 unregister_project

    $foo->unregister_project("project_name");

This command can be used only in 3-tier Project Source Names.

UNREGISTER PROJECT "<project_name>";

=cut

sub unregister_project {
	my $self = shift;
	$self->{PROJECT} = shift;
	if(!defined($self->{PROJECT})) { croak("\nRequired parameter not defined: PROJECT\n"); }
	return "UNREGISTER PROJECT " . $q . $self->{PROJECT} . $q . ";";
}

=head2 update_project
    
    $foo->update_project("project_name");

UPDATE PROJECT "<project_name>";


=cut

sub update_project {
	my $self = shift;
	$self->{PROJECT} = shift;
	if(!defined($self->{PROJECT})) { croak("\nRequired parameter not defined: PROJECT\n"); }
	return "UPDATE PROJECT " . $q . $self->{PROJECT} . $q . ";";
}


=head2 update_schema

    $foo->update_schema(
        REFRESHSCHEMA     => "TRUE" | "FALSE",
        RECALTABLEKEYS    => "TRUE" | "FALSE",
        RECALTABLELOGICAL => "TRUE" | "FALSE",
        RECALOBJECTCACHE  => "TRUE" | "FALSE",
        PROJECT           => "project_name"
    );


Optional parameters:  	
        REFRESHSCHEMA     => "TRUE" | "FALSE",
        RECALTABLEKEYS    => "TRUE" | "FALSE",
        RECALTABLELOGICAL => "TRUE" | "FALSE",
        RECALOBJECTCACHE  => "TRUE" | "FALSE",

UPDATE SCHEMA [ REFRESHSCHEMA | RECALTABLEKEYS | RECALTABLELOGICAL | RECALOBJECTCACHE] FOR PROJECT "<project_name>";

UPDATE SCHEMA REFRESHSCHEMA FOR PROJECT "MicroStrategy Tutorial";
UPDATE SCHEMA RECALTABLEKEYS FOR PROJECT "MicroStrategy Tutorial";
UPDATE SCHEMA RECALTABLELOGICAL FOR PROJECT "MicroStrategy Tutorial";
UPDATE SCHEMA RECALOBJECTCACHE FOR PROJECT "MicroStrategy Tutorial";
UPDATE SCHEMA FOR PROJECT "MicroStrategy Tutorial";
UPDATE SCHEMA REFRESHSCHEMA RECALTABLEKEYS RECALTABLELOGICAL RECALOBJECTCACHE FOR PROJECT "MicroStrategy Tutorial";

=cut

sub update_schema {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(REFRESHSCHEMA RECALTABLEKEYS RECALTABLELOGICAL RECALOBJECTCACHE PROJECT);
my @required = qw(PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
$result .= "UPDATE SCHEMA ";
for(@selected) {
	/REFRESHSCHEMA/ && ($self->{REFRESHSCHEMA} eq "TRUE")  && do { $result .= "REFRESHSCHEMA " };
	/RECALTABLEKEYS/ && ($self->{RECALTABLEKEYS} eq "TRUE") && do { $result .= "RECALTABLEKEYS " };
	/RECALTABLELOGICAL/ && ($self->{RECALTABLELOGICAL} eq "TRUE") && do { $result .= "RECALTABLELOGICAL " };
	/RECALOBJECTCACHE/ && ($self->{RECALOBJECTCACHE} eq "TRUE") && do { $result .= "RECALOBJECTCACHE " };	
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 update_structure

    $foo->update_structure(
        COLMERGEOPTION => "RECENT | MAXDENOMINATOR | NOMERGE",
        WHTABLE        => "warehouse_table_name",
        PROJECT        => "project_name"
    );

Optional parameters: 
       WHTABLE        => "warehouse_table_name" 

UPDATE STRUCTURE COLMERGEOPTION (RECENT | MAXDENOMINATOR | NOMERGE) [FOR WHTABLE "<warehouse_table_name>"] FOR PROJECT "<project_name>";

Notes:
1. Warehouse Partition Table and Non_Relational Table are not supported
2. Warehouse table names are case sensitive; logical table names are not case sensitive

ColMergeOption:
1. RECENT: If a column is discovered in the warehouse, which has the same name as that of an existing column but different data types, the column in the project is updated to have the data type found in the warehouse. 
2. MAXDENOMINATOR: Columns with the same name are always treated as the same object if they have compatible data types (i.e., all numeric, all string-text, etc.). The resulting column in the project has a maximum common data type for all the corresponding physical columns.
3. NOMERGE: Two columns having the same name but different data types are treated as two different columns in the project. 

To update structure for a warehouse table, you will need to provide a name. Command Manager will search for the table and update its column structure. All the logical tables using this warehouse table will also get their definitions updated.
If no table name was provided, Command Manager will proceed to update all warehouse tables currently existing in the project.

UPDATE STRUCTURE COLMERGEOPTION MAXDENOMINATOR FOR WHTABLE "DT_YEAR" FOR PROJECT "MicroStrategy Tutorial";

UPDATE STRUCTURE COLMERGEOPTION RECENT FOR PROJECT "MicroStrategy Tutorial";

=cut

sub update_structure {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(COLMERGEOPTION WHTABLE PROJECT);
my @required = qw(COLMERGEOPTION PROJECT);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/COLMERGEOPTION/ && do { $result .= "UPDATE STRUCTURE COLMERGEOPTION " . $self->{COLMERGEOPTION} . " "};
	/WHTABLE/ && do { $result .= "FOR WHTABLE " . $q . $self->{WHTABLE} . $q . " "};
	/PROJECT/ && do { $result .= "FOR PROJECT " . $q . $self->{PROJECT} . $q . ";"};
}

return $result;
}

=head2 user

internal routine

=cut

sub user {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(IMPORTWINUSER USER NAME NTLINK PASSWORD FULLNAME DESCRIPTION LDAPLINK WHLINK WHPASSWORD ALLOWCHANGEPWD ALLOWSTDAUTH CHANGEPWD PASSWORDEXP PASSWORDEXPFREQ ENABLED GROUP);
my @required = qw(USER);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
$result .= $self->{ACTION} . "USER ";
for(@selected) {
	/^IMPORTWINUSER$/ && do { $result .= "IMPORTWINUSER "; };
	/^USER$/ && do { $result .= $q . $self->{USER} . $q . " "};
	/^NAME$/ && do { $result .= "NAME " . $q . $self->{NAME} . $q . " "};
	/NTLINK/ && do { $result .= "NTLINK " . $q . $self->{NTLINK} . $q . " "};
	/^PASSWORD$/ && do { $result .= "PASSWORD " . $q . $self->{PASSWORD} . $q . " "};
	/^FULLNAME$/ && do { $result .= "FULLNAME " . $q . $self->{FULLNAME} . $q . " "};
	/DESCRIPTION/ && do { $result .= "DESCRIPTION " . $q . $self->{DESCRIPTION} . $q . " "};
	/LDAPLINK/ && do { $result .= "LDAPLINK " . $q . $self->{LDAPLINK} . $q . " "};
	/WHLINK/ && do { $result .= "WHLINK " . $q . $self->{WHLINK} . $q . " "};
	/WHPASSWORD/ && do { $result .= "WHPASSWORD " . $q . $self->{WHPASSWORD} . $q . " "};
	/^ALLOWCHANGEPWD$/ && do { $result .= "ALLOWCHANGEPWD " . $self->{ALLOWCHANGEPWD} . " "};
	/ALLOWSTDAUTH/ && do { $result .= "ALLOWSTDAUTH " . $self->{ALLOWSTDAUTH} . " "};
	/^CHANGEPWD$/ && do { $result .= "CHANGEPWD " . $self->{CHANGEPWD} . " "};
	/^PASSWORDEXP$/ && do { $result .= "PASSWORDEXP " . $self->{PASSWORDEXP} . " "};
	/^PASSWORDEXPFREQ$/ && do { $result .= "PASSWORDEXPFREQ " . $self->{PASSWORDEXPFREQ} . " "};
	/ENABLED/ && do { $result .= $self->{ENABLED} . " "};
	/GROUP/ && do { $result .= "IN GROUP " . $q . $self->{GROUP} . $q . " "};
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}


=head2 user_group

internal routine

=cut

sub user_group {
my $self = shift;
my %parms = @_;
@$self{keys %parms} = values %parms;
my $result;
my @order = qw(USER_GROUP NEW_NAME DESCRIPTION LDAPLINK MEMBERS PARENT_GROUP);
my @required = qw(USER_GROUP);
for(@required){
	if(!defined($self->{$_})) { croak("\nRequired parameter not defined: " , $_, "\n"); }
}
my @selected;
for(@order) { 
	exists $parms{$_} ? ( push(@selected, $_) ) : ($self->{$_} = undef);
}
for(@selected) {
	/USER_GROUP/ && do { $result .= $self->{ACTION} . "USER GROUP " . $q . $self->{USER_GROUP} . $q . " "};
	/NEW_NAME/ && do { $result .= "NAME " . $q . $self->{NEW_NAME} . $q . " "};
	/DESCRIPTION/ && do { $result .= "DESCRIPTION " . $q . $self->{DESCRIPTION} . $q . " "};
	/LDAPLINK/ && do { $result .= "LDAPLINK " . $q . $self->{LDAPLINK} . $q . " "};
	/MEMBERS/ && do { $result .= $self->join_objects($_, $_) };
	/PARENT_GROUP/ && do { $result .= "GROUP " . $q . $self->{PARENT_GROUP} . $q . " "};
}
$result =~ s/\s+$//;
$result .= ";";
return $result;
}

=head1 AUTHOR

Craig Grady, C<< <cgrady357 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-business-intelligence-microstrategy-commandmanager at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-Intelligence-MicroStrategy-CommandManager>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Business::Intelligence::MicroStrategy::CommandManager


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-Intelligence-MicroStrategy-CommandManager>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Business-Intelligence-MicroStrategy-CommandManager>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Business-Intelligence-MicroStrategy-CommandManager>

=item * Search CPAN

L<http://search.cpan.org/dist/Business-Intelligence-MicroStrategy-CommandManager>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Craig Grady, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Business::Intelligence::MicroStrategy::CommandManager
