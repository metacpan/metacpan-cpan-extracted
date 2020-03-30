package DBIx::Class::Helper::ResultSet::Shortcut::LimitedPage;
$DBIx::Class::Helper::ResultSet::Shortcut::LimitedPage::VERSION = '2.036000';
use strict;
use warnings;

use parent qw(
  DBIx::Class::Helper::ResultSet::Shortcut::Rows
  DBIx::Class::Helper::ResultSet::Shortcut::Page
  DBIx::Class::ResultSet
);

sub limited_page {
  my $self = shift;
  if (@_ == 1) {
    my $arg = shift;
    if (ref $arg) {
      my ( $page, $rows ) = @$arg{qw(page rows)};
      return $self->page($page)->rows($rows);
    } else {
      return $self->page($arg);
    }
  } elsif (@_ == 2) {
    my ( $page, $rows ) = @_;
    return $self->page($page)->rows($rows);
  } else {
    die 'Invalid args passed to get_page method';
  }
}

1;

__END__

=pod

=head1 NAME

DBIx::Class::Helper::ResultSet::Shortcut::LimitedPage

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
