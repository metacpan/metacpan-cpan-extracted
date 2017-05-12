package AnyEvent::XMPP::Ext::Registration;
use strict;
use AnyEvent::XMPP::Util;
use AnyEvent::XMPP::Namespaces qw/xmpp_ns/;
use AnyEvent::XMPP::Ext::RegisterForm;

=head1 NAME

AnyEvent::XMPP::Ext::Registration - Handles all tasks of in band registration

=head1 SYNOPSIS

   my $con = AnyEvent::XMPP::Connection->new (...);

   $con->reg_cb (stream_pre_authentication => sub {
      my ($con) = @_;
      my $reg = AnyEvent::XMPP::Ext::Registration->new (connection => $con);

      $reg->send_registration_request (sub {
         my ($reg, $form, $error) = @_;

         if ($error) {
            # error handling

         } else {
            my $af = $form->try_fillout_registration ("tester", "secret");

            $reg->submit_form ($af, sub {
               my ($reg, $ok, $error, $form) = @_;

               if ($ok) { # registered successfully!
                  $con->authenticate

               } else {   # error
                  if ($form) { # we got an alternative form!
                     # fill it out and submit it with C<submit_form> again
                  }
               }
            });
         }
      });

      0
   });

=head1 DESCRIPTION

This module handles all tasks of in band registration that are possible and
specified by XEP-0077. It's mainly a helper class that eases some tasks such
as submitting and retrieving a form.

=cut

=head1 METHODS

=over 4

=item B<new (%args)>

This is the constructor for a registration object.

=over 4

=item connection

This must be a L<AnyEvent::XMPP::Connection> (or some other subclass of that) object.

This argument is required.

=back

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
   #...
}

=item B<send_registration_request ($cb)>

This method sends a register form request.
C<$cb> will be called when either the form arrived or
an error occured.

The first argument of C<$cb> is always C<$self>.
If the form arrived the second argument of C<$cb> will be
a L<AnyEvent::XMPP::Ext::RegisterForm> object.
If an error occured the second argument will be undef
and the third argument will be a L<AnyEvent::XMPP::Error::Register>
object.

For hints how L<AnyEvent::XMPP::Ext::RegisterForm> should be filled
out look in XEP-0077. Either you have legacy form fields, out of band
data or a data form.

See also L<try_fillout_registration> in L<AnyEvent::XMPP::Ext::RegisterForm>.

=cut

sub send_registration_request {
   my ($self, $cb) = @_;

   my $con = $self->{connection};

   $con->send_iq (get => {
      defns => 'register',
      node => { ns => 'register', name => 'query' }
   }, sub {
      my ($node, $error) = @_;

      my $form;
      if ($node) {
         $form = AnyEvent::XMPP::Ext::RegisterForm->new;
         $form->init_from_node ($node);
      } else {
         $error =
            AnyEvent::XMPP::Error::Register->new (
               node => $error->xml_node, register_state => 'register'
            );
      }

      $cb->($self, $form, $error);
   });
}

sub _error_or_form_cb {
   my ($self, $e, $cb) = @_;

   $e = $e->xml_node;

   my $error =
      AnyEvent::XMPP::Error::Register->new (
         node => $e, register_state => 'submit'
      );

   if ($e->find_all ([qw/register query/], [qw/data_form x/])) {
      my $form = AnyEvent::XMPP::Ext::RegisterForm->new;
      $form->init_from_node ($e);

      $cb->($self, 0, $error, $form)
   } else {
      $cb->($self, 0, $error, undef)
   }
}

=item B<send_unregistration_request ($cb)>

This method sends an unregistration request.

For description of the semantics of the callback in C<$cb>
plase look in the description of the C<submit_form> method below.

=cut

sub send_unregistration_request {
   my ($self, $cb) = @_;

   my $con = $self->{connection};

   $con->send_iq (set => {
      defns => 'register',
      node => { ns => 'register', name => 'query', childs => [
         { ns => 'register', name => 'remove' }
      ]}
   }, sub {
      my ($node, $error) = @_;
      if ($node) {
         $cb->($self, 1)
      } else {
         $self->_error_or_form_cb ($error, $cb);
      }
   });
}

=item B<send_password_change_request ($username, $password, $cb)>

This method sends a password change request for the user C<$username>
with the new password C<$password>.

For description of the semantics of the callback in C<$cb>
plase look in the description of the C<submit_form> method below.

=cut

sub send_password_change_request {
   my ($self, $username, $password, $cb) = @_;

   my $con = $self->{connection};

   $con->send_iq (set => {
      defns => 'register',
      node => { ns => 'register', name => 'query', childs => [
         { ns => 'register', name => 'username', childs => [ $username ] },
         { ns => 'register', name => 'password', childs => [ $password ] },
      ]}
   }, sub {
      my ($node, $error) = @_;
      if ($node) {
         $cb->($self, 1, undef, undef)
      } else {
         $self->_error_or_form_cb ($error, $cb);
      }
   });
}

=item B<submit_form ($form, $cb)>

This method submits the C<$form> which should be of
type L<AnyEvent::XMPP::Ext::RegisterForm> and should be an answer
form.

C<$con> is the connection on which to send this form.

C<$cb> is the callback that will be called once the form has been submitted and
either an error or success was received.  The first argument to the callback
will be the L<AnyEvent::XMPP::Ext::Registration> object, the second will be a
boolean value that is true when the form was successfully transmitted and
everything is fine.  If the second argument is false then the third argument is
a L<AnyEvent::XMPP::Error::Register> object.  If the error contained a data form
which is required to successfully make the request then the fourth argument
will be a L<AnyEvent::XMPP::Ext::RegisterForm> which you should fill out and send
again with C<submit_form>.

For the semantics of such an error form see also XEP-0077.

=cut

sub submit_form {
   my ($self, $form, $cb) = @_;

   my $con = $self->{connection};

   $con->send_iq (set => {
      defns => 'register',
      node => { ns => 'register', name => 'query', childs => [
         $form->answer_form_to_simxml
      ]}
   }, sub {
      my ($n, $e) = @_;

      if ($n) {
         $cb->($self, 1, undef, undef)
      } else {
         $self->_error_or_form_cb ($e, $cb);
      }
   });
}

=back

=head1 AUTHOR

Robin Redeker, C<< <elmex at ta-sa.org> >>, JID: C<< <elmex at jabber.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007, 2008 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of AnyEvent::XMPP::Ext::Registration
