package DBIx::Skinny::Mixin::Pager;
use strict;
use warnings;
use UNIVERSAL::require;
use DBIx::Skinny::Pager::Logic::Count;
use DBIx::Skinny::Pager::Logic::MySQLFoundRows;
use DBIx::Skinny::Pager::Logic::PlusOne;

sub register_method {
    +{
        'resultset_with_pager' => \&resultset_with_pager,
    }
}

# see also DBIx::Skinny#resultset
sub resultset_with_pager {
    my ($class, $logic, $args) = @_;
    my $logic_class = "DBIx::Skinny::Pager::Logic::$logic";
    $logic_class->require
        or die $@;
    $args->{skinny} = $class;
    $logic_class->new($args);
}

1;
__END__

=head1 NAME

DBIx::Skinny::Mixin::Pager

=head1 SYNOPSIS

  package Proj::DB;
  use DBIx::Skinny;
  use DBIx::Skinny::Mixin modules => ['Pager'];

  package main;
  use Proj::DB;

  my $rs = Proj::DB->resultset_with_pager('MySQLFoundRows');
  # $rs is DBIx::Skinny::Pager::Logic::MySQLFoundRows

or

  my ($iter, $pager) = Proj::DB->search_with_pager({ foo => "bar" }, { pager_logic => "PlusOne" });

=head1 DESCRIPTION

DBIx::Skinny::Mixin::Pager is a interface for mixin resultset_with_pager method to DBIx::Skinny.
resultset_with_pager return DBIx::Skinny::Pager object.

=head1 AUTHOR

Keiji Yoshimi E<lt>walf443 at gmail dot comE<gt>

=head1 SEE ALSO

L<DBIx::Skinny::Pager>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
