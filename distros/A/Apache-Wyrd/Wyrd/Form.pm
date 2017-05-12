#Copyright barry king <barry@wyrdwright.com> and released under the GPL.
#See http://www.gnu.org/licenses/gpl.html#TOC1 for details
use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Form;
our $VERSION = '0.98';
use base qw(Apache::Wyrd::Interfaces::Mother Apache::Wyrd::Interfaces::Setter Apache::Wyrd);
use XML::Dumper;
use Apache::Wyrd::Services::CodeRing;
use Apache::Wyrd::Services::SAK qw(send_mail);

=pod

=head1 NAME

Apache::Wyrd::Form - Build complex HTML forms from Wyrds

=head1 SYNOPSIS

  <BASENAME::Form recipient="webmaster@example.com">
    <BASENAME::Form::Template name="enter">
      $:error_block
      <BASENAME::ErrField trigger="name">
        Name:
      </BASENAME::ErrField>
      <BASENAME::Input type="text" name="name" flags="required" />
      <input type="submit" name="action" value="Send Name" />
    </BASENAME::Form::Template>
    <BASENAME::Form::Template name="exit">
      Your name has been mailed to the webmaster.
    </BASENAME::Form::Template>
  </BASENAME::Form>

=head1 DESCRIPTION

The C<Apache::Wyrd::Form> (Form) object provides the core mechanism for
processing fill-in forms.

The Form requires one or more C<Apache::Wyrd::Form::Template> objects
(Templates) which provide, on the same page/url/Location, the pages
which make up the complete form.

By default, the form will process these Templates in order, starting
with the first enclosed Template in order of appearance in the HTML
text, and ending with the last, accepting each set of input from the
browser and moving on to the next. On submission of the last page, the
form finalizes the process by calling the C<_submit_data> method.  This
way, a large amount of data can be entered in subsequent browser-pages
as if they were the same page and submitted only when the full requisite
of data is accumulated. Additionally, there are methods available for
conditionally moving between Templates in order to include or exclude a
section of the Template-set or range of requirements.

The form maintains the state of the information between Template pages,
accumulating them in the (reserved) B<_variables> attribute.  If
inputs/controls in later Templates have the same name as those in
earlier ones, the values submitted in the earlier ones will be the
initial values of the later.

Forms have three classes of children: Inputs, Views, and Errors.  Forms
track the value of and operate on Inputs, meaning
C<Apache::Wyrd::Input>s or derived classes of C<Apache::Wyrd::Input>.
C<Form::View> (View) objects show a snapshot of the current state of the
form, as a preview, and C<Form::ErrTag> and C<Form::ErrField> objects
(Error Flags) indicate on the page which Inputs have illegal values for
the requirements of the form.  Dev. Note: Although they are all
enclosed in a C<Form::Template> Wyrd, all these elements are actually
direct children of the Form, because the Template enclosing them becomes
the literal body of the form for the browser-server transaction at that
point in the sequence. (Form objects use a method called C<_reload_self>
to do this.)

Input values can also be initialized via CGI by passing values (in a get
or post request) to the Form.  There is also a pair of explicit
initializers, C<Apache::Wyrd::Form::Preload> and
C<Apache::Wyrd::Form::Defaults>, which are placed inside Templates to
initialize the values of inputs within that Template.  Internally, the
_preload_inputs method can be overridden (defined in a subclass) to do
the same, and yet another method _extra_preloads can be overridden to
preload specific input values.

The Form calls the C<set> method of each of it's Inputs, passing a value
to the Input which is derived (in order of priority) by checking to see
if the input can provide a C<current_value>, seeing if it has a method
defined for that purpose, C<_param_process_foo> where "foo" is the name
of the parameter, or lastly, by checking the CGI environment for the
value.  Dev. Note: Inputs also have a priority by which they attempt to
establish default values for themselves based on defaults or the current
CGI environment if the Form is unable to determine one for them, as is
the case on Form entry pages.  See the documentation for
C<Apache::Wyrd::Input>.

