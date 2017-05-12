package Business::Cart::Generic::Database::Import;

use strict;
use warnings;

use CGI;

use FindBin;

use Business::Cart::Generic::Database;

use IO::File;

use Moose;

use Perl6::Slurp;

use Text::CSV_XS;
use Text::Xslate;

use Try::Tiny;

use WWW::Scraper::Wikipedia::ISO3166::Database;

extends 'Business::Cart::Generic::Database::Base';

has country_map =>
(
	default  => sub{return build_country_map()},
	is       => 'rw',
	isa      => 'HashRef',
	required => 0,
);

use namespace::autoclean;

our $VERSION = '0.85';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	$self -> db
		(
		 Business::Cart::Generic::Database -> new
		 (
		  online => 0,
		  query  => CGI -> new,
		 )
		);

}	# End of BUILD.

# -----------------------------------------------
# Warning: This is a function. Hence no $self.

sub build_country_map
{
	my($country) = WWW::Scraper::Wikipedia::ISO3166::Database -> new -> read_countries_table;

	my(%code2country);

	for my $id (keys %$country)
	{
		$code2country{$$country{$id}{code2} } = {%{$$country{$id} } };
	}

	return \%code2country;

} # End of build_country_map.

# -----------------------------------------------

sub clean_all_data
{
	my($self) = @_;

	$self -> clean_currency_data;
	$self -> clean_language_data;
	$self -> clean_order_statuses_data;

} # End of clean_all_data.

# -----------------------------------------------

