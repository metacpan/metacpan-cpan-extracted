
package App::Requirement::Arch ;

use strict;
use warnings ;
use Carp ;

BEGIN 
{
use Sub::Exporter -setup => 
	{
	exports => [ qw(get_template_files load_master_template load_master_categories) ],
	groups  => 
		{
		all  => [ qw() ],
		}
	};
	
use vars qw ($VERSION);
$VERSION     = '0.02';
}

#-------------------------------------------------------------------------------

use English qw( -no_match_vars ) ;

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;

use Carp qw(carp croak confess) ;

#-------------------------------------------------------------------------------

=head1 NAME

App::Requirement::Arch - Easy requirements creation and handling

=head1 SYNOPSIS

	$> ra_new my_requirement
	$> edit my_requirement
	$> git add my_requirement (if you want to keep your requirements under version control)
	$> ra_show

=head1 BACKGROUND

This module is the result of discussions I have had with friends and collegues. Kolbjörn Gripner, Johan Nat och Dag and Cristian Pendelton 
(to name a few) and I have had heated discussions about how important requirements are and how they should be handled. One common 
trait we share is that we believe requirements are very important and demand a lot of serious work. The reward is great put the effort to 
be put into requirement gathering, prioritizing, categorizing, reviewing, following down to testing is an activity seen as a burden by too many.

By far the greatest challenge to good requirement, and thus to the production of professional application or service, is cultural. Product 
manager are known to range from bad to very bad when it comes to requirement handling, with the too seldom seen exception, producing
low utility excel sheets that developers can't make sense of or that are lacking the minimum information to be of any use.

Developers, particularely in the open source community, are not much better. Their requirement handling ranging from unexistant to
simplistic (todos, error DBs, ...). Here too, development culture and resistance to change is the problem.

We believe we need a system to make requirement handling more attractive so people are 'happy' to work with requirement.

Multidimensional_Requirement_Database.pod, a document writen by Kolbjörn, is an interresting read wich shows what goes on into the 
head of someone who is deeply involved with requirement gathering. Although the format is dry, it is an excellent analysis  of what a better
requirement handling process and tools should handle.

This application set was developed in an agile, ad-hoc , way and it could itself have had great use of a simple requirement handling tool set.
IT has been used in a project with 4 people, hundreds of requirements and months of requirement gathering. Of course there is still a lot of 
work to do (but one of the goals is to not over do it) and your help and input is wished for.

=head1 DESCRIPTION

This module implements  a set of application that you can use to do easy requirement handling. We have defined
a few goals to help us make the requirement handling 'easy' while keeping it powerfull and keeping us out of your way.

Goals:

	- keep things as simple if possible
	- Adapt to the requirement process you use and propose one if you don't have any
	- the UI is provided by your platform
	- power users like the command line
	- handle small to middle sized projects ( wich are the most common)
	- try to make it appealing to developers

The set of applications should be usable by anyone but having a development background does help. If the people writing  requirements
have little or no knowledge of requirements handling, someone with the knowledge should help them. This is true for any requirement 
gathering process wether they use this application or a multi million dollar commercial framework.

=head1 DOCUMENTATION

=head2 Physical representation of the requirements:

=head2 Decisions

	- Each requirements are gathered in a text file
	- The Requirement must match a specified format
	- The format is Perl
	- The format requires the presence of specific fields
	- The requirements can be gathered from multiple places

=head3 Consequences:

	- gathering requirement is simple (except if your product manager has problems opening files with unix line ending (no this is not a joke))
	- tools to verify the format of the requirements are easilly written

=head3 Positive side effects:

	- requirements can be shared between projects, simply gather them from multiple projects
	- the physical organisation of the file is left to user, have any directory structure you deem good
	- requirements can be under version control and you can choose whatever system you like
	- you can use the tools you are used to (this was listed above as a goal)
		- your favorit text editor
		- your favorit version control system
		- your favorit explorer (konqueror, lynx, mc, tree, ...)
		- your favorit text manipulation commands (grep, sort, ...)

=head2 Requirement handling activities

Below is a non exhaustive list of the activities that compose requirement handling:

	Creation
	Format Verification
	Breakdown
	Merging
	Categorisation
	Review
	Filtering
	Visualisation

=head2 Requirement format

The requirement format is defined in I<master_template.pl>. The template is used to create new requirements and check existing templates. 
I<master_template.pl> also contains the definition of a use case template. It is possible to modify and expand I<master_template.pl> with 
more type or different fields for a type. The discussion below is not about the individual fields but their format, see L<Default template fields>.

