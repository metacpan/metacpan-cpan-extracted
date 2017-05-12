package App::Office::CMS::Database::Design;

use Any::Moose;
use common::sense;

use Date::Format;

use File::Spec;

use Tree::DAG_Node;

extends 'App::Office::CMS::Database::Base';

# If Moose...
#use namespace::autoclean;

our $VERSION = '0.92';

# --------------------------------------------------

sub add
{
	my($self, $site, $design) = @_;

	$self -> log(debug => "add($$site{name}, $$design{name})");
	$self -> log(debug => '-' x 50);
	$self -> log(debug => "Design: $_ => $$design{$_}") for sort keys %$design;
	$self -> log(debug => '-' x 50);

	my($action) = $$design{exact_match} ? 'update' : 'add';

	$self -> save_design_record($action, $design);

	if ($action eq 'add')
	{
		$self -> db -> session -> param(edit_design_id => $$design{id});

		# Every design has a default homepage, and an asset and content.

		my($homepage) = $self -> db -> page -> add_homepage($site, $design);
	}

	return $design;

} # End of add.

# -----------------------------------------------

sub build_search_result
{
	my($self, $match, $result, $site, $design) = @_;

	$self -> log(debug => 'build_search_result()');

	my($id_pair) = "$$site{id}-$$design{id}";

	push @$result,
	{
		design_id   => $$design{id},
		design_name => $$design{name},
		id_pair     => $id_pair,
		match       => $match,
		page_name   => '-',
		site_id     => $$site{id},
		site_name   => $$site{name},
	};

} # End of build_search_result.

# -----------------------------------------------

sub delete
{
	my($self, $site, $design) = @_;

	$self -> log(debug => "delete($$site{name}, $$design{name})");

	$self -> db -> simple -> delete('designs', {id => $$design{id} });

	my($message) = "Deleted design '$$design{name}' for site '$$site{name}'";

	if ($self -> db -> get_design_count == 0)
	{
		# This assumes the design's site_id field is valid,
		# or (same thing) the site's id field is valid.

		$self -> log(debug => "Using site_id of design: $$site{id}");

		# Defaults:
		# o Menu orientation: 4 - Vertical
		# o Doc root: /

		my($os_type_id)     = $self -> db -> get_default_os_type_id;
		my($default_design) = $self -> db -> build_default_design($$site{id}, 'Default', 4, $os_type_id, File::Spec -> tmpdir, '/');
		$message            .= '. No designs left, so a default design has been generated';

		$self -> add($site, $default_design);
	}

	return $message;

} # End of delete.

# -----------------------------------------------

sub duplicate
{
	my($self, $site, $design) = @_;

	$self -> log(debug => "duplicate($$site{name}, $$design{name} => $$site{new_name})");
	$self -> log(debug => '-' x 50);
	$self -> log(debug => "Site: $_ => $$site{$_}") for sort keys %$site;
	$self -> log(debug => '-' x 50);
	$self -> log(debug => "Design: $_ => $$design{$_}") for sort keys %$design;
	$self -> log(debug => '-' x 50);

	my($message);

	if ($$site{exact_match} && $$design{exact_match})
	{
		# Do this first, since we overwrite $$design{name} below.

		my($attr)               = {};
		$$attr{old_design_name} = $$design{name};
		$$attr{new_design_name} = $$site{new_name}; # Not $$design{new_name}.
		$$attr{old_site_id}     = $$site{id};
		$$attr{new_site_id}     = $$site{id};
		$message                = "Duplicated design '$$design{name}' to '$$site{new_name}'";

		# 1: Write a new design record.
		# We can't call add() because it does too much.
		# We save the original id so we can find its pages.
		# After the save, $$design{id} is the new design's id.

		$$attr{old_design_id} = $$design{id};
		$$design{name}        = $$site{new_name}; # Not $$design{new_name}.

		$self -> save_design_record('add', $design);

		# Emulate duplicate_designs(), as called by Site.duplicate().

		$$attr{design_id2new_id}                         = {};
		$$attr{design_id2new_id}{$$attr{old_design_id} } = $$design{id};
		$$attr{new_site_id}                              = $$site{id};

		# 2: Write all the corresponding page and menu records.
		# We return the map of old page ids to their new ids, for this design.

		$self -> db -> page -> duplicate_pages($attr);

		# 3: Write all the corresponding asset records.
		# We return the map of old asset ids to their new ids, for each page within this design.

		$self -> db -> asset -> duplicate_assets($attr);

		# 4: Write all the corresponding content records.
		# We return the map of old content ids to their new ids, for each page within this design.

		$self -> db -> content -> duplicate_contents($attr);
	}
	else
	{
		$message = "No site/design combination matches '$$site{name}/$$design{name}'";
	}

	return $message;

} # End of duplicate.

