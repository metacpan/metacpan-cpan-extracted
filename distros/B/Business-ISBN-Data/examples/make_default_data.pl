#!/usr/bin/perl
use v5.10;
use open qw(:std :utf8);

use lib qw(lib);
use Business::ISBN::Data;

my $file = $ARGV[0] // 'lib/Business/ISBN/RangeMessage.xml';

=encoding utf8

=head1 NAME

make_default_data.pl - digest the latest RangeMessage.xml into default data in the module

=head1 SYNOPSIS

	% curl https://www.isbn-international.org/export_rangemessage.xml > RangeMessage.xml
	% perl examples/make_default_data.pl RangeMessage.xml

Without an argument, it assumes the file is lib/Business/ISBN/RangeMessage.xml

	% curl https://www.isbn-international.org/export_rangemessage.xml > lib/Business/ISBN/RangeMessage.xml
	% perl examples/make_default_data.pl

=head1 DESCRIPTION

This program takes the F<RangeMessage.xml> and makes the data
structure to hard-code into L<Business::ISBN::Data>.

The module ships with the F<RangeMessage.xml> that was current as of
the release of the module, but it also hard-codes the same data. That
way, the module has the data even if the XML file disappears. The
module can also use any F<RangeMessage.xml> you specify, which allows
you to use updated (or even past) data. The hard-coded data always
gets you back to that for the release.

=head1 SOURCE AVAILABILITY

This module lives in a Github repository:

	https://github.com/briandfoy/business-isbn-data

You are probably also interested in the module that uses it:

	https://github.com/briandfoy/business-isbn

If you have something to add, create a fork on Github and send a
pull request.

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

Yakov Shafranovich updated the data in October 2008.

Daniel Jakubik updated the data in July 2012.

Markus Spann suggested looking for F<RangeMessage.xml> in the current
directory to make it work with Perl app bundlers.

Josef Moravec C<< <josef.moravec@gmail.com> >> updated the data in January 2019.

Peter Williams fixed a serious issue with ISBN-13 (GitHub #5)

=head1 COPYRIGHT AND LICENSE

Copyright © 2002-2023, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut


do { warn "Usage: $0 RangeMessage.xml\n"; exit(2)  } unless defined $file;
do { warn "File <$file> does not exist\n"; exit(2) } unless -e $file;

my $data = Business::ISBN::Data::_parse_range_message( $file );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#
# Thu, 16 Mar 2023 20:59:31 GMT
say "DATE: $data->{_date}";
my( $day, $mon, $year ) = $data->{_date} =~ m/
	# Thu, 16 Mar 2023 20:59:31 GMT
	\A
	\S+?
	, \s+
	(?<day>  \d+    ) \s
	(?<mon>  [a-z]+ ) \s
	(?<year> \d+    )
	/ix;
my %months = map  { state $n = 1; $_ => $n++ }
	qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my( $year, $day ) = @+{qw(year day)};
my( $month ) = $months{ $+{mon} };

my $new_version_date = sprintf '%4d%02d%02d', $year, $month, $day;
my $current_date = Business::ISBN::Data->VERSION;
my( $major, $minor ) = split /\./, $current_date;

my $new_minor = do {
	if( $new_version_date > $major ) { 1 }
	elsif( $new_version_date == $major ) { $minor + 1 }
	else {
		die "New date ($new_version_date) is older than current version ($current_date)\n";
		}
	};

my $new_version = sprintf '%s.%03d', $new_version_date, $new_minor;
say "CURRENT VERSION: $current_date NEW VERSION: $new_version";

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#
my $string = "\t(\n";

foreach my $key ( sort grep /^_/, keys %$data ) {
	my $value = "'$data->{$key}'";
	$value = '__FILE__' if $key eq '_source';
	$key   = '_data_date' if $key eq '_date';
	$string .= sprintf "\t%-10s => %s,\n", $key, $value;
	}

$string .= "\t978 => \{\n%%978%%\n\t\},\n\t979 => \{\n%%979%%\n\t\},\n\t);";

foreach my $k ( qw(978 979) ) {
	my $s = "\t\t" . join "\n\t\t",
		map {
			my $group = $data->{$k}{$_}[0];
			$group =~ s/'/\\'/g;

			my $numbers = join ", ", map { qq('$_') } $data->{$k}{$_}[1]->@*;

			my $s = sprintf q(%-5s => [ %-30s => [ %s ] ],), $_, qq('$group'), $numbers;
			$s;
			}
		sort { $a <=> $b }
		keys $data->{$k}->%*;

	$string =~ s/%%$k%%/$s/;
	}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#
my $PM_FILE = 'lib/Business/ISBN/Data.pm';
my $TEMP_FILE = 'lib/Business/ISBN/Data.pm.tmp';

open my $in_fh, '<:encoding(UTF-8)', $PM_FILE
	or die "Could not open $PM_FILE: $!\n";
open my $out_fh, '>:encoding(UTF-8)', $TEMP_FILE
	or die "Could not open $TEMP_FILE: $!\n";

while(<$in_fh>) {
	state $in_replace = 0;
	if( s/\$VERSION = \K'\d+\.\d+'/'$new_version'/ ) {
		print {$out_fh} $_;
		next;
		}
	elsif( /\A# BEGIN REPLACE/ ) {
		$in_replace = 1;
		print {$out_fh} $_;
		next;
		}
	elsif( /\A# END REPLACE/ ) {
		$in_replace = 0;
		$string =~ s/\s*\z/\n/;
		print {$out_fh} $string;
		print {$out_fh} $_;
		next;
		}
	elsif( $in_replace ) {
		next;
		}
	elsif( ! $in_replace ) {
		print {$out_fh} $_;
		next;
		}
	}

close($in_fh);
close($out_fh);

rename $TEMP_FILE => $PM_FILE or die "Could not replace $PM_FILE: $!\n";