sub clean_currency_data
{
	my($self)          = @_;
	my($input_path)    = "$FindBin::Bin/../data/raw.currencies.txt";
	my(@original_data) = slurp($input_path, {chomp => 1});

	my(@field);
	my($line);
	my(@raw_data);

	push @raw_data, '"name","code","symbol_left","symbol_right","decimal_places"';

	for $line (@original_data)
	{
		# Expected format:
		# INSERT INTO osc_currencies VALUES (4,'Australian Dollar','AUD','$','','2','1.000', now());

		$line     = substr($line, 0, - 2); # Discard );.
		@field    = split(/VALUES \(/, $line);
		$field[1] =~ tr/'/"/;   # For Text::CSV_XS.
		@field    = split(/\s*,\s*/, $field[1]);

		push @raw_data, join(',', @field[1 .. 5]);
	}

	my($output_path) = "$FindBin::Bin/../data/currencies.csv";

	open(OUT, '>', $output_path) || die "Can't open($output_path): $!";

	my($csv) = Text::CSV_XS -> new({allow_whitespace => 1, binary => 1});

	my($status);
	my(%target);

	while ($line = shift @raw_data)
	{
		$status = $csv -> parse($line) || die "Can't parse $line";
		@field  = $csv -> fields;

		print OUT '"', join('","', @field), qq|"\n|;
	}

	close OUT;

} # End of clean_currency_data.

# -----------------------------------------------

sub clean_language_data
{
	my($self)          = @_;
	my($input_path)    = "$FindBin::Bin/../data/raw.languages.txt";
	my(@original_data) = slurp($input_path, {chomp => 1});

	my(@field);
	my($line);
	my(@raw_data);

	push @raw_data, '"name","code","locale","charset","date_format_short","date_format_long","time_format","text_direction","currency_id","numeric_separator_decimal","numeric_separator_thousands"';

	for $line (@original_data)
	{
		# Expected format:
		# INSERT INTO osc_languages VALUES (2,'English','en_AU','en_AU.UTF-8,en_AU,english','utf-8','%d/%m/%Y','%A %d %B, %Y','%H:%M:%S','ltr',1,'.',',',0,1);

		$line  = substr($line, 0, - 2); # Discard );.
		@field = split(/VALUES \(/, $line);
		$field[1]  =~ s/,(en_(?:AU|US)),/#$1#/; # locale.
		$field[1]  =~ s/B,/B#/;                 # date_format_long.
		$field[1]  =~ s/'.',',',/'.','#',/;     # numeric_separator_thousands.
		$field[1]  =~ tr/'/"/;   # For Text::CSV_XS.
		@field     = split(/\s*,\s*/, $field[1]);
		$field[3]  =~ s/#/,/g; # locale.
		$field[6]  =~ s/#/,/;  # date_format_long.
		$field[11] =~ s/#/,/;  # numeric_separator_thousands.

		push @raw_data, join(',', @field[1 .. 11]);
	}

	my($output_path) = "$FindBin::Bin/../data/languages.csv";

	open(OUT, '>', $output_path) || die "Can't open($output_path): $!";

	my($csv) = Text::CSV_XS -> new({allow_whitespace => 1});

	my($status);
	my(%target);

	while ($line = shift @raw_data)
	{
		$status = $csv -> parse($line) || die "Can't parse $line";
		@field  = $csv -> fields;

		print OUT '"', join('","', @field), qq|"\n|;
	}

	close OUT;

} # End of clean_language_data.

# -----------------------------------------------

sub clean_order_statuses_data
{
	my($self)          = @_;
	my($input_path)    = "$FindBin::Bin/../data/raw.order.statuses.txt";
	my(@original_data) = slurp($input_path, {chomp => 1});

	my(@field);
	my($line);
	my(@raw_data);

	push @raw_data, '"language_id","name"';

	for $line (@original_data)
	{
		# Expected format:
		# INSERT INTO osc_orders_status VALUES ( '1', '4', 'Pending');

		$line     = substr($line, 0, - 2); # Discard );.
		@field    = split(/VALUES \(/, $line);
		$field[1] =~ tr/'/"/;   # For Text::CSV_XS.
		@field    = split(/\s*,\s*/, $field[1]);

		push @raw_data, join(',', @field[1 .. 2]);
	}

	my($output_path) = "$FindBin::Bin/../data/order.statuses.csv";

	open(OUT, '>', $output_path) || die "Can't open($output_path): $!";

	my($csv) = Text::CSV_XS -> new({allow_whitespace => 1});

	my($status);
	my(%target);

	while ($line = shift @raw_data)
	{
		$status = $csv -> parse($line) || die "Can't parse $line";
		@field  = $csv -> fields;

		print OUT '"', join('","', @field), qq|"\n|;
	}

	close OUT;

} # End of clean_order_statuses_data.

# -----------------------------------------------

sub populate_all_tables
{
	my($self) = @_;

	$self -> connector -> txn
		(
		 fixup => sub{ $self -> populate_tables }, catch{ defined $_ ? die $_ : ''}
		);

}	# End of populate_all_tables.

# -----------------------------------------------

sub populate_tables
{
	my($self) = @_;

	$self -> populate_countries_table;
	$self -> populate_zones_table;
	$self -> populate_currencies_table;
	$self -> populate_languages_table;
	$self -> populate_order_statuses_table;
	$self -> populate_tax_classes_table;
	$self -> populate_weight_classes_table;
	$self -> populate_weight_class_rules_table;
	$self -> populate_table('yes.no.csv', 'YesNo');
	$self -> populate_table('payment.methods.csv', 'PaymentMethod');
	$self -> populate_table('customer.statuses.csv', 'CustomerStatuse');
	$self -> populate_table('customer.types.csv', 'CustomerType');
	$self -> populate_table('genders.csv', 'Gender');
	$self -> populate_table('email.address.types.csv', 'EmailAddressType');
	$self -> populate_table('phone.number.types.csv', 'PhoneNumberType');
	$self -> populate_table('titles.csv', 'Title');

}	# End of populate_tables.

# -----------------------------------------------

sub populate_countries_table
{
	my($self)        = @_;
	my($rs)          = $self -> schema -> resultset('Country');
	my($country_map) = $self -> country_map;

	my($result);

	for my $code (sort keys %$country_map)
	{
		$result = $rs -> create
			({
			 code       => $code,
			 name       => $$country_map{$code}{name},
			 upper_name => uc $$country_map{$code}{name},
			});
	}

} # End of populate_countries_table.

# -----------------------------------------------

sub populate_currencies_table
{
	my($self) = @_;
	my($path) = "$FindBin::Bin/../data/currencies.csv";
	my($zone) = $self -> read_csv_file($path);
	my($rs)   = $self -> schema -> resultset('Currency');

	my($result);

	for my $line (@$zone)
	{
		$result = $rs -> create
			({
			 code           => $$line{code},
			 decimal_places => $$line{decimal_places},
			 name           => $$line{name},
			 symbol_left    => $$line{symbol_left},
			 symbol_right   => $$line{symbol_right},
			 upper_name     => uc $$line{name},
			});
	}

} # End of populate_currencies_table.

# -----------------------------------------------

sub populate_languages_table
{
	my($self) = @_;
	my($path) = "$FindBin::Bin/../data/languages.csv";
	my($zone) = $self -> read_csv_file($path);
	my($rs)   = $self -> schema -> resultset('Language');

	my($result);

	for my $line (@$zone)
	{
		$result = $rs -> create
			({
			 charset                     => $$line{charset},
			 code                        => $$line{code},
			 currency_id                 => $$line{currency_id},
			 date_format_long            => $$line{date_format_long},
			 date_format_short           => $$line{date_format_long},
			 locale                      => $$line{locale},
			 name                        => $$line{name},
			 numeric_separator_decimal   => $$line{numeric_separator_decimal},
			 numeric_separator_thousands => $$line{numeric_separator_thousands},
			 text_direction              => $$line{text_direction},
			 time_format                 => $$line{time_format},
			 upper_name                  => uc $$line{name},
			});
	}

} # End of populate_languages_table.

# -----------------------------------------------

sub populate_order_statuses_table
{
	my($self)        = @_;
	my($path)        = "$FindBin::Bin/../data/order.statuses.csv";
	my($zone)        = $self -> read_csv_file($path);
	my($rs)          = $self -> schema -> resultset('OrderStatuse');
	my(@language2id) = $self -> schema -> resultset('Language') -> search({}, {columns => [qw/code id/]});
	my(%language2id) = map{($_ -> code, $_ -> id)} @language2id;

	my($language_id);
	my($result);

	for my $line (@$zone)
	{
		$language_id = $language2id{$$line{language} } || die "Unknown language: $$line{language}";
		$result      = $rs -> create
			({
			 language_id => $language_id,
			 name        => $$line{name},
			 upper_name  => uc $$line{name},
			});
	}

} # End of populate_order_statuses_table.

# -----------------------------------------------

sub populate_table
{
	my($self, $file_name, $class_name) = @_;
	my($path) = "$FindBin::Bin/../data/$file_name";
	my($data) = $self -> read_csv_file($path);
	my($rs)   = $self -> schema -> resultset($class_name);

	my($result);

	for my $line (@$data)
	{
		$result = $rs -> create
			({
			 name       => $$line{name},
			 upper_name => uc $$line{name},
			});
	}

} # End of populate_table.

# -----------------------------------------------

sub populate_tax_classes_table
{
	my($self) = @_;
	my($path) = "$FindBin::Bin/../data/tax.classes.csv";
	my($data) = $self -> read_csv_file($path);
	my($rs)   = $self -> schema -> resultset('TaxClass');

	my($result);

	for my $line (@$data)
	{
		$result = $rs -> create
			(
			 {
				 date_added    => \'now()',
				 date_modified => \'now()',
				 description   => $$line{description},
				 name          => $$line{name},
				 upper_name    => uc $$line{name},
			 }
			);
	}

} # End of populate_tax_classes_table.

# -----------------------------------------------

sub populate_weight_class_rules_table
{
	my($self)     = @_;
	my($path)     = "$FindBin::Bin/../data/weight.class.rules.csv";
	my($data)     = $self -> read_csv_file($path);
	my($rs)       = $self -> schema -> resultset('WeightClassRule');
	my(@class2id) = $self -> schema -> resultset('WeightClass') -> search({}, {columns => [qw/key id/]});
	my(%class2id) = map{($_ -> key, $_ -> id)} @class2id;

	my($from_id);
	my($result);
	my($to_id);

	for my $line (@$data)
	{
		$from_id = $class2id{$$line{from} } || die "Unknown weight class: $$line{from}";
		$to_id   = $class2id{$$line{to} }   || die "Unknown weight class: $$line{to}";
		$result  = $rs -> create
			(
			 {
				 from_id => $from_id,
				 to_id   => $to_id,
				 rule    => $$line{rule},
			 }
			);
	}

} # End of populate_weight_class_rules_table.

# -----------------------------------------------

sub populate_weight_classes_table
{
	my($self)        = @_;
	my($path)        = "$FindBin::Bin/../data/weight.classes.csv";
	my($data)        = $self -> read_csv_file($path);
	my($rs)          = $self -> schema -> resultset('WeightClass');
	my(@language2id) = $self -> schema -> resultset('Language') -> search({}, {columns => [qw/code id/]});
	my(%language2id) = map{($_ -> code, $_ -> id)} @language2id;

	my($language_id);
	my($result);

	for my $line (@$data)
	{
		$language_id = $language2id{$$line{language} } || die "Unknown language: $$line{language}";
		$result      = $rs -> create
			(
			 {
				 language_id => $language_id,
				 key         => $$line{key},
				 name        => $$line{name},
				 upper_name  => uc $$line{name},
			 }
			);
	}

} # End of populate_weight_classes_table.

# -----------------------------------------------

sub populate_zones_table
{
	my($self)         = @_;
	my($rs)           = $self -> schema -> resultset('Zone');
	my($country_map)  = $self -> country_map;
	my($subcountries) = WWW::Scraper::Wikipedia::ISO3166::Database -> new -> read_subcountries_table;

	my($result);
	my(@zones);

	for my $code (keys %$country_map)
	{
		if ($$country_map{$code}{has_subcountries})
		{
			# Move subcountries into @zones for ease of sorting.

			@zones = ();

			for my $id (keys %$subcountries)
			{
				next if ($$subcountries{$id}{country_id} != $$country_map{$code}{id});

				push @zones, {%{$$subcountries{$id} } };
			}

			for my $zone (sort{$$a{sequence} <=> $$b{sequence} } @zones)
			{
				$result = $rs -> create
					({
						code       => $code,
						country_id => $$country_map{$code}{id},
						name       => $$zone{name},
						upper_name => uc $$zone{name},
					 });
			}

			# Zap used-up subcountries so %$subcountries shrinks and hence speeds up.

			delete $$subcountries{$_} for map{$$_{id} } @zones;
		}
		else
		{
			$result = $rs -> create
				({
					code       => '-',
					country_id => $$country_map{$code}{id},
					name       => 'No zones',
					upper_name => uc 'No zones',
				 });
		}
	}

} # End of populate_zones_table.

# -----------------------------------------------

sub read_csv_file
{
	my($self, $file_name) = @_;
	my($csv) = Text::CSV_XS -> new({binary => 1});
	my($io)  = IO::File -> new($file_name, 'r');

	$csv -> column_names($csv -> getline($io) );

	return $csv -> getline_hr_all($io);

} # End of read_csv_file.

# -----------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

=pod

=head1 NAME

L<Business::Cart::Generic::Database::Import> - Basic shopping cart

=head1 Synopsis

See L<Business::Cart::Generic>.

=head1 Description

L<Business::Cart::Generic> implements parts of osCommerce and PrestaShop in Perl.

=head1 Installation

See L<Business::Cart::Generic>.

=head1 Constructor and Initialization

=head2 Parentage

This class extends L<Business::Cart::Generic::Database::Base>.

=head2 Using new()

See scripts/clean.all.data.pl and scripts/populate.tables.pl.

=head1 Methods

=head2 clean_all_data()

Wrapper which calls the next 4 methods.

Returns nothing.

=head2 clean_currency_data()

Reformats the osCommerce data for the currencies table.

Reads data/raw.currencies.txt and writes data/currencies.csv.

=head2 clean_language_data()

Reformats the osCommerce data for the languages table.

Reads data/raw.languages.txt and writes data/languages.csv.

=head2 clean_order_statuses_data()

Reformats the osCommerce data for the order_statuses table.

Reads data/raw.order.statuses.txt and writes data/order.statuses.csv.

Since then I've manually added 'Checked out' to that table.

=head2 populate_all_tables()

Runs a db transaction to populate all tables.

Calls populate_tables().

Returns nothing.

=head2 populate_tables()

A helper for populate_all_tables(). Never called directly.

Calls the next 9 methods.

=head2 populate_countries_table()

=head2 populate_zones_table()

=head2 populate_currencies_table()

=head2 populate_languages_table()

=head2 populate_order_statuses_table()

=head2 populate_table($csv_file_name, $class_name)

Read the CSV file and use the given L<DBIx::Class> class to populate these tables:

=over 4

=item o customer_statuses

=item o customer_types

=item o email_address_types

=item o genders

=item o payment_methods

=item o phone_number_types

=item o titles

=item o yes_no

=back

=head2 populate_tax_classes_table()

=head2 populate_weight_classes_table()

=head2 populate_weight_class_rules_table()

=head2 read_csv_file($file_name)

Uses Text::CSV_XS the read the given file. There I<must> be a header record in the file, listing the column names.

=head1 Machine-Readable Change Log

The file CHANGES was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Thanks

Many thanks are due to the people who chose to make osCommerce and PrestaShop, Zen Cart, etc, Open Source.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Business::Cart::Generic>.

=head1 Author

L<Business::Cart::Generic> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2011.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2011, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
