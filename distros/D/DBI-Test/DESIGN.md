# DESIGN

Currently this is a list of open issues and discussion points...

Topics can be removed once they're settled and the relevant docs have been
updated.


## DBI::Test as a DBD author's tool

This is the principle use-case for DBI::Test: to provide a common suite of
tests for multiple drivers.

We need to consider how evolution of DBI::Test will affect driver authors.
Specifically, as DBI::Test add new tests it's quite likely that some drivers
will fail that test, but that failure is not a regression for the driver.

So it seems reasonable for DBI::Test to be primarily a developer tool
and not run as a standard part of the drivers' test suite, at least for now.
In other words, DBI::Test would only be run if AUTHOR_TESTING is true.

That also allows us to duck the issue of whether DBD's should list DBI::Test as
a dependency. At least for now.


## DBI::Test as a DBI developer's tool

The goal here would be to test the methods the DBI implements itself and the
services the DBI provides to drivers, and also to test the various drivers
shipped with the DBI.

This is a secondary goal, but is important because DBI::Test will probably
become the primary test suite for the drivrs that ship with DBI.


## Define what DBI::Test is NOT trying to do

* It's not trying to test the database SQL behaviour (ORDER BY, JOINs etc).
Databases (an drivers that implement their own databases) should have their
own test suite for that.

* It's not trying to test the database SQL syntax. As many tests as possible
should be usable even for databases that don't use SQL at all.


## List some minimum and other edge cases we want to handle

Example: Using the DBM with SQL::Nano parser.

This means that, as far as possible, all tests should use very simple
SQL and only one or two string columns.

Obviously some tests will need to use more than two columns, or columns of
different type, but they should be the exception.

Tests that require other types or more columns (which should be rare) can use
$dbh->type_info and $dbh->get_info(SQL_MAXIMUM_COLUMNS_IN_TABLE) to check if
the test should be skipped for the current driver.


## Creating and populating test data tables (the fixtures)

If the test code creates and populates the test data tables (the fixtures)
then it'll be hard for drivers that don't use SQL, or use a strange variant, to
make use of the test suite.

So creation and population of fixtures should be abstracted out
into separate module(s) that can be overridden in some way if needed.

We shouldn't need many fixture tables. Most of the test suite could use
a table with two string columns that's populated with either zero or
three rows.

The interface from the test modules could be something like:

    $table_name = init_fixture_table(types => 'str,str', rows => 2);


## Should the test code construct statements itself?

As with the previous topic about test tables, if the tests have SQL embedded in
them then they'll be limited to testing drivers that support that syntax.
The DBI never parses the $statement (except for providing some support for
finding placeholders).

So it seems reasonable that construction of the $statement used for a given
test should be abstracted out into separate module(s) that can be overridden in
some way if needed.

The interface from the test modules could be something like:

    $statement = get_test_statement('name for statement', $table);

Where 'name for statement' is an identifier for the kind of statement needed
and get_test_statement() maps that to suitable SQL.

This is similar to the %SQLS in lib/DBI/Test/Case/basic/do.pm, for example.


## Should we create .t files at all, and if so, how many?

There's a need to have a separate process for some test cases, like
testing DBI vs DBI::PurePerl. But others, like Gofer (DBI_AUTOPROXY)
don't need a separate process.

Let's keep the generation of test files for now, but keep in mind the
possibility that some 'context combinations' might be handled
dynamically in future, i.e., inside the run_test() subroutine.


## Should test modules execute on load or require a subroutine call?

Execute on load seems like a poor choice to me.
I'd rather see something like a sub run { ... } in each test module.


## How and where should database connections be made?

I think the modules that implement tests should not perform connections.
The $dbh to use should be provided as an argument.


## How and where should test tables be created?

I think that creating the test tables, like connecting,
should be kept out of the main test modules.

So I envisage two kinds of test modules. Low-level ones that are given a $dbh
and run tests using that, and higher-level modules that handle connecting and
test table creation. The needs of each are different.


## Should subtests should be used?

I think subtests would be useful for non-trivial test files.
See subtests in https://metacpan.org/module/Test::More
The run() sub could look something like this:

    our $dbh;
    sub run {
        $dbh = shift;
        subtest '...', \&foo;
        subtest '...', \&bar;
        subtest '...', \&baz;
    }

to invoke a set of tests.

Taking that a step further, the run() function could automatically detect what
test functions exist in a package and call each in turn.

It could also call setup and teardown subs that could control fixtures.
Then test modules would look something like this:

    package DBI::Test::...;
    use DBI::Test::ModuleTestsRunner qw(run);
    sub test__setup { ... }
    sub test__teardown { ... }
    sub test_foo { ... }
    sub test_bar { ... }
    sub test_baz { ... }

The imported run() could also do things like randomize the execution
order of the test_* subs.

The test__setup sub should be able to skip the entire module of tests
if they're not applicable for the current $dbh and test context.
E.g., transaction tests on a driver that doesn't support transactions.

The test__teardown sub should aim to restore everything to how it was before
test__setup was called. This may become useful for things like leak checking.


## Is there a need for some kind of 'test context' object?

The low-level test modules should gather as much of the info they need from the
$dbh and $dbh->get_info. If extra information is needed in oder to implement
tests we at least these options:

1. Use a $dbh->{dbi_test_foo} handle attribute (and $dbh->{Driver}{dbi_test_bar})
2. Subclass the DBI and add a new method $dbh->dbi_test_foo(...)
3. Pass an extra argument to the run() function
4. Use a global, managed by a higher-level module

Which of those suits best would become more clear further down the road.


## Handling expected failures/limitations

Some combinations of driver and context will have limitations that will cause
some tests to fail. For example, the DBI test suite has quite a few special cases
for gofer:

    $ ack -li gofer t
    t/03handle.t
    t/08keeperr.t
    t/10examp.t
    t/48dbi_dbd_sqlengine.t
    t/49dbd_file.t
    t/50dbm_simple.t
    t/51dbm_file.t
    t/52dbm_complex.t
    t/65transact.t
    t/72childhandles.t

Some mechanism will be needed to either skip affected tests or mark them as TODO's.
This seems like a good use for some kind of 'test context' object that would
indicate which kinds of tests to skip. Something like:

    sub test_attr_Kids {
        plan skip_all => ''
            if $test_context->{skip_test_attr_Kids};
        ...
    }

Note that the mechanism should be very specific to the test and not copy the
current "skip if using gofer" design, which is too broard.

Umm. Given that design it's possible that run() could and should automate the
$test_context->{"skip_$test_sub_name"} check so it doesn't have to be written
out in each test whenever a new skip is needed.

There might be value in supporting TODO tests in a similar way.


## Using the test suite results to summarize driver behaviour

It would be useful to be able to store for later display the results of running
the tests on different drivers and in different contexts (gofer, nano sql,
pure-perl etc). Then it would be possible to render visualizations to compare
tests vs contexts and compare drivers across tests and contexts.
Something similar to the cpantesters and perl6 compiler features results:

    http://matrix.cpantesters.org/?dist=DBI
    http://perl6.org/compilers/features

This would be another win for using a smart run() sub and subtests 
The details() method in https://metacpan.org/module/Test::Builder#Test-Status-and-Info
should be able to provide the raw info.

