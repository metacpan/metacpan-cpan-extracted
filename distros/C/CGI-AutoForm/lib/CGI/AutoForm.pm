# AutoForm.pm
#
# $Id: AutoForm.pm,v 1.19 2005/04/11 17:02:35 scottb Exp $
#

package CGI::AutoForm;

use strict;
use DBIx::IO::Mask;
use DBIx::IO::Search;
use DBIx::IO::Table;
use DBIx::IO::GenLib ();


*CGI::AutoForm::VERSION = \'1.05';

*CGI::AutoForm::DISPLAY_ONLY_GROUP = \'DISPLAY ONLY';
*CGI::AutoForm::INSERT_GROUP = \'INSERTABLE';
*CGI::AutoForm::EDIT_GROUP = \'DISPLAY EDIT';
*CGI::AutoForm::SEARCH_GROUP = \'SEARCHABLE';

*CGI::AutoForm::DEFAULT_RADIO_CHECKBOX_COLS = \2;

*CGI::AutoForm::DEFAULT_FIELD_LENGTH = \50;

*CGI::AutoForm::DEFAULT_MULTI_VALUE_DELIMITER = \':';

my @months = ('',qw(
    January
    February
    March
    April
    May
    June
    July
    August
    September
    October
    November
    December
));
my $month_field = {
    FIELD_NAME => '_MONTH',
    INPUT_CONTROL_TYPE => 'SELECT',
    SEARCH_CONTROL_TYPE => 'SELECT',
};
my $month_picklist = [
    map { { ID => $_, MASK => $months[$_] } } ('01'..'12')
];

my $day_field = {
    FIELD_NAME => '_DAY',
    INPUT_CONTROL_TYPE => 'SELECT',
    SEARCH_CONTROL_TYPE => 'SELECT',
};
my $day_picklist = [
    map { { ID => $_, MASK => int($_) } } ('01'..'31')
];

my $year_field = {
    FIELD_NAME => '_YEAR',
    INPUT_CONTROL_TYPE => 'SELECT',
    SEARCH_CONTROL_TYPE => 'SELECT',
};
my $this_year = substr(DBIx::IO::GenLib::local_normal_sysdate(),0,4);

my $hour_field = {
    FIELD_NAME => '_HOUR',
    INPUT_CONTROL_TYPE => 'SELECT',
    SEARCH_CONTROL_TYPE => 'SELECT',
};
my $hour_picklist = [
    map { { ID => $_, MASK => $_ } } ('00'..'23')
];

my $min_field = {
    FIELD_NAME => '_MIN',
    INPUT_CONTROL_TYPE => 'SELECT',
    SEARCH_CONTROL_TYPE => 'SELECT',
};
my $min_picklist = [
    map { { ID => $_, MASK => $_ } } ('00'..'59')
];

my $rel_quantity_field = {
    FIELD_NAME => '_QUANT',
    INPUT_CONTROL_TYPE => 'TEXT',
    SEARCH_CONTROL_TYPE => 'TEXT',
    DATATYPE => 'INT',
    INPUT_SIZE => 4,
    INPUT_MAXLENGTH => 7,
};

my $rel_unit_field = {
    FIELD_NAME => '_UNIT',
    INPUT_CONTROL_TYPE => 'SELECT',
    SEARCH_CONTROL_TYPE => 'SELECT',
};
my $rel_unit_picklist = [
    { ID => 'MINS', MASK => 'Minute(s)' },
    { ID => 'HRS', MASK => 'Hour(s)' },
    { ID => 'DAYS', MASK => 'Day(s)' },
    { ID => 'MONTHS', MASK => 'Month(s)' },
    { ID => 'YEARS', MASK => 'Years(s)' },
];

my $use_range_field = {
    FIELD_NAME => '_UR',
    INPUT_CONTROL_TYPE => 'CHECKBOX',
    SEARCH_CONTROL_TYPE => 'CHECKBOX',
};
my $use_range_picklist = [
    { ID => 1, MASK => 'Check to use this date range criteria' },
];

my $start_range_field = {
    FIELD_NAME => '_RS',
    INPUT_CONTROL_TYPE => 'TEXT',
    SEARCH_CONTROL_TYPE => 'TEXT',
};

my $end_range_field = {
    FIELD_NAME => '_RE',
    INPUT_CONTROL_TYPE => 'TEXT',
    SEARCH_CONTROL_TYPE => 'TEXT',
};

=head1 NAME

CGI::AutoForm - Automated abstraction of HTML forms from a data source

=head1 SYNOPSIS

 
 use CGI::AutoForm;


 $form = new CGI::AutoForm($dbh,$form_name);

 $form->action($action_url);

 $form->add_group($CGI::AutoForm::EDIT_GROUP,$table_name);

 $form->add_record($current_record);

 $form_html = $self->prepare();

 # insert $form_html into the BODY section of an (X)HTML document via a template


 $group = $form->group_by_name($group_name);

 $bool = $form->validate_query($query,$callback);

 $records = $form->format_query($query);

 $form_copy = $form->clone();

 $form->reset_group();

 
 #
 # an example of customizing a data group's fields...
 #

 $rv = $form->add_group($CGI::AutoForm::INSERT_GROUP,undef,'Vote For Your Favorite Artist','ARTIST_VOTE');

 $fields = $form->db_fields('ARTIST',$CGI::AutoForm::INSERT_GROUP);

 $form->push_field($fields->{ARTIST_NAME});

 $form->add_field( {
    FIELD_NAME => 'VOTE',
    INPUT_CONTROL_TYPE => 'RADIO',
    REQUIRED => 'Y',
    HEADING => 'Vote',
    DATATYPE => 'CHAR',
    INSERTABLE => 'Y',
    },
    [
        { ID => '1', MASK => '*', },
        { ID => '2', MASK => '**', },
        { ID => '3', MASK => '***', },
        { ID => '4', MASK => '****', },
    ]);

 $form_html = $self->prepare( { 'ARTIST_VOTE.ARTIST_NAME' => 'Nonpoint', 'ARTIST_VOTE.VOTE' => 4 } );



=head1 DESCRIPTION

There are many CGI form abstractions available, (e.g. CGI.pm).
A unique and powerful advantage with this abstraction is that it can be tied closely
with a database schema. Each group of fields in the form can represent a database table (or view)
and the table/column properties and constraints are automagically discovered so your DBA can make DDL
changes that will be immediately reflected in the HTML forms (no duplication of the data dictionary in your code).

All user/operator input is checked tightly against database constraints and there is built-in magic
to provide convenient select lists, etc, and to enforce a discreet set of valid values against unique/primary keys in lookup tables
(see B<Select lists & ID masking>). This means referential integrity even for MySQL. Metadata in MySQL's C<SET> and C<ENUM> types are also supported.
This also gives the operator a chance to correct mistakes with helpful hints instead of just getting a meaningless db error code.

This design allows you to get secure, database-driven web apps up and running is as little as a few
hours (see Cruddy! for an implementation L<http://www.thesmbexchange.com/cruddy/index.html>).
This is made possible with the help of the DBIx::IO abstraction, please refer to it for further details.

Another advantage this abstraction provides is the separation of presentation and style using style sheets and having human-friendly presentation
attributes stored in a database table that can be managed by non-engineers.

Typical CGI apps are characterized by collecting, updating, reporting and formatting data using forms and tables.
Form creation and processing can be divided into the following tasks:

1) Deciding what data to collect in order to perform the desired function.

2) Deciding how the operator will convey the desired information (input fields, checkboxes etc).

3) Form layout.

4) Imposing integrity constraints on the collected data.

5) Presentation and style.

6) Directing the collected data.

