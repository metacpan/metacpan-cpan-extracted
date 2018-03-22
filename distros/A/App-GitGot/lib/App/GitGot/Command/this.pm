package App::GitGot::Command::this;
our $AUTHORITY = 'cpan:GENEHACK';
$App::GitGot::Command::this::VERSION = '1.335';
# ABSTRACT: check if the current repository is managed
use 5.014;

use Cwd;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub _execute {
  my( $self, $opt, $args ) = @_;

  $self->_path_is_managed( getcwd() ) or exit 1;
}

1;

## FIXME docs

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GitGot::Command::this - check if the current repository is managed

=head1 VERSION

version 1.335

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
