#!/bin/false
# PODNAME: BZ::Client::Bug
# ABSTRACT: Client side representation of a bug in Bugzilla

use strict;
use warnings 'all';

package BZ::Client::Bug;
$BZ::Client::Bug::VERSION = '4.4002';

use parent qw( BZ::Client::API );

# See https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Bug.html
# These are in order as per the above

## functions

sub fields {
    my($class, $client, $params) = @_;
    return $class->_returns_array($client, 'Bug.fields', $params, 'fields');
}

sub legal_values {
    my($class, $client, $field) = @_;
    my $params = { 'field' => $field };
    return $class->_returns_array($client, 'Bug.legal_values', $params, 'values');
}

sub get {
    my($class, $client, $params) = @_;
    unless (ref $params) {
        $params = [ $params ]
    }
    if (ref $params eq 'ARRAY') {
        $params = { ids => $params }
    }
    elsif (ref $params eq 'HASH') {
        $params->{'permissive'} = BZ::Client::XMLRPC::boolean::TRUE()
            if $params->{'permissive'};
    }
    my $bugs = $class->_returns_array($client, 'Bug.get', $params, 'bugs');
    my @result;
    for my $bug (@$bugs) {
        push(@result, $class->new(%$bug));
    }
    $client->log('debug', $class . '::get: Got ' . scalar(@result));
    return wantarray ? @result : \@result
}

sub history {
    my($class, $client, $params) = @_;
    return $class->_returns_array($client, 'Bug.history', $params, 'bugs');
}

sub possible_duplicates {
    my($class, $client, $params) = @_;
    my $bugs = $class->_returns_array($client, 'Bug.possible_duplicates', $params, 'bugs');
    my @result;
    for my $bug (@$bugs) {
        push(@result, $class->new(%$bug));
    }
    $client->log('debug', $class . '::possible_duplicates: Got ' . scalar(@result));
    return wantarray ? @result : \@result
}

sub search {
    my($class, $client, $params) = @_;
    my $bugs = $class->_returns_array($client, 'Bug.search', $params, 'bugs');
    my @result;
    for my $bug (@$bugs) {
        push(@result, $class->new(%$bug));
    }
    $client->log('debug', $class . '::search: Found ' . join(',',@result));
    return wantarray ? @result : \@result
}

sub create {
    my($class, $client, $params) = @_;
    return $class->_create($client, 'Bug.create', $params);
}

sub update {
    my($class, $client, $params) = @_;
    return $class->_returns_array($client, 'Bug.update', $params, 'bugs');

}

sub update_see_also {
    my($class, $client, $params) = @_;
    $client->log('debug', $class . '::update_see_also: Updating See-Also');
    my $result = $class->api_call($client, 'Bug.update_see_also', $params);
    my $changes = $result->{'changes'};
    if (!$changes || 'HASH' ne ref($changes)) {
        $class->error($client, 'Invalid reply by server, expected hash of changed bug details.');
    }
    $client->log('debug', $class . '::update_see_also: Updated stuff');
    return wantarray ? %$changes : $changes
}

sub update_tags {
    my($class, $client, $params) = @_;
    $client->log('debug', $class . '::update_tags: Updating Tags');
    my $result = $class->api_call($client, 'Bug.update_tags', $params);
    my $changes = $result->{'changes'};
    if (!$changes || 'HASH' ne ref($changes)) {
        $class->error($client, 'Invalid reply by server, expected hash of changed bug details.');
    }
    $client->log('debug', $class . '::update_tags: Updated stuff');
    return wantarray ? %$changes : $changes
}

## methods

sub id {
    my $self = shift;
    if (@_) {
        $self->{'id'} = shift;
    }
    else {
        return $self->{'id'}
    }
}

sub alias {
    my $self = shift;
    if (@_) {
        my $alias = shift;
        if (ref $alias eq 'ARRAY' && @$a) {
            $self->{'alias'} = $alias->[0];
        }
        if (not ref $alias) {
            $self->{'alias'} = $alias;
        }
        # silently ignore anything else
    }
    else {

        return '' unless defined $self->{'alias'};

        # long form so its clear what is going on.
        if (ref $self->{'alias'}) {
            if (ref $self->{'alias'} eq 'ARRAY'
                and @{$self->{'alias'}}) {
                return $self->{'alias'}->[0];
            }
            return ''
        }

        # fall back
        return $self->{'alias'}
    }
}

sub assigned_to {
    my $self = shift;
    if (@_) {
        $self->{'assigned_to'} = shift;
    }
    else {
        return $self->{'assigned_to'}
    }
}

sub component {
    my $self = shift;
    if (@_) {
        $self->{'component'} = shift;
    } e
    lse {
        return $self->{'component'}
    }
}

sub creation_time {
    my $self = shift;
    if (@_) {
        $self->{'creation_time'} = shift;
    }
    else {
        return $self->{'creation_time'}
    }
}

sub dupe_of {
    my $self = shift;
    if (@_) {
        $self->{'dupe_of'} = shift;
    }
    else {
        return $self->{'dupe_of'}
    }
}

sub internals {
    my $self = shift;
    if (@_) {
        $self->{'internals'} = shift;
    }
    else {
        return $self->{'internals'}
    }
}

sub is_open {
    my $self = shift;
    if (@_) {
        $self->{'is_open'} = shift;
    }
    else {
        return $self->{'is_open'}
    }
}

sub last_change_time {
    my $self = shift;
    if (@_) {
        $self->{'last_change_time'} = shift;
    }
    else {
        return $self->{'last_change_time'}
    }
}

sub priority {
    my $self = shift;
    if (@_) {
        $self->{'priority'} = shift;
    }
    else {
        return $self->{'priority'}
    }
}

sub product {
    my $self = shift;
    if (@_) {
        $self->{'product'} = shift;
    }
    else {
        return $self->{'product'}
    }
}

