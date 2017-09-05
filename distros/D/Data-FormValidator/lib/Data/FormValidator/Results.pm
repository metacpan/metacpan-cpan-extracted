#
#    Results.pm - Object which contains validation result.
#
#    This file is part of FormValidator.
#
#    Author: Francis J. Lacoste <francis.lacoste@iNsu.COM>
#    Maintainer: Mark Stosberg <mark@summersault.com>
#
#    Copyright (C) 2000 iNsu Innovations Inc.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms same terms as perl itself.
#
use strict;

package Data::FormValidator::Results;
use Carp;
use Symbol;
use Data::FormValidator::Filters ':filters';
use Data::FormValidator::Constraints qw(:validators :matchers);
use overload
  'bool' => \&_bool_overload_based_on_success,
  fallback => 1;

our $VERSION = 4.88;

=pod

=head1 NAME

Data::FormValidator::Results - results of form input validation.

=head1 SYNOPSIS

    my $results = Data::FormValidator->check(\%input_hash, \%dfv_profile);

    # Print the name of missing fields
    if ( $results->has_missing ) {
    for my $f ( $results->missing ) {
        print $f, " is missing\n";
    }
    }

    # Print the name of invalid fields
    if ( $results->has_invalid ) {
    for my $f ( $results->invalid ) {
        print $f, " is invalid: ", $results->invalid( $f ), "\n";
    }
    }

    # Print unknown fields
    if ( $results->has_unknown ) {
    for my $f ( $results->unknown ) {
        print $f, " is unknown\n";
    }
    }

    # Print valid fields
    for my $f ( $results->valid() ) {
        print $f, " =  ", $results->valid( $f ), "\n";
    }

=head1 DESCRIPTION

This object is returned by the L<Data::FormValidator> C<check> method.
It can be queried for information about the validation results.

=cut

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my ($profile, $data) = @_;

    my $self = bless {}, $class;

    $self->_process( $profile, $data );

    $self;
}

