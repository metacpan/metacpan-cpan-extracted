package DBIO::Oracle::SQLMaker;
# ABSTRACT: Oracle-specific SQL generation for DBIO

use warnings;
use strict;

use base qw( DBIO::SQLMaker );

use DBIO::Oracle::Identifier ();


sub new {
  my $self = shift;
  my %opts = (ref $_[0] eq 'HASH') ? %{$_[0]} : @_;

  # PRIOR stays an old-style special_op: it is consumed inside CONNECT BY /
  # START WITH via _recurse_where (the SQL::Abstract v1 engine), which does
  # not route through the new expand_op mechanism -- and the base's
  # disable_old_special_ops does not reach that path either, so it keeps
  # working. The canonical parenthesized WHERE renderer is now provided
  # centrally by DBIO::SQLMaker, so the previous local render_clause override
  # is gone.
  push @{$opts{special_ops}}, {
    regex => qr/^prior$/i,
    handler => '_where_field_PRIOR',
  };

  $self->next::method(\%opts);
}


sub apply_limit {
  my ($self, $sql, $rs_attrs, $rows, $offset) = @_;
  return $self->_RowNum($sql, $rs_attrs, $rows, $offset);
}

sub _assemble_binds {
  my $self = shift;
  return map { @{ (delete $self->{"${_}_bind"}) || [] } } (qw/pre_select select from where oracle_connect_by group having order limit/);
}

sub _parse_rs_attrs {
    my $self = shift;
    my ($rs_attrs) = @_;

    my ($cb_sql, @cb_bind) = $self->_connect_by($rs_attrs);
    push @{$self->{oracle_connect_by_bind}}, @cb_bind;

    my $sql = $self->next::method(@_);

    return "$cb_sql $sql";
}

sub _connect_by {
    my ($self, $attrs) = @_;

    my $sql = '';
    my @bind;

    if ( ref($attrs) eq 'HASH' ) {
        if ( $attrs->{'start_with'} ) {
            my ($ws, @wb) = $self->_recurse_where( $attrs->{'start_with'} );
            $sql .= $self->_sqlcase(' start with ') . $ws;
            push @bind, @wb;
        }
        if ( my $connect_by = $attrs->{'connect_by'} || $attrs->{'connect_by_nocycle'} ) {
            my ($connect_by_sql, @connect_by_sql_bind) = $self->_recurse_where( $connect_by );
            $sql .= sprintf(" %s %s",
                ( $attrs->{'connect_by_nocycle'} ) ? $self->_sqlcase('connect by nocycle')
                    : $self->_sqlcase('connect by'),
                $connect_by_sql,
            );
            push @bind, @connect_by_sql_bind;
        }
        if ( $attrs->{'order_siblings_by'} ) {
            $sql .= $self->_order_siblings_by( $attrs->{'order_siblings_by'} );
        }
    }

    return wantarray ? ($sql, @bind) : $sql;
}

sub _order_siblings_by {
    my ( $self, $arg ) = @_;

    my ( @sql, @bind );
    for my $c ( $self->_order_by_chunks($arg) ) {
        if (ref $c) {
            push @sql, shift @$c;
            push @bind, @$c;
        }
        else {
            push @sql, $c;
        }
    }

    my $sql =
      @sql
      ? sprintf( '%s %s', $self->_sqlcase(' order siblings by'), join( ', ', @sql ) )
      : '';

    return wantarray ? ( $sql, @bind ) : $sql;
}

sub _where_field_PRIOR {
  my ($self, $lhs, $op, $rhs) = @_;
  my ($sql, @bind) = $self->_recurse_where ($rhs);

  $sql = sprintf ('%s = %s %s ',
    $self->_convert($self->_quote($lhs)),
    $self->_sqlcase ($op),
    $sql
  );

  return ($sql, @bind);
}