for the REQUIREMENT type the template looks like:

		{
		UUID => {TYPE =>$SCALAR, DEFAULT => undef},
		TYPE => {TYPE =>$SCALAR, DEFAULT => 'requirement', ACCEPTED_VALUES => ['use case', 'requirement']},
		ABSTRACTION_LEVEL => {TYPE =>$SCALAR, DEFAULT => 'system', ACCEPTED_VALUES => ['architecture', 'system', 'module', 'none'], OPTIONAL => 1},

		ORIGINS => {TYPE =>$ARRAY, DEFAULT => []} ,
		CREATORS => {TYPE =>$ARRAY, DEFAULT => []},

		CATEGORIES => {TYPE =>$ARRAY, DEFAULT => []},
		NAME => {TYPE =>$SCALAR, DEFAULT =>''} ,
		...
		},

Each field has a 

	TYPE:  $SCALAR or $ARRAY
	DEFAULT: a default value
	ACCEPTED_VALUES: values that are used to verify the contents of the fiels
	OPTIONAL: wether the field is optional or not. I prefer always having all the fields but other user may prefer not seeing them. Unecessary fields
		are ugly (but the whole buisiness is rather unxxx). the disadvantages of not seing all the fields is that the user has to know what she can
		write or not which, IMO, makes it more difficult
		
TODO: add a comment entry in each field so it can be displayed as help to the user	

=head3 Verification

Once you have created your requirement you can check it's validity with tthe B<ra_check> application. You can check multiple requirement
simulteanously.

B<ra_check> will report the following

=head4 Format error

The syntax you used is not valid. This happends if you forget a comma or have unbalanced braces, ...

=head4 Errorneous  fields

A fields contains data that are not allowed by the template

=head4 Missing  Fields

A non-optional fiels is missing from the requirement

=head4 Extra Fields

A field that was not defined in the requirement template was found. This will only generate a warning because we feel that you should be able to add a field
to a requirement without having to change the template for the following reasons:

	- you may not not have the rights needed to change the template
	- you may want to discuss it with colleagues first
	- you need the extra field right now for something you deem important but you can't be bothered by silly administrative tasks

=head3 Default template fields

=head4 Example:

	{
	UUID => undef ,
	TYPE => 'requirement',
	ABSTRACTION_LEVEL => 'system',

	ORIGINS => [	],
	CREATORS => ['nadim'],

	CATEGORIES => ['System creation/Distribution'],
	NAME => 'Distribute builds',

	DESCRIPTION => 'The Build System shall be able to distribute builds on several computers.',

	LONG_DESCRIPTION => <<"END_OF_LONG_DESCRIPTION",
	By default, compilation is distributed to available computers
	...
	END_OF_LONG_DESCRIPTION

	RATIONALE => <<"END_OF_RATIONAL",
	By distributing a system build on several computers, several build tasks can be computed in parallel. 
	...
	END_OF_RATIONAL

	FIT_CRITERIA => <<"END_OF_LONG_FIT_CRITERIA",
	start a distributed build and check it uses all the available build resources
	END_OF_LONG_FIT_CRITERIA

	SATISFACTION => 5, # [1-5] 1 = user doesn't really care .. 5 = user will be very satisfied if implemented
	DISSATISFACTION => 5,  # [1-5] 1 = user doesn't really care .. 5 = user will be very displeased if not implemented

	DOCUMENTATION_LINKS =>[],

	SUB_REQUIREMENTS => 
		[
		'Administration of distributed build computers',
		'Platform independent distribution',
		'Allowed CPU power usage',
		...
		],

	REVIEWED => 0,

	IMPLEMENTATION_STATE => 0,
	IMPLEMENTATION_PRIORITY => undef,
	}

=head4 Field by field

TODO: Get KG to fill this with NKH

=over 2 

=item UUID => undef , 

=item TYPE => 'requirement',  or 'use_case'

=item ABSTRACTION_LEVEL => 'system',

=item ORIGINS => [	],

=item CREATORS => ['nadim'],

=item CATEGORIES => ['System creation/Distribution'], multiple categories can be listed

=item NAME => 'Distribute builds', matches the file name

=item DESCRIPTION => 'The Build System shall be able to distribute builds on several computers.',

=item LONG_DESCRIPTION => <<"END_OF_LONG_DESCRIPTION",
	By default, compilation is distributed to available computers
	...
	END_OF_LONG_DESCRIPTION

=item RATIONALE => <<"END_OF_RATIONAL",
	By distributing a system build on several computers, several build tasks can be computed in parallel. 
	...
	END_OF_RATIONAL

=item FIT_CRITERIA => <<"END_OF_LONG_FIT_CRITERIA",
	start a distributed build and check it uses all the available build resources
	END_OF_LONG_FIT_CRITERIA

=item SATISFACTION => 5, # [1-5] 1 = user doesn't really care .. 5 = user will be very satisfied if implemented

