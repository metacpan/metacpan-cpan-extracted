package Class::DBI::Plugin::FilterOnClick;

use base qw( Class::DBI::Plugin );

our $VERSION = 1.2;

use strict;
use warnings;
use HTML::Table;
use HTML::Strip;
use HTML::FillInForm;
use CGI::FormBuilder;
use Tie::Hash::Indexed;
use CGI qw/:form/;
use Class::DBI::AsForm;
use Data::Dumper;
use URI::Escape;
use Config::Magic;

our $cgi = CGI->new();
our $config_hash = {};

our @allowed_methods = qw(
rows
exclude_from_url
display_columns
cdbi_class
page_name
descending_string
ascending_string
mouseover_bgcolor
mouseover_class
no_form_tag
no_mouseover
no_reset
no_submit
debug
searchable
rowclass
rowclass_odd
rowcolor_even
rowcolor_odd
filtered_class
navigation_list
navigation_column
navigation_style
navigation_alignment
page_navigation_separator
navigation_separator
hide_zero_match
query_string
data_table
form_table
order_by
hidden_fields
auto_hidden_fields
config_file
use_formbuilder
search_exclude
);

# field_to_column

sub output_debug_info : Plugged {
    my ($self,$message,$level) = @_;
    $level ||= $self->debug();
    return undef if $level == 0;
    if ($level == 2) {
        print "$message\n";
    }
    
    if ($level == 1) {
        warn "$message\n";
    }
}

sub allowed_methods : Plugged {
    return @allowed_methods;
}

sub read_config : Plugged {
    my ($self,$config_file) = @_;
    # my $config = Config::Auto::parse($config_file);
    my $config_reader = Config::Magic->new($config_file);
    my $config = $config_reader->parse();

    
    $config->{config_file} = $config_file;
    foreach my $config_key (keys %{$config}) {
        next if !grep /$config_key/ , @allowed_methods;
        next if !defined $config->{$config_key};
        # change ~ to space
        $config->{$config_key} =~ s/~/ /g;
        $config->{$config_key} =~ s/[\r\n]+$//;
        $self->output_debug_info( "assigning: $config_key" );
        if ($config->{$config_key} =~ /\|/) {
            my @values = split(/\|/,$config->{$config_key});
            $config->{$config_key} = \@values;
        }
        #if ($config_key eq 'debug') {
        #    $debug = $config->{$config_key};
        #} else {
            $self->$config_key($config->{$config_key});
        #}
    }
    
    
    
    $self->output_debug_info( Dumper($config) );
}

sub html : Plugged {
    my ($class,%args) = @_;
    $class->filteronclick(%args);
}

sub filteronclick : Plugged {
    my %args;
    tie %args, 'Tie::Hash::Indexed';
    my ( $class ) = shift;
    %args = @_;

    my $self = bless {
    }, $class;

    # default to 0 for the debug level
    $self->debug(0);
    
    if (ref $args{-field_to_column} eq 'HASH') {
        tie %{$self->{'field_to_column'}}, 'Tie::Hash::Indexed';
        %{$self->{'field_to_column'}} = %{$args{-field_to_column}};
    }

    if (defined $args{-config_file}) {
        # add code for configuration file based settings
        $self->output_debug_info( "conf = $args{-config_file}" );
        $self->read_config( $args{-config_file} );
    }
    
    if (defined $args{-params}) {
        if (ref $self->exclude_from_url() ne 'ARRAY' &&
                defined $args{-exclude_from_url}) {
            $self->exclude_from_url( $args{-exclude_from_url} );
        }
        $self->params($args{-params});
        $self->search_ref();
        $self->url_query();
        unless (defined $args{-no_hidden_fields}) {
            $self->hidden_fields( $self->params() );
        }
    }
    # $config_hash = $config;
    my $rows = $args{-rows} || $self->rows() || 15;
    if ($rows) {
        $self->on_page($args{-on_page});
        $self->pager_object($self->pager($rows,$args{-on_page}));
    }
    
    # end code for configuration based settings
    
    # create some common items for later use
    my $find_columns = $args{-display_columns} ||
                    $self->config('display_columns') ||
                    $self->field_to_column();
    $self->display_columns($self->determine_columns($find_columns));
    $self->query_string_intelligence();
    $self->create_order_by_links();
    
    $self;
}

=head1 NAME

Class::DBI::Plugin::FilterOnClick - Generate browsable and searchable HTML Tables using FilterOnClick in conjunction with Class::DBI

=head1 SYNOPSIS

 # Inside of your sub-class ("package ClassDBIBaseClass;" for example)
 # of Class::DBI for use with your database and
 # tables add these lines:
 
 use Class::DBI::Plugin::FilterOnClick;
 use Class::DBI::Plugin::Pager;
 use Class::DBI::AbstractSearch;
 use Class::DBI::Plugin::AbstractCount;
 use Class::DBI::Plugin::RetrieveAll;
 
 # the rest of your CDBI setup to follow  
 .....
   
 # Inside your script (separate from your Class::DBI setup file) you will be
 # able to use this module's methods on your table class or object as needed.

 # use the package/module created above
 use ClassDBIBaseClass;
 
 # include URI::Escape for some parameters clean up
 use URI::Escape;
 
 # we are using CGI in this example, but you can use Apache::ASP, Embperl, etc.
 use CGI;
 
 my $cgi = CGI->new();
 
 my %params;

 # clean up and create our parameters to be passed to FilterOnClick
 map { $params{$_} = 
       uri_unescape($cgi->param("$_"))
    } $cgi->param();

 # create our FilterOnClick object
 my $filteronclick = Baseball::Master->filteronclick( 
                                   -config_file => '/srv/www/cgi-bin/baseball.ini',
                                   -rows    => $cgi->param('rows') || 15 ,
                                   -on_page => $cgi->param('page') || 1,
                                   -params => \%params );

 $filteronclick->field_to_column(
    lastname   => 'Last Name' . $html->order_by_link('lastname'),
    firstname  => 'First Name' . $html->order_by_link('firstname'),
    bats       => 'Bats',
    throws     => 'Throws',
    ht_ft      => 'Height Ft',
    ht_in      => 'In',
    wt         => 'Weight',
    birthyear  => 'Birthyear',
    birthstate => 'Birthstate',
    _FilterOnClickCustom1_ => 'Other Data',
    _FilterOnClickCustom2_ => 'More Data'
                       );
                       
 
 $filteronclick->data_table->addRow(
                    'Last Name',
                    'First Name',
                    'Bats' ,
                    'Throws' ,
                    'Height (ft)',
                    '(inches)',
                    'Weight',
                    'Birth Year' );

 $filteronclick->params( $cgi->Vars; );    
 $filteronclick->exclude_from_url([ 'page' ]);

 # indicate which columns to exclude, inverse of display above
 # can be set in config file as well
 $filteronclick->exclude_columns();
    
 # indicate the base class to work with, this is optional,
 # if you should create you object via a call to
 # Class::DBI::Plugin::FilterOnClick vs. a Class::DBI sub class
 # this assures the correct sub class is used for data collection
 
 $filteronclick->cdbi_class( 'Baseball::Master' );
    
 # indicate the style of navigation to provide
 $filteronclick->navigation_style( 'both' );
    
 print qq~<fieldset><legend>Filter by First Letter of Last Name</legend>~;

 print $filteronclick->string_filter_navigation(
    -column       => 'lastname',
    -position     => 'begins',
 );

 print qq~</fieldset>~;

 $filteronclick->only('firstname');
  

 print $filteronclick->build_table(
  
    _FilterOnClickCustom1_ => sub {
        my $pid = shift; # pid = Primary ID of the record in the base table
        my @status_objects = Baseball::Allstars->search(lahmanid => $pid);
        if (@status_objects) {
            my $years;
            foreach my $st (@status_objects) {
                $years .= $st->year() . " ";
            }
            return $years;
        }
        return 'NA';
    },
    
    _FilterOnClickCustom2_ => sub {
        my $pid = shift; # pid = Primary ID of the record in the base table
        my @status_objects = Baseball::Allstars->search(lahmanid => $pid);
        if (@status_objects) {
            my $teams;
            foreach my $st (@status_objects) {
                $teams .= $st->team() . " ";
            }
            return $teams;
        }
        return 'NA';
    },
  );

 my $nav = $filteronclick->html_table_navigation();

 print qq!<div algin="center">$nav</div>\n!;

 $filteronclick->add_bottom_span($nav);
     
 print $filteronclick->data_table;

=head1 UPGRADE WARNING

If you are using Class::DBI::Plugin::HTML or a pre version 1
Class::DBI::Plugin::FilterOnClick you will need to alter your code to support
the new style used in version 1 and greater releases.

Version 1.1 uses Class::DBI::Plugin::Pager, you will need to alter your base
class to reflect this change.  In other words the use of Class::DBI::Pager is
no longer allowed.  This was done for an improvement in performance.

=head1 DESCRIPTION

The intention of this module is to simplify the creation of browsable and
searchable HTML tables without having to write the HTML or SQL, either in your 
script or in templates.

It is intended for use inside of other frameworks such as Embperl,
Apache::ASP or even CGI.  It does not aspire to be its own framework.
If you are looking for a frameworks which allow using Class::DBI I suggest you
look into the Maypole or the Catalyst module.

See FilterOnClick below for more on the purpose of this module.

Tables are created using HTML::Table. The use of HTML::Table was selected
because it allows for several advanced sorting techniques that can provide for
easy manipulation of the data outside of the SQL statement.  This is very useful
in scenarios where you want to provide/test a sort routine and not write
SQL for it.  The more I use this utility the less likely it seems that one would
need to leverage this, but it is an option if you want to explore it.

Feedback on this module, its interface, usage, documentation etc. is
welcome.

=head1 FilterOnClick

FilterOnClick is a process for allowing database filtering via an HTML table.
Within a script, filters are predefined based on the type of data and the users
desired interaction with the data.  When users click on an item in the table it
filters (or unfilters if the value had used to filter previously) the records
displayed to match the associated filter. Filters can be applied and unapplied
in almost any order. In addition to filtering FilterOnClick also allows for
ordering the data.

The concept at its core is relatively simple in nature.  You filter the results
in the table by clicking on values that are of interest to you. Each click turns
on or off a filter, which narrows or expands the total number of matching records.
This allows for identifying abnormal entries, trends, or errors, simply by paging,
searching or filtering through your data.  If you configure the table appropriately
you can even link to applications or web pages to allow editing the records.

