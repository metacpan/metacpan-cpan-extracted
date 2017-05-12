package Data::MuForm::Field::Select;

# ABSTRACT: Select field

use Moo;
extends 'Data::MuForm::Field';
use Types::Standard -types;
use HTML::Entities;
use Data::Dump ('pp');


sub build_form_element { 'select' }

has 'options' => (
    is => 'rw',
    isa => ArrayRef,
    lazy => 1,
    builder => 'build_options',
    coerce => sub {
        my $options = shift;
        my @options = @$options;
        return [] unless scalar @options;
        my @opts;
        my $order = 0;
        if ( ref $options[0] eq 'HASH' ) {
            @opts = @options;
            $_->{order} = $order++ foreach @opts;
        }
        elsif ( scalar @options == 1 && ref($options[0]) eq 'ARRAY' ) {
            @options = @{ $options[0] };
            push @opts, { value => $_, label => $_, order => $order++ } foreach @options;
        }
        else {
            die "Options array must contain an even number of elements"
              if @options % 2;
            push @opts, { value => shift @options, label => shift @options, order => $order++ } while @options;
        }
        return \@opts;
    },
);
sub build_options {[]}
sub has_options { shift->num_options }
sub num_options { scalar @{$_[0]->options} }
sub all_options { @{$_[0]->options} }
has 'options_from' => ( is => 'rw', default => 'none' );
has 'do_not_reload' => ( is => 'ro' );
has 'no_option_validation' => ( is => 'rw' );

has 'multiple' => ( is => 'ro', default => 0 );
has 'size' => ( is => 'rw' );
has 'empty_select' => ( is => 'rw', predicate => 'has_empty_select' );

# add trigger to 'value' so we can enforce arrayref value for multiple
has '+value' => ( trigger => 1 );
sub _trigger_value {
    my ( $self, $value ) = @_;
    return unless $self->multiple;
    if (!defined $value || $value eq ''){
        $value = [];
    }
    else {
       $value = ref $value eq 'ARRAY' ? $value : [$value];
    }
    $self->{value} = $value;
}

# This is necessary because if a Select field is unselected, no param will be
# submitted. Needs to be lazy because it checks 'multiple'. Needs to be vivified in BUILD.
has '+input_without_param' => ( lazy => 1, builder => 'build_input_without_param' );
sub build_input_without_param {
    my $self = shift;
    if( $self->multiple ) {
        $self->not_nullable(1);
        return [];
    }
    else {
        return '';
    }
}

has 'label_column' => ( is => 'rw', default => 'name' );
has 'active_column' => ( is => 'rw', default => 'active' );
has 'sort_column' => ( is => 'rw' );


sub BUILD {
    my $self = shift;

    # vivify, so predicate works
    $self->input_without_param;

    if( $self->options && $self->has_options ) {
        $self->options_from('build');
    }
    if( $self->form  && ! exists $self->{methods}->{build_options} ) {
        my $suffix = $self->convert_full_name($self->full_name);
        my $meth_name = "options_$suffix";
        if ( my $meth = $self->form->can($meth_name) ) {
            my $wrap_sub = sub {
                my $self = shift;
                return $self->form->$meth;
            };
            $self->{methods}->{build_options} = $wrap_sub;
        }
    }
    $self->_load_options unless $self->has_options;
}

sub fill_from_params {
    my ( $self, $input, $exists ) = @_;
    $input = ref $input eq 'ARRAY' ? $input : [$input]
        if $self->multiple;
    $self->next::method( $input, $exists );
    $self->_load_options;
}

sub fill_from_object {
    my ( $self, $obj ) = @_;
    $self->next::method( $obj );
    $self->_load_options;
}

sub fill_from_fields {
    my ( $self ) = @_;
    $self->next::method();
    $self->_load_options;
}

sub _load_options {
    my $self = shift;

    return
        if ( $self->options_from eq 'build' ||
        ( $self->has_options && $self->do_not_reload ) );

    # we allow returning an array instead of an arrayref from a build method
    # and it's the usual thing from the DBIC model
    my @options;
    if( my $meth = $self->get_method('build_options') ) {
        @options = $meth->($self);
        $self->options_from('method');
    }
    elsif ( $self->form ) {
        my $full_accessor;
        $full_accessor = $self->parent->full_accessor if $self->parent;
        @options = $self->form->lookup_options( $self, $full_accessor );
        $self->options_from('model') if scalar @options;
    }
    return unless @options;    # so if there isn't an options method and no options
                               # from a table, already set options attributes stays put

    # possibilities:
    #  @options = ( 1 => 'one', 2 => 'two' );
    #  @options = ({ value => 1, label => 'one', { value => 2, label => 'two'})
    #  @options = ([ 1 => 'one', 2 => 'tw' ]);
    #  @options = ([ { value => 1, label => 'one'}, { value => 2, label => 'two'}]);
    #  @options = ([[ 'one', 'two' ]]);
    my $opts = ref $options[0] eq 'ARRAY' ? $options[0] : \@options;
    $opts = $self->options($opts);  # coerce will re-format

    if (scalar @$opts) {
        # sort options if sort method exists
        $opts = $self->sort_options($opts) if $self->methods->{sort};
        # we don't want to trigger and re-order, so set directly
        $self->{options} = $opts;
    }
}

