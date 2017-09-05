#
#    Constraints.pm - Standard constraints for use in Data::FormValidator.
#
#    This file is part of Data::FormValidator.
#
#    Author: Francis J. Lacoste
#    Maintainer: Mark Stosberg <mark@summersault.com>
#
#    Copyright (C) 1999,2000 iNsu Innovations Inc.
#    Copyright (C) 2001 Francis J. Lacoste
#    Parts Copyright 1996-1999 by Michael J. Heins
#    Parts Copyright 1996-1999 by Bruce Albrecht
#
#    Parts of this module are based on work by
#    Bruce Albrecht, contributed to MiniVend.
#
#    Parts also based on work by Michael J. Heins
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms same terms as perl itself.
#
package Data::FormValidator::Constraints;
use base 'Exporter';
use strict;
our $AUTOLOAD;

our $VERSION = 4.88;

BEGIN {
    use Carp;
    my @closures = (qw/
        american_phone
        cc_exp
        cc_number
        cc_type
        email
        ip_address
        phone
        postcode
        province
        state
        state_or_province
        zip
        zip_or_postcode/);

    # This be optimized with some of the voodoo that CGI.pm
    # uses to AUTOLOAD dynamic functions.
    for my $func (@closures) {
        # cc_number is defined statically
        unless ($func eq 'cc_number') {
            # Notice we have to escape some characters
            # in the subroutine, which is really a string here.

            local $SIG{__DIE__} = \&confess;
            my $code = qq!
            sub $func  {
                return sub {
                    my \$dfv = shift;
                    use Scalar::Util ();
                    die "first arg to $func was not an object. Must be called as a constraint_method."
                    unless ( Scalar::Util::blessed(\$dfv) && \$dfv->can('name_this') );

                    \$dfv->name_this('$func') unless \$dfv->get_current_constraint_name();
                    no strict 'refs';
                    return &{"match_$func"}(\@_);
                }
            }
            !;

            eval "package Data::FormValidator::Constraints; $code";
            die "couldn't create $func: $@" if $@;
        }
    }

    my @FVs = (qw/
        FV_length_between
        FV_min_length
        FV_max_length
        FV_eq_with
        FV_num_values
        FV_num_values_between
    /);

    our @EXPORT_OK = (
        @closures,
        @FVs,
        qw(
        valid_american_phone
        valid_cc_exp
        valid_cc_number
        valid_cc_type
        valid_email
        valid_ip_address
        valid_phone
        valid_postcode
        valid_province
        valid_state
        valid_state_or_province
        valid_zip
        valid_zip_or_postcode
        match_american_phone
        match_cc_exp
        match_cc_number
        match_cc_type
        match_email
        match_ip_address
        match_phone
        match_postcode
        match_province
        match_state
        match_state_or_province
        match_zip
        match_zip_or_postcode)
    );

    our %EXPORT_TAGS = (
        # regexp common is correctly empty here, because we handle the case on the fly with the import function below.
        regexp_common => [],
        closures => [ @closures, @FVs ],
        validators => [qw/
            valid_american_phone
            valid_cc_exp
            valid_cc_number
            valid_cc_type
            valid_email
            valid_ip_address
            valid_phone
            valid_postcode
            valid_province
            valid_state
            valid_state_or_province
            valid_zip
            valid_zip_or_postcode
        /],
        matchers => [qw/
            match_american_phone
            match_cc_exp
            match_cc_number
            match_cc_type
            match_email
            match_ip_address
            match_phone
            match_postcode
            match_province
            match_state
            match_state_or_province
            match_zip
            match_zip_or_postcode
        /],
    );

    sub import {
        # This is Regexp::Common support.
        # Here we are handling cases that look like this:
        #
        # my_field => FV_foo_bar(-zoo=>'queue'),
        if (grep { m/^:regexp_common$/ } @_) {
            require Regexp::Common;
            import  Regexp::Common 'RE_ALL';

            for my $sub (grep { m/^RE_/}  keys %Data::FormValidator::Constraints:: ) {
                no strict 'refs';
                my $new_name = $sub;
                $new_name =~ s/^RE_/FV_/;
                *{caller() . "::$new_name"} = sub {
                    my @params =  @_;
                    return sub {
                        my $dfv = shift;
                        $dfv->name_this($new_name) unless $dfv->get_current_constraint_name();

                        no strict "refs";
                        my $re = &$sub(-keep=>1,@params);
                        my ($match) = ($dfv->get_current_constraint_value =~ qr/^($re)$/);
                        return $dfv->untainted_constraint_value($match);
                    }
                }
            }
        }

        Data::FormValidator::Constraints->export_to_level(1,@_);
    }

}


