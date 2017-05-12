1;

# --- PerlDoc_umentation ;-) 

__END__

=head1 NAME

classgen - script that generates a class-module from a control file.


=head1 VERSION

3.03

=head1 SYNOPSIS

!!! A fake-module, just to make the documention in the classgen-script visible to CPAN !!!

classgen input.txt Output.pm	# generate new class


perldoc Output.pm	# review the fresh pod-skelton

vi Output.pm		# edit specific methods

less Output_gs.pm	# instance methods get-/set-


For historical reasons the synonym ".gs" is still inthis documentation. Please
read it as "<file>_gs.pm".
		

=head1 DESCRIPTION

You specify the required instance-variables of a desired class by a control-file. 

Classgen then creates a new package for you which contains the C<new()>-method, accessor- and manipulator-methods for all instance-variables of that class. All instance-variables are blessed into an anonymous hash {}.

classgen adds a basic, simple perldoc skelton to support your documentation for new classes.

For a better overview version 3.03 splits the package into a .pm and a .gs file. The .gs file contains all standard get-/set-methods and will be reviewed only on occasion. The .pm will focus on the specific methods only. Printouts will become much shorter and your overview will increase.


=head2 Input format of the control file

The control file is an ASCII-file which must contain the 3 sections with specific keywords in the specified order:

	header:
	variables:

classgen will scan for these 2 sections and act accordingly. classgen will insist on using exactly these section-headers. It will die, if you don't.

=over 4

=item *
I<header:> In this section you can put any Perl statement you need. classgen will simply copy this section to the beginning of your output file. You should at least include B<package Your_Class_Name_here; use strict;>

=item *
I<variables:> In this section you specify all your required instance-variables. classgen will determine the required type from the first character ($,@ or %) and will create all required variable-related methods for you. - For your convenience and to nurture self-documentation of your new class you can add some descriptive comments after the variable, just using a #.

=back

=head2 Methods generated

classgen generates accessor- and manipulator-methods as required by the variables type. The order of methods is:

=over 4

=item *

new-method

=item *

specifc methods (to be extended by the user)

=item *

accessor methods

=item *

manipulator methods

=item *

(perldoc-skelton) (to be extended by the user)

=back

The B<specific()> method is intended for copy&paste operation to easily append the generated class with more specific class-methods by the user.


A variable-name consists of <type><var_name>, with <type>=($,@,%). Via <type> methods are generated as:

	<method name><var_name>

Run B<perldoc Attribute.pm> for an overview of all created methods.


=head2 Missing Methods for the created Objects

A B<serialize()> method should be added. So far my personal lack of knowledge in this subject prevented me from supplying you with one. Conway examines some possibilities, which you can find at CPAN.

=head2 Other Objects involved

classgen will use instances from the

=over 4

=item *
New.pm - Object

=item *
Attributs.pm - Object

=item *
Section.pm - Object

=item *
Comment.pm - just a package, not an object. Cf. perldoc Comment.pm

=back



=head2 Subroutines used by classgen

Internal methods:

=over 4

=item *
check_of_sections: to ensure every needed section is there

=item *
clean_up: to remove \t and other whitespaces

=item *
find_section: use this to use correct keywords

=item *
get_sections: to retrieve sections from input file

=item *
init_attributes : to generate Attribute-instances for all variables

=item *
init_new: to initialize the New-instance

=item *
write_begining : to write the first few lines into the new class

=item *
write_end :  code at the end of the new class

=item *
write_methods: to generate all required methods for each variable

=item *
write_new: to write the new-function of the generated class

=back


=head2 How to use classgen

In version 3.03 an archive functionality has been introduced. Before classgen creates the .pm and the .gs files from the control file, the old files are copied into the /archive directory with an increasing numeriacl starting index. So your previous edits are not lost.

=over 4

=item *
FIRST RUN: Simply create a control file somewhere and create the output file where appropriate (e.g. classgen /controls/example /Objects/Example.pm).

