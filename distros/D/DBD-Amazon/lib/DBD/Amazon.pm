#
#   Copyright (c) 2005, Presicient Corp., USA
#
# Permission is granted to use this software according to the terms of the
# Artistic License, as specified in the Perl README file,
# with the exception that commercial redistribution, either 
# electronic or via physical media, as either a standalone package, 
# or incorporated into a third party product, requires prior 
# written approval of the author.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# Presicient Corp. reserves the right to provide support for this software
# to individual sites under a separate (possibly fee-based)
# agreement.
#
#	History:
#
#		2005-Jan-27		D. Arnold
#			Coded.
#

require DynaLoader;
require DBD::File;
require IO::File;

package DBD::Amazon;
use vars qw(@ISA $VERSION $drh $err $errstr $sqlstate);

our @ISA = qw(DBD::File);

use SQL::Amazon::StorageEngine;

use Exporter;
use base qw(Exporter);

BEGIN {
our @EXPORT    = ();		   
our @EXPORT_OK = qw($amzn_engine);
}

use strict;

our $amzn_engine;	

our $VERSION = '0.10';

our $err = 0;		
our $errstr = '';	
our $sqlstate = '';	
our $drh = undef;	

my $installed = undef;

sub driver {
	return $drh if $drh;
	my ($class, $attr) = @_;

    $attr->{Attribution} = 'DBD::Amazon by Presicient Corp.';
    my $this = $class->SUPER::driver($attr);
	$amzn_engine = SQL::Amazon::StorageEngine->new();
	unless ($DBD::Amazon::installed) {
	}

	DBI->trace_msg("DBD::Amazon v.$VERSION loaded on $^O\n", 1);
	$drh->{_connections} = {};

    $this;	
}

sub CLONE {
	undef $drh;
}

1;

package DBD::Amazon::dr;

use SQL::Amazon::Parser;
use DBD::Amazon qw($amzn_engine);
use vars qw(@ISA);

@DBD::Amazon::dr::ISA = qw(DBD::File::dr);

use strict;

our $imp_data_size = 0;

our %valid_attrs = qw(
amzn_affiliate_id 0
amzn_strict 1
amzn_rate_limit 1
amzn_max_pages 20
amzn_locale us
amzn_resp_group Large
);

our %valid_locales = qw(
us 1
uk 1
de 1
fr 1
jp 1
ca 1
);

sub connect {
	my ($drh, $dsn, $user, $passwd, $attrs) = @_;
	return $drh->DBI::set_err(-1, 'No Amazon user ID provided.', 'S1000')
		unless (defined($user) && ($user ne ''));

	$attrs = { } unless $attrs;
	foreach (keys %$attrs) {
		return $drh->DBI::set_err(-1, "Unknown attribute $_", 'S1000')
			if (/^amzn_(\w+)$/ && (! $valid_attrs{$_}));
	}
	foreach (keys %valid_attrs) {
		$attrs->{$_} = $valid_attrs{$_} 
			unless defined($attrs->{$_});
	}
	return $drh->DBI::set_err(-1, "Invalid locale attribute $$attrs{amzn_locale}", 'S1000')
		unless $valid_locales{$attrs->{amzn_locale}};

    my $dbh = $drh->DBD::File::dr::connect($dsn, $user, $passwd, $attrs);

	return DBI::set_err(-1, 'Cannot create connection handle.', 'S1000')
		unless $dbh;

	$dbh->{amzn_parser} = SQL::Amazon::Parser->new();
	return DBI::set_err(-1, 'Cannot create parser for Amazon dialect.', 'S1000')
		unless $dbh->{amzn_parser};

    $dbh->{Active} = 1;
	return $dbh;
}
sub data_sources {
   my($drh, $driver_name) = @_;
   return '';
}

sub disconnect_all { 
}

sub DESTROY { 
}

1;


package DBD::Amazon::db;

use SQL::Amazon::Statement;
use DBD::Amazon qw($amzn_engine);

@DBD::Amazon::db::ISA = qw(DBD::File::db);

our $imp_data_size = 0;

our %valid_attrs = qw(
amzn_strict 1
amzn_max_pages 20
amzn_resp_group Large
);

use strict;