# sub DESTROY {}

=pod

=head1 NAME

Data::FormValidator::Constraints - Basic sets of constraints on input profile.

=head1 SYNOPSIS

 use Data::FormValidator::Constraints qw(:closures);

In an Data::FormValidator profile:

    constraint_methods => {
        email   => email(),
        phone   => american_phone(),
        first_names =>  {
           constraint_method => FV_max_length(3),
           name => 'my_custom_name',
       },
    },
    msgs => {
       constraints => {
            my_custom_name => 'My message',
       },
    },



=head1 DESCRIPTION

These are the builtin constraints that can be specified by name in the input
profiles.

Be sure to check out the SEE ALSO section for even more pre-packaged
constraints you can use.

=cut

sub AUTOLOAD {
    my $name = $AUTOLOAD;

    no strict qw/refs/;

    $name =~ m/^(.*::)(valid_|RE_)(.*)/;

    my ($pkg,$prefix,$sub) = ($1,$2,$3);

    #warn "hello!  my ($pkg,$prefix,$sub) = ($1,$2,$3);";

    # Since all the valid_* routines are essentially identical we're
    # going to generate them dynamically from match_ routines with the same names.
    if ((defined $prefix) and ($prefix eq 'valid_')) {
        return defined &{$pkg.'match_' . $sub}(@_);
    }
}

=head2 FV_length_between(1,23)

=head2 FV_max_length(23)

=head2 FV_min_length(1)

  use Data::FormValidator::Constraints qw(
    FV_length_between
    FV_min_length
    FV_max_length
  );

  constraint_methods => {

    # specify a min and max, inclusive
    last_name        => FV_length_between(1,23),

  }

Specify a length constraint for a field.

These constraints have a different naming convention because they are higher-order
functions. They take input and return a code reference to a standard constraint
method. A constraint name of C<length_between>, C<min_length>, or C<max_length> will be set,
corresponding to the function name you choose.

The checks are all inclusive, so a max length of '100' will allow the length 100.

Length is measured in perl characters as opposed to bytes or anything else.

This constraint I<will> untaint your data if you have untainting turned on. However,
a length check alone may not be enough to insure the safety of the data you are receiving.
Using additional constraints to check the data is encouraged.

=cut

sub FV_length_between {
    my ($min,$max) = @_;
    if (not (defined $min and defined $max)) {
            croak "min and max are required";
    }
    return sub {
        my ($dfv,$value) = @_;
        $dfv->name_this('length_between') unless $dfv->get_current_constraint_name();
        return undef if ( ( length($value) > $max ) || ( length($value) < $min) );
        # Use a regexp to untaint
        $value=~/(.*)/s;
        return $dfv->untainted_constraint_value($1);
    }
}

sub FV_max_length {
    my ($max) = @_;
    croak "max is required" unless defined $max;
    return sub {
        my ($dfv,$value) = @_;
        $dfv->name_this('max_length') unless $dfv->get_current_constraint_name();
        return undef if ( length($value) > $max );
        # Use a regexp to untaint
        $value=~/(.*)/s;
        return $dfv->untainted_constraint_value($1);
    }
}

sub FV_min_length {
    my ($min) = @_;
    croak "min is required" unless defined $min;
    return sub {
        my ($dfv,$value) = @_;
        $dfv->name_this('min_length') unless $dfv->get_current_constraint_name();
        return undef if ( length($value) < $min );
        # Use a regexp to untaint
        $value=~/(.*)/s;
        return $dfv->untainted_constraint_value($1);
    }
}

=head2 FV_eq_with

  use Data::FormValidator::Constraints qw( FV_eq_with );

  constraint_methods => {
    password  => FV_eq_with('password_confirm'),
  }

Compares the current field to another field.
A constraint name of C<eq_with> will be set.

=cut

