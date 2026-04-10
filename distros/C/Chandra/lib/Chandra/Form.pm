package Chandra::Form;

use strict;
use warnings;

use Chandra ();

our $VERSION = '0.20';

1;

__END__

=head1 NAME

Chandra::Form - Form helpers with two-way binding for Chandra applications

=head1 SYNOPSIS

    use Chandra::Form;

    my $form = Chandra::Form->new(
        id     => 'settings-form',
        action => sub {
            my ($data) = @_;
            # $data = { username => 'alice', theme => 'dark', notify => 1 }
            save_settings($data);
        },
    );

    # Add fields
    $form->text('username', {
        label       => 'Username',
        placeholder => 'Enter username',
        required    => 1,
        value       => 'alice',
        maxlength   => 50,
    });

    $form->password('password', {
        label     => 'Password',
        required  => 1,
        minlength => 8,
    });

    $form->email('email', {
        label => 'Email Address',
        value => 'alice@example.com',
    });

    $form->textarea('bio', {
        label => 'Biography',
        rows  => 4,
        value => 'Hello world',
    });

    $form->select('theme', {
        label   => 'Theme',
        options => [
            { value => 'light', label => 'Light' },
            { value => 'dark',  label => 'Dark' },
            { value => 'auto',  label => 'System' },
        ],
        value => 'dark',
    });

    $form->checkbox('notify', {
        label   => 'Enable notifications',
        checked => 1,
    });

    $form->radio('priority', {
        label   => 'Priority',
        options => [
            { value => 'low',    label => 'Low' },
            { value => 'medium', label => 'Medium' },
            { value => 'high',   label => 'High' },
        ],
        value => 'medium',
    });

    $form->number('font_size', {
        label => 'Font Size',
        min   => 8,
        max   => 72,
        step  => 1,
        value => 14,
    });

    $form->range('volume', {
        label => 'Volume',
        min   => 0,
        max   => 100,
        value => 75,
    });

    $form->hidden('csrf_token', { value => 'abc123' });

    $form->submit('Save Settings');

    # Render to HTML
    my $html = $form->render;

=head1 DESCRIPTION

Chandra::Form provides form building helpers with automatic two-way
data binding between Perl and the DOM for Chandra desktop applications.

Forms are built by chaining field methods, then rendered to HTML via
C<render()>. When used with C<Chandra::App>, the generated JavaScript
handles form submission, change events, and value synchronization
through the Chandra bridge.

=head1 METHODS

=head2 new

    my $form = Chandra::Form->new(
        id     => 'my-form',      # optional, auto-generated if omitted
        action => sub { ... },     # submit handler
        class  => 'custom-class',  # additional CSS class
        app    => $app,            # Chandra::App instance
    );

Create a new form builder. The C<action> coderef receives a hashref of
form data when the form is submitted.

=head2 text

    $form->text('username', {
        label       => 'Username',
        placeholder => 'Enter name',
        value       => 'default',
        required    => 1,
        maxlength   => 100,
        minlength   => 3,
        pattern     => '[A-Za-z0-9]+',
        disabled    => 0,
        readonly    => 0,
        autofocus   => 1,
        class       => 'custom',
    });

Add a text input field. All option keys are optional. Returns C<$self>
for chaining.

=head2 password

    $form->password('pass', { label => 'Password', required => 1 });

Add a password input field. Same options as C<text()>.

=head2 email

    $form->email('email', { label => 'Email', value => 'a@b.com' });

Add an email input field. Same options as C<text()>.

=head2 textarea

    $form->textarea('bio', {
        label => 'Biography',
        rows  => 4,
        cols  => 60,
        value => 'Hello',
    });

Add a textarea field. Accepts C<rows> and C<cols> in addition to
standard options.

=head2 select

    $form->select('theme', {
        label   => 'Theme',
        options => [
            { value => 'light', label => 'Light' },
            { value => 'dark',  label => 'Dark', disabled => 1 },
        ],
        value => 'dark',
    });

Add a dropdown select field. C<options> is an arrayref of hashrefs,
each with C<value> and C<label> keys. An option can be C<disabled>.

=head2 checkbox

    $form->checkbox('agree', {
        label   => 'I agree to the terms',
        checked => 1,
        value   => 'yes',   # defaults to "1"
    });

