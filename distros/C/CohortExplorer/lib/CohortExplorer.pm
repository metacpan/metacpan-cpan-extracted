#!/usr/bin/perl

package CohortExplorer;

use 5.006;

use strict;
use warnings;

our $VERSION = 0.14;

use CohortExplorer::Application;

# Untaint arguments
for ( 0 .. $#ARGV ) {
 if ( $ARGV[$_] =~ /^(.*)$/ ) {
  $ARGV[$_] = $1;
 }
}

#-------

1;

__END__

=head1 NAME

CohortExplorer - Explore clinical cohorts and search for entities of interest

=head1 SYNOPSIS

B<CohortExplorer [OPTIONS] COMMAND [COMMAND-OPTIONS]>

=head1 DESCRIPTION

CohortExplorer provides an abstracted command line search interface for querying data and meta data stored in clinical data repositories implemented using the Entity-Attribute-Value (EAV) schema also known as the generic schema. Most of the available electronic data capture and clinical data management systems such as L<LabKey|https://labkey.com/>, L<OpenClinica|https://www.openclinica.com/>, L<REDCap|http://project-redcap.org/>, L<Onyx|http://obiba.org/node/3> and L<Opal|http://obiba.org/node/63> use EAV schema as it allows the organisation of heterogeneous data with relatively simple schema. With CohortExplorer's abstracted framework it is possible to 'plug-n-play' with clinical data repositories using the L<datasource API|CohortExplorer::Datasource>. The datasources stored in Opal, REDCap and OpenClinica can be queried using the built-in APIs (see L<here|http://www.youtube.com/watch?v=Tba9An9cWDY>).

The application makes use of the following concepts to explore clinical data repositories using the EAV schema:

=over 

=item B<Datasource>  

A study or a cohort.

=item B<Standard datasource>

Datasource which involves observing entities (e.g. the participant or drug) at a single time-point alone.

=item B<Longitudinal datasource> 

Datasource which involves a repeated observation of entities over different time-points, visits or events.

=item B<Tables> 

Questionnaires, surveys or forms in a datasource.

=item B<Variables and values> 
 
The questions, which form part of the study, are called variables and values are answers to the questions.

=item B<Static table> 

Questionnaires which are used only once in the course of the study are grouped under the static table. The static table represents data that is unchanging. All questionnaires within standard (or cross-sectional) datasources are static. However, the longitudinal datasources may also contain some questionnaires that can be grouped under the static table such as Demographics and FamilyHistory.
      
=item B<Dynamic table> 

Questionnaires which are used repeatedly throughout the study are classed under the dynamic table. This table applies only to the longitudinal datasources and represents data that is changing with time.
      
=back

=head1 MOTIVATION

I have not found any query tools that can standardise the EAV schema. The EAV schema varies with electronic data capture and clinical data management systems. This poses a problem when two or more research groups collaborate on a project and the collaboration involves data exchange in the form of database dump (anonymised). The research groups may have used a different EAV schema to store clinical data. CohortExplorer is an attempt to standardise the entity attribute value model so the users can 'plug-n-play' with EAV schemas.

In addition, our group's specific query requirements also motivated me to write CohortExplorer.
       
=head1 FEATURES

=over

=item 1

Allows the user to query datasources stored in multiple database instances.

=item 2

Access to datasource is granted only after authentication.
       
=item 3

Commands can be run on command line as well as interactively (i.e. console). It is easy to set-up a reporting system by adding commands to cron (under Linux).
        
=item 4

Command-line completion for options and arguments wherever applicable.
        
=item 5

Entities can be searched with/without imposing conditions on the variables.
        
=item 6 

Allows the user to save commands and use them to build new ones.
        
=item 7

Datasource description including entity count can be obtained.
        
=item 8

Allows the user to view summary statistics and export data on tables in csv format which can be readily parsed in statistical software like R for downstream analysis.

=item 9

Allows the user to query for variables and view variable dictionary (i.e. meta data).
        
=back

=head1 OPTIONS