sub FV_eq_with {
    my ($other_field) = @_;
        return sub {
            my $dfv = shift;
        $dfv->name_this('eq_with') unless $dfv->get_current_constraint_name();

        my $curr_val  = $dfv->get_current_constraint_value;

        my $data = $dfv->get_filtered_data;
        # Sometimes the data comes through both ways...
        my $other_val = (ref $data->{$other_field}) ? $data->{$other_field}[0] : $data->{$other_field};

        return ($curr_val eq $other_val);
    }

}

=head2 FV_num_values

    use Data::FormValidator::Constraints qw ( FV_num_values );

    constraint_methods => {
        attachments => FV_num_values(4),
    }

Checks the number of values in the array named by this param.
Note that this is useful for making sure that only one value was passed for a
given param (by supplying a size argument of 1).
A constraint name of C<num_values> will be set.

=cut

sub FV_num_values {
    my $size = shift || croak 'size argument is required';
    return sub {
        my $dfv = shift;
        $dfv->name_this('num_values');
        my $param = $dfv->get_current_constraint_field();
        my $value = $dfv->get_filtered_data()->{$param};

        # If there's an arrayref of values provided, test the number of them found
        # against the number of them of required
        if (defined $value and ref $value eq 'ARRAY') {
            my $num_values_found = scalar @$value;
            return ($num_values_found == $size);
        }
        # If a size of 1 was requested, there was not an arrayref of values,
        # there must be exactly one value.
        elsif ($size == 1) {
            return 1;
        }
        # Any other case is failure.
        else {
            return 0;
        }
    }
}

=head2 FV_num_values_between

    use Data::FormValidator::Constraints qw ( FV_num_values_between );

    constraint_methods => {
        attachments => FV_num_values_between(1,4),
    }

Checks that the number of values in the array named by this param is between
the supplied bounds (inclusively).
A constraint name of C<num_values_between> will be set.

=cut

sub FV_num_values_between {
    my ($min, $max) = @_;
    croak 'min and max arguments are required' unless $min && $max;
    return sub {
        my $dfv = shift;
        $dfv->name_this('num_values_between');
        my $param = $dfv->get_current_constraint_field();
        my $value = $dfv->get_filtered_data()->{$param};

    if (ref($value) eq 'ARRAY') {
          my $num_values = scalar @$value;

          return(
            (
              $num_values >= $min
              && $num_values <= $max
            ) ? 1 : 0
          );
    } else {
      if ($min <= 1 && $max >= 1) {
        # Single value is allowed
        return 1;
      } else {
        return 0;
      }
    }
    }
}

=head2 email

Checks if the email LOOKS LIKE an email address. This should be sufficient
99% of the time.

Look elsewhere if you want something super fancy that matches every possible variation
that is valid in the RFC, or runs out and checks some MX records.

=cut

# Many of the following validators are taken from
# MiniVend 3.14. (http://www.minivend.com)
# Copyright 1996-1999 by Michael J. Heins <mike@heins.net>

sub match_email {
    my $in_email = shift;

    require Email::Valid;
    my $valid_email;

    # The extra check that the result matches the input prevents
    # an address like this from being considered valid: Joe Smith <joe@smith.com>
    if (    ($valid_email = Email::Valid->address($in_email) )
        and ($valid_email eq $in_email)) {
        return $valid_email;
    }
    else {
        return undef;
    }
}

my $state = <<EOF;
AL AK AZ AR CA CO CT DE FL GA HI ID IL IN IA KS KY LA ME MD
MA MI MN MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA PR RI
SC SD TN TX UT VT VA WA WV WI WY DC AP FP FPO APO GU VI
EOF

my $province = <<EOF;
AB BC MB NB NF NL NS NT NU ON PE QC SK YT YK
EOF

=head2 state_or_province

This one checks if the input correspond to an american state or a canadian
province.

=cut

sub match_state_or_province {
    my $match;
    if ($match = match_state(@_)) {
        return $match;
    }
    else {
        return match_province(@_);
    }
}

=head2 state

This one checks if the input is a valid two letter abbreviation of an
American state.

=cut

sub match_state {
    my $val = shift;
    if ($state =~ /\b($val)\b/i) {
    return $1;
    }
    else { return undef; }
}

=head2 province

This checks if the input is a two letter Canadian province
abbreviation.

=cut

