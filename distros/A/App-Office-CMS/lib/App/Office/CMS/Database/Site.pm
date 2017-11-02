package App::Office::CMS::Database::Site;

use strict;
use warnings;

use Date::Format;

use Moo;

extends 'App::Office::CMS::Database::Base';

our $VERSION = '0.93';

# --------------------------------------------------

sub add
{
	my($self, $site, $design) = @_;

	$self -> log(debug => "add($$site{name})");
	$self -> log(debug => '-' x 50);
	$self -> log(debug => "Site: $_ => $$site{$_}") for sort keys %$site;
	$self -> log(debug => '-' x 50);

	my($action) = $$site{exact_match} ? 'update' : 'add';

	$self -> save_site_record($action, $site);

	if ($action eq 'add')
	{
		$self -> db -> session -> param(edit_site_id => $$site{id});
	}

	$$design{site_id} = $$site{id};
	$design           = $self -> db -> design -> add($site, $design);

	return "Saved site '$$site{name}' and design '$$design{name}'. Also, a default homepage has been generated";

} # End of add.

# -----------------------------------------------

sub build_search_result
{
	my($self, $match, $result, $site, $design) = @_;

	$self -> log(debug => 'build_search_result()');

	# Phase 1: Do not add sites if they have already been found
	# by searching for designs using the client's input 'name'.

	for my $record (@$result)
	{
		if ( ($$site{id} == $$record{site_id}) && ($$design{name} eq $$record{design_name}) )
		{
			return;
		}
	}

	# Phase 2: Add new sites to result set.

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
	my($self, $site) = @_;

	$self -> log(debug => "delete($$site{name})");
	$self -> log(debug => '-' x 50);
	$self -> log(debug => "Site: $_ => $$site{$_}") for sort keys %$site;
	$self -> log(debug => '-' x 50);

	my($message);

	if ($$site{exact_match})
	{
		$self -> db -> simple -> delete('sites', {id => $$site{id} });

		$message = "Deleted site '$$site{name}";
	}
	else
	{
		$message = "No site matches the name '$$site{name}'";
	}

	return $message;

} # End of delete.

# -----------------------------------------------

sub duplicate
{
	my($self, $site) = @_;

	$self -> log(debug => "duplicate($$site{name} => $$site{new_name})");
	$self -> log(debug => '-' x 50);
	$self -> log(debug => "Site: $_ => $$site{$_}") for sort keys %$site;
	$self -> log(debug => '-' x 50);

	my($message);

	if ($$site{exact_match})
	{
		# Do this first, since we overwrite $$site{name} below.

		my($attr)             = {};
		$$attr{old_site_name} = $$site{name};
		$$attr{new_site_name} = $$site{new_name};
		$message              = "Duplicated site '$$site{name}' to '$$site{new_name}'";

		# 1: Write a new site record.
		# We can't call add() because it does too much.
		# We save the original id so we can find its designs.
		# After the save, $$site{id} is the new site's id.

		$$attr{old_site_id} = $$site{id};
		$$site{name}        = $$site{new_name};

		$self -> save_site_record('add', $site);

		$$attr{new_site_id} = $$site{id};

		# 2: Write all the corresponding design records.
		# We return the map of old design ids to their new ids.

		$self -> db -> design -> duplicate_designs($attr);

		# 3: Write all the corresponding page records.
		# We return the map of old page ids to their new ids, for each design.

		$self -> db -> page -> duplicate_pages($attr);

		# 4: Write all the corresponding asset records.
		# We return the map of old asset ids to their new ids, for each page within each design.

		$self -> db -> asset -> duplicate_assets($attr);

		# 5: Write all the corresponding content records.
		# We return the map of old content ids to their new ids, for each page within each design.

		$self -> db -> content -> duplicate_contents($attr);
	}
	else
	{
		$message = "No site matches the name '$$site{name}'";
	}

	return $message;

} # End of duplicate.

# --------------------------------------------------

sub get_site_by_exact_name
{
	my($self, $name) = @_;

	$self -> log(debug => "get_site_by_exact_name($name)");

	my($site) = $self -> db -> simple -> query('select * from sites where upper_name = ?', uc $name) -> hash;

	$$site{exact_match} = 1 if ($site);

	return $site;

} # End of get_site_by_exact_name.

# --------------------------------------------------

sub get_site_by_id
{
	my($self, $id)  = @_;

	$self -> log(debug => "get_site_by_id($id)");

	return  $self -> db -> simple -> query('select * from sites where id = ?', $id) -> hash;

} # End of get_site_by_id.

# --------------------------------------------------

sub get_sites_by_approx_name
{
	my($self, $name) = @_;

	$self -> log(debug => "get_sites_by_approx_name($name)");

	return [$self -> db -> simple -> query('select * from sites where upper_name like ?', "%\U$name\E%") -> hashes];

} # End of get_sites_by_approx_name.

# --------------------------------------------------

sub save_site_record
{
	my($self, $context, $site) = @_;

	$self -> log(debug => "save_site_record($context, $$site{name})");

	my($table_name) = 'sites';
	my(@time)       = localtime;
	my($time)       = strftime('%Y-%m-%d %X', @time);
	my(@field)      = (qw/
name
/);
	my($data) = {};

	for (@field)
	{
		$$data{$_} = $$site{$_};
	}

	# Set this no matter whether we're adding or updating.

	$$data{upper_name} = uc $$data{name};

	if ($context eq 'add')
	{
		$$site{id} = $self -> db -> insert_hash_get_id($table_name, $data);
	}
	else
	{
		$self -> db -> simple -> update($table_name, $data, {id => $$site{id} });
	}

	$self -> log(debug => "Saved ($context) site '$$site{name}' with id $$site{id}");

} # End of save_site_record.

# --------------------------------------------------

sub search
{
	my($self, $name) = @_;

	$self -> log(debug => "search($name)");

	my($result)   = [];
	my($site_set) = $self -> get_sites_by_approx_name($name);

	$self -> log(debug => "Site match count: " . scalar @$site_set);

	my($design_set);

	for my $site (@$site_set)
	{
		# This works because every design belongs to a site,
		# and you can't create a site without designs.

		$design_set = $self -> db -> design -> get_designs_by_site_id($$site{id});

		for my $design (@$design_set)
		{
			$self -> build_search_result('Site', $result, $site, $design);
		}
	}

	return $result;

} # End of search.

# --------------------------------------------------

sub update
{
	my($self, $site, $design) = @_;

	$self -> log(debug => "update($$site{name})");
	$self -> log(debug => '-' x 50);
	$self -> log(debug => "Site: $_ => $$site{$_}") for sort keys %$site;
	$self -> log(debug => '-' x 50);
	$self -> log(debug => "Design: $_ => $$design{$_}") for sort keys %$design;
	$self -> log(debug => '-' x 50);

	my($action) = $$site{exact_match} ? 'update' : 'add';

	$self -> save_site_record($action, $site);

	if ($action eq 'add')
	{
		$self -> db -> session -> param(edit_site_id => $$site{id});
	}

	$$design{site_id} = $$site{id};

	$self -> db -> design -> add($site, $design);

	return ucfirst "$action site '$$site{name}'";

} # End of update.

# --------------------------------------------------

1;
