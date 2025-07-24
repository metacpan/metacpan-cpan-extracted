package CPAN::MetaCurator::Util::Import;

use 5.40.0;
use parent 'CPAN::MetaCurator::Util::Database';
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper::Concise; # For Dumper().
use DateTime::Tiny;

use File::Spec;
use File::Slurper 'read_text';

use Moo;
use Mojo::JSON 'from_json';

use Text::CSV::Encoded;
use Types::Standard qw/Str/;

our $VERSION = '1.00';

# -----------------------------------------------

sub populate_all_tables
{
	my($self) = @_;

	$self -> init_config;
	$self -> init_db;
	$self -> logger -> info('Populating all tables');

	my($path)	= File::Spec -> catfile($self -> home_path, $self -> constants_path);
	my($csv)	= Text::CSV::Encoded -> new
	({
		allow_whitespace	=> 1,
		encoding_in			=> 'utf-8',
		strict				=> 1,
	});

	$self -> populate_constants_table($csv, $path);
	$self -> populate_topics_table;

	$self -> logger -> info('Populated all tables');
	$self -> logger -> info('-' x 50);

	# Return 0 for OK and 1 for error.

	return 0;

}	# End of populate_all_tables.

# -----------------------------------------------

sub populate_constants_table
{
	my($self, $csv, $path)	= @_;
	my($table_name)			= 'constants';
	$path					=~ s/levies_due/$table_name/;

	# Populates $self -> column_names.

	$self -> get_table_column_names(true, $table_name);

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	$csv -> column_names($csv -> getline($io) );

	my($count) = 0;

	my($error_message);
	my(%keys);

	for my $item (@{$csv -> getline_hr_all($io) })
	{
		$count++;

		for my $column (@{$self -> column_names})
		{
			if (! defined $$item{$column})
			{
				$self -> logger -> error("$table_name. Row: $count. Column $column undefined");
			}
		}

		if ($keys{$$item{name} })
		{
			$error_message = "$table_name. Duplicate $table_name.name: $keys{$$item{name} }";

			$self -> logger -> error($error_message);

			die $error_message;
		}

		$keys{$$item{name} } = $self -> insert_hashref
		(
			$table_name,
			{
				id		=> $count,
				name	=> $$item{name},
				value	=> $$item{value},
			}
		);
	}

	close $io;

	$self -> logger -> info("Stored $count records into '$table_name'");

}	# End of populate_constants_table.

# -----------------------------------------------

sub populate_topics_table
{
	my($self)		= @_;
	my($data)		= $self -> read_tiddlers_file;
	my($count)		= 1;
	my($record)		= {parent_id => 1, text => 'Root', title => 'MetaCurator'}; # Parent is self.
	my($table_name)	= 'topics';
	my($root_id)	= $self -> insert_hashref($table_name, $record);

	my($id);
	my($text, $title);

	for my $index (0 .. $#$data)
	{
		# Node keys: created modified text title.

		$text	= $$data[$index]{text};
		$title	= $$data[$index]{title};

		next if ($title =~ /GettingStarted|MainMenu/); # TiddlyWiki special cases.

		$count++;

		$self -> logger -> info("Missing text @ line: $index. title: $title"), next if (! defined $text);
		$self -> logger -> info("Missing prefix @ line: $index. title: $title"), next if ($text !~ m/^\"\"\"\no (.+)$/s);

		$$record{parent_id}	= $root_id;
		$$record{title}		= $title;
		$text				= $1 if ($text =~ m/^\"\"\"\n(.+)$/s);
		$$record{text}		= $text;
		$id					= $self -> insert_hashref($table_name, $record);

		$self -> logger -> info('AiEngines: ' . $text) if ($title eq 'AiEngines');
	}

	$self -> logger -> info("Stored $count records into '$table_name'");

} # End of populate_topics_table;

# --------------------------------------------------

sub read_tiddlers_file
{
	my($self)		= @_;
	my($file_name)	= File::Spec -> catfile($self -> home_path, $self -> tiddlers_path);
	my($json)		= read_text($file_name, 'UTF-8');

	return from_json $json;

} # End of read_tiddlers_file.
# --------------------------------------------------

1;

=pod

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Support

Email the author.

=head1 Author

L<CPAN::MetaCurator> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2025.

My homepage: L<https://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2025, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
