package DBIx::Class::Helper::ResultSet::Shortcut::ResultsExist;
$DBIx::Class::Helper::ResultSet::Shortcut::ResultsExist::VERSION = '2.034000';
use strict;
use warnings;

use parent 'DBIx::Class::ResultSet';

sub results_exist {
   my $self   = shift;

   $self
      ->result_source
      ->resultset
      ->search({ -exists => $self->as_query })
      ->first
}

1;

__END__

=pod

=head1 NAME

DBIx::Class::Helper::ResultSet::Shortcut::ResultsExist

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
