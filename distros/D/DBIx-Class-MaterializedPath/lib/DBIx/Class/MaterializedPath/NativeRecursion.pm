package DBIx::Class::MaterializedPath;
{
  $DBIx::Class::MaterializedPath::VERSION = '0.002001';
}

use 5.016;
use warnings;

sub _get_column_change_method {
   my ($self, $path_info) = @_;

   return sub {
      my $self = shift;
      my $rel = $path_info->{children_relationship};
      $self->_set_materialized_path($path_info);
      __SUB__->($_) for $self->$rel->search({
         # to avoid recursion
         map +(
            "me.$_" => { '!=' => $self->get_column($_) },
         ), $self->result_source->primary_columns
      })->all
   }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::MaterializedPath

=head1 VERSION

version 0.002001

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
