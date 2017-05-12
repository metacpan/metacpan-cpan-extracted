
=head1 NAME

  DBIx::DBStag::Cookbook - building and querying databases from XML

=head1 SYNOPSIS

  stag-autoddl.pl
  stag-storenode.pl
  selectall_xml.pl  

=head1 DESCRIPTION

This will give an outline of how to build a normalised relational
database from XML source data, set up SQL templates, issue relational
queries that return hierarchical results (as XML or as perl objects),
and autogenerate a web query front end for this data.

Why would you want to do this? Well, it gives you the full power of
the relational model and SQL, combined with the convenience of
representations which allow for the nesting of data entities (SQL
query results are typically flat relations which are inconvenient for
complex hierarchical data).

The dataset we will use is the CIA World Factbook.

The web interface should end up looking something like this -
L<http://www.godatabase.org/cgi-bin/wfb/ubiq.cgi>

=head2 AUTOGENERATING A RELATIONAL DATABASE

Download CIA world factbook in XML format; this has kindly been made
available by The University of Goettingen as part of their Mondial
database project, see
L<http://www.dbis.informatik.uni-goettingen.de/Mondial/> for details.

The actual XML file is available via
L<http://www.dbis.informatik.uni-goettingen.de/Mondial/cia.xml>

Or from
L<http://www.godatabase.org/wfb/cia.xml>

=head3 Pre-processing

We need to do some pre-processing of the XML to make it more
database-friendly. This is necessitated by the way Stag handles
attributes (Stag prefers XML documents that have a simple tree
format). We also want to turn XXX_id fields into XXX_ciaid, because we
prefer to use XXX_id for surrogate keys in the database.

  stag-mogrify.pl -w xml -r 's/text$/quant/'\
                         -r 's/id$/ciaid/'\
                         -r 's/(.*)\-//'\
                         cia.xml > cia-pp.xml

See also
L<http://www.godatabase.org/wfb/cia-pp.xml>

=head3 Generating the SQL DDL

Next we generate the SQL B<CREATE TABLE> statements

  stag-autoddl.pl -t cia-pp2.xml cia-pp.xml > cia-schema.sql

This does further post-processing of the XML, to make it suitable for
relational storage; see the file B<cia-pp2.xml> which is generated as
a side-effect of running the above script.

Load the database (the following instructions assume you have
postgresql on your localhost; please consult your DBMS manual if this
is not the case)

  createdb cia
  psql -a -e cia < cia-schema.sql >& create.log

(check there are no errors in the log file)

=head3 LOAD THE DATA

Turn the processed XML into relations:

  stag-storenode.pl -d dbi:Pg:dbname=cia cia-pp2.xml >& load.log

=head2 FETCHING TREE DATA USING SQL

You can issue SQL queries (using optional stag-specific extensions)
and get the results back in a hierarchical format such as XML

=head3 SQL to XML via the command line

Fetch countries nested under continents:

  selectall_xml.pl -d dbi:Pg:dbname=cia\
  "SELECT * FROM continent INNER JOIN country ON (continent.name=country.continent)"

Or, edit a file containing the SQL (the following query fetches data
on countries bordering other countries on different continents)

  cat > myquery.sql
  select c1.*, c2.*
  from country AS c1 
           inner join borders on (c1.country_id = borders.country_id)
           inner join country AS c2 on (borders.country=c2.ciaid)
  where c1.continent != c2.continent
  order by c1.name, c2.name
  use nesting (set(c1(c2)));

(the final clause is a DBStag SQL extension - it nests country c2
under country c1)

Then query for XML

  selectall_xml.pl -d dbi:Pg:dbname=cia -f myquery.sql > myresults.xml

=head3 SQL to XML via the Interactive Query Shell

Query the data using the stag query shell (qsh). You type in SQL
queries, and get results back as XML (or any other tree format, such
as indented text or S-Expressions).

The following can be cut and pasted directly onto the unix command
line:

Simple query rooted at B<country>:

  stag-qsh -d dbi:Pg:dbname=cia
  \l
  SELECT * FROM country INNER JOIN country_coasts USING (country_id)
  WHERE country.name = 'France';

(type \q to quit stag-qsh)

Or a more advanced query, still rooted at B<country>

  stag-qsh -d dbi:Pg:dbname=cia
  \l
  SELECT *
  FROM country
       LEFT OUTER JOIN religions USING (country_id)
       LEFT OUTER JOIN languages USING (country_id)
       INNER JOIN continent ON (continent.name=country.continent)
  WHERE continent.ciaid = 'australia'
  USE NESTING (set(country(religions)(languages)(continent)));

See L<DBIx::DBStag> for more details on fetching hierarchical data
from relational database

=head2 USING TEMPLATES

If you have a particular pattern of SQL you execute a lot, you can
reuse this SQL by creating B<templates>

=head3 Creating Templates

First create a place for your templates:

  mkdir ./templates

(do not change directory after this)

The following command specifies a colon-separated path for directories
containing templates (all templates must end with .stg)

  setenv DBSTAG_TEMPLATE_DIRS ".:templates:/usr/local/share/sql/templates"

Auto-generate templates (you can customize these later):

  stag-autoschema.pl -w sxpr cia-pp2.xml > cia-stagschema.sxpr
  stag-autotemplate.pl -no_pp -s cia -dir ./templates  cia-stagschema.sxpr