An example FilterOnClick session would consist of something like this:
You get a table of records, for our example lets assume we
have four columns: "First Name" aka FN, "Last Name" aka LN , "Address" ,
and "Email".  These columns are pulled from the database and placed
into an HTML table on a web page.  The values in the FN , LN and Email 
address columns are links back to the script that generated the original
table, but contain filter information within the query string.
In other words the link holds information that will modify the SQL query
for the next representation of data.  

Presently there are six (6) built in filter types for within tables and
three (3) more that are specific to string based matches outside of the table
itself. (see string_filter_navigation method below for info on the second three)

The six html table level filters are 'only','contains','beginswith','endswith'
'variancepercent','variancenumerical'. The where clause is 
created within FilterOnClick automatically through the
Class::DBI::AbstractSearch module. You are not required to create any SQL
statements or add any code to your Class::DBI base class for simple database
structures.

Back to the example at hand.  Lets say the database has 20K records and
the sort order was set to LN by default. The FN column has been configured with
an 'only' filter. In the FN list you see the FN you are looking for so you click
on it, when the script runs and auto-generates a new filter (query) that now
only shows records that match the FN you clicked on.
Clicking on the FN column a second time removes the filter.

Filters are cascading, allowing you to filter on multiple columns.
So if you want to find all the 'Smith's' with email
addresses like 'aol.com' you could click first on an email address
containing 'aol.com' and then a last name of 'Smith', provided you
configured a proper filter code for the table.

If the searchable option has been enabled you can also perform text based
searched on any column.

You can see FilterOnClick in action at:
http://cdbi.gina.net/cdbitest.pl (user: cdbi password: demo)

Example code to create a FilterOnClick column value ( see the build_table method ):

Match Exactly

  $filteronclick->only('column_name');
  
  # within the build_table method you can do this
  column_name => 'only'

Match Beginning of column value with string provided

  $filteronclick->beginswith('column_name' , 'string');

