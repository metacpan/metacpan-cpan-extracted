package DBIx::Class::Helper::ResultSet::Shortcut::Search::IsAny;
use strict;
use warnings;
use parent 'DBIx::Class::Helper::ResultSet::Shortcut::Search::Base';


sub is_any {
   my ( $self, @columns ) = @_;
   $self->load_components(qw{Helper::ResultSet::SetOperations});
   if ( !ref $columns[0] ) {          
      $self->throw_exception( 'Why would you only send one column to is_any?' ); 
   }
   else {
      my @rs_array;
      my $i = 0;
      foreach my $column ( @{ $columns[0] } ) {
         $rs_array[$i] = $self->_helper_apply_search( { '='  => 'true' }, $column );
         $i++;
      }
      my $result = shift @rs_array;
      return $result->union( \@rs_array );
   }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Helper::ResultSet::Shortcut::Search::IsAny

=head1 VERSION

version 1.0001

=head2 is_any(@columns || \@columns)

 $rs->is_any('status');
 $rs->is_any(['status', 'title']);

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