=over

=item B<-d> I<DATASOURCE>, B<--datasource>=I<DATASOURCE>

Provide datasource

=item B<-u> I<USERNAME>, B<--username>=I<USERNAME>
             
Provide username

=item B<-p> I<PASSWORD>, B<--password>=I<PASSWORD>

Provide password

=item B<-h>, B<--help>

Show usage message and exit

=item B<-v>, B<--verbose>

Show with verbosity

=back

B<Note> the username and password is the same as the parent clinical data repository. The command is an argument to CohortExplorer.

=head1 COMMANDS 

=over

=item B<describe>

This command outputs the datasource description in a tabular format where the first column is the table name followed by the table attributes such as label and variable_count. The command also displays entity count for the specified datasource. For more on this command see L<CohortExplorer::Command::Describe>.
      
=item B<find>
      
This command enables the user to find variables by supplying keywords. The command prints the dictionary of variables meeting the search criteria. The variable dictionary can include variable attributes such as variable name, table name, unit, categories (if any) and the associated label. For more on this command see L<CohortExplorer::Command::Find>.
      
=item B<search>

This command enables the user to search for entities by supplying the variables of interest. The user can also impose conditions on the variables. For more on this command see L<CohortExplorer::Command::Query::Search>.
      
=item B<compare>

This command enables the user to compare entities across visits by supplying the variables of interest. The command is only available to the longitudinal datasources with data on at least 2 visits. For more on this command see L<CohortExplorer::Command::Query::Compare>. 
      
=item B<history>

This command enables the user to see all previously saved commands. The user can utilise the existing information like options and arguments to build new commands. For more on this command see L<CohortExplorer::Command::History>.
      
=back

=head1 EXAMPLES

 [somebody@somewhere]$ CohortExplorer --datasource=Medication --username=admin --password describe (run describe command)

 [somebody@somewhere]$ CohortExplorer -v -dMedication -uadmin -p sh (start console in verbose mode)
   
 [somebody@somewhere]$ CohortExplorer -dMedication -uadixit -p find -fi cancer diabetes (run find command with aliases)

=head1 SECURITY

When setting CohortExplorer for group use it is recommended to install the application using its debian package which is part of the release. The package greatly simplifies the installation and implements the security mechanism. The security measures include:

=over

=item *

forcing the taint mode and,

=item *

disabling the access to configuration files and log file to users other than the administrator or root (user).

=back

=head1 BUGS 

Currently the application does not support the querying of datasources with multiple arms. The application is only tested with clinical data repositories implemented in MySQL and is yet to be tested with repositories implemented in Oracle and Microsoft SQL Server. Please report any bugs or feature requests to adixit@cpan.org.

=head1 DEPENDENCIES

L<Carp>

L<CLI::Framework>

L<Config::General>

L<DBI>

L<Exception::Class::TryCatch>

L<File::HomeDir>

L<File::Spec>

L<Log::Log4perl>

L<SQL::Abstract::More>

L<Term::ReadKey>

L<Text::ASCIITable>

L<Tie::IxHash>

=head1 SEE ALSO

L<CohortExplorer>

L<CohortExplorer::Datasource>

L<CohortExplorer::Command::Describe>

L<CohortExplorer::Command::Find>

L<CohortExplorer::Command::History>

L<CohortExplorer::Command::Query::Search>

L<CohortExplorer::Command::Query::Compare>

=head1 ACKNOWLEDGEMENTS

Many thanks to the authors of all the dependencies used in writing CohortExplorer and also everyone for their suggestions and feedback.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013-2014 Abhishek Dixit (adixit@cpan.org). All rights reserved.

This program is free software: you can redistribute it and/or modify it under the terms of either:

=over

=item *
the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version, or

=item *
the "Artistic Licence".

=back

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details (http://www.gnu.org/licenses/).

On Debian systems, the complete text of the GNU General Public License can be found in '/usr/share/common-licenses/GPL-3'.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

Abhishek Dixit

=cut

1; # End of CohortExplorer
