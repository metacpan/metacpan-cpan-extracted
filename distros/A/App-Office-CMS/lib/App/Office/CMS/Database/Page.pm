package App::Office::CMS::Database::Page;

use Any::Moose;
use common::sense;

use Date::Format;

use Tree;

extends 'App::Office::CMS::Database::Base';

# If Moose...
#use namespace::autoclean;

our $VERSION = '0.92';

# --------------------------------------------------

sub add
{
	my($self, $page) = @_;
	$$page{context}  = $self -> db -> build_context($$page{site_id}, $$page{design_id});

	$self -> log(debug => "add($$page{name})");
	$self -> log(debug => '-' x 50);
	$self -> log(debug => "Page: $_ => $$page{$_}") for sort keys %$page;
	$self -> log(debug => '-' x 50);

	$self -> save_page_record('add', $page);
	$self -> db -> session -> param(edit_page_id => $$page{id});

 	# Add a default asset.
	# Return the asset_id for use by update(), if that's how we got here,
	# since it needs to update the default asset with the user's input.

	my($asset)       = $self -> db -> build_default_asset($page);
	$$page{asset_id} = $self -> db -> asset -> add($asset);

	# Add default content.

	my($content) = $self -> db -> build_default_content($$page{site_id}, $$page{design_id}, $$page{id});

	$self -> db -> content -> add($page, $content);

	return $page;

} # End of add.

# --------------------------------------------------

sub add_child
{
	my($self, $page, $asset) = @_;

	$self -> log(debug => "add_child($$page{name})");
	$self -> log(debug => '-' x 50);
	$self -> log(debug => "Page: $_ => $$page{$_}") for sort keys %$page;
	$self -> log(debug => '-' x 50);

	# Add the page to the pages table.

	my($edit_page_id) = $self -> db -> session -> param('edit_page_id');
	my($old_page)     = $self -> get_page_by_id($edit_page_id);

	$self -> add($page);

	# Add the page to the menu.

	my($tree)     = $self -> db -> menu -> get_menu_by_context($self -> db -> build_context($$page{site_id}, $$page{design_id}) );
	my($old_node) = $self -> db -> menu -> get_node_by_name($tree, $$old_page{name});
	my($node)     = Tree::DAG_Node -> new;

	$node -> name($$page{name});

	# Put the page's id into the node, so that it gets written to the menus table.
	# It is used to recover the content of each node, in *::Controller::Content.generate_web_page().

	${$node -> attributes}{page_id} = $$page{id};

	$old_node -> add_daughter($node);

	my($design) =
	{
		id      => $$page{design_id},
		site_id => $$page{site_id},
	};
	$tree = $self -> db -> menu -> update($design, $tree, ['page_id']);

	return "Added '$$page{name}' as a child";

} # End of add_child.

# --------------------------------------------------

sub add_homepage
{
	my($self, $site, $design) = @_;

	$self -> log(debug => "add_homepage($$site{name}, $$design{name})");

	my($homepage_name)   = ${$self -> db -> config}{homepage_name};
	my($homepage)        = $self -> db -> build_default_page($site, $design, $homepage_name);
	$$homepage{homepage} = 'Yes';
	$homepage            = $self -> add($homepage);

	# Save the corresponding tree in the menus table.

	my($root) = Tree::DAG_Node -> new;
	my($node) = Tree::DAG_Node -> new;

	$root -> name('Root');
	$node -> name($homepage_name);
	$root -> add_daughter($node);

	# Put the page's id into the node, so that it gets written to the menus table.
	# It is used to recover the content of each node, in *::Controller::Content.generate_web_page().

	${$root -> attributes}{page_id} = 0;
	${$node -> attributes}{page_id} = $$homepage{id};

	# Ignore return value, which is $tree.

	$self -> db -> menu -> add($design, $root, ['page_id']);

	# The caller wants access to $$homepage{id}.

	return $homepage;

} # End of add_homepage.

# --------------------------------------------------