sub match_province {
    my $val = shift;
    if ($province =~ /\b($val)\b/i) {
    return $1;
    }
    else { return undef; }
}

=head2 zip_or_postcode

This constraints checks if the input is an American zipcode or a
Canadian postal code.

=cut

sub match_zip_or_postcode {
    my $match;
    if ($match = match_zip(@_)) {
        return $match;
    }
    else {
        return match_postcode(@_)
    };
}
=pod

=head2 postcode

This constraints checks if the input is a valid Canadian postal code.

=cut

sub match_postcode {
    my $val = shift;
    #$val =~ s/[_\W]+//g;
    if ($val =~ /^([ABCEGHJKLMNPRSTVXYabceghjklmnprstvxy][_\W]*\d[_\W]*[A-Za-z][_\W]*[- ]?[_\W]*\d[_\W]*[A-Za-z][_\W]*\d[_\W]*)$/) {
    return $1;
    }
    else { return undef; }
}

=head2 zip

This input validator checks if the input is a valid american zipcode :
5 digits followed by an optional mailbox number.

=cut

sub match_zip {
    my $val = shift;
    if ($val =~ /^(\s*\d{5}(?:[-]\d{4})?\s*)$/) {
    return $1;
    }
    else { return undef; }
}

=head2 phone

This one checks if the input looks like a phone number, (if it
contains at least 6 digits.)

=cut

sub match_phone {
    my $val = shift;

    if ($val =~ /^((?:\D*\d\D*){6,})$/) {
    return $1;
    }
    else { return undef; }
}

=head2 american_phone

This constraints checks if the number is a possible North American style
of phone number : (XXX) XXX-XXXX. It has to contains 7 or more digits.

=cut

sub match_american_phone {
    my $val = shift;

    if ($val =~ /^((?:\D*\d\D*){7,})$/) {
    return $1;
    }
    else { return undef; }
}


=head2 cc_number

This constraint references the value of a credit card type field.

 constraint_methods => {
    cc_no      => cc_number({fields => ['cc_type']}),
  }


The number is checked only for plausibility, it checks if the number could
be valid for a type of card by checking the checksum and looking at the number
of digits and the number of digits of the number.

This functions is only good at catching typos. IT DOESN'T
CHECK IF THERE IS AN ACCOUNT ASSOCIATED WITH THE NUMBER.

=cut

# This one is taken from the contributed program to
# MiniVend by Bruce Albrecht

# XXX raise exception on bad/missing params?
sub cc_number {
    my $attrs = shift;
    return undef unless $attrs && ref($attrs) eq 'HASH'
      && exists $attrs->{fields} && ref($attrs->{fields}) eq 'ARRAY';

    my ($cc_type_field) = @{ $attrs->{fields} };
    return undef unless $cc_type_field;

    return sub {
        my $dfv = shift;
        my $data = $dfv->get_filtered_data;

        return match_cc_number(
            $dfv->get_current_constraint_value,
            $data->{$cc_type_field}
        );
    };
}

sub match_cc_number {
    my ( $the_card, $card_type ) = @_;
    my $orig_card = $the_card; #used for return match at bottom
    my ($index, $digit, $product);
    my $multiplier = 2;        # multiplier is either 1 or 2
    my $the_sum = 0;

    return undef if length($the_card) == 0;

    # check card type
    return undef unless $card_type =~ /^[admv]/i;

    return undef if ($card_type =~ /^v/i && substr($the_card, 0, 1) ne "4") ||
      ($card_type =~ /^m/i && substr($the_card, 0, 1) ne "5" &&
       substr($the_card, 0, 1) ne "2") ||
      ($card_type =~ /^d/i && substr($the_card, 0, 4) ne "6011") ||
      ($card_type =~ /^a/i && substr($the_card, 0, 2) ne "34" &&
       substr($the_card, 0, 2) ne "37");

    # check for valid number of digits.
    $the_card =~ s/\s//g;    # strip out spaces
    return undef if $the_card !~ /^\d+$/;

    $digit = substr($the_card, 0, 1);
    $index = length($the_card)-1;
    return undef if ($digit == 3 && $index != 14) ||
        ($digit == 4 && $index != 12 && $index != 15) ||
            ($digit == 5 && $index != 15) ||
                ($digit == 6 && $index != 13 && $index != 15);


    # calculate checksum.
    for ($index--; $index >= 0; $index --)
    {
        $digit=substr($the_card, $index, 1);
        $product = $multiplier * $digit;
        $the_sum += $product > 9 ? $product - 9 : $product;
        $multiplier = 3 - $multiplier;
    }
    $the_sum %= 10;
    $the_sum = 10 - $the_sum if $the_sum;

    # return whether checksum matched.
    if ($the_sum == substr($the_card, -1)) {
    if ($orig_card =~ /^([\d\s]*)$/) { return $1; }
    else { return undef; }
    }
    else {
    return undef;
    }
}