sub _process {
    my ($self, $profile, $data) = @_;

    # Copy data and assumes that all is valid to start with

    my %data        = $self->_get_input_as_hash($data);
    my %valid       = %data;
    my @missings    = ();
    my @unknown     = ();

    # msgs() method will need access to the profile
    $self->{profile} = $profile;

    my %imported_validators;

    # import valid_* subs from requested packages
    for my $package (_arrayify($profile->{validator_packages})) {
        if ( !exists $imported_validators{$package} ) {
            local $SIG{__DIE__}  = \&confess;
            eval "require $package";
            if ($@) {
                die "Couldn't load validator package '$package': $@";
            }

            # Perl will die with a nice error message if the package can't be found
            # No need to go through extra effort here. -mls :)
            my $package_ref = qualify_to_ref("${package}::");
            my @subs = grep(/^(valid_|match_|filter_)/,
                            keys(%{*{$package_ref}}));
            for my $sub (@subs) {
                # is it a sub? (i.e. make sure it's not a scalar, hash, etc.)
                my $subref = *{qualify_to_ref("${package}::$sub")}{CODE};
                if (defined $subref) {
                    *{qualify_to_ref($sub)} = $subref;
                }
            }
            $imported_validators{$package} = 1;
        }
    }

    # Apply unconditional filters
    for my $filter (_arrayify($profile->{filters})) {
        if (defined $filter) {
            # Qualify symbolic references
            $filter = (ref $filter eq 'CODE' ? $filter : *{qualify_to_ref("filter_$filter")}{CODE}) ||
                die "No filter found named: '$filter'";
            for my $field ( keys %valid ) {
                # apply filter, modifying %valid by reference, skipping undefined values
                _filter_apply(\%valid,$field,$filter);
            }
        }
    }

    # Apply specific filters
    while ( my ($field,$filters) = each %{$profile->{field_filters} }) {
        for my $filter ( _arrayify($filters)) {
            if (defined $filter) {
                # Qualify symbolic references
                $filter = (ref $filter eq 'CODE' ? $filter : *{qualify_to_ref("filter_$filter")}{CODE}) ||
                    die "No filter found named '$filter'";

                # apply filter, modifying %valid by reference
                _filter_apply(\%valid,$field,$filter);
            }
        }
    }

    # add in specific filters from the regexp map
    while ( my ($re,$filters) = each %{$profile->{field_filter_regexp_map} }) {
        my $sub = _create_sub_from_RE($re);

        for my $filter ( _arrayify($filters)) {
            if (defined $filter) {
                # Qualify symbolic references
                $filter = (ref $filter eq 'CODE' ? $filter : *{qualify_to_ref("filter_$filter")}{CODE}) ||
                    die "No filter found named '$filter'";

                no strict 'refs';

                # find all the keys that match this RE and apply filters to them
                for my $field (grep { $sub->($_) } (keys %valid)) {
                    # apply filter, modifying %valid by reference
                    _filter_apply(\%valid,$field,$filter);
                }
            }
        }
    }

    # store the filtered data away for later use
    $self->{__FILTERED_DATA} = \%valid;

    my %required    = map { $_ => 1 } _arrayify($profile->{required});
    my %optional    = map { $_ => 1 } _arrayify($profile->{optional});

    # loop through and add fields to %required and %optional based on regular expressions
    my $required_re = _create_sub_from_RE($profile->{required_regexp});
    my $optional_re = _create_sub_from_RE($profile->{optional_regexp});

    for my $k (keys %valid) {
       if ($required_re && $required_re->($k)) {
          $required{$k} =  1;
       }

       if ($optional_re && $optional_re->($k)) {
          $optional{$k} =  1;
       }
    }

    # handle "require_some"
    while (my ($field, $dependent_require_some) = each %{$profile->{dependent_require_some}}) {
        if (defined $valid{$field}) {
            if (ref $dependent_require_some eq "CODE") {
                for my $value (_arrayify($valid{$field})) {
                    my $returned_require_some = $dependent_require_some->($self, $value);

                    if (ref($returned_require_some) eq 'HASH') {
                        foreach my $key (keys %$returned_require_some) {
                            $profile->{require_some}->{$key} = $returned_require_some->{$key};
                        }
                    }
                }
            } else {
                if (ref($dependent_require_some) eq 'HASH') {
                    foreach my $key (keys %$dependent_require_some) {
                        $profile->{require_some}->{$key} = $dependent_require_some->{$key};
                    }
                }
            }
        }
    }

    my %require_some;
    while ( my ( $field, $deps) = each %{$profile->{require_some}} ) {
        for my $dep (_arrayify($deps)){
             $require_some{$dep} = 1;
        }
    }


    # Remove all empty fields
    for my $field (keys %valid) {
        if (ref $valid{$field}) {
            if ( ref $valid{$field} eq 'ARRAY' ) {
                for (my $i = 0; $i < scalar @{ $valid{$field} }; $i++) {
                    $valid{$field}->[$i] = undef unless (defined $valid{$field}->[$i] and length $valid{$field}->[$i] and $valid{$field}->[$i] !~ /^\x00$/);
                }
                # If all fields are empty, we delete it.
                delete $valid{$field} unless grep { defined $_ } @{$valid{$field}};

            }
        }
        else {
            delete $valid{$field} unless (defined $valid{$field} and length $valid{$field} and $valid{$field} !~ /^\x00$/);
        }
    }

    # Check if the presence of some fields makes other optional fields required.
    while ( my ( $field, $deps) = each %{$profile->{dependencies}} ) {
        if (defined $valid{$field}) {
            if (ref($deps) eq 'HASH') {
                for my $key (keys %$deps) {
                    # Handle case of a key with a single value given as an arrayref
                    # There is probably a better, more general solution to this problem.
                    my $val_to_compare;
                    if ((ref $valid{$field} eq 'ARRAY') and (scalar @{ $valid{$field} } == 1)) {
                        $val_to_compare = $valid{$field}->[0];
                    }
                    else {
                        $val_to_compare = $valid{$field}
                    }

                    if($val_to_compare eq $key){
                        for my $dep (_arrayify($deps->{$key})){
                            $required{$dep} = 1;
                        }
                    }
                }
            }
            elsif (ref $deps eq "CODE") {
                for my $val (_arrayify($valid{$field})) {
                    my $returned_deps = $deps->($self, $val);

                    for my $dep (_arrayify($returned_deps)) {
                        $required{$dep} = 1;
                    }
                }
            }
            else {
                for my $dep (_arrayify($deps)){
                    $required{$dep} = 1;
                }
            }
        }
    }

    # check dependency groups
    # the presence of any member makes them all required
    for my $group (values %{ $profile->{dependency_groups} }) {
       my $require_all = 0;
       for my $field (_arrayify($group)) {
            $require_all = 1 if $valid{$field};
       }
       if ($require_all) {
            map { $required{$_} = 1 } _arrayify($group);
       }
    }

    my $dependency_re;

    foreach my $re (keys %{$profile->{dependencies_regexp}}) {
        my $sub = _create_sub_from_RE($re);

        $dependency_re->{$re} = {
            sub => $sub,
            value => $profile->{dependencies_regexp}->{$re},
        };
    }

    if ($dependency_re) {
        foreach my $k (keys %valid) {
            foreach my $re (keys %$dependency_re) {
                if ($dependency_re->{$re}->{sub}->($k)) {
                    my $deps = $dependency_re->{$re}->{value};

                    if (ref($deps) eq 'HASH') {
                        for my $key (keys %$deps) {
                            # Handle case of a key with a single value given as an arrayref
                            # There is probably a better, more general solution to this problem.
                            my $val_to_compare;

                            if ((ref $valid{$k} eq 'ARRAY') and (scalar @{ $valid{$k} } == 1)) {
                                $val_to_compare = $valid{$k}->[0];
                            } else {
                                $val_to_compare = $valid{$k}
                            }

                            if($val_to_compare eq $key){
                                for my $dep (_arrayify($deps->{$key})){
                                    $required{$dep} = 1;
                                }
                            }
                        }
                    } elsif (ref $deps eq "CODE") {
                        for my $val (_arrayify($valid{$k})) {
                            my $returned_deps = $deps->($self, $val, $k);

                            for my $dep (_arrayify($returned_deps)) {
                                $required{$dep} = 1;
                            }
                        }
                    } else {
                        for my $dep (_arrayify($deps)){
                            $required{$dep} = 1;
                        }
                    }
                }
            }
        }
    }

    # Check if the presence of some fields makes other fields optional.
    while (my ($field, $dependent_optional) = each %{$profile->{dependent_optionals}} ) {
        if (defined $valid{$field}) {
            if (ref $dependent_optional eq "CODE") {
                for my $value (_arrayify($valid{$field})) {
                    my $returned_optionals = $dependent_optional->($self, $value);



                    foreach my $optional (_arrayify($returned_optionals)) {
                        $optional{$optional} = 1;
                    }
                }
            } else {
                foreach my $optional (_arrayify($dependent_optional)){
                    $optional{$optional} = 1;
                }
            }
        }
    }

    # Find unknown
    @unknown =
      grep { not (exists $optional{$_} or exists $required{$_} or exists $require_some{$_} ) } keys %valid;
    # and remove them from the list
    for my $field ( @unknown ) {
        delete $valid{$field};
    }

    # Add defaults from defaults_regexp_map
    my %private_defaults;
    my @all_possible = keys %optional, keys %required, keys %require_some;
    while ( my ($re,$value) = each %{$profile->{defaults_regexp_map}} ) {
        # We only add defaults for known fields.
        for (@all_possible) {
            $private_defaults{$_} = $value if m/$re/;
        }
    }

    # Fill defaults
    my %combined_defaults = (
        %private_defaults,
        %{ $profile->{defaults} || {} }
    );
    while ( my ($field,$value) = each %combined_defaults ) {
        unless(exists $valid{$field}) {
            if (ref($value) && ref($value) eq "CODE") {
                $valid{$field} = $value->($self);
            } else {
                $valid{$field} = $value;
            }
        }
    }

    # Check for required fields
    for my $field ( keys %required ) {
        push @missings, $field unless exists $valid{$field};
    }

    # Check for the absence of require_some fields
    while ( my ( $field, $deps) = each %{$profile->{require_some}} ) {
        my $enough_required_fields = 0;
        my @deps = _arrayify($deps);
        # num fields to require is first element in array if looks like a digit, 1 otherwise.
        my $num_fields_to_require = ($deps[0] =~ m/^\d+$/) ? $deps[0] : 1;
        for my $dep (@deps){
            $enough_required_fields++ if exists $valid{$dep};
        }
        push @missings, $field unless ($enough_required_fields >= $num_fields_to_require);
    }

    # add in the constraints from the regexp maps
    # We don't want to modify the profile, so we use a new variable.
    $profile->{constraints} ||= {};
    my $private_constraints = {
        %{ $profile->{constraints} },
        _add_constraints_from_map($profile,'constraint',\%valid),
    };
    $profile->{constraint_methods} ||= {};
    my $private_constraint_methods = {
        %{ $profile->{constraint_methods} },
        _add_constraints_from_map($profile,'constraint_method',\%valid),
    };

    #Decide which fields to untaint
    my ($untaint_all, %untaint_hash);
    if (defined $profile->{untaint_regexp_map} or defined $profile->{untaint_constraint_fields} ) {
        # first deal with untaint_constraint_fields
        if (defined($profile->{untaint_constraint_fields})) {
            if (ref $profile->{untaint_constraint_fields} eq "ARRAY") {
                for my $field (@{$profile->{untaint_constraint_fields}}) {
                    $untaint_hash{$field} = 1;
                }
            }
            elsif ($valid{$profile->{untaint_constraint_fields}}) {
                $untaint_hash{$profile->{untaint_constraint_fields}} = 1;
            }
        }

        # now look at untaint_regexp_map
        if(defined($profile->{untaint_regexp_map})) {
            my @untaint_regexes;
            if(ref $profile->{untaint_regexp_map} eq "ARRAY") {
                @untaint_regexes = @{$profile->{untaint_regexp_map}};
            }
            else {
                push(@untaint_regexes, $profile->{untaint_regexp_map});
            }

            for my $regex (@untaint_regexes) {
                # look at both constraints and constraint_methods
                for my $field (keys %$private_constraints, keys %$private_constraint_methods) {
                    next if($untaint_hash{$field});
                    $untaint_hash{$field} = 1 if( $field =~ $regex );
                }
            }
        }
    }
    elsif ((defined($profile->{untaint_all_constraints}))
       && ($profile->{untaint_all_constraints} == 1)) {
       $untaint_all = 1;
    }

    $self->_check_constraints($private_constraints,\%valid,$untaint_all,\%untaint_hash);

    my $force_method_p = 1;
    $self->_check_constraints($private_constraint_methods,\%valid,$untaint_all,\%untaint_hash, $force_method_p);

    # add back in missing optional fields from the data hash if we need to
    for my $field ( keys %data ) {
        if ($profile->{missing_optional_valid} and $optional{$field} and (not exists $valid{$field})) {
            $valid{$field} = undef;
        }
    }

    # all invalid fields are removed from valid hash
    for my $field (keys %{ $self->{invalid} }) {
        delete $valid{$field};
    }

    my ($missing,$invalid);

    $self->{valid} ||= {};
    $self->{valid}  =  { %valid , %{$self->{valid}} };
    $self->{missing}    = { map { $_ => 1 } @missings };
    $self->{unknown}    = { map { $_ => $data{$_} } @unknown };

}

