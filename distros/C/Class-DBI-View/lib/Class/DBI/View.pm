package Class::DBI::View;

use strict;
use vars qw($VERSION);
$VERSION = 0.07;

use UNIVERSAL::require;

sub _croak { require Carp; Carp::croak(@_) }

sub import {
    my($class, $strategy) = @_;
    my $pkg = caller;

    defined $strategy   or _croak("You should supply strategy for setup_view()");

    my $mod = "Class::DBI::View::$strategy";
       $mod->require or _croak($UNIVERSAL::require::ERROR);
    no strict 'refs';
    *{"$pkg\::setup_view"} = \&{"$mod\::setup_view"};
}

1;
__END__

=head1 NAME

Class::DBI::View - Virtual table for Class::DBI

=head1 SYNOPSIS

  package CD::Music::SalesRanking;
  use base qw(CD::DBI); # your Class::DBI base class
  use Class::DBI::View qw(TemporaryTable);

  __PACKAGE__->columns(All => qw(id count));
  __PACKAGE__->setup_view(<<SQL);
    SELECT cd_id AS id, COUNT(*) AS count
    FROM cd_sales
    GROUP BY cd_id
    ORDER BY count
    LIMIT 1, 10
  SQL


=head1 DESCRIPTION

Class::DBI::View is a Class::DBI wrapper to make virtual VIEWs.

=head1 METHODS

=over 4

=item import

  use Class::DBI::View qw(TemporaryTable);
  use Class::DBI::View qw(SubQuery);
  use Class::DBI::View qw(Having);

When use()ing this module, you should supply which strategy
(implmentation) you use to create virtual view, which is one of
'TemporaryTable', 'SubQuery' or 'Having'.

=item setup_view

  $class->setup_view($sql [, %opt ]);

Setups virtual VIEW for C<$class>. C<$sql> should be a raw SQL statement
to build the VIEW.

C<%opt> can be any of these:

=over 6

=item cache_for_session

Caches temporary table per database connection. Only valid for
C<TemporaryTable> implementation.

  # creates tmp table once per session
  __PACKAGE__->setup_view($sql, cache_for_session => 1);

=back

=back

=head1 TIPS AND TRAPS

You know Class::DBI's C<retrieve> method wants value for primary
key. What if your view doesn't have primary column? Quick solution
would be making primary column by combining some columns like:

  __PACKAGE__->columns(All => qw(id acc_id orgname sub_id productname));
  __PACKAGE__->setup_view( <<SQL );
  SELECT CONCAT(a.acc_id, '.', a.subs_id) AS id,
         a.acc_id, a.orgname,
         s.sub_id, s.productname
  FROM   accounts a, subscriptions s
  WHERE  a.acc_id = s.acc_id
  SQL

=head1 NOTES

=over 4

=item *

Currently update/delete/insert-related methods (like C<create>) are
not supported. Supporting it would make things too complicated IMHO.
So only SELECT-related methods (C<search> etc.) would be
enough. (Patches are welcome, off course)

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt> with feedbacks
from:

  Dominic Mitchell E<lt>dom@semantico.comE<gt>
  Tim Bunce E<lt>Tim.bunce@pobox.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Class::DBI>

=cut
