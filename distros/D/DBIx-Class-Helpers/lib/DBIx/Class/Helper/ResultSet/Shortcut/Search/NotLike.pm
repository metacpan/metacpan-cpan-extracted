package DBIx::Class::Helper::ResultSet::Shortcut::Search::NotLike;
$DBIx::Class::Helper::ResultSet::Shortcut::Search::NotLike::VERSION = '2.036000';
use strict;
use warnings;

use parent 'DBIx::Class::Helper::ResultSet::Shortcut::Search::Base';


sub not_like {
    my ($self, $columns, $cond) = @_;

    return $self->_helper_apply_search({ '-not_like' => $cond }, $columns);
}

1;

__END__

=pod

=head1 NAME

DBIx::Class::Helper::ResultSet::Shortcut::Search::NotLike

=head2 not_like($column || \@columns, $cond)

 $rs->not_like('lyrics', '%zebra%');
 $rs->not_like(['lyrics', 'title'], '%zebra%');

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
