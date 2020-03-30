package DBIx::Class::Helper::ResultSet::Shortcut::Search::Base;
$DBIx::Class::Helper::ResultSet::Shortcut::Search::Base::VERSION = '2.036000';
use strict;
use warnings;

use parent 'DBIx::Class::ResultSet';

#--------------------------------------------------------------------------#
# _helper_unwrap_columns(@columns)
#--------------------------------------------------------------------------#

sub _helper_unwrap_columns {
    my ($self, @columns) = @_;

    if (@columns == 1 && ref($columns[0]) && ref($columns[0]) eq 'ARRAY') {
        @columns = @{ $columns[0] };
    }

    return @columns;
}

#--------------------------------------------------------------------------#
# _helper_meify($column)
#--------------------------------------------------------------------------#

sub _helper_meify {
    my ($self, $column) = @_;

    return $self->current_source_alias . $column if $column =~ m/^\./;
    return $column;
}

#--------------------------------------------------------------------------#
# _helper_apply_search($cond, @columns)
#--------------------------------------------------------------------------#

sub _helper_apply_search {
    my ($self, $cond, @columns) = @_;

    @columns = $self->_helper_unwrap_columns(@columns);

    my $rs = $self;
    foreach my $column (@columns) {
    	$rs = $rs->search_rs({ $self->_helper_meify($column) => $cond });
    }

    return $rs;
}


1;

__END__

=pod

=head1 NAME

DBIx::Class::Helper::ResultSet::Shortcut::Search::Base

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
