package AnyEvent::XMPP::Ext::RegisterForm;
use strict;
use AnyEvent::XMPP::Util;
use AnyEvent::XMPP::Namespaces qw/xmpp_ns/;
use AnyEvent::XMPP::Ext::DataForm;
use AnyEvent::XMPP::Ext::OOB;

=head1 NAME

AnyEvent::XMPP::Ext::RegisterForm - Handle for in band registration

=head1 SYNOPSIS

   my $con = AnyEvent::XMPP::Connection->new (...);
   ...
   $con->do_in_band_register (sub {
      my ($form, $error) = @_;
      if ($error) { print "ERROR: ".$error->string."\n" }
      else {
         if ($form->type eq 'simple') {
            if ($form->has_field ('username') && $form->has_field ('password')) {
               $form->set_field (
                  username => 'test',
                  password => 'qwerty',
               );
               $form->submit (sub {
                  my ($form, $error) = @_;
                  if ($error) { print "SUBMIT ERROR: ".$error->string."\n" }
                  else {
                     print "Successfully registered as ".$form->field ('username')."\n"
                  }
               });
            } else {
               print "Couldn't fill out the form: " . $form->field ('instructions') ."\n";
            }
         } elsif ($form->type eq 'data_form' {
            my $dform = $form->data_form;
            ... fill out the form $dform (of type AnyEvent::XMPP::DataForm) ...
            $form->submit_data_form ($dform, sub {
               my ($form, $error) = @_;
               if ($error) { print "DATA FORM SUBMIT ERROR: ".$error->string."\n" }
               else {
                  print "Successfully registered as ".$form->field ('username')."\n"
               }
            })
         }
      }
   });

=head1 DESCRIPTION

This module represents an in band registration form
which can be filled out and submitted.

You can get an instance of this class only by requesting it
from a L<AnyEvent::XMPP::Connection> by calling the C<request_inband_register_form>
method.

=over 4

=item B<new (%args)>

Usually the constructor takes no arguments except when you want to construct
an answer form, then you call the constructor like this:

If you have legacy form fields as a hash ref in C<$filled_legacy_form>:

   AnyEvent::XMPP::Ext::RegisterForm (
      legacy_form => $filled_legacy_form,
      answered => 1
   );

If you have a data form in C<$answer_data_form>:

   AnyEvent::XMPP::Ext::RegisterForm (
      legacy_form => $answer_data_form,
      answered => 1
   );

=cut

sub new {
   my $this = shift;
   my $class = ref($this) || $this;
   my $self = bless { @_ }, $class;
   $self
}

=item B<try_fillout_registration ($username, $password)>

This method tries to fill out a form which was received from the
other end. It enters the username and password and returns a
new L<AnyEvent::XMPP::Ext::RegisterForm> object which is the answer
form.

B<NOTE:> This function is just a heuristic to fill out a form for automatic
registration, but it might fail if the forms are more complex and have
required fields that we don't know.

Registration without user interaction is theoretically not possible because
forms can be different from server to server and require different information.
Please also have a look at XEP-0077.

Note that if the form is more complicated this method will not work
and it's not guranteed that the registration will be successful.

Calling this method on a answer form (where C<is_answer_form> returns true)
will have an undefined result.

=cut

sub try_fillout_registration {
   my ($self, $username, $password) = @_;

   my $form;
   my $nform;

   if (my $df = $self->get_data_form) {
      my $af = AnyEvent::XMPP::Ext::DataForm->new;
      $af->make_answer_form ($df);
      $af->set_field_value (username => $username);
      $af->set_field_value (password => $password);
      $nform = $af;

   } else {
      $form = {
         username => $username,
         password => $password
      };
   }

   return
      AnyEvent::XMPP::Ext::RegisterForm->new (
         data_form   => $nform,
         legacy_form => $form,
         answered    => 1
      );
}

=item B<is_answer_form>

This method will return a true value if this form was returned by eg.
C<try_fillout_registration> or generally represents an answer form.

=cut

sub is_answer_form {
   my ($self) = @_;
   $self->{answered}
}

=item B<is_already_registered>

This method returns true if the received form
were just the current registration data. Basically this method returns
true when you are already registered to the server.

=cut

sub is_already_registered {
   my ($self) = @_;
   exists $self->{legacy_form}
   && exists $self->{legacy_form}->{registered}
}

=item B<get_legacy_form_fields>

This method returns a hash with the keys being the fields
of the legacy form as described in the XML scheme of XEP-0077.

If the form contained just nodes the keys will have undef as value.

If the form contained also register information, in case C<is_already_registered>
returns a true value, the values will contain the strings for the fields.

=cut

sub get_legacy_form_fields {
   my ($self) = @_;
   $self->{legacy_form}
}

=item B<get_data_form>

This method returns the L<AnyEvent::XMPP::Ext::DataForm> that came
with the registration response. If no data form was provided by the
server this method returns undef.

=cut

sub get_data_form {
   my ($self) = @_;
   $self->{data_form}
}


=item B<get_oob>

This method returns a hash like the one returned from
the function C<url_from_node> in L<AnyEvent::XMPP::Ext::OOB>.
It contains the out of band data for this registration form.

=cut

sub get_oob {
   my ($self) = @_;
   $self->{oob}
}

sub init_new_form {
   my ($self, $formnode) = @_;

   my $df = AnyEvent::XMPP::Ext::DataForm->new;
   $df->from_node ($formnode);
   $self->{data_form} = $df;
}

sub _get_legacy_form {
   my ($self, $node) = @_;

   my $form = {};

   my ($qnode) = $node->find_all ([qw/register query/]);

   return $form unless $qnode;

   for ($qnode->nodes) {
      if ($_->eq_ns ('register')) {
         $form->{$_->name} = $_->text;
      }
   }

   $form
}

sub init_from_node {
   my ($self, $node) = @_;

   if (my (@form) = $node->find_all ([qw/register query/], [qw/data_form x/])) {
      $self->init_new_form (@form);
   }
   if (my ($xoob) = $node->find_all ([qw/register query/], [qw/x_oob x/])) {
      $self->{oob} = AnyEvent::XMPP::Ext::OOB::url_from_node ($xoob);
   }
   $self->{legacy_form} = $self->_get_legacy_form ($node);
}

=item B<answer_form_to_simxml>

This method returns a list of C<simxml> nodes.

=cut

sub answer_form_to_simxml {
   my ($self) = @_;

   if ($self->{data_form}) {
      my $sxl = $self->{data_form}->to_simxml;
      return $sxl;

   } else {
      my @childs;

      my $lf = $self->get_legacy_form_fields;

      for (keys %$lf) {
         push @childs, {
            ns     => 'register',
            dns    => 'register',
            name   => $_,
            childs => [ $lf->{$_} ]
         }
      }

      return @childs;
   }
}

=back

=head1 AUTHOR

Robin Redeker, C<< <elmex at ta-sa.org> >>, JID: C<< <elmex at jabber.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007, 2008 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of AnyEvent::XMPP::RegisterForm