Internally, the form also manipulates the CGI environment to make the
use of image-buttons more convenient.  It searches for CGI parameters by
the name of B<foo.x> and sets value of the parameter B<action> to "foo".
This allows to set an action parameter simply by naming the image button
to the name of the action you would like it to perform.  For example,
the following input will cause an Apache::Wyrd::Form object to set the
value of the CGI parameter B<action> to "cancel":

	<input type="image" src="/images/cancel.gif" name="cancel">

Before advancing to the next Template in the sequence, the form will
check every input in turn to see if it has returned an error.  Errors
are compiled, and if they number more than zero, the submitted Template
will be reloaded, setting any Error Flag triggered by the Input.  If
there are no errors, the Form moves on to the next Template.  If there
are no more templates, it submits all its accumulated data via the
C<_submit_data> method.

No matter which template is the current one, the Form will also complete
the transaction by setting any placemarkers inside the template which
match the name of one of the C<_globals> keys.  By so doing, the
programmer can set a global at any point in the form handling system and
expect that global to show in it's placemarked area in the HTML of the
form.

Among the standard globals is the B<error_block> global, which
represents where to put the block of error messages on the page of the
form.  In other words if $:error_block does not appear on the template,
there will be no error_block shown on the form.

=head2 HTML ATTRIBUTES

=over

=item action

Same as the B<action> attribute of the HTML E<lt>formE<gt> tag.  If this is
the location of a page with a different Form object on it, the form sequence
will continue with all accumulated data to that location.  Note, however,
that any new data (that is, data entered on the template from which the
action is triggered) will need to be received and vetted by the B<next>
form, not this form.  This can be done by putting appropriate Input objects
in the receiving form.

If not provided, the default, and generally much simpler, action value is a
reference to the current page.

=item method

Same as the B<method> attribute of the HTML E<lt>formE<gt> tag.

=item recipient

When using the default behavior, submits the information via email to
this recipient in the form of an XML dump.

=item flags

=over

=item check_resets

Check for the submission of a "reset" button by checking that the
parameter action is set to "reset".  Resets the whole form to it's
default state.

=item continue

Keep accumulated data past the _submit() method and insert it in the final
form page.  This allows that page to be used as a continuation point to
another form.  Note that the C<action> attribute must be set to the location
of the continuation page.

=item ignore_errors

Proceed through the Templates from one to the next even if there are input
errors.

=item no_collapse

Show all error messages, even if there are more than one identical
message.

=item no_grow

Do not add the formname to the URL of each step to mark the passage from
one form to the next.  The default behavior is to do so so as to avoid
any weirdness with odd browsers.

=item no_submit

Do not submit the form.  Useful for forms for "control panel" style
forms that shift the state of the page while retaining that state.

=item preload

Checks for preloaded values.  Set automatically by an
C<Apache::Wyrd::Form::Preload> object.

=back

=head1 HIDDEN ATTRIBUTES

Because of the complexity of the C<Apache::Wyrd::Form> object,
explanations of these internal attributes are provided to aid
development of subclasses.

=over

=item _variables

hashref of all input/form values, loaded first from the storage
variable, then from the CGI environment.

=item _globals

hashref of private variables for the given form.  By default, the form
will have any matching C<Apache::Wyrd::Interfaces::Setter>-style
placemarkers set to these values.

=item _input_index & _input

Inputs are stored in arrayref to support multiple inputs of the same
variable.  Hence, unique names need to be used in an index to indicate a
given member of the arrayref _input.

=item _errortag_index & _errortag

Errortags are conditionally-varying elements of the form usually
indicating errors.

=item _view_index & _view

Views are set-style templates used for showing the current state of the
form on the page.

=item _errors

