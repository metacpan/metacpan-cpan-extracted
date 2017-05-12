package App::wmiirc::Ssh;
{
  $App::wmiirc::Ssh::VERSION = '1.000';
}
use 5.014;
use App::wmiirc::Plugin;
use File::stat;
with 'App::wmiirc::Role::Action';


sub action_ssh {
  my($self, @args) = @_;
  state($last_mtime, @hosts);

  my $known_hosts = "$ENV{HOME}/.ssh/known_hosts";
  if(-r $known_hosts && !$last_mtime
      || $last_mtime != stat($known_hosts)->mtime) {
    open my $fh, "<", $known_hosts or die "$known_hosts: $!";
    @hosts = map /^([^, ]+)/ ? $1 : (), <$fh>;
  }

  if(my $host = @args ? "@args"
      : wimenu { name => "host:", history => "ssh" }, \@hosts) {
    system $self->core->main_config->{terminal} . " -e ssh $host &";
  }
}

1;

__END__
=pod

=head1 NAME

App::wmiirc::Ssh

=head1 VERSION

version 1.000

=head2 NOTE

You may need to turn off the C<HashKnownHosts> option in F<~/.ssh/config>:

  echo HashKnownHosts no >> ~/.ssh/config

=head1 AUTHOR

David Leadbeater <dgl@dgl.cx>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by David Leadbeater.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