sub add_sibling
{
	my($self, $page, $offset) = @_;

	# Add the page to the pages table.

	my($edit_page_id) = $self -> db -> session -> param('edit_page_id');
	my($old_page)     = $self -> get_page_by_id($edit_page_id);

	$self -> add($page);

	# Add the page to the menu.

	my($tree)     = $self -> db -> menu -> get_menu_by_context($self -> db -> build_context($$page{site_id}, $$page{design_id}) );
	my($old_node) = $self -> db -> menu -> get_node_by_name($tree, $$old_page{name});
	my($new_node) = Tree::DAG_Node -> new;

	$new_node -> name($$page{name});

	# Put the page's id into the node, so that it gets written to the menus table.
	# It is used to recover the content of each node, in *::Controller::Content.generate_web_page().

	${$new_node -> attributes}{page_id} = $$page{id};
	my(@daughter)                       = $old_node -> self_and_sisters;
	my($index)                          = $old_node -> my_daughter_index;

	if ($offset eq 'below')
	{
		$index++;
	}

	splice(@daughter, $index, 0, $new_node);

	$old_node -> mother -> set_daughters(@daughter);

	my($design) =
	{
		id      => $$page{design_id},
		site_id => $$page{site_id},
	};
	$tree = $self -> db -> menu -> update($design, $tree, ['page_id']);

	return "Added '$$page{name}' as a sibling $offset '$$old_page{name}'";

} # End of add_sibling.

# --------------------------------------------------

sub add_sibling_above
{
	my($self, $page, $asset) = @_;

	$self -> log(debug => "add_sibling_above($$page{name})");
	$self -> log(debug => '-' x 50);
	$self -> log(debug => "Page: $_ => $$page{$_}") for sort keys %$page;
	$self -> log(debug => '-' x 50);

	return $self -> add_sibling($page, 'above');

} # End of add_sibling_above.

# --------------------------------------------------

sub add_sibling_below
{
	my($self, $page) = @_;

	$self -> log(debug => "add_sibling_below($$page{name})");
	$self -> log(debug => '-' x 50);
	$self -> log(debug => "Page: $_ => $$page{$_}") for sort keys %$page;
	$self -> log(debug => '-' x 50);

	return $self -> add_sibling($page, 'below');

} # End of add_sibling_below.

# -----------------------------------------------

sub build_search_result
{
	my($self, $match, $result, $site, $design, $page) = @_;

	$self -> log(debug => 'build_search_result()');

	my($id_pair) = "$$site{id}-$$page{design_id}";

	$self -> log(debug => "Adding page $$page{name} to the search results");

	push @$result,
	{
		design_id   => $$page{design_id},
		design_name => $$design{name},
		id_pair     => $id_pair,
		match       => $match,
		page_name   => $$page{name},
		site_id     => $$site{id},
		site_name   => $$site{name},
	};

} # End of build_search_result.

# --------------------------------------------------

sub delete
{
	my($self, $page, $asset) = @_;

	$self -> log(debug => "delete($$page{name})");
	$self -> log(debug => '-' x 50);
	$self -> log(debug => "Page: $_ => $$page{$_}") for sort keys %$page;
	$self -> log(debug => '-' x 50);

	# Delete from the tree in RAM.

	my($tree) = $self -> db -> menu -> get_menu_by_context($self -> db -> build_context($$page{site_id}, $$page{design_id}) );
	my($node) = $self -> db -> menu -> get_node_by_name($tree, $$page{name});

	$node -> replace_with_daughters;

	my($design) = $self -> db -> design -> get_design_by_id($$page{design_id});

	$self -> db -> menu -> update($design, $tree, ['page_id']);

	# Delete from the pages table.

	my($paje) = $self -> get_page_by_exact_name($$page{site_id}, $$page{design_id}, $$page{name});

	$self -> delete_page_by_id($$paje{id});

	my($message) = "Deleted '$$page{name}' from the menu";

	# If that was the last page in the design, fabricate a default homepage.

	if (scalar $tree -> daughters == 0)
	{
		my($site) = $self -> db -> site -> get_site_by_id($$page{site_id});

		$self -> add_homepage($site, $design);

		$message .= ". Also, a default homepage has been generated";
	}

	# Now we must set the 'current' page to something meaningful.

	my($homepage) = $self -> get_homepage($$page{site_id}, $$page{design_id});

	$self -> log(debug => "Got homepage id: $$homepage{id}");

	$self -> db -> session -> param(edit_page_id => $$homepage{id});

	return $message;

} # End of delete.