flags for particular error conditions, stored in an arrayref. This array
is checked against registered triggers for errortags.  Errors are
defined as arbitrary strings signifying an error event such as "preview"
or "no full name".  Note that as soon as an error is inserted, the form
will not advance to the next template until the error is corrected
(unless, of course, the ignore_errors flag is set).

=item _error_messages

arrayref of strings to be displayed to the user explaining what error
conditions have occurred and how to fix them.

=item _current_identifier

which of the multiple forms is the current focus. Will normally change
during any given run of the Form object as one form is approved and the
next is loaded.

=item _form & _form_index

Forms are individual "states" that the form is in, usually signifying
the process of filling out each step of a multiple-page form.

=item _action_index

Hashref holding the action to put into the form tag when using that form
as the current form.

=item _next_form, _current_form, & _last_form

self explanatory place markers used in deciding where in the sequence of
forms the user is.

=back

=head2 PERL METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (void) C<drop_var> (scalar)

Remove a parameter from the tracked state.

=cut

#Public methods

sub drop_var {
	#accessor for special cases
	my ($self, $var) = @_;
	delete($self->{'_variables'}->{$var->name});
}

=item (void) C<insert_error> (scalar)

Add a "trigger" to the error register.  In the most usual case where the
error indicates illegal input, this is the parameter name, but may
represent a more complex error condition, such as a scheduling conflict
or unbalanced set of figures.

=cut

sub insert_error {
	my ($self, $error) = @_;
	$self->{'_errors'} = [@{$self->{'_errors'}}, $error];
}

=item (void) C<insert_error_messages> (array[ref])

Insert an error message into the error message queue.  The queue is
processed by the C<_dump_errors> method.

=cut

sub insert_error_messages {
	my ($self, @error_messages) = @_;
	@error_messages = @{$error_messages[0]} if (ref($error_messages[0]) eq 'ARRAY');
	$self->{'_error_messages'} = [@{$self->{'_error_messages'}}, @error_messages];
}

=item (void) C<register_form> (Apache::Wyrd::Form::Template)

Add a form Template to this form object.  Called by
C<Apache::Wyrd::Form::Template> to build the form sequence.  Also notes
the action attribute of the template, which can override the default or
given action of the Form.

=cut

sub register_form {
	my ($self, $form) = @_;
	$self->{'_form'}->{$form->name} = $form->_form_body;
	$self->{'_form_index'} = [@{$self->{'_form_index'}}, $form->name];
	$self->{'_action_index'}->{$form->name} = $form->action;
	return;
}

=item (void) C<register_errors> (Apache::Wyrd::Input)

Same as C<insert_error>, except the argument is an Input object who's
errors are inserted.

=cut

sub register_errors {
	my ($self, $input) = @_;
	my $errors = $input->errors;
	foreach my $error (@$errors) {
		$self->insert_error($error);
	}
	return;
}

=item (void) C<register_error_messages> (Apache::Wyrd::Input)

Same as C<insert_error_messages>, except the argument is an object who's
(possibly multiple) errors are inserted.

=cut

sub register_error_messages {
	my ($self, $input) = @_;
	my $errors = $input->error_messages;
	foreach my $error (@$errors) {
		$self->{'_error_messages'} = [@{$self->{'_error_messages'}}, $error];
	}
	return;
}

=item (void) C<register_input> (Apache::Wyrd::Input)

Register an input to be tracked by this form.  See C<Apache::Wyrd::Input>

=cut

sub register_input {
	my ($self, $input) = @_;
	my @current_inputs = @{$self->{'_input'}};
	my $input_count = @current_inputs; #note that scalar is always index + 1
	my $id = $self->_name_child;
	$self->{'_input'} = [@current_inputs, $input];
	$self->{'_input_index'}->{$id} = $input_count;
	return $id;
}

=item (void) C<register_errortag> (Apache::Wyrd::ErrTag)

Register an ErrorTag-like object to be tracked by this form.  See
C<Apache::Wyrd::ErrTag> or C<Apache::Wyrd::ErrField>.

=cut

