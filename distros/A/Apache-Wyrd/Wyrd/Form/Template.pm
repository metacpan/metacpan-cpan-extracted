#Copyright barry king <barry@wyrdwright.com> and released under the GPL.
#See http://www.gnu.org/licenses/gpl.html#TOC1 for details
use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Form::Template;
our $VERSION = '0.98';
use base qw(Apache::Wyrd);

=pod

=head1 NAME

Apache::Wyrd::Form::Template - Sub-form unit Wyrd

=head1 SYNOPSIS

    <BASENAME::SQLForm index="user_id" table="users">
      <BASENAME::Form::Template name="password">
        <BASENAME::Form::Preload>
          <BASENAME::Defaults>
            select 'root' as user_id;
          </BASENAME::Defaults>
          <BASENAME::Query>
            select user_id from users where name='Groucho'
          </BASENAME::Query>
        </BASENAME::Form::Preload>
        <b>Enter Password:</b><br>
        <BASENAME::Input name="password" type="password" />
        <BASENAME::Input name="user_id" type="hidden" />
      </BASENAME::Form::Template>
      <BASENAME::Form::Template name="result">
        <H1>Status: $:_status</H1>
        <HR>
        <P>$:_message</P>
      </BASENAME::Form::Template>
    </BASENAME::SQLForm>

=head1 DESCRIPTION

Every Form must have at least one Template.  Each Template is arranged
in order by default representing each step in a multiple-page form, with
each Template a step in that sequence.

=head2 HTML ATTRIBUTES

=over

=item name

Name of the form.  Required, and must be different from the name of any
other template.

=item action

What action to perform on the submission of this template.  If set,
changes the sequence of the submission, and can move the flow of
information entry to an entirely different page and continuing the form
sequence from that entry-point.

=back

=head2 PERL METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (scalar) C<action> (void)

(Read-only) Returns the B<action> attribute

=cut

sub action {
	my $self = shift;
	return $self->{'action'};
}

=pod

=item (scalar) C<name> (void)

(Read-only) Returns the B<name> attribute

=cut

sub name {
	my $self = shift;
	return $self->{'name'};
}

=pod

=item (scalar) C<form_body> (void)

(Read-only) Returns the template proper.

=cut

sub form_body {
	my $self = shift;
	return $self->{'_form_body'};
}

=pod

=back

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the _setup and _format_output methods.

=cut

sub _setup {
	my ($self) = @_;
	$self->_raise_exception("Form::Template requires a name") unless ($self->{'name'});
	$self->{'_form_body'} = $self->{'_data'};
	#Parent form processes children if it picks this form as current.
	$self->{'_data'} = undef;
}

sub _format_output {
	my ($self) = @_;
	$self->_raise_exception("Form::Template objects must exist inside a Form object family member which implements the register_form method.")
		unless ($self->{'_parent'}->can('register_form'));
	$self->{'_parent'}->register_form($self);
	#register self as current form unless it's already defined
	#(favor first form in the formprocessor).
	$self->{'_parent'}->{'_current_form'} ||= $self->{'name'};
	$self->{'_parent'}->{'_last_form'} = $self->{'name'};
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
