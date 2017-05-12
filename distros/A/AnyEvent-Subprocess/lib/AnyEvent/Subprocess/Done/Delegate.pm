package AnyEvent::Subprocess::Done::Delegate;
BEGIN {
  $AnyEvent::Subprocess::Done::Delegate::VERSION = '1.102912';
}
# ABSTRACT: role that delegates on the Done class must implement
use Moose::Role;

with 'AnyEvent::Subprocess::Delegate';

1;



=pod

=head1 NAME

AnyEvent::Subprocess::Done::Delegate - role that delegates on the Done class must implement

=head1 VERSION

version 1.102912

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