=pod

=head1  success();

This method returns true if there were no invalid or missing fields,
else it returns false.

As a shorthand, When the $results object is used in boolean context, it is overloaded
to use the value of success() instead. That allows creation of a syntax like this one used
in C<CGI::Application::Plugin::ValidateRM>:

 my $results = $self->check_rm('form_display','_form_profile') || return $self->dfv_error_page;

=cut

sub success {
    my $self = shift;
    return !($self->has_invalid || $self->has_missing);
}

=head1  valid( [[field] [, value]] );

In list context with no arguments, it returns the list of fields which
contain valid values:

 @all_valid_field_names = $r->valid;

In a scalar context with no arguments, it returns an hash reference which
contains the valid fields as keys and their input as values:

 $all_valid_href = $r->valid;

If called with one argument in scalar context, it returns the value of that
C<field> if it contains valid data, C<undef> otherwise. The value will be an
array ref if the field had multiple values:

 $value = $r->valid('field');

If called with one argument in list context, it returns the values of C<field>
as an array:

 @values = $r->valid('field');

If called with two arguments, it sets C<field> to C<value> and returns C<value>.
This form is useful to alter the results from within some constraints.
See the L<Data::FormValidator::Constraints> documentation.

 $new_value = $r->valid('field',$new_value);

=cut