sub register_errortag {
	my ($self, $errortag) = @_;
	my @current_errortags = @{$self->{'_errortag'}};
	my $errortag_count = @current_errortags; #note that scalar(array) is always index + 1
	my $id = $self->_name_child;
	my $triggers = $errortag->get_triggers;
	$self->{'_errortag'} = [@current_errortags, $errortag];
	$self->{'_errortag_index'}->{$id} = $errortag_count;
	foreach my $trigger (@$triggers) {
		$self->{'_triggers'}->{$trigger} ||= [];
		$self->{'_triggers'}->{$trigger} = [@{$self->{'_triggers'}->{$trigger}}, $errortag]
	}
	return $id;
}

=item (void) C<register_view> (Apache::Wyrd::ErrTag)

Register a View-like object to be tracked by this form.  See
C<Apache::Wyrd::Form::View>.

=cut

sub register_view {
	my ($self, $view) = @_;
	my @current_views = @{$self->{'_view'}};
	my $view_count = @current_views; #note that scalar is always index + 1
	my $id = $self->_name_child;
	$self->{'_view'} = [@current_views, $view];
	$self->{'_view_index'}->{$id} = $view_count;
	return $id;
}

=item (void) C<set_var> (scalar)

Set the value of the given parameter in the tracked state.

=cut

sub set_var {
	#accessor for special cases
	my ($self, $var) = @_;
	$self->{'_variables'}->{$var->name} = $var->value;
}

=pod

=back

=head2 HOOK METHODS

=over

=item (void) C<_interpret_action> (void)

Called during the _setup phase.  Default behavior is to interpret any
image-type inputs into the param B<action>.

=cut

#Private Methods

sub _interpret_action {
	my ($self) = @_;
	return undef if ($self->dbl->param('action'));
	my @param = $self->dbl->param();
	foreach my $param (@param) {
		my $action = $1 if ($param =~ /(.+)\.x$/);
		$self->dbl->param('action', $action) if ($action);
		$self->_info("Interpreting $action as the action") if ($action);
	}
	return;
}

=item (scalar) C<_format_error> (scalar)

Format an error message.  To be used with C<_format_error_block> to
format the error message on the page.  These are compiled into a block
during the _format_output phase.  Default behavior is to return the
error as an HTML line-item.

=cut

sub _format_error {
	my ($self, $error) = @_;
	return "<LI>$error";
}

=item (scalar) C<_format_error_block> (scalar)

Format the block of error messages.  To be used with
C<_format_error_block> to format the error message on the page.  Default
behavior is to return the error as an HTML unordered list with the text:
"The following problems were found:" and "Please correct the items
marked before continuing" around it.  The default behavior assumes the
CSS style B<.error> is defined to mark errors.  See
C<Apache::Wyrd::ErrField>.

=cut

sub _format_error_block {
	my ($self, $block) = @_;
	return "<P>The following problems were found:<UL>$block</UL>Please correct the items <span class=\"error\">marked</span> before continuing.<P>";
}

=item (void) C<_dispatch_errors> (void)

This method handles how the errors will be sent to the page.  The default is
to set the global placemaker "error_block" to the value of the error block,
so this placemarker must be somewhere in the current Form Template in order
to show on the page.

=cut

sub _dispatch_errors {
	my $self = shift;
	$self->{'_globals'}->{'error_block'} = $self->_dump_errors;
	return;
}

=item (void) C<_prep_submission> (void)

If the default C<_submit_data> method is used, this provides a hook for
altering the data prior to submitting it.

=cut

sub _prep_submission {
	return;
}

=item (void) C<_submit_data> (void)

Submit the accumulated data.  All variables should be in the _variables
attribute at the time this method is called.  By default, it will attempt
to mail an XML dump of the data if the recipient attribute is set.  If
not, it will dump the data to STDERR (the Apache error log).

=cut

