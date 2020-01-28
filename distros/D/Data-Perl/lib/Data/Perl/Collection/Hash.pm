  package Data::Perl::Collection::Hash;
$Data::Perl::Collection::Hash::VERSION = '0.002011';
# ABSTRACT: Wrapping class for Perl's built in hash structure.

use strictures 1;

use Role::Tiny::With;

with 'Data::Perl::Role::Collection::Hash';

1;

=pod

=encoding UTF-8

=head1 NAME

Data::Perl::Collection::Hash - Wrapping class for Perl's built in hash structure.

=head1 VERSION

version 0.002011

=head1 SYNOPSIS

  use Data::Perl qw/hash/;

  my $hash = hash(a => 1, b => 2);

  $array->push(5);

  $hash->values; # (1, 2)

  $hash->set('foo', 'bar'); # (a => 1, b => 2, foo => 'bar')

=head1 DESCRIPTION

This class is a simple consumer of the L<Data::Perl::Role::Collection::Hash>
role, which provides all functionality. You probably want to look there
instead.

=head1 AUTHOR

Matthew Phillips <mattp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Matthew Phillips <mattp@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
==pod