=item DISSATISFACTION => 5,  # [1-5] 1 = user doesn't really care .. 5 = user will be very displeased if not implemented

=item DOCUMENTATION_LINKS =>[],

=item SUB_REQUIREMENTS => 
	[
	'Administration of distributed build computers', 
	'Platform independent distribution',
	'Allowed CPU power usage',
	...
	],

	requirements do not have to exist to be listed. this has allowed us to brain storm about the sub-requirements 
	
=item REVIEWED => 0,

=item IMPLEMENTATION_STATE => 0,

=item IMPLEMENTATION_PRIORITY => undef,

=back

=head2 Categories

	- A requirements does not have to be categorized
	- A requirements can belong to different categories
	- Categories are inherited from parents
	- Requirements can be sub-requirements to multiple requirements and thus inherit from different categories
	- Categories are checked
	
The categories template  is define in I<master_categories.pl>. The template is used by the <ra_check> application to check your requirements.

I<master_categories.pl> can also be run as application. When run, it will output the category structure on your terminal.

	$> perl master_categories.pl
		...
	| Build tool                                                                                                        
	|  |- _DEFINITION = The software program that can automate (parts of) the build process by taking sources and a build
	|  |  definition as input                                                                                            
	|  |- Internal commands                                                                                              
	|  |  `- _DEFINITION = Internal commands that can invoke functionality internally implemented in the build tool      
	|  |- Output                                                                                                         
	|  |  |- _DEFINITION = Output generated by the build tool                                                            
	|  |  `- Expected system                                                                                             
	|  |     `- _DEFINITION = A theoretical model showing the dependence between nodes, constructed by applying all the rules
	|  |        defining a system starting from a specified configuration and a target that can influence the rules application 
	|  |- Plug-ins                                                                                                              
	|  |  `- _DEFINITION = A functional extension to the Build Engine. Internal command implementations that can be plugged in into
	|  |     a specific directory, listed in a file or passed as argument to the build tool                                        
	|  |- Reliability                                                                                                              
	|  |  `- _DEFINITION = A build tool is reliable and behaves in a predictable manner under both normal and unexpected conditions |  
	|- Runtime build options                                                                                                     
	|  |  `- _DEFINITION = User selectable runtime options for the build tool and expected system                                   
	|  `- System creation                                                                                                           
	|     |- Build                                                                                                                  
	|     |  |- _DEFINITION = The creation of the physical artefacts based on on a System Description and a current physical        
		...
	
	number of categories = 81
	missing definitions = 11

=head3 Format

The categories are defined in a perl hash. Each hash entry is a category. Sub categories  are sub entries in the hashes. A B<_DEFINITION> field
is expected to be present and contain an explaination for the category. Although it is not an obligation, we more than recommend  to fill the 
B<_DEFINITION> field. The verification tool will complain if categories without B<_DEFINITION> field are found.

	{
	'category_name' => 
		{
		'_DEFINITION' => 'definition of the category',
		'sub_category_name' => 
			{
			'_DEFINITION' => 'definition of the sub category',
			'sub_sub_category_name' => 
				{
				'_DEFINITION' => 'definition of the sub sub category',
				...
				},
			...
			},
		'another_sub_category_name' => 
			{
			'_DEFINITION' => 'definition of the sub category',
			...
			},
		...
		},
	...
	}

=head3 Example

	{
	'Build tool' => 
		{
		'_DEFINITION' => 'The software program that can automate (parts of) the build process by taking sources and a build definition as input',
		'Internal commands' => 
			{
			'_DEFINITION' => 'Internal commands that can invoke functionality internally implemented in the build tool'
			},
			
		'Output' => 
			{
			'_DEFINITION' => 'Output generated by the build tool',
			'Expected system' => 
				{
				'_DEFINITION' => 'A theoretical model showing the dependence between nodes, constructed by applying all the rules defining a system starting from a specified configuration and a target that can influence the rules application'
				}
			},
			
		'Plug-ins' => ...
		'Reliability' => ...
		'Runtime build options' => 
			{
			'_DEFINITION' => 'User selectable runtime options for the build tool and expected system'
			},
		...
		},
	}

=head3 Verification

Running the B<ra_*> application will verify the categories you have assigned to requirements. Categories that are declared in
I<master_categories.pl> will be reported.

=head3 Physical sorting of the requirements

The file system layout doesn't have to match the requirement categorization, although that is sound.

Filesystem layout example:

	$> tree -d 
	.                                             
	|-- raw_requirements
	|-- some_directory_unrelated_to_requirements_but_related_project
	|-- sorted requirements
	|   |-- Build                                 
	|   |   |-- Build_Integration                 
	|   |   `-- Digest                            
	|   |-- Config                                
	|   |-- Depend                                
	|   |   `-- General                           
	|   |-- Distribution                          
	|   |   |-- Filesystem
	...
	|   |-- User_interaction
	|   |   |-- Debug
	|   |   |-- Documentation
	|   |   |-- General
	|   |   |-- Interface_to_PBS
	|   |   |-- statistics
	|   |   `-- wizards
	|   `-- environment
	|       `-- pathes
	`-- source

In the example above the requirements are in the same directory as other project artifacts.

=head2 Visualisation

All output on stddout.

=head3 Filtering

=head4 Requirements

The requirements can be filtered so only those matching  specified criterias  are displayed, EG: only display architectural requirements.

=head4 Requirements fields

You can choose to remove some of the requirement fields from the display, EG: remove the origin field from display

=head3 Requiremetns hierarchy

=head4 Structured

The relation between requirements and their sub requirements is kept

=head4 Flat

The requirements are sorted on its top category

=head3 Rendering formats

=head4 text

=head4 HTML/DHTML

=head2 Scripts and data location

=head1 SUBROUTINES/METHODS

=cut


#-------------------------------------------------------------------------------

sub get_template_files_from_directory
{

=head2 get_template_files_from_directory( xxx )

Returns the location of the template files

 <Arguments>

=over 2 

=item * $xxx - 

=back

I<Returns> - Nothing

I<Exceptions>

die if templates are not valid

See C<xxx>.

=cut

my ($directory, $master_template_file, $master_categories_file, $free_form_template) =  @_ ;

$master_template_file = $directory . '/master_template.pl'  unless(defined $master_template_file) ;
$master_categories_file = $directory . '/master_categories.pl'  unless(defined $master_categories_file) ;
$free_form_template = $directory . '/free_form_template.rat'  unless(defined $free_form_template) ;

return($master_template_file, $master_categories_file, $free_form_template) ;
}

#-------------------------------------------------------------------------------

use File::HomeDir ;

sub get_template_files
{

=head2 get_template_files( xxx )

Returns the location of the template files

 <Arguments>

=over 2 

=item * $xxx - 

=back

I<Returns> - Nothing

I<Exceptions>

die if templates are not valid

See C<xxx>.

=cut

my ($master_template_file, $master_categories_file, $free_form_template) =  @_ ;

return get_template_files_from_directory(home() . '/.ra/templates', $master_template_file, $master_categories_file, $free_form_template) ;
}

#--------------------------------------------------------------------------------------------------------------

sub load_master_template
{

=head2 load_master_template($master_template_file)

Load and verify the master template.

I<Arguments>

=over 2

=item * $master_template_file - Name to a file containing the master template.

=back

I<Returns>

=over 2

=item * $requirement_template - A template specifying the formatting of requirements.

=back

=cut

my ($master_template_file) = @_ ;
	
croak "Error: Can't find file '$master_template_file'" unless -f $master_template_file;

my $master_template = do $master_template_file or croak "Bad template '$master_template_file'! $@." ;

croak 'Error: Requirement is not a hash reference!' unless 'HASH' eq ref $master_template ;

croak "Error: This script can only handle update to version 2.0 of the requirement and use case template!" unless $master_template->{VERSION} == 2.0 ;

my $requirement_template = $master_template->{TEMPLATE} ;

return $requirement_template ;
}

#--------------------------------------------------------------------------------------------------------------

sub load_master_categories
{

=head2 load_master_categories($master_categories_file)

Load and verify the master template.

I<Arguments>

=over 2

=item * $master_categories_file - Name to a file containing the master categories.

=back

I<Returns>

=over 2

=item * %master_categories - A data structure containing the categories hierarchy

=back

=cut

my ($master_categories_file) = @_ ;
	
croak "Error: Can't find file '$master_categories_file'" unless -f $master_categories_file ;

my $master_categories = do $master_categories_file or croak "Bad template '$master_categories_file'! $@." ;

croak 'Error: Requirement is not a hash reference!' unless 'HASH' eq ref $master_categories;

return $master_categories;
}

#-------------------------------------------------------------------------------

1 ;

=head1 BUGS AND LIMITATIONS

None so far.

=head1 AUTHORS

	Nadim ibn hamouda el Khemir
	CPAN ID: NH
	mailto: nadim@cpan.org

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Requirement::Arch

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Requirement-Arch>

=item * RT: CPAN's request tracker

Please report any bugs or feature requests to  L <bug-app-requirement-arch@rt.cpan.org>.

We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=item * Search CPAN

L<http://search.cpan.org/dist/App-Requirement-Arch>

=back

=head1 SEE ALSO


=cut
