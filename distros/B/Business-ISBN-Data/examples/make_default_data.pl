#!/usr/bin/perl
use v5.10;
use open qw(:std :utf8);

use lib qw(lib);
use Business::ISBN::Data;

my $file = $ARGV[0];

=encoding utf8

=head1 NAME

make_default_data.pl

=head1 SYNOPSIS

	% curl https://www.isbn-international.org/?q=download_range/15821 > RangeMessage.xml
	% perl make_default_data.pl RangeMessage.xml

	# cut and paste result into lib/Business/ISBN/Data.pm

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

	https://github.com/briandfoy/business-isbn-data.git

You are probably also interested in the module that uses it:

	https://github.com/briandfoy/business-isbn.git

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

Copyright © 2002-2021, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut


do { warn "Usage: $0 RangeMessage.xml\n"; exit(2)  } unless defined $file;
do { warn "File <$file> does not exist\n"; exit(2) } unless -e $file;

my $data = Business::ISBN::Data::_parse_range_message( $file );

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


say $string;


__END__

		     _date => Tue, 12 Jan 2021 10:43:54 GMT,
		   _serial => 0c5e7d67-d086-48c1-80f9-55319988b0c0,
		   _source => lib/Business/ISBN/RangeMessage.xml,
	(

