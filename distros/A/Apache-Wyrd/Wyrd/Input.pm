use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Input;
our $VERSION = '0.98';
use Apache::Wyrd::Datum;
use base qw(Apache::Wyrd::Interfaces::Setter Apache::Wyrd::Interfaces::SmartInput Apache::Wyrd);
use Apache::Wyrd::Services::SAK qw(token_parse);

=pod

=head1 NAME

Apache::Wyrd::Input - Form Input Wyrds (scalar)

=head1 SYNOPSIS

    <BASENAME::Input type="text" name="foo" flags="required" />

    <BASENAME::Input type="textarea" name="desc" height="100" width="100">
      This is the default text
    </BASENAME::Input>

    <BASENAME::Input type="hidden" name="name" value="lenore" />

    <BASENAME::Input type="password" name="name" size="10" />

    sub _startup_integer {
        my ($self, $value, $params) = @_;
        $self->{'_datum'} ||=
          Apache::Wyrd::Datum::Integer->new($self->{'value'}, $params);
        $self->{'_template'} ||= '<input type="text" name="$:name" ' .
          'value="$:value"?:size{ size="$:size"}?:id{ id="$:id"}' .
          '?:readonly{ readonly}>';
        $self->{'_smart_type'} = 'text';
    }

	<BASENAME::Input type="integer" default="1" name="counted" />

=head1 DESCRIPTION

This is the base class for Input objects, which are tracked and affected
by the Apache::Wyrd::Form (Form) objects that enclose them.  The base
Input object is meant to replace, in most cases, the input HTML objects:

=over

=item *

text inputs

=item *

password inputs

=item *

textarea inputs

=item *

hidden inputs

=back

For these, set the type attribute to B<text>, B<password>, B<textarea>,
and B<hidden> respectively.  Another hybrid input is B<plaintext>, which
both shows the text and includes it in the form as a hidden input.  For
other input types, such as radiobuttons, checkboxes, selection sets,
etc., see C<Apache::Wyrd::Input::Set>.

The Input does its work in the C<_format_output> phase.  If given a
type of "foo", it will first attempt to match it to one of the standard
types, then look for a C<startup_foo> method and if it finds it, will call
the method.  This is to allow derived Input objects to initialize
builtins, if needed, without re-implementing the whole _format_output
method.

Any derived startup_foo method should, for completeness, set the _datum
attribute to a Datum object appropriate to the type, put together a
template for the input appropriate to the expected output, and if the
C<Apache::Wyrd::Interfaces::SmartInput> interface is to be used, set the
_smart_type attribute to the appropriate one for the template.  See the
SYNOPSIS for an example startup routine for integer types.

For entry pages to Forms or any other state where the enclosing Form
cannot determine the initial value of an input, the Input will try the
current value it would be getting from a submission now (typically by
using a CGI parameter of the same name), any previous submissions (in
this form sequence) of variables of the same name, and lastly the
"default" value before giving up and initializing to null.

=head2 HTML ATTRIBUTES

=over

=item regular attributes

Most Input objects also accept the attributes of their HTML
counterparts.  For example, B<text>-type Inputs accept name, value,
size, class, id, maxlength, tabindex, accesskey, onchange, onselect,
onblur, etc.  Dev Note: Derived classes should maintain this support by
including conditionals in the template (see the code).

=item description

A description for this input, to be used in error messages.

=item maxlength

Maximum length of the inputted text, applies both to text and textarea
type Inputs.

=item name

Required.  The name of the Input.

=item param

The CGI parameter to use for this Input, if not the B<name>.

=item triggers

The triggers fired (comma separated list) by this input if invalid, if
not B<param> or B<name> (in that order of precedence).

=item width

Width of the item, in pixels.  This is an estimated value based on the
browser in use and assuming default style-sheets for those browsers. 
Meant for really quick-and-dirty formatting.  Applies only to text and
textarea Inputs, or Inputs that somehow make use of the
C<Apache::Wyrd::Interfaces::SmartInput> interface.

=item height

