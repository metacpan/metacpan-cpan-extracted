NAME
      DBIx::DBStag - Relational Database to Hierarchical (Stag/XML) Mapping

SYNOPSIS
      use DBIx::DBStag;
      my $dbh = DBIx::DBStag->connect("dbi:Pg:dbname=moviedb");
      my $sql = q[
                  SELECT 
                   studio.*,
                   movie.*,
                   star.*
                  FROM
                   studio NATURAL JOIN 
                   movie NATURAL JOIN
                   movie_to_star NATURAL JOIN
                   star
                  WHERE
                   movie.genre = 'sci-fi' AND star.lastname = 'Fisher'
                  USE NESTING
                   (set(studio(movie(star))))
                 ];
      my $dataset = $dbh->selectall_stag($sql);
      my @studios = $dataset->get_studio;

      # returns nested data that looks like this -
      #
      # (studio
      #  (name "20th C Fox")
      #  (movie
      #   (name "star wars") (genre "sci-fi")
      #   (star
      #    (firstname "Carrie")(lastname "Fisher")))))

      # iterate through result tree -
      foreach my $studio (@studios) {
            printf "STUDIO: %s\n", $studio->get_name;
            my @movies = $studio->get_movie;

            foreach my $movie (@movies) {
                printf "  MOVIE: %s (genre:%s)\n", 
                  $movie->get_name, $movie->get_genre;
                my @stars = $movie->get_star;

                foreach my $star (@stars) {
                    printf "    STARRING: %s:%s\n", 
                      $star->get_firstname, $star->get_lastname;
                }
            }
      }
  
      # manipulate data then store it back in the database
      my @allstars = $dataset->get("movie/studio/star");
      $_->set_fullname($_->get_firstname.' '.$_->get_lastname)
        foreach(@allstars);

      $dbh->storenode($dataset);

    Or from the command line:

      unix> selectall_xml -d 'dbi:Pg:dbname=spybase' 'SELECT * FROM studio NATURAL JOIN movie'

