package App::GitGot::Command::that;
our $AUTHORITY = 'cpan:GENEHACK';
$App::GitGot::Command::that::VERSION = '1.339';
# ABSTRACT: check if a given repository is managed
use 5.014;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub _execute {
  my( $self, $opt, $args ) = @_;
  my $path = pop @$args;

  defined $path and -d $path
    or say STDERR 'ERROR: You must provide a path to a repo to check' and exit 1;

  $self->_path_is_managed( $path ) or exit 1;
}

1;

## FIXME docs

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GitGot::Command::that - check if a given repository is managed

=head1 VERSION

version 1.339

=head1 AUTHOR

John SJ Anderson <john@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