=head2 cc_exp

This one checks if the input is in the format MM/YY or MM/YYYY and if
the MM part is a valid month (1-12) and if that date is not in the past.

=cut

sub match_cc_exp {
    my $val = shift;
    my ($matched_month, $matched_year);

    my ($month, $year) = split('/', $val);
    return undef if $month !~ /^(\d+)$/;
    $matched_month = $1;

    return undef if  $year !~ /^(\d+)$/;
    $matched_year = $1;

    return undef if $month <1 || $month > 12;
    $year += ($year < 70) ? 2000 : 1900 if $year < 1900;
    my @now=localtime();
    $now[5] += 1900;
    return undef if ($year < $now[5]) || ($year == $now[5] && $month <= $now[4]);

    return "$matched_month/$matched_year";
}

=head2 cc_type

This one checks if the input field starts by M(asterCard), V(isa),
A(merican express) or D(iscovery).

=cut

sub match_cc_type {
    my $val = shift;
    if ($val =~ /^([MVAD].*)$/i) { return $1; }
    else { return undef; }
}

=head2 ip_address

This checks if the input is formatted like a dotted decimal IP address (v4).
For other kinds of IP address method, See L<Regexp::Common::net> which provides
several more options. L<REGEXP::COMMON SUPPORT> explains how we easily integrate
with Regexp::Common.

=cut

# contributed by Juan Jose Natera Abreu <jnatera@net-uno.net>

sub match_ip_address {
   my $val = shift;
   if ($val =~ m/^((\d+)\.(\d+)\.(\d+)\.(\d+))$/) {
       if
       (($2 >= 0 && $2 <= 255) && ($3 >= 0 && $3 <= 255) && ($4 >= 0 && $4 <= 255) && ($5 >= 0 && $5 <= 255)) {
           return $1;
       }
       else { return undef; }
   }
   else { return undef; }
}


1;

__END__

=head1 RENAMING BUILT-IN CONSTAINTS

If you'd like, you can rename any of the built-in constraints. Just define the constraint_method and name
in a hashref, like this:

        constraint_methods => {
            first_names =>  {
                constraint_method => FV_max_length(3),
                name => 'custom_length',
            }
        },


=head1 REGEXP::COMMON SUPPORT

Data::FormValidator also includes built-in support for using any of regular expressions
in L<Regexp::Common> as named constraints. Simply use the name of regular expression you want.
This works whether you want to untaint the data or not. For example:

 use Data::FormValidator::Constraints qw(:regexp_common);

 constraint_methods => {
    my_ip_address => FV_net_IPv4(),

    # An example with parameters
    other_ip      => FV_net_IPv4(-sep=>' '),
 }

Notice that the routines are named with the prefix "FV_" instead of "RE_" now.
This is simply a visual cue that these are slightly modified versions. We've made
a wrapper for each Regexp::Common routine so that it can be used as a named constraint
like this.

Be sure to check out the L<Regexp::Common> syntax for how its syntax works. It
will make more sense to add future regular expressions to Regexp::Common rather
than to Data::FormValidator.

=head1 PROCEDURAL INTERFACE

You may also call these functions directly through the procedural interface by
either importing them directly or importing the whole I<:validators> group.
This is useful if you want to use the built-in validators out of the usual
profile specification interface.


For example, if you want to access the I<email> validator
directly, you could either do:

    use Data::FormValidator::Constraints (qw/valid_email/);
    or
    use Data::FormValidator::Constraints (:validators);

    if (valid_email($email)) {
      # do something with the email address
    }

Notice that when you call validators directly, you'll need to prefix the
validator name with "valid_"

