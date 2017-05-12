use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Input::Set;
our $VERSION = '0.98';
use Apache::Wyrd::Datum;
use base qw(
	Apache::Wyrd::Interfaces::Mother
	Apache::Wyrd::Interfaces::Setter
	Apache::Wyrd::Input
);
use Apache::Wyrd::Services::SAK qw(token_parse sort_by_ikey);

=pod

=head1 NAME

Apache::Wyrd::Input::Set - Form Input Wyrds (array)

=head1 SYNOPSIS

    <BASENAME::Input::Set name="numbers"
      type="pulldown" options="one, two, three" />

    <BASENAME::Input::Set name="numbers" type="selections"
      hash_options="one, One, two, Two, three, Three" />

    <BASENAME::Input::Set name="numbers" type="checkboxes">
      <BASENAME::Input::Opt name="one" value="One" />
      <BASENAME::Input::Opt name="two" value="Two" />
      <BASENAME::Input::Opt name="three" value="Three" />
    </BASENAME::Input::Set>

    <BASENAME::Input::Set name="numbers" type="radiobuttons">
      <BASENAME::Input::Opt name="one">One</BASENAME::Input::Opt>
      <BASENAME::Input::Opt name="two">Two</BASENAME::Input::Opt>
      <BASENAME::Input::Opt name="three">Three</BASENAME::Input::Opt>
    </BASENAME::Input::Set>

=head1 DESCRIPTION

The Set Input extends the regular input to handle the parameters of
multiple values.  This module designs _startup_foo where foo is:

=over

=item *

A set of check-boxes

=item *

A pull-down menu of items

=item *

A set of radio-buttons

=item *

A box of selections

=back

For these, set the type attribute to B<checkboxes>, B<pulldown>,
B<radiobuttons>, and B<selections> respectively.  see
C<Apache::Wyrd::Input::Set>.

=head2 HTML ATTRIBUTES

As with C<Apache::Wyrd::Input>, most attributes that can be set for the
corresponding HTML tags these Wyrds generate can be set, such as
B<class> and B<onfocus>.

=over

=item emptyname

What to call the null option, or the empty value.  Defaults to the null
string.

=item options

When not using C<Apache::Wyrd::Input::Opt> objects to populate the
selection, a comma/whitespace-delimited set of options can be given
instead.

=item hash_options

When not using C<Apache::Wyrd::Input::Opt> objects to populate the
selection, a comma-delimited hash of options can be given instead.  The
sequence is param value, param label, param value, param label....

=item delimiter

Override the default behavior for parsing options or hash_options by
using the indicated regexp as delimiter.  Defaults to commas if there
are any or whitespace if not.

=item flags

=over

=item noauto

Do not automatically format the opt area, but allow the options and the HTML
around them to remain.  This allows manual layout of checkboxes, etc.  This
implies "nosort".

=item nosort

Do not sort the options.

=item noempty

Do not generate the empty option "" on pulldown menus.

=item emptyname

Generate the empty option on pulldown menus, but give it this name, for example
"None".

=back

=back

=head2 PERL METHODS

see C<Apache::Wyrd::Input>

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the _generate_output, final_output, and _process_child methods.

=cut

sub _generate_output {
	my ($self) = @_;
	$self->_set_children;
	my $id = $self->{'_id'};
	$self->_raise_exception('No ID provided by form') unless ($id);
	#the template is imported from the enclosed text if auto-fill of options is off
	$self->{'_template'} = $self->_data if ($self->_flags->noauto);
	$self->_data('$:' . $id);
}