# --------------------------------------------------

sub delete_page_by_id
{
	my($self, $id) = @_;

	$self -> log(debug => "delete_page_by_id($id)");

	$self -> db -> simple -> delete('pages', {id => $id});

} # End of delete_page_by_id.

# --------------------------------------------------

sub duplicate_pages
{
	my($self, $attr) = @_;

	$self -> log(debug => 'duplicate_pages()');

	$$attr{page_id2new_id} = {};

	my($new_design_id);
	my($old_page_id);

	for my $old_design_id (keys %{$$attr{design_id2new_id} })
	{
		$new_design_id                         = $$attr{design_id2new_id}{$old_design_id};
		$$attr{page_id2new_id}{$old_design_id} = {};

		for my $page (@{$self -> get_pages_by_design_id($old_design_id)})
		{
			# Move house.

			$old_page_id      = $$page{id};
			$$page{design_id} = $new_design_id;
			$$page{site_id}   = $$attr{new_site_id};

			# We call add(), unlink designs, to calculate context.

			$self -> add($page);

			$$attr{page_id2new_id}{$old_design_id}{$old_page_id} = $$page{id};

			# Duplicate menus.

			my($context) = $self -> db -> build_context($$attr{old_site_id}, $old_design_id);
			my($tree)    = $self -> db -> menu -> get_menu_by_context($context);
			$context     = $self -> db -> build_context($$attr{new_site_id}, $new_design_id);

			$self -> db -> menu -> context($context);
			$self -> db -> menu -> save_menu_tree('add', $tree);
		}
	}

} # End of duplicate_pages.

# --------------------------------------------------

sub get_homepage
{
	my($self, $site_id, $design_id) = @_;

	$self -> log(debug => "get_homepage($site_id, $design_id)");

	my($page) = $self -> db -> simple -> query('select * from pages where site_id = ? and design_id = ? and homepage = ?', $site_id, $design_id, 'Yes') -> hash;

	# If we can't find any page flagged as the homepage, find the root's first daughter.
	# Of course, the page we find may not be the homepage, unless the homepage is the only page.
	# This works because whenever we delete a page, and there are no pages left,
	# we fabricate a homepage.

	if (! $page)
	{
		my($tree) = $self -> db -> menu -> get_menu_by_context($self -> db -> build_context($site_id, $design_id) );
		my(@girl) = $tree -> daughters;
		my($id)   = ${$girl[0] -> attribute}{id};
		$page     = $self -> get_page_by_id($id);
	}

	$$page{exact_match} = 1;

	return $page;

} # End of get_homepage.

# --------------------------------------------------

sub get_page_by_exact_name
{
	my($self, $site_id, $design_id, $name) = @_;

	$self -> log(debug => "get_page_by_exact_name($name)");

	my($page) = $self -> db -> simple -> query('select * from pages where site_id = ? and design_id = ? and upper_name = ?', $site_id, $design_id, uc $name) -> hash;

	$$page{exact_match} = 1 if ($page);

	return $page;

} # End of get_page_by_exact_name.

# --------------------------------------------------

sub get_page_by_id
{
	my($self, $id)  = @_;

	$self -> log(debug => "get_page_by_id($id)");

	return  $self -> db -> simple -> query('select * from pages where id = ?', $id) -> hash;

} # End of get_page_by_id.

# --------------------------------------------------

sub get_pages
{
	my($self, $site, $design) = @_;

	$self -> log(debug => "get_pages($$site{id}, $$design{id})");

	return [$self -> db -> simple -> query('select * from pages where site_id = ? and design_id = ?', $$site{id}, $$design{id}) -> hashes];

} # End of get_pages.

# --------------------------------------------------