The first command creates an S-Expression representation of the
Schema; the second generates SQL templates from these.

You may wish to examine a template:

  more templates/cia-country.stg

You can hand generate as many templates as you like; see
L<DBIx::DBStag::SQLTemplate> for more details

For more example templates for this schema, see
L<http://www.godatabase.org/cgi-bin/wfb/ubiq.cgi>

=head3 Executing Templates from the Command Line

now execute a template from the command line:

  selectall_xml.pl -d dbi:Pg:dbname=cia /cia-country country_name=Austria

You should get back a tree (rooted in B<country>), that looks similar
to this:

  <set>
    <country>
      <country_id>3</country_id>
      <government>federal republic</government>
      <population>8023244</population>
      <total_area>83850</total_area>
      <name>Austria</name>
      <inflation>2.3</inflation>
      ...
      <languages>
        <languages_id>1</languages_id>
        <name>German</name>
        <num>100</num>
        <country_id>3</country_id>
      </languages>
      ...

=head3 Executing Templates with the Stag Query Shell

You can also do this interactively using qsh

First, we need to inform stag-qsh what the schema is. The schema is
used to determine which templates are appropriate. Later we will
discover how to set up a resources file, which will allow stag to
infer the schema.

Call qsh from command line:

  stag-qsh -d dbi:Pg:dbname=cia -s cia

Interactive perl/qsh:
  
  \l
  t cia-country
  /borders_country=cid-cia-Germany

(do not leave spaces at the beginning of the line)

The above should fetch all countries bordering Germany

If we prefer objects over hierarchical formats such as XML, we can do
this using perl. For example, to print the religions of spanish
speaking countries:

Still in qsh (multi-line mode), type the following:

  # find all Spanish-speaking countries
  $dataset =
    $dbh->selectall_stag(-template=>'cia-country',-bind=>{languages_name=>'Spanish'});
  # get country objects from query results
  @lcountry = $dataset->get_country;

  foreach $country (@lcountry) { 
    printf("Country: %s\n  Religions:%s\n",
           $country->sget_name,
           join(' & ', 
                map {
                     $_->get_name.' '.$_->get_quant.'%'
                } $country->get_religions))
  }
  print "\n\nDone!\n";
  \q

See L<Data::Stag> for more details on using Stag objects

=head2 BUILDING A CGI/WEB INTERFACE

We can construct a generic but powerful default cgi interface for our
data, using ubiq.cgi, which should come with your distribution. 

You may have to modify some of the directories below, depending on
your web server set up (we assume Apache here).

We want to create the CGI, and give it access to our templates:

  mkdir /usr/local/httpd/cgi-bin/cia
  cp templates/*.stg /usr/local/httpd/cgi-bin/cia
  cp `which ubiq.cgi` /usr/local/httpd/cgi-bin/cia
  chmod +x /usr/local/httpd/cgi-bin/cia/ubiq.cgi
  mkdir /usr/local/httpd/cgi-bin/cia/cache
  chmod 777 /usr/local/httpd/cgi-bin/cia/cache

Set up the environment for the CGI script. It must be able to see the
templates and the necessary perl libraries (if not installed
system-wide)

  cat > /usr/local/httpd/cgi-bin/cia/dbenv.pl
  $ENV{DBSTAG_DBIMAP_FILE} = "./resources.conf";
  $ENV{DBSTAG_TEMPLATE_DIRS} = ".:./templates:/usr/local/share/sql/templates";
  $ENV{STAGLIB} = "/users/me/lib/DBIx-DBStag:/users/me/lib/stag";

We must create a basic resources file, currently containing one db:

  cat > /usr/local/httpd/cgi-bin/cia/resources.conf
  cia              rdb               Pg:cia        schema=cia

Fields are whitespace delimited; do not leave a space before the
initial 'cia'

(note that if you set DBSTAG_DBIMAP_FILE to the avove file on the
command line, you can use the shortened name of B<cia> instead of
B<dbi:Pg:dbname=cia>)

You should be able to use the interface via
http://localhost/cgi-bin/cia/ubiq.cgi

You can customize this by overriding some of the existing display functions;

  cat > /usr/local/httpd/cgi-bin/cia/ubiq-customize.pl
  # --- CUSTOM SETTINGS
  {
   no warnings 'redefine';
   
   *g_title = sub {
       "U * B * I * Q - CIA World Factbook";
   };
   *short_intro = sub {
       "Demo interface to CIA World Factbook"
   };
   add_initfunc(sub {
  		   $dbname = 'cia';
  		   $schema = 'cia';
  	       });
  }


From here on you can customise the web interface, create new
templates, integrate this with other data. Consult L<DBIx::DBStag> and
the script B<ubiq.cgi> for further details.

=head2 FURTHER EXPLORATION

This cookbook has focused on an example with relatively simple XML,
with only a few layers of nesting. 

There is a more complex example you can download from the Mondial
project site here:
L<http://www.dbis.informatik.uni-goettingen.de/Mondial/mondial-2.0.xml>

This also integrates data on cities, which increases the depth of the
XML tree.

You could use the tutorial above to try and turn this XML into a
database.

=head1 WEBSITE

L<http://stag.sourceforge.net>

=head1 AUTHOR

Chris Mungall 

  cjm at fruitfly dot org

=head1 COPYRIGHT

Copyright (c) 2002 Chris Mungall

This module is free software.
You may distribute this module under the same terms as perl itself

=cut
