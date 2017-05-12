package DNS::Oterica::Role::RecordMaker;
# ABSTRACT: a delegation class for the DNSO recordmaker.
$DNS::Oterica::Role::RecordMaker::VERSION = '0.304';
use Moose::Role;

use DNS::Oterica::RecordMaker::TinyDNS;

#pod =head1 DESCRIPTION
#pod
#pod C<DNS::Oterica::Role::RecordMaker> delegates to an underlying record maker. It
#pod exposes this record maker with its C<rec> method.
#pod
#pod =attr rec
#pod
#pod The record maker, e.g. L<DNS::Oterica::RecordMaker::TinyDNS>.
#pod
#pod =cut

has rec => (
  is  => 'ro',
  isa => 'Str', # XXX or object doing role, etc
  default => 'DNS::Oterica::RecordMaker::TinyDNS',
);

no Moose::Role;
1

__END__

=pod

=encoding UTF-8

=head1 NAME

DNS::Oterica::Role::RecordMaker - a delegation class for the DNSO recordmaker.

=head1 VERSION

version 0.304

=head1 DESCRIPTION

C<DNS::Oterica::Role::RecordMaker> delegates to an underlying record maker. It
exposes this record maker with its C<rec> method.

=head1 ATTRIBUTES

=head2 rec

The record maker, e.g. L<DNS::Oterica::RecordMaker::TinyDNS>.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
