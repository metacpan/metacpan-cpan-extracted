package DBIx::Class::Helper::ResultSet::Shortcut::Search::BlankOrNull;
use strict;
use warnings;
use parent 'DBIx::Class::Helper::ResultSet::Shortcut::Search::Base';


sub blank_or_null {
   my ( $self, @columns ) = @_;
   $self->load_components(qw{Helper::ResultSet::SetOperations});
   if ( !ref $columns[0] ) {                    # Only sent one column. This is easy.
      my $nulls_rs     = $self->_helper_apply_search( { '='  => undef }, @columns );
      my $not_empty_rs = $self->_helper_apply_search( { '=' => '' },    @columns );
      return $nulls_rs->union( [$not_empty_rs] );
   }
   else {
      my @rs_array;
      my $i = 0;
      foreach my $column ( @{ $columns[0] } ) {
         my $nulls_rs     = $self->_helper_apply_search( { '='  => undef }, $column );
         my $not_empty_rs = $self->_helper_apply_search( { '=' => '' },    $column );
         $rs_array[$i] = $nulls_rs->union( [$not_empty_rs] );
         $i++;
      }
      my $result = shift @rs_array;
      return $result->intersect( \@rs_array );
   }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Helper::ResultSet::Shortcut::Search::BlankOrNull

=head1 VERSION

version 1.0001

=head2 blank_or_null(@columns || \@columns)

 $rs->blank_or_null('status');
 $rs->blank_or_null(['status', 'title']);

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