sub valid {
    my $self = shift;
    my $key = shift;
    my $val = shift;
    $self->{valid}{$key} = $val if defined $val;

    if (defined $key) {
        return wantarray ? _arrayify($self->{valid}{$key}) : $self->{valid}{$key};
    }

    # If we got this far, there were no arguments passed.
    return wantarray ? keys %{ $self->{valid} } : $self->{valid};
}


=pod

=head1 has_missing()

This method returns true if the results contain missing fields.

=cut

sub has_missing {
    return scalar keys %{$_[0]{missing}};
}

=pod

=head1 missing( [field] )

In list context it returns the list of fields which are missing.
In a scalar context, it returns an array reference to the list of missing fields.

If called with an argument, it returns true if that C<field> is missing,
undef otherwise.

=cut

sub missing {
    return $_[0]{missing}{$_[1]} if (defined $_[1]);

    wantarray ? keys %{$_[0]{missing}} : [ keys %{$_[0]{missing}} ];
}


=pod

=head1 has_invalid()

This method returns true if the results contain fields with invalid
data.

=cut

sub has_invalid {
    return scalar keys %{$_[0]{invalid}};
}

=pod

=head1 invalid( [field] )

In list context, it returns the list of fields which contains invalid value.

In a scalar context, it returns an hash reference which contains the invalid
fields as keys, and references to arrays of failed constraints as values.

If called with an argument, it returns the reference to an array of failed
constraints for C<field>.

=cut

sub invalid {
    my $self = shift;
    my $field = shift;
    return $self->{invalid}{$field} if defined $field;

    wantarray ? keys %{$self->{invalid}} : $self->{invalid};
}

=pod

=head1 has_unknown()

This method returns true if the results contain unknown fields.

=cut

sub has_unknown {
    return scalar keys %{$_[0]{unknown}};

}

=pod

=head1 unknown( [field] )

In list context, it returns the list of fields which are unknown.
In a scalar context, it returns an hash reference which contains the unknown
fields and their values.

If called with an argument, it returns the value of that C<field> if it
is unknown, undef otherwise.

=cut

sub unknown {
    return (wantarray ? _arrayify($_[0]{unknown}{$_[1]}) : $_[0]{unknown}{$_[1]})
      if (defined $_[1]);

    wantarray ? keys %{$_[0]{unknown}} : $_[0]{unknown};
}


=pod

=head1 msgs([config parameters])

This method returns a hash reference to error messages. The exact format
is determined by parameters in the C<msgs> area of the validation profile,
described in the L<Data::FormValidator> documentation.

B<NOTE:> the C<msgs> parameter in the profile can take a code reference as a
value, allowing complete control of how messages are generated. If such a code
reference was provided there, it will be called here instead of the usual
processing, described below. It will receive as arguments the L<Data::FormValidator::Results>
object and a hash reference of control parameters.

The hashref passed in should contain the same options that you can define in
the validation profile. This allows you to separate the controls for message
display from the rest of the profile. While validation profiles may be
different for every form, you may wish to format messages the same way across
many projects.

Controls passed into the <msgs> method will be applied first, followed by ones
applied in the profile. This allows you to keep the controls you pass to
C<msgs> as "global" and override them in a specific profile if needed.

=cut

sub msgs {
  my $self = shift;
  my $msgs = $self->{profile}{msgs} || {};
  if ((ref $msgs eq 'CODE')) {
    return $msgs->($self,@_);
  } else {
    return $self->_generate_msgs(@_);
  }
}


