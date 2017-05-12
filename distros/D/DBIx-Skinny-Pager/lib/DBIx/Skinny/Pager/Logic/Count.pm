package DBIx::Skinny::Pager::Logic::Count;
use strict;
use warnings;
use base qw/DBIx::Skinny::Pager/;
use Data::Page;
use DBIx::Skinny::SQL;

sub get_total_entries {
    my ($self, $iter) = @_;
    my %hash = %{ $self };
    for my $col ( qw( limit offset page select order ) ) {
        delete $hash{$col};
    }
    my $rs = DBIx::Skinny::SQL->new(\%hash);
    $rs->add_select("COUNT(*)" => 'cnt');
    my $new_iter = $rs->retrieve;
    if ( $rs->group && ( ref $rs->group eq 'ARRAY' && @{ $rs->group } ) ) {
        # are there better way?
        return $new_iter->count;
    } else {
        return $new_iter->first->cnt;
    }
}

1;
__END__

=head1 NAME

DBIx::Skinny::Pager::Logic::Count

=head1 SYNOPSIS

  package Proj::DB;
  use DBIx::Skinny;
  use DBIx::Skinny::Mixin modules => ['Pager'];

  package main;
  use Proj::DB;

  my $rs = Proj::DB->resultset_with_pager('Count');
  # $rs can handle like DBIx::Skinny::SQL.
  $rs->from(['some_table']);
  $rs->add_where('foo' => 'bar');
  $rs->limit(10);
  $rs->offset(20);
  my ($iter, $pager) = $rs->retrieve;
  # $iter is a DBIx::Skinny::Iterator
  # $pager is a Data::Page

=head1 DESCRIPTION

DBIx::Skinny::Pager::Logic::Count is most normal logic.

=head1 AUTHOR

Keiji Yoshimi E<lt>walf443 at gmail dot comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