Each validator also has a version that returns the untainted value if
the validation succeeded. You may call these functions directly
through the procedural interface by either importing them directly or
importing the I<:matchers> group. For example if you want to untaint a
value with the I<email> validator directly you may:

    if ($email = match_email($email)) {
        system("echo $email");
    }
    else {
        die "Unable to validate email";
    }

Notice that when you call validators directly and want them to return an
untainted value, you'll need to prefix the validator name with "match_"

=pod

=head1 WRITING YOUR OWN CONSTRAINT ROUTINES

=head2 New School Constraints Overview

This is the current recommended way to write constraints. See also L<Old School Constraints>.

The most flexible way to create constraints to use closures-- a normal seeming
outer subroutine which returns a customized DFV method subroutine as a result.
It's easy to do. These "constraint methods" can be named whatever you like, and
imported normally into the name space where the profile is located.

Let's look at an example.

  # Near your profile
  # Of course, you don't have to export/import if your constraints are in the same
  # package as the profile.
  use My::Constraints 'coolness';

  # In your profile
  constraint_methods => {
    email            => email(),
    prospective_date => coolness( 40, 60,
        {fields => [qw/personality smarts good_looks/]}
    ),
  }

Let's look at how this complex C<coolness> constraint method works. The
interface asks for users to define minimum and maximum coolness values, as
well as declaring three data field names that we should peek into to look
their values.

Here's what the code might look like:

  sub coolness {
    my ($min_cool,$max_cool, $attrs) = @_;
    my ($personality,$smarts,$looks) = @{ $attrs->{fields} } if $attrs->{fields};
    return sub {
        my $dfv = shift;

        # Name it to refer to in the 'msgs' system.
        $dfv->name_this('coolness');

        # value of 'prospective_date' parameter
        my $val = $dfv->get_current_constraint_value();

        # get other data to refer to
        my $data = $dfv->get_filtered_data;

        my $has_all_three = ($data->{$personality} && $data->{$smarts} && $data->{$looks});
        return ( ($val >= $min_cool) && ($val <= $max_cool) && $has_all_three );
    }
  }

=head2 Old School Constraints

Here is documentation on how old school constraints are created. These are
supported, but the new school style documented above is recommended.

See also the C<validator_packages> option in the input profile, for loading
sets of old school constraints from other packages.

Old school constraint routines are named two ways. Some are named with the
prefix C<match_> while others start with C<valid_>. The difference is that the
C<match_> routines are built to untaint the data and return a safe version of
it if it validates, while C<valid_> routines simply return a true value if the
validation succeeds and false otherwise.

It is preferable to write C<match_> routines that untaint data for the extra
security benefits. Plus, Data::FormValidator will AUTOLOAD a C<valid_> version
if anyone tries to use it, so you only need to write one routine to cover both
cases.

Usually constraint routines only need one input, the value being specified.
However, sometimes more than one value is needed.

B<Example>:

        image_field  => {
            constraint_method  => 'max_image_dimensions',
            params => [\100,\200],
        },

Using that syntax, the first parameter that will be passed to the routine is
the Data::FormValidator object. The remaining parameters will come from the
C<params> array. Strings will be replaced by the values of fields with the same names,
and references will be passed directly.

In addition to C<constraint_method>, there is also an even older technique using
the name C<constraint> instead. Routines that are designed to work with
C<constraint> I<don't> have access to Data::FormValidator object, which
means users need to pass in the name of the field being validated. Besides
adding unnecessary syntax to the user interface, it won't work in conjunction
with C<constraint_regexp_map>.

=head2 Methods available for use inside of constraints

A few useful methods to use on the Data::FormValidator::Results object are
available to you to use inside of your routine.

=head3 get_input_data()

Returns the raw input data. This may be a CGI object if that's what
was used in the constraint routine.

B<Examples:>

 # Raw and uncensored
 my $data = $self->get_input_data;

 # tamed to be a hashref, if it wasn't already
 my $data = $self->get_input_data( as_hashref => 1 );

=head3 get_filtered_data()

 my $data = $self->get_filtered_data;

Returns the valid filtered data as a hashref, regardless of whether
it started out as a CGI.pm compatible object. Multiple values are
expressed as array references.

=head3 get_current_constraint_field()

Returns the name of the current field being tested in the constraint.

B<Example>:

 my $field = $self->get_current_constraint_field;