sub _submit_data {
	my ($self) = @_;
	$self->_prep_submission;
	my $recipient = ($self->{'recipient'});
	my $sender = ($self->{'sender'} || $recipient);
	my $subject = ($self->{'subject'} || 'Data from ' . $self->dbl->self_path);
	my $xd = new XML::Dumper;
	my $body = $xd->pl2xml(
		{
			form_data => $self->{'_variables'},
			timestamp => scalar(localtime)
		}
	);
	if ($recipient) {
		send_mail(
			{
				to		=>	$recipient,
				from		=>	$sender,
				subject	=>	$subject,
				body		=>	$body
			}
		);
	} else {
		#Dump to STDERR
		warn("Form Submission:\n$body");
	}
}

=item (void) C<_prep_preloads> (void)

Hook for altering preloads before executing them.  Called during the
_format_output phase.

=cut

sub _prep_preloads {
	return;
}


=item (void) C<_extra_preloads> (void)

Hook for additional preloads.  Called during the _format_output phase.

=cut

sub _extra_preloads {
	return;
}

=item (void) C<_activate_widgets> (void)

Hook for activating special controls. Called during the _format_output phase.

=cut

sub _activate_widgets {
	#blank placemaker
	return;
}

=item (void) C<_check_form> (void)

Hook for inserting special error conditions for form-wide events, such
as a running total that violates a special rule.  Called during the
_format_output phase.

=cut

sub _check_form {
	#blank placemaker
	return;
}

=item (void) C<_check_reset> (void)

Determine if a reset condition is reached.  By default, checks to see if
the B<action> parameter is set to "reset" and the B<check_reset> flag is
set.

=cut

sub _check_reset {
	my $self = shift;
	return undef unless ($self->_flags->check_resets);
	return 1 if ($self->dbl->param('action') =~ /reset/i);
	return;
}

=item (void) C<_check_form> (void)

Hook for inserting special error conditions for global events, or for
altering global values before continuing with processing the form.

This is also a good place to do flow control when pages in a template
sequence may conditionally need to be skipped, or where flow is to be
directed to a form on a new page.

Example:

    sub _check_form {
        my ($self) = @_;
        if ( ($self->{_current_form} eq 'fourthpage') ) {
            if ($self->{_variables}->{skip_page_5}) {
                #
                #if the skip_page_5 variable is set, move on to page 6.
                $self->{_next_form} = 'sixthpage';
                #
            } elsif ($self->{_variables}->{validity} eq 'invalid') {
                #
                #if the value of "validity" is "invalid", move on to the
                #validity restoration form.
                return $self->dbl->req->internal_redirect_handler('/restore_validity.html');
                #
            }
        }
    }


=cut

sub _check_globals {
	my $self = shift;
	$self->insert_error('no_submit') if ($self->_flags->no_submit);
	return;
}

=item (scalar) C<_storage_template> (void)

HTML format for the state-storage hidden variable.  By default is a simple hidden input.

=cut

sub _storage_template {
	return '<input type="hidden" name="$:name" value="$:data">' . "\n";
}


=item (scalar) C<_submitted> (void)

Has the form been submitted yet, or are we on the first page?  If altered, be sure to alter _proof_of_submit as well.

=cut

sub _submitted {
	my $self = shift;
	return $self->dbl->param('_submitted');
}

=item (scalar) C<_proof_of_submit> (void)

HTML format for the proof of submit hidden variable.  By default is a simple hidden input with the param name B<_submitted>.

=cut

sub _proof_of_submit {
	return '<input type="hidden" name="_submitted" value="1">' . "\n";
}

=pod

=back

=head2 OTHER RESERVED METHODS

The Form object also reserves the methods _dump_errors, _fire_triggers, _unpack_data, _pack_data, _preload_inputs, _check_inputs, _check_errors, _reload_form, _get_value, _wrap_form, _current_marker, register_child, and _set_children.

=cut