Add a checkbox. The label appears I<after> the checkbox. Serialized
as C<1>/C<0> in form data.

=head2 radio

    $form->radio('priority', {
        label   => 'Priority',
        options => [
            { value => 'low',  label => 'Low' },
            { value => 'high', label => 'High' },
        ],
        value => 'low',
    });

Add a radio button group. C<options> and C<value> work like C<select()>.

=head2 number

    $form->number('qty', { label => 'Quantity', min => 1, max => 99, step => 1 });

Add a numeric input. Accepts C<min>, C<max>, and C<step>.

=head2 range

    $form->range('volume', { label => 'Volume', min => 0, max => 100, value => 50 });

Add a range slider. Same numeric options as C<number()>.

=head2 hidden

    $form->hidden('token', { value => 'secret' });

Add a hidden field. No label or error placeholder is rendered.

=head2 submit

    $form->submit('Save');

Set the submit button label. Defaults to C<"Submit">.

=head2 group

    $form->group('Appearance' => sub {
        $form->select('theme', { ... });
        $form->number('font_size', { ... });
    });

Wrap fields in a C<< <fieldset> >> with a C<< <legend> >>.

=head2 render

    my $html = $form->render;

Render the form to an HTML string. Each field is wrapped in a
C<< <div class="chandra-field"> >> with a label and error placeholder.

=head2 bind_js

    my $js = $form->bind_js;

Returns JavaScript that intercepts form submit and change/input events,
sending data to Perl via C<window.chandra.invoke()>.

=head2 attach

    $form->attach($app);

Register this form with the global form registry and bind the bridge
events (C<_form_submit>, C<_form_change>, C<_form_input>,
C<_form_values>) on the given L<Chandra::App>.  The binding JS is
automatically injected via C<dispatch_eval>.

Multiple forms can be attached to the same app; each submit/change
event is routed to the correct form by its C<id>.

=head2 detach

    $form->detach;

Remove this form from the global registry.  Future bridge events
for this form's id will be silently ignored.

=head2 set_values_js

    my $js = $form->set_values_js({ username => 'bob', theme => 'light' });

Returns JavaScript that sets DOM field values from a hashref.

=head2 get_values_js

    my $js = $form->get_values_js;

Returns JavaScript that reads current form values and sends them via bridge.

=head2 show_errors_js

    my $js = $form->show_errors_js({ username => 'Required' });

Returns JavaScript that displays error messages next to fields.

=head2 clear_errors_js

    my $js = $form->clear_errors_js;

Returns JavaScript that clears all error messages.

=head2 on_change

    # Global handler - called for any field change
    $form->on_change(sub {
        my ($field, $value) = @_;
        print "$field changed to: $value\n";
    });

    # Field-specific handler
    $form->on_change('theme', sub {
        my ($value) = @_;
        apply_theme($value);
    });

Register change event handlers. Field-specific handlers receive just
the value; global handlers receive field name and value.

=head2 dispatch

    $form->dispatch('_form_submit', $json_string);

Internal method called by the Chandra bridge to dispatch events.
Not intended for direct use.

=head2 field_count

    my $count = $form->field_count;

Returns the number of fields added to the form.

=head2 id

    my $id = $form->id;

Returns the form's HTML id attribute.

=head2 fields

    my $names = $form->fields;   # ['username', 'email', 'theme']

Returns an arrayref of field names in order.

=head2 action

    $form->action(sub { ... });  # set
    my $cb = $form->action;      # get

Get or set the form submit action handler.

=head1 CSS CLASSES

The generated HTML uses these CSS classes for styling:

    .chandra-form              — the <form> element
    .chandra-field             — wrapper <div> around each field
    .chandra-field-checkbox    — checkbox field wrapper
    .chandra-field-radio       — radio group wrapper
    .chandra-field-submit      — submit button wrapper
    .chandra-label             — <label> elements
    .chandra-submit            — submit <button>
    .chandra-error             — error message <span>
    .chandra-group             — <fieldset> from group()
    .chandra-radio-option      — individual radio <div>

=head1 SEE ALSO

L<Chandra>, L<Chandra::Element>, L<Chandra::App>, L<Chandra::Bind>

=head1 AUTHOR

LNATION E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
