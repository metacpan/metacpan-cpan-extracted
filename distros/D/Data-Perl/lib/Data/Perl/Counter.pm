package Data::Perl::Counter;
$Data::Perl::Counter::VERSION = '0.002011';
# ABSTRACT: Wrapping class for a simple numeric counter.

use strictures 1;

use Role::Tiny::With;

with 'Data::Perl::Role::Counter';

1;

=pod

=encoding UTF-8

=head1 NAME

Data::Perl::Counter - Wrapping class for a simple numeric counter.

=head1 VERSION

version 0.002011

=head1 SYNOPSIS

  use Data::Perl qw/counter/;

  my $c = counter(4);

  $c->inc;   # $c == 5

  $c->reset; # $c == 0

=head1 DESCRIPTION

This class is a simple consumer of the L<Data::Perl::Role::Counter> role, which
provides all functionality. You probably want to look there instead.

=head1 AUTHOR

Matthew Phillips <mattp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Matthew Phillips <mattp@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
==pod

