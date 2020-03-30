package DBIx::Class::Helper::ResultSet::Shortcut::HRI;
$DBIx::Class::Helper::ResultSet::Shortcut::HRI::VERSION = '2.036000';
use strict;
use warnings;

use parent 'DBIx::Class::ResultSet';

sub hri {
   shift->search(undef, {
      result_class => 'DBIx::Class::ResultClass::HashRefInflator' })
}

1;

__END__

=pod

=head1 NAME

DBIx::Class::Helper::ResultSet::Shortcut::HRI

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