With the same caveats as width, this attribute is the height of the
item, in pixels.  As with width, applies only to textarea attributes or
SmartInputs that implement a height in chars.

=item type

Required.  The type of the Input.

=item flags

=over

=item allow_zero

By default, a value of zero is not considered a valid value, and a value of zero
will trigger an error if the required flag is set.  This flag will allow values
that are mathematically equivalent to zero.  It may become the default behavior
in future versions of this Wyrd.

=item escape

Escape the HTML of the value, so as to avoid HTML parsing errors. 
Default behavior for Inputs who's end-result input tags have this
problem, such as E<lt>input type="text"E<gt>

=item no_fail

Always accept value, even when invalid.

=item not_null

an alias for required.

=item quiet

Do not report error messages, only errors.

=item required

trigger an error if empty

=item reset

Do not track the value of this input, but allow it to be reset on every
submit (used in some no_submit flagged forms).

=item strict

Enforce the strict pragma on the underlying datum object.  Of limited
use outside of debugging Input objects.

=back

=back

=head2 PERL METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (scalar) C<name/type/value/description/param> (void)

Input has read-only methods for C<name>, C<type>, C<value>,
C<description>, C<triggers>, and C<param>.  The C<param> attribute is optional for
Inputs which might need to use another name than the CGI variable of
their associated HTML input, such as to use 'username' and 'password' when
the browser may attempt to auto-fill these values.

Note that the C<value> call gets the current value of the input from the
underlying C<_datum> object, and not from it's temporary storage under
the C<_value> attribute.  This allows the Datum to be independent of the
temporary value of the Input.

=cut

sub name {
	my ($self) = @_;
	return $self->{'name'};
}

sub type {
	my ($self) = @_;
	return $self->{'type'};
}

sub param {
	my ($self) = @_;
	return $self->{'param'} if ($self->{'param'});
	return $self->{'name'};
}

sub triggers {
	my ($self) = @_;
	if ($self->{'triggers'}) {
		return [token_parse($self->{'triggers'})];
	}
	return [$self->param];
}

sub value {
	my ($self) = @_;
	$self->{'_datum'}->get;
	return $self->{'_datum'}->get;
}

sub description {
	my ($self) = @_;
	return $self->{'description'};
}

=item (scalar) C<null_ok> (void)

In rare cases (a number of checkboxes, for example), the Form Wyrd being
unable to find the params associated with this input.  Normally, the
Form Wyrd will consider this an error, and refuse to alter the value of
the associated variable.  Setting a positive value for null_ok will
allow the unfound parameter to indicate a null value (such as when all
checkboxes are unchecked) You should not normally have to use this
feature.

=cut

sub null_ok {
	my ($self) = @_;
	return undef;
}

=pod

=item (void) C<set> (varies)

set accepts a value, which is converted to the appropriate type
(arrayref, scalar, etc.) to safely pass the next test, which is the
B<_check_param> internal method.  If B<_check_param> returns a null
result, it is assumed to have failed and the appropriate error calls are
made, setting error flags in the parent via the parent's
B<register_errors> and B<register_error_messages>.

In the parent, B<register_errors> is assumed to process the triggers and
register that at least one error has occurred in submitting it's inputs.
B<register_error_messages> is called separately, as there may not be a
one-to-one correspondence between what the Input should warn the user
about and what it considers an error.

The no_fail flag prevents the errors from registering at all, while the
quiet flag will suppress only the error messages.

However, pass or fail, a call to the _datum object will occur with the
B<set> call, and presumably, the Datum class will know how to deal with
that.  For it's own purposes, however, the value will be temporarily
stored by the Input, and HTML esacaped if the B<escape> flag is set.

=cut