sub _dump_errors {
	my ($self) = @_;
	my $error_text = undef;
	my %errors = ();
	unless ($self->_flags->no_collapse) {
		foreach my $error (@{$self->{'_error_messages'}}) {
			$errors{$error} = $error;
		}
		foreach my $error (sort { $a cmp $b } keys(%errors)) {
			$error_text .= $self->_format_error($error);
		}
	} else {
		foreach my $error (@{$self->{'_error_messages'}}) {
			$error_text .= $self->_format_error($error);
		}
	}
	$error_text = $self->_format_error_block($error_text) if ($error_text);
	return $error_text;
}

sub _fire_triggers {
	my ($self) = @_;
	foreach my $error (@{$self->{'_errors'}}) {
		$self->_debug("Firing triggers: $error");
		foreach my $error_tag (@{$self->{'_triggers'}->{$error}}) {
			$error_tag->fire;
		}
	}
}

sub _unpack_data {
	#decode stored data for inclusion into variables
	my ($self) = @_;
	my $storage = $self->dbl->param("_storage");
	return undef unless ($storage);
	my $ring = Apache::Wyrd::Services::CodeRing->new;
	my $counter = undef;
	my $stored_data = undef;
	do {
		$stored_data .= $storage;
		$counter++;
		$storage = $self->dbl->param("_storage$counter");
	} while ($self->dbl->param("_storage$counter"));
	#now that you have it, decrypt it (CodeRing);
	$stored_data = ${$ring->decrypt(\$stored_data)};
	my $xd = new XML::Dumper;
	my $hash = $xd->xml2pl($stored_data);
	foreach my $var_name (keys(%{$hash})) {
		#warn("Unpacked data: " . $var_name .'='. $hash->{$var_name});
		my $value = $hash->{$var_name};
		if (ref($value) eq 'ARRAY') {
			$value = $value->[0] unless (scalar(@$value) > 1);
		}
		$self->{_variables}->{$var_name} = $value;
	}
}

sub _pack_data {
	my ($self) = @_;
	my $xd = new XML::Dumper;
	my $out = $xd->pl2xml($self->{_variables});
	my $ring = Apache::Wyrd::Services::CodeRing->new;
	$out = ${$ring->encrypt(\$out)};
	my $length_out = length($out)/30000 + 1;
	my @outs = unpack ('a30000' x $length_out, $out);
	#rebuild out out of 30K pieces to overcome crappy IE cgi submission
	my $counter = undef;
	$out = undef;
	foreach my $subpart (@outs) {
			$out .= $self->_set({data => $subpart, name => "_storage$counter"}, $self->_storage_template);
			$counter++;
	}
	$self->{'_stored_data'} = $out;
}

sub _preload_inputs {
	my ($self) = @_;
	$self->_prep_preloads;
	#iterate through the inputs, setting if possible
	foreach my $input (keys(%{$self->{_input_index}})) {
		$input = $self->{'_input'}->[$self->{'_input_index'}->{$input}];
		$input->set($self->{'_variables'}->{$input->name});
	}
	$self->_extra_preloads;
}

sub _check_inputs {
	my ($self) = @_;
	#iterate through the inputs, checking errors
	foreach my $input (keys(%{$self->{_input_index}})) {
		$input = $self->{'_input'}->[$self->{'_input_index'}->{$input}];
		my ($value, $success) = ();
		#inputs can define a current_value method in order to override a normal
		#CGI lookup
		if ($input->can('current_value')) {
			$success = 1;
			$value = $input->current_value;
		} else {
			($value, $success) = $self->_get_value($input->param);
		}
		$input->set($value);
		#use Data::Dumper;
		#warn "Value of input: " . $input->name . " is " . Dumper($input->value);
		$self->_debug("Value of input: " . $input->name . " is " . $input->value);
		#set the running variable amount
		if ($success or $input->null_ok) {
			$self->{'_variables'}->{$input->name} = $input->value;
		}
	}
}

sub _check_errors {
	my $self = shift;
	return scalar(@{$self->{'_errors'}});
}

