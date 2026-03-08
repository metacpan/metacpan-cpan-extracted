package DBIx::Class::Async::SelectNormaliser;

$DBIx::Class::Async::SelectNormaliser::VERSION   = '0.64';
$DBIx::Class::Async::SelectNormaliser::AUTHORITY = 'cpan:MANWAR';

use strict;
use warnings;

=head1 NAME

DBIx::Class::Async::SelectNormaliser - Normalise C<-ident> clauses in ResultSet C<select> attributes

=head1 VERSION

Version 0.64

=head1 SYNOPSIS

    use DBIx::Class::Async::SelectNormaliser;

    # Inline normalisation before passing attrs to search()
    my ($clean_select, $clean_as) = DBIx::Class::Async::SelectNormaliser->normalise(
        select => [ { -ident => 'me.status', -as => 'current_status' } ],
        as     => [],
    );

    my $rs = $schema->resultset('Order')->search({}, {
        select => $clean_select,
        as     => $clean_as,
    });

    # Or call normalise_attrs() directly on a complete attrs hashref
    my $attrs = DBIx::Class::Async::SelectNormaliser->normalise_attrs({
        select => [
            'me.id',
            { -ident => 'me.status',  -as => 'current_status' },
            { -ident => 'me.created', -as => 'created_at'     },
            { count  => 'me.id',      -as => 'total'          },   # function form -- left unchanged
        ],
        as      => [ 'id' ],          # partially specified -- filled in from -as
        where   => { active => 1 },
        order_by => 'me.id',
    });

    my $rs = $schema->resultset('Order')->search($attrs->{where}, $attrs);

=head1 DESCRIPTION

=head2 The problem

L<DBIx::Class> supports a C<-ident> operator in C<where>, C<order_by>, and
C<group_by> clauses to force a value to be treated as a SQL identifier (column
or table name) rather than a literal string or a function call:

    # In a where clause -- works correctly
    $rs->search({ 'me.status' => { -ident => 'other_table.status' } });

However, C<-ident> in the C<select> attribute does B<not> work:

    # Broken -- produces: SELECT -IDENT(me.status) AS current_status
    $rs->search({}, {
        select => [ { -ident => 'me.status', -as => 'current_status' } ],
    });

The C<select> attribute is processed by a different code path inside
L<SQL::Abstract> -- specifically C<_select_field> -- which does not recognise
C<-ident> as a special sigil and instead treats it as a function name.  The
hash key C<-ident> becomes the function, its value becomes the argument, and
the result is the literal string C<-IDENT(me.status)> in the SQL output,
which is a syntax error on every database.

=head2 Why not fix upstream?

Extending C<select> to support C<-ident> in L<DBIx::Class> or
L<SQL::Abstract::More> is non-trivial:

=over 4

=item *

C<select> hashrefs are already used for function calls:
C<< { count => 'me.id', -as => 'cnt' } >>.  Adding C<-ident> as a special
sigil inside the same hashref form requires distinguishing
C<< { -ident => 'col', -as => 'alias' } >> (identifier alias) from
C<< { func => 'col', -as => 'alias' } >> (function call) without introducing
ambiguity. A column named C<ident> would be indistinguishable from the
operator.

=item *

The C<select>/C<as> separation is deliberate DBIC design: C<select> is a list
of SQL expressions and C<as> is a parallel list of Perl-side aliases.  Adding
inline C<-as> to C<select> as well (which DBIC already supports for functions)
and now C<-ident> would create three overlapping ways to alias a column, all
with subtly different semantics.

=item *

Changing this in C<SQL::Abstract> would affect all DBIC users and all other
consumers of SQL::Abstract, requiring deprecation cycles and backwards
compatibility guarantees that are beyond the scope of a single distribution.

=back

=head2 The solution: pre-processing in DBIx::Class::Async

Rather than patching upstream, this module pre-processes the C<select> and
C<as> attributes before they reach L<SQL::Abstract>.  Any
C<< { -ident => $col, -as => $alias } >> hashref is rewritten to its canonical
DBIC form: a bare column name string in C<select> and a corresponding entry in
C<as>. All other forms -- bare strings, function hashrefs, literal SQL
references -- are left completely unchanged.

This approach:

=over 4

=item *

