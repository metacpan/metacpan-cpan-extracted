package DBIx::Skinny::Pager::Logic::MySQLFoundRows;
use strict;
use warnings;
use base qw/DBIx::Skinny::Pager/;
use Data::Page;

sub as_sql {
    my $self = shift;
    my $result = $self->SUPER::as_sql;
    # TODO: 正規表現もいいかげんなのでもうちょいちゃんとやりたい
    # as_sqlの中身をいじるのは本家への追従を考えると難しそう
    $result =~ s/SELECT /SELECT SQL_CALC_FOUND_ROWS /; # mysql support only
    $result;
}

sub get_total_entries {
    my $self = shift;
    $self->skinny->search_by_sql(q{SELECT FOUND_ROWS() AS row})->first->row;
}

1;
__END__

=head1 NAME

DBIx::Skinny::Pager::Logic::MySQLFoundRows

=head1 SYNOPSIS

  package Proj::DB;
  use DBIx::Skinny;
  use DBIx::Skinny::Mixin modules => ['Pager'];

  package main;
  use Proj::DB;

  my $rs = Proj::DB->resultset_with_pager('MySQLFoundRows');
  # $rs can handle like DBIx::Skinny::SQL.
  $rs->from(['some_table']);
  $rs->add_where('foo' => 'bar');
  $rs->limit(10);
  $rs->offset(20);
  my ($iter, $pager) = $rs->retrieve;
  # $iter is a DBIx::Skinny::Iterator
  # $pager is a Data::Page

=head1 DESCRIPTION

DBIx::Skinny::Pager::Logic::MySQLFoundRows is supported mysql only.

=head1 AUTHOR

Keiji Yoshimi E<lt>walf443 at gmail dot comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
