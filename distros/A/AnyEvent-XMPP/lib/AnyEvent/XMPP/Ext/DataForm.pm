package AnyEvent::XMPP::Ext::DataForm;
use strict;
use AnyEvent::XMPP::Namespaces qw/xmpp_ns/;

=head1 NAME

AnyEvent::XMPP::Ext::DataForm - XEP-0004 DataForm

=head1 SYNOPSIS

=head1 DESCRIPTION

This module represents a Data Form as specified in XEP-0004.

=head1 METHODS

=over 4

=item B<new (%args)>

=cut

sub new {
   my $this = shift;
   my $class = ref($this) || $this;
   my $self = bless { @_ }, $class;
   $self->init;
   $self
}

sub init {
   my ($self) = @_;
   $self->{fields}    = [];
   $self->{field_var} = {};
   $self->{items}     = [];
   $self->{reported}  = [];
   delete $self->{type};
   delete $self->{title};
   delete $self->{instructions};
}

=item B<append_field ($field)>

This method appends a field to the form.
C<$field> must have the structure as described in L<FIELD STRUCTURE> below.

=cut

sub append_field {
   my ($self, $field) = @_;
   $self->{fields}    = [] unless $self->{fields};
   $self->{field_var} = {} unless $self->{field_var};
   push @{$self->{fields}}, $field;
   $self->{field_var}->{$field->{var}} = $field if defined $field->{var};
}

=item B<from_node ($node)>

This method interprets the L<AnyEvent::XMPP::Node> object in C<$node> as
data form XML node and reads out the fields and all associated information.

(C<$node> must be the XML node of the <x xmlns='jabber:x:data'> tag).

=cut

sub _extract_field {
   my ($field) = @_;

   my $fo = {
      label => $field->attr ('label'),
      var   => $field->attr ('var'),
      type  => $field->attr ('type'),
   };

   my ($desc) = $field->find_all ([qw/data_form desc/]);
   if ($desc) {
      $fo->{desc} = $desc->text;
   }
   if ($field->find_all ([qw/data_form required/])) {
      $fo->{required} = 1;
   }
   my (@vals) = $field->find_all ([qw/data_form value/]);
   $fo->{values} = [];
   for (@vals) {
      push @{$fo->{values}}, $_->text;
   }
   my (@opts) = $field->find_all ([qw/data_form option/]);
   $fo->{options} = [];
   for my $o (@opts) {
      my (@v) = $o->find_all ([qw/data_form value/]);
      my $vals = [];
      for my $val (@v) {
         push @$vals, $val->text;
      }
      push @{$fo->{options}}, [$o->attr ('label'), $vals];
   }

   $fo
}

sub from_node {
   my ($self, $node) = @_;

   $self->init;

   my ($title) = $node->find_all ([qw/data_form title/]);
   my ($instr) = $node->find_all ([qw/data_form instructions/]);

   $self->{type}         = $node->attr ('type');
   $self->{title}        = $title->text if $title;
   $self->{instructions} = $instr->text if $instr;

   for my $field ($node->find_all ([qw/data_form field/])) {
      my $fo = _extract_field ($field);
      $self->append_field ($fo);
   }

   my ($rep) = $node->find_all ([qw/data_form reported/]);
   if ($rep) {
      for my $field ($rep->find_all ([qw/data_form field/])) {
         my $fo = {
            label => $field->attr ('label'),
            var   => $field->attr ('var'),
            type  => $field->attr ('type'),
         };
         push @{$self->{reported}}, $fo;
      }
   }

   for my $item ($node->find_all ([qw/data_form item/])) {
      my $flds = [];
      for my $field ($item->find_all ([qw/data_form field/])) {
         my $fo = _extract_field ($field);
         push @$flds, $fo;
      }
      push @{$self->{items}}, $flds;
   }
}

=item B<make_answer_form ($request_form)>

This method initializes this form with default answers and
other neccessary fields from C<$request_form>, which must be
of type L<AnyEvent::XMPP::Ext::DataForm> or compatible.

The result will be a form with a copy of all fields which are not of
type C<fixed>. The fields will also have the default value copied over.

The form type will be set to C<submit>.

The idea is: this creates a template answer form from C<$request_form>.

