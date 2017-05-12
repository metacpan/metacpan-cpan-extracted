package CatalystX::ListFramework;
use HTML::Widget;
use File::Slurp;
use Data::Dumper;
use Carp;

use strict;
use warnings;
our $VERSION = '0.5';
require 5.8.1;

=head1 NAME

CatalystX::ListFramework - foundations for displaying and editing lists (CRUD) in a Catalyst application

=head1 SYNOPSIS

    package MyApp::Controller::Foo;
    use base 'Catalyst::Controller';
    use CatalystX::ListFramework;
    
    sub listandsearch :Local {
        my ($self, $c, $kind) = @_;
        my $lf = CatalystX::ListFramework->new($kind, $c);
        my $restrict = {};
        $lf->stash_listing('myview', 'myprefix', $restrict);
        $c->stash->{template} = 'list-and-search.tt';
    }

    sub get :Local {
        my ($self, $c, $kind, $id) = @_;
        my $lf = CatalystX::ListFramework->new($kind, $c);
        $lf->stash_infoboxes({'me.id' => $id}); 
        $c->stash->{kind} = $kind;
        $c->stash->{id} = $id;  # the update form adds this to the URL
        $c->stash->{template} = 'detail.tt';
    }
    
    sub update :Local {
        my ($self, $c, $kind, $id) = @_;
        my $lf = CatalystX::ListFramework->new($kind, $c);
        $lf->update_from_query({'me.id' => $id}); 
        $c->res->redirect("/listandsearch/$kind");
    }
    
    sub create :Local {
        my ($self, $c, $kind) = @_;
        my $lf = CatalystX::ListFramework->new($kind, $c);
        my $id = $lf->create_new; 
        $c->res->redirect("/get/$kind/$id");
    }

=head1 DESCRIPTION