Match ending of column value with string provided

  $filteronclick->endswith('column_name , 'string');

Filter to columns that contain a particular string (no anchor point)

  $filteronclick->contains('column_name' , 'string'); 

Show records with a numerical variance of a column value

  $filteronclick->variancenumerical('column_name' , number);

Show records with a percentage variance of a column value

  $filteronclick->variancepercent('column_name' , number);


=head1 CONFIGURATION FILE

As of version .9 you can assign many of the attributes via a configuration file
See the t/examples directory for a sample ini file

=head1 METHOD NOTES

The parameters are passed in via a hash, arrayref or scalar for the methods.
The Class::DBI::Plugin::FilterOnClick specific keys in the hash are preceeded
by a hypen (-).  The build_table method allows for column names to be passed
in with their own anonymous subroutine (callback) if you need to produce any
special formating or linkage. Column name anonymous subroutines should NOT
begin with a hypen.

=head1 METHODS

=head2 filteronclick

Creates a new Class::DBI::Plugin::FilterOnClick object

    $filteronclick = ClassDBIBase::Class->filteronclick();

=head2 debug

Wants: 0, 1 or 2

Defaults to: 0

Valid in Conifguration File: Yes

Set to one to turn on debugging output.  This will result in a considerable amount
of information being sent to the browser output so be sure to disable in production.
Can be set via method or configuration file. If set to 1 it will print debug
data via 'warn' if set to 2 it will print debug data via 'print'

    $filteronclick->debug(1);

=head2 params

Wants: Hash reference of page paramters

Defaults to: {} (empty hash ref)

This should be passed in via the filteronclick method as -params to allow
auto generation of various attributes, this documentation is provided for those
that want to handle various stages of the build process manually.

Set the params that have been passed on the current request to the page/script

    $filteronclick->params( {
        param1 => 'twenty'
    } );
    
Using CGI

    use URI::Escape;
    my %params;

    map { $params{$_} =
           uri_unescape($cgi->param("$_"))
        } $cgi->param();

    $filteronclick->params( \%params );
    
Using Apache::ASP

    $filteronclick->params( $Request->Form() );
    
Using Embperl

    $filteronclick->params( \%fdat );

=head2 config

Wants: configuration key, value is optional

Defatuls to: na

Configuration values can be accessed directly or via the config method. This is
allowed so you know where the value you are calling is being assigned from.

To get get a value:

    $filteronclick->config("searchable");

To set a value do this:

    $filteronclick->config('searchable',1);


=head2 exclude_from_url

Wants: Array reference

Defaults to: [] (emptry array ref)

Key/value pair to be removed from auto generated URL query strings. The key for
the page should be one of the items here to avoid navigation issues

    $filteronclick->exclude_from_url( [ 'page' ] );

=head2 form_table

Wants: HTML::Table object

Defaults to: HTML::Table object

Returns: HTML::Table object

    $filteronclick->form_table(); # get current form table object
    $filteronclick->form_table($html_table_object); # set form table object

There is no need to set this manually for simple forms. This method is a lingering
item and may be removed in future releases. If you use it please inform the author.

=head2 field_to_column

Wants: Hash

Defaults to: empty

    $filteronclick->field_to_column(
        'firstname' => 'First Name',
        'lastname' => 'Last Name'
    );

=head2 cdbi_class

Wants: string

Defaults: n/a

Returns: current value

Sets or returns the table class the HTML is being generated for
    
    $filteronclick->cdbi_class();

=head2 config_file

Returns the name of the config_file currently in use

=head2 rows

Wants: Number

Defaults to: 15

Sets the number of rows the table output by build_table will contain per page

    $filteronclick->rows(20);

=head2 html_table

Wants: HTML::Table object

Defaults to: HTML::Table object

This is useful if you want to either create your own HTML::Table object and
pass it in or you want to heavily modify the resulting table from build_table.
See the L<HTML::Table> module for more information.

=cut

sub html_table : Plugged {
    my ( $self, %args ) = @_;
    my $new_table = HTML::Table->new(%args);
    $self->data_table( $new_table );
    $self->form_table( $new_table );
}

=head2 build_table

Wants: Hash

Defatuls to: na

Returns: HTML::Table object

Accepts a hash of options to define the table parameters and content.  This method
returns an HTML::Table object. It also sets the data_table method to the HTML::Table
object generated so you can ignore the return value and make further modifications
to the table via the built in methods.
   
See Synopsis above for an example usage.

The build_table method has a wide range of paramters that are mostly optional.

=head2 exclude_columns

Wants: Arrary reference

Defaults to: na

Valid in configuration File: Yes

Returns: When called with no argument, returns current value; an array ref

Removes fields even if included in the display_columns list.
Useful if you are not setting the columns or the columns are dynamic and you
want to insure a particular column (field) is not revealed even if someone adds
it somewhere else.

=head2 extend_query_string

Wants: hash of key and values to add

Defaults to: na

Valid in configuration File: No

Returns: Current query string + the arguments passed in

Adds elements to the query string to allow for creating custom predefined
links with the current filter options applied.

=head2 data_table

Wants: HTML::Table object

Defaults to: na

Returns: HTML::Table object is assigned

Allows for you to pass in an HTML::Table object, this is handy
if you have setup the column headers or have done some special formating prior to
retrieving the results. 

=head2 pager_object

Wants: Class::DBI::Pager object

Defaults to: Class::DBI::Pager object

Returns: Current pager_object

Allows you to pass in a Class::DBI::Pager based object. This is useful in
conjunction with the html_table_navigation method.  If not passed in
and no -records have been based it will use the calling class to perform the
lookup of records.

As of version .9 you do not need to assign this manually, it will be auto
populated when call to 'filteronclick' is made.

=head2 records

Wants: Array reference

Defaults to: na

Returns: present value

Expects an anonymous array of record objects. This allows for your own creation
of record retrieval methods without relying on the underlying techniques of the
build_table attempts to automate it. In other words you can send in records from
none Class::DBI sources, but you lose some functionality.

=head2 where

Wants: Hash reference

Defaults to: Dynamically created hash ref based on query string values, part of
the FilterOnClick process.

Expects an anonymous hash that is compatiable with Class::DBI::AbstractSearch

=head2 order_by

Wants: scalar

Returns: current value if set

Passed along with the -where OR it is sent to the retrieve_all_sort_by method
if present.  The retrieve_all_sort_by method is part of the
L<Class::DBI::Plugin::RetrieveAll> module.

=head2 page_name

Wants: scalar

Returns: current value if set

Valid in Configuration file: Yes

Used within form and querystring creation.  This is the name of the script that
is being called.

=head2 query_string

Wants: scalar

Returns: current value if set

It is not required to set this, it is auto generated through the FilterOnClick
process. This method is generally used for debugging.

=head2 rowcolor_even

Wants: Valid HTML code attribute

Defaults to: '#ffffff'

Returns: Current value if set

Valid in Configuration file: Yes

Define the even count row backgroud color

=head2 rowcolor_odd

Wants: Valid HTML code attributes

Defaults to: '#c0c0c0'

Valid in Configuration file: Yes

Define the odd count row backgroud color

=head2 rowclass


Valid in Configuration file: Yes

(optional) - overrides the -rowcolor above and assigns a class (css) to table rows

=head2 no_mouseover

Valid in Configuration file: Yes

Turns off the mouseover feature on the table output by build_table

=head2 mouseover_class


Valid in Configuration file: Yes

The CSS class to use when mousing over a table row

=head2 searchable


Valid in Configuration file: Yes

Enables free form searching within a column

=head2 search_exclude

Wants: arrayref of column names to not allow searching on

Defaults to: []

Returns: current columns to not allow searching for when called without parameters,
returns nothing when new values are passed in.

list of columns that should allow for searching if searchable is set to 1

=head2 mouseover_bgcolor


Valid in Configuration file: Yes

Color for mouseover if not using a CSS definition. Defaults to red if not set

=head2 filtered_class

Valid in Configuration file: Yes

Defines the CSS class to use for columns that currently have an active Filter

=head2 ascending_string

Wants: string (can be image name)

Default to: '^'

Valid in Configuration file: Yes

The string used to represent the ascending sort filter option. If value ends
with a file extension assumes it is an image and adds approriate img tag.

=head2 descending_string

Wants: string (can be an image name)

Defaults to: 'v'

Valid in Configuration file: Yes

The string used to represent the descending sort filter option. If value ends
with a file extension assumes it is an image and adds approriate img tag.

=head2 rowclass_odd

Valid in Configuration file: Yes

The CSS class to use for odd rows within the table

=head2 navigation_separator

Valid in Configuration file: Yes

The seperator character(s) for page navigation

=head2 page_navigation_separator

Valid in Configuration file: Yes

The seperator for page navigation

=head2 table field name (dynamic method)

(code ref || (like,only) , optional) - You can pass in anonymous subroutines for
a particular field by using the table field name (column). Three items are
passed back to the sub; value of the column in the database, current url, and
the entire database record as a Class::DBI result object.

Example:
    
    first_name => sub {
       my ($name,$turl,$record) = @_;

       my $extra = $record->other_column();                         

       return qq!<a href="test2.pl?$turl">$name - $extra</a>!;
    },

=cut

sub determine_columns : Plugged {
    my ($self,$columns) = @_;
    my $class;
    
    if ( !$self->isa('Class::DBI::Plugin') ) {
        $class = $self;
    } else {
        $class = $self->cdbi_class();
    }
    
    my @columns;
    if (ref $columns eq 'ARRAY') {
        @columns = @{ $columns };
        return @columns;
    }
    
    if ( !@columns && ref $self->display_columns() eq 'ARRAY' ) {
        @columns = @{ $self->display_columns() };
        return @columns;
    }
    
    if ( !@columns && ref $self->field_to_column() eq 'HASH' ) {
        @columns = keys %{$self->field_to_column()};
        return @columns;
    }
    
    if ( !@columns ) {
        @columns = $class->columns();
        return @columns;
    }
    
    return undef;
    
}

sub create_auto_hidden_fields : Plugged {
    my ($self) = @_;
    my $hidden = $self->params() || {};
    my $hidden_options;
    foreach my $hidden_field ( keys %{ $hidden } ) {
            next if $hidden_field !~ /\w/;
            $hidden_options .=
qq!<input name="$hidden_field" type="hidden" value="$hidden->{$hidden_field}">!;
    }
    $self->auto_hidden_fields($hidden_options);
}

sub filter_lookup : Plugged {
    # determines the level of match on a particular filter
    my ($self,$args) = @_;
    my %args = %{ $args };
        foreach ('-type','-value','-column','-base') {
        $args{$_} ||= '';
    }
    if (defined $args{-type}) {
        my %in = ();
        if ( ref $self->current_filters() eq 'HASH') {
            %in = %{ $self->current_filters() };
        } else {
            return 0;
        }

        $self->output_debug_info("<pre>" . Dumper(\%in) . "</pre>");
        $self->output_debug_info("<pre>" . Dumper(\%args) . "</pre>");
        if (scalar(keys %in) > 0) {
        foreach (keys %in) {
            if (
                lc($in{$_}{column}) eq lc($args{-column})
                && $in{$_}{type}    eq    $args{-type}
                && $in{$_}{base}    eq    $args{-base}
                && $in{$_}{value}   eq    $args{-value}
                ) {
                return 3;
            } elsif (
                lc($in{$_}{column}) eq lc($args{-column})
                && $in{$_}{type}    eq    $args{-type}
                && $in{$_}{base}    eq    $args{-base}
                ) {
                return 2;
            } elsif (lc($in{$_}{column}) eq lc($args{-column})
                && $in{$_}{type} eq $args{-type}) {
                return 1;
            }
        }
        }
        
    }
    
    return 0;
}

sub build_query_string : Plugged {
    
    # there are five conditions that need to be meet
    # Condition 1 - Link with existing items from last query
    # Condition 2 - Existing items minus current column if already filtered
    # Condition 3 - Existing items plus ORDERBYCOL (minus existing ORDERBY if applicable)
    # Condition 4 - Existing items plus additional item if sent in, but only if
    #               not currently in query_string
    # Condition 5 - Existing items plus string navigation, but also exclude
    #               correctly if it was already in the list of links
    
    my ($self,%args) = @_;
    foreach ('-type','-value','-column','-base') {
        $args{$_} ||= '';
    }
    $args{-string_navigation} ||= 0;
    $self->output_debug_info("<br><b>Building a QUERY_STRING</b><br>");
    my $query_string = $self->query_string() || '';

    my $single = $args{-single} || 0;

    my %in = ();
    

    # create a variable to track if we have active filters, possibly simpler
    # then a hash check

    my $active_filters = 0;

    # check to see if the current filters exist, assign to %in if they do
    if ( ref $self->current_filters() eq 'HASH') {
        %in = %{ $self->current_filters() };
    }

    my @existing_strings = ();
    if (scalar(keys %in) > 0) {
    foreach my $key (reverse sort keys %in) {
        push @existing_strings, $in{$key}{type} . $in{$key}{value} . '-' .
                         $in{$key}{column} . "=" .
                         $in{$key}{base};
    }
    }
    # set our active filters to true if we have keys in our %in hash
    my $query_string_match = 0;

    if ($args{-type} =~ /(WITH|CONTAINS)$/i && !defined $args{-value} ) {
        %args = (); 
    }

    if (scalar(keys %in) > 0) {
        $active_filters = 1;
        if ( defined $args{-type} ) {
            $query_string_match = $self->filter_lookup(\%args);
        }
    }
    
    # rewrite of logic started on 5-20-2007
    # rethink everything

    # create a link based on the arguments passed in, this most likely
    # will most likely not be used, or that is the assumption anyway
    my $args_string = $args{-type} .
                 $args{-value} .
                 '-' .
                 $args{-column} .
                 "=" .
                 $args{-base};
    
    # create an empty array to house our link strings
    my @string = ();
    
    my $skip;
    
    # determine our current column being worked on
    my $column = $args{-column} || $self->current_column();
    
    # lower case the column for "safety"
    $column = lc($column);
    
    # here is how the method is called
    #    my $link = $self->build_query_string(-column => $column,
    #                                     -value  => $args{-value},
    #                                     -type   => $type,
    #                                     -base   => $link_val,
    #                                     -single => $args{-single} || 0
    #                                     );
    
    my %strings = ();
    my %short_strings = ();
    # number 1 lets create the args based extension if applicable
    if ( defined $args{-type} ) {
               
        my $alt_string;

        if ($single == 1 && $query_string_match < 3) {
            # single means we only want one link in the URL
            return $args_string;
        }

       if ( $query_string_match == 0 || $query_string_match == 1 || $args{-string_navigation} == 1) {
            $strings{$args_string}++;
            $in{'9999'}{column} = $args{-column} || '';
            $in{'9999'}{type}   = $args{-type}   || '';
            $in{'9999'}{value}  = $args{-value}  || '';
            $in{'9999'}{base}   = $args{-base}   || '';
            
       }

    }

    if ($active_filters) {
        
        foreach my $key (reverse sort keys %in) {

            my $type_and_value = $in{$key}{type} . $in{$key}{value};

            if ($self->url_query() =~ /$column/ && $in{$key}{column} eq $column) {
                next;
            }

            my $string = $in{$key}{type} . $in{$key}{value} . '-' .
                         $in{$key}{column} . "=" .
                         $in{$key}{base};
            next if defined $strings{$string} && exists $strings{$string};
            my $short_string = $in{$key}{type} . $in{$key}{column};

            
            $strings{$string}++;
            $short_strings{$short_string}++;
            next if ($strings{$string} > 1 || $short_strings{$short_string} > 1)
                    && $in{$key}{type} !~ /begins|ends/i;

        }
    }    

    my $out = join('&',keys %strings);
    $self->output_debug_info("<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<b>In lower section - $column - $out</b><br>");
    #if (!$single) {
        my @count = $out =~ /ORDERBYCOL-(\w+)\=(ASC|DESC)/g;
        if (scalar(@count) > 2) {
            $out =~ s/ORDERBYCOL-(\w+)\=(ASC|DESC)//;
        }
    #}
    return $out;


}

sub query_string_intelligence : Plugged {
    # method will help deduce what should be done with
    # an incoming query string

    my ($self,%args) = @_;
    my $query_info;
    my $order_by;
    my $query_string   = $args{-query_string}    || $self->query_string();
    my %out = ();
    
    # break it into parts
    my %working = %{$self->params};
    
    my $base;
    my $count;
    foreach my $key (keys %working) {
        $count++;
        $self->output_debug_info( "Looking at: $key" );
        my $front = $key;
        $front =~ s/-(\w+)$//;
        my $column = $1;
        # look for =1 commands
        # if ($working{$key} == 1 || $key =~ /VARIANCE/) {
        if ($key =~ /CONTAINS|BEGINSWITH|ENDSWITH|VARIANCE/) {
            # CONTAINS00-price
            # $self->output_debug_info( "Silly Test!" );
            my $base = $working{$key};
            my ($type,$null,$value) =
                $front =~ /(CONTAINS|BEGINSWITH|ENDSWITH|VARIANCE(NUMERICAL|PERCENT))(\w+)/;
                $self->output_debug_info( "$type,$value,$column,$base" );
            if ($type) {
                $out{$count} = {
                                 type   => $type   || '',
                                 value  => $value  || '',
                                 base   => $base   || '',
                                 column => $column || '',
                                };
            }
            next;
        }
        
        if ($front =~ /(only|orderbycol)/i) {
            my $type = uc($front);
                        $out{$count} = {
                                 type   => $type          || '',
                                 base   => $working{$key} || '',
                                 column => $column        || '',
                                 value  => '',
                                 # value => $value,
                                };
            $self->output_debug_info( "$type,$column" );
        }
        
    }
    
    $self->current_filters(\%out);
}

sub colorize_value : Plugged {
    my ($self,$col,$text) = @_;
    #print "working on $col with $text\n";
    #sleep 2;
    if (defined $self->{column_value_colors}{$col} &&
        $text =~ /$self->{column_value_colors}{$col}[0]/ ) {
        
        $text = $cgi->span({
                            -class => $self->{column_value_colors}{$col}[1]},
                           $text
                          );
    }
    return $text;
}

sub build_table : Plugged {
    
    my ( $self, %args ) = @_;
    
    my $table        = $args{-data_table}           || $self->data_table();
    if (!$table || !$table->isa( 'HTML::Table' ) ) {
         $table = HTML::Table->new();
         $self->data_table($table);
    }
    my $table_obj      = $args{-pager_object}    || $self->pager_object();
    my $page_name      = $args{-page_name}       || $self->page_name();
    my $query_string   = $args{-query_string}    || $self->query_string();
    my $exclude        = $args{-exclude_columns} || $self->exclude_columns() || 0;
    my $where          = $args{-where}           || $self->where();
    my $order_by       = $args{-order_by}        || $self->order_by();
    my $filtered_class = $args{-filtered_class}  || 'filtered';
    my $search         = $args{-searchable}      || $self->searchable || 0;
    my $find_columns   = $args{-display_columns} || $self->field_to_column();
    my @search_exclude = @{$self->search_exclude()} || ();
    my $primary        = $self->columns('Primary');
    
    my $class;
    
    # order by via query string adjustment
    if ($query_string && $query_string =~ /ORDERBYCOL/) {
        my ($order_col,$direction) = $query_string =~ m/BYCOL\-([\w\_]+)=(\w+)/;
        $order_by = "$order_col $direction"; 
    }
    
    my @columns = $self->determine_columns($find_columns);
    
    if ( !@columns ) {
        warn
          "Array 'columns' was not defined and could not be auto identified\n";
    }
    
    if ( ref($exclude) eq 'ARRAY' ) {
        @columns = $self->_process_excludes( $exclude, @columns );
    }
   
    # create text search row if requested
    if ($search) {
        my @text_fields;
        $self->create_auto_hidden_fields();
        foreach my $col (@columns) {
           # exclude any in the search exclude array
           if (@search_exclude) {
              if ( grep /$col/i , @{$self->search_exclude()} ) {
                  push @text_fields , '';
                  next;
              }
           }
           if ( grep /$col/i , $self->columns() ) {

                if ( ( !$self->search_primary() )
                            && ( lc($col) eq lc($self->columns('Primary') ) ) ) {
                    push @text_fields , '';
                    next;
                }
                push @text_fields ,
                $cgi->start_form( -action => $page_name , -method => "get" ) .
                $cgi->textfield( -name => "SEARCH-$col",
                                -size => 4 ) . $self->auto_hidden_fields() .
                $cgi->submit( -name => '', -value => "GO" ) .
                $cgi->end_form();
                
                #<input type="text" name="SEARCH-$col" value="" size="4">
                #<input type="submit" value="GO">! .
                #$self->auto_hidden_fields() .
                #qq!</form>
                #!;
            } else {
                push @text_fields , '';
            }
	}

	$table->addRow(@text_fields);
        $table->setRowVAlign(-1,'top');
	my $corner = $table->getCell( 1, 1 );
    }
    
    my @records;

    if ( ref $args{-records} eq 'ARRAY' ) {
        @records = @{ $args{-records} };
    }
    else {
	
        # testing based on suggestion from user
        
        if ( ref $where eq 'ARRAY' ) {
           $self->output_debug_info( "Where was an ARRAY" );
           @records = $table_obj->search_where( @{ $where } ); 
        }
    
        elsif ( ref $where ne 'HASH' ) {
            if ( defined $order_by ) {
                $self->output_debug_info( "Where was NOT a HASH and we had an ORDER BY" );
                # @records = $table_obj->retrieve_all_sorted_by( $order_by );
                $table_obj->where($where);
                $table_obj->order_by($order_by);
                @records = $table_obj->search_where();
                
            }
            else {
                
                $self->output_debug_info( "Where was NOT a HASH" );
                @records = $table_obj->retrieve_all();
                
            }

        }
        else {
            $self->output_debug_info( "Last attempt to get records ($where,$order_by)" );
            $table_obj->where($where);
            $table_obj->order_by($order_by);
            @records =
              $table_obj->search_where();
        }

    }
    my $count;

    # define our background colors (even and odd rows)
    my $bgcolor   = $args{-rowcolor_odd}  || $self->rowcolor_odd()  || '#c0c0c0';
    my $bgcolor2  = $args{-rowcolor_even} || $self->rowcolor_even() || '#ffffff';
    
    # define our colors or classes
    my $mouseover_bgcolor = $args{-mouseover_bgcolor}  ||
                            $self->mouseover_bgcolor() ||
                            'red';
    
    my $mouseover_class   = $args{-mouseover_class}  ||
                            $self->mouseover_class() ||
                            '';
    
    # define if we use bgcolor or class to assign color
    my $js_this_object = 'this.bgColor';
    my $bg_over = $mouseover_bgcolor;
    my $bg_out_odd  = $bgcolor;
    my $bg_out_even = $bgcolor2;
    
    if ($mouseover_class) {
        $js_this_object = 'this.className';
        $bg_over = $mouseover_class;
	$args{-rowclass} ||= $self->rowclass() || 'defaultRowClass';
	$args{-rowclass_odd} ||= $self->rowclass_odd() || 'defaultRowClassOdd';
        $bg_out_even = $args{-rowclass};
	$bg_out_odd  = $args{-rowclass_odd};
    }
            
    foreach my $rec (@records) {
        $count++;
        my $pid = $rec->$primary();
        my @row;
        foreach my $working_column (@columns) {
            next if $working_column !~ /\w/;
            $self->current_column($working_column);
            $self->current_record($rec);
            if ($working_column =~ /_FilterOnClickCustom\d+?_/) {
                # do your thing
                if ( ref $args{$working_column} eq 'CODE' ) {
                
                    push @row, $self->colorize_value($working_column,$args{$working_column}->(
                             $pid,
		             $working_column,
			     $query_string,
                             $rec
			     )
                                                );
                }
                next;
            }
            if (!defined $args{$working_column} && defined $self->{column_filters}{$working_column}) {
                # print "$working_column : " . $self->{column_filters}{$working_column} . "\n";
                $args{$working_column} = $self->{column_filters}{$working_column};
            }
            $self->output_debug_info( "col = $working_column" );
            if ( ref $args{$working_column} eq 'CODE' ) {
                $self->output_debug_info("<br>Doing the match where the column on has <b>CODE</b> ref ($working_column)<br>"); 
                # test to add link to CODE columns as well
                if ($query_string && (
                            $query_string =~ /CONTAINS[\w+]\-$working_column=/
                            # SEARCH-price=00&=GO
                            || $query_string =~ /SEARCH-$working_column/
                                     )
                            ) {
                    push @row,
                        $self->add_link(
                            -link_text => $self->colorize_value($working_column,$args{$working_column}->( 
		             $rec->$working_column,
			     $query_string,
                             $rec
                        	     )
                                ),
                            -type => 'CONTAINS'
                        
                                   );
                } else {
                    push @row,  $self->colorize_value($working_column,$args{$working_column}->( 
		             $rec->$working_column,
			     $query_string,
                             $rec
			     )
                        ) 
                }
            }
            elsif ( $args{$working_column} =~ /only|like|beginswith|endswith|contains|variance/i ) {
                $self->output_debug_info("Doing the match where the column on has one value and is not an ARRAY ref ($working_column)<br>");
                push @row,
                  $self->add_link(
                                  -type => $args{$working_column},
                                  -link_text => $self->colorize_value($working_column,$rec->$working_column),
                                 );

            } elsif ( ref($args{$working_column}) eq 'ARRAY' ) {
               $self->output_debug_info("<br>Doing the match where the column on has one value and IS an <b>ARRAY</b> ref ($working_column)<br>"); 
	       my ($type,$value) = @{ $args{$working_column} };
	         my $display_value = $rec->$working_column;
                 
	         push @row,
                            $self->add_link(
                                  -type      => "$type",
                                  -value     => "$value",
                                  -link_text => $self->colorize_value($working_column,$rec->$working_column),
                                  -hardcoded => 1
                                 );
	       
	    }
            else {
                $self->output_debug_info("<br>Doing the match where the column us in the url_query ($working_column)<br>"); 
                if (grep /$working_column/ , $self->cdbi_class->columns() ) {
                    # is the match too agressive?  it includes the character to match, should it?
                    # I content not if the column value is already in the URL
                   if ($self->url_query =~ /(VARIANCE|BEGINSWITH|ENDSWITH|CONTAINS)\w+\-$working_column/) {
                       # my $type = $1;
                       $self->output_debug_info("<b>Trimmed down the regex capture $1</b><br>");
                       push @row, $self->add_link(
                                  -type => $1,
                                  -link_text => $self->colorize_value($working_column,$rec->$working_column),
                                  -hardcoded => 1
                                 );
                   } else {
                       push @row, $self->colorize_value($working_column,$rec->$working_column);
                   }
                }
            }
	    
	    if ($query_string && $query_string =~ /(ONL|VAR|BEGIN|ENDS|CONTAINS)\w+\-$working_column/) {
	       $row[-1] = qq~<div class="$filtered_class">$row[-1]</div>~;
	    } else {
                if (defined $self->{column_css_class}{$working_column}) {
                   
                    $row[-1] = qq~<div class="~ . $self->{column_css_class}{$working_column} .
                    qq~">$row[-1]</div>~;
                }
            }
        }
        $table->addRow(@row);
	
	if ( ($count % 2 == 0) && $args{-rowclass} ne '' ) {
            $table->setRowClass( -1, $args{-rowclass} );
	} elsif ( ($count % 2 != 0) && $args{-rowclass} ne '' ) {
	    $table->setRowClass( -1, $args{-rowclass_odd} );
	} elsif ( ($count %2 == 0) && $args{-rowclass} eq '') {
	    
	    $table->setRowBGColor( -1, $bgcolor2 );

	} elsif ( ($count %2 != 0) && $args{-rowclass} eq '') {
	    
	    $table->setRowBGColor( -1, $bgcolor );
	}
	
        $args{-no_mouseover} ||= $self->no_mouseover();
        
	if (!$args{-no_mouseover}) {
            
	     my $out = $bg_out_odd;
	     if ($count % 2 == 0) {
	         $out = $bg_out_even;
	     }
	     $table->setRowAttr( -1 , 
	          qq!onmouseover="$js_this_object='$bg_over'"
	          onmouseout="$js_this_object='$out'"!);
        }
	
	
	# if defined $args{-rowclass};
    }
    $self->data_table($table);
    return $table;
}

sub add_link : Plugged {

    my ($self,%args) = @_;

    my $type      = $args{-type};
    my $hardcoded = $args{-hardcoded};
    my $name      = $args{-name}  || $args{-link_text};
    my $value     = $args{-value} || '';

    my $column    = $args{-column} || $self->current_column();    
    my $ourl      = $self->url_query();
    my $page_name = $self->page_name();
    my $turl      = $ourl;

    # my $link_text = $name;
    my $hs = HTML::Strip->new();
    my $link_text = $hs->parse( $name );
    $hs->eof;

    my $link_val = $link_text;
    
    $link_val = 1 if $type =~ /like|begin|end|contain/i;

    # add the string to the type if we are doing
    # a begin,end or contain link
    
    if ( $type =~ /begin|end|contain/i && !$hardcoded ) {
         # $type .= $name;
        # $self->output_debug_info("matched begin/end/contain");
    }
    
    # $self->output_debug_info(Dumper(\%args));
    my $link = $self->build_query_string(-column            => $column,
                                         -value             => $args{-value},
                                         -type              => $type,
                                         -base              => $link_val,
                                         -single            => $args{-single} || 0,
                                         -string_navigation => $args{-string_navigation} || 0,
                                         );
    # $self->output_debug_info( " * * * THE LINK: $link" );
    return qq!<a href="$page_name?$link">$name</a>!;
    
}

sub order_by_link : Plugged {
    my ($self,$column_name) = @_;
    return $self->{order_by_links}{$column_name};
}

sub create_order_by_links : Plugged {
     my ($self,%args) = @_;
     
     my $asc_string   = $args{-ascending_string}  || 'v';
     my $desc_string  = $args{-descending_string} || '^';
     my $page_name    = $args{-page_name}         || $self->page_name() || '';
#    

     my $order_by_links_hashref;
     
     my @order_by_html;
     foreach my $col ( @{$self->display_columns} ) {
         #my $asc_qstring  = "ORDERBYCOL-$col=ASC";
	 #my $desc_qstring = "ORDERBYCOL-$col=DESC";
         my $query_string = $args{-query_string} ||
                            $self->build_query_string() ||
                            '';
        my $q_string_copy = $query_string;
        if ($query_string && $query_string =~ /ORDERBYCOL-(\w+)\=(ASC|DESC)/) {
           $query_string =~ s/ORDERBYCOL-(\w+)\=(ASC|DESC)//;
        }
        my $link_base    = "$page_name?";
        my @qdesc = ( $query_string);
        my @qasc = @qdesc;
         
        #if ($query_string) {
           
        #   $link_base .= "$query_string&";
        #}


        my $desc_qstring = $self->build_query_string(
                                                      -type => 'ORDERBYCOL',
                                                      -column => "$col",
                                                      -base => 'DESC',
                                                      -single => 1
                                                      );
	 $self->output_debug_info( $desc_qstring . "***<br>" );
         my $asc_qstring  = $self->build_query_string(
                                                      -type => 'ORDERBYCOL',
                                                      -column => "$col",
                                                      -base => 'ASC',
                                                      -single => 1
                                                      );
         
         my $asc_class_open   = '';
	 my $desc_class_open  = '';
	 my $asc_class_close  = '';
	 my $desc_class_close = '';
         $self->output_debug_info($q_string_copy . " this is the string");
	 if ($q_string_copy && $q_string_copy =~ /$asc_qstring/i) {
	     $asc_qstring = $query_string; # ~ s/\Q$asc_qstring//i;
	     $asc_class_open = qq!<span class="orderedBy">!;
	     $asc_class_close = qq!</span>!;
	 } else {
            push @qasc , $asc_qstring;
            #$asc_qstring .= '&' . $query_string;
         }
	 
	 if ($q_string_copy && $q_string_copy =~ /$desc_qstring/i) {
	     $desc_qstring = $query_string;
             # ~ s/\Q$desc_qstring//i;
	     $desc_class_open = qq!<span class="orderedBy">!;
	     $desc_class_close = qq!</span>!;
	 } else {
            push @qdesc , $desc_qstring;
            #$desc_qstring .= '&' . $query_string;
         }
	 
         if ($asc_string && $asc_string =~ /\.\w{3,}/i) {
            $asc_string = qq!<img src="$asc_string">!;  
         }
         
         if ($desc_string && $desc_string =~ /\.\w{3,}/i) {
            $desc_string = qq!<img src="$desc_string">!;  
         }
         
         my $asc_out = join('&',@qasc);
         my $desc_out = join('&',@qdesc);
         if ($asc_out) {
            $asc_out =~ s/^\&//;
         }
         
         if ($desc_out) {
            $desc_out =~ s/^\&//;
         }         
         
         my $tstring = qq!
         $asc_class_open<a href="$page_name?$asc_out">$asc_string</a>$asc_class_close
	 $desc_class_open<a href="$page_name?$desc_out">$desc_string</a>$desc_class_close
!; 
         push @order_by_html, $tstring;
         $order_by_links_hashref->{$col} = $tstring;
     }
     $self->order_by_links($order_by_links_hashref);
     return @order_by_html;
}

# this is a work in progress
# intended to provide hidden field support
# for both forms and table

sub add_hidden : Plugged {
    
    my ($self,$args) = @_;
    my $hidden;
    my $html_table;
    if ( $hidden ) {
        my $corner = $html_table->getCell( 1, 1 );
        foreach my $hidden_field ( keys %{ $hidden } ) {
            next if $hidden_field !~ /\w/;
            $corner .=
qq!<input name="$hidden_field" type="hidden" value="$hidden->{$hidden_field}">!;
        }

        $html_table->setCell( 1, 1, $corner );
    }

}

sub build_form : Plugged {

    my ( $self, %args ) = @_;

    if ($self->use_formbuilder() ) {
        my $find_columns = $args{-display_columns} || $self->field_to_column();
        $self->display_columns($self->determine_columns($find_columns));
        $args{'fields'} ||= $self->display_columns();
        my $form = CGI::FormBuilder->new(
                                         %args,
                                         );
        
        return $form;   
    }

    my $html_table = $args{-form_table} || $self->form_table() || HTML::Table->new(); 
    #if (!$html_table->isa( 'HTML::Table' ) ) {
    #     $html_table = HTML::Table->new();
    #}
    my $labels     = $args{-field_to_column} || $self->field_to_column();
    my @columns    = $self->determine_columns($args{-display_columns} || $labels);
    
    my $hidden     = $args{-hidden_fields}   || $self->hidden_fields();
    my $exclude    = $args{-exclude_columns} || $self->exclude_columns() || 0;
    
    if ( !@columns ) {
        warn
          "Array 'display_columns' was not defined and could not be auto identified\n";
    }
    if ( ref $exclude eq 'ARRAY' ) {
        @columns = $self->_process_excludes( $exclude , @columns );
    }

    my %cgi_field = $self->to_cgi;

    foreach my $col (@columns) {
        my $cell_content;
        if ( ref $args{$col} eq 'CODE' ) {
            $cell_content = $args{$col}->( $cgi_field{$col}->as_HTML() );
        }
        else {

            $cell_content = $cgi_field{$col}->as_HTML();
        }

        $html_table->addRow( $labels->{$col} || $col, $cell_content );
        $html_table->setRowClass( -1, $args{-rowclass} )
          if defined $args{-rowclass};
    }

    $args{-no_submit} ||= $self->no_submit();

    if ( !$args{-no_submit} ) {
        $html_table =
          $self->_process_attributes( $args{-attributes}, $html_table );
        $html_table->addRow();
        $html_table->setCellColSpan( $html_table->getTableRows, 1,
            $html_table->getTableCols );
        $html_table->setCell( $html_table->getTableRows, 1,
            CGI::submit( '.submit', 'Continue' ) );
    }

    if ( $hidden ) {
        my $corner = $html_table->getCell( 1, 1 );
        foreach my $hidden_field ( keys %{ $hidden } ) {
            next if $hidden_field !~ /\w/;
            $corner .=
qq!<input name="$hidden_field" type="hidden" value="$hidden->{$hidden_field}">!;
        }

        $html_table->setCell( 1, 1, $corner );
    }

    $args{-no_form_tag} ||= $self->no_form_tag();

    if ( !$args{-no_form_tag} ) {
        $html_table =
          start_form( $args{-form_tag_attributes} ) . $html_table . end_form;
    }

    return $html_table;

}

sub _process_attributes : Plugged {
    my ( $self, $attributes, $html_table ) = @_;
    foreach ( keys %{$attributes} ) {
        if ( ref $attributes->{$_} eq 'ARRAY' ) {
            $self->output_debug_info( "_process_attributes is doing a $_" );
            $html_table->$_( @{ $attributes->{$_} } );
        }
        else {
            $html_table->$_( $attributes->{$_} );
        }
    }
    return $html_table;
}

sub _process_excludes : Plugged {

    my ( $self, $exclude_list, @columns ) = @_;
    my %exclude;
    map { $exclude{$_} = 1 } @{$exclude_list};
    $self->output_debug_info( "excluding" . Dumper(\%exclude)  );
    map { undef $_ if exists $exclude{$_} } @columns;
    return grep /\w/, @columns;
}



=head2 html_table_navigation

Creates HTML anchor tag (link) based navigation for datasets. Requires Class::DBI::Pager.
Navigation can be in google style (1 2 3 4) or block (previous,next).

    my $nav = $cdbi_plugin_html->html_table_navigation(
                        -pager_object      => $pager,
                        # pass in -navigation with block as the value for
                        # next/previous style 
                        # "google" style is the default
                        -navigation_style   => 'block',
                        -page_name          => 'test2.pl', 
                   );

    print "'$nav'\n";

=cut

sub html_table_navigation : Plugged {
    my ( $self, %args ) = @_;
    my $pager = $args{-pager_object} || $self->pager_object();

    my $nav_block;
    my $nav_number;
    my $page_name        = $args{-page_name}    || $self->page_name();
    my $query_string     = $args{-query_string} || $self->query_string() || '';
    my $navigation_style = $args{-navigation_style}   || $self->navigation_style()
                            || 'both';
    my $page_navigation_separator = $args{-page_navigation_separator} ||
                                    $self->page_navigation_separator() ||
                                    ' | ';
    
    my $first_page_link = CGI::a(
	        {
		  href => "$page_name?page="
                      . $pager->first_page . '&'
                      . $query_string
		},'first'
		);
    
    my $last_page_link = CGI::a(
	       {
		  href => "$page_name?page="
                      . $pager->last_page . '&'
                      . $query_string
		},'last'
		);
    if ($pager->total_entries() <= $self->rows()) {
        $last_page_link  = '';
        $first_page_link = '';
    }
    if (   defined $navigation_style
        && defined $page_name )
    {

        if ( $pager->previous_page ) {
            $nav_block .= CGI::a(
                {
                        href => "$page_name?page="
                      . $pager->previous_page . '&'
                      . $query_string
                },
                'prev'
            );

        }

        if ( $pager->previous_page && $pager->next_page ) {
            $nav_block .= $page_navigation_separator;
        }

        if ( $pager->next_page ) {
            $nav_block .= CGI::a(
                {
                        href => "$page_name?page="
                      . $pager->next_page . '&'
                      . $query_string
                },
                'next'
            );
        }

		
        #} else {
	
	# determine paging system
	# need to allow for "to first" and "to last" record list
	# need to allow for "next" and "previous"
	# need to show which record group we are on
	# need to limit the list of records via an argument and/or
	# a reasonable default.
	
	if ( ($pager->total_entries / $pager->entries_per_page) > 10 ) {
	
	    my $left = $pager->last_page - $pager->current_page;
	    my $offset = $left;
	    if ($left > 9) {
	       $offset = 9;
	    } 
	    foreach my $num ( $pager->current_page .. $offset + $pager->current_page ) {
	     $nav_number .= add_number($pager->current_page,$num,$page_name,$query_string);
	    }    
	
	} else {
	
        foreach my $num ( $pager->first_page .. $pager->last_page ) {
             # $current,$number,$page_name,$query_string
	     $nav_number .= add_number($pager->current_page,$num,$page_name,$query_string);
        }
        
	}
        #}
    }
    if ($nav_number) {
        $nav_number = '' if $nav_number =~ /\[ 1 \]\s$/;
    }

    my $nav = $nav_number;

    # warn "'$nav_number'\n";

    if ( lc( $navigation_style ) eq 'both' ) {
        if ( $nav_block =~ /\|/ ) {
            $nav_block =~ s/ \| / $nav_number/;
            $nav = $nav_block;
        }
        elsif ( $nav_block =~ m#prev</a>$# ) {
            $nav = $nav_block . ' ' . $nav_number;
        }
        else {
            $nav = $nav_number . ' ' . $nav_block;
        }

    }

    if ( $navigation_style eq 'block' ) {
        $nav = $nav_block;
    }
    
    return $first_page_link . " " . $nav . " $last_page_link";
}

sub add_number {
   my ($current,$num,$page_name,$query_string) = @_;
   my $nav_num;
            if ( $num == $current ) {
                $nav_num .= "[ $num ]";
            }
            else {
                $nav_num .= '[ ';
                $nav_num .= CGI::a(
                    {
                        href =>
                          "$page_name?page=$num&$query_string"
                    },
                    $num
                );
                $nav_num .= ' ]';
            }
            $nav_num .= ' ';
    return $nav_num;
}

sub fill_in_form : Plugged {
    my ( $self, %args ) = @_;
    my $fif = new HTML::FillInForm;
    return $fif->fill(%args);

}

=head2 add_bottom_span

Places the content you pass in at the bottom of the HTML::Table
object passed in.  Used for adding "submit" buttons or navigation to
the bottom of a table.

=cut

sub add_bottom_span : Plugged {
    my ( $self, $add ) = @_;
    $self->data_table->addRow();
    $self->data_table->setCellColSpan( $self->data_table->getTableRows, 
                                       1,
                                       $self->data_table->getTableCols );
    $self->data_table->setCell( $self->data_table->getTableRows, 1, $add );
    # return $table;
}

=head2 search_ref

Creates the URL and where statement based on the parameters based
into the script. This method sets the query_string accessor value
and returns the where hash ref.

   $cdbi_plugin_html->search_ref( 
           # hash ref of incoming parameters (form data or query string)
           # can also be set via the params method instead of passed in
	   -params => \%params,
          
           # the like parameters by column (field) name that the
           # SQL statement should include in the where statement
           -like_column_map  => { 'first_name' => 'A%' },
          
   );

=head2 url_query

Creates the query portion of the URL based on the incoming parameters, this
method sets the query_string accessor value and returns the query string

    $cdbi_plugin_html->url_query(
        
	# pass in the parameters coming into the script as a hashref 
	-params => \%params,
	
        # items to remove from the url, extra data that
        # doesn't apply to the database fields
        -exclude_from_url => [ 'page' ], 
    );

=head2 navigation_style

Wants: string, either 'block' or 'both'

Defaults to: block

Valid in Configuration File: Yes

Returns: Current setting

    $filteronclick->navigation_style('both');

The navigation style applies to the string_filer_navigation method.

=head2 string_filter_navigation

    my ($filter_navigation) = $cdbi_plugin_html->string_filter_navigation(
       -position => 'ends'
    );

This method creates navigation in a series of elements, each element indicating a item that
should appear in a particular column value.  This filter uses anchor points to determine how
to qualify the search.  The anchor points are:
   BEGINSWITH
   ENDSWITH
   CONTAINS

The items in the 'strings' list will only be hrefs if the items in the database
match the search. If you prefer them not to be displayed at all pass in the
-hide_zero_match

The allowed parameters to pass into the method are:

=head2 hide_zero_match

Removes items that have no matches in the database from the strings allowed in the final navigation.

-position (optional - default is 'begin') - Tells the method how to do the match, allowed options are any case
of 'begin' , 'end' or 'contains'.  These options can be the entire anchor points as outlined above,
but for ease of use only the aforemention is enforced at a code level.

=head2 query_string

(optional) - See methods above for documentation

=head2 navigation_list

(optional, array_ref - default is A-Z) - Array ref containing the strings to filter on.

=head2 navigation_column

Indicates which column the string filter will occur on.
If you want to provide a filter on multiple columns it is recommended that
you create multiple string_filter_navigation.
Can be set via method, string_filter_navigation argument or configuration file

-page_name - The name of page that the navigation should link to

=head2 navigation_alignment

Set HTML attribute alignment for the page navigation.

=head2 navigation_seperator

    $filteronclick->navigation_seperator('::');
-or-
    -navigation_seperator => '::' # argument passed into string_filter_navigation
-or-
    navigation_sperator=:: in the configuration file
    
(optional, default two non-breaking spaces) - The characters to place between each item in the list.

=head2 align

(optional, defaults to center) - defines the alignment of the navigation

=head2 no_reset

don't include the filter reset link in the output

=head2 form_select

This method is used in conjunction with build_form and is slated for removal in
the next release. Please contact the author if you use this method or are
interested in seeing it improved rather then removed.

this methods expects the following:

    -value_column    # column containing the value for the option in the select
    -text_column     # column containing the text for the optoin in the select (optional)
    -selected_value  # the value to be selected (optional)
    -no_select_tag   # returns option list only (optional)


=head1 FILTERS

Filters are generated with the build_table method.  Filters allow for cascading
drill down of data based on individual cell values.  See Example page for
a demo.

=head2 beginswith

Declare a begins with match on a column

    $filteronclick->beginswith('column_name','A');
    # where 'A' is the value to match at the beginning

=head2 endswith

   $filteronclick->endswith('column_name','A');
   # where 'A' is the value to match at the end of the column contents

=head2 contains

   $filteronclick->contains('column_name','A');
   # where 'A' is the value to match anywhere in the column contents

=head2 variancepercent

   $filteronclick->variancepercent('column_name',2);
   # where '2' is the allowed percentage of variance to filter on

=head2 variancenumerical

   $filteronclick->variancenumerical('column_name',2);
   # where '2' is the allowed variance to filter on based
   # if value for 'column_name' is clicked

=head2 only

    $filteronclick->only('column_name');
    # creates a filter on 'column_name' cells to match the value in the cell
    # clicked

=head1 Additional Column Value Methods

=head2 colorize

Wants: list with column name, regular expression and CSS class name

Defaults to: na

Returns: na

    $filteronclick->colorize('column_name','regex','className');
    # will colorize a cell value based on a css entry when the value
    # matches the regex passed in

This method will colorize a cell with matching content based on a CSS class
passed into it. The appropriate html markup for the css is added to the output.

=cut

sub string_filter_navigation : Plugged {

    # intent of sub is to provide a consistent way to navigate to find
    # records that contain a particular string.
    my ( $self, %args ) = @_;
    $self->output_debug_info("STARTING STRING NAV!");
    # set up or variables and defaults

    my @links;

    my @alphabet;

    $args{-strings} = $args{-navigation_list} || $self->navigation_list();

    if (ref($args{-strings}) eq 'ARRAY') {
        @alphabet = @{ $args{-strings} }
    } else {
        @alphabet = ( 'A' .. 'Z' )
    }

    my $navigation_separator = $args{-navigation_separator} ||
                               $self->navigation_separator()  ||
                               '&nbsp;&nbsp;';
                               
    my $navigation_alignment = $args{-navigation_alignment}
                               || $self->navigation_alignment()
                               || 'center';
                               
    my $page_name      = $args{-page_name}       || $self->page_name();
    my $query_string   = $args{-query_string}    || $self->query_string();
    my $filtered_class =    $args{-filtered_class}
                            || $self->filtered_class()
                            || 'filtered';
    
    $args{-no_reset} ||= $self->no_reset();
    
    if ( $args{-no_reset} == 0 ) {
        push @links, qq!<a href="$page_name">Reset</a>$args{-separator}!;
    }
    my $filter;
    my $link_type;
    
    foreach my $string (@alphabet) {
        
        if ( $args{-position} =~ /ends/i ) {
            $filter    = "\%$string";
            $link_type = 'ENDSWITH';
        }
        elsif ( $args{-position} =~ /contain/i ) {
            $filter    = "\%$string\%";
            $link_type = 'CONTAINS';
        }
        else {
            $filter    = "$string\%";
            $link_type = 'BEGINSWITH';
        }

        my $count = $self->cdbi_class()->count_search_where(
                      $args{-column} => { like => "$filter" }
                                               );
        if ($count) {
            $self->output_debug_info("sending some info");
            push @links,
                  
                  $self->add_link(
                                  -type              => $link_type,
                                  -link_text         => $string,
                                  -value             => $string,
                                  -column            => $args{-column},
                                  -string_navigation => 1,
                                 );            
            
        }
        elsif ( $args{-hide_zero_match} > 1 ) {

            # do nothing
        }
        else {
            push @links, qq!$string!;
        }

        if ($query_string =~ /(WITH|CONTAINS)$string\-$args{-column}/) {
	       $links[-1] = qq~<span class="$filtered_class">$links[-1]</span>~;
	}
        
        if (scalar(@links) % 30 == 0) {
            $links[-1] .= "<br>";
        }
    }
    $self->output_debug_info("ENDING STRING NAV!");
    return qq!<div align="$navigation_alignment">!
      . join( $navigation_separator, @links )
      . "</div>";
}

sub search_ref : Plugged {
    my ( $self, %args ) = @_;
    $args{-exclude_from_url} ||= $self->exclude_from_url();
    $args{-params} ||= $self->params();
    my %where;
    if ( exists $args{-exclude_from_url} ) {

        # print_arrayref("Exclude from URL",$args{-exclude_from_url});
        map { delete $args{-params}->{$_} } @{ $args{-exclude_from_url} };
    }

    if ( exists $args{-params} ) {

        # print_hashref("Incoming parameters",$args{-params});
        my @only       = grep /ONLY\-/,               keys %{ $args{-params} };
        my @like       = grep /LIKE\-/,               keys %{ $args{-params} };
        my @beginswith = grep /BEGINSWITH\w+/,        keys %{ $args{-params} };
        my @endswith   = grep /ENDSWITH\w+/,          keys %{ $args{-params} };
        my @contains   = grep /CONTAINS[\@\w+]/,      keys %{ $args{-params} };
        my @percentage = grep /VARIANCEPERCENT\d+/,   keys %{ $args{-params} };
        my @numerical  = grep /VARIANCENUMERICAL\d+/, keys %{ $args{-params} };
	
        if (@only) {
            $self->output_debug_info( "\tOnly show matches of: " );
            foreach my $only (@only) {
	        $self->output_debug_info( $only );
                $only =~ s/ONLY-//;

    # print qq~\t\t$only becomes $only = '$args{-params}->{"ONLY-" . $only}'\n~;
                $where{$only} = $args{-params}->{ "ONLY-" . $only };
            }

        }

        if (@like) {

            # print "\tLike clauses to be added\n";
            foreach my $like (@like) {
                $like =~ s/LIKE-//;

# print "\t\t$like becomes \"first_name LIKE '$args{-like_column_map}->{$like}'\"\n";
                if ( exists $args{-like_column_map}->{$like} ) {

                    $where{$like} =
                      { 'LIKE', $args{-like_column_map}->{$like} };
                }
            }
        }

        if (@beginswith) {
            $self->output_debug_info( "\tShow only begining with" );
            foreach my $beginswith (@beginswith) {
                my ( $value, $column ) =
                  $beginswith =~ m/beginswith(\w+)-([\w\_]+)/i;
                $self->output_debug_info(
            qq~    '$beginswith' - looking $column that begins with $value~);
                $where{$column} = { 'LIKE', "$value\%" };
            }
        }

        if (@endswith) {
            $self->output_debug_info("\tShow only endswith with");
            
            foreach my $endswith (@endswith) {
                my ( $value, $column ) =
                  $endswith =~ m/endswith(\w+)-([\w\_]+)/i;
                $self->output_debug_info(
                  qq~\t\t'$endswith' - looking $column that ends with $value~);
                $where{$column} = { 'LIKE', "\%$value" };
            }
        }

        if (@contains) {
            $self->output_debug_info("\tShow only entries that contain");
            my $null = 'IS NULL';
            my $notnull = 'IS NOT NULL';
            foreach my $contains (@contains) {
                my ( $value, $column ) =
                  $contains =~ m/contains(.+)-([\w\_]+)/i;
                $self->output_debug_info(
                    qq~\t\t'$contains' - looking $column that contain $value~);
                if ($value eq 'NOTNULL') {
                     $where{$column} = \$notnull;
                } elsif ($value eq 'NULL') {
                     $where{$column} = \$null;
                } elsif ($value eq 'NOSTRING') {
                     $where{$column} = '';
                } else {
                     $where{$column} = { 'LIKE', "\%$value\%" };
                }
            }
        }

	if (@percentage) {
	    $self->output_debug_info(
                "\tShow only entries that are within a percentage variance");
	    foreach my $per (@percentage) {
	        my ( $percent , $column ) =
		   # VARIANCEPERCENT5-wt=170
		   $per =~ m/VARIANCEPERCENT(\d+)-([\w\_]+)/i;
		   # $per =~ m/VARIANCEPERCENT(\d+)-([\w\_]+)/i;
		my $value = $args{-params}->{$per};
	        $self->output_debug_info(
                 qq~    $per - looking for $percent variance
    on $column where value for variance is $value~);
		$percent = $percent / 100;
		my $diff    = $value * $percent;
		
		my $high = $value + $diff;
		my $low  = $value - $diff;
		
		$where{$column} = { 'BETWEEN' , [ $low , $high ] };
	    }
	}
	
	if (@numerical) {
	    $self->output_debug_info("\tShow only entries that are within a percentage variance");
	    foreach my $string (@numerical) {
	        my ( $number , $column ) =
		   # VARIANCEPERCENT5-wt=170
		   $string =~ m/VARIANCENUMERICAL(\d+)-([\w\_]+)/i;
		   # $per =~ m/VARIANCEPERCENT(\d+)-([\w\_]+)/i;
		my $value = $args{-params}->{$string};
	        $self->output_debug_info(
    qq~    $string - looking for $number variance
    on $column where value for variance is $value~);
		
		
		my $high = $value + $number;
		my $low  = $value - $number;
		
		$where{$column} = { 'BETWEEN' , [ $low , $high ] };
	    }
	}
	
    }

    if (exists $args{-override}) {
        %where = ( %where , %{  $args{-override} } );
    }

    if ( scalar( keys %where ) > 0 ) {
        $self->where( \%where );
        return \%where;
    }
    else {
        $self->where( undef );
        return undef;
    }

}

sub url_query : Plugged {
    my ( $self, %args ) = @_;
    $args{-params} ||= $self->params();
    $args{-exclude_from_url} ||= $self->exclude_from_url();
    if ( exists $args{-exclude_from_url} ) {
        map { delete $args{-params}->{$_} } @{ $args{-exclude_from_url} };
    }
    my %Param = %{ $args{-params} };
    my @url;
    foreach my $key ( keys %Param ) {

        if ( $key =~ m/\w/ && defined $Param{"$key"} ) {
            $self->output_debug_info("url_query $key<br>");
            push @url, qq~$key=~ . uri_escape( $Param{"$key"} )
              if defined $Param{"$key"}; # ne '';
        }
    }

    if ( $url[0] ) {
        $self->query_string( join( '&', @url ) );
        return join( '&', @url );
    }
    else {
        $self->query_string( undef );
        return undef;
    }
}

sub form_select : Plugged {
    my ( $self, %args ) = @_;

    my $html;
    my @objs         = $self->get_records(%args);
    my $value_column = $args{'-value_column'};
    my $text_column  = $args{'-text_column'};
    my $divider      = $args{'-text_divider'};
    $divider         ||= ', ';
    foreach my $obj (@objs) {
        my $text;
        my $value = $obj->$value_column();
        if ( ref($text_column) eq 'ARRAY' ) {
            my @text_multiple;
            foreach my $tc ( @{$text_column} ) {
                push @text_multiple, $obj->$tc();
            }
            $text = join( $divider, @text_multiple );
        }
        elsif ($text_column) {
            $text = $obj->$text_column();
        }
        else {
            $text = $value;
        }
        my $selected;
        $selected = ' SELECTED' if $value eq $args{'-selected_value'};
        $html .= qq!<option value="$value"$selected>$text</option>\n!;

    }
    if ( $args{no_select_tag} == 0 ) {
        $html = qq!<select name="$args{'-value_column'}">
       $html
</select>!;
    }
    return $html;
}

sub get_records : Plugged {

    # this code was taken from the build_table method
    # due to a limitation of the Class::DBI::Pager module and/or the way
    # in which this module identifies itself this code is currently replicated
    # here since Class::DBI::Pager throws and error when used.
    # behavior was retested with Class::DBI::Plugin and problem persisted

    my ( $table_obj, %args ) = @_;
    my $order_by = $args{-order_by} || $table_obj->order_by();
    if ( $table_obj->isa('Class::DBI::Plugin::FilterOnClick') ) {
        $table_obj = $table_obj->cdbi_class() ||
	             $table_obj->pager_object()
		     
    }
    $table_obj->output_debug_info( Dumper($table_obj) );
    my @records;
    if ( ref $args{-where} ne 'HASH' ) {
        if ( defined $order_by ) {
            @records = $table_obj->retrieve_all_sorted_by( $order_by );
        }
        else {
            @records = $table_obj->retrieve_all;
        }

# @records = $table_obj->search( user_id => '>0' , { order_by => $args{-order} } );
    }
    else {

        # my %attr = $args{-order};
        @records =
          $table_obj->search_where( $args{-where}, { order => $order_by } );
    }
    return @records;
}

=head1 INTERNAL METHODS/SUBS

If you want to change behaviors or hack the source these methods and subs should
be reviewed as well.

=head2 get_records

Finds all matching records in the database

=head2 create_order_by_links

=head2 add_number

=head2 determine_columns

Finds the columns that are to be displayed

=head2 auto_hidden_fields

=head2 add_hidden

=head2 create_auto_hidden_fields

=head2 add_link

=head2 allowed_methods

=head2 build_form

=head2 build_query_string

=head2 colorize_value

=head2 column_css_class

=head2 current_column

=head2 current_filters

=head2 current_record

=head2 fill_in_form

=head2 filter_lookup

=head2 hidden_fields

=head2 html

=head2 no_form_tag

=head2 no_submit

=head2 on_page

=head2 order_by_link

=head2 order_by_links

=head2 output_debug_info

=head2 query_string_intelligence

=head2 read_config

=head2 search_primary

=head2 use_formbuilder

=head1 BUGS

Unknown at this time.

=head1 SEE ALSO

L<Class::DBI>, L<Class::DBI::AbstractSearch>, L<Class::DBI::AsForm>,
L<HTML::Table>, L<Class::DBI::Plugin::Pager>

=head1 AUTHOR

Aaron Johnson
aaronjjohnson@gmail.com

=head1 THANKS

Thanks to my Dad for buying that TRS-80 in 1981 and getting
me addicted to computers.

Thanks to my wife for leaving me alone while I write my code
:^)