sub prepare {
	my ($dbh, $sql, $attrs) = @_;
	
	if ($attrs) {
		foreach (keys %$attrs) {
			next unless /^amzn_/;
			
			return $dbh->set_err(-1, "Unknown statement attribute $_.", 'S1000')
				unless $valid_attrs{$_};
		}
	}
    my $sth = DBI::_new_sth($dbh, {'Statement' => $sql});

	return DBI::set_err(-1, 'Cannot create statement handle.', 'S1000')
		unless $sth;
	$ENV{DBD_AMZN_DEBUG} = ($dbh->{TraceLevel} & 12);
	my $stmt = SQL::Amazon::Statement->new($sql, $dbh->{amzn_parser},
		$amzn_engine);
    undef $sth,
	return DBI::set_err($dbh, 1, $stmt->errstr, 'S1000')
		if $stmt->errstr;
	my $command = $stmt->command();
    undef $sth,
	return DBI::set_err($dbh, -1, "$command statements not supported.", 'S1000')
		if (($command eq 'CREATE') || ($command eq 'DROP'));

	my @tables = $stmt->tables();
	foreach (0..@tables) {
    	undef $sth,
		return DBI::set_err($dbh, -1, 
			"$command statements not supported on table $_.", 'S1000')
			if (($command ne 'SELECT') && 
				($amzn_engine->is_readonly($_)));
	}
    $sth->STORE('f_stmt', $stmt);
    $sth->STORE('f_params', []);
    $sth->STORE('NUM_OF_PARAMS', scalar($stmt->params()));
    $sth->STORE($_, ($attrs && $attrs->{$_}) ? 
    	$attrs->{$_} : $dbh->{$_} ? $dbh->{$_} : $valid_attrs{$_})
    	foreach (keys %valid_attrs);
    $sth->{TraceLevel} = $dbh->{TraceLevel};

	return $sth;
}

sub disconnect {
    my $dbh = shift;

    $dbh->STORE('Active', 0);
    return 1;
}