sub set {
	my ($self, $value) = @_;
	$value = $self->_unescape($value) if ($self->_flags->escape);
	#convert value to appropriate type
	$value = [$value] if ((ref($value) ne 'ARRAY') and ($self->{'_multiple'}));
	$value = shift(@{$value}) if ((ref($value) eq 'ARRAY') and not($self->{'_multiple'}));
	my $result = $self->_check_param($value); #check params and set error values
	unless ($result) {
		$self->_warn("Failed to set the datum object for " . $self->{'name'} . " to the value $value");
		unless ($self->_flags->no_fail) {
			$self->{'_parent'}->register_errors($self);
			$self->{'_parent'}->register_error_messages($self) unless ($self->_flags->quiet);
		}
	}
	$self->{'_datum'}->set($value);
	#set the value anyway, since it will need to be stored temporarily and,
	#presumeably, an impossible value will not be rendered as set by the
	#browser on the form at all.
	$value = $self->{'_datum'}->get($value);
	$self->{'value'}=$value unless ($self->_flags->reset);
}

=pod

=item (void) C<_parse_options> (void)

_parse_options looks to the B<options> attribute, which may be explicit
as a comma/whitespace delineated list or built up by sub-objects (see
C<Apache::Wyrd::Input::Opt>) in order to determine what options to give
to the datum object.  If this value is already a hashref or arrayref, it
does no further processing.  Otherwise it attempts to separate the words
of the options attribute, using an optional regexp under the "delimiter"
attribute.

=cut

sub _parse_options {
	#prepare options for Apache::Wyrd::Datum
	my ($self) = @_;
	$self->{options} = {} unless ($self->{'options'} or $self->{'hash_options'});
	my $self_options = $self->{'options'};
	my $delimiter = $self->{'delimiter'};
	return undef if (ref($self_options) =~ /HASH|ARRAY/);
	if (ref($self_options)) {
		$self->_raise_exception("Don't understand why options are a " 
			. ref($self_options));
	} elsif ($self->{'hash_options'}) {
		my %hash = token_parse($self->{'hash_options'}, $delimiter);
		$self->{'options'} = \%hash;
	} else {
		my @options = token_parse($self->{options}, $delimiter);
		$self->{'options'} = \@options;
	}
}

=item (scalar) C<_check_param> (scalar)

the B<_check_param> method itself, by default, calls the B<check> method
of the underlying Datum instance.  Datum returns two values, the first
indicating pass/fail for defined/undefined and the second indicating
what the default error message is.  Authors producing Datum objects
created to support the Input should pay special attention to this, as
this is where useful error messages can be generated, rather than the
default "Invalid data in <param-name>".  _check_param also adds the
parameter/name as a token to the error register so it can be tracked by
the parent.

A shorthand for adding this method to an item is the description
attribute, which will be prepended to the error string if an error
occurs.

the values stored in the _errors and _error_messages registers can be
accessed read_only through the errors and error_messages methods, as
demonstrated by the Form object.

=cut

sub _check_param {
	my ($self, $value) = @_;
	#use the datum as the checker
	my ($ok, $errstr) = ($self->{'_datum'}->check($value));
	return 1 if ($ok);
	$errstr ||= ($self->{'error_message'} || 'Invalid data.');
	$errstr = $self->description . ": $errstr" if ($self->description);
	$self->{'_error_messages'} = [@{$self->{'_error_messages'}}, $errstr];
	$self->{'_errors'} ||= $self->triggers;
	return;
}

=pod

=item (scalar) C<errors> (void)

Return all the errors for this Input.  Should be considered as
"triggers" of an C<Apache::Wyrd::Form> object for the
C<Apache::Wyrd::ErrTag> objects to detect (see documentation for those
modules).

=cut

sub errors {
	my ($self) = @_;
	return $self->{'_errors'};
}

=item (scalar) C<error_messages> (void)

Return all the error messages for this Input.

=cut

sub error_messages {
	my ($self) = @_;
	return $self->{'_error_messages'};
}

=pod

=item (scalar) C<_escape> (scalar)

the C<_escape> method is a utility for escaping the data in an HTML
text-type input in order to avoid formatting errors.  The default is to
only escape quotes and ampersands by encoding them as the appropriate
entity.

=cut

