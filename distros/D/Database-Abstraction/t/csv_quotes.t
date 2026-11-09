#!perl -w

# A quote inside a quoted field.  RFC 4180, and every spreadsheet, writes it
# as two quotes ("Adeste ""Overture"""); some files write it with a backslash
# ("Joe\"s Bar").  Each file is read by the escape it was written with, on the
# slurp path and the DBI path alike.

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Test::Most;

{
	package Database::quotes;
	use parent -norequire, 'Database::Abstraction';
}
require Database::Abstraction;

sub titles {
	my ($content, %args) = @_;
	my $dir = tempdir(CLEANUP => 1);
	open(my $fh, '>', File::Spec->catfile($dir, 'quotes.csv')) or die $!;
	print $fh $content;
	close $fh;
	my $db = Database::quotes->new(directory => $dir, no_entry => 1, sep_char => ',', %args);
	return [ map { $_->{title} } $db->selectall_array() ];
}

for my $path ([ slurp => () ], [ DBI => (max_slurp_size => 0) ]) {
	my ($name, @args) = @{$path};
	subtest "$name path" => sub {
		is_deeply(titles(qq{id,title\n1,"Adeste Fidelis ""Overture"""\n2,Plain\n}, @args),
			[ 'Adeste Fidelis "Overture"', 'Plain' ], 'doubled quotes are one quote');
		is_deeply(titles(qq{id,title\n1,"Joe\\"s Bar"\n2,Plain\n}, @args),
			[ 'Joe"s Bar', 'Plain' ], 'a backslash escape still reads');
		is_deeply(titles(qq{id,title\n1,"Joe\\"s Bar"\n2,""\n3,Plain\n}, @args),
			[ 'Joe"s Bar', undef, 'Plain' ], 'an empty quoted field does not change the escape');
		is_deeply(titles(qq{id,title\n1,"a, b"\n2,Plain\n}, @args),
			[ 'a, b', 'Plain' ], 'no quote inside a field: as before');
	};
}

subtest '_csv_escape_char' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, 'x.csv');
	my $db = bless {}, 'Database::Abstraction';
	for my $case ([ qq{a,"b ""c"""\n}, '"' ], [ qq{a,"b \\"c\\""\n}, '\\' ], [ qq{a,"b"\n}, '\\' ],
		[ qq{a,"x ""y"""\nb,"p \\"q\\""\n}, '\\' ], [ qq{a,""\n}, '"' ]) {
		open(my $fh, '>', $file) or die $!;
		print $fh $case->[0];
		close $fh;
		is($db->_csv_escape_char($file), $case->[1], "escape for $case->[0]");
	}
	is($db->_csv_escape_char(File::Spec->catfile($dir, 'missing.csv')), '\\', 'a file that will not open: backslash');
};

done_testing();