B<Requires no upstream changes.> The transformation happens entirely in
DBIx::Class::Async before the attrs touch SQL::Abstract.

=item *

B<Is transparent to callers.> Application code that already uses the
canonical C<select>/C<as> form is unaffected.  Callers who prefer the
C<-ident> form get intuitive, correct behaviour.

=item *

B<Is safe to compose.> Function hashrefs (C<< { count => 'me.id' } >>) are
detected by the absence of C<-ident> and passed through untouched, so all
existing query patterns continue to work.

=item *

B<Is explicit about intent.> C<-ident> says clearly "this is a column
name, not a function and not a literal string", which is useful documentation
in itself.

=back

=head2 Integration Points

This module is called from two places in DBIx::Class::Async:

=over 4

=item C<DBIx::Class::Async::ResultSet::search()>

Before building the payload for the worker, C<search()> calls
L</normalise_attrs> on the incoming attrs hashref.  This means all ResultSet
operations that flow through C<search> (C<all>, C<count>, C<update>, etc.)
benefit automatically.

=item C<DBIx::Class::Async::ResultSet::search_rs()>

The same normalisation is applied when building a new ResultSet object, so
chained searches also produce correct SQL.

=back

=head2 Interaction with C<-as> in function hashrefs

DBIC supports an inline C<-as> inside function hashrefs:

    { count => 'me.id', -as => 'total' }

This module does B<not> touch that form.  The C<-as> key is only consumed when
it appears alongside C<-ident>.  In a function hashref, C<-as> is already
handled correctly by DBIC and SQL::Abstract and must not be extracted into the
C<as> array, because DBIC expects the alias to come from the function hashref
itself in that case.

=head2 Partial C<as> arrays

The incoming C<as> array may be shorter than C<select>, absent entirely, or
partially specified.  This module fills in missing entries from C<-as> values
found in the C<select> items.  Entries already present in C<as> take priority
over any C<-as> in the corresponding C<select> item, preserving the behaviour
of callers who specify both.

=cut

=head1 METHODS

=head2 normalise_attrs

    my $clean_attrs = DBIx::Class::Async::SelectNormaliser->normalise_attrs(\%attrs);

Accepts a complete ResultSet attrs hashref.  If the hashref contains a
C<select> key, rewrites any C<< { -ident => $col, -as => $alias } >> items to
bare column strings and populates C<as> accordingly.  All other keys in the
attrs hashref (C<where>, C<order_by>, C<join>, etc.) are passed through
unchanged.

Returns a B<new> hashref -- the input is never modified in place.

If C<select> is absent or contains no C<-ident> items, the returned hashref is
a shallow copy of the input with no further changes.

=cut

sub normalise_attrs {
    my ($class, $attrs) = @_;

    return $attrs unless ref $attrs eq 'HASH';
    return $attrs unless exists $attrs->{select};

    # Shallow copy -- we only touch select and as, leave everything else
    my %out = %$attrs;

    my ($clean_select, $clean_as) = $class->normalise(
        select => $attrs->{select},
        as     => $attrs->{as} // [],
    );

    $out{select} = $clean_select;
    $out{as}     = $clean_as;

    return \%out;
}

=head2 normalise

    my ($clean_select, $clean_as) = DBIx::Class::Async::SelectNormaliser->normalise(
        select => \@select_items,
        as     => \@as_items,        # may be empty or shorter than select
    );

Lower-level method.  Accepts C<select> and C<as> arrays directly and returns
two new arrayrefs.

Each item in C<select> is inspected:

=over 4

=item C<< { -ident => $col } >> or C<< { -ident => $col, -as => $alias } >>

Rewritten to the bare column string C<$col> in C<< $clean_select >>.  If
C<-as> is present and the corresponding position in the incoming C<as> array
is not already set, the alias is placed into C<< $clean_as >>.

=item Any other form

Passed through to C<< $clean_select >> unchanged.  If the corresponding
position in the incoming C<as> array is set, it is preserved in
C<< $clean_as >>.  Otherwise the C<< $clean_as >> slot is left as C<undef>
(DBIC omits C<undef> alias entries).

=back

The two returned arrays are always the same length.

=cut

