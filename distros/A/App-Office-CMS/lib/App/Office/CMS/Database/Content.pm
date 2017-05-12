package App::Office::CMS::Database::Content;

use Any::Moose;
use common::sense;

extends 'App::Office::CMS::Database::Base';

use Capture::Tiny 'capture';

use File::Slurp; # For write_file().

# If Moose...
#use namespace::autoclean;

our $VERSION = '0.92';

# --------------------------------------------------

sub add
{
	my($self, $page, $content) = @_;

	$self -> log(debug => "add($$page{name}, ...)");
	$self -> log(debug => '-' x 50);
	$self -> log(debug => "$_ => $$content{$_}") for sort grep{! /^(?:body_text|head_text)$/} keys %$content;
	$self -> log(debug => 'head_text => ' . length($$content{head_text}) . ' bytes');
	$self -> log(debug => 'body_text => ' . length($$content{body_text}) . ' bytes');
	$self -> log(debug => '-' x 50);

	$self -> save_content_record('add', $page, $content);

	return "Saved (add) content for page '$$page{name}'";

} # End of add.

# --------------------------------------------------

sub backup
{
	my($self, $page, $content) = @_;
	my($backup_command) = ${$self -> db -> config}{backup_command};
	my($backup_file)    = ${$self -> db -> config}{backup_file};
	my($stdout)         = $self -> capture_or_die($backup_command);

	write_file($backup_file, {err_mode => 'quiet'}, $stdout) || die "Error: Can't write backup file: $!\n";

	return $self -> update($page, $content) . " and backed-up";

} # End of backup.

# -----------------------------------------------

sub capture_or_die
{
	my($self, @command)  = @_;
	my($stdout, $stderr) = capture{system(@command)};

	$stderr && die "Error: $stderr\n";

	return $stdout;

} # End of capture_or_die.

# --------------------------------------------------

sub duplicate_contents
{
	my($self, $attr) = @_;

	$self -> log(debug => "duplicate_contents()");

	$$attr{content_id2new_id} = {};

	my($content);
	my($old_content_id);
	my($page);

	for my $old_design_id (keys %{$$attr{page_id2new_id} })
	{
		$$attr{content_id2new_id}{$old_design_id} = {};

		for my $old_page_id (keys %{$$attr{page_id2new_id}{$old_design_id} })
		{
			$content = $self -> get_content_by_page_id($old_page_id);

			# Skip pages which have no content.

			next if (! $content);

			$page                = $self -> db -> page -> get_page_by_id($old_page_id);
			$old_content_id      = $$content{id};
			$$content{design_id} = $$attr{design_id2new_id}{$old_design_id};
			$$content{page_id}   = $$attr{page_id2new_id}{$old_design_id}{$old_page_id};
			$$content{site_id}   = $$attr{new_site_id};

			$self -> add($page, $content);

			$$attr{content_id2new_id}{$old_design_id}{$old_content_id} = $$content{id};
		}
	}

} # End of duplicate_contents.

# --------------------------------------------------
# TODO. We assume the page has 1 content record, so we get it and not an arrayref.

sub get_content_by_page_id
{
	my($self, $id) = @_;

	return $self -> db -> simple -> query('select * from contents where page_id = ?', $id) -> hash;

} # End of get_content_by_page_id.

# --------------------------------------------------

sub get_content_id_by_page_id
{
	my($self, $id) = @_;
	my($hash) = $self -> db -> simple -> query('select id from contents where page_id = ?', $id) -> hash;

	return $hash && $$hash{id} ? $$hash{id} : 0;

} # End of get_content_id_by_page_id.

# --------------------------------------------------

sub save_content_record
{
	my($self, $context, $page, $content) = @_;

	$self -> log(debug => "save_content_record($context, ...)");

	my($table_name) = 'contents';
	my(@field)      = (qw/
body_text
design_id
head_text
page_id
site_id
/);
	my($data) = {};

	for (@field)
	{
		$$data{$_} = $$content{$_};
	}

	if ($context eq 'add')
	{
		$$content{id} = $self -> db -> insert_hash_get_id($table_name, $data);
	}
	else
	{
		$self -> db -> simple -> update($table_name, $data, {id => $$content{id} });
	}

	$self -> log(debug => "Saved ($context) content for page '$$page{name}' with id $$content{id}");

} # End of save_content_record.

# --------------------------------------------------

sub update
{
	my($self, $page, $content) = @_;

	$self -> log(debug => "update($$page{name}, ...)");
	$self -> log(debug => '-' x 50);
	$self -> log(debug => "$_ => $$content{$_}") for sort grep{! /^(?:body_text|head_text)$/} keys %$content;
	$self -> log(debug => 'head_text => ' . length($$content{head_text}) . ' bytes');
	$self -> log(debug => 'body_text => ' . length($$content{body_text}) . ' bytes');
	$self -> log(debug => '-' x 50);

	# Now determine if this is an add or an update.

	$$content{id} = $self -> get_content_id_by_page_id($$content{page_id});
	my($action)   = $$content{id} ? 'update' : 'add';

	$self -> save_content_record($action, $page, $content);

	return "Saved ($action) content";

} # End of update.

# --------------------------------------------------

no Any::Moose;

# If Moose...
#__PACKAGE__ -> meta -> make_immutable;

1;
