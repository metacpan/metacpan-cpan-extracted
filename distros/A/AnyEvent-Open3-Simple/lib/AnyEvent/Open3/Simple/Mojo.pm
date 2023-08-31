package AnyEvent::Open3::Simple::Mojo;

use strict;
use warnings;
use POSIX ':sys_wait_h';

# ABSTRACT: Code for the AnyEvent::Open3::Simple mojo implementation
our $VERSION = '0.90'; # VERSION

if($^O eq 'MSWin32')
{
  *_watcher = sub
  {
    my $pid = waitpid($_[0], WNOHANG);
    $_[1]->($_[0], $?) if $_[0] == $pid;
  };
}
else
{
  my %proc;

  $SIG{CHLD} = sub {
    while((my $pid = waitpid -1, WNOHANG) > 0)
    {
      $proc{$pid} = $?;
    }
  };

  *_watcher = sub
  {
    my($pid, $cb) = @_;
    $cb->($pid, delete $proc{$pid}) if defined $proc{$pid};
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Open3::Simple::Mojo - Code for the AnyEvent::Open3::Simple mojo implementation

=head1 VERSION

version 0.90

=head1 SYNOPSIS

 $ perldoc AnyEvent::Open3::Simple

=head1 DESCRIPTION

This is a private module.

=head1 SEE ALSO

=over 4

=item L<AnyEvent::Open3::Simple>

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Stephen R. Scaffidi

Scott Wiersdorf

Graham Knop (HAARG)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