sub _reload_form {
	#reprocess the form based on current value of _current_form
	my ($self) = @_;
	$self->_info("Loading '" . $self->{'_current_form'} . "' and reprocessing self");
	$self->_data($self->{'_form'}->{$self->{'_current_form'}});
	$self->_process_self;
}

sub _get_value {
	my ($self, $param) = @_;
	my $success = 1;
	if ($self->can('_param_process_' . $param)) {
		$self->_info("found a _param_process_$param I can call");
		eval('$param=$self->_param_process_' . $param);
		$self->_raise_exception($@) if ($@);
	} else {
		if ($self->dbl->param_exists($param)) {
			my @value = $self->dbl->param($param);
			$param = [@value];
			$param = $value[0] if (scalar(@value) == 1);
			$param = undef if (scalar(@value) == 0);
		} else {
			$param = undef;
			$success = 0;
		}
	}
	return ($param, $success);
}

sub _wrap_form {
	my ($self, $form) = @_;
	my $remove_form = $self->dbl->param('_current_form');
	my $default = $self->dbl->self_path;
	$default =~ s/\/$remove_form$//;
	$default .= "/" . $self->{'_current_form'} unless ($self->_flags->no_grow);
	my $action = ($self->{'_action_index'}->{$self->{'_current_form'}} || $self->{'action'} || $default);
	my $method = ($self->{'method'} || 'post');
	my $extra_attributes = '';
	foreach my $attribute (qw(enctype accept-charset onsubmit)) {
		my $attribute_value = $self->{$attribute};
		if ($attribute_value) {
			$extra_attributes .= qq( $attribute="$attribute_value");
		}
	}
	my $name = ($self->{'_current_form'} || 'form');
	my $header = $self->_proof_of_submit . $self->_current_marker;
	$header .= $self->{'_stored_data'} if ($self->{'_stored_data'});
	return "<form name=\"$name\" action=\"$action\" method=\"$method\"$extra_attributes>\n" . $header . $form . "\n</form>";
}

sub _current_marker {
	my $self = shift;
	my $form = $self->{'_current_form'};
	return undef unless ($form);
	return '<input type="hidden" name="_current_form" value="' . $form . '">' . "\n";
}

sub register_child {
	my ($self) = @_;
	$self->_raise_exception($self->_class_name . ' has separate child registers. Do not call register_child.');
}

sub _set_children {
	my ($self) = @_;
	$self->_raise_exception($self->_class_name . ' has separate child registers. Do not call set_children.');
}

=pod

=back

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the _setup, the _format_output, AND the _generate_output method.  Subclassing is done via the other hooks, above.

=cut

#standard Wyrd methods
sub _setup {
	my ($self) = @_;
	$self->{'_globals'} = {error_block => undef};
	$self->{'_variables'} = {};
	$self->{'_input_index'} = {};
	$self->{'_input'} = [];
	$self->{'_errortag_index'} = {};
	$self->{'_errortag'} = [];
	$self->{'_view_index'} = {};
	$self->{'_view'} = [];
	$self->{'_errors'} = [];
	$self->{'_triggers'} = {};
	$self->{'_error_messages'} = [];
	$self->{'_current_identifier'} = 0;
	$self->{'_form'} = {};
	$self->{'_form_index'} = [];
	$self->{'_action_index'} = {};
	#use CGI to attempt to set current and next forms.  Forms will set themselves in
	#the first pass of _process_self. NB- subforms can't outclass this.
	$self->{'_next_form'} = $self->dbl->param('_next_form');
	$self->{'_current_form'} =  $self->dbl->param('_current_form');
	$self->{'_last_form'} = undef;
	$self->_interpret_action;
	return;
}