DESCRIPTION
    This module is for mapping from databases to Stag objects (Structured
    Tags - see the Data::Stag manpage), which can also be represented as
    XML. It has two main uses:

    Querying
        This module can take the results of any SQL query and decompose the
        flattened results into a tree data structure which reflects the
        foreign keys in the underlying relational schema. It does this by
        looking at the SQL query and introspecting the database schema,
        rather than requiring metadata or an object model.

        In this respect, the module works just like a regular the DBI
        manpage handle, with some extra methods provided.

    Storing Data
        DBStag objects can store any tree-like datastructure (such as XML
        documents) into a database using normalized schema that reflects the
        structure of the tree being stored. This is done using little or no
        metadata.

        XML can also be imported, and a relational schema automatically
        generated.

    For a tutorial on using DBStag to build and query relational databases
    from XML sources, please see the DBIx::DBStag::Cookbook manpage

  HOW QUERYING WORKS

    This is a general overview of the rules for turning SQL query results
    into a tree like data structure.

   Relations

    Relations (i.e. tables and views) are elements (nodes) in the tree. The
    elements have the same name as the relation in the database.

   Columns

    Table and view columns of a relation are sub-elements of the table or
    view to which they belong. These elements will be data elements (i.e.
    terminal nodes). Only the columns selected in the SQL query will be
    present.

    For example, the following query

      SELECT name, job FROM person;

    will return a data structure that looks like this:

      (person
       (name "fred")
       (job "forklift driver"))
      (person
       (name "joe")
       (job "steamroller mechanic"))

    The data is shown as a lisp-style S-Expression - it can also be
    expressed as XML, or manipulated as an object within perl.

   Table aliases

    If an ALIAS is used in the FROM part of the SQL query, the relation
    element will be nested inside an element with the same name as the
    alias. For instance, the query

      SELECT name FROM person AS author WHERE job = 'author';

    Will return a data structure like this:

      (author
       (person
        (name "Philip K Dick")))

    The underlying assumption is that aliasing is used for a purpose in the
    original query; for instance, to determine the context of the relation
    where it may be ambiguous.

      SELECT *
      FROM person AS employee 
               INNER JOIN 
           person AS boss ON (employee.boss_id = boss.person_id)

    Will generate a nested result structure similar to this -

      (employee
       (person
        (person_id "...")
        (name "...")
        (foo  "...")
        (boss
         (person
          (person_id "...")
          (name "...")
          (foo  "...")))))

    If we neglected the alias, we would have 'person' directly nested under
    'person', and the meaning would not be obvious. Note how the contents of
    the SQL query dynamically modifies the schema/structure of the result
    tree.

   NOTE ON SQL SYNTAX

    Right now, DBStag is fussy about how you specify aliases; you must use
    AS - you must say

      SELECT name FROM person AS author;

    instead of

      SELECT name FROM person author;

   Nesting of relations

    The main utility of querying using this module is in retrieving the
    nested relation elements from the flattened query results. Given a query
    over relations A, B, C, D,... there are a number of possible tree
    structures. Not all of the tree structures are meaningful.

    Usually it will make no sense to nest A under B if there is no foreign
    key relationship linking either A to B, or B to A. This is not always
    the case - it may be desirable to nest A under B if there is an
    intermediate linking table that is required at the relational level but
    not required in the tree structure.

    DBStag will guess a structure/schema based on the ordering of the
    relations in your FROM clause. However, this guess can be over-ridden at
    either the SQL level (using DBStag specific SQL extensions) or at the
    API level.

    The default algorithm is to nest each relation element under the
    relation element preceeding it in the FROM clause; for instance:

      SELECT * FROM a NATURAL JOIN b NATURAL JOIN c

    If there are appropriately named foreign keys, the following data will
    be returned (assuming one row in each of a, b and c)

      (set
       (a
        (a_foo "...")
        (b
         (b_foo "...")
         (c
          (c_foo "...")))))

    where 'x_foo' is a column in relation 'x'

    This is not always desirable. If both b and c have foreign keys into
    table a, DBStag will not detect this - you have to guide it. There are
    two ways of doing this - you can guide by bracketing your FROM clause
    like this:

      !!##
      !!## NOTE - THIS PART IS NOT SET IN STONE - THIS MAY CHANGE
      !!## 
      SELECT * FROM (a NATURAL JOIN b) NATURAL JOIN c

    This will generate

      (set
       (a
        (a_foo "...")
        (b
         (b_foo "..."))
        (c
         (c_foo "..."))))
 
    Now b and c are siblings in the tree. The algorithm is similar to
    before: nest each relation element under the relation element preceeding
    it; or, if the preceeding item in the FROM clause is a bracketed
    structure, nest it under the first relational element in the bracketed
    structure.

    (Note that in MySQL you may not place brackets in the FROM clause in
    this way)

    Another way to achieve the same thing is to specify the desired tree
    structure using a DBStag specific SQL extension. The DBStag specific
    component is removed from the SQL before being presented to the DBMS.
    The extension is the USE NESTING clause, which should come at the end of
    the SQL query (and is subsequently removed before processing by the
    DBMS).

      SELECT * 
      FROM a NATURAL JOIN b NATURAL JOIN c 
      USE NESTING (set (a (b)(c)));

    This will generate the same tree as above (i.e. 'b' and 'c' are
    siblings). Notice how the nesting in the clause is the same as the
    nesting in the resulting tree structure.

    Note that 'set' is not a table in the underlying relational schema - the
    result data tree requires a named top level node to group all the 'a'
    relations under. You can call this top level element whatever you like.

    If you are using the DBStag API directly, you can pass in the nesting
    structure as an argument to the select call; for instance:

      my $seq =
        $dbh->selectall_xml(-sql=>q[SELECT * 
                                    FROM a NATURAL JOIN b 
                                         NATURAL JOIN c],
                            -nesting=>'(set (a (b)(c)))');

    or the equivalent -

      my $seq =
        $dbh->selectall_xml(q[SELECT * 
                              FROM a NATURAL JOIN b 
                                   NATURAL JOIN c],
                            '(set (a (b)(c)))');

    If you like, you can also use XML here (only at the API level, not at
    the SQL level) -

      my $seq =
        $dbh->selectall_xml(-sql=>q[SELECT * 
                                    FROM a NATURAL JOIN b 
                                         NATURAL JOIN c],
                            -nesting=>q[
                                        <set>
                                          <a>
                                            <b></b>
                                            <c></c>
                                          </a>
                                        </set>
                                       ]);

    As you can see, this is a little more verbose.

    Most command line scripts that use this module should allow pass-through
    via the '-nesting' switch.

   Aliasing of functions and expressions

    If you alias a function or an expression, DBStag needs to know where to
    put the resulting column; the column must be aliased.

    This is inferred from the first named column in the function or
    expression; for example, in the SQL below

      SELECT blah.*, foo.*, foo.x - foo.y AS z

    The z element will be nested under the foo element

    You can force different nesting using a double underscore:

      SELECT blah.*, foo.*, foo.x - foo.y AS blah__z

    This will nest the z element under the blah element

  Conformance to DTD/XML-Schema

    DBStag returns the Data::Stag manpage structures that are equivalent to
    a simplified subset of XML (and also a simplified subset of lisp
    S-Expressions).

    These structures are examples of semi-structured data - a good reference
    is this book -

      Data on the Web: From Relations to Semistructured Data and XML
      Serge Abiteboul, Dan Suciu, Peter Buneman
      Morgan Kaufmann; 1st edition (January 2000)

    The schema for the resulting Stag structures can be seen to conform to a
    schema that is dynamically determined at query-time from the underlying
    relational schema and from the specification of the query itself.

