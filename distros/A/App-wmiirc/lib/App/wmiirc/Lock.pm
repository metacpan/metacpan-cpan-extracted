package App::wmiirc::Lock;
{
  $App::wmiirc::Lock::VERSION = '1.000';
}
use App::wmiirc::Plugin;
with 'App::wmiirc::Role::Action';

sub action_lock {
  system config("commands", "lock", "xscreensaver-command -lock");
}

sub action_sleep(XF86PowerOff) {
  system config("commands", "sleep", "sudo pm-suspend");
}

sub action_hibernate {
  system config("commands", "hibernate", "sudo pm-hibernate");
}

# TODO: Less hacky / more supported way? Probably involves dbus.
# On arch I currently have the following in /etc/acpi/actions/lm_lid.sh:
# DISPLAY=:0 sudo -u dgl ~dgl/bin/wmiir xwrite /event Lid $3

sub event_lid {
  my($self, $type) = @_;
  if($type eq 'close') {
    system config("commands", "sleep", "sudo pm-suspend");
  }
}

1;

__END__
=pod

=head1 NAME

App::wmiirc::Lock

=head1 VERSION

version 1.000

=head1 AUTHOR

David Leadbeater <dgl@dgl.cx>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by David Leadbeater.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