our $class_messages = {
    'select_not_multiple' => 'This field does not take multiple values',
    'select_invalid_value' => '\'{value}\' is not a valid value',
};

sub base_render_args {
    my $self = shift;
    my $args = $self->next::method(@_);
    $args->{multiple} = $self->multiple;
    $args->{options} = $self->options;
    $args->{empty_select} = $self->empty_select if $self->has_empty_select;
    $args->{size} = $self->size if defined $self->size;
    return $args;
}

sub render_option {
  my ( $self, $option ) = @_;
  my $render_args = $self->get_render_args;
  return $self->renderer->render_option($render_args, $option);
}

sub get_class_messages  {
    my $self = shift;
    return {
        %{ $self->next::method },
        %$class_messages,
    }
}

sub normalize_input {
    my ($self) = @_;

    my $input = $self->input;
    return unless defined $input;    # nothing to check

    if ( ref $input eq 'ARRAY' && !( $self->can('multiple') && $self->multiple ) ) {
        $self->add_error( $self->get_message('select_not_multiple') );
    }
    elsif ( ref $input ne 'ARRAY' && $self->multiple ) {
        $input = [$input];
        $self->input($input);
    }
}

sub validate {
    my $self = shift;

    return if $self->no_option_validation;

    my $value = $self->value;
    # create a lookup hash
    my %options;
    foreach my $opt ( @{ $self->options } ) {
        if ( exists $opt->{group} ) {
            foreach my $group_opt ( @{ $opt->{options} } ) {
                $options{$group_opt->{value}} = 1;
            }
        }
        else {
            $options{$opt->{value}} = 1;
        }
    }
    for my $value ( ref $value eq 'ARRAY' ? @$value : ($value) ) {
        unless ( $options{$value} ) {
            my $opt_value = encode_entities($value);
            $self->add_error($self->get_message('select_invalid_value'), value => $opt_value);
            return;
        }
    }
    return 1;
}