=item *
ADDITIONAL RUNS: Classgen copies the current versions of .pm and .gs into the /archive directory. Next, it overwrites the current .pm and .gs as indicated by your control file.

=item *
ADDING METHODS: Edit your newly created package (e.g. Example.pm). Use the dummy-method at the end to create all further required methods of your class. All accessor- and manipulator-methods should already be there (I hope :-)

=item *
REMOVING METHODS: Cut them with your editor from the newly created package (e.g. Example.pm) or put comments at every line of the undesired subroutine.
Perhaps you want to use them later again? Then cut them first and paste them to an intermediate-file.

=item *
RESTORING REMOVED METHODS: You have several choices: re-run classgen to create a safe copy of your package (e.g. Example_new.pm); copy&paste the missing part. Or re-use the intermediate-file from the previous hint; retrieving it from one of the files in the /archive directory etc. 

=back

=head2 How to produce undesired results (and how to avoid them)

Version 3.03: Problems from overwriting have been removed. Your edits are copied to the /archive directory first.



=head2 How to handle inheritance of classes

Derive two classes with classgen. In the header-section of the derived class you can add the required Perl-statements already in the control-file.

Make sure to include the base-class in an @ISA-statement and adapt the call to inherit_from() right after the blessing in the new() method of your derived class.

See also   examples/inheritance/README

=head2 Open issues

I would like to know how classgen performs compared to other approaches to object-oriented-implementations. How can I find out how much memory my version actually consumes? - Please, gimme a hint ...

Instance-variables could also be blessed into [] or $. Initially I planned to offer these choices, too. It turned out to be more convenient to omit this for a start. Your benefit is that you can do less things wrong. As a by-product the control file becomes more handy ;-)

=head2 Background / Motivation

J.Rumbaughs "Object Oriented Modelling" showed me a very promissing way to tackle challenging software-projects. The idea is to identify relevant classes (objects), their relationship (associations), their dynamic behaviour (statediagrams) and their flow of data (functional model) - all on paper.

Once done and tested by various scenarios a very good specification has been grown. Then there are ways to implement these objects both in object-oriented (e.g. C++, Smalltalk, Eiffel) and NON-object-oriented languages (e.g. C, Fortran, Algol) or databases. - What a challange for Perl!

I tried Damian Conways excellent book "Object Oriented Perl", which has been published in fall 1999. I learned again, that there still "... are always more than one way to do it" when it comes to implementing objects in Perl:

=over 4

=item *
do it by hand: introduce a new instance-variable and write all required methods to acces or change this variable yourself.

=item *
use the AUTOLOAD-mechanism to provide all required get- and set-methods at run-time.

=item *
use class-templates, like Class::Struct or Class::MethodMaker.

=back

Clearly, the first choice is the least desireable one. It is prone to typing errors and one spends more time on same methods again rather than on methods unique to the class (as I would prefer).

The other methods have some advantages and some disadvantages. The least tasty for me was that they tend to produce "obscure" code, at least in
examples I looked at. That is, code where I had to spend a lot of thinking to understand what it does.

Rather, I'd prefer code which I can understand at just one glance (idealy ;-). Therefor classgen creates almost every get- and set-method you can think of. Should you need it, it is already there. Should you dislike it, simply throw methods away. Or even better, just do not care about their existence at all. Stay focused on what your class should be doing, not on the instance-variables.

There is another inportant reason for my approach. I feel OOP-code appears to be more 'cleaner' when it can be distributed over separated, individual files. Some of the approaches mentioned above tend to create and modify objects WITHIN another program. I think that shouldn't be done. Have a look at my 'peanuts' example.


=head2 Future Plans

classgen lets me create new classes within minutes rather than days. I myself am quite satisfied with the current performance. classgen was created more or less on-the-fly. Perhaps I will redesign it by a more consequent OMT-approach lateron.

But before doing so I'd need more input about the good's and bad's from you to make up my mind.  The missing parts. The nice-to-have things and so on.

If you like classgen and want it to have more useful functions please let me know ;-)

