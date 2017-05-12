# -*- Mode: perl -*-
#
# $Id: Field.pm,v 0.1 2001/04/22 17:57:03 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Field.pm,v $
# Revision 0.1  2001/04/22 17:57:03  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use strict;

package CGI::MxScreen::Form::Field;

use CGI;
use Carp::Datum;
use Log::Agent;
use Getargs::Long qw(ignorecase);

# index of the array
BEGIN {
    sub NAME ()             {0}
    sub MANDATORY ()        {1}
    sub VERIFY_ARG ()       {2}		# VERIFY conflict with Carp::Datum's
    sub STORAGE ()          {3}
    sub PATCH ()            {4}
    sub NOSTORAGE ()        {5}

    sub CGI_ARGS ()         {6}
    sub VALUE ()            {7}
    sub ERROR ()            {8}
}


#
# ->make
#
# Arguments: (that are considered, others values are kept aside) 
#   -name       => string
#   -mandatory  => boolean
#   -verify     => 'routine' or ['routine', args ...]
#   -patch      => 'routine' or ['routine', args ...]
#   -storage    => 'symbol' or [objref, 'routine', arg] or [ref, 'symbol']
#   -nostorage  => boolean
#   
sub make {
    DFEATURE my $f_;
    my $self = bless [], shift;
	my ($name, $default) = cxgetargs(@_, { -strict => 0, -extra => 0 },
		-name		=> 's',
		-default	=> [],
	);

	# Initial value at creation time
	my $param = CGI::param($name);
    $self->[VALUE] = defined($param) ? $param : $default;
    $self->[ERROR] = '';

    $self->update(@_);
    return DVAL $self;
}


#
# ->update
#
#
sub update {
    DFEATURE my $f_;
    my $self = shift;

    ($self->[NAME],
     $self->[MANDATORY],
     $self->[VERIFY_ARG],
     $self->[STORAGE],
     $self->[PATCH],
     $self->[NOSTORAGE],
     @{$self->[CGI_ARGS]}) =
		cxgetargs(@_, {-strict => 0},
			-name        => 's',
			-mandatory   => ['i'],
			-verify      => [],
			-storage     => [],
			-patch       => [],
			-nostorage   => ['i']
		);

    unshift @{$self->[CGI_ARGS]}, ('-name', $self->name);
    
    return DVOID;
}


# Temporary method
#
# To Be Removed
# when storable would be able to select what is stored with
# Storable::Hook
sub cleanup {
    DFEATURE my $f_;
    my $self = shift;
    
    $#{$self} = NOSTORAGE;

    return DVOID;
}

#########################################################################
# Class Feature: usable from the external world                         # 
#########################################################################
sub name           { $_[0]->[NAME] }
sub mandatory      { $_[0]->[MANDATORY] }
sub verify         { $_[0]->[VERIFY_ARG] }
sub storage        { $_[0]->[STORAGE] }
sub patch          { $_[0]->[PATCH] }
sub nostorage      { $_[0]->[NOSTORAGE] }

sub value          { $_[0]->[VALUE] }
sub error          { $_[0]->[ERROR] }

sub set_value          { $_[0]->[VALUE] = $_[1] }
sub set_error          { $_[0]->[ERROR] = $_[1] }

#
# ->properties
#
# return the full list of arg that were given at creation time. The
# result can be used to supply the CGI functions.
#
# Return:
#   a list of arguments.
#
sub properties {
    DFEATURE my $f_;
    my $self = shift;
    
    return DARY (@{$self->[CGI_ARGS]});
}