Displaying tabulated lists of database records, updating those records and
creating new ones is a common task in Catalyst applications.
This class supplies such lists, and forms to edit such records, to a set of
templates, using simple definition files and your L<DBIx::Class> Catalyst
model. A search form is also supplied, which can include JSON-powered
ExtJS comboboxes (see L<http://www.extjs.com/>).

To run the included demo application, grab a copy of ExtJS, then

    cd t/
    ln -s /path/to/extjs/ static/extjs-1.1
    lib/script/testapp_server.pl

then

    firefox http://localhost:3000/start
    
Please see L<BUGS> about some SQLite issues with the demo app.
The noninteractive test suite is

    perl live-test.pl
    

=head1 DEFINITION FILES

ListFramework is driven by a set of definition files, found under C<formdef/>, one pair per schema class (table).
These are divided into 'master' files and 'site' files and are named I<kind>.form.
Files under C<master/> describe a I<kind>'s source, what fields it has available, and how it is
associated with other schema classes.
Files under C<site/> describe how the data is displayed on the page.
This division, and the naming, implies that a vendor (you) could supply the master files, while a particular
installation could use customised site files to suit their needs.

These are best understood by looking at the example files.

=head2 Files under /master

The sections in these files are:

=over

=item title

A title, displayed on various screens.

=item model

The DBIx::Class model to use.

=item uses

This is a hashref linking this schema to others, in the form C<< field => 'kind' >>.
In site files, you can then use C<field.> (or several ones nested) to access the foreign schema, for example
"C<fromalbum.artist.name>". C<field> must be listed in the schema as a column and have a matching belongs_to relationship.

=item columns

This hashref species what columns the schema makes available and provides some metadata,
such as column headings, default values and types.

The 'field' property may be an arrayref, all elements of which are concatenated for display.
Static text can be specified using a scalar ref, and you can call functions from the Helper class by
specifying C<function(field)>. For example,

    field => [ \'(', uc(surname), \')' ]
    
If a 'type' field is specified', then a coresponding filter function in ::Helper::Types is called.

There should be a special entry,
C<< OBJECT => {primary_key => 'id'} >>, which specifies the table's primary key (and has other uses).
Referencing OBJECT in a site file gives you the serialisation of the object,
which is useful if you've overloaded "", as in:

    package TestApp::Model::TestModel::Artist;
    use overload '""' => sub {
        my $self = shift;
        return $self->artist_forename . ' ' . $self->artist_surname;
    };

=item create_uri

=item delete_uri

These are simply read by the template. If they're specified, then links are generated on the page.

=item searches

This is a hashref of searches which are made available by this schema, e.g.

    albtitle => {heading=>'Album title', field=>'title', op=>'like'}

If 'op' is set to 'like', the user's input is automatically surrounded by '%'s. The other usual choice is '='.

=back

=head2 Files under /site

The sections in these files are:

=over

=item display

This is a hashref of views, each of which is an arrayref of columns to show in a list.

    default => [
                  {id=>'tid', heading => 'Track Code', uri => '/get/track/'},
                  ...
               ]
               
'id' can refer to foreign fields through the dot notation.
If 'uri' is specified, then the value of the entry's primary key is appended and the column is shown as a link.

=item search

This is an arrayref of fields you want the search form to present (in order).

    {id=>'fromalbum.albid', autocomplete=>['fromalbum.id' => 'fromalbum.title'], minchars=>'0'}

The 'autocomplete' parameter takes 2 arguments in an arrayref: a hidden field
(sent when a search form is submitted) and a field to be displayed to the user in a dropdown list.
Here, album titles are shown, but album IDs are sent by the form.
The user can find an album by typing a substring.

You can also override the 'heading' parameter from the 'site' .form file.

=item infoboxes

The detail view for an entry is split into 'boxes', which are rendered as ExtJS tabs in the demo app.
You can specify local or foreign schema fields by the 'id' property, and headings etc can be overridden as usual.
All fields are editable, unless 'not_editable' is true or the field is more complicated than just a table column.
If '.OBJECT' is specified, a dropdown list of choices is presented.

        track => [
            {id => 'ttitle', not_editable => 1},
            {id => 'fromalbum.artist.OBJECT', heading=>'Who by'},
            ...
            
=item infobox_order



=back

=head1 TEMPLATES

Documentation TODO

=head1 JSON

Documentation TODO

=cut

our %LOADED; # cache of eval'ed formdefs

sub new {
    my ($class, $type, $c) = @_;
    if (exists $LOADED{$type}) {
        # Return the cached instance but refresh the Catalyst context
        $LOADED{$type}->{c} = $c;
        return $LOADED{$type};
    }
    my $FORMDEF_PATH = $c->config()->{'formdef_path'} or die "formdef_path not set";
    
    ## Eval the master/ form file, then the site/ file

    my $def = read_file("$FORMDEF_PATH/master/$type.form") or confess("Can't read formdef file $FORMDEF_PATH/master/$type.form");
    $def = eval($def);
    die "Formdef eval error (master/$type): ".$@ if ($@);

    my $def2 = read_file("$FORMDEF_PATH/site/$type.form") or confess("Can't read formdef file $FORMDEF_PATH/site/$type.form");
    $def2 = eval($def2);
    die "Formdef eval error (site/$type): ".$@ if ($@);

    $def = {%$def, %$def2};

    my $self = {formdef => $def, c => $c, name => $type};
    bless $self, $class;
    $LOADED{$type} = $self;

    if (ref $def->{columns} ne 'HASH') {
        die "No columns hash defined in $type.form";
    }
    foreach my $column_id (keys %{$def->{columns}}) {
        # Set a default 'order_by' value
        my $col = $def->{columns}->{$column_id};
        unless (exists $col->{order_by}) {
            $col->{order_by} = $col->{field};
            if (ref($col->{order_by})) { die "Compound column $column_id must have order_by property"; }
        }
    }
    $def->{columns}->{OBJECT}->{form_type} = $type;
    $def->{columns}->{OBJECT}->{model} = $def->{model};  # to help in autocompletes, where we just get an OBJECT column id
    
    if (ref $def->{searches} ne 'HASH') {
        die "No searches hash defined in $type.form";
    }
    foreach my $search (keys %{$def->{searches}}) {
        my $s = $def->{searches}->{$search};
        # Set a default match operator
        $s->{op} = '=' if (!defined $s->{op});
        # Set a default html type
        $s->{html_type} = 'Textfield' if (!defined $s->{html_type});
    }
    
    return $self;        
}

sub copy_metadata_from_columns {
    # Copy hash fields like 'heading' and 'field' from formdef->columns to ->display->view or infoboxes 
    my ($self, $destination_columns) = @_;
    foreach my $display_column (@$destination_columns) {
        my $formobj = $self;
        my $display_column_id = $display_column->{id};
        while ($display_column_id =~ m{^(\w+)\.(.+)}) {
            my $formdeftype_for_relationship = $formobj->{formdef}->{uses}->{$1}
                or die "Relationship $1 in $1.$2 isn't specified in 'uses'";
            $formobj = __PACKAGE__->new($formdeftype_for_relationship, $formobj->{c});
            $display_column_id = $2;
        }
        my $column_metadata = $formobj->{formdef}->{columns}->{$display_column_id} or die "No such column - $display_column_id";
        foreach my $k (keys %$column_metadata) {
            $display_column->{$k} = $column_metadata->{$k} unless (exists $display_column->{$k});
        }
    }
}

sub get_searches_entry_from_id {
    # In .form files, 'search' is an arrayref of {id=>rel.searchid, arg=>val} which refers to
    # searchid as a key in the 'searches' hash in "$uses->{rel}".form.
    # 'searches' links searchid to things such as field=>, op=> etc. which blah=> in 'search' adds-to/overrides
    
    my ($self, $search_id) = @_;
    my $formobj = $self;
    my ($site_settings) = grep { $_->{id} eq $search_id } (@{$self->{formdef}->{search}});
    while ($search_id =~ m{^(\w+)\.(.+)}) {
        my $formdeftype_for_relationship = $formobj->{formdef}->{uses}->{$1}
            or die "Relationship $1 in $1.$2 isn't specified in 'uses'";
        $formobj = __PACKAGE__->new($formdeftype_for_relationship, $self->{c});
        $search_id = $2;
    }
    my $searches_entry = $formobj->{formdef}->{searches}->{$search_id}  # only this line makes us different from copy_m_from_c above
        or die("No searches entry '$search_id' in $formobj->{name}.form");

    $searches_entry = {%$searches_entry, %$site_settings};
    
    $searches_entry; # oh and the way we're called is different, too
}

sub rowobject_to_columns {
    # Given a row object from the base table and a list of columns to display, return a hashref of col_id => cell_data
    
    my ($self, $db_row_obj, $list_columns) = @_;
    my $processed_row = {};
    foreach my $col (@$list_columns) {
        # To get a column from $db_row, eval '$row = $row->rel' on each bit of $col->{id} up to the last dot,
        # then eval $row->($col->{field})
        my $row_in_wanted_table = $db_row_obj;
        {
            my $col_id = $col->{id};
            while ($col_id =~ m{^(\w+)\.(.+)}) { # work along the abc.def.ghi relationships til we get to the final row obj we want
                $row_in_wanted_table = eval("\$row_in_wanted_table->$1");
                if ($@) { die "Eval of row->$1 failed"; }
                $col_id = $2;
            }
        }
        
        if ($col->{id} =~ m{\.OBJECT$}) { # called from stash_infoboxes and requesting the whole row-object
            $processed_row->{$col->{id}} = $row_in_wanted_table;
            next; # skip processing $field, cos it won't have one
        }
            
        my $cell = "";
        my @fields = ref($col->{field})?(@{$col->{field}}):($col->{field});
        foreach my $field (@fields) {
            if (ref($field) eq 'SCALAR') {  # literal text
                $cell .= $$field;
            }
            elsif ($field =~ /^(\w+)\((.+)\)/) {  # requesting helper $1 on data from dbic call $2
                my $tmp;
                eval "\$tmp = \$row_in_wanted_table->$2";
                if ($@) { die "Eval of row->$2 failed"; }
                eval "\$cell .= \&CatalystX::ListFramework::Helpers::$1(\$tmp, \$self->{c}, \$self->{formdef})";
                confess "Helper call failed: $@" if ($@);
            }
            else { # a simple column name. NB: field can't have dots any more - that's what id is for
                if ($#fields == 0) {
                    eval "\$cell = \$row_in_wanted_table->$field";  # this allows $cell to be an object; not normal in a listing
                    if (ref $cell) {warn '*-*-* Setting cell to an object. Is this really necessary?';}
                }
                else {
                    eval "\$cell .= \$row_in_wanted_table->$field"; # append to $cell if multiple fields (CAN'T BE AN OBJECT!)
                }
                die "Setting cell failed: $@" if ($@);
                if (defined $col->{type}) {
                    eval "\$cell = \&CatalystX::ListFramework::Helpers::Types::$col->{type}(\$cell, \$self->{c}, \$self->{formdef})";
                    confess "Type-helper call failed: $@" if ($@);
                }
            }
        }
        
        $processed_row->{$col->{id}} = $cell;
    }
    return $processed_row;
}



sub join_arg_from_columns {
    my ($self, $list_columns) = @_;
    # Formulate 'join' and 'prefetch' arguments for the DBIC call.
    # Join is for the relationships we search on. Prefetch is for the data we display.

    # join => ['rel', {rel1=>'rel2'}, {rel1=>{rel2=>'rel3'}}, ...] # depending how many dots we have to follow
    
    my %prefetches_seen;
    foreach my $column (@$list_columns) {
        my $prefetch;
        my @path = reverse(split(/\./, $column->{id}));
        next if (scalar(@path) == 1);  # no dots, just a local column
        shift @path;  # junk the column part
        $prefetches_seen{join('.', @path)}++;
    }
    
    # If we're using rel1 and rel1.rel2, this gives join_arg = 'rel1', {rel1=>'rel2'} which is fine but DBIC seems
    # to then join both rels multiple times, e.g. as rel2_2 etc, which is harmless but annoying.
    
    # In the end, just set join=> and prefetch=> to the same thing. DBIC == join proliferation.
    # Prefetch of {rel1=>'rel2'} prefetches both rel1.* and rel2.* - surely a misbehaviour?

    my %joins_seen = %prefetches_seen;  # anything prefetched must also be joined, but we need to spot unnecessary joins first
    foreach my $column (@{$self->{formdef}->{search}}) {
        my $join;
        my @path = reverse(split(/\./, $column->{id}));
        next if (scalar(@path) == 1);  # no dots, just a local column  (this is why I've not rejigged the wasteful split/join/split)
        shift @path;  # junk the column part
        $joins_seen{join('.', @path)}++;
    }
    my @joins_needed = keys %joins_seen;
    # If we have 'album' and 'artist.album' then only 'artist.album' is needed.
    my $deeper_join_exists = sub {
        my $join = shift;
        my @joins = keys %joins_seen;
        foreach (@joins) {
            return 1 if (m{\.$join$});
        }
        return 0;
    };
    @joins_needed = grep { !&$deeper_join_exists($_); } (@joins_needed);
    
    my $join_arg = [];
    foreach (@joins_needed) {
        my @path = split(/\./);
        my $join;
        foreach my $element (@path) {
            if (!defined($join)) {
                $join = $element;   
            }
            else {
                $join = {$element => $join};   
            }
        }
        push @$join_arg, $join;
    }
    #warn Dumper($join_arg);
    $join_arg;
}

sub stash_listing {
    my ($self, $view, $prefix, $default_search) = @_;
    $default_search = {} if (!defined $default_search);
    my $c = $self->{c};
    my $list_columns = $self->{formdef}->{display}->{$view} or confess("No columns defined for view $view");
    
    my $page_size = $c->req->params->{"${prefix}page_size"} || 10;
    my $current_page = $c->req->params->{"${prefix}current_page"} || 1;

    my $join_arg = $self->join_arg_from_columns($list_columns);
    
    my $search_opts = {
                        join     => $join_arg,
                        prefetch => $join_arg,  # having its own arg still leads to redundant extra joins :-(
                      };
                      
    # Check for paging controls on the template.
    my $template_opts = $c->stash->{"${prefix}options"};
    if ($template_opts->{pager}) {    
        $search_opts = {%$search_opts, page => $current_page, rows => $page_size};
    }
    
    # Copy metadata (headings etc) from 'columns' (maybe in a related form file) to 'display'
    $self->copy_metadata_from_columns($list_columns);
    
    if ($c->req->params->{"${prefix}sort"}) {
        my ($order_column_id, $order_direction) = split('-', $c->req->params->{"${prefix}sort"});

        # As we've copied metadata from 'columns' to 'display', we can just grep display for the ID we've been passed
        # and get the order_by info from there.
        
        my ($order_column) = grep {$_->{id} eq $order_column_id} (@$list_columns)
            or die "Can't find a column with id $order_column_id";
        my @orders = ref($order_column->{order_by}) ? (@{$order_column->{order_by}})
                                                    : ($order_column->{order_by});
        my $sql_table = 'me';
        if ($order_column_id =~ m{(.+\.)?(\w+)\.\w+$}) {
            $sql_table = $2;
        }
        foreach my $sql_column (@orders) {
            push @{$search_opts->{order_by}}, \"$sql_table.$sql_column $order_direction";
        }
    }
    elsif ($self->{formdef}->{order_by}) {  # use a default specified in the formdef if nothing clicked, e.g. for invoice detail lines
        push @{$search_opts->{order_by}}, \"$self->{formdef}->{order_by}";
    }
    
    my %search;   # Format is:  date => [-and, {'<=', $before}, {'>=', $after}]
    
    # For each possible search parameter, see if there's a CGI param specifying to use it
    
    foreach my $column (@{$self->{formdef}->{search}}) {
        my $cgi_param = "${prefix}search-$column->{id}";
        if (defined $c->req->params->{$cgi_param} and length $c->req->params->{$cgi_param}) {  # "" means match anything
            my $match = $c->req->params->{$cgi_param};

            # Deal with a.b.c multilevel joins by following the 'uses' chain to get to the 'field' property.
            # See CustomerExtranet.pm. This assumes that no relationship name is repeated.
            
            my $search_id = $column->{id};
            my $searches_entry = $self->get_searches_entry_from_id($search_id);

            # Do transforms based on field type, e.g. for dates turn x/y/zzzz into zzzz-yy-xx
            if (defined $searches_entry->{type}) {
                eval "\$match = \&CatalystX::ListFramework::Helpers::Types::inverse$searches_entry->{type}(\"$match\", \$c, \$self->{formdef})";
                confess "Type-helper call failed: $@" if ($@);
            }
            $match = '%'.$match.'%' if (lc $searches_entry->{op} eq 'like');

            my $sql_column = $searches_entry->{field} or die "No field specified";
            my $sql_table = 'me';
            # If it's a foreign column search, extract the final relationship name
            # as foreign tables are aliased according to the relationship that links to them
            if ($column->{id} =~ m{(.+\.)?(\w+)\.\w+$}) {
                $sql_table = $2; 
            }
            push @{$search{"$sql_table.$sql_column"}}, {$searches_entry->{op} => $match};
        }
    }
    
    # Transform our %search into an SQL::Abstract one.  NB Don't modify default_search
    foreach my $k (keys %search) {
        @{$search{$k}} = ('-and', @{$search{$k}}) if (scalar (@{$search{$k}}) > 1);
    }
    
    my $rs = $c->model($self->{formdef}->{model})->search(
                { %search, %$default_search }, 
                $search_opts
             );

    my @db_rows = $rs->all;
    my @processed;

    foreach my $db_row (@db_rows) {
        my $processed_row;
        $processed_row = $self->rowobject_to_columns($db_row, $list_columns); # a hashref with col_id => celldata

        foreach my $col (@$list_columns) {
            if ($col->{do_running_total}) {
                $processed_row->{$col->{id}.'rt'} = $processed_row->{$col->{id}};
                foreach my $previous_row (@processed) {
                    $processed_row->{$col->{id}.'rt'} += $previous_row->{$col->{id}};
                }
            }
        }
        
        push @processed, $processed_row;
    }
    
    # TODO  This will only work on non-foreign fields
    my @sum_cols = grep {$_->{do_sum}} (@$list_columns);
    if (@sum_cols) {
        my @colfields = map {$_->{field}} (@sum_cols);
        my $sumrs = $c->model($self->{formdef}->{model})->search(
            {
              %search, %$default_search
            }, 
            {
                select => [ map {{ sum => $_ }} (@colfields) ], # @colfields needs to be relationship.row or me.row
                as     => [ @colfields ],
                join   => $join_arg,
            }
        );
        my $sumobj = $sumrs->first;
        my %sums = map {$_->{id} => $sumobj->get_column($_->{field})} (@sum_cols);
        $c->stash->{"${prefix}sums"} = \%sums;
    }
    
    $c->stash->{"${prefix}results"} = \@processed;
    $c->stash->{"${prefix}pager"} = $rs->pager if ($template_opts->{pager}); # Data::Page object
    $c->stash->{"${prefix}listframework"} = $self;
    $c->stash->{"${prefix}view"} = $view;  # for TT to pass to get_listing_columns
    ($c->stash->{"${prefix}search"}, $c->stash->{"${prefix}searchtypes"}) = $self->create_search_widget($prefix, $c);
}


sub stash_infoboxes {
    my ($self, $search) = @_;
    my $c = $self->{c};
    # Stash a TT var ${boxkey}data which contains data on @columns in the obj which is 1st out of $search

    my $all_cols;
    foreach my $box (keys %{$self->{formdef}->{infoboxes}}) {
        my $columns = $self->{formdef}->{infoboxes}->{$box};
        push @$all_cols, @$columns;
    }
    my $join_arg = $self->join_arg_from_columns($all_cols);
    
    my $search_opts = {
                        join => $join_arg,
                        prefetch => $join_arg,
                      };
    
    my $rs = $c->model($self->{formdef}->{model})->search($search, $search_opts);
    my $db_row = $rs->first;
    unless (ref $db_row) {
        warn "NO OBJECT";
        return; # allows invoice view to detect no match and try the other table
    }

    my $box_metadata = [];
    my $box_data = {};
    
    foreach my $box (keys %{$self->{formdef}->{infoboxes}}) {
        my @info;
        my $columns = $self->{formdef}->{infoboxes}->{$box};

        # Copy metadata (headings etc) from 'columns' (maybe in a related form file)
        $self->copy_metadata_from_columns($columns);

        # Make calls on the row object to fill the various columns
        my $processed_row = $self->rowobject_to_columns($db_row, $columns); # a hashref with col_id => celldata

        foreach my $col (@$columns) {
            my %object_info;
            if (ref($processed_row->{$col->{id}})) {  # if it's a '.OBJECT' entry, i.e. to select a belongs_to thing
                %object_info = (
                                primary_key  => $col->{primary_key},  # master formdef columns line for OBJECT sets this
                                form_type    => $col->{form_type},  # some duplication here. This is set by new()
                                stringified  => "$processed_row->{$col->{id}}", # use overloaded ""
                                is_object    => 1,
                               );
            }
            my $is_editable = 1;
            # anything that's not a simple single field or that has a not_editable key isn't editable
            $is_editable = 0 if ($col->{field} && (ref($col->{field}) || $col->{not_editable} || $col->{field} !~ m{^\w+$}));
            
            push @info, {
                          name       => $col->{heading},
                          id         => $col->{id},
                          value      => $processed_row->{$col->{id}},
                          options    => $col->{options},
                          type       => $col->{type},
                          is_editable=> $is_editable,
                          %object_info,
                        };
        }

        # If no column ids were specified for this box, just stash the DB object and let the template do what it likes.
        if (scalar(@info)) {
            $box_data->{$box} = \@info;
        }
        else {
            $box_data->{$box} = $db_row;
        }
        my $title = ucfirst($box);
        $title =~ tr/_/ /;
        push @$box_metadata, {id=>$box, title=>$title};
    }
    
    if (ref($self->{formdef}->{infobox_order})) {
        @$box_metadata = sort { $self->{formdef}->{infobox_order}->{$a->{id}}
                                  <=>
                                $self->{formdef}->{infobox_order}->{$b->{id}}
                              } @$box_metadata;
    }
    $c->stash->{box_metadata} = $box_metadata;
    $c->stash->{box_data} = $box_data;

    return 1;
}

sub update_from_query {  # Update a record. Probably called from an infobox screen
    my ($self, $search) = @_;
    my $c = $self->{c};
    my $rs = $c->model($self->{formdef}->{model})->search($search, {});  # NB: no joins. We'll assume we're looking locally for an id
    my $db_row_obj = $rs->first;
    unless (ref $db_row_obj) { confess "No such object found"; }
    
    # All editable fields must be listed in the infobox section
    my $all_cols;
    foreach my $box (keys %{$self->{formdef}->{infoboxes}}) {
        my $columns = $self->{formdef}->{infoboxes}->{$box};
        push @$all_cols, @$columns;
    }
    $self->copy_metadata_from_columns($all_cols);

    foreach my $col (@$all_cols) {
        next if ($col->{field} && (ref($col->{field}) || $col->{not_editable} || $col->{field} !~ m{^\w+$}));
        if (my $new_value = $c->req->params->{$col->{id}}) {
            my $row_in_wanted_table = $db_row_obj;
            my $row_in_parent_table = undef; # this is the one we must update if we're being sent an OBJECT id
            {
                # Obtain the row object on which to call update.
                my $col_id = $col->{id};
                while ($col_id =~ m{^(\w+)\.(.+)}) { # work along the abc.def.ghi relationships til we get to the final row obj we want
                    $row_in_parent_table = $row_in_wanted_table;
                    $row_in_wanted_table = eval("\$row_in_parent_table->$1");
                    if ($@) { die "Eval of row->$1 failed"; }
                    $col_id = $2;
                }
            }
            if ($col->{id} =~ m{\.OBJECT$}) { # called from stash_infoboxes and requesting the relationship be updated by id
                my $foreign_model = $col->{model}; # filled-in by new() above
                $col->{id} =~ m{(\w+)\.OBJECT$};
                my $rel = $1;
                #warn "Fetching id $new_value from $foreign_model to update $rel";
                (my $new_foreign_row) = $c->model($foreign_model)->find($new_value);
                die "Row for new relationship setting not found" if (!ref $new_foreign_row);
                $row_in_parent_table->update_from_related($rel, $new_foreign_row);
            }
            else {
                if (defined $col->{type}) {
                    eval "\$new_value = \&CatalystX::ListFramework::Helpers::Types::inverse$col->{type}(\"$new_value\", \$c, \$self->{formdef})";
                    if ($@) {die "Type-helper call failed: $@";}
                }
                # Do the update
                eval("\$row_in_wanted_table->$col->{field}(\$new_value); \$row_in_wanted_table->update;");
                if ($@) { die "Error while updating row: $@"; }
            }
        }
    }
}

sub create_new {
    my ($self, $columnvalues, $dont_set_rels) = @_;
    my $c = $self->{c};
    my $columns = $self->{formdef}->{columns};
    my $relationships = $self->{formdef}->{uses};
    
    # Do the create(). Use default_value if specified in a column hash, and set 'belongs_to's to the 1st row out of the hat.
    my $create_hash = $columnvalues;
    foreach my $col (keys %$columns) {
        if (defined $columns->{$col}->{default_value} && !$columnvalues->{$columns->{$col}->{field}}) { # i.e. if not sent in @_
            $create_hash->{$columns->{$col}->{field}} = $columns->{$col}->{default_value};
        }
    }
    
    my $new_obj = $c->model($self->{formdef}->{model})->create($create_hash);
    # warn '*** INSERT finished ***';    
    foreach my $rel (keys %$relationships) {
        my $formobj = __PACKAGE__->new($relationships->{$rel}, $c);
        my ($foreign_row) = $c->model($formobj->{formdef}->{model})->first;
        $new_obj->update_from_related($rel, $foreign_row) unless ($dont_set_rels);
    }
    
    # Get the ID of what we just INSERTed
    my $pk = $columns->{OBJECT}->{primary_key};
    my $new_obj_id;
    eval "\$new_obj_id = \$new_obj->$pk";
    if ($@) { die "Error getting primary key '$pk' of new insert: $@"; }
    return $new_obj_id;
}

sub delete_row {
    my ($self, $rowid) = @_;
    my $c = $self->{c};
    my ($row) = $c->model($self->{formdef}->{model})->find($rowid);
    $row->delete();
}

sub create_search_widget {  # creates an HTML::Widget::Result, as we call ->process($c->req)
    my ($self, $prefix, $c) = @_;
    my $w = HTML::Widget->new('searchform')->method('get');  # method isn't actually used
    $w->element_container_class('CatalystX::ListFramework::SearchformElementContainer');
    my @search_ids = map { $_->{id} } (@{$self->{formdef}->{search}});
    
    my %fieldtypes;  # to hold the column's 'type' setting
    
    foreach my $s_id (@search_ids) {
        my $col = $self->get_searches_entry_from_id($s_id);
        # warn Dumper $col;
        if ($col->{html_type} eq 'Textfield') {
            $w->element('Textfield', "${prefix}search-$col->{id}")->label($col->{heading})->size(10);
            $fieldtypes{"${prefix}search-$col->{id}"} = $col->{type};
        }
        elsif ($col->{html_type} eq 'Textarea') {
            $w->element('Textfield', "${prefix}search-$col->{id}")->label($col->{heading})->size(10);
        }
        elsif ($col->{html_type} eq 'Select') {
            $w->element('Select', "${prefix}search-$col->{id}")->label($col->{heading})->size(1)->options(%{$col->{options}});
        }
    }

    my $hwr = $w->process($c->req);
   # warn Dumper $hwr;
    return ($hwr, \%fieldtypes);
}

sub get_listing_columns {
    my ($self, $view) = @_;
    confess if (!$view);
    return @{$self->{formdef}->{display}->{$view}};
}

sub stash_json_autocomplete {
    my ($self, $query, $id_field, $show_field, $restrict) = @_;

    my $searchcol = $show_field;
    if ($show_field eq 'OBJECT') {
        # Normally we'd search on this field, but OBJECT isn't a DB column so search on $id_field and hope the
        # "" overloading includes the ID somewhere in the stringification
        $searchcol = $id_field;
    }

    $searchcol =~ s/.+\.(\w+\.\w+)/$1/;

    my $join_arg = $self->join_arg_from_columns([ { id=>$show_field }, { id=>$id_field } ]);

    my $c = $self->{c};    
    my @results = $c->model($self->{formdef}->{model})->search(
      { 
        $searchcol => { 'like', '%'.$query.'%' },
        %$restrict,
      },
      {
        #distinct => 1,                           # This and
        #columns => [ keys %select_columns ],     # this doesn't work, as we need extra cols to resolve multi-level relationships
        group_by => [$searchcol],
        join => $join_arg,
      },
    );

    foreach ($id_field, $show_field) {
        s/\./->/g;
    }        
    
    my $res = [map {
                     {
                       id    => eval("\$_->$id_field"),
                       value => eval("\$_->$id_field"),
                       name  => ($show_field eq 'OBJECT')?("$_"):(eval("\$_->$show_field")),  # if we're picking an object, just "" it
                     }
                   } (@results)];

    $c->stash->{results} = $res;
    $c->stash->{count} = scalar(@results);
                               
    #warn "AJAX: Got ".scalar(@results)." hits";
    #warn "$id_field : $show_field ";
    #warn eval("\$results[0]->$id_field");
    #warn Dumper($res);
}   

use Template::Stash;
# Ignore these; they're just for Dragonstaff. They're here rather than in Helpers.pm so the template gets to choose.
# TODO: move these into their own .pm
$Template::Stash::SCALAR_OPS->{'moneyformat'} = sub {
    my $thing = shift;
    return "" if (!length($thing));
    $thing = sprintf('%.2f', $thing);
    return $thing;
};

$Template::Stash::SCALAR_OPS->{'money4format'} = sub {
    my $thing = shift;
    return "" if (!length($thing));
    $thing = sprintf('%.4f', $thing);
    return $thing;
};


1;

=head1 BUGS

Probably many, and many areas are in need of further work.
See all the TODO tags within the code.
Please feel free to email me with comments or patches.

Something somewhere between SQLite and DBIx::Class is buggy when it comes to row updates.
You will see TT error screens on the demo app about "too many rows updated". This goes away if you refresh
and is fine with a real DB like MySQL.

=head1 AUTHOR

Andrew Payne C<< <andrew@dragonstaff.com> >>.

=head1 COPYRIGHT

This module is Copyright (C) 2007 Dragonstaff Ltd and is licensed under
the same terms as Perl itself.