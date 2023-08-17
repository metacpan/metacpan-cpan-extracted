package DBIx::Class::Helper::ResultSet::Shortcut::Search::Negative;
use strict;
use warnings;
use parent 'DBIx::Class::Helper::ResultSet::Shortcut::Search::Base';


sub negative {
   my ( $self, @columns ) = @_;

   return $self->_helper_apply_search( { '<' => 0 }, @columns );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Helper::ResultSet::Shortcut::Search::Negative

=head1 VERSION

version 1.0001

=head2 negative(@columns || \@columns)

 $rs->negative('active');
 $rs->negative(['active', 'blocked']);

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
