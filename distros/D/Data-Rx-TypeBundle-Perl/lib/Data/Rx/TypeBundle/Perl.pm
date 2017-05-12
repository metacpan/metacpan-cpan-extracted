use strict;
use warnings;
package Data::Rx::TypeBundle::Perl;
{
  $Data::Rx::TypeBundle::Perl::VERSION = '0.009';
}
use base 'Data::Rx::TypeBundle';
# ABSTRACT: experimental / perl types

use Data::Rx::Type::Perl::Code;
use Data::Rx::Type::Perl::Obj;
use Data::Rx::Type::Perl::Ref;


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

version 0.009

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

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