sub _generate_msgs {
    my $self = shift;
    my $controls = shift || {};
    if (defined $controls and ref $controls ne 'HASH') {
        die "$0: parameter passed to msgs must be a hash ref";
    }


    # Allow msgs to be called more than one to accumulate error messages
    $self->{msgs} ||= {};
    $self->{profile}{msgs} ||= {};
    $self->{msgs} = { %{ $self->{msgs} }, %$controls };

    # Legacy typo support.
    for my $href ($self->{msgs}, $self->{profile}{msgs}) {
        if (
             (not defined $href->{invalid_separator})
             &&  (defined $href->{invalid_seperator})
         ) {
            $href->{invalid_separator} = $href->{invalid_seperator};
        }
    }

    my %profile = (
        prefix  => '',
        missing => 'Missing',
        invalid => 'Invalid',
        invalid_separator => ' ',

        format  => '<span style="color:red;font-weight:bold" class="dfv_errors">* %s</span>',
        %{ $self->{msgs} },
        %{ $self->{profile}{msgs} },
    );


    my %msgs = ();

    # Add invalid messages to hash
        #  look at all the constraints, look up their messages (or provide a default)
        #  add field + formatted constraint message to hash
    if ($self->has_invalid) {
        my $invalid = $self->invalid;
        for my $i ( keys %$invalid ) {
            $msgs{$i} = join $profile{invalid_separator}, map {
                _error_msg_fmt($profile{format},($profile{constraints}{$_} || $profile{invalid}))
                } @{ $invalid->{$i} };
        }
    }

    # Add missing messages, if any
    if ($self->has_missing) {
        my $missing = $self->missing;
        for my $m (@$missing) {
            $msgs{$m} = _error_msg_fmt($profile{format},$profile{missing});
        }
    }

    my $msgs_ref = prefix_hash($profile{prefix},\%msgs);

    if (! $self->success) {
        $msgs_ref->{ $profile{any_errors} } = 1 if defined $profile{any_errors};
    }

    return $msgs_ref;

}

=pod

=head1 meta()

In a few cases, a constraint may discover meta data that is useful
to access later. For example, when using L<Data::FormValidator::Constraints::Upload>, several bits of meta data are discovered about files in the process
of validating. These can include "bytes", "width", "height" and "extension".
The C<meta()> function is used by constraint methods to set this data. It's
also used to access this data. Here are some examples.

 # return all field names that have meta data
 my @fields = $results->meta();

 # To retrieve all meta data for a field:
 $meta_href = $results->meta('img');

 # Access a particular piece:
 $width = $results->meta('img')->{width};

Here's how to set some meta data. This is useful to know if you are
writing your own complex constraint.

    $self->meta('img', {
        width  => '50',
        height => '60',
    });

This function does not currently support multi-valued fields. If it
does in the future, the above syntax will still work.

=cut

sub meta {
    my $self  = shift;
    my $field = shift;
    my $data  = shift;

    # initialize if it's the first call
    $self->{__META} ||= {};

    if ($data) {
        (ref $data eq 'HASH') or die 'meta: data passed not a hash ref';
        $self->{__META}{$field} = $data;
    }


    # If we are passed a field, return data for that field
    if ($field) {
        return $self->{__META}{$field};
    }
    # Otherwise return a list of all fields that have meta data
    else {
        return keys %{ $self->{__META} };
    }
}

# These are documented in ::Constraints, in the section
# on writing your own routines. It was more intuitive
# for the user to look there.

sub get_input_data {
    my $self = shift;
    my %p = @_;
    if ($p{as_hashref}) {
        my %hash = $self->_get_input_as_hash( $self->{__INPUT_DATA} );
        return \%hash;
    }
    else {
        return $self->{__INPUT_DATA};
    }
}

sub get_filtered_data {
    my $self = shift;
    return $self->{__FILTERED_DATA};
}

sub get_current_constraint_field {
    my $self = shift;
    return $self->{__CURRENT_CONSTRAINT_FIELD};
}

sub get_current_constraint_value {
    my $self = shift;
    return $self->{__CURRENT_CONSTRAINT_VALUE};
}

sub get_current_constraint_name {
    my $self = shift;
    return $self->{__CURRENT_CONSTRAINT_NAME};
}

sub untainted_constraint_value {
    my $self = shift;
    my $match = shift;

    return undef unless defined $match;
    return $self->{__UNTAINT_THIS} ? $match : length $match;
}

sub set_current_constraint_name {
    my $self = shift;
    my $value = shift;
    $self->{__CURRENT_CONSTRAINT_NAME} = $value;
}
# same as above
sub name_this {
    my $self = shift;
    my $value = shift;
    $self->{__CURRENT_CONSTRAINT_NAME} = $value;
}

# INPUT: prefix_string, hash reference
# Copies the hash and prefixes all keys with prefix_string
# OUTPUT: hash reference
sub prefix_hash {
    my ($pre,$href) = @_;
    die "prefix_hash: need two arguments" unless (scalar @_ == 2);
    die "prefix_hash: second argument must be a hash ref" unless (ref $href eq 'HASH');
    my %out;
    for (keys %$href) {
        $out{$pre.$_} = $href->{$_};
    }
    return \%out;
}


# We tolerate two kinds of regular expression formats
# First, the preferred format made with "qr", matched using a leading paren
# Also, we accept the deprecated format given as strings: 'm/old/'
# (which must start with a slash or "m", not a paren)
sub _create_sub_from_RE {
    my $re = shift || return undef;
    my $untaint_this = shift;
    my $force_method_p = shift;

    my $sub;
    # If it's "qr" style
    if (substr($re,0,1) eq '(') {
        $sub = sub {
            # With methods, the value is the second argument
            my $val = $force_method_p ? $_[1] : $_[0];
            my ($match) = scalar ($val =~ $re);
            if ($untaint_this && defined $match) {
                # pass the value through a RE that matches anything to untaint it.
                my ($untainted) = ($&  =~ m/(.*)/s);
                return $untainted;
            }
            else {
                return $match;
            }
        };

    }
    else {
        local $SIG{__DIE__}  = \&confess;
        my $return_code = ($untaint_this) ? '; return ($& =~ m/(.*)/s)[0] if defined($`);' : '';
        # With methods, the value is the second argument
        if ($force_method_p) {
            $sub = eval 'sub { $_[1] =~ '.$re.$return_code. '}';
        }
        else {
            $sub = eval 'sub { $_[0] =~ '.$re.$return_code. '}';
        }
        die "Error compiling regular expression $re: $@" if $@;
    }
    return $sub;
}