=head1 ENVIRONMENT

Perhaps you may have to modify the first line in classgen due to different locations of perl on different operating systems. If so, you'll probably find classgen as (watch make install for details):

	/usr/bin/classgen

You can avoid this adaption if you simply call:

	perl classgen <input_file> <output_class>


=head1 DIAGNOSTICS

When running classgen you will see the message:

	#: 2
	var1head1
	N: 2

which is a relict from program development. It helped me to trace if the correct sections where identified. It does not harm very much and perhaps may be useful to find errors lateron. So, for the moment, it is just in the program.

classgen runs with the B<-w> option. If you call classgen with the wrong number of arguments it will simply die. The subroutines should either return your requested result or "undef".

The ideal diagnostics is the diagnostic which is not there, but which function is performed. - To approach this ideal I did the following:

The sensitivity analysis part from the Taguchi-method has been used to measure sensitivity of classgen against errorness inputs from the control file (that is against variable usage-conditions). Only those kinds of errors which are likely to occure for a serious user, playing by the rules, where investigated. Those are for example:

=over 4

=item *

missing ; in the header section (no problem, but perl will complain lateron; this is somewhat inconvenient)

=item *

putting , or ; after a variable from the variables: section (causing strange methods generated)

=item *

putting comments in all sections (not allowed in the early version, but very useful for self-documentation purposes)

=back 

This lead to creating the Comments.pm package, which provides just a few simple routines to detect and to correct the errors mentioned above.

=head2 Error Messages:

In alphabetical order:

=over 4

=item *
'less sections than expected' - not all sections could be found -- check if delimiter ':' has been used ( from: check_of_sections() )

=item *
'more sections than expected' - there are more sections specified than allowed -- check for multiple sections or not allowed sections ( from: check_of_section() )

=item *
'specified identifier $id is ambigous' - more than one section is found in the control file with the same name -- check the control file for unique
sections ( from: find_section() )

=item *
'specified identifier $id not found in %section' - this section is missing in the control file -- add this section to the control file ( from: find_section() )

=back


=head1 BUGS

You should always put at least one instance-variable into your class. If you don't, you'll get a strange blessing ;-) . In most cases you probably will do so automatically, so I decided to leave this invonvenience until I know if it is worth while to re-concept classgen or not (cf. Future Plans).

=head1 FILES

=head2 Installation

Copy the .gz to a suitable directory. Run 'gunzip' and 'tar xvf '. Change to Class/Classgen. Execute:

	perl Makefile.PL
	make

As root do the final installation:

	make install

When you run Perl under Windows you may want to use nmake.exe instead of make (download e.g. from ftp://ftp.microsoft.com/Softlib/MSLFILES/nmake15.exe)

=head1 SEE ALSO

	Changes

=head2 Methods created by classgen

Run
	perldoc Attribute.pm

Run
	perldoc New.pm


=head2 Example: Starting up with classgen

You may also want to review the included example files, which creates the class Example.

=over 4

=item *
control.txt is the control-file for the class Example

=item *
Example.pm is the result created by classgen

=item *
'classgen control.txt Example.pm' will create Example.pm

=back

=head2 perldoc

Please refer also to

=over 4

=item *
perldoc New.pm (specifics of the created $self->new() function)

=item *
perldoc Attribute.pm (type dependend functions)

=item *
perldoc Section.pm (splitting up the control file)

=item *
perldoc Comments.pm (dealing with comments)

=back


=head2 Books I referred to

=over 4

=item *
J.Rumbaugh, I<Objektorientiertes Modellieren und Entwerfen>, ISBN 3-446-17520-2  or J.Rumbaugh I<Object-Oriented Modeling and Design>, ISBN 0136298419

=item *
D.Conway, I<Object Oriented Perl>, ISBN 1-884777-79-1

=back


=head1 AUTHOR

Name:  Michael Schlueter
email: mschlue@cpan.org

=head1 COPYRIGHT

Copyright (c) 2000, Michael Schlueter. All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as Perl itself.