This class allows (but doesn't force) form elements and constraints to be defined in a database.
This way, the definitions are organized in a central repository, so they can be managed
in a shared environment separate from the code. Vanilla HTML is generated and several HTML classes
are used so that presentation and style can be dictated with style sheets (again separate from the code).
For flexibility, methods are given to modify form definitions and layout programmatically as well.

=head1 DETAILS

=head2 Form object structure

A form contains of a list of data groups. Each data group contains a list of form fields, and
a list of 0 or more data records that correspond to the form fields. Each form field is a hash
of attributes describing how the field should be rendered as a form element along with constraints, access controls and such.

A form object is blessed and will be referred throughout these docs as $form. Of its many attributes,
it holds an arrayref and a hashref of data groups, each referred to as $group. Each $group is
a (non-blessed) object-like hashref (sub-object) and of its many attributes, it holds an arrayref
and a hashref of data fields, each referred to as $field. Each $field in turn is a (non-blessed) object-like
hashref (sub-object) as well. Because these sub-objects are stored as a list and a hash by their parent,
it is best to use the methods provided when mutating the list/hash structures themselves. However,
modifying individual sub-object attributes may be done by accessing the hash keys directly (or iterating the lists).

If using a database on the backend to manage form data, a data group would correspond to a table,
each of its fields would correspond to columns, likewise, with the group's list of records.

One of the primary attributes of a data group is its type or usage and must be one of the following:

=over 2

=item Insert

Gather and validate data, e.g. for subsequent database insert.

=item Display/Update

Display a record with certain fields available for editing.

=item Search

Gather criteria for running a database report (with the help of DBIx::IO::Search).

=item Display Only

Display read-only data, e.g. a database report generated from a search form.

=back

Each of these types is referred to as $usage throughout these docs (see C<add_group> for defined constants).

Each form object will be in a certain state with respect to the groups, fields
and records associated with it. The state is defined in terms of the current
group#, record# and field#. The state is altered when adding a new data group to a form or through the iterative
methods such as C<next_group>, C<next_record>, C<next_field>. C<reset_group> will zero these
state properties. State is important for methods such as C<add_record>, C<push_field>
and such. Methods dependent on state will be annotated accordingly.


=head2 Form field attire

Form field attributes may be kept and managed in a database table (see contrib/ for DDL contained in the Cruddy! distribution L<http://www.thesmbexchange.com/cruddy/index.html>).
The default name of the table
that holds these attributes is C<UI_TABLE_COLUMN> and may be overridden per $form object by setting $form->{attr_defn_table_name}.
NOTE MySQL users! If your database has case-sensitive table names then pay attention to this name.

Each record in C<UI_TABLE_COLUMN> describes attributes/constraints of a single field in an HTML form. Each HTML form field
usually corresponds to a table column (or a view column for search forms or possibly updatable views otherwise).
The data dictionary will be queried if a form's field group corresponds to a table
that does not have any fields defined in C<UI_TABLE_COLUMN> and appropriate default attributes will be used (schema auto-discovery).
NOTE! however that this is all or nothing - if using a database table to store form data and that table has at least one field defined in C<UI_TABLE_COLUMN>, then
all fields in that table must have a record in C<UI_TABLE_COLUMN> or bad things can happen. The exception here are Oracle LOB type fields
(BLOB, etc) - these fields are completely ignored by this module.

You may also elect to leave some of the fields in C<UI_TABLE_COLUMN> NULL and they will be taken from the data dictionary. This is recommended
to avoid data duplication/syncing issues; essentially, it allows
the DBA to make changes that will be automagically reflected in the HTML forms (see C<use_data_dict>).

The following is a list of fields in C<UI_TABLE_COLUMN> and how each influences the form HTML, presentation, access control, constraint checking, etc:

=over 2

=item TABLE_NAME

UPPER CASE name of a table (or group of fields) that corresponds to a data group of a form object

=item FIELD_NAME

UPPER CASE name of a field associated with table_name

=item APPEAR_ORDER

Relative order the fields will appear in the form's data group (integer, recommended to use sequence of 10's - 10, 20, 30...)

=item HEADING

User-friendly name of FIELD_NAME that will appear in the form

=item SEARCHABLE

True/false - allows this field to appear in a search group

=item UPDATABLE

True/false - allows this field to be updated (e.g. set false for a primary key sequence)

=item INSERTABLE

True/false - allows this field to be defined by the operator for inserts (e.g. set false for auto-generated primary key sequence)

=item INPUT_CONTROL_TYPE

Form control type for operator input (update/insert groups) one of: TEXT, TEXTAREA, PASSWORD, DATE, DATETIME, FILE, SELECT, RADIO, CHECKGROUP

=item MULTI_INSERT_DELIMITER

For the CHECKGROUP input control, will insert multiple values as one field with each value serialized by this string (deserialized automagically on display)

=item SEARCH_CONTROL_TYPE

Form control type for search groups, one of: SELECT, CHECKBOX, RADIO, TEXT, MATCH TEXT, COMMALIST, DATE, DATETIME, DATERANGE, DATETRANGE (query on a range of date + time), RANGE

=item SEARCH_MULT_SELECT

For search groups, allow multi-select on a select box (values will be OR'ed using the IN operator) accepts an integer that gives the height of the control

=item USE_DATA_DICT

If true, datatype, default_value, required, input_size and input_maxlength will be taken from the data dictionary if those fields are NULL (recommended to use this whenever possible)

=item DATATYPE

Datatype constraint for this field, one of CHAR, DATE, NUMBER, DATETIME, INT, INT UNSIGNED

=item DEFAULT_VALUE

Default value for insert groups, can be the special value _SYSDATE for date types, meaning insert the current date

=item REQUIRED

True/false constraint - is empty input (NULL) acceptable?

=item INPUT_SIZE

For input_control_type of TEXT or PASSWORD - the width of the control box

=item INPUT_MAXLENGTH

For input_control_type of TEXT, PASSWORD - the maximum length of text that can be entered

=item BRIEF_HEADING

Short, user-friendly heading for the brief tabular display results (see B<Tabular data groups>)

=item ALT_MASK_FIELD

For auto-recognition of associated lookup table, an alternative name for the USER_MASK field (see B<Select lists & ID masking>)

=item MASK_TABLE_NAME

For configured recognition of associated lookup table, the name of the table with primary keys that match this foreign key (see B<Select lists & ID masking>)

=item MASK_FIELD_NAME

For configured recognition of associated lookup table, the name of the field that contains the user-friendly values (see B<Select lists & ID masking>)

=item ID_FIELD_NAME

For configured recognition of associated lookup table, the name of the field that contains the ID values as a unique or primary key (see B<Select lists & ID masking>)

=item NO_CACHE

True/false - use this for caching of the lookup table. If the records in the lookup table change frequently set this to TRUE. The default is FALSE,
which will cache the lookup table

=item RADIO_CHECKBOX_COLS

Integer value of the number of columns of buttons/controls for RADIO, CHECKBOX and CHECKGROUP controls.

=item FIELD_GROUP

Special considerations for a group of controls that govern a single field, only supported value is CONFIRM, which is useful for PASSWORD fields

=item ELEMENT_ATTRS

Additional attributes that will be added to the HTML control element (e.g. enter 'rows="5" cols="10"' to size a TEXTAREA control box)

=item HELP_SUMMARY

The heading of this field will be an active link and when clicked, will render this summary as a js alert giving useful hints to the operator about the use of this field

=back

Notes:

All values in TABLE_NAME and FIELD_NAME must be UPPER CASE. If you have use an RDBMS where table names are case-sensitive (MySQL on Linux/UNIX)
and you have two or more tables with the same name but different letter cases, this is probably not a good idea to begin with but there is no workaround.

True/false fields accept 'Y', 'N' or NULL only (NULL => false).

Doesn't make much sense to have a value for C<input_control_type> if C<insertable> AND C<updatable> are set FALSE.

Values left NULL will be given reasonable defaults.

If C<CONFIRM> is used for C<field_group>, two controls will be presented and the values entered into each must match. This is useful for PASSWORD fields
where the operator can't see the input or other important fields that can be mistyped (email TEXT box, for example).

For a well-defined set of records (with a common C<table_name>, where C<use_data_dict> is FALSE) C<table_name> does not have to refer to
a database table or any RDBMS entity at all. Feel free to make up a schema that doesn't even exist - I've done this to
manage an LDAP tree on the backend. You can even create your own data groups/controls that don't exist in C<UI_TABLE_COLUMN> by defining a record in a perl hash variable with
the keys of the hash being field names of C<UI_TABLE_COLUMN> (in UPPER CASE, example given in B<SYNOPSIS>).

You'll want to set C<use_data_dict> TRUE if the data group is supported by a database table so that properties/constraints are
automagically taken from the database schema.

For updates/inserts of submitted data, you may want to use only those fields that are updatable/insertable;
e.g. $table->insert({ %{$rec}{ map { $_->{UPDATABLE} eq 'Y' ? $_->{FIELD_NAME} : () } @$field_list } }).

For search groups, multiple values selected in a select box or checkbox will be OR'ed together using the C<IN> SQL operator.

Either alt_mask_field is populated or (mask_table_name, mask_field_name, id_field_name) as a group is populated (or none at all).
See B<Select lists & ID masking> for details.

Careful with NO_CACHE as it can be confusing - the default (false) is to cache the underlying lookup table for the set of acceptable values.
If you have meta-data that changes on a daily basis (which is many times the case) set this to true ('Y').

This module caches data dictionary info from the database. So if you're using a persistent interpreter (mod_perl), you'll
need to restart the webserver to recognize changes to the database structures (DDL modifications).

Clarification on RADIO, CHECKBOX and CHECKGROUP control types.

A RADIO set of controls only allows one value to be selected. CHECKBOX allows multiple values to be selected and is valid for C<SEARCH_CONTROL_TYPE>
where the values are or'd together in the search criteria (SELECT with C<SEARCH_MULT_SELECT> set to an integer value will have the same behavior).
CHECKGROUP allows for multiple values on INSERT and UPDATES such that these values are serialized into one field by the value of C<MULTI_INSERT_DELIMITER>.
If you use CHECKGROUP then you'll want to set C<MULTI_INSERT_DELIMITER> or the default value will be used, which is not what you want.
This behavior is very similar to the MySQL C<SET> data type. In fact you should be using CHECKGROUP for any MySQL C<SET> fields, in which
case the value for C<MULTI_INSERT_DELIMITER> is optional and ignored anyway because MySQL always uses a comma.

Using CHECKBOX (or SELECT with C<SEARCH_MULT_SELECT> set to an integer value) for C<SEARCH_CONTROL_TYPE> where C<INPUT_CONTROL_TYPE> is set to CHECKBOX will
probably not do what you want. If you want to do subset searching within a field of multiple values, use C<MATCH TEXT>, which will
accept C<%> as a wildcard.

Tip: use a select list for C<search_control_type> and text input box for C<input_control_type> for tables with numeric ID's as
the primary key. This will give a select list when doing a search masked with readable names and will give the numeric
ID value on inspection (not recommended for large tables as the select list becomes too large).

=head2 Select lists & ID masking

There is a significant amount of magic to mask ID values
with related lookup tables (meta-data) and verify referential integrity thereof. Take the example of a schema model of a CD
collection:

  ARTIST
+-------------------------+
| artist_id               |
| artist_name (user_mask) |
| ...                     |
+-------------------------+
          |
          |
          |
  TITLE  /|\
+--------------+
| artist_id    |
| title        |
| year         |
| ...          |
+--------------+

In this simple example, you'd want to join these tables and present C<artist_name> to the operator rather
than the meaningless-to-humans C<artist_id>. The magic starts by specifying a discreet HTML form control type
(C<UI_TABLE_COLUMN.INPUT_CONTROL_TYPE>) e.g. SELECT or RADIO where table_name = 'TITLE' and field_name = 'ARTIST_ID'.
This is enough to automagically populate the control
with values from the related lookup table (ARTIST) with the meaningful artist names and will put a constraint check
on the server side (I claimed "high" security after all) to verify referential integrity.
The masked values will then be translated back on insert/update.

This magic occurs when an appropriate control type is used and when there is a singular foreign key
where the foreign key column name (with the C<_ID> suffix stripped off, if present) matches a table name containing the unique/primary keys.
Additionally, the ID field name in the lookup
table must match the foreign key name and the human-friendly mask field must be named C<user_mask>.

In this example above, all conditions are met except the mask field name is C<artist_name> (not C<user_mask>) so we'll
populate the set of fields (mask_table_name, mask_field_name, id_field_name) with ('ARTIST', 'ARTIST_ID', 'ARTIST_NAME') respectively where field_name = C<ARTIST_ID>
and table_name = C<TITLE>
for ultimate control over table/field names of related lookup tables.

An example where you might use just alt_mask_field instead of the set (of fields (mask_table_name, mask_field_name, id_field_name) is perhaps
if you have a table COUNTRY with fields (country, user_mask) where country is the country code and user_mask is the country name
and a field in ARTIST (ARTIST.ORIGIN_COUNTRY) you'd simply set UI_TABLE_COLUMN.ALT_MASK_FIELD to 'COUNTRY' where field_name = C<ORIGIN_COUNTRY>
and table_name = C<ARTIST> and the magic will happen.

If the underlying RDBMS is MySQL some additional magic parses allowed values for C<SET> and C<ENUM> data types to obtain
this pick list (no related table with a foreign key is necessary).

If using a form control that demands a discreet set of values where none of the above conditions apply,
you must specify the list (see $pick_list under C<create_field>).

This magic provides a great deal of convenience and security not only for translating ID values for human operators
but also for enforcing a discreet set of allowable values for certain form fields.

=head2 Tabular data groups

If passing a true value for $tabular to C<add_group>, that group's data (via C<add_record>) will be displayed
in a tabular form - one column for each field in the record (read-only). This is how you display multiple records in a data group.
The only fields that will be shown in a tabular view are the ones with a non-empty value for C<UI_TABLE_COLUMN.BRIEF_HEADING>.

If $tabular is false (the default), a vertical form with a field heading and field value on each line is produced;
each use HTML C<table> elements however (see B<Form preparation, HTML generation & customization> for details).

=head2 Form preparation, HTML generation & customization

Once the data group(s) of the form object have been defined, C<prepare>
will generate the HTML, which should be inserted into the BODY section
of an HTML document (presumably using a templating system).
The structure of the generated HTML follows:

 Form Heading
 <form>
   <div>Data Group1 Heading</div>
   <table>
   tabular view of search results (see below)
    -or-
   vertical view of data group1 fields (see below)
   </table>
   [<div>Data Group2 Heading...</div>
   ...]
 </form>

 for the tabular view of a data group:
 <thead><tr><th>Field1 name</th>[<th>Field2 name</th>...]</tr></thead>
 <tr><td>Value1</td>[<td>Value2</td>...]</tr>
 ...

 for the vertical view of a data group (updatable/insertable groups):
 <tr><td><label>field name</label></td><td>field value/form control</td></tr>
 ...

See C<prepare> for further details of the layout.
See the Cruddy! demo for the default layout:

L<http://www.thesmbexchange.com/cruddy/index.html>

The HTML generated by C<prepare> can be influenced by a number of attributes
of the form object and group/field sub-object(s) (manipulate via hash keys, only some accessor methods have been defined as yet).
To get the $field sub-object (hashref) try C<$group-E<gt>{field_hash}{FIELD_NAME}> (see also C<field_hash>).
Some of the following attributes may have content already so it is best to append to them, rather
than assign/replace their values. C<prepare> also accepts some callbacks to allow further customization.
Unless otherwise noted, custom content is expected to be HTML (encode with HTML entities, etc, see C<escape>).

=over

=item $form->{top_message}

Content displayed at the very top of the form.

=item $form->{heading} (or $form->heading())

Header content near the top of the form describing the form. Will be enclosed in an C<h2> block.

=item $form->{heading2}

Sub-header content near the top of the form.

=item $form->{verr_msg}

Error message displayed near the top of the form when there are validation errors (see C<validate_query>).

=item $form->{noscript}

Content enclosed in a C<noscript> block.

=item $form->{name} (or $form->name())

Will be used in the C<name> attribute of the C<form> element.

=item $form->{action} (or $form->action() this needs to be set somewhere in your code)

Will be used in the C<action> attribute of the C<form> element.

=item $form->{submit_value} (or $form->submit_value())

Will be used in the C<value> attribute of the submit button.
The value will be HTML-escaped (don't encode with HTML entities).

=item $form->{submit_button_attrs}

Appended to the list of attributes of the C<input> button controls (submit, reset, etc).

=item $group->{heading}

Header content at the top of the data group describing that group.

=item $group->{GT}

Appended to the list of attributes of the outermost C<table> element of each group.

=item $group->{js}

A block of javascript added to the HTML block of each data group.

=item $form->{head_html}

=item $form->{tail_html}

=item $group->{head_html}

=item $group->{tail_html}

If these are defined before calling C<prepare>, their contents completely override those blocks of HTML (see C<prepare> for details).

=item The following affect the presentation of data groups in the tabular view

=over 2

=item $group->{TABULAR_TH_ATTRS}

For a tabular data group, this will append attributes to all C<th> elements in the data group (don't include a C<class> attribute).

=item $field->{TABULAR_TH_ATTRS}

For a tabular data group, this will append attributes to the C<th> element for
a particular $field sub-object (don't include a C<class> attribute).

=item $field->{TABULAR_TD_ATTRS}

For a tabular data group, this will append attributes to the C<td> elements
for a particular $field sub-object (don't include a C<class> attribute).

=item $field->{TABULAR_TD_STYLE}

For a tabular data group, this will append style properties to the C<style>
attribute of the C<td> elements for a particular $field sub-object.

=item $group->{TABULAR_TD_TAIL_ATTRS}

For a tabular data group, this will append attributes to the C<td> elements
on the final row in the table only (don't include a C<class> attribute).

=item $group->{TABULAR_TD_TAIL_STYLE}

For a tabular data group, this will append style properties to the C<style>
attribute of the C<td> elements on the final row in the table only.

=item $group->{TABULAR_TR_TAIL_ATTRS}

For a tabular data group, this will add to the list of attributes of the C<tr> element on the final
row in the table only.

=back

=item The following affect the presentation of data groups in the vertical view (updatable/insertable)

=over 2

=item $form->{VFR}

For vertical view data groups (update/insert), this will add to the list of attributes of the C<tr> elements.

=item $form->{VFL}

For vertical view data groups (update/insert), this will add to the list of attributes of the C<td> elements containing the label.

=item $form->{VFE}

For vertical view data groups (update/insert), this will add to the list of attributes of the C<td> elements containing the value (control).

=back

=item $form->{dontescape}

=item $form->{dontunescape}

These don't really affect the presentation but for lack of a better place to document, these attributes
prevent any (un)escaping of HTML content (using HTML entities) during HTML generation (dontescape)
or during query extraction/normalization/validation (dontunescape).

=back

=head2 Style sheets

Class attributes are hooked into the HTML that is generated to allow custom styling with CSS.
The following is a list of class names and how/where they influence the presentation.

=over

=item REQ

For fields that require input (NOT NULL), C<label> elements will be tagged with this class.

=item REQI

For fields that require input (NOT NULL), C<input> elements will be tagged with this class.

=item GH

For each data group heading, the opening C<div> element will be tagged with this class.

=item GT

For each data group, the outermost C<table> element will be tagged with this class.

=item TABULAR_TH

For a tabular data group, the C<th> elements will be tagged with this class.

=item TABULAR_TD

For a tabular data group, the C<td> elements will be tagged with this class.

=item GTAIL_TR

For a tabular data group, the C<tr> element will be tagged with this class on the final
row in the table only.

=item AS

For fields with UI_TABLE_COLUMN.HELP_SUMMARY populated, the C<a> element will be tagged with this class.

=item VFR

For vertical view data groups (update/insert), the C<tr> elements will be tagged with this class.

=item VFL

For vertical view data groups (update/insert), the C<td> elements containing the label will be tagged with this class.

=item VFE

For vertical view data groups (update/insert), the C<td> elements containing the value (control) will be tagged with this class.

=item CONFIRM

For fields that use C<CONFIRM> for UI_TABLE_COLUMN.FIELD_GROUP, the C<label> element will be tagged with this class
for the second confirmation field.

=item VERR_MSG

If there are validation errors (see C<validate_query>) the enclosing C<div> tag of the error
message will be tagged with this class.

=item VERR

If there are validation errors C<font>, C<span> and C<label> elements of the vertical view of a data group will be tagged with this
class for invalid fields. For tabular groups, the C<td> elements of invalid fields will be tagged.

=back

=head2 Form field names

To help avoid form field namespace collisions, the C<name> attribute of form controls will use the following format:

E<lt>group_nameE<gt>.E<lt>field_nameE<gt>

where E<lt>group_nameE<gt> is typically the name of the table but must be unique.

C<structure_query>, C<extract_query_group> and C<extract_cut_query_group> provide handy ways
of organizing form data with this naming convention.

=head1 METHODS

=over 4


=item C<new> (constructor)

 $form = new CGI::AutoForm([$dbh],[$form_name]);

Create a new $form object given an optional database handle
and optional name, which is helpful for CGI::AutoForm::Session.

=cut
sub new
{
    my ($caller,$dbh,$name) = @_;
    my $class = ref($caller) || $caller;
    my $self = bless({},$class);

    $self->{dbh} = $dbh;
    $self->{curr_group_no} = -1;
    $self->{curr_rec_no} = -1;
    $self->{curr_field_no} = -1;
    $self->{group_hash} = {};
    $self->{group_list} = [];
    $self->name($name);
    $self->{hidden} = {};

    $self->{attr_defn_table_name} = 'ui_table_column';

    return $self;
}

=pod

=head2 Form Attribute Accessors/Modifiers

Get the values of these READ-ONLY attributes.

 $dbh           = $form->dbh();

Get or set the values of these attributes.

 $bool          = $form->readonly();
 $name          = $form->name();
 $action        = $form->action();
 $heading       = $form->heading();
 $submit_value  = $form->submit_value();
 $hidden_fields = $form->hidden();
 $meta          = $form->meta();
 $continue      = $form->continue();


=cut
sub dbh
{
    my $self = shift;
    return $self->{dbh};
}

=pod

=item C<readonly>


Setting this attribute will force all data to be displayed
as read-only such that no form controls will be used.

=cut
sub readonly
{
    my ($self,$readonly) = @_;
    if (defined($readonly))
    {
        $self->{readonly} = $readonly;
    }
    return $self->{readonly};
}

sub meta
{
    my $self = shift;
    return $self->{meta};
}

sub continue
{
    my $self = shift;
    return $self->{continue};
}

#=pod
#
#=item C<name>
#
#
#Associate a name with $form. Will be used
#in the C<name> attribute of the HTML C<form> element.
#
#=cut
sub name
{
    my ($self,$name) = @_;
    if (defined($name))
    {
        $self->{name} = $name;
    }
    return $self->{name};
}

#=pod
#
#=item C<action>
#
#
#Specify the ACTION attribute of an HTML FORM element, e.g. a URI.
#
#=cut
sub action
{
    my ($self,$action) = @_;
    if (defined($action))
    {
        $self->{action} = $action;
    }
    return $self->{action};
}

#=pod
#
#=item C<heading>
#
#The heading will be displayed near the top of the form in HTML.
#
#=cut
sub heading
{
    my ($self,$heading) = @_;
    if (defined($heading))
    {
        $self->{heading} = $heading;
    }
    return $self->{heading};
}

#=pod
#
#=item C<submit_value>
#
#Override the text that appears in the form's SUBMIT button.
#
#=cut
sub submit_value
{
    my ($self,$submit_value) = @_;
    if (defined($submit_value))
    {
        $self->{submit_value} = $submit_value;
    }
    return $self->{submit_value};
}

=pod

=item C<add_group>

 $group_count = $form->add_group($usage[,$table_name,$heading,$group_name,$tabular,$defaults,$mid]);

Add a data group to $form of type $usage. Elements of the group are taken from UI_TABLE_COLUMN
according to $usage and $table_name.

$usage can be one of:

 $CGI::AutoForm::DISPLAY_ONLY_GROUP
 $CGI::AutoForm::INSERT_GROUP
 $CGI::AutoForm::EDIT_GROUP
 $CGI::AutoForm::SEARCH_GROUP

If $table_name is given,
fields of the group are taken from UI_TABLE_COLUMN or the data dictionary
as a last resort for that table name. If $table_name is not given, you are expected to add fields (see C<create_field> or C<add_field>).

$heading is used to label the group on the HTML form
and has a reasonable default according to $group_name. $group_name
defaults to $table_name and can be specified in the case where
more than one group with the same $table_name will appear on the
same form. The groups of a form must have unique names.

A true value for $tabular means the data that the group accumulates
will be displayed in a tabular view (see B<Tabular data groups>). If false, it does not make sense
to include more than one record for C<add_record> (or simply passing $query to C<prepare> is sufficient).

$defaults can be specified as a hashref of FIELD_NAME => value
pairs to be used as default values for fields in the group.
These values will override those in UI_TABLE_COLUMN.DEFAULT_VALUE or those determined from the data dictionary.

$mid will insert the group at a midpoint in the group list.
Default is the end of the list; index starts at 0 so say you want to insert a group
at position 4 on the form - you would specify 3 for $mid.

 Return the new number of groups for $form if successful.
 Return 0 if no fields exist in UI_TABLE_COLUMN or the data dictionary for $table_name.
 Return -1 if a pick_list could not be determined but is required (see C<create_field>).
 Return -2 if $group_name is not unique.
 Return -3 if data dictionary attributes were requested via UI_TABLE_COLUMN but could not be found.
 Return undef if db error.

This method affects the state of $form by incrementing the group#.

=cut
##at should rename this add_table_group() then have an add_static_group() for non-db lookups
sub add_group
{
    my ($self,$usage,$table_name,$heading,$group_name,$tabular,$defaults,$mid) = @_;
    my $group = $self->create_group($table_name,$heading,$group_name,$usage,$tabular);
    my $elems = $self->push_group($group,$mid) || return -2;
    return 1 unless $table_name;
    my $fields = $self->field_template($usage,$table_name,$defaults);
    unless ($fields > 0)
    {
        return $fields;
    }
    my ($key,$val);
    while (($key,$val) = each(%$fields))
    {
        $group->{$key} = $val;
    }
    return $elems;
}

=pod

=head2 Group Attribute Accessors/Modifiers

Get the values of these READ-ONLY group attributes. These are state dependent (refer to B<Form object structure>).


 $name          = $form->current_group_name();
 $usage         = $form->group_usage();
 $name          = $form->curr_table_name();


=cut
sub current_group_name
{
    my ($self) = @_;
    my $group = $self->current_group();
    return $group->{group_name};
}

sub group_usage
{
    my ($self) = @_;
    my $group = $self->current_group();
    return $group->{usage};
}

sub curr_table_name
{
    my ($self) = @_;
    my $group = $self->current_group();
    return $group->{table_name};
}

=pod

=item C<current_group>

 $rec = $form->current_group();

Return the $group structure of the current group.
If there is no current group, the first one will be returned and curr_group_no modified.

=cut
sub current_group
{
    my ($self) = @_;
    my $i = $self->{curr_group_no};
    $i = 0 if $i < 0;
    return $self->{group_list}[$i];
}

=pod

=item C<group_by_name>

 $group = $form->group_by_name($group_name);

Return the $group structure identified by $group_name.

=cut
sub group_by_name
{
    my ($self,$group_name) = @_;
##at really need to use Tie::IxHash - should set $self->{group_no} to the index of group_name
    return $self->{group_hash}{$group_name};
}

=pod

=item C<reset_group>

 $form->reset_group();

Zero the state of $form by resetting the group#, record# and field#.

=cut
sub reset_group
{
    my ($self) = @_;
    $self->{curr_group_no} = -1;
    $self->{curr_field_no} = -1;
    $self->{curr_rec_no} = -1;

    return 1;
}

# The VALUE or DISPLAY_VALUE attribute of the next field will be set
# depending on the group usage, after making a copy of the field's hash stored in $group->{field_list}
# the VALUE attribute can be an array ref of values where multiple values are
# allowed.

# Returns either a hashref of the next field's attributes, or
# an array ref of field attributes in the case where a field
# represents a group of form fields (e.g. an insert date field)

# depends on curr_rec_no being incremented - DO NOT USE THIS METHOD WITHOUT next_record method
sub next_field
{
    my ($self) = @_;
    my $field_list = $self->field_list();
    my $field = $field_list->[++$self->{curr_field_no}];
    if (ref($field) && %$field)
    {
        unless ($field = $self->_export_field($field))
        {
            defined($field) || return $field;
            return $self->next_field();
        }
    }
    elsif (ref($field))
    {
        # some kind of bug in perl?? an empty hash ref is an element beyond the number of elements in $field_list?
        undef($field);
    }
    return $field;
}

=pod

=item C<control_type>

 $control_type = $form->control_type($field);

Return the control type of $field specified in either UI_TABLE_COLUMN.INPUT_CONTROL_TYPE or UI_TABLE_COLUMN.SEARCH_CONTROL_TYPE
depending upon the usage of the current data group (state dependent).

=cut
sub control_type
{
    my ($self,$field,$usage) = @_;
    $usage ||= $self->group_usage();
    return ($usage eq $CGI::AutoForm::SEARCH_GROUP ? $field->{SEARCH_CONTROL_TYPE} : $field->{INPUT_CONTROL_TYPE});
}

# for backwards compatibility
sub _control_type
{
    &control_type;
}

=pod

=head2 Customizing groups & fields

The following methods allow you to manipulate
and customize form definitions taken from UI_TABLE_COLUMN or the data dictionary. You may even roll your own
fields by creating a hashref of NAME => value pairs that emulate a record from UI_TABLE_COLUMN.

=cut

=pod

=item C<create_field>

 $group_field = $form->create_field($field[,$pick_list,$all_db_defn]);

Given $field - a hashref of NAME => value pairs that resembles a record in UI_TABLE_COLUMN, return
a hashref that is suitable to add to an existing data group structure ($group) using
C<push_field>, C<unshift_field>, etc.

$field is copied so be sure to use the return value.

$pick_list is a list of discreet values that may be used for a field with a SELECT
control list, RADIO or CHECKBOX group, etc. It is an arrayref of hashes, each hash with two keys:
ID => C<value> attribute of the control element
MASK => the human-friendly description the operator sees.
You may also add/replace/modify the picklist after calling this method using C<replace_picklist>
or by manipulating the following structures:
 $field->{PICK_LIST}
 $field->{PICK_HASH}

If this field has a control type of C<SELECT>, C<RADIO>, C<CHECKBOX>, etc., or if $all_db_defn is true, a picklist will be looked for
in the database or data dictionary (see B<Select lists & ID masking>) unless
$pick_list is passed to this method.

Advanced:
The $field->{REQUIRED} attribute is always set false for SEARCHABLE data groups as no fields are required for running reports.
If you really know what you're doing, it is OK to set this to true after calling
this method.

May return 0 if $pick_list was not given for a C<SELECT>, C<RADIO> or C<CHECKBOX> field and one could not be generated
from the database using DBIx::IO::Mask.
May return undef if a db error occurred with DBIx::IO::Mask

=cut
# If $no_group is true, $field->{FORM_ELEMENT_NAME} will not be defined (normally defined
# using the namespace of the current group name). This means you'll have to define it elsewhere.
# $usage must be one of the valid group usage identifiers.
sub create_field
{
    my ($self,$field_attrs,$pick_list,$all_db_defn,$no_group,$usage) = @_;
    $field_attrs = { %$field_attrs };
    $pick_list ||= $field_attrs->{PICK_LIST};
    my $pick_hash;
    my $type = $self->control_type($field_attrs,$usage);
    my $fname = $field_attrs->{FIELD_NAME};

    my $group = $self->current_group();
    $pick_list = [ @{$group->{table}{io}{picklist}{$fname}} ] if (!ref($pick_list) && exists($group->{table}{io}{picklist}{$fname}) && @{$group->{table}{io}{picklist}{$fname}});

    if (($type eq 'SELECT' || $type eq 'RADIO' || $type eq 'CHECKBOX' || $type eq 'CHECKGROUP' || $all_db_defn) && !ref($pick_list))
    {
        my $dbh = $self->dbh();
        my $oldp = $dbh->{PrintError};
        $dbh->{PrintError} = 0;
        my $masker = new DBIx::IO::Mask($self->dbh(),($field_attrs->{ALT_MASK_FIELD} || lc($fname)),
            $field_attrs->{MASK_TABLE_NAME},$field_attrs->{MASK_FIELD_NAME},$field_attrs->{ID_FIELD_NAME},($field_attrs->{NO_CACHE} eq 'Y'));
        $dbh->{PrintError} = $oldp;
        if ($masker)
        {
            $pick_list = $masker->pick_list();
            $pick_hash = $masker->ids_to_mask();
        }
        else
        {
            unless ($all_db_defn)
            {
                if (defined($masker))
                {
                    # may add picklist after creating the field!!                    warn("No mask list found for " . $fname);
                    # return $masker;
                }
                else
                {
                    warn("No mask list found for $field_attrs->{TABLE_NAME}.$fname, perhaps you need to set UI_TABLE_COLUMN.MASK_TABLE_NAME et al appropriately.\n",$dbh->errstr());
                    return $masker;
                }
            }
        }
    }
    elsif (ref($pick_list))
    {
        $pick_hash = { map { $_->{ID} => $_->{MASK} } @$pick_list  };
    }

    if ($all_db_defn && ref($pick_list))
    {
        # if mask test is true and all defn come from db, set SEARCH_MULT_SELECT (will only affect SEARCHABLE groups)
        $field_attrs->{INPUT_CONTROL_TYPE} = 'SELECT';
        $field_attrs->{SEARCH_CONTROL_TYPE} = 'SELECT';
        $field_attrs->{SEARCH_MULT_SELECT} = 3;

        # Special magic for MySQL's SET type
        if ($group->{table}{io}{column_types}{$fname} eq 'SET')
        {
            $field_attrs->{INPUT_CONTROL_TYPE} = 'CHECKGROUP';
            $field_attrs->{SEARCH_CONTROL_TYPE} = 'MATCH TEXT';
            $field_attrs->{SEARCH_MULT_SELECT} = undef;
        }

        $type = $self->control_type($field_attrs,$usage);
    }

    # Special magic for MySQL's SET type
    $field_attrs->{MULTI_INSERT_DELIMITER} = ',' if $group->{table}{io}{column_types}{$fname} eq 'SET';

    $field_attrs->{PICK_LIST} = $pick_list;
    $field_attrs->{PICK_HASH} = $pick_hash;

    return $field_attrs if $no_group;
    
    my $group_name = $self->current_group_name();
    my $elem_name_app;
    if ($type eq 'TEXT' && _isdate($field_attrs) && !$usage)
    {
        # this extension will be stripped via normalize_query()
        # This will signal when a TEXT field needs to be checked that it holds a parseable date string
        $elem_name_app = "._DT";
    }
    elsif ($type eq 'MATCH TEXT')
    {
        # this signals when a search should use wildcards
        $elem_name_app = "._WM";
    }
    elsif ($type eq 'CHECKGROUP')
    {
        $elem_name_app = "._CG";
    }
    elsif ($type eq 'COMMALIST')
    {
        $elem_name_app = "._CL";
    }
    $field_attrs->{FORM_ELEMENT_NAME} = "$group_name." . $fname . $elem_name_app;
    return $field_attrs;
}

=pod

=item C<add_field>

 $field_count = $form->add_field($field[,$picklist,$mid]);

Conveniently combines C<create_field> and C<push_field>.

=cut
##at on this and related methods, should check to make sure a group exists!!
sub add_field
{
    my ($self,$field,$picklist,$mid) = @_;
    unless ($field = $self->create_field($field,$picklist))
    {
        return $field;
    }
    return $self->push_field($field,$mid);
}

=pod

=item C<replace_picklist>

 $pick_hash = $form->replace_picklist($field_name,$pick_list[,$group]);

Replace the picklist of $field_name with $pick_list for $group (which defaults
to the current group).

=cut
sub replace_picklist
{
    my ($self,$field_name,$pick_list,$group) = @_;
    $field_name = uc($field_name);
    $group ||= $self->current_group();
    $group->{field_hash}{$field_name}{PICK_LIST} = $pick_list;
    my $pick_hash = { map { $_->{ID} => $_->{MASK} } @$pick_list  };
    return $group->{field_hash}{$field_name}{PICK_HASH} = $pick_hash;
}

=pod

=item C<push_group>

 $group_count = $form->push_group($group[,$mid]);

Push $group on to the end of the group list or at the position $mid (using splice) if provided.
Alters the current group number (state) to point to the $group just added.

=cut
sub push_group
{
    my ($self,$group,$mid) = @_;
    defined($mid) || ($mid = @{$self->{group_list}});
    my $name = $group->{group_name};
    exists($self->{group_hash}{$name}) && (warn("\$group_name [$name] not unique"),return undef);
    $self->{group_hash}{$name} = $group;
    splice(@{$self->{group_list}},$mid,0,$group);
    my $elems = @{$self->{group_list}};
    $self->{curr_group_no} = $mid;
    return $elems;
}

=pod

=item C<push_field>

 $field_count = $form->push_field($field[,$mid]);

Push $field (see C<create_field>) on to the end of the field list of the current group (or at the position $mid if provided).

=cut
sub push_field
{
    my ($self,$field,$mid) = @_;
    my $field_list = $self->field_list();
    defined($mid) || ($mid = @{$field_list});
    my $field_hash = $self->field_hash();
    $field_hash->{$field->{FIELD_NAME}} = $field;
    splice(@{$field_list},$mid,0,$field);
    return scalar(@{$field_list});
}


##at would be nice to have a field {NEVER_SHOW} that flagged if it should be included in the record at all (hidden or otherwise)

=pod

=item C<unshift_field>

 $field_count = $form->unshift_field($field);

unshift $field (see C<create_field>) on to the beginning of the field list of the current group.

=cut
sub unshift_field
{
    my ($self,$field) = @_;
    my $field_list = $self->field_list();
    my $field_hash = $self->field_hash();
    $field_hash->{$field->{FIELD_NAME}} = $field;
    return unshift(@{$field_list},$field);
}

sub pop_field
{
    my ($self) = @_;
    my $field_list = $self->field_list();
    my $field_hash = $self->field_hash();
    my $field = pop(@{$field_list});
    delete($field_hash->{$field->{FIELD_NAME}}) if ref($field);
    return $field;
}

sub shift_field
{
    my ($self) = @_;
    my $field_list = $self->field_list();
    my $field_hash = $self->field_hash();
    my $field = shift(@{$field_list});
    delete($field_hash->{$field->{FIELD_NAME}}) if ref($field);
    return $field;
}

=pod

=item C<delete_field>

 $deleted_field = $form->delete_field($field_name[,$group]);

Delete the field hashref identified by $field_name from $group (defaults
to the current group). Return the deleted field hashref.

=cut
# Assumes that FIELD_NAME is unique
# Modifies by reference (no copying is done)
sub delete_field
{
    my ($self,$field_name,$group) = @_;
    $field_name = uc($field_name);
    my $field_list;
    my $field_hash;
    if ($group)
    {
        $field_list = $group->{field_list};
        $field_hash = $group->{field_hash};
    }
    else
    {
        $field_list = $self->field_list();
        $field_hash = $self->field_hash();
    }
    my $i = 0;
    foreach my $field (@{$field_list})
    {
        next if $field->{FIELD_NAME} eq $field_name;
        $field_list->[$i] = $field;
        $i++;
    }
    return if @{$field_list} == $i;
    pop(@{$field_list});
    return delete($field_hash->{$field_name});
}

=pod

=item C<db_fields>

 $fields = $form->db_fields($table_name,$usage);

Return a hashref of $field structures from the database using $table_name. Check UI_TABLE_COLUMN first and then the data dictionary. This
is useful for customizing a data group or adding fields from different tables into the same
data group, etc.

 Return 0 if no fields exist in UI_TABLE_COLUMN or the data dictionary for $table_name.
 Return -1 if a pick_list could not be determined but is required (see C<create_field>).
 Return -3 if data dictionary attributes were requested via UI_TABLE_COLUMN but could not be found.
 Return undef if db error.

=cut
sub db_fields
{
    my ($self,$table_name,$usage) = @_;
    my $fields = $self->field_template($usage,$table_name,undef,1);
    unless ($fields > 0)
    {
        return $fields;
    }
    return $fields->{field_hash};
}

# By convention, all TABLE_NAME GROUP_NAME and FIELD_NAME are case-sensitive and always UPPER CASE

# If successful, return a hashref where:
# field_list => fields in the order they should appear on the form
# field_hash => fields keyed by UI_TABLE_COLUMN.FIELD_NAME
# fields may be defined in UI_TABLE_COLUMN or may be derived from the db dict via table_name

# Return 0 if no fields exist in UI_TABLE_COLUMN for $table_name
# Return -1 if a pick_list could not be culled using DBIx::IO::Mask
# Return -3 if data dictionary attributes were requested but could not be found
# Return undef if db error

# $defaults override those listed in the db
##at maybe cache field_list for the entire class??
sub field_template
{
    my ($self,$usage,$table_name,$defaults,$no_group) = @_;
    $defaults ||= {};
    my $orig_table_name = $table_name;
    $table_name = uc($table_name);

    my $group = $self->current_group();

    my $recs = [];
    my $searcher = new DBIx::IO::Search($self->dbh(),$self->{attr_defn_table_name});
    if (ref($searcher))
    {
        $searcher->build_scalar_crit('TABLE_NAME','=',$table_name);
##at    $searcher->build_scalar_crit($usage,'=','Y') unless $usage eq $CGI::AutoForm::DISPLAY_ONLY_GROUP || $usage eq $CGI::AutoForm::EDIT_GROUP;
        $recs = $searcher->search(undef,[ 'APPEAR_ORDER' ]) || return undef;
    }
    elsif (!defined($searcher))
    {
        return undef;
    }

    my $all_db_defn;
    my $table;
    unless (@$recs)
    {
        # Try and see if a table exists
        if ($table = new DBIx::IO::Table($self->dbh(),undef,undef,$orig_table_name))
        {
            foreach my $col (@{$table->{io}{col_list}})
            {
                # Ignore LOB types completely (Oracle)
                push(@$recs, { TABLE_NAME => $table_name, FIELD_NAME => $col, UPDATABLE => 'Y', SEARCHABLE => 'Y', INSERTABLE => 'Y', })
                    unless $table->{io}->is_ignore_type($table->column_type($col));
            }
            unless ($no_group)
            {
                $group->{table} = $table;
            }
            $all_db_defn++;
        }
        else
        {
            defined($table) || return $table;
        }
        @$recs || (warn("No fields defined for $orig_table_name"),return 0);
    }
    my $field_hash = {};
    my $fields = [];
    foreach my $rec (@$recs)
    {
        my $fname = uc($rec->{FIELD_NAME});
        $rec->{FIELD_NAME} = $fname;
        if ($rec->{USE_DATA_DICT} eq 'Y' || $all_db_defn)
        {
            my $rv;
            unless ($rv = $self->use_data_dict($rec,$orig_table_name,$table,$no_group))
            {
                defined($rv) && return -3;
                return $rv;
            }
        }
        else
        {
            $rec->{DATATYPE} = 'CHAR' unless $rec->{DATATYPE};
            $rec->{INPUT_SIZE} ||= $CGI::AutoForm::DEFAULT_FIELD_LENGTH;
            $rec->{INPUT_MAXLENGTH} ||= $CGI::AutoForm::DEFAULT_FIELD_LENGTH;
        }
        if (!$rec->{SEARCH_CONTROL_TYPE} && $usage eq $CGI::AutoForm::SEARCH_GROUP)
        {
            my $ir = $rec->{INPUT_CONTROL_TYPE};
            if ($ir)
            {
                $rec->{SEARCH_CONTROL_TYPE} = 'DATERANGE' if $ir eq 'DATE';
                $rec->{SEARCH_CONTROL_TYPE} = 'DATETRANGE' if $ir eq 'DATETIME';
                $rec->{SEARCH_CONTROL_TYPE} = 'SELECT' if $ir eq 'SELECT';
                $rec->{SEARCH_CONTROL_TYPE} = 'RADIO' if $ir eq 'RADIO';
            }
            elsif (_isdate($rec))
            {
                $rec->{SEARCH_CONTROL_TYPE} = 'DATETRANGE' if $rec->{DATATYPE} eq 'DATETIME';
                $rec->{SEARCH_CONTROL_TYPE} = 'DATERANGE' if $rec->{DATATYPE} eq 'DATE';
            }
            else
            {
                $rec->{SEARCH_CONTROL_TYPE} = 'TEXT';
            }
        }
        elsif (!$rec->{INPUT_CONTROL_TYPE} && !$self->is_readonly($rec))
        {
            if (_isdate($rec))
            {
                $rec->{INPUT_CONTROL_TYPE} = 'DATETIME' if $rec->{DATATYPE} eq 'DATETIME';
                $rec->{INPUT_CONTROL_TYPE} = 'DATE' if $rec->{DATATYPE} eq 'DATE';
            }
            else
            {
                $rec->{INPUT_CONTROL_TYPE} = 'TEXT';
            }
        }

        # Disable searches for Oracle LONG or RAW types (they will error)
        my $type = '';
        $rec->{SEARCHABLE} = 'N'
            if $group->{table} && ($type = $group->{table}->column_type($rec->{FIELD_NAME})) && $group->{table}{ioclass} eq 'DBIx::IO::OracleIO' &&
                ($type eq 'LONG' || $type eq 'RAW' || $type eq 'LONG RAW');

        # the required field, therefore only applies to a non-searchable group (exept as noted above where you can set it explicitly)
        # this needs clearer docs: the REQUIRED field DOES NOT APPLY TO groups that are designated as $CGI::AutoForm::SEARCH_GROUP, the REQUIRED field is unset (undef())
        # you can, however explicitly set $group->{REQUIRED} = 'Y' after calling add_group()
        undef($rec->{REQUIRED}) if $usage eq $CGI::AutoForm::SEARCH_GROUP;
        $rec->{DEFAULT_VALUE} = $defaults->{$fname} if defined($defaults->{$fname});
        $rec->{HEADING} = $fname unless length($rec->{HEADING});
        $rec->{BRIEF_HEADING} = $fname if !length($rec->{BRIEF_HEADING}) && $all_db_defn;
        my $field = $self->create_field($rec,undef,$all_db_defn,$no_group,$usage);
        unless ($field)
        {
            defined($field) && return -1;
            return $field;
        }
        push(@$fields,$field);
        $field_hash->{$fname} = $field;
    }
    return { field_list => $fields, field_hash => $field_hash };
}

##at because intrinsic date types can differ from explicit ones, this should always be executed if a table exists and tableIO is performed

# Return 0 if FIELD_NAME does not exist in table
sub use_data_dict
{
    my ($self,$field,$table_name,$table,$no_group) = @_;
    unless ($table && %$table)
    {
        unless ($table = new DBIx::IO::Table($self->dbh(),undef,undef,$table_name))
        {
            return $table;
        }
        unless ($no_group)
        {
            my $group = $self->current_group();
            $group->{table} = $table;
        }
    }
    my $io = $table->{io};
    my $fname = $field->{FIELD_NAME};
    return 0 unless $io->column_type($fname);
    if ($io->is_datetime($fname))
    {
        $field->{_imp_datetype} = 'DATETIME';
    }
    elsif ($io->is_date($fname))
    {
        $field->{_imp_datetype} = 'DATE';
    }
    unless ($field->{DATATYPE})
    {
        $field->{DATATYPE} = $field->{_imp_datetype} if $field->{_imp_datetype};
    }
    my $dval = $io->default_value($fname);
    # Dates cannot have default values from the data dictionary, I don't want to bother with formatting them!
    undef($dval) if $field->{_imp_datetype};
    $field->{DEFAULT_VALUE} = $dval unless length($field->{DEFAULT_VALUE}) || !length($dval);
    $field->{REQUIRED} = ($io->required($fname) ? 'Y' : undef) unless $field->{REQUIRED};
    my $flen = $io->field_length($fname);
    if ($field->{DATATYPE} eq 'DATE')
    {
##at const depends on output date format
        $flen = 11;
    }
    elsif ($field->{DATATYPE} eq 'DATETIME')
    {
##at const depends on output date format
        $flen = 17;
    }
    $field->{INPUT_SIZE} = ($flen > $CGI::AutoForm::DEFAULT_FIELD_LENGTH ? $CGI::AutoForm::DEFAULT_FIELD_LENGTH : $flen)
        unless $field->{INPUT_SIZE};
    $field->{INPUT_MAXLENGTH} = $flen unless $field->{INPUT_MAXLENGTH};
    return $field;
}

# Set the html attribute of $field with, and return a string of HTML
# according to INPUT_CONTROL_TYPE.
# Note that INPUT_CONTROL_TYPE may have been set by _export_field() depending
# on the way $field will be used in the form.
sub field_html
{
    my ($self,$field) = @_;
    my $type = $self->control_type($field);
    if ($type eq 'TEXT' || $type eq 'PASSWORD' || $type eq 'MATCH TEXT' || $type eq 'COMMALIST')
    {
        return ($field->{html} = $self->text_pass_html($field,$type));
    }
    elsif ($type eq 'TEXTAREA')
    {
        return ($field->{html} = $self->textarea_html($field));
    }
    elsif ($type eq 'SELECT')
    {
        return ($field->{html} = $self->select_html($field));
    }
    elsif ($type eq $CGI::AutoForm::DISPLAY_ONLY_GROUP)
    {
        return ($field->{html} = $self->display_html($field));
    }
    elsif ($type eq 'CHECKBOX' or $type eq 'CHECKGROUP')
    {
        return ($field->{html} = $self->checkbox_html($field));
    }
    elsif ($type eq 'RADIO')
    {
        return ($field->{html} = $self->radio_html($field));
    }
    elsif ($type eq 'FILE')
    {
        return ($field->{html} = $self->fileupload_html($field));
    }
    else
    {
        die("Field type [$type] not recognized for $field->{FIELD_NAME}");
        return undef;
    }
}

# File type input.
##at not sure if the comments below are correct?
## In order for file uploads to work on a form,
## the enctype="file" attribute needs to be added to the form tag.
sub fileupload_html
{
    my ($self,$field) = @_;

    my $need_req = $field->{REQUIRED} eq 'Y';
    my $need_req_class = 0;
    if ($need_req)
    {
        $need_req_class = 1 unless $field->{ELEMENT_ATTRS} =~ 
            s/CLASS\s*=\s*['"]?(.*?)['"]?/CLASS="$1 REQI"/i;
    }

    my $name = qq[name="] . $self->escape($field->{FORM_ELEMENT_NAME}) . qq["];
    my $class = $need_req_class ? qq[CLASS="REQI" ] : "";
    my $attrs = $field->{ELEMENT_ATTRS};

    my $html = qq[<input type="file" $class $name $attrs>];

    $self->{form_enctype_attr} = qq[enctype="multipart/form-data"];

    return $html;
}

# A checkbox field results in a series of checkboxes, one for each
# PICK_LIST element, multiple values may be checked for the same field.
# A PICK_LIST attribute of $field is necessary (see create_field())

# The default layout of the checkboxes will be a tabular with
# $CGI::AutoForm::DEFAULT_RADIO_CHECKBOX_COLS number of rows, this can
# be overridden by specifying UI_TABLE_COLUMN.RADIO_CHECKBOX_COLS
sub checkbox_html
{
    my ($self,$field) = @_;

    my %checked;
    if (ref($field->{VALUE}) eq 'ARRAY')
    {
        map { $checked{$_} = 'CHECKED ' } (@{$field->{VALUE}});
    }
    elsif (!ref($field->{VALUE}))
    {
        $checked{$field->{VALUE}} = 'CHECKED ' if defined($field->{VALUE});
    }
    else
    {
        die "A horrible death";
    }

    my $need_req = $field->{REQUIRED} eq 'Y';
    my $need_req_class = 0;
    if ($need_req)
    {
        $need_req_class = 1 unless $field->{ELEMENT_ATTRS} =~ s/CLASS\s*=\s*['"]?(.*?)['"]?/CLASS="$1 REQI"/i;
    }

##at should have a {RADIO_CHECKBOX_COLS} = 0 where no <TABLE> and related tags are generated
    my $ret = '<TABLE><TR>';
    my $i;
    my $cols = ($field->{RADIO_CHECKBOX_COLS} ? $field->{RADIO_CHECKBOX_COLS} : $CGI::AutoForm::DEFAULT_RADIO_CHECKBOX_COLS);
    foreach my $opt (@{$field->{PICK_LIST}})
    {
        my $new_row = $i && !($i % $cols);
        $new_row && ($ret .= '</TR><TR>');

        $ret .= '<TD><INPUT TYPE="CHECKBOX" ' .
        qq[NAME="] . $self->escape($field->{FORM_ELEMENT_NAME}) . '" ' .
        qq[VALUE="] . $self->escape($opt->{ID}) . '" ' .
        $checked{$opt->{ID}} .
        ($need_req_class ? qq[CLASS="REQI" ] : "") .
        "$field->{ELEMENT_ATTRS}>" .
        $self->escape($opt->{MASK}) . '</TD>';
        $i++;
    }
    $ret .= '</TR></TABLE>';
    return $ret;
}

# A radio field results in an HTML radio control group
# where each element can be toggled but only 1 element
# in the group can be in the on position. This differs from
# a checkbox group in that the field can have only 1 value.
# Choices for the field value are taken from the field's PICK_LIST;
# a PICK_LIST attribute of $field must exist (see create_field())

# Refer to checkbox_html() for a description of the layout of the
# radio group.
sub radio_html
{
    my ($self,$field) = @_;
    my $val = $field->{VALUE};
    ref($val) && (die("Radio groups cannot be muti-valued"),return undef);
    my %checked;
    $checked{$val} = 'CHECKED ' if defined($val);
    my $ret = '<TABLE><TR>';
    my $i;
    my $cols = ($field->{RADIO_CHECKBOX_COLS} ? $field->{RADIO_CHECKBOX_COLS} : $CGI::AutoForm::DEFAULT_RADIO_CHECKBOX_COLS);

    my $need_req = $field->{REQUIRED} eq 'Y';
    my $need_req_class = 0;
    if ($need_req)
    {
        $need_req_class = 1 unless $field->{ELEMENT_ATTRS} =~ s/CLASS\s*=\s*['"]?(.*?)['"]?/CLASS="$1 REQI"/i;
    }

    foreach my $opt (@{$field->{PICK_LIST}})
    {
        my $new_row = $i && !($i % $cols);
        $new_row && ($ret .= '</TR><TR>');

        $ret .= '<TD><INPUT TYPE="RADIO" ' .
        qq[NAME="] . $self->escape($field->{FORM_ELEMENT_NAME}) . '" ' .
        qq[VALUE="] . $self->escape($opt->{ID}) . '" ' .
        $checked{$opt->{ID}} .
        ($need_req_class ? qq[CLASS="REQI" ] : "") .
        "$field->{ELEMENT_ATTRS}>" .
        $self->escape($opt->{MASK}) . '</TD>';
        $i++;
    }
    $ret .= '</TR></TABLE>';
    return $ret;
}

##at new field_group of 'COMBO' would be nice to accept free-form or a select list

sub display_html
{
    my ($self,$field) = @_;
    my $val = $field->{DISPLAY_VALUE};
    my $dval = '';
    if (ref($val))
    {
        foreach my $v (@$val)
        {
            $dval .= $self->escape($val) . '<BR>';
        }
        chop($dval);
        chop($dval);
        chop($dval);
        chop($dval);
    }
    else
    {
        $dval = $self->escape($val);
        $dval =~ s/\r?\n/<BR>/gs;
    }
    return $dval;
}

sub select_html
{
    my ($self,$field) = @_;

    my $need_req = $field->{REQUIRED} eq 'Y';
    my $need_req_class = 0;
    if ($need_req)
    {
        $need_req_class = 1 unless $field->{ELEMENT_ATTRS} =~ s/CLASS\s*=\s*['"]?(.*?)['"]?/CLASS="$1 REQI"/i;
    }

    my $ret = '<SELECT ' .
        qq[NAME="] . $self->escape($field->{FORM_ELEMENT_NAME}) . '" ' .
        "$field->{ELEMENT_ATTRS} " .
        ($need_req_class ? qq[CLASS="REQI" ] : "");

    my %selected;
    if (ref($field->{VALUE}) eq 'ARRAY')
    {
        map { $selected{$_} = 'SELECTED ' } (@{$field->{VALUE}});
    }
    elsif (!ref($field->{VALUE}))
    {
        $selected{$field->{VALUE}} = 'SELECTED ' if defined($field->{VALUE});
    }
    else
    {
        die "The value of $field->{FIELD_NAME} must be an array ref or scalar, found [$field->{VALUE}]";
    }

    my $usage = $self->group_usage();
    if ($usage eq $CGI::AutoForm::SEARCH_GROUP)
    {
        $ret .= ($field->{SEARCH_MULT_SELECT} ? qq[MULTIPLE SIZE="$field->{SEARCH_MULT_SELECT}" ] : '');
    }
    $ret .= '>';
    unless ($need_req)
    {
        $ret .= '<OPTION VALUE="" ' . (%selected ? '' : 'SELECTED ') . '>&nbsp;</OPTION>';
    }

    foreach my $opt (@{$field->{PICK_LIST}})
    {
        $ret .= qq[<OPTION VALUE="] . $self->escape($opt->{ID}) . qq[" $selected{$opt->{ID}}>] . $self->escape($opt->{MASK}) . '</OPTION>';
    }
    $ret .= '</SELECT>';
    return $ret;
}

sub text_pass_html
{
    my ($self,$field,$type) = @_;

    my $html_type = $type;

    my $need_req = $field->{REQUIRED} eq 'Y';
    my $need_req_class = 0;
    if ($need_req)
    {
        $need_req_class = 1 unless $field->{ELEMENT_ATTRS} =~ s/CLASS\s*=\s*['"]?(.*?)['"]?/CLASS="$1 REQI"/i;
    }

    my $val = $field->{VALUE};

    $self->{_ast_match}++,$html_type = 'TEXT' if $type eq 'MATCH TEXT';

    if ($type eq 'COMMALIST')
    {
        $self->{_cst_match}++;
        $html_type = 'TEXT';
        undef($field->{INPUT_MAXLENGTH});
        $field->{INPUT_SIZE} *= 2;
        $val = join(',',@$val) if ref($val);
    }

    $val = '**INVALID REFERENCE**' if ref($val);

    return qq[<INPUT TYPE="$html_type" ] .
        qq[NAME="] . $self->escape($field->{FORM_ELEMENT_NAME}) . '" ' .
        qq[VALUE="] . $self->escape($val) . '" ' .
        ($field->{INPUT_SIZE} ? qq[SIZE="$field->{INPUT_SIZE}" ] : '') .
        ($field->{INPUT_MAXLENGTH} ? qq[MAXLENGTH="$field->{INPUT_MAXLENGTH}" ] : '') .
        ($need_req_class ? qq[CLASS="REQI" ] : "") .
        "$field->{ELEMENT_ATTRS}>" .
        ($type eq 'MATCH TEXT' ? '**' : '') .
        ($type eq 'COMMALIST' ? '***' : '');
}

sub textarea_html
{
    my ($self,$field) = @_;

    my $need_req = $field->{REQUIRED} eq 'Y';
    my $need_req_class = 0;
    if ($need_req)
    {
        $need_req_class = 1 unless $field->{ELEMENT_ATTRS} =~ s/CLASS\s*=\s*['"]?(.*?)['"]?/CLASS="$1 REQI"/i;
    }

    my $val = $field->{VALUE};
    $val = '**INVALID REFERENCE**' if ref($val);

    return '<TEXTAREA ' .
        qq[NAME="] . $self->escape($field->{FORM_ELEMENT_NAME}) . '" ' .
        ($need_req_class ? qq[CLASS="REQI" ] : "") .
        "$field->{ELEMENT_ATTRS}>" .
        $self->escape($val,1) .
        '</TEXTAREA>';
}

=pod

=head2 HTML Generation and Other Accessors

=item C<hidden>


C<hidden> is a form object attribute that stores a hashref of name => value
pairs that will be included as hidden INPUT form elements.
The hash can be accessed via this method or directly with $form->{hidden}.

The values of the hash can be a scalar or an array ref where multiple form elements of
the same name for each array value will be rendered.

You can add/remove keys from this hash but don't replace it as it is updated internally.
Keys will be removed internally if they conflict with updatable/insertable visible
form fields.
Keys may be overwritten if $query is used (see C<prepare>) or by C<add_record()>
for an updatable group.

The HTML from this hash is automatically stored in the html attr.

=cut
sub hidden
{
    my ($self,$hidden) = @_;
    if (defined($hidden))
    {
        $self->{hidden} = $hidden;
    }
    return $self->{hidden};
}

=pod

=item C<hidden_html>

 $html_block = $form->hidden_html();

Create a block of HTML hidden INPUT elements
using the $form->{hidden} attribute hash.

=cut
sub hidden_html
{
    my ($self) = @_;
    my ($name,$val);
    my $ret;
    while (($name,$val) = each(%{$self->{hidden}}))
    {
        if (!ref($val))
        {
            $val = [ $val ];
        }
        elsif (!(ref($val) eq 'ARRAY'))
        {
            die "The hidden field [$name] must be an array ref or scalar, found [$val]";
        }

        foreach my $subval (@$val)
        {
            $ret .= qq[<INPUT TYPE="HIDDEN" NAME="] . $self->escape($name) . '" VALUE="' . $self->escape($subval) . '">';
        }
    }
    $self->{hidden_html} = $ret;
    return $ret;
}

# create a copy of $field processing and return the new $field
sub _export_field
{
    my ($self,$field) = @_;
    $field = { %$field };
    my $usage = $self->group_usage();

    # First check if its read-only at the record level
    # because an updatable record might have a read-only field
    # which will be handled differently in the updatable context
    if ($self->is_readonly())
    {
        return $self->_export_ro($field);
    }
    elsif ($usage eq $CGI::AutoForm::EDIT_GROUP)
    {
        return $self->_export_update($field);
    }
    elsif ($usage eq $CGI::AutoForm::SEARCH_GROUP)
    {
        return $self->_export_search($field);
    }
    elsif ($usage eq $CGI::AutoForm::INSERT_GROUP)
    {
        return $self->_export_insert($field);
    }
    else
    {
        die("Group type [$usage] not recognized");
    }
}

# add to hidden a record from {data} if it exists
sub _export_update
{
    my ($self,$field) = @_;
    my ($rec,$val);
    my $isdate = _isdate($field);
    my $fname = $field->{FIELD_NAME};
    my $gname = $self->current_group_name();
    $rec = $self->{struct_query}{$gname};

# may have empty records if no fields in the record require a value
#    unless (($rec = $self->{struct_query}{$gname}) && ref($rec))
#    {
#        die("No record exists for field: " . $fname);
#        return undef;
#    }

    if ($self->is_readonly($field))
    {
        $self->_assign_ro_val($field,$rec->{$fname},$isdate);
    }
    else
    {
        $val = $self->_extract_query_val($fname);
        if ($self->_isdate_inscontrol($field))
        {
            return $self->expand_date_fields($field,$val);
        }
        else
        {
            if ($field->{INPUT_CONTROL_TYPE} eq 'CHECKGROUP')
            {
                $val = [ split($field->{MULTI_INSERT_DELIMITER}, $val) ];
            }
            $field->{VALUE} = $val;
        }
    }
    my $group = $self->current_group();
    push(@{$group->{export_rec}[$self->{curr_rec_no}]},$field);
    return $field;
}

##at a query must only be introduced through prepare() in order for it to be cleaned,
##at structured and recognized properly in next_field()

# some elements of hidden may be deleted if _extract_query_val() is called with $delete_end = TRUE (currently only true if 'INSERTABLE')

# delete query element(s) and if last field in rec, delete all query elements of that group
sub _extract_query_val
{
    my ($self,$fname,$delete_end) = @_;
    my ($rec,$val);
##at for updates, $form_pre must match $fen exactly for this to work
    my $form_pre = $self->current_group_name() . '.' . $fname;
    my $hidden = $self->hidden();
    $val = $hidden->{$form_pre};

    delete($hidden->{$form_pre});
    if ($delete_end)
    {
        my $field_list = $self->field_list();
        $self->delete_hidden_group() if ($self->{curr_field_no} == $#$field_list);
    }
    return $val;
}

sub delete_hidden_group
{
    my ($self) = @_;
    my $hidden = $self->hidden();
    my $name = $self->current_group_name();
    $name = quotemeta($name);
    foreach my $field_name (keys(%$hidden))
    {
        delete($hidden->{$field_name}) if $field_name =~ /^$name\./;
    }
    return $hidden
}

##at should be able to give an insert group default values and have some of those default values
##at be non-insertable but simply informational so that the user knows what its value will be
##at and can't change it this will require an insert group supporting readonly fields

sub _export_insert
{
    my ($self,$field) = @_;
    return 0 unless $field->{INSERTABLE} eq 'Y';
    my ($rec,$val);
    if (exists($self->{struct_query}{$self->current_group_name()}))
    {
        $val = $self->_extract_query_val($field->{FIELD_NAME},1);
    }
    elsif ($rec = $self->current_record())
    {
        $val = $rec->{$field->{FIELD_NAME}};
        $val = $field->{DEFAULT_VALUE} if !length($val) && $self->{coalesce_default_insert};
    }
    else
    {
        $val = $field->{DEFAULT_VALUE};
    }

    if ($self->_isdate_inscontrol($field))
    {
        return $self->expand_date_fields($field,$val);
    }
    elsif ($field->{FIELD_GROUP} eq 'CONFIRM')
    {
        # Only for inserts
        return $self->expand_confirm_fields($field);
    }
    if ($field->{INPUT_CONTROL_TYPE} eq 'CHECKGROUP')
    {
        $val = [ split($field->{MULTI_INSERT_DELIMITER}, $val) ];
    }
    $field->{VALUE} = $val;
    my $group = $self->current_group();
    push(@{$group->{export_rec}[$self->{curr_rec_no}]},$field);
    return $field;
}

# Only for inserts
sub expand_confirm_fields
{
    my ($self,$field) = @_;
    my $new_field = { %$field };
    $new_field->{FIELD_NAME} = '_CONFIRM1';
    my $conf = _copy_field($new_field,$field);
    $conf = $self->create_field($conf);
    my $group = $self->current_group();
    push(@{$group->{export_rec}[$self->{curr_rec_no}]},$conf);
    $new_field->{FIELD_NAME} = '_CONFIRM2';
    my $conf2 = _copy_field($new_field,$field);
    $conf2 = $self->create_field($conf2);
    $conf2->{HEADING} = 'Re-enter';
    push(@{$group->{export_rec}[$self->{curr_rec_no}]},$conf2);

    return [ $conf,$conf2 ];
}

sub _isdate
{
    my ($field) = @_;
    return ($field->{DATATYPE} eq $DBIx::IO::GenLib::DATE_TYPE || $field->{DATATYPE} eq $DBIx::IO::GenLib::DATETIME_TYPE);
}

sub _isdate_inscontrol
{
    my ($self,$field) = @_;
    my $type = $self->control_type($field);
    return ($type eq 'DATE' || $type eq 'DATETIME');
}

sub _export_search
{
    my ($self,$field) = @_;
    return 0 unless $field->{SEARCHABLE} eq 'Y';
    my $qhit;
    my $gname = $self->current_group_name();
    my $fname = $field->{FIELD_NAME};
    $qhit++ if (exists($self->{struct_query}{$gname}));
    my $rec = $self->current_record();
    ref($rec) && (die("Data record exists for search crit"),return undef);
    my $type = $field->{SEARCH_CONTROL_TYPE};
    if ($type eq 'DATERANGE' || $type eq 'DATETRANGE')
    {
        my ($ur,$rs,$re);
        if ($qhit)
        {
            $ur = $self->_extract_query_val("$fname._UR");
            $rs = $self->_extract_query_val("$fname._RS");
            $re = $self->_extract_query_val("$fname._RE",1);
        }
        return $self->expand_date_search_fields($field,$ur,$rs,$re);
    }
    elsif ($type eq 'DATE' || $type eq 'DATETIME')
    {
        my $dval = '_SYSDATE';
        $dval = $self->_extract_query_val($fname,1) if ($qhit);
        return $self->expand_date_fields($field,$dval);
    }
    elsif ($type eq 'RANGE')
    {
        my ($rs,$re);
        if ($qhit)
        {
            $rs = $self->_extract_query_val("$fname._RS");
            $re = $self->_extract_query_val("$fname._RE",1);
        }
        return $self->expand_range_fields($field,$rs,$re);
    }
    elsif ($type eq 'MATCH TEXT')
    {
        $field->{VALUE} = $self->_extract_query_val("$fname._WM",1) if ($qhit);
    }
    elsif ($type eq 'COMMALIST')
    {
        $field->{VALUE} = [split(/,/,$self->_extract_query_val("$fname._CL",1))] if ($qhit);
    }
    else
    {
        $field->{VALUE} = $self->_extract_query_val($fname,1) if ($qhit);
    }
    my $group = $self->current_group();
    push(@{$group->{export_rec}[$self->{curr_rec_no}]},$field);
    return $field;
}

sub expand_range_fields
{
    my ($self,$field,$rs,$re) = @_;
    my @fields;
    my $startf = _copy_field($start_range_field,$field);
    $startf = $self->create_field($startf);
    $startf->{VALUE} = $rs;
    push(@fields,$startf);
    my $endf = _copy_field($end_range_field,$field);
    $endf = $self->create_field($endf);
    $endf->{VALUE} = $re;
    push(@fields,$endf);
    my $group = $self->current_group();
    push(@{$group->{export_rec}[$self->{curr_rec_no}]},@fields);
    return \@fields;
}

# set the read-only flag according to form -> group -> if read-only, do not transmit form element properties
sub _export_ro
{
    my ($self,$field) = @_;
    my ($rec,$val);
    my $isdate = _isdate($field);

    my $usage = $self->group_usage();
    my $group = $self->current_group();

    # Check $group->{data} BEFORE any {hidden} fields because an incomplete record may be passed
    # around in the hidden fields but display of the full record is normally desired
    # e.g. passing around the record's PK is useful but the full record should be displayed
    if ($rec = $self->current_record())
    {
    }
    elsif (exists($self->{struct_query}{$self->current_group_name()}))
    {
        $rec = $self->{struct_query}{$self->current_group_name()};
    }

    $rec = {} unless $rec;

    # If the group is being used for display, then display only those values contained in $rec
    # If the original group usage is other than DISPLAY ONLY, we want to show all user input, and lack of input
    # e.g. if we're conducting a session and are showing the summary screen, any fields left blank by the user should be revealed
    # unless the field is empty and the user is not allowed to enter a value for the field
    exists($rec->{$field->{FIELD_NAME}}) || return 0 if ($usage eq $CGI::AutoForm::DISPLAY_ONLY_GROUP && !$group->{tabular}) ||
        ($usage eq $CGI::AutoForm::INSERT_GROUP && $field->{INSERTABLE} ne 'Y') ||
        ($usage eq $CGI::AutoForm::EDIT_GROUP && $field->{UPDATABLE} ne 'Y') ||
        ($usage eq $CGI::AutoForm::SEARCH_GROUP && $field->{SEARCHABLE} ne 'Y');

    $val = $rec->{$field->{FIELD_NAME}};

    $self->_assign_ro_val($field,$val,$isdate);
    push(@{$group->{export_rec}[$self->{curr_rec_no}]},$field);
    return $field;
}

sub _assign_ro_val
{
    my ($self,$field,$val,$isdate) = @_;
    $val = _display_normal_date($val,$field->{DATATYPE}) if ($isdate);

    if ($field->{INPUT_CONTROL_TYPE} eq 'CHECKGROUP' && ref($field->{PICK_HASH}))
    {
        foreach my $sp (split($field->{MULTI_INSERT_DELIMITER},$val))
        {
            $field->{DISPLAY_VALUE} .= (exists($field->{PICK_HASH}{$sp}) ? $field->{PICK_HASH}{$sp} : 'INVALID!') . ', ';
        }
        chop($field->{DISPLAY_VALUE});
        chop($field->{DISPLAY_VALUE});
    }
    else
    {
        $field->{DISPLAY_VALUE} = (ref($field->{PICK_HASH}) ? $field->{PICK_HASH}{$val} : $val);
    }

    $field->{INPUT_CONTROL_TYPE} = $CGI::AutoForm::DISPLAY_ONLY_GROUP;
    delete($field->{FORM_ELEMENT_NAME});
}

sub _display_normal_date
{
    my ($dateval,$type) = @_;
    my ($year,$mon,$day,$hr,$min,$sec) = $dateval =~ /(\d\d\d\d)(\d\d)(\d\d)(\d\d)?(\d\d)?(\d\d)?/;
    my $date = $day . '-' . substr($months[$mon],0,3) . '-' . $year;
    if ($type eq $DBIx::IO::GenLib::DATE_TYPE)
    {
        return $date;
    }
    elsif ($type eq $DBIx::IO::GenLib::DATETIME_TYPE)
    {
        return "$date $hr:$min";
    }
    else
    {
        die("Invalid date type: $type");
        return undef;
    }
}

=pod

=item C<prepare>

 $form_html = $self->prepare([$query],[$val_callback],[$rec_callback],[$head_callback]);

$query can be given to impose a state on forms
between instantiations via otherwise stateless HTTP (see also CGI::AutoForm::Session).
$query is a hashref of NAME => value pairs where the value can be a scalar or arrayref.
An arrayref is used where NAME is associated with more than one value. $query is typically
derived from a GET query string or POST name=value pairs from an HTTP response.

If present, $query values are sticky in the sense that they
will override any defaults and any values introduced with C<add_record>.

For vertical views (insert/update groups), assign values to the fields
according to the following priority scheme:
 1) If a query was submitted, use it as a source of data if it has values for the current group.
 2) If a current record exists for the current group, use it as a data source.
 3) Use the field's DEFAULT_VALUE attribute, if any.
 The exception here is that if the $form->{coalesce_default_insert} attribute is true then:
 Use the value from current record if it exists
 otherwise use the DEFAULT_VALUE attribute, if any.


To give you more control over the HTML that is generated, callback functions are accepted.
$head_callback and $val_callback functions will be called for each field in the form as (except for tabular groups where $head_callback is not called at all):

 &callback($value,$field,$form)

and must return the desired HTML snippet for that element. $field is a hashref of all columns
in UI_TABLE_COLUMN plus any added by this class while processing (see C<create_field>). $form is the form object.

For $head_callback, $value will be the heading text to be displayed for each field.

For $val_callback, $value will be the display value or HTML form input element
depending on the type of data group it is part of (read-only/writable).

For $rec_callback, the prototype follows:

 &callback($value,$field,$group,$form)

where $value will be the entire HTML row C<tr> block and $group is the data group structure.
For a tabular display of search results, $field will instead be the data record for that row (hashref of NAME => value pairs).

An ugly, unformatted gob of HTML is returned as a scalar reference for performance reasons.
If only certain parts of the HTML generated are useful, the following attributes can
be used to extract certain sections. Some can also be completely overridden
if defined before calling this method (see B<Form preparation, HTML generation & customization>), in which case they should contain certain opening/closing HTML elements
noted below:

For each field in $group->{export_rec}:
 $field->{html}

Note that the export_rec attr for each group is only available
after calling this method.

For each $group in $form:

 $group->{html}, a composite of:
 $group->{head_html} (must contain the opening C<table> tag)
 $group->{body_html}
 $group->{tail_html} (must contain the closing C<table> tag)
 
 $form->{body_html}, a composite of:
 $form->{hidden_html}
 $group->{html} for each group in $form
 
 $form->{html}, a composite of:
 $form->{head_html} (must contain the opening C<form> tag)
 $form->{body_html}
 $form->{tail_html} (must contain the closing C<form> tag and submit button)

=cut
##at how about a group_callback???
##at default head and tail html (and other default HTML) should be available as a constant
# populate export attr of each group and integrate query into hidden fields
# the query passed in will be structured, date compressed, and validated (see structure_query(),validate_query())
#
# Advanced:
# All $query values will be also added to the form's hidden attribute, except if they
# have been used to override values in the current form (we don't want to confuse these with data
# submitted by the operator).

sub prepare
{
    my ($self,$query,$val_callback,$rec_callback,$head_callback) = @_;
    $self->{val_callback} = $val_callback;
    $self->{head_callback} = $head_callback;
    $self->{rec_callback} = $rec_callback;
    $query ||= {};
    my $hidden = $self->hidden();
    my ($key,$val);

    # this will overwrite any values for keys in {hidden} with those values in $q
    while (($key,$val) = each(%$query))
    {
        $hidden->{$key} = $val;
    }
    $self->{hidden} = $self->normalize_query($hidden);
    $self->{struct_query} = $self->structure_query($self->{hidden});
    $self->prepare_export();
    return \$self->{html};
}

##at should have a <NOSCRIPT> html tag to explain that the header help links will not be accessible

sub prepare_export
{
    my ($self) = @_;
    $self->reset_group();
    my ($group,$field_s);
    while ($group = $self->next_group())
    {
        my $record;
        my $rec_no;
        my $rec_count = $#{$group->{data}};
##at sharing $hidden with $record (in add_record()) is a bad idea could cause discrepancies below
##at are you sure?? I think if the user keeps their own namespace when using hidden there should be no problems???
##at what is really happening is that whatever is in hidden will take precedence over parameter keys in $record
        while ($record = $self->next_record())
        {
            my $head_rec;
            my $fields;
            my $tail_rec = 0;
            if ($group->{tabular} && $rec_no == 0)
            {
                (($group->{body_html} = "No records found"),next) unless %$record;
                $head_rec = '<THEAD><TR>';
            }
            if ($group->{tabular} && $rec_no == $rec_count)
            {
                $tail_rec = 1;
            }
            while ($field_s = $self->next_field())
            {
                $fields .= $self->field_group_html($field_s,$group,undef,($head_rec ? \$head_rec : undef()),$tail_rec);
            }
            if ($group->{tabular})
            {
                if ($rec_no == 0)
                {
                    $head_rec .= '</TR></THEAD>';
                    $group->{body_html} .= $head_rec;
                }
                $fields = &{$self->{rec_callback}}($fields,$record,$group,$self) if ref($self->{rec_callback}) eq 'CODE';
                $fields = "<TR" . ($tail_rec ? ' '.$group->{TABULAR_TR_TAIL_ATTRS} . ' CLASS="GTAIL_TR"' : '') . ">$fields</TR>";
            }
            $group->{body_html} .= $fields;
            $rec_no++;
        }
        $group->{body_html} = qq[<SCRIPT LANGUAGE="JavaScript"><!--\r\n$group->{js}\r\n--></SCRIPT>$group->{body_html}] if $group->{js};
##at for each css class there should be a form/group object attribute
##at with the same name as the class, any HTML attributes it contains will be inserted into the tag after the CLASS attr
        # GT => group table GH => Group Heading
        $group->{head_html} = qq[<DIV CLASS="GH">$group->{heading}</DIV><TABLE CLASS="GT" $self->{GT}>] unless defined($group->{head_html});
        $group->{tail_html} = qq[</TABLE>] unless defined($group->{tail_html});
        $group->{html} = "$group->{head_html}$group->{body_html}$group->{tail_html}";
        $self->{body_html} .= "<P>$group->{html}</P>";
    }
    $self->{heading} = qq[<H2>$self->{heading}</H2>] if $self->{heading};
    $self->{head_html} = qq[$self->{heading}<FORM NAME="$self->{name}" ACTION="$self->{action}" METHOD="POST" $self->{form_enctype_attr}>]
        unless defined($self->{head_html});
    if ($self->{valid_error})
    {
        $self->{verr_msg} = '!----INPUT ERROR: Please correct the fields marked below----!' unless $self->{verr_msg};
        $self->{head_html} .= qq[<P><B><FONT COLOR="RED"><DIV ALIGN="CENTER" CLASS="VERR_MSG">$self->{verr_msg}</DIV></FONT></B></P>];
    }
    my $submit_val = $self->escape($self->{submit_value});
    $submit_val = qq[VALUE="$submit_val"] if length($self->{submit_value});
##at shouldn't use WIDTH and ALIGN attrs - use classes/CSS instead
    $self->{tail_html} = qq[<P><TABLE WIDTH="100%"><TR><TD style="text-align: right;"><INPUT $self->{submit_button_attrs} TYPE="RESET"></TD><TD style="width: 30px;"></TD>] .
        qq[<TD style="text-align: left;"><INPUT $self->{submit_button_attrs} TYPE="SUBMIT" $submit_val></TD></TR></TABLE></P></FORM>] unless defined($self->{tail_html});
    $self->{tail_html} .= qq[<DIV>* Indicates required field</DIV>] if $self->{ast_foot};
    my $wmess = $self->escape("** Field accepts '\%' as a wildcard matching operator");
    my $cmess = $self->escape("*** Field accepts a comma-separated list of values");
    $self->{tail_html} .= qq[<DIV>$wmess</DIV>] if $self->{_ast_match};
    $self->{tail_html} .= qq[<DIV>$cmess</DIV>] if $self->{_cst_match};
    $self->{body_html} = $self->hidden_html() . $self->{body_html};
    my $tmess = $self->{top_message};
    my $noscript = '';
    $noscript = qq[<NOSCRIPT><P>$self->{noscript}</NOSCRIPT>] if $self->{noscript};
    $self->{html} = "$noscript$tmess$self->{head_html}$self->{heading2}$self->{body_html}$self->{tail_html}";
    $self->reset_group();
}

sub field_group_html
{
    my ($self,$field_s,$group,$label_class_add,$head_rec,$tail_rec) = @_;
    my ($val,$head,$headadd);
    if (ref($field_s) eq 'ARRAY')
    {
        if (ref($field_s->[1]) eq 'ARRAY')
        {
            if ($self->group_usage() eq $CGI::AutoForm::SEARCH_GROUP)
            {
                # SEARCHABLE date range group
                ($headadd,$val) = $self->search_date_html($field_s,$group);
                $field_s = $field_s->[0];
            }
            elsif ($field_s->[1][0]{FIELD_GROUP} eq 'CONFIRM')
            {
                # For a confirmable date group (will this EVER happen!!)
                my $ret = $self->field_group_html($field_s->[0],$group);

                # using CSS content generation, can set a different heading for CONFIRM fields in the style sheet by setting a class property
                $ret .= $self->field_group_html($field_s->[1],$group,'CONFIRM') unless $group->{tabular};
                return $ret;
            }
            else { die "A horrible death"; }
        }
        elsif (substr($field_s->[0]{FORM_ELEMENT_NAME},-6) eq '_MONTH')
        {
            # Must be a date group
            $val .= '<TABLE BORDER="0" CELLSPACING="0" CELLPADDING="0"><TR>';
            $val .= $self->date_group_html($field_s);
            $val .= '</TR></TABLE>';
            $field_s = $field_s->[0];
        }
        elsif ($self->group_usage() eq $CGI::AutoForm::SEARCH_GROUP)
        {
            # Must be a plain search range with 'TEXT' controls
            $val = $self->search_range_html($field_s,$group);
            $field_s = $field_s->[0];
        }
        elsif ($field_s->[0]{FIELD_GROUP} eq 'CONFIRM')
        {
            my $ret = $self->field_group_html($field_s->[0],$group);
            $ret .= $self->field_group_html($field_s->[1],$group,'CONFIRM') unless $group->{tabular};
            return $ret;
        }
        else { die "A horrible death"; }
    }
    else
    {
        $val = $self->field_html($field_s);
    }
    
    if ($group->{tabular})
    {
        return '' unless length($field_s->{BRIEF_HEADING});
        if ($head_rec)
        {
            $head = $self->escape($field_s->{BRIEF_HEADING});
##at could also support TABULAR_TH_ATTRS, TABULAR_TD_ATTRS, etc management by adding it to UI_TABLE_COLUMN and pod up
            $$head_rec .= qq[<TH CLASS="TABULAR_TH" $group->{TABULAR_TH_ATTRS} $field_s->{TABULAR_TH_ATTRS}>$head</TH>];
        }
        $val = &{$self->{val_callback}}($val,$field_s,$self) if ref($self->{val_callback});
        if ($tail_rec && $group->{TABULAR_TD_TAIL_STYLE})
        {
            $field_s->{TABULAR_TD_STYLE} .= $group->{TABULAR_TD_TAIL_STYLE};
        }
        my $style = '';
        if ($field_s->{TABULAR_TD_STYLE})
        {
            $style = qq[style="$field_s->{TABULAR_TD_STYLE}"];
        }
        return "<TD" . ($field_s->{VALID_ERROR} ? ' CLASS="VERR TABULAR_TD"' : ' CLASS="TABULAR_TD"') . " $field_s->{TABULAR_TD_ATTRS}" .
            ($tail_rec ? ' '. $group->{TABULAR_TD_TAIL_ATTRS} : '') . " $style>" . (length($val) ? $val : '&nbsp;' ) . "</TD>";
    }
    else
    {
        my $valerr = $self->escape($field_s->{VALID_ERROR});
        $head = $self->escape($field_s->{HEADING});
        $head = $self->_process_field_head($field_s,$head,$group);

        # all callbacks must be responsible for escaping any added HTML
        $val = &{$self->{val_callback}}($val,$field_s,$self) if ref($self->{val_callback});

        my $class;
        $class .= "$label_class_add " if $label_class_add;
        $class .= "REQ " if $field_s->{REQUIRED} eq 'Y';
        $class .= "VERR " if $valerr;
        chop($class);
        $class = qq[ CLASS="$class" ] if $class;
        $headadd = qq[<P>$headadd</P>] if $headadd;

        # this can be overridden on-the-fly also
        $valerr = qq[<FONT COLOR="RED" CLASS="VERR"><SPAN CLASS="VERR">$valerr</SPAN></FONT>]
            if $valerr;

        my $ret = qq[<TD CLASS="VFL" $self->{VFL}><LABEL$class>$head $valerr</LABEL>$headadd</TD><TD CLASS="VFE" $self->{VFE}>&nbsp;$val</TD>];
        $ret = &{$self->{rec_callback}}($ret,$field_s,$group,$self) if ref($self->{rec_callback}) eq 'CODE';
        return qq[<TR CLASS="VFR" $self->{VFR}>$ret</TR>];
    }
}

# If callback differs, don't add alert_summary
sub _process_field_head
{
    my ($self,$field_s,$head,$group) = @_;
    # {head_callback} does not apply to tabular headings
    if (ref($self->{head_callback}))
    {
        my $call_head = &{$self->{head_callback}}($head,$field_s,$self);
        return $call_head if $head ne $call_head;
    }
    else
    {
        $head = qq[$head:&nbsp;];
        my $usage = $self->group_usage();
        if (!$self->readonly() && $field_s->{REQUIRED} eq 'Y' && ($usage eq $CGI::AutoForm::INSERT_GROUP || $usage eq $CGI::AutoForm::EDIT_GROUP))
        {
            $head .= '*';
            $self->{ast_foot}++;
        }
    }
    if (length($field_s->{HELP_SUMMARY}))
    {
        my $sum = $field_s->{HELP_SUMMARY};
        $sum =~ s/\"/\\"/gs;
        $sum =~ s/\r?\n/\\n/gs;
        my $func_name = $field_s->{FORM_ELEMENT_NAME};
        $func_name =~ s/\./_/gs;
        $func_name = "${func_name}_ALRT_SUM";
        $group->{js} .= qq[function $func_name(){alert("$sum");}\n];
        $head = qq[<A CLASS="AS" HREF="javascript:$func_name();">$head </A>];
    }
    return $head;
}

=pod

=item C<require_js>

 $form->require_js();

Add a default C<noscript> summary to require the client to support javascript.
You may also set $form->{noscript} yourself.

=cut
sub require_js
{
    my ($self) = @_;
    $self->{noscript} = qq[This application requires that you enable javascript in your browser.<BR>Refer to your browser's documentation] .
        qq[ to enable javascript and then return to this page.];
}

sub search_date_html
{
    my ($self,$field_s,$group) = @_;
    my ($val,$head);
    $val .= '<TABLE BORDER="0" CELLSPACING="0" CELLPADDING="0">';
    $val .= '<TR><TD>Between&nbsp;</TD>' . $self->date_group_html($field_s->[1]) . '</TR>';
    $val .= '<TR><TD>And</TD>' . $self->date_group_html($field_s->[2]) . '</TR>';
    $val .= '<TR><TD>OR within the past&nbsp;</TD>' . $self->date_rel_html($field_s->[3]) . '</TR>';
    $val .= '</TABLE>';
    $head = $self->field_html($field_s->[0]);
    return ($head,$val);
}

sub search_range_html
{
    my ($self,$field_s,$group) = @_;
    my $val;
    $val .= '<TABLE BORDER="0" CELLSPACING="0" CELLPADDING="0">';
    $val .= '<TR><TD>Between&nbsp;</TD><TD>' . $self->field_html($field_s->[0]) . '</TD></TR>';
    $val .= '<TR><TD>And</TD><TD>' . $self->field_html($field_s->[1]) . '</TD></TR>';
    $val .= '</TABLE>';
    return $val;
}

##at should include javascript functions for days of month, leap year, etc
sub date_group_html
{
    my ($self,$dateset) = @_;
    my $ret;
    foreach my $date (@$dateset)
    {
        my ($tit) = $date->{FORM_ELEMENT_NAME} =~ /\.(\w+)$/;
        my $fill;
        if ($tit eq '_MONTH')
        {
            $tit = 'Month';
            $fill = '-';
        }
        elsif ($tit eq '_DAY')
        {
            $tit = 'Day';
            $fill = '-';
        }
        elsif ($tit eq '_YEAR')
        {
            $tit = 'Year';
            $fill = '&nbsp;';
        }
        elsif ($tit eq '_HOUR')
        {
            $tit = 'Hour';
            $fill = ':';
        }
        elsif ($tit eq '_MIN')
        {
            $tit = 'Min';
            $fill = '';
        }
        $ret .= "<TD><DIV>$tit</DIV>". $self->field_html($date) . "$fill</TD>";
    }
    return $ret;
}

sub date_rel_html
{
    my ($self,$dateset) = @_;
    my $ret;
    foreach my $date (@$dateset)
    {
        my ($tit) = $date->{FORM_ELEMENT_NAME} =~ /\.(\w+)$/;
        my $fill;
        if ($tit eq '_QUANT')
        {
            $tit = 'Quantity';
            $fill = '';
            $ret .= "<TD><DIV>$tit</DIV>". $self->field_html($date) . "$fill</TD>";
        }
        elsif ($tit eq '_UNIT')
        {
            $tit = 'Units';
            $fill = '';
            $ret .= "<TD COLSPAN=\"2\"><DIV>$tit</DIV>". $self->field_html($date) . "$fill</TD>";
        }
    }
    return $ret;
}

=pod

=item C<field_by_name>

 $field = $form->field_by_name($field_name);

Return a hashref of properties for $field_name from the current group including attributes
from UI_TABLE_COLUMN and VALUE that will be displayed determined
from the priority list (see C<prepare> and C<_export_field>).

The returned $field structure is a copy so don't expect to change
its attributes and have them be reflected in the generated HTML. To manipulate
field attributes that will affect the generated HTML, access the field hashref
directly using C<$form-E<gt>field_hash()-E<gt>{field_name}>

=cut
sub field_by_name
{
    my ($self,$field_name) = @_;
    $field_name = uc($field_name);
    my $field_hash = $self->field_hash();
    my $field = $field_hash->{$field_name};
    if (defined($field))
    {
        $field = $self->_export_field($field);
    }
    return $field;
}

=pod

=item C<field_list>

 $fields = $form->field_list();

Return a list of fields from the current group.

=cut
sub field_list
{
    my ($self) = @_;
    my $group = $self->current_group();
    return $group->{field_list};
}

=pod

=item C<field_hash>

 $fields = $form->field_hash();

Return a list of fields from the current group.

=cut
sub field_hash
{
    my ($self) = @_;
    my $group = $self->current_group();
    return $group->{field_hash};
}

sub next_record
{
    my ($self) = @_;
    $self->{curr_field_no} = -1;
    my $group = $self->current_group();
    my $rec = $group->{data}[++$self->{curr_rec_no}];
##at if no data exists, an empty record {} will be returned the first time this sub is called for any given group
##at otherwise false will be returned
    !$rec && ($self->{curr_rec_no} == 0) && ($rec = {});
    return $rec;
}

=pod

=item C<next_group>

 $fields = $form->next_group();

Return the next data group structure (hashref) in the list.
Changes state of $form by incrementing curr_group_no.

=cut
sub next_group
{
    my ($self) = @_;
    $self->{curr_field_no} = -1;
    $self->{curr_rec_no} = -1;
    return $self->{group_list}[++$self->{curr_group_no}];
}

sub create_group
{
    my ($self,$table_name,$heading,$group_name,$usage,$tabular) = @_;
    defined($group_name) || ($group_name = $table_name);
    defined($heading) || ($heading = "\u\L$group_name" . ' Info');
    return {
        table_name              => $table_name,
        heading                 => $heading,
        group_name              => uc($group_name),
        data                    => [],
        export_rec              => [],
        usage                   => $usage,
        tabular                 => $tabular,
        field_list              => [],
        field_hash              => {},
    };
}

# hidden namespace issues: if you call add_record() and then try and add hidden fields that
# clash with fields in the record (when using it for an update) the added hidden fields
# will overwrite those added via add_record()
# this is because when using add_record(), it actually adds the record to the hidden field group
# for an updatable group

##at to improve memory usage under mod_perl - it may be useful to audit all refs used
##at from external modules and make sure that they are always cloned so the program
##at doesn't think they will be potentially modified

=pod

=item C<is_readonly>

 $bool = $form->is_readonly([$field]);

Determime if the current data group is read-only, and if the particular $field
is read-only if given. State-dependent.
Search data groups are never read-only.

=cut
# $form cannot be set readonly if one of it's groups is SEARCHABLE
# if $form is set readonly() then this sub will still return false for any groups that are SEARCHABLE
sub is_readonly
{
    my ($self,$field) = @_;
    my $usage = $self->group_usage();
    return 0 if $usage eq $CGI::AutoForm::SEARCH_GROUP;
    return 1 if ($self->readonly() || $usage eq $CGI::AutoForm::DISPLAY_ONLY_GROUP);
    return 1 if $field && $usage eq $CGI::AutoForm::EDIT_GROUP && $field->{UPDATABLE} ne 'Y';
    return 0;
}

sub add_search_date_fields
{
    my ($self,$fields,$attrs,$ur,$rs,$re) = @_;
    $rs ||= '_SYSDATE';
    $re ||= '_SYSDATE';

    my $usef = _copy_field($use_range_field,$attrs,$ur);
    $usef = $self->create_field($usef,$use_range_picklist);
    push(@$fields,$usef);

    my $subfields1 = [];
    my $subfields2 = [];
    my $subfields3 = [];
    if ($attrs->{SEARCH_CONTROL_TYPE} eq 'DATERANGE')
    {
        $self->add_date_fields($subfields1,$attrs,$rs,'_RS');
        $self->add_date_fields($subfields2,$attrs,$re,'_RE');
    }
    else
    {
        $self->add_datetime_fields($subfields1,$attrs,$rs,'_RS');
        $self->add_datetime_fields($subfields2,$attrs,$re,'_RE');
    }
    $self->add_rel_daterange_fields($subfields3,$attrs);
    push(@$fields,$subfields1,$subfields2,$subfields3);
    return $fields
}

sub add_rel_daterange_fields
{
    my ($self,$fields,$attrs) = @_;
    my $relq = _copy_field($rel_quantity_field,$attrs,'','_RS');
    $relq = $self->create_field($relq,undef,undef,undef,1);
    push(@$fields,$relq);
    my $relu = _copy_field($rel_unit_field,$attrs,'','_RS');
    $relu = $self->create_field($relu,$rel_unit_picklist);
    push(@$fields,$relu);

}

sub add_date_fields
{
    my ($self,$fields,$attrs,$dateval,$name_fill) = @_;
    if ($dateval eq '_SYSDATE')
    {
        $dateval = DBIx::IO::GenLib::local_normal_sysdate();
    }
    my ($year,$month,$day);
    if ($dateval =~ /(\d\d\d\d)(\d\d)(\d\d)/)
    {
        ($year,$month,$day) = ($1,$2,$3);
    }
    elsif (length($dateval))
    {
        warn("Date value [$dateval] could not be parsed");
        undef($dateval);
    }

    my $monf = _copy_field($month_field,$attrs,$month,$name_fill);
    $monf = $self->create_field($monf,$month_picklist);
    push(@$fields,$monf);

    my $dayf = _copy_field($day_field,$attrs,$day,$name_fill);
    $dayf = $self->create_field($dayf,$day_picklist);
    push(@$fields,$dayf);

##at had this default to current year but was ambiguous (if an insert/update field is not touched and meant to be null
##at this will cause the validate routine to signal an error) so not suitable for the general public
    $year = $this_year unless $year != 0 || $attrs->{REQUIRED} ne 'Y';
    my $yearf = _copy_field($year_field,$attrs,$year,$name_fill);
##at configurable constant 10
    $yearf = $self->create_field($yearf,[ map { { ID => $_, MASK => $_} } (($this_year-110)..($this_year+10)) ]);
    push(@$fields,$yearf);

    return $dateval;
}

sub add_datetime_fields
{
    my ($self,$fields,$attrs,$dateval,$name_fill) = @_;
    $dateval = $self->add_date_fields($fields,$attrs,$dateval,$name_fill);
    my ($hour,$min) = $dateval =~ /\d\d\d\d\d\d\d\d(\d\d)(\d\d)/;

    my $hourf = _copy_field($hour_field,$attrs,$hour,$name_fill);
    $hourf = $self->create_field($hourf,$hour_picklist);
    push(@$fields,$hourf);
    #$field_hash->{$hourf->{FIELD_NAME}} = $hourf;

    my $minf = _copy_field($min_field,$attrs,$min,$name_fill);
    $minf = $self->create_field($minf,$min_picklist);
    push(@$fields,$minf);
    #$field_hash->{$minf->{FIELD_NAME}} = $minf;

    return $dateval;
}

sub _copy_field
{
    my ($field,$templ,$value,$name_fill) = @_;
    my $target = { %$field };
    $target->{FIELD_NAME} = $templ->{FIELD_NAME} . '.' . (length($name_fill) ? "$name_fill." : '') . $field->{FIELD_NAME};
    $target->{VALUE} = $value;
    foreach my $prop (qw(
        HEADING
        DATATYPE
        REQUIRED
        SEARCHABLE
        UPDATABLE
        INSERTABLE
        FIELD_GROUP
        VALID_ERROR
        SEARCH_MULT_SELECT
        _imp_datetype
        INPUT_SIZE
        INPUT_MAXLENGTH
        ELEMENT_ATTRS
        HELP_SUMMARY
    ))
    {
        $target->{$prop} = $templ->{$prop} if exists($templ->{$prop}) && !exists($target->{$prop});
    }
    return $target;
}

sub expand_date_search_fields
{
    my ($self,$field,$ur,$rs,$re) = @_;
    my $fields = [];
    $self->add_search_date_fields($fields,$field,$ur,$rs,$re);
    my $group = $self->current_group();
    push(@{$group->{export_rec}[$self->{curr_rec_no}]},@$fields);
    return $fields;
}

sub expand_date_fields
{
    my ($self,$field,$dateval) = @_;
    my $fields = [];
    my $type = $self->control_type($field);
    if ($type eq 'DATE')
    {
        $self->add_date_fields($fields,$field,$dateval);
    }
    elsif ($type eq 'DATETIME')
    {
        $self->add_datetime_fields($fields,$field,$dateval);
    }
    else
    {
        die("Date type " . $type . " not recognized");
        return undef;
    }
    my $group = $self->current_group();
    push(@{$group->{export_rec}[$self->{curr_rec_no}]},@$fields);
    return $fields;
}

=pod

=item C<add_record>

 $rec_count = $form->add_record($record[,$group_name]);

Add data to $form's current group (state dependent) or the
group identified by $group_name if given.
$record can be a hashref of FIELD_NAME => value pairs
or an arrayref of such records (for tabular groups of type
'DISPLAY ONLY').

This method should be used for groups of type 'DISPLAY EDIT'
and 'DISPLAY ONLY', which require data to be present (unless passing $query to C<prepare>).

See C<prepare> for assignment priority when using CGI query data.

Returns the number of records currently stored.

=cut
# for edit groups, add to hidden params
##at for updates, only 1 record can be updated at a time

##at could allow add_record() to accept data for SEARCHABLE groups and add the data to query just like UPDATABLE groups
# this can be done by passing a query to prepare(), which is the preferred way.
sub add_record
{
    my ($self,$record,$group_name) = @_;
    my $group;
    if (defined($group_name))
    {
        $group_name = uc($group_name);
        $group = $self->{group_hash}{$group_name};
    }
    else
    {
        $group = $self->current_group();
        $group_name = $self->current_group_name();
    }
    my $usage = $group->{usage};
    if ($usage eq $CGI::AutoForm::EDIT_GROUP)
    {
        # add to hidden
        my ($key,$val);
        while (($key,$val) = each(%$record))
        {
            my $fen = "$group_name.$key";
            $self->{hidden}{$fen} = $val;
        }
    }
    ref($record) eq 'ARRAY' || ($record = [ $record ]);
    return push(@{$group->{data}},@$record);
}

=pod

=item C<current_record>

 $rec = $form->current_record();

Return the current record.
If there is no current record, the first one will be returned and curr_rec_no modified.

=cut
sub current_record
{
    my ($self) = @_;
    my $group = $self->current_group();
    $self->{curr_rec_no} = 0  if $self->{curr_rec_no} < 0;
    my $i = $self->{curr_rec_no};
    my $rec = $group->{data}[$i];
    return $rec;
}

=pod

=item C<validate_query>

 $bool = $form->validate_query($query[,$callback]);

Validate input fields submitted from a form previously
created by this class.
The structure of $query is explained
in C<prepare> except that multi-valued fields are not checked, which should never be used for insert/update groups anyway (notwithstanding
pseudo multi-valued fields packed with C<MULTI_INSERT_DELIMITER>, which WILL be split out and individually validated).

Numerous checks are done and there is magic to validate input that meets database constraints (if using a db on the backend)
so the operator can correct mistakes instead of just getting a meaningless db error code. For discreet value controls (SELECT box, etc)
this will also confirm submitted values fall withing the list (beware hackers).

For each field that fails, its VALID_ERROR attribute is set
to an appropriate error message/user hint.
Normally if an error occurs this form would be presented to the user again.
The HTML generated from C<prepare> uses the VALID_ERROR attribute
to set an HTML class name of VALID_ERROR for the field's heading
which is enclosed in a LABEL element so emphasis can be placed through style sheets.
Additionally, the error message is displayed inline with the heading
to give the user a hint of what went wrong.

$callback is optional and allows you to perform further validation checking; it is used as:

 ($success,$err_message) = &$callback($value,$field,$group,$form,$query);

Where $success indicates valid input, $err_message is set when the input is invalid
(its use is described above). $value is the value to be verified.
$field is the field sub-object,
$group is the data group sub-object structure.
$form is the form object and $query is a normalized version of the $query originally passed in.

See CGI::AutoForm::Session for an example implementation.

=cut

##at should the javascript be escaped too?

# this does not allow multiple record inserts per form group however for search field validation
# fields with multiple values can be assumed to come from a select list, radio or checkbox
# in which case all values are already validated :>
# include header content that will be included in {head_html} saying an error was encountered and to please correct
# only single valued query elements are allowed!
##at should also validate search forms a db error still might occur from badly formed SQL

# careful when custom defining your own fields that they don't match the name of a field in the database
# as they will be validated as if they were that field!! (see B<Form field names>)

sub validate_query
{
##at $query should be a refref (or ref for backwards compat) and should be assigned the new normalized query if the caller wants it!!
    my ($self,$inquery,$callback) = @_;
    my $query = $self->normalize_query($inquery);
    my $valid = 1;

    foreach my $group (@{$self->{group_list}})
    {
        my $usage = $group->{usage};
##at may still want to validate if a summary form (some values may have been mangled along the way)
        next if $usage eq $CGI::AutoForm::DISPLAY_ONLY_GROUP;
        foreach my $field (@{$group->{field_list}})
        {
            my $fename = "$group->{group_name}.$field->{FIELD_NAME}";
##at HASH and ARRAY should be consts assigned by ref({}) and ref([])
            
            if (($usage eq $CGI::AutoForm::INSERT_GROUP && $field->{INSERTABLE} ne 'Y') ||
                ($usage eq $CGI::AutoForm::EDIT_GROUP && $field->{UPDATABLE} ne 'Y') ||
                ($usage eq $CGI::AutoForm::SEARCH_GROUP && $field->{SEARCHABLE} ne 'Y'))
            {
                my $v = $query->{$fename};
                next if !length($v) || $usage eq $CGI::AutoForm::EDIT_GROUP;
                $valid = 0;
                delete($inquery->{$fename});
                warn("Value [$v] should be NULL for field [$fename]");
                next;
            }

            my $type = $self->control_type($field);
            if ($type eq 'RANGE' || $type eq 'DATERANGE' || $type eq 'DATETRANGE')
            {
                my $rs = $query->{"$fename._RS"};
                my $re = $query->{"$fename._RE"};
                if ((length($rs) || length($re)) && !(length($rs) && length($re)))
                {
                    $valid = 0;
                    $field->{VALID_ERROR} = "End range value required" if !length($re);
                    $field->{VALID_ERROR} = "Start range value required" if !length($rs);
                }
                else
                {
                    ($valid = $self->_validate($field,$rs,$valid,$callback,$group)) &&
                    ($valid = $self->_validate($field,$re,$valid,$callback,$group));
                }
            }
            elsif ($type eq 'MATCH TEXT' || $type eq 'COMMALIST')
            {
                next;
            }
            elsif ($type eq 'CHECKGROUP')
            {
                # In a CHECKGROUP values appear in a single string separated by the 
                # multi_insert_delimiter.  Split them out and validate individually.
                my $delimiter = $field->{MULTI_INSERT_DELIMITER} ?
                    $field->{MULTI_INSERT_DELIMITER} : 
                    $CGI::AutoForm::DEFAULT_MULTI_VALUE_DELIMITER; 

                my @values = split $delimiter, $query->{$fename};
        
                # Check for an empty required checkgroup.
                if ($field->{REQUIRED} eq 'Y' && scalar(@values) == 0)
                {               
                    $field->{VALID_ERROR} = 'At least one checkbox must be selected';
                    $valid = 0;
                }
                else 
                {
                    foreach my $v (@values)
                    {
                        $valid = $self->_validate($field,$v,$valid,$callback,$group,$query);
                        last unless $valid;
                    }
                }

            }
            else
            {
                $valid = $self->_validate($field,$query->{$fename},$valid,$callback,$group,$query);
            }
        }
    }
    $self->{valid_error}++ unless $valid;
    return $valid;
}

# will validate field length against $field->{INPUT_MAXLENGTH} and check if valid values for enumerated list fields ($field->{PICK_HASH}), etc...
sub _validate
{
    my ($self,$field,$val,$valid,$callback,$group,$query) = @_;
    # An empty hashref signals a CONFIRM field error where both fields don't match
    if (ref($val) eq 'HASH' && !%$val)
    {
        $valid = 0;
        $field->{VALID_ERROR} = "Input error";
##at use js to validate these are equal
        $val = '';
    }
    elsif ($field->{REQUIRED} eq 'Y' && !length($val))
    {
        $valid = 0;
        $field->{VALID_ERROR} = "Input required";
    }
    elsif (length($val) && !ref($val))
    {
        my $ct = '';
        eval{ $ct = $group->{table}->column_type($field->{FIELD_NAME}); };
        my $rv;
        if (($rv = ($field->{DATATYPE} ? _verify_datatype($val,$field->{DATATYPE},$field->{_imp_datetype}) : 1)) > 0 &&
            ( (ref($group->{table}) && length($ct)) ?
            ($rv = $group->{table}->verify_datatype($val,$field->{FIELD_NAME})) > 0 : 1))
        {
            if ($field->{INPUT_MAXLENGTH} && $field->{INPUT_MAXLENGTH} < length($val))
            {
                $valid = 0;
                $field->{VALID_ERROR} = "Field value too big.";
            }
            elsif (ref($field->{PICK_HASH}) && !exists($field->{PICK_HASH}{$val}))
            {
                $valid = 0;
                $field->{VALID_ERROR} = "Value submitted not in list of valid values.";
            }
            elsif (ref($callback) eq 'CODE')
            {
##at should verify that $success is even defined, if not there was an error in attempting to validate
                my ($success,$err_message) = &$callback($val,$field,$group,$self,$query);
                unless ($success)
                {
                    $valid = 0;
                    $field->{VALID_ERROR} = ($err_message ? $err_message : 'ERROR');
                }
            }
        }
        else
        {
            $valid = 0;
            if ($rv == 0)
            {
                $field->{VALID_ERROR} = "Numeric value required";
            }
            elsif ($rv == -1)
            {
                $field->{VALID_ERROR} = "Integer value required, no decimals";
            }
            elsif ($rv == -2)
            {
                $field->{VALID_ERROR} = "Negative value not allowed";
            }
            elsif ($rv == -3)
            {
                $field->{VALID_ERROR} = "Unrecognized date format";
            }
            else
            {
                $field->{VALID_ERROR} = "Datatype error";
            }
        }
    }
    return $valid;
}

sub _verify_datatype
{
    my ($val,$type,$imp) = @_;
    my $datetype = $imp || $type;
    if ($type eq 'NUMBER')
    {
        return DBIx::IO::GenLib::isreal($val);
    }
    elsif ($type =~ /INT/)
    {
        return -1 unless DBIx::IO::GenLib::isint($val);
        if ($type =~ /UNSIGNED/)
        {
            return -2 unless $val > 0;
        }
    }
    elsif (($datetype eq 'DATETIME' || $datetype eq 'DATE') && $val !~ /^\d{2,14}$/)
    {
        return -3;
    }
    return 1;
}

# Return YYYYMMDDHH24MISS format only (pad with zeros as necessary) unless date can't
# be parsed, in which case, $val is passed back untouched
# if month or day or year are == 0 then return undef

##at document that it can accept alternate date forms (YYYYMMDDHH24MISS or D?D-MON-YYYY H?H24:MI:SS)
sub _parse_datetime
{
    my ($val) = @_;
    my $norm_date;
    if ($val =~ /^(\d\d\d\d)(\d\d)(\d\d)(?:(\d\d)(\d\d)(\d\d)?)?$/)
    {
        $norm_date = _norm_date($1,$2,$3,$4,$5,$6,'DATETIME');
    }
##at should affirm the correct days in the month also, leap years, etc.
    elsif ($val =~ /^(\d{1,2})\W([A-Za-z]{3})\W(\d{4})(?:\s+(\d{1,2})\W(\d\d)(?:\W(\d\d))?)?$/)
    {
        my $m = uc($2);
        my $i = '00';
        foreach my $mon (@months)
        {
            last if $m eq uc(substr($mon,0,3));
            $i++;
        }
        $norm_date = _norm_date($3,$i,$1,$4,$5,$6,'DATETIME');
    }
    else
    {
        $norm_date = $val;
    }
    return $norm_date;
}

# if month and day are false then date is null
sub _norm_date
{
    my ($y,$m,$d,$h,$mi,$s,$datetype) = @_;
    $datetype ||= 'DATETIME';
    if ($y == 0 || $m == 0 || $d == 0)
    {
        return undef;
    }
    $m = "0$m" if (length($m) == 1);
    $d = "0$d" if (length($d) == 1);
    $h = "0$h" if (length($h) == 1);
    $mi = "0$mi" if (length($mi) == 1);
    $s = "0$s" if (length($s) == 1);
    unless (length($h))
    {
        $h = '00';
        $mi = '00';
    }
    length($s) || ($s = '00');
    return "$y$m$d$h$mi$s" if $datetype eq 'DATETIME';
##at should warn if the time element was > 0 that it will be truncated
    return "$y$m$d" if $datetype eq 'DATE';
}

=pod

=item C<format_query>

 $formatted_query = $form->format_query($query);

Class or object method. Normalize and structure input fields
submitted by a form created by this class.
The structure of $query is explained in C<prepare>.

Convenience method that executes C<normalize_query> and then C<structure_query>
on $query (see those methods for details).

=cut
sub format_query
{
    my ($caller,$query) = @_;
    return $caller->structure_query($caller->normalize_query($query));
}

sub clean_val
{
    my ($caller,$val) = @_;
    $val =~ s/^\s+//;
    $val =~ s/\s+$//;
    $val =~ s/\000//g;
    $val = $caller->unescape($val);
    return $val;
}


# only dates in TEXT and date group form fields will be validated
# dates will ALWAYS be normalized with a time element (this is fine for both DATE and DATETIME types in mysql)

=pod

=item C<normalize_query>

 $norm_query = $form->normalize_query($query);

Class or object method (must use as object method for a non-default multi-value delimiter).

All date fields will be normalized in the YYYYMMDDHH24MISS format (in Oracle-speak) for
consumption by DBIx::IO::Table and friends (see also DBIx::IO::GenLib).
CONFIRM fields are de-duped and checked for equality. If unequal,
the value will be given as an empty hashref.
All field names are converted to UPPER CASE.
Removes leading and trailing whitespace, remove all NULL chars and removes elements
that have an empty or undefined value.

Whereas C<format_query> will execute this method AND C<structure_query>, sometimes just this call
is useful to manipulate a query in its normalized form before passing to C<prepare>, which won't accept
a structured query.

See C<prepare> for the structure of $query.

=cut
sub normalize_query
{
    my ($caller,$query) = @_;
    my $new_query = {};
    my ($key,$val);
    my %confirm_proc;
    while (($key,$val) = each(%$query))
    {
        if (ref($val) eq 'ARRAY')
        {
            my @newv;
            foreach my $v (@$val)
            {
                $v = $caller->clean_val($v);
                next unless length($v);
                push(@newv,$v);
            }
            next unless @newv;
            $val = (@newv > 1 ? \@newv : $newv[0]);
        }
        else
        {
            $val = $caller->clean_val($val);
            next unless length($val);
        }
        $key = $caller->unescape($key);
        $key = uc($key);
        my ($key_pre,$key_pre2,$gname,$fname);
        if (($key_pre,$key_pre2,$gname,$fname) = $key =~ /((?:__SDAT\.)?(?:SC\.)?((.*?)\.(.*?))(?:\..*?)?)\._(?:QUANT|UNIT|MONTH|YEAR|DAY|MIN|HOUR)$/)
        {
            next if $new_query->{$key_pre};

            my $quant = $query->{"$key_pre._QUANT"};
            my $unit = $query->{"$key_pre._UNIT"};

            my $dtype = ref($caller) && ref($caller->field_hash()) ? $caller->field_hash()->{$fname}{_imp_datetype} : undef();

            my $start_key = $key_pre;
            my $end_key = $key_pre;
            $end_key =~ s/_RS$/_RE/;

            # _QUANT/_UNIT fields take precedence
            if (length($quant) || length($unit))
            {
                ($new_query->{$start_key} = $new_query->{$end_key} = {},next) unless length($quant) && length($unit) && DBIx::IO::GenLib::isint($quant);

                my $factor;

                if ($unit eq 'HRS')
                {
                    $factor = 3600;
                }
                elsif ($unit eq 'DAYS')
                {
                    $factor = 3600 * 24;
                }
                elsif ($unit eq 'MINS')
                {
                    $factor = 60;
                }
                elsif ($unit eq 'MONTHS')
                {
                    # Estimate
                    $factor = 3600 * 24 * 30;
                }
                elsif ($unit eq 'YEARS')
                {
                    # Estimate
                    $factor = int(3600 * 24 * 365.25);
                }
                else
                {
                    $new_query->{$start_key} = $new_query->{$end_key} = {}; # Empty hash reference signals an error to validate_query()
                    next;
                }

                my $enow = time;
                my $then = $enow - $factor * $quant;

                my @t = localtime($then);
                $new_query->{$start_key} = _norm_date($t[5]+1900,$t[4]+1,@t[3,2,1,0],$dtype);

                @t = localtime($enow);
                $new_query->{$end_key} = _norm_date($t[5]+1900,$t[4]+1,@t[3,2,1,0],$dtype);

                next;
            }

            $val = _norm_date(@{$query}{
                "$key_pre._YEAR",
                "$key_pre._MONTH",
                "$key_pre._DAY",
                "$key_pre._HOUR",
                "$key_pre._MIN",
                },
                '00',
                $dtype
            );
            $val = {} unless length($val);
        }
        elsif (($key_pre) = $key =~ /(.*)\._CONFIRM[12]$/)
        {
            next if $confirm_proc{$key_pre};
            $val =
                ($query->{"$key_pre._CONFIRM1"} eq $query->{"$key_pre._CONFIRM2"} ?
                $query->{"$key_pre._CONFIRM1"} :
                {}); # Empty hash reference signals an error to validate_query()
            $confirm_proc{$key_pre}++;
        }
        else
        {
            $key_pre = $key;
        }
        if ($key =~ /(.*)\._DT$/)
        {
            $val = _parse_datetime($val) unless ($val =~ /^\d{14}$/);
            $key_pre = $1;
        }
        # Checkgroup
        # This re match needs to return $1=GROUP.FIELD, $2=GROUP, $3=FIELD 
        elsif ($key =~ /((.*)\.(.*))\._CG$/) 
        {       

            # It is possible that we have been called as a class
            # method, ie $form->normalize_query.  If so, we will
            # not be able to access the multi-value delimiter defined
            # in the form object, so we will use a default.
            my $delimiter = $CGI::AutoForm::DEFAULT_MULTI_VALUE_DELIMITER;

            if (ref($caller))
            {
                # Need to get the multi-value delimiter. Use the field
                # name from the re match to access the field_hash;
                my $field_name = $3;

                my $field_attrs = $caller->field_hash()->{$field_name};

                # If the hash value is not set, use the default.
                $delimiter = $field_attrs->{MULTI_INSERT_DELIMITER} if $field_attrs->{MULTI_INSERT_DELIMITER};
            }

            # If $val is an array ref then concat all elements
            # together into a single string, joining with the
            # multi-value separator.  Otherwise just use $val as is.
            $key_pre = $1;
            $val = join($delimiter, @$val) if ref($val) eq 'ARRAY';

        }               
        $new_query->{$key_pre} = $val;
    }
    return $new_query;
}

=pod

=item C<structure_query>

 $struct_query = CGI::AutoForm->structure_query($query);

Class or object method.

The returned $struct_query will be structured like C<$struct_query-E<gt>{group_name}{FIELD_NAME}>
from properly named form fields (see B<Form field names>).
This structure
can facilitate record extraction for each group in the form, e.g. $formatted_query->{group_name}
will give a record available for direct insert using DBIx::IO::Table.

See C<prepare> for the structure of $query.

=cut
sub structure_query
{
    my ($caller,$query) = @_;
    my ($key,$val);
    my $struct_query = {};
    while (($key,$val) = each(%$query))
    {
        my $expr = '$struct_query->';
        foreach my $word (split(/\W+/,$key))
        {
            $expr .= "{$word}";
        }
        #$expr .= " = " . (defined($val) ? "'$val'" : 'undef()');
        $expr .= " = " . '$val';
        eval($expr);
        die($@) if $@; # runtime error so OK to die
    }
    return $struct_query;
}

##at special column names, eg. _MONTH should be lower case by convention to distinguish from 'real' column names

=pod

=item C<clone>

 $form_copy = $form->clone();

Perform a deep copy of $form.
HTML attributes generated from C<prepare> will not
be copied.

Useful for caching form objects in environments like mod_perl, see CGI::AutoForm::Session
for an example.

Return the new object.

=cut
sub clone
{
    my $self = shift;
    my $clone = $self->new(@_);
    foreach my $key (keys(%$self))
    {
        next if ref($self->{$key});
        $clone->{$key} = $self->{$key};
    }
    $clone->{group_hash} = {};
    $clone->{group_list} = [];
    $clone->{hidden} = {};
    foreach my $group (@{$self->{group_list}})
    {
        my $clone_group = {};
        foreach my $key (keys(%$group))
        {
            next if ref($group->{$key});
            $clone_group->{$key} = $group->{$key};
        }
        $clone_group->{field_hash} = {};
        $clone_group->{field_list} = [];
        $clone_group->{data} = [];
        $clone_group->{export_rec} = [];
        foreach my $field (@{$group->{field_list}})
        {
            my $clone_field = {};
            foreach my $key (keys(%$field))
            {
                $clone_field->{$key} = $field->{$key};
            }
            push(@{$clone_group->{field_list}},$clone_field);
            $clone_group->{field_hash}{$clone_field->{FIELD_NAME}} = $clone_field;
        }
        push(@{$clone->{group_list}},$clone_group);
        $clone->{group_hash}{$clone_group->{group_name}} = $clone_group;
    }
    return $clone;
}

##at group_names can NOT have a /\W/ in them (should check and return an appropriate error code)

=pod

=item C<extract_query_group>

 $form_fields = CGI::AutoForm->extract_query_group($query,$group_name);

Object or class method.

Return a hashref of form field 'E<lt>group_nameE<gt>.E<lt>field_nameE<gt>' => value pairs from a data group named $group_name.
Must use properly named form fields (see B<Form field names>).

See C<prepare> for the structure of $query.

=cut
sub extract_query_group
{
    my ($self,$q,$name) = @_;
    my ($field,$val);
    my %nq;
    $name = quotemeta($name);
    while (($field,$val) = each(%$q))
    {
        $nq{$field} = $val if $field =~ /\b$name\./;
    }
    return \%nq;
}

=pod

=item C<extract_cut_query_group>

 $form_fields = CGI::AutoForm->extract_cut_query_group($query,$group_name);

Object or class method.

Return a hashref of form field E<lt>field_nameE<gt> => value pairs from a data group named $group_name.
Similar to C<extract_query_group> except the keys of the hashref don't have the E<lt>group_nameE<gt> component.
Must use properly named form fields (see B<Form field names>).

See C<prepare> for the structure of $query.

=cut
sub extract_cut_query_group
{
    my ($self,$q,$name) = @_;
    my ($field,$val);
    my %nq;
    $name = quotemeta($name);
    while (($field,$val) = each(%$q))
    {
        $nq{$1} = $val if $field =~ /\b$name\.(.*)/;
    }
    return \%nq;
}

=pod

=item C<escape>

 $form_fields = CGI::AutoForm->escape($query,$group_name);

Object or class method (use the object method invocation with the C<dontescape> attribute).

Utility method to transform text into an HTML compatible format by escaping (encoding) certain characters with HTML entities.
Ignored if $form->{dontescape} is TRUE.

=cut
sub escape
{
    my ($self,$toencode,$newlinestoo) = @_;
    return undef unless defined($toencode);
    return $toencode if ref($self) && $self->{'dontescape'};
    $toencode =~ s{&}{&amp;}gso;
    $toencode =~ s{<}{&lt;}gso;
    $toencode =~ s{>}{&gt;}gso;
    $toencode =~ s{"}{&quot;}gso;

    # bug in some browsers
    $toencode =~ s{'}{&#39;}gso;
    $toencode =~ s{\x8b}{&#139;}gso;
    $toencode =~ s{\x9b}{&#155;}gso;
    if (defined $newlinestoo && $newlinestoo) {
         $toencode =~ s{\012}{&#10;}gso;
         $toencode =~ s{\015}{&#13;}gso;
    }
    return $toencode;
}

=pod

=item C<unescape>

 $form_fields = CGI::AutoForm->unescape($query,$group_name);

Object or class method (use the object method invocation with the C<dontunescape> attribute).

Utility method to reverse the transformation of C<escape>.
Ignored if $form->{dontunescape} is TRUE.

=cut
sub unescape
{
    my ($self,$string) = @_;
    return undef unless defined($string);
    return $string if ref($self) && $self->{dontunescape};

    my $latin = 1;#defined $self->{'.charset'} ? $self->{'.charset'} =~ /^(ISO-8859-1|WINDOWS-1252)$/i : 1;
    # thanks to Randal Schwartz for the correct solution to this one
    $string=~ s[&(.*?);]{
        local $_ = $1;
        /^amp$/i        ? "&" :
        /^quot$/i       ? '"' :
        /^gt$/i         ? ">" :
        /^lt$/i         ? "<" :
        /^#(\d+)$/ && $latin         ? chr($1) :
        /^#x([0-9a-f]+)$/i && $latin ? chr(hex($1)) :
        $_
        }gex;
    return $string;
}

=pod

=back

=cut


1;

__END__

=head1 BUGS

This file is way too long - it should be divided into smaller classes each with limited scope (e.g. create a CGI::AutoForm::Group class).

No quoting of object (table) names is done within SQL (L<DBIx::IO>) so object names containing reserved words or otherwise need quoting (e.g. `mysql_reserved_word` or "oracle_reserved_word") in your respective RDBMS will be problematic.

=head1 SEE ALSO

L<CGI::AutoForm::Session>, L<DBIx::IO>, L<DBIx::IO::Table>, L<DBIx::IO::Search>, L<DBIx::IO::Mask>, Cruddy! L<http://www.thesmbexchange.com/cruddy/index.html>

=head1 AUTHOR

Reed Sandberg, E<lt>reed_sandberg Ӓ yahooE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2000-2008 Reed Sandberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