CLASS METHODS
  connect

      Usage   - $dbh = DBIx::DBStag->connect($DSN);
      Returns - L<DBIx::DBStag>
      Args    - see the connect() method in L<DBI>

  selectall_stag

     Usage   - $stag = $dbh->selectall_stag($sql);
               $stag = $dbh->selectall_stag($sql, $nesting_clause);
               $stag = $dbh->selectall_stag(-template=>$template,
                                            -bind=>{%variable_bindinfs});
     Returns - L<Data::Stag>
     Args    - sql string, 
               [nesting string], 
               [bind hashref],
               [template DBIx::DBStag::SQLTemplate]

    Executes a query and returns a the Data::Stag manpage structure

    An optional nesting expression can be passed in to control how the
    relation is decomposed into a tree. The nesting expression can be XML or
    an S-Expression; see above for details

  selectall_xml

     Usage   - $xml = $dbh->selectall_xml($sql);
     Returns - string
     Args    - See selectall_stag()

    As selectall_stag(), but the results are transformed into an XML string

  selectall_sxpr

     Usage   - $sxpr = $dbh->selectall_sxpr($sql);
     Returns - string
     Args    - See selectall_stag()

    As selectall_stag(), but the results are transformed into an
    S-Expression string; see the Data::Stag manpage for more details.

  selectall_sax

     Usage   - $dbh->selectall_sax(-sql=>$sql, -handler=>$sax_handler);
     Returns - string
     Args    - sql string, [nesting string], handler SAX

    As selectall_stag(), but the results are transformed into SAX events

    [currently this is just a wrapper to selectall_xml but a genuine event
    generation model will later be used]

  selectall_rows

     Usage   - $tbl = $dbh->selectall_rows($sql);
     Returns - arrayref of arrayref
     Args    - See selectall_stag()

    As selectall_stag(), but the results of the SQL query are left
    undecomposed and unnested. The resulting structure is just a flat table;
    the first row is the column headings. This is similar to
    DBI->selectall_arrayref(). The main reason to use this over the direct
    DBI method is to take advantage of other stag functionality, such as
    templates

  prepare_stag SEMI-PRIVATE METHOD

     Usage   - $prepare_h = $dbh->prepare_stag(-template=>$template);
     Returns - hashref (see below)
     Args    - See selectall_stag()

    Returns a hashref

          {
           sth=>$sth,
           exec_args=>\@exec_args,
           cols=>\@cols,
           col_aliases_ordered=>\@col_aliases_ordered,
           alias=>$aliasstruct,
           nesting=>$nesting
          };

  storenode

      Usage   - $dbh->storenode($stag);
      Returns - 
      Args    - L<Data::Stag>

    Recursively stores a tree structure in the database

SQL TEMPLATES
    DBStag comes with its own SQL templating system. This allows you to
    reuse the same canned SQL or similar SQL qeuries in different contexts.
    See the DBIx::DBStag::SQLTemplate manpage

  find_template

      Usage   - $template = $dbh->find_template("my-template-name");
      Returns - L<DBIx::DBStag::SQLTemplate>
      Args    - str

    Returns an object representing a canned paramterized SQL query. See the
    DBIx::DBStag::SQLTemplate manpage for documentation on templates

  list_templates

      Usage   - $templates = $dbh->list_templates();
      Returns - Arrayref of L<DBIx::DBStag::SQLTemplate>
      Args    - 

    Returns a list of ALL defined templates - See the
    DBIx::DBStag::SQLTemplate manpage

  find_templates_by_schema

      Usage   - $templates = $dbh->find_templates_by_schema($schema_name);
      Returns - Arrayref of L<DBIx::DBStag::SQLTemplate>
      Args    - str

    Returns a list of templates for a particular schema - See the
    DBIx::DBStag::SQLTemplate manpage

  find_templates_by_dbname

      Usage   - $templates = $dbh->find_templates_by_dbname("mydb");
      Returns - Arrayref of L<DBIx::DBStag::SQLTemplate>
      Args    - db name

    Returns a list of templates for a particular db

    Requires resources to be set up (see below)