sub _escape {
	my ($self, $value) = @_;
	$value =~ s/\&/\&amp;/g;
	$value =~ s/'/\&apos;/g;
	$value =~ s/"/\&quot;/g;
	$value =~ s/</\&lt;/g;
	$value =~ s/>/\&gt;/g;
	$value =~ s/\?:/\?\x00:/g;
	$value =~ s/\!:/\!\x00:/g;
	$value =~ s/\$:/\$\x00:/g;
	return $value;
}

=pod

=item (scalar) C<_escape> (scalar)

the C<_unescape> method reverse-mirrors the C<_escape> method exactly.

=cut

sub _unescape {
	my ($self, $value) = @_;
	$value =~ s/\&amp;/\&/g;
	$value =~ s/\&apos;/'/g;
	$value =~ s/\&quot;/"/g;
	$value =~ s/\&lt;/</g;
	$value =~ s/\&gt;/>/g;
	$value =~ s/\?\x00:/\?:/g;
	$value =~ s/\!\x00:/\!:/g;
	$value =~ s/\$\x00:/\$:/g;
	return $value;
}

=pod

=item (scalar) C<_template_foo> (scalar)

the C<_template> methods should provide an
C<Apache::Wyrd::Interfaces::Setter>-style template for a given input.
Built-in templates are text, textarea, password

=cut

sub _template_text {
	return '<input type="text" name="$:param" value="$:value"?:size{ size="$:size"}?:class{ class="$:class"}?:style{ style="$:style"}?:id{ id="$:id"}?:maxlength{ maxlength="$:maxlength"}?:tabindex{ tabindex="$:tabindex"}?:accesskey{ accesskey="$:tabindex"}?:onchange{ onchange="$:onchange"}?:onselect{ onselect="$:onselect"}?:onblur{ onblur="$:onblur"}?:onfocus{ onfocus="$:onfocus"}?:onkeydown{ onkeydown="$:onkeydown"}?:autocomplete{ autocomplete="$:autocomplete"}?:disabled{ disabled}?:readonly{ readonly}>';
}

sub _template_textarea {
	return '<textarea name="$:param"?:cols{ cols="$:cols"}?:rows{ rows="$:rows"}?:wrap{ wrap="$:wrap"}?:id{ id="$:id"}?:class{ class="$:class"}?:style{ style="$:style"}?:tabindex{ tabindex="$:tabindex"}?:accesskey{ accesskey="$:accesskey"}?:onblur{ onblur="$:onblur"}?:onchange{ onchange="$:onchange"}?:onfocus{ onfocus="$:onfocus"}?:onkeypress{ onkeypress="$:onkeypress"}?:disabled{ disabled}?:readonly{ readonly}>$:value</textarea>';
}

sub _template_password {
	return '<input type="password" name="$:param" value="$:value"?:size{ size="$:size"}?:id{ id="$:id"}?:maxlength{ maxlength="$:maxlength"}?:class{ class="$:class"}?:style{ style="$:style"}?:tabindex{ tabindex="$:tabindex"}?:accesskey{ accesskey="$:tabindex"}?:onchange{ onchange="$:onchange"}?:onselect{ onselect="$:onselect"}?:onblur{ onblur="$:onblur"}?:onfocus{ onfocus="$:onfocus"}?:onkeydown{ onkeydown="$:onkeydown"}?:autocomplete{ autocomplete="$:autocomplete"}?:disabled{ disabled}?:readonly{ readonly}>';
}

sub _template_hidden {
	return '<input type="hidden" name="$:param" value="$:value">';
}

=pod

=back

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the C<_format_output> and C<_generate_output> methods.  Also
reserves the C<final_output> method.

=cut