To strip out the unneccessary fields later you don't need call the
C<clear_empty_fields> method.

=cut

sub make_answer_form {
   my ($self, $reqform) = @_;

   $self->set_form_type ('submit');

   for my $field ($reqform->get_fields) {
      next if $field->{type} eq 'fixed';

      my $fo = {
         var     => $field->{var},
         type    => $field->{type},
         values  => [ @{$field->{values}} ],
         options => [],
      };

      $self->append_field ($fo);
   }
}

=item B<clear_empty_fields>

This method removes all fields that have no values and options.

=cut

sub clear_empty_fields {
   my ($self) = @_;

   my @dead;
   for ($self->get_fields) {
      unless (@{$_->{values}} || @{$_->{options}}) {
         push @dead, $_;
      }
   }
   $self->remove_field ($_) for @dead;
}

=item B<remove_field ($field_or_var)>

This method removes a field either by it's unique name or
by reference. C<$field_or_var> can either be the unique name or
the actual field hash reference you get from C<get_field> or C<get_fields>.

=cut

sub remove_field {
   my ($self, $field) = @_;
   unless (ref $field) {
      $field = $self->get_field ($field) or return;
   }
   @{$self->{fields}} = grep { $_ ne $field } @{$self->{fields}};
   if (defined $field->{var}) {
      delete $self->{field_var}->{$field->{var}};
   }
}

=item B<set_form_type ($type)>

This method sets the type of the form, which must be one of:

   form, submit, cancel, result

=cut

sub set_form_type {
   my ($self, $type) = @_;
   $self->{type} = $type;
}

=item B<form_type>

This method returns the type of the form, which is one of the
options described in C<set_form_type> above or undef if no type
was yet set.

=cut

sub form_type { return $_[0]->{type} }

=item B<get_reported_fields>

If this is a search result this method returns more than one element
here. The returned list consists of fields as described in L<FIELD STRUCTURE>,
only that they lack values and options.

See also the C<get_items> method.

=cut

sub get_reported_fields {
   my ($self) = @_;
   @{$self->{reported}}
}

=item B<get_items>

If this form is a search result this method returns the list of
items of that search.

An item is a array ref of fields (field structure is described in L<FIELD STRUCTURE>).
This method returns a list of items.

=cut

sub get_items {
   my ($self) = @_;
   @{$self->{items}};
}

=item B<get_fields>

This method returns a list of fields. Each field has the structure as described
in L<FIELD STRUCTURE>.

=cut

sub get_fields {
   my ($self) = @_;
   @{$self->{fields}}
}

=item B<get_field ($var)>

Returns the field with the unique field name C<$var> or
undef if no such field is in this form.

=cut

sub get_field {
   my ($self, $var) = @_;
   $self->{field_var}->{$var}
}

=item B<set_field_value ($var, $value)>

This method sets the value of the field with the unique name C<$var>.
If the field has supports multiple values all values will be removed
and only C<$value> will be added, if C<$value> is undefined the field's
value will be deleted.

=cut

sub set_field_value {
   my ($self, $var, $val) = @_;
   my $f = $self->get_field ($var) or return;
   $f->{values} = defined $val ? [ $val ] : [];
}

=item B<add_field_value ($var, $value)>

This method adds the C<$value> to the field with the unique name C<$var>.
If the field doesn't support multiple values this method has the same
effect as C<set_field_value>.

=cut

sub add_field_value {
   my ($self, $var, $val) = @_;
   my $f = $self->get_field ($var) or return;
   if (grep { $f->{type} eq $_ } qw/jid-multi list-multi text-multi/) {
      push @{$f->{values}}, $val;
   } else {
      $self->set_field_value ($var, $val);
   }
}

=item B<to_simxml>

This method converts the form to a data strcuture
that you can pass as C<node> argument to the C<simxml>
function which is documented in L<AnyEvent::XMPP::Util>.

Example call might be:

   my $node = $form->to_simxml;
   simxml ($w, defns => $node->{ns}, node => $node);

B<NOTE:> The returned simxml node has the C<dns> field set
so that no prefixes are generated for the namespace it is in.

=cut