sub _error_msg_fmt  {
    my ($fmt,$msg) = @_;
    $fmt ||=
            '<span style="color:red;font-weight:bold" class="dfv_errors">* %s</span>';
    ($fmt =~ m/%s/) || die 'format must contain %s';
    return sprintf $fmt, $msg;
}



# takes string or array ref as input
# returns array
sub _arrayify {
   # if the input is undefined, return an empty list
   my $val = shift;
   defined $val or return ();

   # if it's a reference, return an array unless it points to an empty array. -mls
   if ( ref $val eq 'ARRAY' ) {
       local $^W = 0; # turn off warnings about undef
       return grep(defined, @$val) ? @$val : ();
   }
   # if it's a string, return an array unless the string is missing or empty. -mls
   else {
       return (length $val) ? ($val) : ();
   }
}

# apply filter, modifying %valid by reference
# We don't bother trying to filter undefined fields.
# This prevents warnings from Perl.
sub _filter_apply {
    my ($valid,$field,$filter) = @_;
    die 'wrong number of arguments passed to _filter_apply' unless (scalar @_ == 3);
    if (ref $valid->{$field} eq 'ARRAY') {
        for (my $i = 0; $i < @{ $valid->{$field} }; $i++) {
            $valid->{$field}->[$i] = $filter->( $valid->{$field}->[$i] ) if defined $valid->{$field}->[$i];
        }
    }
    else {
        $valid->{$field} = $filter->( $valid->{$field} ) if defined $valid->{$field};
    }
}

# =head2 _constraint_hash_build()
#
# $constraint_href = $self->_constraint_hash_build($spec,$untaint_p)
#
# Input:
#   - $spec           # Any constraint valid in the profile
#   - $untaint        # bool for whether we could try to untaint the field.
#   - $force_method_p # bool for if it's  a method ?
#
# Output:
#  - $constraint_hashref
#    Keys are as follows:
#       constraint - the constraint as coderef
#       name       - the constraint name, if we know it.
#       params     - 'params', as given in the hashref style of specifying a constraint
#       is_method  - bool for whether this was a 'constraint' or 'constraint_method'

sub _constraint_hash_build {
    my ($self,$constraint_spec,$untaint_this,$force_method_p) = @_;
    die "_constraint_hash_build received wrong number of arguments" unless (scalar @_ == 4);

    my  $c = {
        name        => undef,
        constraint  => $constraint_spec,
    };
    $c->{name} = $constraint_spec if not ref $constraint_spec;

   # constraints can be passed in directly via hash
    if (ref $c->{constraint} eq 'HASH') {
            $c->{constraint} = ($constraint_spec->{constraint_method} || $constraint_spec->{constraint});
            $c->{name}       = $constraint_spec->{name};
            $c->{params}     = $constraint_spec->{params};
            $c->{is_method}  = 1 if $constraint_spec->{constraint_method};
    }

    # Check for regexp constraint
    if ((ref $c->{constraint} eq 'Regexp')
            or ( $c->{constraint} =~ m@^\s*(/.+/|m(.).+\2)[cgimosx]*\s*$@ )) {
        $c->{constraint} = _create_sub_from_RE($c->{constraint},$untaint_this,$force_method_p);
    }
    # check for code ref
    elsif (ref $c->{constraint} eq 'CODE') {
        # do nothing, it's already a code ref
    }
    else {
        # provide a default name for the constraint if we don't have one already
        if (not $c->{name} and not ref $c->{constraint}) {
            $c->{name} ||= $c->{constraint};
        }

        #If untaint is turned on call match_* sub directly.
        if ($untaint_this) {
            my $routine = 'match_'.$c->{constraint};
            my $match_sub = *{qualify_to_ref($routine)}{CODE};
            if ($match_sub) {
                $c->{constraint} = $match_sub;
            }
            # If the constraint name starts with RE_, try looking for it in the Regexp::Common package
            elsif ($c->{constraint} =~ m/^RE_/) {
                local $SIG{__DIE__}  = \&confess;
                $c->{is_method} = 1;
                $c->{constraint} = eval 'sub { &_create_regexp_common_constraint(@_)}'
                    || die "could not create Regexp::Common constraint: $@";
            } else {
                die "No untainting constraint found named $c->{constraint}";
            }
        }
        else {
            # try to use match_* first
            my $routine = 'match_'.$c->{constraint};
            if (defined *{qualify_to_ref($routine)}{CODE}) {
                local $SIG{__DIE__}  = \&confess;
                $c->{constraint} = eval 'sub { no strict qw/refs/; return defined &{"match_'.$c->{constraint}.'"}(@_)}';
            }
            # match_* doesn't exist; if it is supposed to be from the
            # validator_package(s) there may be only valid_* defined
            elsif (my $valid_sub = *{qualify_to_ref('valid_'.$c->{constraint})}{CODE}) {
                $c->{constraint} = $valid_sub;
            }
            # Load it from Regexp::Common
            elsif ($c->{constraint} =~ m/^RE_/) {
                local $SIG{__DIE__}  = \&confess;
                $c->{is_method} = 1;
                $c->{constraint} = eval 'sub { return defined &_create_regexp_common_constraint(@_)}' ||
                    die "could not create Regexp::Common constraint: $@";
            }
            else {
                die "No constraint found named '$c->{name}'";
            }
        }
    }

    # Save the current constraint name for later
    $self->{__CURRENT_CONSTRAINT_NAME} = $c->{name};

    return $c;

}