sub normalise {
    my ($class, %args) = @_;

    my $select = $args{select} // [];
    my $as     = $args{as}     // [];

    # Normalise select to an arrayref -- callers sometimes pass a bare scalar
    # (single column) or a hashref (single function/ident expression).
    $select = [ $select ] unless ref $select eq 'ARRAY';

    my (@clean_select, @clean_as);

    for my $i ( 0 .. $#$select ) {
        my $item  = $select->[$i];
        my $alias = $as->[$i];      # may be undef if as is shorter than select

        if ( _is_ident_hashref(undef, $item) ) {
            # Rewrite { -ident => $col, -as => $alias } to a bare column string.
            # The caller's $as entry takes priority if already set.
            push @clean_select, $item->{'-ident'};
            push @clean_as,     defined($alias) ? $alias : $item->{'-as'};
        }
        else {
            # All other forms: bare string, function hashref, literal SQL ref --
            # pass through untouched.
            push @clean_select, $item;
            push @clean_as,     $alias;
        }
    }

    # Preserve any trailing as[] entries that extend beyond the select list.
    # These are unusual (DBIC ignores them) but we return them unchanged so
    # the caller gets back exactly what they passed in.
    if ( @$as > @$select ) {
        push @clean_as, @{$as}[ scalar(@$select) .. $#$as ];
    }

    return (\@clean_select, \@clean_as);
}

#
#
# Private Helpers

=head2 _is_ident_hashref

    my $bool = _is_ident_hashref($item);

Returns true if C<$item> is a hashref with a C<-ident> key.  Returns false for
everything else, including function hashrefs like C<< { count => 'me.id' } >>
which happen to also contain a C<-as> key.

The check is intentionally minimal: we only require the presence of C<-ident>.
The C<-as> key is optional (the caller may specify aliases via the C<as> array
instead).

=cut

sub _is_ident_hashref {
    my (undef, $item) = @_;
    return ref $item eq 'HASH' && exists $item->{'-ident'};
}

=head1 EXAMPLES

=head2 Basic identifier aliasing

    # Before normalisation (would produce broken SQL):
    select => [ { -ident => 'me.status', -as => 'current_status' } ]

    # After normalisation (correct canonical DBIC form):
    select => [ 'me.status' ],
    as     => [ 'current_status' ],

=head2 Mixed select list

    # Input
    select => [
        'me.id',
        { -ident => 'me.status',  -as => 'current_status' },
        { count  => 'me.id',      -as => 'total'          },  # function -- untouched
        { -ident => 'me.created'                          },  # no inline alias
    ],
    as => [ 'id', undef, 'total', 'created_at' ],             # as takes priority

    # Output
    select => [ 'me.id', 'me.status', { count => 'me.id', -as => 'total' }, 'me.created' ],
    as     => [ 'id', 'current_status', 'total', 'created_at' ],

    # Note: slot 1 uses 'current_status' from -as (incoming as[1] was undef).
    # Note: slot 3 uses 'created_at' from the as array (it was already set),
    #       ignoring the missing -as in the -ident item.

=head2 Caller-specified as takes priority

    # Input
    select => [ { -ident => 'me.col', -as => 'from_ident' } ],
    as     => [ 'from_as_array' ],

    # Output
    select => [ 'me.col' ],
    as     => [ 'from_as_array' ],   # as array wins

=head2 Scalar select (single column, not an array)

    # Input -- normalise() accepts a bare scalar or hashref too
    select => { -ident => 'me.status', -as => 'current_status' },
    as     => [],

    # Output
    select => [ 'me.status' ],
    as     => [ 'current_status' ],

=head1 SEE ALSO

=over 4

=item L<DBIx::Class::ResultSet/select>

DBIC documentation for the C<select> ResultSet attribute.

=item L<DBIx::Class::ResultSet/as>

DBIC documentation for the C<as> ResultSet attribute.

=item L<SQL::Abstract>

The underlying SQL generation library.  The C<_select_field> method is the
code path that does B<not> handle C<-ident>.

=back

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/DBIx-Class-Async>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/DBIx-Class-Async/issues>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::Async::SelectNormaliser

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/DBIx-Class-Async/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-Async>

=item * Search MetaCPAN

L<https://metacpan.org/dist/DBIx-Class-Async/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
license at:
L<http://www.perlfoundation.org/artistic_license_2_0>
Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.
If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.
This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.
This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.
Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of DBIx::Class::Async::SelectNormaliser