The CDBI community for all the feedback on the list and
contributors that make these utilities possible.

Roy Johnson (no relation) for reviewing the documentation prior to the 1.1
release.

=head1 CHANGES

Changes file included in distro

=head1 COPYRIGHT

Copyright (c) 2004-2007 Aaron Johnson.
All rights Reserved. This module is free software.
It may be used,  redistributed and/or modified under
the same terms as Perl itself.

=cut


sub params : Plugged {
      my $self = shift;

      if(@_ == 1) {
          my $params = shift;
          foreach my $key ( keys %{ $params } ) {
              next if $key !~ /SEARCH/;
              if (!defined $params->{$key}) {
                  delete $params->{$key};
                  next;
              }
              my ($column) = $key =~ /SEARCH-(.+)/;
              $params->{"CONTAINS$params->{$key}-$column"} = 1;
              delete $params->{$key};
          }
          $self->{params} = $params;
      }
      elsif(@_ > 1) {
          $self->{params} = [@_];
      }

      return $self->{params};
  }


sub field_to_column : Plugged {
    my ($self) = shift;
    if(@_ > 1) {
        my %args;
        tie %args , 'Tie::Hash::Indexed';
        %args = @_;
        $self->{field_to_column} = \%args;
        $self->display_columns(keys %args);
    } else {
        return $self->{field_to_column};  
    }
}

