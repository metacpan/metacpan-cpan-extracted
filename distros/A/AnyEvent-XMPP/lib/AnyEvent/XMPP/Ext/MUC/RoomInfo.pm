package AnyEvent::XMPP::Ext::MUC::RoomInfo;
use strict;
use AnyEvent::XMPP::Namespaces qw/xmpp_ns/;

=head1 NAME

AnyEvent::XMPP::Ext::MUC::RoomInfo - Room information

=head1 SYNOPSIS

=head1 DESCRIPTION

This module represents the room information for a MUC.

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
   my $info = $self->{disco_info};
   my $df;
   if (my ($xdata) = $info->xml_node ()->find_all ([qw/data_form x/])) {
      $df = AnyEvent::XMPP::Ext::DataForm->new;
      $df->from_node ($xdata);
   }
   $self->{form} = $df;
}

=item B<disco_info>

This method returns the info discovery object L<AnyEvent::XMPP::Ext::Disco::Info>
for the disco query that this roominfo was obtained from.

=cut

sub disco_info {
   $_[0]->{disco_info}
}

=item B<as_debug_string>

Returns the MUC room information as string for debugging.

=cut

sub as_debug_string {
   my ($self) = @_;
   my $info = $self->{disco_info};
   my @feats = keys %{$info->features};
   my $str = "MUC features for " . $info->jid . "\n";
   for (@feats) {
      if (/^muc_/) {
         $str .= "- $_\n";
      }
   }
   if (defined $self->{form}) {
      $str .= "form:\n";
      $str .= $self->{form}->as_debug_string;
   }
   $str
}

=back

=head1 AUTHOR

Robin Redeker, C<< <elmex at ta-sa.org> >>, JID: C<< <elmex at jabber.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007, 2008 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