sub _quote {
  my ($self, $label) = @_;

  return '' unless defined $label;
  return ${$label} if ref($label) eq 'SCALAR';

  # SQL::Abstract v2 hands qualified identifiers to _render_ident as an arrayref
  # of already-split segments, so the string regex below never sees them and the
  # WHERE/HAVING column qualifiers bypass Oracle identifier shortening while the
  # SELECT/FROM string path shortens them. Shorten each over-long segment here
  # too, with the same keyword-less _shorten_identifier call so both paths emit
  # the identical short name.
  if (ref $label eq 'ARRAY') {
    return $self->next::method([
      map { (defined and !ref and length > 30) ? $self->_shorten_identifier($_) : $_ } @$label
    ]);
  }

  $label =~ s/ ( [^\.]{31,} ) /$self->_shorten_identifier($1)/gxe;

  $self->next::method($label);
}

sub _shorten_identifier {
  my ($self, $to_shorten, $keywords) = @_;
  return DBIO::Oracle::Identifier::shorten($to_shorten, $keywords);
}

sub _unqualify_colname {
  my ($self, $fqcn) = @_;

  return $self->_shorten_identifier($self->next::method($fqcn));
}



sub _insert_returning {
  my ($self, $options) = @_;

  my $f = $options->{returning};

  my ($f_list, @f_names) = do {
    if (! ref $f) {
      (
        $self->_quote($f),
        $f,
      )
    }
    elsif (ref $f eq 'ARRAY') {
      (
        (join ', ', map { $self->_quote($_) } @$f),
        @$f,
      )
    }
    elsif (ref $f eq 'SCALAR') {
      (
        $$f,
        $$f,
      )
    }
    else {
      $self->throw_exception("Unsupported INSERT RETURNING option $f");
    }
  };

  my $rc_ref = $options->{returning_container}
    or $self->throw_exception('No returning container supplied for IR values');

  @$rc_ref = (undef) x @f_names;

  return (
    ( join (' ',
      $self->_sqlcase(' returning'),
      $f_list,
      $self->_sqlcase('into'),
      join (', ', ('?') x @f_names ),
    )),
    map {
      $self->{bindtype} eq 'columns'
        ? [ $f_names[$_] => \$rc_ref->[$_] ]
        : \$rc_ref->[$_]
    } (0 .. $#f_names),
  );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::SQLMaker - Oracle-specific SQL generation for DBIO

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

L<DBIO::SQLMaker> subclass for Oracle databases. Extends standard SQL
generation with:

=over

=item * Oracle C<CONNECT BY> / C<START WITH> / C<ORDER SIBLINGS BY> hierarchical
query support via the C<connect_by>, C<connect_by_nocycle>, C<start_with>,
and C<order_siblings_by> resultset attributes.

=item * C<PRIOR> operator support in WHERE clauses.

=item * Automatic identifier shortening to fit Oracle's 30-character limit,
using an MD5-based suffix (requires L<Digest::MD5>, L<Math::BigInt>,
L<Math::Base36>).

=item * Oracle-style C<RETURNING ... INTO ?> syntax for insert-returning.

=back

Used automatically by L<DBIO::Oracle::Storage>.

=head1 METHODS

=head2 apply_limit

Oracle has no native C<LIMIT> keyword. Wrap the statement in a C<ROWNUM>
subquery via the inherited C<_RowNum> dialect instead of the base
C<LIMIT ?> syntax.

=head2 _shorten_identifier

    my $short = $sql_maker->_shorten_identifier($long_name, \@keywords);

Shortens an identifier to fit Oracle's 30-character limit. Uses camelCase
compression of C<@keywords> (or the identifier itself if none supplied),
followed by a base-36 MD5 suffix to guarantee uniqueness.

=head2 _insert_returning

Generates Oracle C<RETURNING ... INTO ?> SQL for insert-returning operations.
The returned values are captured into scalar references in the
C<returning_container> option.

=head1 SEE ALSO

=over

=item * L<DBIO::Oracle::Storage> - Oracle storage (uses this SQL maker)

=item * L<DBIO::Oracle::SQLMaker::Joins> - WHERE-clause join syntax for Oracle E<lt> 9

=item * L<DBIO::SQLMaker> - Base SQL maker class

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