sub final_output {
	my ($self) = @_;
	my (%values) = ();
	foreach my $value (keys %{$self}) {
		next if ($value =~ /^_.+[^_]$/);
		$values{$value} = $self->{$value};
	}
	my $value = $values{'value'};
	delete($values{'value'});
	my $effective_value = $value;
	if (ref($effective_value) eq 'ARRAY') {
		my @values = @$effective_value;
		$effective_value = grep{defined($_)} @values;
	}
	unless ($effective_value or ($value eq '0') or $self->_flags->reset) {
		my ($attempt, $success) = $self->{'_parent'}->_get_value($self->{'name'});
		if ($self->{'_check_null_submit'}) {
			if ($self->dbl->param('_being_submitted_' . $self->{'name'})) {
				$self->{'_parent'}->{'_variables'}->{$self->{'name'}} = undef;
			}
		}
		$value = $attempt;
		$value ||= $self->{'_parent'}->{'_variables'}->{$self->{'name'}};
		$value ||= ($self->{'_multiple'} ? [token_parse($self->{'default'})] : $self->{'default'}) || ($self->{'_multiple'} ? [] : '');
	}
	if ($self->{'_multiple'}) {
		$value = [$value] if (ref($value) ne 'ARRAY');
		foreach my $option (@{$value}) {
			$values{'_' . $option . '_on_'} = $self->{'_on_button'};
		}
	} else {
		$value = shift(@{$value}) if (ref($value) eq 'ARRAY');
		$values{'_' . $value . '_on_'} = $self->{'_on_button'};
	}
	return ($self->_set(\%values, $self->{'_template'}));
}

sub _process_child {
	my ($self, $child) = @_;
	my $name = (defined($child->name) ? $child->name : $child->value);
	my $value = (defined($child->value) ? $child->value : $child->name);
	$self->{'_options'}->{$name} = $value;
}

=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=item Apache::Wyrd::Input::Opt

Options of the multi-value Input.

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

sub _parse_options {
	my ($self) = @_;
	$self->SUPER::_parse_options;
	my $options = $self->{'options'};
	if (ref($options) eq 'ARRAY') {
		use Apache::Wyrd::Input::Opt;
		foreach my $option (@$options) {
			my $object = Apache::Wyrd::Input::Opt->new($self->dbl, {value => $option});
			$self->register_child($object);
		}
	} elsif (ref($options) eq 'HASH') {
		use Apache::Wyrd::Input::Opt;
		my ($name, $value) = ();
		while (($name, $value) = each %$options) {
			my $object = Apache::Wyrd::Input::Opt->new($self->dbl, {name => $name, value => $value});
			$self->register_child($object);
		}
	} else {
		$self->_info('No valid options given');
	}
}

sub _startup_radiobuttons {
	my ($self, $value, $params) = @_;
	$self->{'_check_null_submit'} = 1;
	$self->{'_on_button'} = ' checked';
	$params->{'options'} = [keys(%{$self->{'_options'}})];
	$self->{'_datum'} ||= (Apache::Wyrd::Datum::Enum->new($value, $params));
	$self->{'sort'} ||= 'value';
	my @sort = token_parse($self->{'sort'});
	my $name = $self->name;
	my $template = qq(<input type="hidden" name="_being_submitted_$name" value="1">);
	my $emptyname = $self->{'emptyname'};
	my $emptyclass = $self->{'emptyclass'};
	my $emptystyle = $self->{'emptystyle'};
	my @objects = @{$self->{'_children'}};
	unless ($self->_flags->nosort) {
		@objects = sort {sort_by_ikey($a, $b, @sort)} @objects;
	}
	if ($emptyname and not($self->_flags->noauto)) {
		#pre-layed-out checkbox options should include their own empty option.
		if (UNIVERSAL::can($self->{'_children'}->[0], 'clone')) {
			my $object = $self->{'_children'}->[0]->clone;
			if ($object->can('radiobutton')) {
				$object->{'value'} = $emptyname;
				$object->{'class'} = $emptyclass;
				$object->{'style'} = $emptystyle;
				$object->{'name'} = '';
				$self->_process_child($object);
				unshift @objects, $object;
			} else {
				$self->_error(ref($object) . ' object cannot make a radiobutton for the requested emptyname');
			}
		}
	}
	foreach my $object (@objects) {
		my $option = ($object->name || ($object->name eq '0'? '0' : $self->{'_options'}->{$object->value}));
		my $option_on = '$:_' . $option . '_on_';
		$self->{'_' . $option . '_on_'} = undef;
		if ($self->_flags->noauto) {
			$object->{'_template'} = $self->_set({option => $option, option_on => $option_on, option_text => $self->{_options}->{$option}}, $object->radiobutton);
		} else {
			$template .= $self->_set({option => $option, option_on => $option_on, option_text => $self->{_options}->{$option}}, $object->radiobutton);
		}
	}
	if ($self->_flags->noauto) {
		$self->{'_template'} = $self->_data;
	} else {
		$self->{'_template'} = $template;
	}
}

