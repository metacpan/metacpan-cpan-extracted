#!/usr/bin/perl

use strict;
use warnings;

# perl5.27.2 -DD -Mblib t/02_free_unref_scalar.t > & alloc-free.log
#            ^^^
# -DD  Cleaning up

#use Devel::Peek;
#use Data::Peek;
use Test::More;
#use Test::NoWarnings;

$] < 5.026 and plan skip_all => "This is a perl5 CORE issue fixed in perl-5.26";

use_ok "DBI";
require "./t/lib.pl";

$SIG{__WARN__} = sub {
    $_[0] =~ m/^Attempt to free unreferenced scalar: SV (0x[0-9a-f]+)(, \<\w+\> line \d+)?.* during global destruction\.$/ and
	fail ("there was an attempt to free unreferenced scalar");
    diag "@_";
    };

sub DBD::CSV::Table::DESTROY {
    my $self = shift;

    delete $self->{meta}{csv_in};
    } # DBD::CSV::Table::DESTROY

sub test_with_options {
    my (%opts) = @_;
    my $dbh = DBI->connect ("dbi:CSV:", undef, undef, {
	f_schema         => undef,
	f_dir            => 't',
	f_dir_search     => [],
	f_ext            => ".csv/r",
	f_lock           => 2,
	f_encoding       => "utf8",

	%opts,

	RaiseError       => 1,
	PrintError       => 1,
	FetchHashKeyName => "NAME_lc",
	}) or die "$DBI::errstr\n" || $DBI::errstr;

    my %tbl = map { $_ => 1 } $dbh->tables (undef, undef, undef, undef);

    is ($tbl{$_}, 1, "Table $_ found") for qw( tmp );

    my %data = (
	tmp => {		# t/tmp.csv
	    1 => "ape",
	    2 => (grep (m/^csv_callbacks$/ => keys %opts) ? "new world monkey" : "monkey"),
	    3 => "gorilla",
	    },
	);

    foreach my $tbl (sort keys %data) {
	my $sth = $dbh->prepare ("select * from $tbl");
	$sth->execute;
	while (my $row = $sth->fetch) {
	    is ($row->[1], $data{$tbl}{$row->[0]}, "$tbl ($row->[0], ...)");
	    }
	$sth->finish ();
	}

    $dbh->disconnect;
    }

sub new_world_monkeys {
    my ($csv, $data) = @_;

    $data->[1] =~ s/^monkey$/new world monkey/;

    return;
    }

my $callbacks = {
    csv_callbacks => {
	after_parse => \&new_world_monkeys,
	},
    };

test_with_options (
    csv_tables => { tmp => { f_file => "tmp.csv"} },
    %$callbacks,
    );

test_with_options (
    csv_auto_diag => 0,
    %$callbacks,
    ) for (1 .. 100);

done_testing ();