This reduces the number of parameters that need to be passed into the routine
and allows multi-valued constraints to be used with C<constraint_regexp_map>.

For complete examples of multi-valued constraints, see L<Data::FormValidator::Constraints::Upload>

=head3 get_current_constraint_value()

Returns the name of the current value being tested in the constraint.

B<Example>:

 my $value = $self->get_current_constraint_value;

This reduces the number of parameters that need to be passed into the routine
and allows multi-valued constraints to be used with C<constraint_regexp_map>.

=head3 get_current_constraint_name()

Returns the name of the current constraint being applied

B<Example>:

 my $value = $self->get_current_constraint_name;

This is useful for building a constraint on the fly based on its name.
It's used internally as part of the interface to the L<Regexp::Commmon>
regular expressions.

=head3 untainted_constraint_value()

   return $dfv->untainted_constraint_value($match);

If you have written a constraint which untaints, use this method to return the
untainted result. It will prepare the right result whether the user has requested
untainting or not.

=head3 name_this()

=head3 set_current_constraint_name()

Sets the name of the current constraint being applied.

B<Example>:

 sub my_constraint {
    my @outer_params = @_;
    return sub {
        my $dfv = shift;
        $dfv->set_current_constraint_name('my_constraint');
        my @params = @outer_params;
        # do something constraining here...
    }
 }

By returning a closure which uses this method,  you can build an advanced named
constraint in your profile, before you actually have access to the DFV object
that will be used later. See Data::FormValidator::Constraints::Upload for an
example.

C<name_this> is a provided as a shorter synonym.

The C<meta()> method may also be useful to communicate meta data that
may have been found. See L<Data::FormValidator::Results> for documentation
of that method.

=head1  BACKWARDS COMPATIBILITY

Prior to Data::FormValidator 4.00, constraints were specified a bit differently.
This older style is still supported.

It was not necessary to explicitly load some constraints into your name space,
and the names were given as strings, like this:

    constraints  => {
        email         => 'email',
        fax           => 'american_phone',
        phone         => 'american_phone',
        state         => 'state',
        my_ip_address => 'RE_net_IPv4',
        other_ip => {
            constraint => 'RE_net_IPv4',
            params => [ \'-sep'=> \' ' ],
        },
        my_cc_no      => {
            constraint => 'cc_number',
            params => [qw/cc_no cc_type/],
        }
    },


=head1 SEE ALSO

=head2 Constraints available in other modules

=over

=item L<Data::FormValidator::Constraints::Upload> - validate the bytes, format and dimensions of file uploads

=item L<Data::FormValidator::Constraints::DateTime> - A newer DateTime constraint module. May save you a step of transforming the date into a more useful format after it's validated.

=item L<Data::FormValidator::Constraints::Dates> - the original DFV date constraint module. Try the newer one first!

=item L<Data::FormValidator::Constraints::Japanese> - Japan-specific constraints

=item L<Data::FormValidator::Constraints::MethodsFactory> - a useful collection of tools generate more complex constraints. Recommended!


=back

=head2 Related modules in this package

=over

=item L<Data::FormValidator::Filters> - transform data before constraints are applied

=item L<Data::FormValidator::ConstraintsFactory> - This is a historical collection of constraints that suffer from cumbersome names. They are worth reviewing though-- C<make_and_constraint> will allow one to validate against a list of constraints and shortcircuit if the first one fails. That's perfect if the second constraint depends on the first one having passed.
 For a modern version of this toolkit, see L<Data::FormValidator::Constraints::MethodsFactory>.

=item L<Data::FormValidator>

=back

=head1 CREDITS

Some of those input validation functions have been taken from MiniVend
by Michael J. Heins

The credit card checksum validation was taken from contribution by
Bruce Albrecht to the MiniVend program.

=head1 AUTHORS

    Francis J. Lacoste
    Michael J. Heins
    Bruce Albrecht
    Mark Stosberg

=head1 COPYRIGHT

Copyright (c) 1999 iNsu Innovations Inc.
All rights reserved.

Parts Copyright 1996-1999 by Michael J. Heins
Parts Copyright 1996-1999 by Bruce Albrecht
Parts Copyright 2005-2009 by Mark Stosberg

This program is free software; you can redistribute it and/or modify
it under the terms as perl itself.

=cut
