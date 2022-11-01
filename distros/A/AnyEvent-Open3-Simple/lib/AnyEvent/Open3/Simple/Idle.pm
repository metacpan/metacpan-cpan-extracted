package AnyEvent::Open3::Simple::Idle;

use strict;
use warnings;
use POSIX ':sys_wait_h';

# ABSTRACT: Code for the AnyEvent::Open3::Simple idle implementation
our $VERSION = '0.88'; # VERSION

sub _watcher
{
  my $pid = waitpid($_[0], WNOHANG);
  $_[1]->($_[0], $?) if $_[0] == $pid;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Open3::Simple::Idle - Code for the AnyEvent::Open3::Simple idle implementation

=head1 VERSION

version 0.88

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

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