sub table_info ($) {
	my($dbh) = @_;
	my $sth = $dbh->prepare(
'SELECT TABLE_CAT, 
	TABLE_SCHEM, 
	TABLE_NAME, 
	TABLE_TYPE, 
	REMARKS 
FROM SYSSCHEMA');
	return ($sth && $sth->execute) ? $sth : undef;
}

sub DESTROY {
    my $dbh = shift;

    $dbh->STORE('Active', 0);
}

sub type_info_all ($) {
    [
     {   TYPE_NAME         => 0,
	 DATA_TYPE         => 1,
	 PRECISION         => 2,
	 LITERAL_PREFIX    => 3,
	 LITERAL_SUFFIX    => 4,
	 CREATE_PARAMS     => 5,
	 NULLABLE          => 6,
	 CASE_SENSITIVE    => 7,
	 SEARCHABLE        => 8,
	 UNSIGNED_ATTRIBUTE=> 9,
	 MONEY             => 10,
	 AUTO_INCREMENT    => 11,
	 LOCAL_TYPE_NAME   => 12,
	 MINIMUM_SCALE     => 13,
	 MAXIMUM_SCALE     => 14,
     },
     [ 'VARCHAR', DBI::SQL_VARCHAR(),
       undef, "'","'", undef,0, 1,1,0,0,0,undef,1,999999
       ],
     [ 'CHAR', DBI::SQL_CHAR(),
       undef, "'","'", undef,0, 1,1,0,0,0,undef,1,999999
       ],
     [ 'DECIMAL', DBI::SQL_DECIMAL(),
       31,  "", "", undef,0, 0,1,0,0,0,undef,0,  31
       ],
     [ 'INTEGER', DBI::SQL_INTEGER(),
       undef,  "", "", undef,0, 0,1,0,0,0,undef,0,  0
       ],
     [ 'FLOAT', DBI::SQL_FLOAT(),
       undef,  "", "", undef,0, 0,1,0,0,0,undef,0,  0
       ],
     ]
}

1;

package DBD::Amazon::st;
our $imp_data_size = 0;
@DBD::Amazon::st::ISA = qw(DBD::File::st);
sub execute {
    my $sth = shift;
    my $params;
    if (@_) {
		$sth->{f_params} = ($params = [@_]);
    }
    else {
		$params = $sth->{f_params};
    }

    $sth->finish 
    	if $sth->{Active};

    $sth->{Active} = 1;

	$ENV{DBD_AMZN_DEBUG} = ($sth->{TraceLevel} & 12);

    my $result = $sth->{f_stmt}->execute($sth, $params);
    return $sth->set_err(-1, $sth->{f_stmt}->errstr, 'S1000')
    	unless defined($result);

	$sth->STORE('NUM_OF_FIELDS', $sth->{f_stmt}->{NUM_OF_FIELDS})
    	if ($sth->{f_stmt}->{NUM_OF_FIELDS} && !$sth->FETCH('NUM_OF_FIELDS'));

    return $result;
}

sub DESTROY ($) { undef; }

1;

=pod

=head1 NAME

DBD::Amazon- DBI driver abstraction for the Amazon E-Commerce Services API

=head1 SYNOPSIS

	$dbh = DBI->connect('dbi:Amazon:', $amznid, undef,
		{ amzn_mode => 'books', 
			amzn_locale => 'us',
			amzn_max_pages => 3
		})
	    or die "Cannot connect: " . $DBI::errstr;
	#
	#	search for some Perl DBI books
	#
	$sth = $dbh->prepare("
		SELECT ASIN, 
			Title, 
			Publisher, 
			PublicationDate, 
			Author, 
			SmallImageURL, 
			URL, 
			SalesRank, 
			ListPriceAmt, 
			AverageRating
		FROM Books
		WHERE MATCHES ALL('Perl', 'DBI') AND 
			PublicationDate >= '2000-01-01'
		ORDER BY SalesRank DESC,
			ListPriceAmt ASC, 
			AverageRating DESC");

	$sth->execute or die 'Cannot execute: ' . $sth->errstr;

	print join(', ', @$row), "\n"
		while $row = $sth->fetchrow_arrayref;

	$dbh->disconnect;

=head1 DESCRIPTION

DBD::Amazon provides a DBI and SQL syntax abstraction for the Amazon(R)
E-Commerce Services 4.0 API I<aka> ECS.
L<http://www.amazon.com/gp/>. Using the REST interface, and
a limited SQL dialect, it provides a L<DBI>-friendly interface to ECS.

B<Be advised that this is ALPHA release software> and subject to change at
the whim of the author(s).

=begin html

<h2>Download</h2>
<a href='http://www.presicient.com/dbdamzn/DBD-Amazon-0.10.tar.gz'>
DBD-Amazon-0.10.tar.gz</a><p>

=end html

=head2 Prerequisites

Perl 5.8.0

L<DBI> 1.42 minimum

L<SQL::Statement> 1.14

L<SQL::Amazon> 0.10 (included in this bundle)

L<Clone> 0.15

=head2 Testing Considerations

To run the test package, you'll need

=over 4

=item An Amazon ECS User ID

An environment variable DBD_AMZN_USER must be set to an
Amazon ECS user ID in order to connect and execute ECS  requests.
Registration at the Amazon Web Services site is required to acquire a user ID.

=item An Internet Connection

Obviously.

=item Patience

Some of these tests download large amounts of Amazon catalog
data, which can take some time (esp. since a minimum 1 second
delay between requests is required).

=back

Also, be prepared for possible intermittent 'Internal Error' reports; these
are problems within the Amazon ECS system, B<not> failures in 
DBD::Amazon itself.

=head2 Installation

For Unix:

I<gunzip/untar as usual, then>

    cd DBD-Amazon-0.10
    perl Makefile.PL
    make
	make test
    make install

Note that you probably need root or administrator permissions
to install. Refer to L<ExtUtils::MakeMaker> for details
on installing in your own local directories.

For Windows:

I<Unzip with your favorite utility, e.g., WinZIP, then>

    cd DBD-Amazon-0.10
    perl Makefile.PL
    nmake
	nmake test
    nmake install

=head2 SQL Dialect

DBD::Amazon supports a subset of standard SQL, and additional
predicate functions for keyword searches. Review L<SQL::Amazon::Parser>
and L<SQL::Statement> for syntax details.

Use C<table_info()> to retrieve the metadata for any of the defined
tables/views.

Currently, only the following tables are defined:

=over 4

=item B<Books> 

=item B<Offers> 

=item B<CustomerReviews> 

=item B<EditorialReviews> 

=item B<BrowseNodes> 

=item B<ListManiaLists> 

=item B<Merchants> 

=item B<SimilarProducts> 

=item B<SysSchema> 

=back

=head2 Driver-specific Attributes

=over 4

=item amzn_locale I<(Connection attribute)>

Sets the Amazon locale to use (i.e., the root ECS request URL).
Valid values are 'us', 'uk', 'de', 'fr', 'jp', 'ca' I<(Currently,
only us is supported)>. Default is 'us'.

=item amzn_affiliate_id I<(Connection attribute)>

An Amazon affiliate ID. Default none.

=item amzn_strict I<(Connection attribute)>

=item amzn_rate_limit I<(Connection attribute)>

Minimum number of seconds allowed between requests. Default 1.
May be fractional.

=item amzn_max_pages I<(Connection and statement attribute)>

Maximum number of pages to return for each request. Default 20.

=item amzn_resp_group I<(Connection and statement attribute)>

ECS Response Group to use; can be any of 'Small', 'Medium', or 'Large';
default is 'Large'.

=back

=head1 ACKNOWLEDGEMENTS

Many thanks to Jeff Zucker for his guidance/patience, and adding
some nice new features to SQL::Statement to help make DBD::Amazon
a reality.

=head1 FOR MORE INFO

L<http://www.presicient.com/dbdamzn>

=head1 AUTHOR AND COPYRIGHT

Copyright (C) 2005 by Presicient Corporation, USA

L<darnold@presicient.com>

L<http://www.presicient.com>

Permission is granted to use this software according to the terms of the
Artistic License, as specified in the Perl README file,
with the exception that commercial redistribution, either 
electronic or via physical media, as either a standalone package, 
or incorporated into a third party product, requires prior 
written approval of the author.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Presicient Corp. reserves the right to provide support for this software
to individual sites under a separate (possibly fee-based)
agreement.

=head1 SEE ALSO

For help on the use of DBI, see the DBI users mailing list:

L<dbi-users-subscribe@perl.org>

For general information on DBI see

L<http://dbi.perl.org>
  
For information about the Amazon API, see

L<http://www.amazon.com/gp/browse.html/102-3140335-1462533?%5Fencoding=UTF8&node=3435361>

=cut