RESOURCES
  resources_list

      Usage   - $rlist = $dbh->resources_list
      Returns - arrayref to a hashref
      Args    - none

    Returns a list of resources; each resource is a hash

      {name=>"mydbname",
       type=>"rdb",
       schema=>"myschema",
      }

SETTING UP RESOURCES
    The above methods rely on you having a file describing all the
    relational dbs available to you, and setting the env var
    DBSTAG_DBIMAP_FILE set (this is a : separated list of paths).

    This is alpha code - not fully documented, API may change

    Currently a resources file is a whitespace delimited text file -
    XML/Sxpr/IText definitions may be available later

    Here is an example of a resources file:

      # LOCAL
      mytestdb         rdb        Pg:mytestdb                      schema=test
  
      # SYSTEM
      worldfactbook    rdb      Pg:worldfactbook@db1.mycompany.com  schema=wfb
      employees        rdb      Pg:employees@db2.mycompany.com      schema=employees

    The first column is the nickname or logical name of the resource/db.
    This nickname can be used instead of the full DBI locator path (eg you
    can just use employees instead of
    dbi:Pg:dbname=employees;host=db2.mycompany.com

    The second column is the resource type - rdb is for relational database.
    You can use the same file to track other system datasources available to
    you, but DBStag is only interested in relational dbs.

    The 3rd column is a way of locating the resource - driver:name@host

    The 4th column is a ; separated list of tag=value pairs; the most
    important tag is the schema tag. Multiple dbs may share the same schema,
    and hence share SQL Templates

COMMAND LINE SCRIPTS
    DBStag is usable without writing any perl, you can use command line
    scripts and files that utilise tree structures (XML, S-Expressions)

    selectall_xml.pl
         selectall_xml.pl -d <DSN> [-n <nestexpr>] <SQL>

        Queries database and writes decomposed relation as XML

        Can also be used with templates:

         selectall_xml.pl -d <DSN> /<templatename> <var1> <var2> ... <varN>

    selectall_html.pl
         selectall_html.pl -d <DSN> [-n <nestexpr>] <SQL>

        Queries database and writes decomposed relation as HTML with nested
        tables indicating the nested structures.

    stag-storenode.pl
         stag-storenode.pl -d <DSN> <file>

        Stores data from a file (Supported formats: XML, Sxpr, IText - see
        the Data::Stag manpage) in a normalized database. Gets it right most
        of the time.

        TODO - metadata help

    stag-autoddl.pl
         stag-autoddl.pl [-l <linktable>]* <file>

        Takes data from a file (Supported formats: XML, Sxpr, IText - see
        the Data::Stag manpage) and generates a relational schema in the
        form of SQL CREATE TABLE statements.

ENVIRONMENT VARIABLES
    DBSTAG_TRACE
        setting this environment will cause all SQL statements to be printed
        on STDERR

BUGS
    This is alpha software! Probably several bugs.

    The SQL parsing can be quite particular - sometimes the SQL can be
    parsed by the DBMS but not by DBStag. The error messages are not always
    helpful.

    There are probably a few cases the SQL SELECT parsing grammar cannot
    deal with.

    If you want to select from views, you need to hack DBIx::DBSchema (as of
    v0.21)

TODO
    Use SQL::Translator to make SQL DDL generation less Pg-specific; also
    for deducing foreign keys (right now foreign keys are guessed by the
    name of the column, eg table_id)

    Can we cache the grammar so that startup is not so slow?

    Improve algorithm so that events are fired rather than building up
    entire structure in-memory

    Tie in all DBI attributes accessible by hash, i.e.: $dbh->{...}

    Error handling

WEBSITE
    http://stag.sourceforge.net

AUTHOR
    Chris Mungall <cjm@fruitfly.org>

COPYRIGHT
    Copyright (c) 2004 Chris Mungall

    This module is free software. You may distribute this module under the
    same terms as perl itself