sub query_string : Plugged {
      my $self = shift;

      if(@_ == 1) {
          $self->{query_string} = shift;
      }
      elsif(@_ > 1) {
          $self->{query_string} = [@_];
      }

      return $self->{query_string};
  }

sub pager_object : Plugged {
      my $self = shift;

      if(@_ == 1) {
          $self->{pager_object} = shift;
      }
      elsif(@_ > 1) {
          $self->{pager_object} = [@_];
      }

      return $self->{pager_object};
  }

sub where : Plugged {
      my $self = shift;

      if(@_ == 1) {
          $self->{where} = shift;
      }
      elsif(@_ > 1) {
          $self->{where} = [@_];
      }

      return $self->{where};
  }

## Testing this section for .9 release

sub config : Plugged {
    my ($self,$key) = @_;
    return $config_hash->{$key};
}

## colorize matching values

sub colorize : Plugged {
    my $self = shift;
    $self->{column_value_colors}{$_[0]} = [ $_[1] , $_[2] ];
}

## assign class (css) to a column

sub column_css_class : Plugged {
    my $self = shift;
    $self->{column_css_class}{$_[0]} = $_[1];
}

## the following are called with:
## $html->beginswith('lastname','A');

sub beginswith : Plugged {
    my $self = shift;
    $self->{column_filters}{$_[0]} = [ 'BEGINSWITH' , $_[1] ];
}

