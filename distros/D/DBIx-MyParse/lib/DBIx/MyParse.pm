package DBIx::MyParse;

use strict;
use warnings;

use DBIx::MyParse::Query;
use DBIx::MyParse::Item;

our $VERSION = '0.88';

use constant MYPARSE_DB		=> 0;
use constant MYPARSE_OPTIONS	=> 1;
use constant MYPARSE_GROUPS	=> 2;
use constant MYPARSE_THD	=> 3;
use constant MYPARSE_DATADIR	=> 4;
use constant MYPARSE_SQLMODE	=> 5;

require XSLoader;
XSLoader::load('DBIx::MyParse', $VERSION);

my %args = (
	'db'		=> MYPARSE_DB,
	'database'	=> MYPARSE_DB,
	'options'	=> MYPARSE_OPTIONS,
	'groups'	=> MYPARSE_GROUPS,
	'datadir'	=> MYPARSE_DATADIR,
	'sql_mode'	=> MYPARSE_SQLMODE,
	'sql_modes'	=> MYPARSE_SQLMODE
	
);

1;

sub new {
	my $class = shift;
        my $parser = bless ([], $class);

	my $max_arg = (scalar(@_) / 2) - 1;
	
	foreach my $i (0..$max_arg) {
		if (exists $args{$_[$i * 2]}) {
			$parser->[$args{$_[$i * 2]}] = $_[$i * 2 + 1];
                } else {
			warn("Unkown argument '$_[$i * 2]' to DBIx::MyParse->new()");
		}
	}

	if (not defined $parser->[MYPARSE_DATADIR]) {
		warn("no 'datadir' specified for DBIx::MyParse->new(), assuming '/tmp/myparse'");
		$parser->[MYPARSE_DATADIR] = '/tmp/myparse';
	}

	if (not defined $parser->[MYPARSE_OPTIONS]) {
		$parser->[MYPARSE_OPTIONS] = [
			"--skip-bdb", "--skip-innodb", "--skip-isam",
			"--skip-ndbcluster", "--skip-merge",
			"--skip-grant-tables", "--skip-networking",
			"--key_buffer_size=1K", "--key_buffer=1K",
			"--sort_buffer_size=1K", "--myisam_sort_buffer_size=1K",
			"--read_only"
		];
	} elsif (ref($parser->[MYPARSE_OPTIONS]) ne 'ARRAY') {
		warn("argument 'options' to DBIx::MyParse->new() must be a reference to an array, ignoring");
		$parser->[MYPARSE_OPTIONS] = [];
	}

	push @{$parser->[MYPARSE_OPTIONS]}, '--datadir='.$parser->[MYPARSE_DATADIR];

	if (defined $parser->[MYPARSE_SQLMODE]) {
		push @{$parser->[MYPARSE_OPTIONS]}, "--sql_mode=".$parser->[MYPARSE_SQLMODE];
	}

	if (not defined $parser->[MYPARSE_GROUPS]) {
		$parser->[MYPARSE_GROUPS] = ["myparse"];
	} elsif (ref($parser->[MYPARSE_GROUPS]) ne 'ARRAY') {
		warn("argument 'groups' to DBIx::MyParse->new() must be a reference to an array, ignoring");
		$parser->[MYPARSE_GROUPS] = ["myparse"];
	}

	$parser->[MYPARSE_DB] = '' if not defined $parser->[MYPARSE_DB];

	my $ret = $parser->init_xs($parser->[MYPARSE_OPTIONS], $parser->[MYPARSE_GROUPS]);

	if ($ret == 0) {
		return $parser;
	} else {
		warn("Unable to initialize libmysqld.");
		return undef;
	}
}

sub setDatabase {
	my ($parser, $db) = @_;
	$parser->[MYPARSE_DB] = $db;
}

sub getDatadir {
	return $_[0]->[MYPARSE_DATADIR];
}

sub parse {
	my ($parser, $query_text) = @_;
	return $parser->parse_xs($parser->[MYPARSE_DB], $query_text);
}

1;


__END__

=head1 NAME

DBIx::MyParse - Perl API for MySQL's SQL Parser

=head1 SYNOPSIS

	use DBIx::MyParse;
	my $parser = DBIx::MyParse->new(
		database => 'database',
		groups => ['my_cnf_group'],
		options => ['--skip-networking'],
		datadir => '/tmp'
	);
	my $query = $parser->parse("SELECT field FROM table");
	print $query->getCommand();

=head1 DESCRIPTION

This module provides access to MySQL's SQL parser, which is a full-featured
lexx/yacc-based SQL parser, complete with subqueries and various MySQL extensions.

Please check the documentation for L<DBIx::MyParse::Query|DBIx::MyParse::Query> to see how you can access
the parse tree produced by C<parse()>. The parse tree itself consists of L<DBIx::MyParse::Item|DBIx::MyParse::Item> objects.

=head1 INSTALLATION

A binary RPM created using C<cpan2rpm> on a Fedora Core 6 is available from L<http://www.sf.net/projects/myparse>.
Alternatively, please see the C<README> for details on compiling the module from scratch. You will need to patch and
compile the MySQL source.

=head1 CONSTRUCTOR

The constructor allows one to specify what C<options> to be passed to C<libmysqld>. Please make sure your options are
all syntactically correct. An incorrect option can cause the constructor to C<exit()> in a silent and untrappable way.
If no C<options> are specified, the following defaults are used, which provide low memory usage:

	--skip-grant-tables --skip-networking --read_only
	--key_buffer_size=1K --key_buffer=1K --sort_buffer_size=1K --myisam_sort_buffer_size=1K
	plus --skip for all database engines except MyISAM which can not be --skip-ed