#
# ->store_value
#
#
# Arguments:
#   $var_ctx: context reference where data can be stored when the
#             storage location is merly a string.
#   Svalue: the value to store.
#
# Return:
#   true (1) when the param has been stored somewhere (storage
#   indication is defined), false (0) otherwise.
#
sub store_value {
    DFEATURE my $f_;
    my $self = shift;
    my ($var_ctx, $value) = @_;
    my $storage = $self->storage;

    # save it internally
    $self->set_value($value);

    return DVAL ($self->nostorage != 0) unless defined $storage;

    # when storage indication is an array, the value is stored 
    # at the location defined by the 2 arrays elements. It is either
    # a hashref and a key, or a list ref and an index, or an object ref
    # and a method.
    if (ref($storage) eq 'ARRAY') {       
        my ($ref, $name, @arg) = @{$storage};
        my $target = ref($ref);
        
        if ($target eq 'HASH') {
            DTRACE "it is a hash ref";
            $ref->{$name} = $value;
        }
        elsif ($target eq 'ARRAY') {
            DTRACE "it is a list ref";
            $ref->[$name] = $value;
        }
        elsif (is_blessed($ref)) {
            DTRACE "it is an object ref ($ref)";
            DASSERT $ref->can($name), "can call '->$name' on $ref";
            if (@arg) {
                $ref->$name($value, @arg);
            } else {
                $ref->$name($value);
            }
        } else {
			my $name = $self->name;
			logwarn "invalid -storage for $name: first listed item is '$ref'";
		}
    }
    else {
        # when storage indication is a scalar, the value is stored
        # in the $var_ctx hash
        DASSERT ref(\$storage) eq 'SCALAR';        
        $var_ctx->{$storage} = $value;
    }
    
    return DVAL 1;
}

#
# ->patch_value
#
# Argument:
#   value to patch (scalar, or ref to list of values)
#
# Returns:
#   boolean indicating whether value was passed to a patching routine or not.
#   patched value, when passed to patching routine.
#
sub patch_value {
    DFEATURE my $f_;
    my $self = shift;
    my ($value) = @_;
    my $ref = $self->patch;
    return DARY (0) unless defined $ref;		# Not patched

	#
	# Patching routine can be a single routine name (which is then looked up
	# in the util path), or a list ref indicating the routine name and the
	# extra arguments to append, after the value to patch.
	#

	my ($routine, @arg);
	if (ref($ref) eq 'ARRAY') {
		# handle array setting : -patch => ['float2float', 4]
		($routine, @arg) = @$ref;
	}
	else {
		# handle scalar setting : -patch => 'float2int'
		$routine = $ref;
	}

	require CGI::MxScreen::Form::Utils;

	my $coderef = CGI::MxScreen::Form::Utils::lookup($routine);
	VERIFY $coderef != 0, "found routine '$routine'";

	#
	# NOTE: value to patch pre-pended to any extra args supplied by user
	#

	return DARY (1, &{$coderef}($value, @arg));	# Patched
}

#
# ->validate
#
# check that the value contained in this field matches the required
# criteria (mandatory or verify)
#
# Return:
#   a boolean value which indicates the error status (false on error).
#
sub validate {
    DFEATURE my $f_;
    my $self = shift;
	my $value = $self->value;

    if ($self->mandatory && $value eq "") {
        $self->set_error('field is mandatory');
        return DVAL 0;
    }
    
    # don't verify an empty field
    return DVAL 1 if $value eq "";

    if (defined $self->verify) {
        my $ref = $self->verify;

        my ($routine, @arg);
        if (ref($ref) eq 'ARRAY') {
            # handle array setting : -verify => ['is_greater', 4]
            ($routine, @arg) = @$ref;
        }
        else {
            # handle scalar setting : -verify => 'is_num'
            $routine = $ref;
        }

		require CGI::MxScreen::Form::Utils;

        my $coderef = CGI::MxScreen::Form::Utils::lookup($routine);
		logdie "validation routine '$routine' not found for the \"%s\" field",
			$self->name unless defined $coderef;

        my $error = &{$coderef}($self->value, @arg);
        $self->set_error($error) if $error;
        return DVAL !$error;
    }
    
    return DVAL 1; # there is no error
}


#
# is_blessed
#
# check whether a reference points onto an blessed object
#
# Return:
#   a boolean value.   
#
sub is_blessed { UNIVERSAL::isa($_[0], "UNIVERSAL") }

1;

=head1 NAME

CGI::MxScreen::Form::Field - A recorded field

