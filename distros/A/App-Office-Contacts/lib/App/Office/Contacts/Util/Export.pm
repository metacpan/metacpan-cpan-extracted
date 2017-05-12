package App::Office::Contacts::Util::Export;

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use App::Office::Contacts::Database;
use App::Office::Contacts::Util::Logger;

use CGI;

use Encode; # For decode().

use Moo;

use Text::CSV::Encoded;
use Text::Xslate 'mark_raw';

use Types::Standard qw/Any Bool Str/;

extends 'App::Office::Contacts::Database::Base';

has logger =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Any, # 'App::Office::Contacts::Util::Logger',
	required => 0,
);

has output_file =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 1,
);

has standalone_page =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Bool,
	required => 0,
);

our $VERSION = '2.04';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	# Fix value if undef is passed in.
	# This happens with Getopt::Long when the option /name/ is not provided on the command line.

	$self -> standalone_page($self -> standalone_page || 0);
	$self -> logger(App::Office::Contacts::Util::Logger -> new);
	$self -> db
	(
		App::Office::Contacts::Database -> new
		(
			logger        => $self -> logger,
			module_config => $self -> logger -> module_config,
			query         => CGI -> new,
		)
	);

}	# End of BUILD.

# -----------------------------------------------

sub as_csv
{
	my($self) = @_;

	die "No output file specified\n" if (! $self -> output_file);

	my($csv)  = Text::CSV::Encoded -> new
	({
		always_quote => 1,
		encoding_out => 'utf-8',
	});
	my($output_file) = $self -> output_file;

	open(my $out, '>', $output_file) || die "Can't open(> $output_file): $!";

	$csv -> print($out, ['Name', 'Upper name']);

	for my $item (@{$self -> read_people_table})
	{
		$csv -> print($out,
		[
			$$item{name},
			$$item{upper_name},
		]);
	}

	close($out);

	print "Wrote $output_file. \n";

	# Return 0 for success and 1 for failure.

	return 0;

}	# End of as_csv.

# -----------------------------------------------

sub as_html
{
	my($self) = @_;
	my($count) = 0;

	$self -> logger -> log(info => 'Generating HTML table. standalone_page: ' . $self -> standalone_page);

	my(@row);

	push @row,
	[
	{td => '#'},
	{td => 'Name'},
	{td => 'Upper name'},
	];

	for my $item (@{$self -> read_people_table})
	{
		push @row,
		[
		{td => ++$count},
		{td => $$item{name} },
		{td => $$item{upper_name} },
		];
	}

	push @row,
	[
	{td => '#'},
	{td => 'Name'},
	{td => 'Upper name'},
	];

	my($tx) = Text::Xslate -> new
	(
		input_layer => '',
		path        => ${$self -> logger -> module_config}{template_path},
	);

	return $tx -> render
	(
		$self -> standalone_page ? 'standalone.page.tx' : 'basic.table.tx',
		{
			row     => \@row,
			summary => 'A list of people',
		}
	);

} # End of as_html.

# -----------------------------------------------

sub read_people_table
{
	my($self)   = @_;
	my(@people) = $self -> db -> simple -> query('select name, upper_name from people order by name') -> hashes;

	my(@person);

	for my $person (@people)
	{
		push @person,
		{
			name       => decode('utf-8', $$person{name}),
			upper_name => decode('utf-8', $$person{upper_name}),
		};
	}

	return [sort{$$a{name} cmp $$b{name} } @person];

} # End of read_people_table.

# -----------------------------------------------

1;

=head1 NAME

App::Office::Contacts::Util::Export - A web-based contacts manager

=head1 Synopsis

See L<App::Office::Contacts/Synopsis>.

=head1 Description

L<App::Office::Contacts> implements a utf8-aware, web-based, private and group contacts manager.

=head1 Distributions

See L<App::Office::Contacts/Distributions>.

=head1 Installation

See L<App::Office::Contacts/Installation>.

=head1 Object attributes

Extends both L<App::Office::Contacts::Util::Logger> and L<App::Office::Contacts::Database::Base>, and
has these attributes:

=over 4

=item o whole_page

Is a Boolean.

Specifies whether or not as_html() outputs a web page or just a HTML table.

Default: 0.

=back

Further, each attribute name is also a method name.

=head1 Methods

=head2 as_csv()

Prints 2 columns (name, upper_name) of the I<people> table, in CSV format.

=head2 as_html()

Not implemented.

=head2 read_people_table()

Reads 2 columns (name, upper_name) from the I<people> table.

=head2 whole_page()

Returns a Boolean, which specifies whether or not as_html() outputs a web page or just a HTML table.

=head1 FAQ

See L<App::Office::Contacts/FAQ>.

=head1 Support

See L<App::Office::Contacts/Support>.

=head1 Author

C<App::Office::Contacts> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2013.

L<Home page|http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2013, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License V 2, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