sub endswith : Plugged {
    my $self = shift;
    $self->{column_filters}{$_[0]} = [ 'ENDSWITH' , $_[1] ];
}

sub contains : Plugged {
    my $self = shift;
    $self->{column_filters}{$_[0]} = [ 'CONTAINS' , $_[1] ];    
}

sub variancepercent : Plugged {
    my $self = shift;
    $self->{column_filters}{$_[0]} = [ 'VARIANCEPERCENT' , $_[1] ];    
}

sub variancenumerical : Plugged {
    my $self = shift;
    $self->{column_filters}{$_[0]} = [ 'VARIANCENUMERICAL' , $_[1] ];    
}

sub only : Plugged {
    my $self = shift;
    $self->{column_filters}{$_[0]} = 'ONLY';
}


sub current_column : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{current_column} = shift;
    }
    elsif(@_ > 1) {
        $self->{current_column} = [@_];
    }
    return $self->{current_column};
}

sub current_record : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{current_record} = shift;
    }
    elsif(@_ > 1) {
        $self->{current_record} = [@_];
    }
    return $self->{current_record};
}

## from config

sub rows : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{rows} = shift;
    }
    elsif(@_ > 1) {
        $self->{rows} = [@_];
    }
    return $self->{rows};
}

sub exclude_from_url : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{exclude_from_url} = shift;
    }
    elsif(@_ > 1) {
        $self->{exclude_from_url} = [@_];
    }
    return $self->{exclude_from_url};
}