=head1 SYNOPSIS

 # $self is a CGI::MxScreen::Screen

 use CGI qw/:standard/;

 my $amount = $self->record_field(
     -name       => "price",
     -storage    => [$order, 'set_amount'],
     -default    => $order->amount,
     -override   => 1,
     -verify     => 'is_positive',
     -mandatory  => 1,
     -patch      => 'strip_spurious_zeros',
     -size       => 10,
     -maxlength  => 10,
 );
 print textfield($amount->properties);

 my $menu = $self->record_field(
     -name       => "mode",
     -values     => ['replace', 'append', 'prepend'],
     -default    => 'append',
 );
 print popup_menu($menu->properties);

=head1 DESCRIPTION

This class models a recorded CGI control field.  One does not manually create
objects from this class, they are created by C<CGI::MxScreen> when the
C<record_field()> routine is called on a screen object to declare a new
field.

In order to attach application-specific storage information and validating
or patching callbacks to a CGI field, it is necessary to declare them
within the screen they belong, usually before generating the HTML code
for those fields.  The declaration routine takes a set of meaningful
arguments, and lets the others pass through verbatim (they are recorded
to be given back when C<properties()> is called).

You must at least supply the C<-name> argument.  You will probably supply
C<-verify> as well if you wish to perform validation of control fields,
and C<-storage> to be able to store the value in some place, or perform
any other processing on it.

=head1 INTERFACE

Some of the arguments below take a plain I<routine> argument as a scalar.
This I<routine> is not a code reference but a name that will be looked up
in various packages unless it is already qualified, such as C<'main::f'>.
See L<CGI::MxScreen/Utility Path> for information about how to specify
the searching I<path>, so to speak.

=head2 Creation Arguments

The following named arguments may be given to C<record_field()>.
They are all optional but for C<-name>.  Any argument not listed below
will be simply recorded and propagated via C<properties()>:

=over 4

=item C<-default> => I<value>

Sets the default value, for the first time the field is shown.
Since C<CGI> routines create stateful fields, you may need to say:

    -default  => $value,
    -override => 1,

to force the value of the field to C<$value>.  That is, if you use the
C<CGI> routines to ultimately generate your field.

This parameter is propagated via C<properties()>, but is intercepted
by. C<record_field> to set the C<value> attribute of the object.  If no
C<-default> is given, then the value will be that of the CGI parameter
bearing the name you give via C<-name>.

=item C<-mandatory> => I<flag>

By default, fields are not mandatory.  Setting I<flag> to true tells
C<CGI::MxScreen> that this parameter should be filled.  However, this checking
only occurs when you list C<'validate'> as an action callback in the submit
buttons of your screen.  See L<CGI::MxScreen::Form::Button>.

=item C<-name> => I<name>

Madantory parameter, giving the name of the field.
This is the CGI parameter name.

=item C<-nostorage> => 1

This directs C<CGI::MxScreen> to not handle the storage of the
parameter, at submit time.  No trail will be left anywhere in the context.
This parameter is ignored when C<-storage> is also given.

=item C<-patch> => I<routine>

Specifies a patching routine, to be called on the field value to modify
it on-the-fly, before storage and verification take place.

The routine is given the parameter value, and it must return a new (possibly
unchanged) value, which will be the one retained for further processing.
Everything will be as if the user had entered this value in the first place.

For instance, assume you say:

    -patch => 'main::no_needless_zeros',

and define:

    sub main::no_needless_zeros {
        my ($v) = @_;
        $v =~ s/^0+//;
        $v =~ s/0+$//;
        return $v;
    }

Then you if the user entered C<003.140> in a text field, it would be
patched to C<3.14>.

See L<CGI::MxScreen/Utility Path> to learn how to avoid qualifying the
I<routine> and just give its "basename", here C<no_needless_zeros>.

=item C<-storage> => I<scalar> | I<array_ref>

Storage indication lets you store the value of the field in some place,
either directly in the global persistent hash, or in any other data
structure of your choice, or even by invoking a callback.

If the argument is a I<scalar>, then it is taken as a key in the global
persistent hash.  For instance:

    -storage => "user_id",