sub resolution {
    my $self = shift;
    if (@_) {
        $self->{'resolution'} = shift;
    }
    else {
        return $self->{'resolution'}
    }
}

sub severity {
    my $self = shift;
    if (@_) {
        $self->{'severity'} = shift;
    }
    else {
        return $self->{'severity'}
    }
}

sub status {
    my $self = shift;
    if (@_) {
        $self->{'status'} = shift;
    }
    else {
        return $self->{'status'}
    }
}

sub summary {
    my $self = shift;
    if (@_) {
        $self->{'summary'} = shift;
    }
    else {
        return $self->{'summary'}
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BZ::Client::Bug - Client side representation of a bug in Bugzilla

=head1 VERSION

version 4.4002

=head1 SYNOPSIS

This class provides methods for accessing and managing bugs in Bugzilla.

  my $client = BZ::Client->new( url      => $url,
                                user     => $user,
                                password => $password );

  my $bugs = BZ::Client::Bug->get( $client, \%params );

=head1 COMMON PARAMETERS

Many Bugzilla Webservice methods take similar arguments. Instead of re-writing the documentation for each method, we document the parameters here, once, and then refer back to this documentation from the individual methods where these parameters are used.

=head2 Limiting What Fields Are Returned

Many methods return an array of structs with various fields in the structs.
(For example, L</get> in L<BZ::Client::Bug> returns a list of bugs that have fields like
L</id>, L</summary>, L</creation_time>, etc.)

These parameters allow you to limit what fields are present in the structs, to possibly improve performance or save some bandwidth.

Fields follow:

=head3 include_fields

I<include_fields> (array) - An array of strings, representing the (case-sensitive) names of fields in the return value. Only the fields specified in this hash will be returned, the rest will not be included.

If you specify an empty array, then this function will return empty hashes.

Invalid field names are ignored.

Example:

 BZ::Client::Bug->get( $client,
    { ids => [1], include_fields => ['id', 'name'] })

would return something like:

 [{ id => 1, name => 'user@domain.com' }]

=head3 exclude_fields

I<exclude_fields> (array) - An array of strings, representing the (case-sensitive) names of fields in the return value. The fields specified will not be included in the returned hashes.

If you specify all the fields, then this function will return empty hashes.

Some RPC calls support specifying sub fields. If an RPC call states that it support sub field restrictions, you can restrict what information is returned within the first field. For example, if you call Product.get with an include_fields of components.name, then only the component name would be returned (and nothing else). You can include the main field, and exclude a sub field.

Invalid field names are ignored.

Specifying fields here overrides L</include_fields>, so if you specify a field in both, it will be excluded, not included.

Example:

 BZ::Client::Bug->get( $client,
    { ids => [1], exclude_fields => ['name'] })

would return something like:

 [{ id => 1, real_name => 'John Smith' }]

=head3 shortcuts

There are several shortcut identifiers to ask for only certain groups of fields to be returned or excluded.

=over 4

=item _all

All possible fields are returned if C<_all> is specified in L</include_fields>.

=item _default

These fields are returned if L</include_fields> is empty or C<_default> is specified. All fields described in the documentation are returned by default unless specified otherwise.

=item _extra

These fields are not returned by default and need to be manually specified in L</include_fields> either by field name, or using C<_extra>.

=item _custom

Only custom fields are returned if C<_custom> is specified in L</include_fields>. This is normally specific to bug objects and not relevant for other returned objects.

=back

Example:

 BZ::Client::Bug->get( $client,
    { ids => [1], include_fields => ['_all'] })

=head1 EXCEPTION HANDLING

See L<BZ::Client::Exception>

=head1 UTILITY FUNCTIONS

This section lists the utility functions provided by this module.

These deal with bug-related information, but not bugs directly.

=head2 fields

 $fields = BZ::Client::Bug->fields( $client, $params )
 @fields = BZ::Client::Bug->fields( $client, $params )

Get information about valid bug fields, including the lists of legal values for each field.

=head3 History

Added in Bugzilla 3.6

=head3 Parameters

You can pass either field ids or field names.

Note: If neither ids nor names is specified, then all non-obsolete fields will be returned.

=over 4

=item ids

I<ids> (array) - An array of integer field ids

=item names

I<names> (array) - An array of strings representing field names.

=back

In addition to the parameters above, this method also accepts the standard L</include_fields> and L</exclude_fields> arguments.

=head3 Returns

Returns an array or an arrayref of hashes, containing the following keys:

=over 4

=item id

I<id> (int) - An integer id uniquely identifying this field in this installation only.

=item type

I<type> (int) The number of the fieldtype. The following values are defined:

=over 4

=item 0 Unknown

=item 1 Free Text

=item 2 Drop Down

=item 3 Multiple-Selection Box

=item 4 Large Text Box

=item 5 Date/Time

=item 6 Bug ID

=item 7 Bug URLs ("See Also")

=back

=item is_custom

I<is_custom> (boolean) True when this is a custom field, false otherwise.

=item name

I<name> (string) The internal name of this field. This is a unique identifier for this field. If this is not a custom field, then this name will be the same across all Bugzilla installations.

=item display_name

I<display_name>  (string) The name of the field, as it is shown in the user interface.

=item is_mandatory

I<is_mandatory> (boolean) True if the field must have a value when filing new bugs. Also, mandatory fields cannot have their value cleared when updating bugs.

This return value was added in Bugzilla 4.0.

=item is_on_bug_entry

I<is_on_bug_entry> (boolean) For custom fields, this is true if the field is shown when you enter a new bug. For standard fields, this is currently always false, even if the field shows up when entering a bug. (To know whether or not a standard field is valid on bug entry, see L</create>.)

=item visibility_field

I<visibility_field> (string) The name of a field that controls the visibility of this field in the user interface. This field only appears in the user interface when the named field is equal to one of the values in L</visibility_values>. Can be null.

=item visibility_values

I<visibility_values> (array) of strings This field is only shown when visibility_field matches one of these values. When visibility_field is null, then this is an empty array.

=item value_field

I<value_field> (string) The name of the field that controls whether or not particular values of the field are shown in the user interface. Can be null.

=item values

This is an array of hashes, representing the legal values for select-type (drop-down and multiple-selection) fields. This is also populated for the L</component>, L</version>, L</target_milestone>, and L</keywords> fields, but not for the C<product> field (you must use L<BZ::Client::Product/get_accessible_products> for that).

For fields that aren't select-type fields, this will simply be an empty array.

Each hash has the following keys:

=over 4

=item name

I<name> (string) The actual value--this is what you would specify for this field in L</create>, etc.

=item sort_key

I<sort_key> (int) Values, when displayed in a list, are sorted first by this integer and then secondly by their name.

=item sortkey

B<DEPRECATED> - Use L</sort_key> instead.

Renamed to C<sort_key> in Bugzilla 4.2.

=item visibility_values

If L</value_field> is defined for this field, then this value is only shown if the L</value_field> is set to one of the values listed in this array.

Note that for per-product fields, L</value_field> is set to C<product> and L</visibility_values> will reflect which product(s) this value appears in.

=item is_active

I<is_active> (boolean) This value is defined only for certain product specific fields such as L</version>, L</target_milestone> or L</component>.

When true, the value is active, otherwise the value is not active.

Added in Bugzilla 4.4.

=item description

I<description> (string) The description of the value. This item is only included for the L</keywords> field.

=item is_open

I<is_open> (boolean) For L</bug_status> values, determines whether this status specifies that the bug is "open" (true) or "closed" (false). This item is only included for the L</bug_status> field.

=item can_change_to

For L</bug_status> values, this is an array of hashes that determines which statuses you can transition to from this status. (This item is only included for the L</bug_status> field.)

Each hash contains the following items:

=over 4

=item name

The name of the new status

=item comment_required

I<comment_required> (boolean) True if a comment is required when you change a bug into this status using this transition.

=back

=back

=back

Errors:

=over 4

=item 51 - Invalid Field Name or ID

You specified an invalid field name or id.

=back

=head2 legal_values

 $values = BZ::Client::Bug->legal_values( $client, $field )
 @values = BZ::Client::Bug->legal_values( $client, $field )

Tells you what values are allowed for a particular field.

Note: This is deprecated in Bugzilla, use L</fields> instead.

=head3 Parameters

=over 4

=item field

The name of the field you want information about. This should be the same as the name you would use in L</create>, below.

=item product_id

If you're picking a product-specific field, you have to specify the id of the product you want the values for.

=back

=head3 Returns

=over 4

=item values

An array or arrayref of strings: the legal values for this field. The values will be sorted as they normally would be in Bugzilla.

=back

=head3 Errors

=over 4

=item 106 - Invalid Product

You were required to specify a product, and either you didn't, or you specified an invalid product (or a product that you can't access).

=item 108 - Invalid Field Name

You specified a field that doesn't exist or isn't a drop-down field.

=back

=head1 FUNCTIONS FOR FINDING AND RETRIEVING BUGS

This section lists the class methods pertaining to finding and retrieving bugs from your server.

Listed here in order of what you most likely want to do... maybe?

=head2 get

 @bugs = BZ::Client::Bug->get( $client, $id );
 $bugs = BZ::Client::Bug->get( $client, $id );
 @bugs = BZ::Client::Bug->get( $client, \@ids );
 $bugs = BZ::Client::Bug->get( $client, \@ids );
 @bugs = BZ::Client::Bug->get( $client, \%params );
 $bugs = BZ::Client::Bug->get( $client, \%params );

Gets information about particular bugs in the database.

=head3 Parameters

A single I<$id> or array ref of I<@ids> may be provided, otherwise a hash ref with the following:

=over 4

=item ids

An array of numbers and strings.

If an element in the array is entirely numeric, it represents a C<bug_id> from the Bugzilla database to fetch. If it contains any non-numeric characters, it is considered to be a bug alias instead, and the bug with that alias will be loaded.

=item permissive

I<permissive> (boolean) Normally, if you request any inaccessible or invalid bug ids, will throw an error.

If this parameter is True, instead of throwing an error we return an array of hashes with a C<id>, C<faultString> and C<faultCode> for each bug that fails, and return normal information for the other bugs that were accessible.

Note: marked as B<EXPERIMENTAL> in Bugzilla 4.4

Added in Bugzilla 3.4.

=back

=head3 Returns

An array or arrayref of bug instance objects with the given ID's.

See L</INSTANCE METHODS> for how to use them.

FIXME missing the I<faults> return values (added in 3.4)

=head3 Errors

=over 4

=item 100 - Invalid Bug Alias

If you specified an alias and there is no bug with that alias.

=item 101 - Invalid Bug ID

The bug_id you specified doesn't exist in the database.

=item 102 - Access Denied

You do not have access to the bug_id you specified.

=back

=head2 search

FIXME Documentation not fully fleshed out

 @bugs = BZ::Client::Bug->search( $client, \%params );
 $bugs = BZ::Client::Bug->search( $client, \%params );

Searches for bugs matching the given parameters.

=head3 Parameters

This is just a quick example, there are lot's of fields

 %params = (

   'alias' => 'ACONVENIENTALIAS',

   'assigned_to' => 'hopefullynotme@domain.local',

   'creator' => 'littlejohnnytables@school.local',

   'severity' => 'major',

   'status' => 'OPEN',

 );

Criteria are joined in a logical AND. That is, you will be returned bugs that match all of the criteria, not bugs that match any of the criteria.

See also L<https://bugzilla.readthedocs.io/en/5.0/api/core/v1/bug.html#search-bugs>

=head3 Returns

Returns an array or arrayref of bug instance objects with the given ID's.

See L<INSTANCE METHODS> for how to use them.

=head2 history

 @history = BZ::Client::Bug->history( $client, \%params );
 $history = BZ::Client::Bug->history( $client, \%params );

Gets the history of changes for particular bugs in the database.

Added in Bugzilla 3.4.

=head3 Parameters

=over 4

=item ids

An array of numbers and strings.

If an element in the array is entirely numeric, it represents a C<bug_id> from the Bugzilla database to fetch. If it contains any non-numeric characters, it is considered to be a bug alias instead, and the data bug with that alias will be loaded.

=back

=head3 Returns

An array or arrayref of hashes, containing the following keys:

=over 4

=item id

I<id> (int) The numeric id of the bug

=item alias

I<alias> (array) The alias of this bug. If there is no alias, this will be undef.

=item history

I<history> (An array of hashes) - Each hash having the following keys:

=over 4

=item when

I<when> (L<DateTime>) The date the bug activity/change happened.

=item who

I<who> (string) The login name of the user who performed the bug change.

=item changes

An array of hashes which contain all the changes that happened to the bug at this time (as specified by when). Each hash contains the following items:

=over 4

=item field_name

I<field_name> (string) The name of the bug field that has changed.

=item removed

I<removed> (string) The previous value of the bug field which has been deleted by the change.

=item added

I<added> (string) The new value of the bug field which has been added by the change.

=item attachment_id

I<attachment_id> (int) The id of the attachment that was changed. This only appears if the change was to an attachment, otherwise L</attachment_id> will not be present in this hash.

=back

=back

=back

=head3 Errors

=over 4

=item 100 - Invalid Bug Alias

If you specified an alias and there is no bug with that alias.

=item 101 - Invalid Bug ID

The bug_id you specified doesn't exist in the database.

=item 102 - Access Denied

You do not have access to the bug_id you specified.

=back

=head2 possible_duplicates

 @bugs = BZ::Client::Bug->possible_duplicates( $client, \%params );
 $bugs = BZ::Client::Bug->possible_duplicates( $client, \%params );

Allows a user to find possible duplicate bugs based on a set of keywords such as a user may use as a bug summary. Optionally the search can be narrowed down to specific products.

=head3 History

Added in Bugzilla 4.0.

=head3 Parameters

=over 4

=item summary

I<summary> (string) A string of keywords defining the type of bug you are trying to report. B<Required>.

=item product

I<product> (array) One or more product names to narrow the duplicate search to. If omitted, all bugs are searched.

=back

=head3 Returns

The same as L</get>.

Note that you will only be returned information about bugs that you can see. Bugs that you can't see will be entirely excluded from the results. So, if you want to see private bugs, you will have to first log in and then call this method.

=head3 Errors

=over 4

=item 50 - Param Required

You must specify a value for L</summary> containing a string of keywords to search for duplicates.

=back

=head1 FUNCTIONS FOR CREATING AND MODIFYING BUGS

This section lists the class methods pertaining to the creation and modification of bugs.

Listed here in order of what you most likely want to do... maybe?

=head2 create

  my $id = BZ::Client::Bug->create( $client, \%params );

This allows you to create a new bug in Bugzilla. If you specify any invalid fields, an error will be thrown stating which field is invalid. If you specify any fields you are not allowed to set, they will just be set to their defaults or ignored.

You cannot currently set all the items here that you can set on enter_bug.cgi (i.e. the web page to enter bugs).

The Bugzilla WebService API itself may allow you to set things other than those listed here, but realize that anything undocumented is B<UNSTABLE> and will very likely change in the future.

=head3 History

Before Bugzilla 3.0.4, parameters marked as B<Defaulted> were actually B<Required>, due to a bug in Bugzilla itself.

The groups argument was added in Bugzilla B<4.0>. Before Bugzilla 4.0, bugs were only added into Mandatory groups by this method. Since Bugzilla B<4.0.2>, passing an illegal group name will throw an error. In Bugzilla 4.0 and 4.0.1, illegal group names were silently ignored.

The C<comment_is_private> argument was added in Bugzilla B<4.0>. Before Bugzilla 4.0, you had to use the undocumented C<commentprivacy> argument.

Error C<116> was added in Bugzilla B<4.0>. Before that, dependency loop errors had a generic code of C<32000>.

The ability to file new bugs with a C<resolution> was added in Bugzilla B<4.4>.

=head3 Parameters

Some params must be set, or an error will be thrown. These params are marked B<Required>.

Some parameters can have defaults set in Bugzilla, by the administrator. If these parameters have defaults set, you can omit them. These parameters are marked B<Defaulted>.

Clients that want to be able to interact uniformly with multiple Bugzillas should always set both the params marked B<Required> and those marked B<Defaulted>, because some Bugzillas may not have defaults set for B<Defaulted> parameters, and then this method will throw an error if you don't specify them.

The descriptions of the parameters below are what they mean when Bugzilla is being used to track software bugs. They may have other meanings in some installations.

=over 4

=item product (string) B<Required> - The name of the product the bug is being filed against.

I<product> (string) B<Required> - The name of the product the bug is being filed against.

=item component

I<component> (string) B<Required> - The name of a component in the product above.

=item summary

I<summary> (string) B<Required> - A brief description of the bug being filed.

=item version

I<version> (string) B<Required> - A version of the product above; the version the bug was found in.

=item description

I<description> (string) B<Defaulted> - The initial description for this bug. Some Bugzilla installations require this to not be blank.

=item op_sys

I<op_sys> (string) B<Defaulted> - The operating system the bug was discovered on.

=item platform

I<platform> (string) B<Defaulted> - What type of hardware the bug was experienced on.

=item priority

I<priority> (string) B<Defaulted> - What order the bug will be fixed in by the developer, compared to the developer's other bugs.

=item severity

I<severity> (string) B<Defaulted> - How severe the bug is.

=item alias

I<alias> (string) - A brief alias for the bug that can be used instead of a bug number when accessing this bug. Must be unique in all of this Bugzilla.

=item assigned_to

I<assigned_to> (username) - A user to assign this bug to, if you don't want it to be assigned to the component owner.

=item cc

I<cc> (array) - An array of usernames to CC on this bug.

=item comment_is_private

I<comment_is_private> (boolean) - If set to true, the description is private, otherwise it is assumed to be public.

=item groups

I<groups> (array) - An array (ref) of group names to put this bug into. You can see valid group names on the I<Permissions tab> of the I<Preferences screen>, or, if you are an administrator, in the I<Groups control panel>. If you don't specify this argument, then the bug will be added into all the groups that are set as being "Default" for this product. (If you want to avoid that, you should specify C<groups> as an empty array.)

=item qa_contact

I<qa_contact> (username) - If this installation has QA Contacts enabled, you can set the QA Contact here if you don't want to use the component's default QA Contact.

=item status

I<status> (string) - The status that this bug should start out as. Note that only certain statuses can be set on bug creation.

=item resolution

I<resolution> (string) - If you are filing a closed bug, then you will have to specify a resolution. You cannot currently specify a resolution of C<DUPLICATE> for new bugs, though. That must be done with L</update>.

=item target_milestone

I<target_milestone> (string) - A valid target milestone for this product.

=item depends_on

I<depends_on> (array) - An array of bug id's that this new bug should depend upon.

As of Bugzilla 5.0 this option isn't included in the WebService API docks for =create()=, although it is mentioned in it's error codes.

=item blocks

I<blocks> (array) - An array of bug id's that this new bug should block.

As of Bugzilla 5.0 this option isn't included in the WebService API docks for =create()=, although it is mentioned in it's error codes.

=back

B<Note:> In addition to the above parameters, if your installation has any custom fields, you can set them just by passing in the name of the field and its value as a string.

=head3 Returns

A hash with one element, C<id>. This is the id of the newly-filed bug.

=head3 Errors

=over 4

=item 51 - Invalid Object

You specified a field value that is invalid. The error message will have more details.

=item 103 - Invalid Alias

The alias you specified is invalid for some reason. See the error message for more details.

=item 104 - Invalid Field

One of the drop-down fields has an invalid value, or a value entered in a text field is too long. The error message will have more detail.

=item 105 - Invalid Component

You didn't specify a component.

=item 106 - Invalid Product

Either you didn't specify a product, this product doesn't exist, or you don't have permission to enter bugs in this product.

=item 107 - Invalid Summary

You didn't specify a summary for the bug.

=item 116 - Dependency Loop

You specified values in the blocks or depends_on fields that would cause a circular dependency between bugs.

=item 120 - Group Restriction Denied

You tried to restrict the bug to a group which does not exist, or which you cannot use with this product.

=item 504 - Invalid User

Either the QA Contact, Assignee, or CC lists have some invalid user in them. The error message will have more details.

=back

=head2 update

  my $id = BZ::Client::Bug->update( $client, \%params );

Allows you to update the fields of a bug.

(Your Bugzilla server may automatically sends emails out about the changes)

=head3 History

Added in Bugzilla B<4.0>.

=head3 Parameters

=over 4

=item ids

I<ids> (Array of C<int>s or C<string>s) -  The ids or aliases of the bugs that you want to modify.

B<Note:> All following fields specify the values you want to set on the bugs you are updating.

=item alias

I<alias> (string) - The alias of the bug. You can only set this if you are modifying a single bug. If there is more than one bug specified in C<ids>, passing in a value for C<alias> will cause an error to be thrown.

=item assigned_to

I<assigned_to> (string) -  The full login name of the user this bug is assigned to.

=item blocks

I<blocks> (hash) -  These specify the bugs that this bug blocks. To set these, you should pass a hash as the value. The hash may contain the following fields:

=over 4

=item add

I<add> (Array of C<int>s) - Bug ids to add to this field.

=item remove

I<remove> (Array of C<int>s) -  Bug ids to remove from this field. If the bug ids are not already in the field, they will be ignored.

=item set

I<set> (Array of C<int>s) - An exact set of bug ids to set this field to, overriding the current value. If you specify C<set>, then C<add> and C<remove> will be ignored.

=back

=item depends_on

I<depends_on> (hash) -  These specify the bugs that this depends on. To set these, you should pass a hash as the value. The hash may contain the following fields:

=over 4

=item add

I<add> (Array of C<int>s) - Bug ids to add to this field.

=item remove

I<remove> (Array of C<int>s) -  Bug ids to remove from this field. If the bug ids are not already in the field, they will be ignored.

=item set

I<set> (Array of C<int>s) - An exact set of bug ids to set this field to, overriding the current value. If you specify C<set>, then C<add> and C<remove> will be ignored.

=back

=item cc

I<cc> (hash) -  The users on the cc list. To modify this field, pass a hash, which may have the following fields:

=over 4

=item add

I<add> (Array of C<string>s) - User names to add to the CC list. They must be full user names, and an error will be thrown if you pass in an invalid user name.

=item remove

I<remove> (Array of C<string>s) - User names to remove from the CC list. They must be full user names, and an error will be thrown if you pass in an invalid user name.

=back

=item is_cc_accessible

I<is_cc_accessible> (boolean) -  Whether or not users in the CC list are allowed to access the bug, even if they aren't in a group that can normally access the bug.

=item comment

I<comment> (hash) -  A comment on the change. The hash may contain the following fields:

=over 4

=item body

I<body> (string) -  The actual text of the comment. B<Note:> For compatibility with the parameters to L</add_comment>, you can also call this field C<comment>, if you wish.

=item is_private

I<is_private> (boolean) - Whether the comment is private or not. If you try to make a comment private and you don't have the permission to, an error will be thrown.

=back

=item comment_is_private

I<comment_is_private> (hash) - This is how you update the privacy of comments that are already on a bug. This is a hash, where the keys are the C<int> id of comments (not their count on a bug, like #1, #2, #3, but their globally-unique id, as returned by L</comments>) and the value is a C<boolean> which specifies whether that comment should become private (C<true>) or public (C<false>).

The comment ids must be valid for the bug being updated. Thus, it is not practical to use this while updating multiple bugs at once, as a single comment id will never be valid on multiple bugs.

=item component
I<component> (string) - The Component the bug is in.

=item deadline

I<deadline> (string) -  The Deadline field--a date specifying when the bug must be completed by, in the format C<YYYY-MM-DD>.

=item dupe_of

I<dupe_of> (int) -  The bug that this bug is a duplicate of. If you want to mark a bug as a duplicate, the safest thing to do is to set this value and not set the C<status> or C<resolution> fields. They will automatically be set by Bugzilla to the appropriate values for duplicate bugs.

=item estimated_time

I<estimated_time> (double) - The total estimate of time required to fix the bug, in hours. This is the I<total> estimate, not the amount of time remaining to fix it.

=item groups

I<groups> (hash) -  The groups a bug is in. To modify this field, pass a hash, which may have the following fields:

=over 4

=item add

I<add> (Array of C<string>s) - The names of groups to add. Passing in an invalid group name or a group that you cannot add to this bug will cause an error to be thrown.

=item remove

I<remove> (Array of C<string>s) - The names of groups to remove. Passing in an invalid group name or a group that you cannot remove from this bug will cause an error to be thrown.

=back

=item keywords

I<keywords> (hash) -  Keywords on the bug. To modify this field, pass a hash, which may have the following fields:

=over 4

=item add

I<add> (An array of C<string>s) - The names of keywords to add to the field on the bug. Passing something that isn't a valid keyword name will cause an error to be thrown.

=item remove

I<remove> (An array of C<string>s) - The names of keywords to remove from the field on the bug. Passing something that isn't a valid keyword name will cause an error to be thrown.

=item set

I<set> (An array of C<string>s) - An exact set of keywords to set the field to, on the bug. Passing something that isn't a valid keyword name will cause an error to be thrown. Specifying C<set> overrides C<add> and C<remove>.

=back

=item op_sys

I<op_sys> (string) -  The Operating System ("OS") field on the bug.

=item platform

I<platform> (string) - The Platform or "Hardware" field on the bug.

=item priority

I<priority> (string) -  The Priority field on the bug.

=item product

I<product> (string) - The name of the product that the bug is in. If you change this, you will probably also want to change C<target_milestone>, C<version>, and C<component>, since those have different legal values in every product.

If you cannot change the C<target_milestone> field, it will be reset to the default for the product, when you move a bug to a new product.

You may also wish to add or remove groups, as which groups are valid on a bug depends on the product. Groups that are not valid in the new product will be automatically removed, and groups which are mandatory in the new product will be automaticaly added, but no other automatic group changes will be done.

B<Note:> that users can only move a bug into a product if they would normally have permission to file new bugs in that product.

=item qa_contact

I<qa_contact> (string) - The full login name of the bug's QA Contact.

=item is_creator_accessible

I<is_creator_accessible> (boolean) - Whether or not the bug's reporter is allowed to access the bug, even if he or she isn't in a group that can normally access the bug.

=item remaining_time

I<remaining_time> (double) - How much work time is remaining to fix the bug, in hours. If you set C<work_time> but don't explicitly set C<remaining_time>, then the C<work_time> will be deducted from the bug's C<remaining_time>.

=item reset_assigned_to

I<reset_assigned_to> (boolean) - If true, the C<assigned_to> field will be reset to the default for the component that the bug is in. (If you have set the component at the same time as using this, then the component used will be the new component, not the old one.)

=item reset_qa_contact

I<reset_qa_contact> (boolean) - If true, the C<qa_contact> field will be reset to the default for the component that the bug is in. (If you have set the component at the same time as using this, then the component used will be the new component, not the old one.)

=item resolution

I<resolution> (string) The current resolution. May only be set if you are closing a bug or if you are modifying an already-closed bug. Attempting to set the resolution to I<any> value (even an empty or null string) on an open bug will cause an error to be thrown.

If you change the C<status> field to an open status, the resolution field will automatically be cleared, so you don't have to clear it manually.

=item see_also

I<see_also> (hash) - The See Also field on a bug, specifying URLs to bugs in other bug trackers. To modify this field, pass a hash, which may have the following fields:

=over 4

=item add

I<add> (An array of C<string>s) - URLs to add to the field. Each URL must be a valid URL to a bug-tracker, or an error will be thrown.

=item remove

I<remove> (An array of C<string>s) - URLs to remove from the field. Invalid URLs will be ignored.

=back

=item severity

I<severity> (string) - The Severity field of a bug.

=item status

I<status> (string) - The status you want to change the bug to. Note that if a bug is changing from open to closed, you should also specify a resolution.

=item summary

I<summary> (string) - The Summary field of the bug.

=item target_milestone

I<target_milestone> (string) -  The bug's Target Milestone.

=item url

I<url> (string) - The "URL" field of a bug.

=item version

I<version> (string) -  The bug's Version field.

=item whiteboard

I<whiteboard> (string) - The Status Whiteboard field of a bug.

=item work_time

I<work_time> (double) - The number of hours worked on this bug as part of this change. If you set C<work_time> but don't explicitly set C<remaining_time>, then the C<work_time> will be deducted from the bug's remaining_time.

=back

B<Note:> You can also set the value of any custom field by passing its name as a parameter, and the value to set the field to. For multiple-selection fields, the value should be an array of strings.

=head3 Returns

A C<hash> with a single field, "bugs". This points to an array of hashes with the following fields:

=over 4

=item id

I<id> (int) - The id of the bug that was updated.

=item alias

I<alias> (string) - The alias of the bug that was updated, if this bug has an alias.

=item last_change_time

I<last_change_time> (L<DateTime>) - The exact time that this update was done at, for this bug. If no update was done (that is, no fields had their values changed and no comment was added) then this will instead be the last time the bug was updated.

=item changes

I<changes> (hash) - The changes that were actually done on this bug. The keys are the names of the fields that were changed, and the values are a hash with two keys:

=over 4

=item added

I<added> (string) - The values that were added to this field, possibly a comma-and-space-separated list if multiple values were added.

=item removed

I<removed> (string) - The values that were removed from this field, possibly a comma-and-space-separated list if multiple values were removed.

=back

=back

Here's an example of what a return value might look like:

 {
   bugs => [
     {
       id    => 123,
       alias => 'foo',
       last_change_time => '2010-01-01T12:34:56',
       changes => {
         status => {
           removed => 'NEW',
           added   => 'ASSIGNED'
         },
         keywords => {
           removed => 'bar',
           added   => 'qux, quo, qui',
         },
       },
     },
   ],
 }

B<Note:> Currently, some fields are not tracked in changes: C<comment>, C<comment_is_private>, and C<work_time>. This means that they will not show up in the return value even if they were successfully updated. This may change in a future version of Bugzilla.

=head3 Errors

This function can throw all of the errors that L</get>, L</create>, and L</add_comment> can throw, plus:

=over 4

=item 50 - Empty Field

You tried to set some field to be empty, but that field cannot be empty. The error message will have more details.

=item 52 - Input Not A Number

You tried to set a numeric field to a value that wasn't numeric.

=item 54 - Number Too Large

You tried to set a numeric field to a value larger than that field can accept.

=item 55 - Number Too Small

You tried to set a negative value in a numeric field that does not accept negative values.

=item 56 - Bad Date/Time

You specified an invalid date or time in a date/time field (such as the deadline field or a custom date/time field).

=item 112 - See Also Invalid

You attempted to add an invalid value to the see_also field.

=item 115 - Permission Denied

You don't have permission to change a particular field to a particular value. The error message will have more detail.

=item 116 - Dependency Loop

You specified a value in the blocks or depends_on fields that causes a dependency loop.

=item 117 - Invalid Comment ID

You specified a comment id in comment_is_private that isn't on this bug.

=item 118 - Duplicate Loop

You specified a value for dupe_of that causes an infinite loop of duplicates.

=item 119 - dupe_of Required

You changed the resolution to DUPLICATE but did not specify a value for the dupe_of field.

=item 120 - Group Add/Remove Denied

You tried to add or remove a group that you don't have permission to modify for this bug, or you tried to add a group that isn't valid in this product.

=item 121 - Resolution Required

You tried to set the status field to a closed status, but you didn't specify a resolution.

=item 122 - Resolution On Open Status

This bug has an open status, but you specified a value for the resolution field.

=item 123 - Invalid Status Transition

You tried to change from one status to another, but the status workflow rules don't allow that change.

=back

=head2 update_see_also

 @changes = BZ::Client::Bug->update_see_also( $client, \%params );
 $changes = BZ::Client::Bug->update_see_also( $client, \%params );

Adds or removes URLs for the I<See Also> field on bugs. These URLs must point to some valid bug in some Bugzilla installation or in Launchpad.

=head3 History

This is marked as B<EXPERIMENTAL> in Bugzilla 4.4

Added in Bugzilla 3.4.

=head3 Parameters

=over 4

=item ids

An array of integers or strings. The IDs or aliases of bugs that you want to modify.

=item add

Array of strings. URLs to Bugzilla bugs. These URLs will be added to the I<See Also> field.

If the URLs don't start with C<http://> or C<https://>, it will be assumed that C<http://> should be added to the beginning of the string.

It is safe to specify URLs that are already in the I<See Also> field on a bug as they will just be silently ignored.

=item remove

An array of strings. These URLs will be removed from the I<See Also> field. You must specify the full URL that you want removed. However, matching is done case-insensitively, so you don't have to specify the URL in exact case, if you don't want to.

If you specify a URL that is not in the I<See Also> field of a particular bug, it will just be silently ignored. Invaild URLs are currently silently ignored, though this may change in some future version of Bugzilla.

=back

B<Note:> If you specify the same URL in both L</add> and L</remove>, it will be added. (That is, L</add> overrides L</remove>.)

=head3 Returns

A hash or hashref where the keys are numeric bug ids and the contents are a hash with one key, C<see_also>.

C<see_also> points to a hash, which contains two keys, C<added> and C<removed>.

These are arrays of strings, representing the actual changes that were made to the bug.

Here's a diagram of what the return value looks like for updating bug ids 1 and 2:

 {
     1 => {
         see_also => {
             added   => [(an array of bug URLs)],
             removed => [(an array of bug URLs)],
         }
     },
     2 => {
         see_also => {
             added   => [(an array of bug URLs)],
             removed => [(an array of bug URLs)],
         }
     }
 }

This return value allows you to tell what this method actually did.

It is in this format to be compatible with the return value of a future L</update> method.

=head3 Errors

=over 4

=item 100 - Invalid Bug Alias

If you specified an alias and there is no bug with that alias.

=item 101 - Invalid Bug ID

The bug_id you specified doesn't exist in the database.

=item 102 - Access Denied

You do not have access to the bug_id you specified.

=item 109 - Bug Edit Denied

You did not have the necessary rights to edit the bug.

=item 112 - Invalid Bug URL

One of the URLs you provided did not look like a valid bug URL.

=item 115 - See Also Edit Denied

You did not have the necessary rights to edit the See Also field for this bug.

Before Bugzilla 3.6, error 115 had a generic error code of 32000.

=back

=head2 update_tags

 @changes = BZ::Client::Bug->update_tags( $client, \%params );
 $changes = BZ::Client::Bug->update_tags( $client, \%params );

Adds or removes tags on bugs.

Unlike Keywords which are global and visible by all users, Tags are personal and can only be viewed and edited by their author. Editing them won't send any notification to other users. Use them to tag and keep track of bugs.

Bugzilla will lower case the text of the tags. This doesn't seem to be documented.

B<Reminder:> to retrieve these tags, specify C<_extra> or the field name C<tags> in L</include_fields> when searching etc.

=head3 History

This is marked as B<UNSTABLE> in Bugzilla 4.4

Added in Bugzilla 4.4.

=head3 Parameters

=over 4

=item ids

An array of ints and/or strings--the ids or aliases of bugs that you want to add or remove tags to. All the tags will be added or removed to all these bugs.

=item tags

A hash representing tags to be added and/or removed. The hash has the following fields:

=over 4

=item add

An array of strings representing tag names to be added to the bugs.

It is safe to specify tags that are already associated with the bugs as they will just be silently ignored.

=item remove

An array of strings representing tag names to be removed from the bugs.

It is safe to specify tags that are not associated with any bugs as they will just be silently ignored.

=back

=back

=head3 Returns

A hash or hashref where the keys are numeric bug ids and the contents are a hash with one key, C<tags>.

C<tags> points to a hash, which contains two keys, C<added> and C<removed>.

These are arrays of strings, representing the actual changes that were made to the bug.

Here's a diagram of what the return value looks like for updating bug ids 1 and 2:

 {
     1 => {
         tags => {
             added   => [(an array of tags)],
             removed => [(an array of tags)],
         }
     },
     2 => {
         tags => {
             added   => [(an array of tags)],
             removed => [(an array of tags)],
         }
     }
 }

This return value allows you to tell what this method actually did.

=head3 Errors

=over 4

=item 100 - Invalid Bug Alias

If you specified an alias and there is no bug with that alias.

=item 101 - Invalid Bug ID

The bug_id you specified doesn't exist in the database.

=item 102 - Access Denied

You do not have access to the bug_id you specified.

=back

=head2 new

 my $bug = BZ::Client::Bug->new( id => $id );

Creates a new bug object instance with the given ID.

B<Note:> Doesn't actually touch your bugzilla server.

See L</INSTANCE METHODS> for how to use it.

=head1 INSTANCE METHODS

This section lists the modules instance methods.

Once you have a bug object, you can use these methods to inspect and manipulate the bug.

=head2 id

 $id = $bug->id();
 $bug->id( $id );

Gets or sets the bugs ID.

=head2 alias

 $alias = $bug->alias();
 $bug->alias( $alias );

Gets or sets the bugs alias. If there is no alias or aliases are disabled in Bugzilla,
this will be an empty string.

=head2 assigned_to

 $assigned_to = $bug->assigned_to();
 $bug->assigned_to( $assigned_to );

Gets or sets the login name of the user to whom the bug is assigned.

=head2 component

 $component = $bug->component();
 $bug->component( $component );

Gets or sets the name of the current component of this bug.

=head2 creation_time

 $dateTime = $bug->creation_time();
 $bug->creation_time( $dateTime );

Gets or sets the date and time, when the bug was created.

=head2 dupe_of

 $dupeOf = $bug->dupe_of();
 $bug->dupe_of( $dupeOf );

Gets or sets the bug ID of the bug that this bug is a duplicate of. If this
bug isn't a duplicate of any bug, this will be an empty int.

=head2 is_open

 $isOpen = $bug->is_open();
 $bug->is_open( $isOpen );

Gets or sets, whether this bug is closed. The return value, or parameter value
is true (1) if this bug is open, false (0) if it is closed.

=head2 last_change_time

 $lastChangeTime = $bug->last_change_time();
 $bug->last_change_time( $lastChangeTime );

Gets or sets the date and time, when the bug was last changed.

=head2 priority

 $priority = $bug->priority();
 $bug->priority( $priority );

Gets or sets the priority of the bug.

=head2 product

 $product = $bug->product();
 $bug->product( $product );

Gets or sets the name of the product this bug is in.

=head2 resolution

 $resolution = $bug->resolution();
 $bug->resolution( $resolution );

Gets or sets the current resolution of the bug, or an empty string if the bug is open.

=head2 severity

 $severity = $bug->severity();
 $bug->severity( $severity );

Gets or sets the current severity of the bug.

=head2 status

 $status = $bug->status();
 $bug->status( $status );

Gets or sets the current status of the bug.

=head2 summary

 $summary = $bug->summary();
 $bug->summary( $summary );

Gets or sets the summary of this bug.

=head1 ATTACHMENTS & COMMENTS

These are implemented by other modules.

See L<BZ::Client::Bug::Attachment> and L<BZ::Client::Bug::Comment>

=head1 TODO

Bugzilla 5.0. introduced the C<search_comment_tags> and C<update_comment_tags> methods,
these are yet to be specifically implemented.

=head1 SEE ALSO

L<BZ::Client>, L<BZ::Client::Bug::Attachment>, L<BZ::Client::Bug::Comment>

L<BZ::Client::API>,
L<Bugzilla WebService 4.4 API|https://www.bugzilla.org/docs/4.4/en/html/api/Bugzilla/WebService/Bug.html>,
L<Bugzilla WebService 5.0 API|https://www.bugzilla.org/docs/5.0/en/html/integrating/api/Bugzilla/WebService/Bug.html>

=head1 AUTHORS

=over 4

=item *

Dean Hamstead <dean@bytefoundry.com.au>

=item *

Jochen Wiedmann <jochen.wiedmann@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Dean Hamstad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