sub order_by_links : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{order_by_links} = shift;
    }
    elsif(@_ > 1) {
        $self->{order_by_links} = [@_];
    }
    return $self->{order_by_links};
}

sub extend_query_string : Plugged {
    my ($self,%args) = @_;
    my @new;
    foreach ( keys %args ) {
        push @new , $_ . "=" . uri_escape($args{$_});
    }
    return $self->query_string() . '&' . join('&',@new);
}

sub display_columns : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{display_columns} = shift;
    }
    elsif(@_ > 1) {
        $self->{display_columns} = [@_];
    }
    return $self->{display_columns};
}

sub search_exclude : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{search_exclude} = shift;
    }
    elsif(@_ > 1) {
        $self->{search_exclude} = [@_];
    }
    return $self->{search_exclude} || [];
}

sub cdbi_class : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{cdbi_class} = shift;
    }
    elsif(@_ > 1) {
        $self->{cdbi_class} = [@_];
    }
    return $self->{cdbi_class};
}

sub page_name : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{page_name} = shift;
    }
    elsif(@_ > 1) {
        $self->{page_name} = [@_];
    }
    return $self->{page_name};
}


sub descending_string : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{descending_string} = shift;
    }
    elsif(@_ > 1) {
        $self->{descending_string} = [@_];
    }
    return $self->{descending_string};
}