sub _format_output {
	my ($self) = @_;
	#Decide on current and next forms or die trying.
	$self->_raise_exception("One or more FormTemplate objects are required for each form.")
		unless ($self->{'_current_form'});#forms changed this value registering
	if (not(grep {$self->{'_current_form'} eq $_} @{$self->{'_form_index'}})) {#if we've come here from another form
		$self->{'_next_form'} = $self->{'_form_index'}->[0];
		$self->{'_current_form'} = $self->{'_form_index'}->[0];
	}
	unless ($self->{'_next_form'}) {#give cgi a chance to override
		my $last_form = undef;
		foreach my $form (@{$self->{'_form_index'}}) {#otherwise find next in sequence
			$last_form = $self->{'_next_form'};
			$self->{'_next_form'} = $form;
			last if ($last_form eq $self->{'_current_form'});
		}
	}
	$self->_raise_exception("Could not determine what the next form should be.  Use the 'nextform' attribute to name it.")
		unless ($self->{'_next_form'});#catch malformed forms
	$self->_debug('Forms found: ' . $self->{'_current_form'} . " -> " . $self->{'_next_form'});

	#Use the current form as self and process self again.
	$self->_reload_form;

	#Do any preprocessing on widgets
	$self->_activate_widgets;

	#Form::Preload object preloads _variables
	$self->_preload_inputs if (($self->_flags->preload) and not($self->_submitted));
	
	#everything up to this point is all that's needed for a new form.
	return undef unless ($self->_submitted);

	#cover reset events
	return undef if ($self->_check_reset);

	#Start processing the data from CGI.
	$self->_unpack_data;#get storage

	#inputs should now be registered (_reload above), go through them for errors.
	$self->_check_inputs;

	#Check form-wide conditions
	$self->_check_form;

	#Check global conditions
	$self->_check_globals;

	#error -> same form, set errorconditions
	my $error = $self->_check_errors;

	#no error -> next form.  ignore_errors flag overrides error checking and forces next form.
	if ((not($error) or $self->_flags->ignore_errors)) {
		$self->{'_current_form'} = $self->{'_next_form'};
		#last form was decided by the last form to be parsed in the first pass of
		#_process_self.
		if ($self->{'_current_form'} eq $self->{'_last_form'}){
			$self->_submit_data;
			$self->_pack_data if ($self->_flags->continue);
		} else {
			$self->_pack_data;
		}
		$self->_reload_form;
	} else {
		$self->_dispatch_errors;
		$self->_pack_data;
		$self->_fire_triggers;
	}

	return;
}

sub _generate_output {
	my ($self) = @_;
	my (%item) = %{$self->{'_globals'}};
	#fill in placemarkers
	foreach my $child (keys(%{$self->{'_input_index'}})) {
		$self->_verbose("processing input $child :" . $self->{'_input_index'}->{$child} . ' : ' . $self->{'_input'}->[$self->{'_input_index'}->{$child}]->name);
		my $input = $self->{'_input'}->[$self->{'_input_index'}->{$child}];
		my $output = $input->final_output;
		$item{$child} = $output;
	}
	foreach my $child (keys(%{$self->{'_errortag_index'}})) {
		$self->_verbose("processing errortag $child :" . $self->{'_errortag_index'}->{$child} . ' : ' . $self->{'_errortag'}->[$self->{'_errortag_index'}->{$child}]->trigger);
		my $errtag = $self->{'_errortag'}->[$self->{'_errortag_index'}->{$child}];
		my $output = $errtag->final_output;
		$self->_debug($output . ' for ' . $child);
		$item{$child} = $output;
	}
	foreach my $child (keys(%{$self->{'_view_index'}})) {
		$self->_verbose("processing view $child");
		my $view = $self->{'_view'}->[$self->{'_view_index'}->{$child}];
		my $output = $view->final_output($self->{_variables});
		$item{$child} = $output;
	}
	my $out = $self->{_data};
	$out = $self->_text_set(\%item, $out);
	$out = $self->_wrap_form($out);

	#finally, filter out any Input character sequences
	$out =~ s/\x00//g;
	return $out;
}


=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;
