package DBIx::Skinny::Pager::Page;
use strict;
use warnings;
use base qw(Data::Page);

sub to_hash {
    my $self = $_[0];
    return +{
        total_entries    => $self->total_entries,
        entries_per_page => $self->entries_per_page,
        previous_page    => $self->previous_page,
        current_page  => $self->current_page,
        next_page        => $self->next_page,
    };
}

1;

__END__
=head1 NAME

DBIx::Skinny::Pager::Page - simple wrapper of Data::Page.

=head1 SYNOPSIS

  my $rs = Proj::DB->resultset_with_pager('MySQLFoundRows');
  # ... do something with $rs.
  my ($iter, $pager) = $rs->retrieve;
  # $iter is a DBIx::Skinny::Iterator
  isa_ok($pager, "Data::Page");
  $pager->to_hash # => { 
                  #   total_entries => 70, 
                  #   current_page => 2, 
                  #   entries_per_page => 20, 
                  #   previous_page => 1,
                  #   next_page     => 3,
                  # }

=head1 DESCRIPTION

DBIx::Skinny::Pager::Page is a simple wrapper of Data::Page.
you can handle it like a Data::Page object.

DBIx::Skinny::Pager's retrieve method return a wrapped DBIx::Skinny::Pager::Page object.
It's for distinguish what logic was used from view layer.

=head1 AUTHOR

Keiji Yoshimi E<lt>walf443 at gmail dot comE<gt>

=head1 SEE ALSO

+<DBIx::Skinny>, +<DBIx::Skinny::SQL>, +<DBIx::Skinny::Mixin>, +<Data::Page>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