sub ascending_string : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{ascending_string} = shift;
    }
    elsif(@_ > 1) {
        $self->{ascending_string} = [@_];
    }
    return $self->{ascending_string};
}

sub mouseover_bgcolor : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{mouseover_bgcolor} = shift;
    }
    elsif(@_ > 1) {
        $self->{mouseover_bgcolor} = [@_];
    }
    return $self->{mouseover_bgcolor};
}

sub mouseover_class : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{mouseover_class} = shift;
    }
    elsif(@_ > 1) {
        $self->{mouseover_class} = [@_];
    }
    return $self->{mouseover_class};
}

sub no_form_tag : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{no_form_tag} = shift;
    }
    elsif(@_ > 1) {
        $self->{no_form_tag} = [@_];
    }
    return $self->{no_form_tag};
}

sub no_mouseover : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{no_mouseover} = shift;
    }
    elsif(@_ > 1) {
        $self->{no_mouseover} = [@_];
    }
    return $self->{no_mouseover};
}

sub no_reset : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{no_reset} = shift;
    }
    elsif(@_ > 1) {
        $self->{no_reset} = [@_];
    }
    return $self->{no_reset};
}

sub no_submit : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{no_submit} = shift;
    }
    elsif(@_ > 1) {
        $self->{no_submit} = [@_];
    }
    return $self->{no_submit};
}

sub debug : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{debug} = shift;
    }
    elsif(@_ > 1) {
        $self->{debug} = [@_];
    }
    return $self->{debug};
}

sub searchable : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{searchable} = shift;
    }
    elsif(@_ > 1) {
        $self->{searchable} = [@_];
    }
    return $self->{searchable};
}

sub rowclass : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{rowclass} = shift;
    }
    elsif(@_ > 1) {
        $self->{rowclass} = [@_];
    }
    return $self->{rowclass};
}

sub rowclass_odd : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{rowclass_odd} = shift;
    }
    elsif(@_ > 1) {
        $self->{rowclass_odd} = [@_];
    }
    return $self->{rowclass_odd};
}

sub rowcolor_even : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{rowcolor_even} = shift;
    }
    elsif(@_ > 1) {
        $self->{rowcolor} = [@_];
    }
    return $self->{rowcolor_even};
}

sub rowcolor_odd : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{rowcolor_odd} = shift;
    }
    elsif(@_ > 1) {
        $self->{rowcolor_odd} = [@_];
    }
    return $self->{rowcolor_odd};
}

sub search_primary : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{search_primary} = shift;
    }
    elsif(@_ > 1) {
        $self->{search_primary} = [@_];
    }
    return $self->{search_primary};
}

sub filtered_class : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{filtered_class} = shift;
    }
    elsif(@_ > 1) {
        $self->{filtered_class} = [@_];
    }
    return $self->{filtered_class};
}

sub navigation_list : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{navigation_list} = shift;
    }
    elsif(@_ > 1) {
        $self->{navigation_list} = [@_];
    }
    return $self->{navigation_list};
}

sub navigation_column : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{navigation_column} = shift;
    }
    elsif(@_ > 1) {
        $self->{navigation_column} = [@_];
    }
    return $self->{navigation_column};
}

sub navigation_style : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{navigation_style} = shift;
    }
    elsif(@_ > 1) {
        $self->{navigation_style} = [@_];
    }
    return $self->{navigation_style};
}

sub navigation_alignment : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{navigation_alignment} = shift;
    }
    elsif(@_ > 1) {
        $self->{navigation_alignment} = [@_];
    }
    return $self->{navigation_alignment};
}

#sub separator : Plugged {
#    my $self = shift;
#
#    if(@_ == 1) {
#        $self->{separator} = shift;
#    }
#    elsif(@_ > 1) {
#        $self->{separator} = [@_];
#    }
#    return $self->{separator};
#}

sub hide_zero_match : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{hide_zero_match} = shift;
    }
    elsif(@_ > 1) {
        $self->{hide_zero_match} = [@_];
    }
    return $self->{hide_zero_match};
}

sub data_table : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{data_table} = shift;
    }
    elsif(@_ > 1) {
        $self->{data_table} = [@_];
    }
    return $self->{data_table};
}

sub form_table : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{form_table} = shift;
    }
    elsif(@_ > 1) {
        $self->{form_table} = [@_];
    }
    return $self->{form_table};
}

sub order_by : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{order_by} = shift;
    }
    elsif(@_ > 1) {
        $self->{order_by} = [@_];
    }
    return $self->{order_by};
}

sub hidden_fields : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{hidden_fields} = shift;
    }
    elsif(@_ > 1) {
        $self->{hidden_fields} = [@_];
    }
    return $self->{hidden_fields};
}

sub auto_hidden_fields : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{auto_hidden_fields} = shift;
    }
    elsif(@_ > 1) {
        $self->{auto_hidden_fields} = [@_];
    }
    return $self->{auto_hidden_fields};
}

sub config_file : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{config_file} = shift;
    }
    elsif(@_ > 1) {
        $self->{config_file} = [@_];
    }
    return $self->{config_file};
}

sub exclude_columns : Plugged {
      my $self = shift;

      if(@_ == 1) {
          $self->{exclude_columns} = shift;
      }
      elsif(@_ > 1) {
          $self->{exclude_columns} = [@_];
      }

      return $self->{exclude_columns};
  }


sub page_navigation_separator : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{page_navigation_separator} = shift;
    }
    elsif(@_ > 1) {
        $self->{page_navigation_separator} = [@_];
    }
    return $self->{page_navigation_separator};
}

sub navigation_separator : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{navigation_separator} = shift;
    }
    elsif(@_ > 1) {
        $self->{navigation_separator} = [@_];
    }
    return $self->{navigation_separator};
}

sub use_formbuilder : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{use_formbuilder} = shift;
    }
    elsif(@_ > 1) {
        $self->{use_formbuilder} = [@_];
    }
    return $self->{use_formbuilder};
}

# added to set/get current page outside of pager object
# added in 1.1

sub on_page : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{on_page} = shift;
    }
    elsif(@_ > 1) {
        $self->{on_page} = [@_];
    }
    return $self->{on_page};
}

## end from config

# added in 1.1 to allow for better query parsing

sub current_filters : Plugged {
    my $self = shift;

    if(@_ == 1) {
        $self->{current_filters} = shift;
    }
    elsif(@_ > 1) {
        $self->{current_filters} = [@_];
    }
    return $self->{current_filters};
}

1;