sub _field_to_simxml {
   my ($f) = @_;

   my $ofa = [];
   my $ofc = [];
   my $of = { name => 'field', attrs  => $ofa, childs => $ofc };

   push @$ofa, (label => $f->{label}) if defined $f->{label};
   push @$ofa, (var   => $f->{var})   if defined $f->{var};
   push @$ofa, (type  => $f->{type})  if defined $f->{type};

   for (@{$f->{values}}) {
      push @$ofc, { name => 'value', childs => [ $_ ] }
   }

   for (@{$f->{options}}) {
      my $at = [];
      my $chlds = [];
      push @$ofc, {
         name => 'option', attrs => $at, childs => $chlds
      };
      for (@{$_->[1]}) {
         push @$chlds, { name => 'value', childs => [ $_ ] }
      }
      if (defined $_->[0]) { push @$at, (label => $_->[0]) }
   }

   if ($f->{desc}) {
      push @$ofc, { name => 'desc', childs => [ $f->{desc} ] }
   }

   if ($f->{required}) {
      push @$ofc, { name => 'required' }
   }

   $of
}

sub to_simxml {
   my ($self) = @_;

   my $fields = [];
   my $top = {
      ns     => 'data_form',
      dns    => 'data_form',
      name   => 'x',
      attrs  => [],
      childs => $fields,
   };

   push @{$top->{attrs}}, ( type => $self->{type} );

   if (defined $self->{title}) {
      push @$fields, {
         name => 'title', childs => [ $self->{title} ]
      }
   }

   if (defined $self->{instructions}) {
      push @$fields, {
         name => 'instructions', childs => [ $self->{instructions} ]
      }
   }

   for my $f ($self->get_fields) {
      push @$fields, _field_to_simxml ($f);
   }

   my $repchld = [];
   for my $rf ($self->get_reported_fields) {
      push @$repchld, _field_to_simxml ($rf);
   }

   if (@$repchld) {
      push @$fields, {
         name => 'reported',
         childs => $repchld
      };
   }

   for my $itf ($self->get_items) {
      my $itfields = [];

      for my $f (@$itf) {
         push @$itfields, _field_to_simxml ($f);
      }

      push @$fields, {
         name => 'item',
         childs => $itfields
      }
   }

   $top
}

=item B<as_debug_string>

This method returns a string that represents the form.
Only for debugging purposes.

=cut

sub as_debug_string {
   my ($self) = @_;

   my $str;
   $str .= "title: $self->{title}\n"
          ."instructions: $self->{instructions}\n"
          ."type: $self->{type}\n";
   for my $f ($self->get_fields) {
      $str .= sprintf "- var : %-50s label: %s\n  type: %-10s required: %d\n",
                 $f->{var}, $f->{label}, $f->{type}, $f->{required};
      for (@{$f->{values}}) {
         $str .= sprintf "     * val    : %s\n", $_
      }
      for (@{$f->{options}}) {
         $str .= sprintf "     * opt lbl: %-50s text: %s\n", @$_
      }
   }

   $str .= "reported:\n";
   for my $f (@{$self->{reported}}) {
      $str .= sprintf "- var: %-50s label: %-30s type: %-10s %d\n",
                    $f->{var}, $f->{label}, $f->{type};
   }

   $str .= "items:\n";
   for my $i (@{$self->{items}}) {
      $str .= "-" x 60 . "\n";
      for my $f (@$i) {
         $str .= sprintf "- var : %-50s\n", $f->{var};
         for (@{$f->{values}}) {
            $str .= sprintf "     * val    : %s\n", $_
         }
         for (@{$f->{options}}) {
            $str .= sprintf "     * opt lbl: %-50s text: %s\n", @$_
         }
      }
   }

   $str
}

=back

=head1 FIELD STRUCTURE

   {
      label    => 'field label',
      type     => 'field type',
      var      => '(unique) field name'
      required => true or false value,
      values   => [
         'value text',
         ...
      ],
      options  => [
         ['option label', 'option text'],
         ...
      ]
   }

For the semantics of all fields please consult XEP 0004.

=head1 SEE ALSO

   XEP 0004

=head1 AUTHOR

Robin Redeker, C<< <elmex at ta-sa.org> >>, JID: C<< <elmex at jabber.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007, 2008 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
