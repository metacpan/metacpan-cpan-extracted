package DBIx::Class::Helper::ResultSet::NoColumns;
$DBIx::Class::Helper::ResultSet::NoColumns::VERSION = '2.036000';
# ABSTRACT: Look ma, no columns!

use strict;
use warnings;

use parent 'DBIx::Class::ResultSet';

sub no_columns { $_[0]->search(undef, { columns => [] }) }

1;

__END__

=pod

=head1 NAME

DBIx::Class::Helper::ResultSet::NoColumns - Look ma, no columns!

=head1 SYNOPSIS

 package MySchema::ResultSet::Bar;

 use strict;
 use warnings;

 use parent 'DBIx::Class::ResultSet';

 __PACKAGE__->load_components('Helper::ResultSet::NoColumns');

 # in code using resultset:
 my $rs = $schema->resultset('Bar')->no_columns->search(undef, {
    '+columns' => { 'foo' => 'me.foo' },
 });

=head1 DESCRIPTION

This component simply gives you a method to clear the set of columns to be
selected.  It's just handy sugar.

See L<DBIx::Class::Helper::ResultSet/NOTE> for a nice way to apply this to your
entire schema.

=head1 METHODS

=head2 no_columns

 $rs->no_columns

Returns resultset with zero columns configured, fresh for the addition of new
columns.

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
