package Data::Perl::Collection::Array;
$Data::Perl::Collection::Array::VERSION = '0.002011';
# ABSTRACT: Wrapping class for Perl's built in array structure.

use strictures 1;

use Role::Tiny::With;

with 'Data::Perl::Role::Collection::Array';

1;

=pod

=encoding UTF-8

=head1 NAME

Data::Perl::Collection::Array - Wrapping class for Perl's built in array structure.

=head1 VERSION

version 0.002011

=head1 SYNOPSIS

  use Data::Perl qw/array/;

  my $array = array(1, 2, 3);

  $array->push(5);

  $array->grep(sub { $_ > 2 })->map(sub { $_ ** 2 })->elements; # (3, 5);

=head1 DESCRIPTION

This class is a simple consumer of the L<Data::Perl::Role::Collection::Array>
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

