package AnyEvent::Retry::Interval::API;
BEGIN {
  $AnyEvent::Retry::Interval::API::VERSION = '0.03';
}
# ABSTRACT: API role that interval classes must implement
use Moose::Role;
use true;
use namespace::autoclean;

requires 'next';
requires 'reset';



=pod

=head1 NAME

AnyEvent::Retry::Interval::API - API role that interval classes must implement

=head1 VERSION

version 0.03

=head1 SEE ALSO

L<AnyEvent::Retry::Interval>

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

