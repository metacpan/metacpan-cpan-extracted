package DBIx::Class::Helper::ResultSet::Shortcut::RemoveColumns;
$DBIx::Class::Helper::ResultSet::Shortcut::RemoveColumns::VERSION = '2.036000';
use strict;
use warnings;

use parent 'DBIx::Class::ResultSet';

__PACKAGE__->load_components('Helper::ResultSet::RemoveColumns');

sub remove_columns { shift->search(undef, { remove_columns => shift }) }

1;

__END__

=pod

=head1 NAME

DBIx::Class::Helper::ResultSet::Shortcut::RemoveColumns

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