sub _startup_checkboxes {
	my ($self, $value, $params) = @_;
	$self->{'_multiple'} = 1;
	$self->{'_check_null_submit'} = 1;
	$self->{'_on_button'} = ' checked';
	$params->{'options'} = [keys(%{$self->{'_options'}})];
	$self->{'_datum'} ||= (Apache::Wyrd::Datum::Set->new($value, $params));
	$self->{'sort'} ||= 'value';
	my @sort = token_parse($self->{'sort'});
	my $name = $self->name;
	my $template = qq(<input type="hidden" name="_being_submitted_$name" value="1">);
	my $emptyname = $self->{'emptyname'};
	my $emptyclass = $self->{'emptyclass'};
	my $emptystyle = $self->{'emptystyle'};
	$self->_raise_exception("You must define some options") unless (@{$self->{'_children'} || []});
	my @objects = @{$self->{'_children'}};
	unless ($self->_flags->nosort) {
		@objects = sort {sort_by_ikey($a, $b, @sort)} @objects;
	}
	if ($emptyname and not($self->_flags->noauto)) {
		#pre-layed-out checkbox options should include their own empty option.
		if (UNIVERSAL::can($self->{'_children'}->[0], 'clone')) {
			my $object = $self->{'_children'}->[0]->clone;
			if ($object->can('checkbox')) {
				$object->{'name'} = $emptyname;
				$object->{'class'} = $emptyclass;
				$object->{'style'} = $emptystyle;
				$object->{'value'} = '';
				$self->_process_child($object);
				unshift @objects, $object;
			} else {
				$self->_error(ref($object) . ' object cannot make a checkbox for the requested emptyname');
			}
		}
	}
	foreach my $object (@objects) {
		my $option = ($object->name || ($object->name eq '0' ? '0' : $self->{'_options'}->{$object->value}));
		my $option_on = '$:_' . $option . '_on_';
		$self->{'_' . $option . '_on_'} = undef;
		if ($self->_flags->noauto) {
			$object->{'_template'} = $self->_set({option => $option, option_on => $option_on, option_text => $self->{_options}->{$option}}, $object->checkbox);
		} else {
			$template .= $self->_set({option => $option, option_on => $option_on, option_text => $self->{_options}->{$option}}, $object->checkbox);
		}
	}
	if ($self->_flags->noauto) {
		$self->{'_data'} = $template . $self->_data;
	} else {
		$self->{'_template'} = $template;
	}
}