sub as_label {
    my ( $self, $value ) = @_;

    $value = $self->value unless defined $value;
    return unless defined $value;
    if ( $self->multiple ) {
        unless ( ref($value) eq 'ARRAY' ) {
            if( $self->has_transform_default_to_value ) {
                my @values = $self->transform_default_to_value->($self, $value);
                $value = \@values;
            }
            else {
                # not sure under what circumstances this would happen, but
                # just in case
                return $value;
            }
        }
        my @labels;
        my %value_hash;
        @value_hash{@$value} = ();
        for ( $self->all_options ) {
            if ( exists $value_hash{$_->{value}} ) {
                push @labels, $_->{label};
                delete $value_hash{$_->{value}};
                last unless keys %value_hash;
            }
        }
        my $str = join(', ', @labels);
        return $str;
    }
    else {
        for ( $self->all_options ) {
            return $_->{label} if $_->{value} eq $value;
        }
    }
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::MuForm::Field::Select - Select field

=head1 VERSION

version 0.04

=head1 DESCRIPTION

This is a field that includes a list of possible valid options.
This can be used for select and multiple-select fields.
The field can be rendered as a select, a checkbox group (when
'multiple' is turned on), or a radiogroup.

Because select lists and checkbox_groups do not return an HTTP
parameter when the entire list is unselected, the Select field
must assume that the lack of a param means unselection. So to
avoid setting a Select field with the 'skip_fields_without_input'
flag, it must be set to inactive, not merely not included in the
submitted params.

=head2 options

The 'options' attribute returns an arrayref. (In FH it used to return
an array.)

The 'options' array can come from a number of different places, but
a coercion will reformat from one of the valid options formats to
the standard arrayref of hashrefs.

=over 4

=item From a field declaration

In a field declaration:

   has_field 'opt_in' => ( type => 'Select',
      options => [{ value => 0, label => 'No'}, { value => 1, label => 'Yes'} ] );

=item From a coderef supplied to the field definition

   has_field 'flim' => ( type => 'Select', methods => { build_options => \&flim_options );
   sub flim_options {  <return options arrayref> }

=item From a form 'options_<field_name>' method or attribute

   has_field 'fruit' => ( type => 'Select' );
   sub options_fruit { <returns options arraryef> }
       OR
   has 'options_fruit' => ( is => 'rw',
       default => sub { [1 => 'apples', 2 => 'oranges', 3 => 'kiwi'] } );

The 'attribute' version is mostly useful when you want to be able to pass the
options in on ->new or ->process.

=item From a field class 'build_options' method

In a custom field class:

   package MyApp::Field::WeekDay;
   use Moo;
   extends 'Data::MuForm::Field::Select';
   ....
   sub build_options { <returns a valid options arrayref> }

=item From the database

The final source of the options array is a database when the name of the
accessor is a relation to the table holding the information used to construct
the select list.  The primary key is used as the value. The other columns used are:

    label_column  --  Used for the labels in the options (default 'name')
    active_column --  The name of the column to be used in the query (default 'active')
                      that allows the rows retrieved to be restricted
    sort_column   --  The name or arrayref of names of the column(s) used to sort the options

See also L<Data::MuForm::Model::DBIC>, the 'lookup_options' method.

=back

The options field should contain one of the following valid data structures:

=over

=item ArrayRef of HashRefs

Each hash reference defines an option, with the label and value
attributes corresponding to those of the HTML field. This is the only
structure in which you can supply additional attributes to be rendered.
This is the format to which the other accepted formats will be coerced.

   [{ value => 1, label => 'one' }, { value => 2, label => 'two' }]]

=item ArrayRef

A list of key/value pairs corresponding to HTML field values and labels.

   [ 1 => 'one', 2 => 'two' ]

=item ArrayRef containing one ArrayRef

Each item inside the inner ArrayRef defines both the label and value of
an option.

   [[ 'one', 'two' ]]

=back

=head2 Customizing options

Additional attributes can be added in the options array hashref.

  [{ value => 1, label => 'one', id => 'first' }, { value => 1, label => 'two', id => 'second' }]

You can also use an 'attributes' hashref to set additional renderable option
attributes (compatible with FH).

  [{ value => 1, label => 'one', attributes => { 'data-field' => { 'key' => '...' } } }]

Note that you should *not* set 'checked' or 'selected' attributes in options.
That is handled by setting a field default.

    has_field 'my_select' => ( type => 'Select', default => 2 );

You can also divide the options up into option groups. See the section on
rendering.

=head2 Reloading options

If the options come from the options_<fieldname> method or the database, they
will be reloaded every time the form is reloaded because the available options
may have changed. To prevent this from happening when the available options are
known to be static, set the 'do_not_reload' flag, and the options will not be
reloaded after the first time

=head2 Sorting options

The sorting of the options may be changed using a 'sort_options' method in a
custom field class. The 'Multiple' field uses this method to put the already
selected options at the top of the list. Note that this won't work with
option groups.

=head1 Other Attributes and Methods

=head2 multiple

If true allows multiple input values

=head2 size

This can be used to store how many items should be offered in the UI
at a given time.  Defaults to 0.

=head2 empty_select

Set to the string value of the select label if you want the renderer
to create an empty select value. This only affects rendering - it does
not add an entry to the list of options.

   has_field 'fruit' => ( type => 'Select',
        empty_select => '---Choose a Fruit---' );

=head2 label_column

Sets or returns the name of the method to call on the foreign class
to fetch the text to use for the select list.

Refers to the method (or column) name to use in a related
object class for the label for select lists.

Defaults to "name".

=head2 active_column

Sets or returns the name of a boolean column that is used as a flag to indicate that
a row is active or not.  Rows that are not active are ignored.

The default is "active".

If this column exists on the class then the list of options will included only
rows that are marked "active".

The exception is any columns that are marked inactive, but are also part of the
input data will be included with brackets around the label.  This allows
updating records that might have data that is now considered inactive.

=head2 sort_column

Sets or returns the column or arrayref of columns used in the foreign class
for sorting the options labels.  Default is undefined.

If not defined the label_column is used as the sort condition.

=head2 as_label

Returns the option label for the option value that matches the field's current value.
Can be helpful for displaying information about the field in a more friendly format.

=head2 no_option_validation

Set this flag to true if you don't want to validate the options that are submitted.
This would generally only happen if the options are generated via javascript, and
you would presumably have some other kind of validation.

=head2 error messages

Customize 'select_invalid_value' and 'select_not_multiple'. Though neither of these
messages should really be seen by users in a properly constructed select.

=head1 Rendering

The 'select' field can be rendered as a 'select', 'radiogroup', and 'checkboxgroup'.
You change the 'layout_type' from 'standard' (for select) to 'radiogroup' or
'checkboxgroup' in the render args.

Option groups can be rendered by providing an options arrays with 'group' elements
containing options:

    sub options_testop { [
        {
            group => 'First Group',
            options => [
                { value => 1, label => 'One' },
                { value => 2, label => 'Two' },
                { value => 3, label => 'Three' },
            ],
        },
        {
            group => 'Second Group',
            options => [
                { value => 4, label => 'Four' },
                { value => 5, label => 'Five' },
                { value => 6, label => 'Six' },
            ],
        },
    ] }

You can use the 'render_option' method to render the options individually in
a template.

=head1 Database relations

Also see L<DBIC::MuForm::Role::Model::DBIC>.

The single select is for a DBIC 'belongs_to' relation. The multiple select is for
a 'many_to_many' relation.

=head1 AUTHOR

Gerda Shank

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