# --------------------------------------------------

sub duplicate_designs
{
	my($self, $attr) = @_;

	$self -> log(debug => "duplicate_designs()");

	$$attr{design_id2new_id} = {};

	my($old_design_id);

	for my $design (@{$self -> get_designs_by_site_id($$attr{old_site_id})})
	{
		# Move house.

		$old_design_id    = $$design{id};
		$$design{site_id} = $$attr{new_site_id};

		# We don't call add() because it does too much.

		$self -> save_design_record('add', $design);

		$$attr{design_id2new_id}{$old_design_id} = $$design{id};
	}

} # End of duplicate_designs.

# --------------------------------------------------

sub get_design_by_exact_name
{
	my($self, $site_id, $name) = @_;

	$self -> log(debug => "get_design_by_exact_name($site_id, $name)");

	my($design) = $self -> db -> simple -> query('select * from designs where site_id = ? and upper_name = ?', $site_id, uc $name) -> hash;

	$$design{exact_match} = 1 if ($design);

	return $design;

} # End of get_design_by_exact_name.

# --------------------------------------------------

sub get_designs_by_approx_name
{
	my($self, $name) = @_;

	$self -> log(debug => "get_designs_by_approx_name($name)");

	return [$self -> db -> simple -> query('select * from designs where upper_name like ?', "%\U$name\E%") -> hashes];

} # End of get_designs_by_approx_name.

# --------------------------------------------------

sub get_design_by_id
{
	my($self, $id)  = @_;

	$self -> log(debug => "get_design_by_id($id)");

	return  $self -> db -> simple -> query('select * from designs where id = ?', $id) -> hash;

} # End of get_design_by_id.

# --------------------------------------------------

sub get_designs_by_site_id
{
	my($self, $site_id) = @_;

	$self -> log(debug => "get_designs_by_site_id($site_id)");

	return [$self -> db -> simple -> query('select * from designs where site_id = ?', $site_id) -> hashes];

} # End of get_designs_by_site_id.

# --------------------------------------------------

sub save_design_record
{
	my($self, $context, $design) = @_;

	$self -> log(debug => "save_design_record($context, $$design{name})");

	my($table_name) = 'designs';
	my(@time)       = localtime;
	my($time)       = strftime('%Y-%m-%d %X', @time);
	my(@field)      = (qw/
menu_orientation_id
name
os_type_id
output_directory
output_doc_root
site_id
/);
	my($data) = {};

	for (@field)
	{
		$$data{$_} = $$design{$_};
	}

	# Set this no matter whether we're adding or updating.

	$$data{upper_name} = uc $$data{name};

	if ($context eq 'add')
	{
		$$design{id} = $self -> db -> insert_hash_get_id($table_name, $data);
	}
	else
	{
		$self -> db -> simple -> update($table_name, $data, {id => $$design{id} });
	}

	$self -> log(debug => "Saved ($context) design '$$design{name}' with id $$design{id}");

} # End of save_design_record.

# --------------------------------------------------

sub search
{
	my($self, $name, $result) = @_;

	$self -> log(debug => "search($name)");

	my($design_set) = $self -> get_designs_by_approx_name($name);

	$self -> log(debug => "Design match count: " . scalar @$design_set);

	my($site);

	for my $design (@$design_set)
	{
		$site = $self -> db -> site -> get_site_by_id($$design{site_id});

		$self -> build_search_result('Design', $result, $site, $design);
	}

	return $result;

} # End of search.

# --------------------------------------------------

sub update
{
	my($self, $design) = @_;

	$self -> log(debug => "update($$design{name})");
	$self -> log(debug => '-' x 50);
	$self -> log(debug => "Site: $_ => $$design{$_}") for sort keys %$design;
	$self -> log(debug => '-' x 50);

	my($action) = $$design{exact_match} ? 'update' : 'add';

	$self -> save_design_record($action, $design);

	if ($action eq 'add')
	{
		$self -> db -> session -> param(edit_design_id => $$design{id});
	}

	return ucfirst "$action design '$$design{name}'";

} # End of update.

# --------------------------------------------------

no Any::Moose;

# If Moose...
#__PACKAGE__ -> meta -> make_immutable;

1;