sub _format_output {
	my ($self) = @_;
	$self->{'value'} ||= undef;#value will be set by the end if not earlier
	$self->{'_error_messages'} ||= [];
	my $name = $self->{'name'};
	$self->{'param'} ||= $name;
	my $type = $self->{'type'};
	$self->_parse_options;
	#primitives are overriden by instances of Apache::Wyrd::Input
	my %params = (
		#default params
		strict => ($self->_flags->{strict} || undef),
		not_null => ($self->_flags->not_null || $self->_flags->required || undef),
		options => $self->{'options'}
	);
	if ($self->_flags->readonly) {
		$self->{'readonly'} = 'true';
	}
	$self->{'_template'} = $self->{'_data'};
	if ($name eq '') {
		$self->_raise_exception('All Inputs must have a name')
	} elsif ($type eq '') {
		$self->_raise_exception('All Inputs must have a type')
	} elsif ($self->can('_setup_' . $type)) {
		my $result = eval('$self->_setup_' . $type);
		if ($@) {
			$self->_raise_exception($@);
		}
	#send the datums the "value" for defaults.
	} elsif ($type eq 'text') {
		$self->_flags->escape(1);
		my $max_length =  $self->{'maxlength'};
		if ($max_length and ($max_length < 255)) {
			$params{'length'} = $max_length;
			$self->{'_datum'} ||= (Apache::Wyrd::Datum::Char->new($self->{'value'}, \%params));
		} else {
			$self->{'_datum'} ||= (Apache::Wyrd::Datum::Text->new($self->{'value'}, \%params));
		};
		$self->{'_template'} ||= $self->_template_text;
	} elsif ($type eq 'textarea') {
		$self->_flags->escape(1);
		$self->{'value'} ||= $self->_data;#value may be enclosed in a textarea input
		$self->{'_datum'} ||= Apache::Wyrd::Datum::Text->new($self->{'value'}, \%params);
		if ($self->{'_template'} !~ /<textarea/) {
			$self->{'_template'} = $self->_template_textarea;
		}
	} elsif ($type eq 'hidden') {
		$self->_flags->escape(1);
		$self->{'_datum'} ||= Apache::Wyrd::Datum::Text->new($self->{'value'}, \%params);
		$self->{'_template'} ||= $self->_template_hidden;
	} elsif ($type eq 'password') {
		$self->{'_datum'} ||= Apache::Wyrd::Datum::Text->new($self->{'value'}, \%params);
		$self->{'_template'} ||= $self->_template_password;
	} elsif ($type eq 'plaintext') {
		$self->{'_datum'} ||= Apache::Wyrd::Datum::Text->new($self->{'value'}, \%params);
		$self->{'_template'} ||= '$:value<input type="hidden" name="$:name" value="$:value">';
	} else {
		if ($self->can('_startup_' . $type)) {
			eval('$self->_startup_' . $type .'($self->{\'value\'}, \\%params)');
			$self->_raise_exception($@ . " while trying to create an input of type '$type'") if ($@);
		} else {
			$self->_raise_exception("Don't know how to handle a '$type'");
		}
	}
	$self->_input_size;
	$self->_raise_exception('Input must be a top-level item in a Form-family Wyrd.  This parent is: ' . $self->_parent->class_name)
		unless ($self->{'_parent'}->can('register_input'));
	$self->{'_id'} = $self->{'_parent'}->register_input($self);
}

sub _generate_output {
	my ($self) = @_;
	my $id = $self->{'_id'};
	$self->_raise_exception('No ID provided by form') unless ($id);
	$self->_data('$:' . $id);
}

sub final_output {
	my ($self) = @_;
	my (%values) = ();
	foreach my $value (keys %{$self}) {
		next if $value =~ /^_/;
		$values{$value} = $self->{$value};
	}
	#If by now the input has no value, try to give it one from CGI, the form, or default in that order;
	unless ($values{'value'} or $self->_flags->reset or ($self->_flags->allow_zero and $values{'value'}=~ /^\s*0?E?[+\-]?\s*0(\.0+)?\s*/)) {
		my ($value, $success) = $self->{'_parent'}->_get_value($self->{'name'});
		$values{'value'} = ($value || $self->{'_parent'}->{'_variables'}->{$self->{'name'}} || $self->{'default'} || '');
	}
	$values{'value'} = $self->_escape($values{'value'}) if ($self->_flags->escape);
	return ($self->_clear_set(\%values, $self->{'_template'}));
}

=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=item Apache::Wyrd::Form

Build complex HTML forms from Wyrds

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;