# =head2 _constraint_input_build()
#
#  @params = $self->constraint_input_build($c,$value,$data);
#
# Build in the input that passed into the constraint.
#
# =cut

sub _constraint_input_build {
    my ($self,$c,$value,$data) = @_;
    die "_constraint_input_build received wrong number of arguments" unless (scalar @_ == 4);

    my @params;
    if (defined $c->{params}) {
        for my $fname (_arrayify($c->{params})) {
            # If the value is passed by reference, we treat it literally
            push @params, (ref $fname) ? $fname : $data->{$fname}
        }
    }
    else {
        push @params, $value;
    }

    unshift @params, $self if $c->{is_method};
    return @params;
}

# =head2 _constraint_check_match()
#
# ($value,$failed_href) = $self->_constraint_check_match($c,\@params,$untaint_this);
#
# This is the routine that actually, finally, checks if a constraint passes or fails.
#
# Input:
#   - $c,            a constraint hash, as returned by C<_constraint_hash_build()>.
#   - \@params,      params to pass to the constraint, as prepared by C<_constraint_input_build()>.
#   - $untaint_this  bool if we untaint successful constraints.
#
# Output:
#  - $value          the value if successful
#  - $failed_href    a hashref with the following keys:
#       - failed     bool for failure or not
#       - name       name of the failed constraint, if known.

sub _constraint_check_match {
    my  ($self,$c,$params,$untaint_this) = @_;
    die "_constraint_check_match received wrong number of arguments" unless (scalar @_ == 4);

    # Store whether or not we want untainting in the object so that constraints
    # can do the right thing conditionally.
    $self->{__UNTAINT_THIS} = $untaint_this;

    my $match = $c->{constraint}->( @$params );

    # We need to make this distinction when untainting,
    # to allow untainting values that are defined but not true,
    # such as zero.
    my $success;
    if (defined $match) {
       $success =  ($untaint_this) ? length $match : $match;
    }

    my $failed = 1 unless $success;
    return (
        $match,
        {
            failed  => $failed,
            name    => $self->{__CURRENT_CONSTRAINT_NAME},
        },
    );
}

# Figure out whether the data is a hash reference of a param-capable object and return it has a hash
sub _get_input_as_hash {
    my ($self,$data) = @_;
    $self->{__INPUT_DATA} = $data;

    require Scalar::Util;

    # This checks whether we have an object that supports param
    if ( Scalar::Util::blessed($data) && $data->can('param') ) {
        my %return;
        for my $k ($data->param()){
            # we expect param to return an array if there are multiple values
            my @v;

            # CGI::Simple requires us to call 'upload()' to get upload data,
            # while CGI/Apache::Request return it on calling 'param()'.
            #
            # This seems quirky, but there isn't a way for us to easily check if
            # "this field contains a file upload" or not.
            if ($data->isa('CGI::Simple')) {
                @v = $data->upload($k) || $data->param($k);
            }
            else {
                # insecure
                @v = $data->multi_param($k);
            }

            # we expect param to return an array if there are multiple values
            $return{$k} = scalar(@v)>1 ? \@v : $v[0];
        }
        return %return;
    }
    # otherwise, it's already a hash reference
    elsif (ref $data eq 'HASH') {
        # be careful to actually copy array references
        my %copy = %$data;
        for (grep { ref $data->{$_} eq 'ARRAY' } keys %$data) {
            my @array_copy = @{ $data->{$_} };
            $copy{$_} = \@array_copy;
        }

        return %copy;
    }
    else {
        die "Data::FormValidator->validate() or check() called with invalid input data structure.";
    }
}

# A newer version of this logic now exists in Constraints.pm in the AUTOLOADing section
# This is is used to support the older param passing style. Eg:
#
# {
#   constraint => 'RE_foo_bar',
#   params => [ \'zoo' ]
#  }
#
# Still, it's possible, the two bits of logic could be refactored into one location if you cared
# to do that.

sub _create_regexp_common_constraint  {
    # this should work most of the time and is useful for preventing warnings

    # prevent name space clashes
    package Data::FormValidator::Constraints::RegexpCommon;

    require Regexp::Common;
    import  Regexp::Common 'RE_ALL';

    my $self = shift;
    my $re_name = $self->get_current_constraint_name;
    # deference all input
    my @params = map {$_ = $$_ if ref $_ }  @_;

    no strict "refs";
    my $re = &$re_name(-keep=>1,@params) || die 'no matching Regexp::Common routine found';
    return ($self->get_current_constraint_value =~ qr/^$re$/) ? $1 : undef;
}

