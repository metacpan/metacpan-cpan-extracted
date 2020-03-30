package DBIx::Class::Helper::ResultSet::Shortcut::OrderByMagic;
$DBIx::Class::Helper::ResultSet::Shortcut::OrderByMagic::VERSION = '2.036000';
use strict;
use warnings;

use parent 'DBIx::Class::Helper::ResultSet::Shortcut::OrderBy', 'DBIx::Class::ResultSet';

sub order_by {
    my ($self, @order) = @_;

    return $self->next::method(@order)
       if @order && ref($order[0]);

    my @clauses;
    foreach (@order) {
        foreach my $col (split(/\s*,\s*/)) {
            my $dir = 'asc';
            if (substr($col, 0, 1) eq '!') {
                $col = substr($col, 1); # take everything after '!'
                $dir = 'desc';
            }

            # add csa prefix if necessary
            $col = join('.', $self->current_source_alias, $col)
                if index($col, '.') == -1;

            push @clauses, { "-$dir" => $col };
        }
    }

    return $self->next::method(\@clauses);
}

1;

__END__

=pod

=head1 NAME

DBIx::Class::Helper::ResultSet::Shortcut::OrderByMagic

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