sub get_pages_by_approx_name
{
	my($self, $name) = @_;

	$self -> log(debug => "get_pages_by_approx_name($name)");

	return [$self -> db -> simple -> query('select * from pages where upper_name like ?', "\U%$name\E%") -> hashes];

} # End of get_pages_by_approx_name.

# --------------------------------------------------

sub get_pages_by_design_id
{
	my($self, $design_id) = @_;

	$self -> log(debug => "get_pages_by_design_id($design_id)");

	return [$self -> db -> simple -> query('select * from pages where design_id = ?', $design_id) -> hashes];

} # End of get_pages_by_design_id.

# --------------------------------------------------

sub save_page_record
{
	my($self, $context, $page) = @_;

	$self -> log(debug => "save_page_record($context, $$page{name})");

	my($table_name) = 'pages';
	my(@time)       = localtime;
	my($time)       = strftime('%Y-%m-%d %X', @time);
	my(@field)      = (qw/
context
design_id
homepage
name
site_id
/);
	my($data) = {};

	for (@field)
	{
		$$data{$_} = $$page{$_};
	}

	# Set this no matter whether we're adding or updating.

	$$data{upper_name} = uc $$data{name};

	if ($context eq 'add')
	{
		$$page{id} = $self -> db -> insert_hash_get_id($table_name, $data);
	}
	else
	{
		$self -> db -> simple -> update($table_name, $data, {id => $$page{id} });
	}

	if ($$data{homepage} eq 'Yes')
	{
		# If this is a homepage, no other page in this design can be a homepage...

		$self -> db -> simple -> update
			(
			 'pages',
			 {
				 homepage  => 'No',
			 },
			 {
				 design_id => $$page{design_id},
				 id        => {'!=' => $$page{id} },
				 site_id   => $$page{site_id},
			 }
			);
	}

	$self -> log(debug => "Saved ($context) page '$$page{name}' with id $$page{id}");

} # End of save_page_record.

# --------------------------------------------------

sub search
{
	my($self, $name, $result) = @_;

	$self -> log(debug => "search($name)");

	my($page_set) = $self -> get_pages_by_approx_name($name);

	$self -> log(debug => "Page match count: " . scalar @$page_set);

	my($design);
	my($site);

	for my $page (@$page_set)
	{
		$design = $self -> db -> design -> get_design_by_id($$page{design_id});
		$site   = $self -> db -> site -> get_site_by_id($$page{site_id});

		$self -> build_search_result('Page', $result, $site, $design, $page);
	}

	return $result;

} # End of search.

# --------------------------------------------------

sub update
{
	my($self, $page, $asset) = @_;
	my($action) = $$page{exact_match} ? 'update' : 'add';

	# If the update is really an add, because the user changed the name of the page,
	# then we have to execute the 'add' code, and then update the default asset.
	#
	# Calling add_sibling() rather than add_child() is my arbitrary decision.
	# We can't call add(), because that wouldn't add the page to the menu.
	#
	# We set $$page{exact_match} and $$asset{id} so that asset -> update()
	# will update the default asset.
	#
	# Lastly, we set $$asset{page_id} since the default page had no id - it was undef,
	# and it was that id which was put into the default asset's page_id.

	if ($action eq 'add')
	{
		my($result)         = $self -> add_sibling($page, 'below');
		$$page{exact_match} = 1;
		$$asset{id}         = $$page{asset_id};
		$$asset{page_id}    = $$page{id};

		$self -> db -> asset -> update($page, $asset);

		return $result;
	}

	$self -> log(debug => "update($$page{name})");
	$self -> log(debug => '-' x 50);
	$self -> log(debug => "Page: $_ => $$page{$_}") for sort keys %$page;
	$self -> log(debug => '-' x 50);
	$self -> log(debug => "Asset: $_ => $$asset{$_}") for sort keys %$asset;
	$self -> log(debug => '-' x 50);

	$self -> save_page_record($action, $page);

	$$asset{page_id} = $$page{id};

	$self -> db -> asset -> update($page, $asset);

	return ucfirst "$action page '$$page{name}'";

} # End of update.

# --------------------------------------------------

no Any::Moose;

# If Moose...
#__PACKAGE__ -> meta -> make_immutable;

1;
