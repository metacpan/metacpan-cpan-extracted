package CGI::Inspect::Plugin::Exit;

use strict;
use base 'CGI::Inspect::Plugin';

sub process {
  my ($self) = @_;
  my $exit_link = $self->request->callback_link(
    Exit => sub {
      $self->manager->{do_exit} = 1;
    }
  );
  my $output = qq{
    <div class=dialog title="Exit">
      $exit_link
    </div>
  };
  return $output;
}

1;