If you specify some C<options> however do not skip loading the database engines, e.g. Innodb, data files may be created
and a considerable ammount of memory may be occupied. You can also put your configuration options in C</etc/my.cnf>,
however it is recommended that you use a separate group within that file, rather than the C<[mysqld]> group.

It is also recommended that you specify a C<database> in the constructor or call C<setDatabase()> as soon as possible,
because some SQL statements will fail to parse without a default database. At the same time, please note that the default
database name may end up in your parse tree as if it was present in the SQL query itself.

It is also recommended that you also specify a C<datadir> because some SQL statements require an existing C<datadir> to parse
correctly. Furthermore, within the C<datadir>, you should have a subdirectory for each database you intend to use. There
is no need for the directory to contain any C<.FRM> files. If no C<datadir> is specified, C</tmp> is used. Do NOT specify a
datadir that contains useful information -- as this module grows, unforseen interactions can occur.

You can also specify a C<sql_mode> to influence the parsing behavoir. From all possible SQL modes listed in section 5.2.6
of the MySQL manual, only those that pertain to parsing are useful, e.g. C<"PIPES_AS_CONCAT">. Note that specifying non-parsing
flags such as C<"ERROR_FOR_DIVISION_BY_ZERO"> will not result in any division by zero errors in your SQL query being caught.
Multiple flags are specified with a comma separator.

Even if you do not have the rest of the MySQL disribution installed, you still need to have the
C</usr/local/share/mysql/charsets> directory. You can either run C<make install> in the
C</sql/share> of your MySql source tree or do a complete MySQL install to obtain it.

It is recommended that you only have one C<DBIx::MyParse> object per script. Having several objects is possible, however
options and sql_modes specified for the last object created will probably apply to all objects.

=head1 OPERATING ENVIRONMENT

At this time, the following options are passed to the MySQL library:


It is recommended that you do a C<setDatabase()> because certain SQL statements will fail to parse if there is no
default database.
 Furthermore, it is best to have a directory with the name of your database under C</tmp>.

=head1 UNSUPPORTED SQL STATEMENTS

A great deal of work has gone into supporting as much of the SQL syntax as possible.

The following SQL statements are not supported:

	UNION
	ALTER
	CREATE except CREATE DATABASE
	DROP except DROP DATABASE and DROP TABLE
	RENAME DATABASE
	HANDLER
	LOAD DATA INFILE
	HELP

The following esoteric SQL constructs are not currently supported:
	
	* LOAD DATA INFILE
	* SELECT INTO OUTFILE
	* SELECT PROCEDURE
	* CREATE DATABASE with CHARSET or COLLATION

The following SQL functions are not currenly supported:

	* VALUES(field)
	* ENCODE() and DECODE()
	* GET_FORMAT()
	* MAKE_SET()
	* GROUP_CONCAT
	* NAME_CONST()
	* MATCH WITH QUERY EXPANSION
	* MATCH IN BOOLEAN MODE
	* TRIM()

=head1 ADVANTAGES OF THE APPROACH

This is a full-featured SQL parser, not a set of regular expressions that parse just
the most common queries. It makes use of a complete parsing grammar taken from a real-life
database, by virtue of the fact that it uses the MySQL parsing engine to do the dirty work.

This module will accept any input that is a valid MySQL command and will reject any input
that is not a valid MySQL command. Accepting an imput is one thing, producing a complete and
meaningful parse tree is a different thing, however the module currently produces parse trees
of considerable complexity for almost all SQL constructs.

MySQL is unlikely to crash on SQL expressions of any complexity, and so is this parser API. In
particular, weird functions, complex nested expressions and operator precedence are all handled
correctly by definition. Subqueries and nested joins are also fully supported.

Errors are returned as both error numbers, error codes in English and language-specific long
MySQL error messages, rather than as C<die()> or C<carp()>.

The module's objects are completely hash-free, which should be considerably faster than a comparable
hash-based implementation.

=head1 DISADVANTAGES

This module is hooked directly to MySQL's internals. Non-MySQL SQL features are not supported
and can not be supported without changing the MySQL source code. Extending MySQL to support new
functionality is far more complicated and rewarding than simply adding a few regexps to your
home-grown SQL parser.

Some of MySQL's code is not friendly towards being (ab)used in the manner employed by this module. There
are object methods declared Private for no obvious reasons.

MySQL is GPL, so this module is GPL, please see the COPYRIGHT section below for more information.

=head1 TESTING

Apart from the standard C<make test> test suite, the following approaches were used to test this module:

	* The MySQL test suite
	* the crash-me script from the MySQL benchmark suite
	* DBD::mysql tests

=head1 SEE ALSO

Please see the following sources for further information:

MySQL Internals Manual: L<http://dev.mysql.com/doc/internals/en/index.html>

Doxygen documentation for MySQL 4.1 source: L<http://www.distlab.dk/mysql-4.1/html/>

Doxygen documentation for MySQL 5 source: L<http:://leithal.cool-tools.co.uk/sourcedoc/mysql509/html/index.html>

C<DBIx::MyParse> has a page at SourceForge: L<http://sourceforge.net/projects/myparse/>

=head1 AUTHOR

Philip Stoev E<lt>philip@stoev.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Philip Stoev

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public Licence

Please note that this module links to libmysqld which is distributed under
GPL as well. If you intend to use this module in a commercial product, you are
strongly advised to contact MySQL directly to obtain a commercial licence for 
the MySQL embedded server.

Please see the file named LICENCE for the full text of the GNU General Public Licence

=cut
