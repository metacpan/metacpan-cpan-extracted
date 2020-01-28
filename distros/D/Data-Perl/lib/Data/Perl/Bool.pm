package Data::Perl::Bool;
$Data::Perl::Bool::VERSION = '0.002011';
# ABSTRACT: Wrapping class for boolean values.

use strictures 1;

use Role::Tiny::With;

with 'Data::Perl::Role::Bool';

1;

=pod

=encoding UTF-8

=head1 NAME

Data::Perl::Bool - Wrapping class for boolean values.

=head1 VERSION

version 0.002011

=head1 SYNOPSIS

  use Data::Perl qw/bool/;

  my $bool = bool(0);

  $bool->toggle; # 1

  $bool->unset; # 0

=head1 DESCRIPTION

This class is a simple consumer of the L<Data::Perl::Role::Bool> role, which
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

