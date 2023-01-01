package DNS::Oterica::Role::RecordMaker;
# ABSTRACT: a delegation class for the DNSO recordmaker.
$DNS::Oterica::Role::RecordMaker::VERSION = '0.314';
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
  isa => 'Defined', # String or object (duck type this?)
  default => sub { DNS::Oterica::RecordMaker::TinyDNS->new },
);

no Moose::Role;
1

__END__

=pod

=encoding UTF-8

=head1 NAME

DNS::Oterica::Role::RecordMaker - a delegation class for the DNSO recordmaker.

=head1 VERSION

version 0.314

=head1 DESCRIPTION

C<DNS::Oterica::Role::RecordMaker> delegates to an underlying record maker. It
exposes this record maker with its C<rec> method.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 ATTRIBUTES

=head2 rec

The record maker, e.g. L<DNS::Oterica::RecordMaker::TinyDNS>.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