would store the value of the field in the global hash, and would be accessed
within a screen by saying:

    my $id = $self->vars->{user_id};

Or the argument to C<-storage> can be an array ref.  In that case, the
meaning of the items in the list depend on the nature of its first item:

If it is an array ref, then the following item must be an index, and the
value will be stored at that position in the array.  For instance:

    my $array = $self->vars->{user_array};
    my $field = $self->record_field(
        -name       => "id",
        -storage    => [$array, 2],
    );

If it is an hash ref, then the following item must be a key, and the
value will be store at that key in the hash.  For instance:

    my $hash = $self->vars->{user_hash};
    my $field = $self->record_field(
        -name       => "id",
        -storage    => [$hash, "uid"],
    );

If it is a blessed ref, then we have a callback specification of the
third kind, as described in L<CGI::MxScreen/Callbacks>.  For instance:

    my $field = $self->record_field(
        -name       => "id",
        -storage    => [$object, 'record_uid', 4],
    );

The parameter value is prepended to the argument list, so the above would
raise the following call:

    $object->record_uid(CGI::param("id"), 4);

so to speak.

B<Note>: the storage specification is serialized into the context, and the
actual processing will occur once the user has submitted the form back to
the server, on the deserialized context.  This means that anything you
specify needs to be persistent, and stay accessible throughout the section.

That's why it's B<useless> to say:

    my $field = $self->record_field(
        -name       => "id",
        -storage    => [['a'], 2],
    );

because it will indeed store the value in an I<anonymous> array, which
is not otherwise accessible by the application.  You should say something
along those lines:

    my $vars = $self->vars;

    my $array;
    if (exists $vars->{user_array}) {
        $array = $vars->{user_array};
    } else {
        $array = $vars->{user_array} = [];
    }

    my $field = $self->record_field(
        -name       => "id",
        -storage    => [$array, 2],
    );

The C<exists()> check is there because by default, keys within the global
hash context are protected: it is a fatal error to access a non-existent
key (see L<CGI::MxScreen::Config> to learn how to disable that check).

All the code examples given above were simplified, assuming the value
within the context was already properly initialized.

=item C<-verify> => I<routine>

Specifies a validation I<routine> to be run.  The routine will not be
actually run unless the C<'validate'> action callback is not recorded
in the pressed submit button (see L<CGI::MxScreen::Form::Button>).

The I<routine> can be specified as a single scalar, or as an array ref:

    ['is_greater', 4]

The validation routine is passed the parameter value as a first argument,
and it must return C<0> if OK, an error message otherwise, which will be
stored in the C<error> field.  In the example above,

    is_greater($value, 4);

would be called, assuming C<$value> is the value of the field.

=back

Any other argument will be recorded as-is and passed through when
C<properties()> is called on the field object.

=head2 Features

Once created via C<record_field>, the following features may be called
on the object:

=over 4

=item C<error>

The error message returned by the validation routine.  If it evaluates to
I<false>, there is no error condition for this field.

=item C<name>

Returns the field name.

=item C<properties>

Generates the list of CGI arguments suitable to use with the routines
in the C<CGI> modules.  An easy way to generate a popup menu is to
do:

    print popup_menu($menu->properties);

assuming C<$menu> was obtained through a C<record_field()> call and
included such things as C<-values>.  Otherwise, you may add those
additional switches now, like in:

    print popup_menu($menu->properties, -values => ['a', 'b']);

but it might be better to group properties at the same place, i.e. when
C<record_field()> is called.

=item C<value>

Returns the recorded field value.

When recording a field within a screen, the C<value> attribute is
automatically set to the CGI parameter value.

=back

=head1 AUTHORS

The original authors are
Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>
and
Christophe Dehaudt F<E<lt>Christophe.Dehaudt@teamlog.frE<gt>>.

Send bug reports, suggestions, problems or questions to
Jason Purdy F<E<lt>Jason@Purdy.INFOE<gt>>

=head1 SEE ALSO

CGI::MxScreen(3), CGI::MxScreen::Form::Button(3),
CGI::MxScreen::Form::Utils(3).

=cut

