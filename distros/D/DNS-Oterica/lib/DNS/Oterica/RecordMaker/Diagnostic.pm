use strict;
use warnings;
package DNS::Oterica::RecordMaker::Diagnostic;
# ABSTRACT: a collector of record generation requests, for testing
$DNS::Oterica::RecordMaker::Diagnostic::VERSION = '0.313';
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

version 0.313

=head1 DESCRIPTION

This recordmaker returns hashrefs describing the requested record.

At present, the returned data are very simple.  They will change and improve
over time.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