sub _startup_selection {
	my ($self, $value, $params) = @_;
	$self->{'_multiple'} = 1;
	$self->{'_on_button'} = ' selected';
	$params->{'options'} = [keys(%{$self->{'_options'}})];
	$self->{'_datum'} ||= (Apache::Wyrd::Datum::Set->new($value, $params));
	$self->{'sort'} ||= 'value';
	my @sort = token_parse($self->{'sort'});
	my $emptyname = $self->{'emptyname'};
	my $emptyclass = $self->{'emptyclass'};
	my $emptystyle = $self->{'emptystyle'};
	my $template = '';
	my @objects = @{$self->{'_children'}};
	unless ($self->_flags->nosort) {
		@objects = sort {sort_by_ikey($a, $b, @sort)} @objects;
	}
	if ($emptyname) {
		if (UNIVERSAL::can($self->{'_children'}->[0], 'clone')) {
			my $object = $self->{'_children'}->[0]->clone;
			if ($object->can('option')) {
				$object->{'value'} = $emptyname;
				$object->{'class'} = $emptyclass;
				$object->{'style'} = $emptystyle;
				$object->{'name'} = '';
				$self->_process_child($object);
				unshift @objects, $object;
			} else {
				$self->_error(ref($object) . ' object cannot make a selection for the requested emptyname');
			}
		}
	}
	foreach my $object (@objects) {
		my $option = ($object->name || ($object->name eq '0' ? '0' : $self->{'_options'}->{$object->value}));
		my $option_on = '$:_' . $option . '_on_';
		$self->{'_' . $option . '_on_'} = undef;
		$template .= $self->_set({option => $option, option_on => $option_on, option_text => $self->{_options}->{$option}}, $object->option);
	}
	my $additional = '?:size{ size="$:id"}?:id{ id="$:id"}?:class{ class="$:class"}?:style{ style="$:style"}?:onchange{ onchange="$:onchange"}?:onselect{ onselect="$:onselect"}?:onblur{ onblur="$:onblur"}?:onfocus{ onfocus="$:onfocus"}?:disabled{ disabled}';
	my %hash = map {$_ => $self->{$_}} qw(size id class onchange onselect onblur onfocus disabled);
	$additional = $self->_set(\%hash, $additional);
	$self->{'_template'} = qq(<select name="\$:name"$additional multiple>\n$template\n</select>);
}

sub _startup_pulldown {
	my ($self, $value, $params) = @_;
	$self->{'_on_button'} = ' selected';
	$params->{'options'} = [keys(%{$self->{'_options'}})];
	$self->{'_datum'} ||= (Apache::Wyrd::Datum::Enum->new($value, $params));
	$self->{'sort'} ||= 'name';
	my @sort = token_parse($self->{'sort'});
	my $emptyname = $self->{'emptyname'};
	my $emptyclass = $self->{'emptyclass'};
	if ($emptyclass) {
		$emptyclass = qq( class="$emptyclass")
	}
	my $emptystyle = $self->{'emptystyle'};
	if ($emptystyle) {
		$emptystyle = qq( style="$emptystyle")
	}
	my $template = qq(<option value=""$emptyclass$emptystyle>$emptyname</option>);
	$template = '' if ($self->_flags->noempty);
	my @objects = @{$self->{'_children'}};
	unless ($self->_flags->nosort) {
		@objects = sort {sort_by_ikey($a, $b, @sort)} @objects;
	}
	foreach my $object (@objects) {
		my $option = ($object->name || ($object->name eq '0' ? '0' : $self->{'_options'}->{$object->value}));
		my $option_on = '$:_' . $option . '_on_';
		$self->{'_' . $option . '_on_'} = undef;
		$template .= $self->_set({option => $option, option_on => $option_on, option_text => $object->value}, $object->option);
	}
	my $additional = '?:size{ size="$:size"}?:id{ id="$:id"}?:class{ class="$:class"}?:style{ style="$:style"}?:onchange{ onchange="$:onchange"}?:onselect{ onselect="$:onselect"}?:onblur{ onblur="$:onblur"}?:onfocus{ onfocus="$:onfocus"}?:disabled{ disabled}?:_multiple{ multiple}';
	my %hash = map {$_ => $self->{$_}} qw(size id class onchange onselect onblur onfocus disabled _multiple);
	$additional = $self->_set(\%hash, $additional);
	$self->{'_template'} = qq(<select name="\$:name"$additional>\n$template\n</select>);
}

sub null_ok {
	my ($self) = @_;
	return $self->{'_check_null_submit'};
}

1;