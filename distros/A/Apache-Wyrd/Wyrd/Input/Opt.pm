use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Input::Opt;
our $VERSION = '0.98';
use Apache::Wyrd::Datum;
use base qw(Apache::Wyrd::Interfaces::Setter Apache::Wyrd);
=pod

=head1 NAME

Apache::Wyrd::Input::Opt - Wyrd for passing options to Apache::Wyrd::Input::Set

=head1 SYNOPSIS

see SYNOPSIS for C<Apache::Wyrd::Input::Set>

=head1 DESCRIPTION

Roughly equivalent to the E<lt>optionE<gt> HTML tag, but for
C<Apache::Wyrd::Input::Set> objects, rather than for E<lt>selectE<gt>
tags. Opt provides an option to a Set Input.  The label is given either
as the value attribute or as the enclosed text.  The name attribute is
the value added to the list of values for the affected parameter.

=head2 HTML ATTRIBUTES


Opt accepts most attributes that can be handed to the appropriate HTML
tag, i.e. E<lt>optionE<gt>, E<lt>checkboxE<gt>, or E<lt>radioE<gt>.  These are:

=over

=item *

class

=item *

onchange

=item *

onblur

=item *

onfocus

=item *

disabled

=back

B<disabled> is set if the attribute B<disable> is set to some value or
if the disabled B<flag> is set.  Unlike in some versions of HTML tags,
disabled on its own in a tag does not disable the Opt Wyrd.

=over

=item name

The value this option will represent

=item value

The label this option will have (Optional).  If not set, the label will
be the same as the name.

=item flags

=over

=item break

By default, radio button and checkbox choices override breaking whitespace.
This flag disables that override.

=back

=back

=head2 PERL METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (scalar) C<name> (void)

The option name.

=cut

sub name {
	my($self) = @_;
	return $self->{'name'}
}

=pod

=item (scalar) C<value> (void)

The option label

=cut

sub value {
	my($self) = @_;
	return $self->{'value'}
}

=pod

=item (scalar) C<radiobutton> (void)

Return the template for a radiobutton, based on the attributes given
this Opt.  Called by Apache::Wyrd::Input::Set when making a radiobuttons
interface.

=cut

sub radiobutton {
	my ($self) = @_;
	my $template = q(<nobr><input type="radio" name="$:name" value="$:option"$:option_on?:id{ id="$:id"}?:class{ class="$:class"}?:style{ style="$:style"}?:onchange{ onchange="$:onchange"}?:onfocus{ onfocus="$:onfocus"}?:onblur{ onblur="$:onblur"}?:onclick{ onclick="$:onclick"}?:label{ label="$:label"}?:disabled{ disabled}>$:option_text</input>!:break{</nobr>});
	$self->{'disabled'} = 1 if ($self->_flags->disabled);
	$self->{'break'} = 1 if ($self->_flags->break);
	my %hash = map {$_ => $self->{$_}} qw(id class style onchange onfocus onblur onclick label disabled break);
	return $self->_set(\%hash, $template);
}

=pod

=item (scalar) C<checkbox> (void)

Return the template for a checkbox, based on the attributes given this
Opt.  Called by Apache::Wyrd::Input::Set when making a radiobuttons
interface.

=cut

sub checkbox {
	my ($self) = @_;
	my $template = q(!:break{<nobr>}<input type="checkbox" name="$:name" value="$:option"$:option_on?:id{ id="$:id"}?:class{ class="$:class"}?:style{ style="$:style"}?:onchange{ onchange="$:onchange"}?:onfocus{ onfocus="$:onfocus"}?:onblur{ onblur="$:onblur"}?:onclick{ onclick="$:onclick"}?:label{ label="$:label"}?:disabled{ disabled}>$:option_text</input>!:break{</nobr>});
	$self->{'disabled'} = 1 if ($self->_flags->disabled);
	$self->{'break'} = 1 if ($self->_flags->break);
	my %hash = map {$_ => $self->{$_}} qw(id class style onchange onfocus onblur onclick label disabled break);
	return $self->_set(\%hash, $template);
}

=pod

=item (scalar) C<option> (void)

Return the template for a option, based on the attributes given this
Opt.  Called by Apache::Wyrd::Input::Set when making a radiobuttons
interface.

=cut

sub option {
	my ($self) = @_;
	my $template = q(<option value="$:option"$:option_on?:id{ id="$:id"}?:class{ class="$:class"}?:style{ style="$:style"}?:onchange{ onchange="$:onchange"}?:onfocus{ onfocus="$:onfocus"}?:onblur{ onblur="$:onblur"}?:onclick{ onclick="$:onclick"}?:label{ label="$:label"}?:disabled{ disabled}>$:option_text</option>);
	$self->{'disabled'} = 1 if ($self->_flags->disabled);
	my %hash = map {$_ => $self->{$_}} qw(id class style onchange onfocus onblur onclick label disabled);
	return $self->_set(\%hash, $template);
}

=pod

=back

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the _format_output, _generate_output, and final_output methods.

=cut

#very important -- although a standard <option> uses the value in the place of
#the name, an Opt uses the name as the submitted value.
sub _format_output {
	my ($self) = @_;
	$self->{'value'} ||= ($self->{'_data'});
	$self->_raise_exception("Opt must have at least a name or value") unless ($self->{'name'} or $self->{'value'} or $self->{'name'} =~ /0/);
	$self->_raise_exception("Opt needs to be inside an Input::Set") unless ($self->{'_parent'}->can('register_child'));
	$self->{'_id'} = $self->{'_parent'}->register_child($self);
	$self->{'_template'} = $self->_data;
	return;
}

sub _generate_output {
	my ($self) = @_;
	my $id = $self->{'_id'};
	$self->_raise_exception('No ID provided by form') unless ($id);
	$self->_data('$:' . $id);
}

sub final_output {
	my ($self) = @_;
	return $self->{'_template'};
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