use strict;
use warnings;
package Data::Rx::TypeBundle::Perl 0.011;
use base 'Data::Rx::TypeBundle';
# ABSTRACT: experimental / perl types

use Data::Rx::Type::Perl::Code;
use Data::Rx::Type::Perl::Obj;
use Data::Rx::Type::Perl::Ref;

#pod =head1 SYNOPSIS
#pod
#pod   use Data::Rx;
#pod   use Data::Rx::Type::Perl;
#pod   use Test::More tests => 2;
#pod
#pod   my $rx = Data::Rx->new({
#pod     type_plugins => [ qw(Data::Rx::TypeBundle::Perl) ],
#pod   });
#pod
#pod   my $isa_rx = $rx->make_schema({
#pod     type       => '/perl/obj',
#pod     isa        => 'Data::Rx',
#pod   });
#pod
#pod   ok($isa_rx->check($rx),   "a Data::Rx object isa Data::Rx /perl/obj");
#pod   ok(! $isa_rx->check( 1 ), "1 is not a Data::Rx /perl/obj");
#pod
#pod =cut

sub _prefix_pairs {
  return (
    perl => 'tag:codesimply.com,2008:rx/perl/',
  );
}

sub type_plugins {
  return qw(
    Data::Rx::Type::Perl::Code
    Data::Rx::Type::Perl::Obj
    Data::Rx::Type::Perl::Ref
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Rx::TypeBundle::Perl - experimental / perl types

=head1 VERSION

version 0.011

=head1 SYNOPSIS

  use Data::Rx;
  use Data::Rx::Type::Perl;
  use Test::More tests => 2;

  my $rx = Data::Rx->new({
    type_plugins => [ qw(Data::Rx::TypeBundle::Perl) ],
  });

  my $isa_rx = $rx->make_schema({
    type       => '/perl/obj',
    isa        => 'Data::Rx',
  });

  ok($isa_rx->check($rx),   "a Data::Rx object isa Data::Rx /perl/obj");
  ok(! $isa_rx->check( 1 ), "1 is not a Data::Rx /perl/obj");

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 CONTRIBUTOR

=for stopwords Ricardo Signes

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
