use strict;
use warnings;
package DNS::Oterica::RecordMaker::Diagnostic;
# ABSTRACT: a collector of record generation requests, for testing
$DNS::Oterica::RecordMaker::Diagnostic::VERSION = '0.311';
use Sub::Install;

#pod =head1 DESCRIPTION
#pod
#pod This recordmaker returns hashrefs describing the requested record.
#pod
#pod At present, the returned data are very simple.  They will change and improve
#pod over time.
#pod
#pod =cut

my @types = qw(
  comment
  a_and_ptr
  ptr
  soa_and_ns_for_ip
  a
  mx
  domain
  soa_and_ns
  cname
  txt
  srv
  dkim
);

for my $type (@types) {
  my $code = sub {
    return {
      type => $type,
      args => [ @_ ],
    };
  };

  Sub::Install::install_sub({ code => $code, as => $type });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DNS::Oterica::RecordMaker::Diagnostic - a collector of record generation requests, for testing

=head1 VERSION

version 0.311

=head1 DESCRIPTION

This recordmaker returns hashrefs describing the requested record.

At present, the returned data are very simple.  They will change and improve
over time.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
