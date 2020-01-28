package Data::Perl::Code;
$Data::Perl::Code::VERSION = '0.002011';
# ABSTRACT: Wrapping class for Perl coderefs.

use strictures 1;

use Role::Tiny::With;

with 'Data::Perl::Role::Code';

1;

=pod

=encoding UTF-8

=head1 NAME

Data::Perl::Code - Wrapping class for Perl coderefs.

=head1 VERSION

version 0.002011

=head1 SYNOPSIS

  use Data::Perl qw/code/;

  my $code = code(sub { 'Foo'} );

  $code->execute(); # returns 'Foo';

=head1 DESCRIPTION

This class is a simple consumer of the L<Data::Perl::Role::Code> role, which
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

