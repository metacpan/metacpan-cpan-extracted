package DBIx::Class::Helper::ResultSet::Shortcut::Search::NotNull;
$DBIx::Class::Helper::ResultSet::Shortcut::Search::NotNull::VERSION = '2.036000';
use strict;
use warnings;

use parent 'DBIx::Class::Helper::ResultSet::Shortcut::Search::Base';


sub not_null {
    my ($self, @columns) = @_;

    return $self->_helper_apply_search({ '!=' => undef }, @columns);
}

1;

__END__

=pod

=head1 NAME

DBIx::Class::Helper::ResultSet::Shortcut::Search::NotNull

=head2 not_null(@columns || \@columns)

 $rs->not_null('status');
 $rs->not_null(['status', 'title']);

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