# _add_constraints_from_map($profile,'constraint',\%valid);
# Returns:
#  - a hash to add to either 'constraints' or 'constraint_methods'

sub _add_constraints_from_map {
    die "_add_constraints_from_map: need 3 arguments" unless (scalar @_ == 3);
    my ($profile, $name, $valid) = @_;
    ($name =~ m/^constraint(_method)?$/) || die "unexpected input.";

    my $key_name = $name.'s';
    my $map_name = $name.'_regexp_map';

    my %result = ();
    for my $re (keys %{ $profile->{$map_name} }) {
        my $sub = _create_sub_from_RE($re);

        # find all the keys that match this RE and add a constraint for them
        for my $key (keys %$valid) {
            if ($sub->($key)) {
                    my $cur = $profile->{$key_name}{$key};
                    my $new = $profile->{$map_name}{$re};
                    # If they already have an arrayref of constraints, add to the list
                    if (ref $cur eq 'ARRAY') {
                        push @{ $result{$key} }, @$cur, $new;
                    }
                    # If they have a single constraint defined, create an array ref with with this plus the new one
                    elsif ($cur) {
                        $result{$key} = [$cur,$new];
                    }
                    # otherwise, a new constraint is created with this as the single constraint
                    else {
                        $result{$key} = $new;
                    }
                    warn "$map_name: $key matches\n" if $profile->{debug};
                }
            }
    }
    return %result;
}

sub _bool_overload_based_on_success {
    my $results = shift;
    return $results->success()
}

# =head2 _check_constraints()
#
# $self->_check_constraints(
#   $profile->{constraint_methods},
#   \%valid,
#   $untaint_all
#   \%untaint_hash
#   $force_method_p
#);
#
# Input:
#  - 'constraints' or 'constraint_methods' hashref
#  - hashref of valid data
#  - bool to try to untaint everything
#  - hashref of things to untaint
#  - bool if all constraints should be treated as methods.

sub _check_constraints {
    my ($self,
        $constraint_href,
        $valid,
        $untaint_all,
        $untaint_href,
        $force_method_p) = @_;

    while ( my ($field,$constraint_list) = each %$constraint_href ) {
        next unless exists $valid->{$field};

        my $is_constraint_list = 1 if (ref $constraint_list eq 'ARRAY');
        my $untaint_this = ($untaint_all || $untaint_href->{$field} || 0);

        my @invalid_list;
        # used to insure we only bother recording each failed constraint once
        my %constraints_seen;
        for my $constraint_spec (_arrayify($constraint_list)) {

            # set current constraint field for use by get_current_constraint_field
            $self->{__CURRENT_CONSTRAINT_FIELD} = $field;

            # Initialize the current constraint name to undef, to prevent it
            # from being accidently shared
            $self->{__CURRENT_CONSTRAINT_NAME} = undef;

            my $c = $self->_constraint_hash_build($constraint_spec,$untaint_this, $force_method_p);
            $c->{is_method} = 1 if $force_method_p;

            my $is_value_list = 1 if (ref $valid->{$field} eq 'ARRAY');
            my %param_data = ( $self->_get_input_as_hash($self->get_input_data) , %$valid );
            if ($is_value_list) {
                for (my $i = 0; $i < scalar @{ $valid->{$field}} ; $i++) {
                    if( !exists $constraints_seen{\$c} ) {

                        my @params = $self->_constraint_input_build($c,$valid->{$field}->[$i],\%param_data);

                        # set current constraint field for use by get_current_constraint_value
                        $self->{__CURRENT_CONSTRAINT_VALUE} = $valid->{$field}->[$i];

                        my ($match,$failed) = $self->_constraint_check_match($c,\@params,$untaint_this);
                        if ($failed->{failed}) {
                            push @invalid_list, $failed;
                            $constraints_seen{\$c} = 1;
                        }
                        else {
                            $valid->{$field}->[$i] = $match if $untaint_this;
                        }
                    }
                }
            }
            else {
                my @params = $self->_constraint_input_build($c,$valid->{$field},\%param_data);

                # set current constraint field for use by get_current_constraint_value
                $self->{__CURRENT_CONSTRAINT_VALUE} = $valid->{$field};

                my ($match,$failed) = $self->_constraint_check_match($c,\@params,$untaint_this);
                if ($failed->{failed}) {
                    push @invalid_list, $failed
                }
                else {
                    $valid->{$field} = $match if $untaint_this;
                }
            }
       }

        if (@invalid_list) {
            my @failed = map { $_->{name} } @invalid_list;
            push @{ $self->{invalid}{$field}  }, @failed;
            # the older interface to validate returned things differently
            push @{ $self->{validate_invalid} }, $is_constraint_list ? [$field, @failed] : $field;
        }
    }
}

1;

__END__

=pod

=head1 SEE ALSO

Data::FormValidator, Data::FormValidator::Filters,
Data::FormValidator::Constraints, Data::FormValidator::ConstraintsFactory

=head1 AUTHOR

Author: Francis J. Lacoste <francis.lacoste@iNsu.COM>
Maintainer: Mark Stosberg <mark@summersault.com>

=head1 COPYRIGHT

Copyright (c) 1999,2000 iNsu Innovations Inc.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms as perl itself.

=cut
