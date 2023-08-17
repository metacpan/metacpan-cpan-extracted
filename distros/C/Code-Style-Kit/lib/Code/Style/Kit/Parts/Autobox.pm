package Code::Style::Kit::Parts::Autobox;
use strict;
use warnings;
our $VERSION = '1.0.3'; # VERSION
# ABSTRACT: add autobox to your kit


sub feature_autobox_default { 1 }
sub feature_autobox_export_list {
    qw(autobox::Core autobox::Camelize autobox::Transform);
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords autobox

=head1 NAME

Code::Style::Kit::Parts::Autobox - add autobox to your kit

=head1 VERSION

version 1.0.3

=head1 SYNOPSIS

  package My::Kit;
  use parent qw(Code::Style::Kit Code::Style::Kit::Parts::Autobox);
  1;

Then:

  package My::Module;
  use My::Kit;

  # you have autobox::Core, autobox::Camelize, autobox::Transform

=head1 DESCRIPTION

This part defines the feature C<autobox>, enabled by default, which
imports L<< C<autobox::Core> >>, L<< C<autobox::Camelize> >>, L<<
C<autobox::Transform> >>.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
