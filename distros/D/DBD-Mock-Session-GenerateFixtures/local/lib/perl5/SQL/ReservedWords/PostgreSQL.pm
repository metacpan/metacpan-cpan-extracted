package SQL::ReservedWords::PostgreSQL;

use strict;
use warnings;
use vars '$VERSION';

$VERSION = '0.8';

use constant POSTGRESQL73 => 0x01;
use constant POSTGRESQL74 => 0x02;
use constant POSTGRESQL80 => 0x04;
use constant POSTGRESQL81 => 0x08;

{
    require Sub::Exporter;

    my @exports = qw[
        is_reserved
        is_reserved_by_postgresql7
        is_reserved_by_postgresql8
        reserved_by
        words
    ];

    Sub::Exporter->import( -setup => { exports => \@exports } );
}

{
    my %WORDS = (
        ALL                 => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        ANALYSE             => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        ANALYZE             => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        AND                 => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        ANY                 => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        ARRAY               =>                POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        AS                  => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        ASC                 => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        ASYMMETRIC          =>                                              POSTGRESQL81,
        AUTHORIZATION       => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        BETWEEN             => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        BINARY              => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        BOTH                => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        CASE                => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        CAST                => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        CHECK               => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        COLLATE             => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        COLUMN              => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        CONSTRAINT          => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        CREATE              => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        CROSS               => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        CURRENT_DATE        => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        CURRENT_ROLE        =>                                              POSTGRESQL81,
        CURRENT_TIME        => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        CURRENT_TIMESTAMP   => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        CURRENT_USER        => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        DEFAULT             => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        DEFERRABLE          => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        DESC                => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        DISTINCT            => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        DO                  => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        ELSE                => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        END                 => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        EXCEPT              => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        FALSE               => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        FOR                 => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        FOREIGN             => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        FREEZE              => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        FROM                => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        FULL                => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        GRANT               => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        GROUP               => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        HAVING              => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        ILIKE               => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        IN                  => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        INITIALLY           => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        INNER               => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        INTERSECT           => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        INTO                => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        IS                  => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        ISNULL              => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        JOIN                => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        LEADING             => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        LEFT                => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        LIKE                => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        LIMIT               => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        LOCALTIME           => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        LOCALTIMESTAMP      => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        NATURAL             => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        NEW                 => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        NOT                 => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        NOTNULL             => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        NULL                => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        OFF                 => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        OFFSET              => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        OLD                 => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        ON                  => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        ONLY                => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        OR                  => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        ORDER               => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        OUTER               => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        OVERLAPS            => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        PLACING             => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        PRIMARY             => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        REFERENCES          => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        RIGHT               => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        SELECT              => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        SESSION_USER        => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        SIMILAR             => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        SOME                => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        SYMMETRIC           =>                                              POSTGRESQL81,
        TABLE               => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        THEN                => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        TO                  => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        TRAILING            => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        TRUE                => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        UNION               => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        UNIQUE              => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        USER                => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        USING               => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        VERBOSE             => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        WHEN                => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
        WHERE               => POSTGRESQL73 | POSTGRESQL74 | POSTGRESQL80 | POSTGRESQL81,
    );

    sub is_reserved {
        return $WORDS{ uc(pop || '') } || 0;
    }

    sub is_reserved_by_postgresql7 {
        my $flags = &is_reserved;
        return $flags & POSTGRESQL73 || $flags & POSTGRESQL74;
    }

    sub is_reserved_by_postgresql8 {
        my $flags = &is_reserved;
        return $flags & POSTGRESQL80 || $flags & POSTGRESQL81;
    }

    sub reserved_by {
        my $flags       = &is_reserved;
        my @reserved_by = ();

        push @reserved_by, 'PostgreSQL 7.3' if $flags & POSTGRESQL73;
        push @reserved_by, 'PostgreSQL 7.4' if $flags & POSTGRESQL74;
        push @reserved_by, 'PostgreSQL 8.0' if $flags & POSTGRESQL80;
        push @reserved_by, 'PostgreSQL 8.1' if $flags & POSTGRESQL81;

        return @reserved_by;
    }

    sub words {
        return sort keys %WORDS;
    }
}

1;

__END__

=head1 NAME

SQL::ReservedWords::PostgreSQL - Reserved SQL words by PostgreSQL

=head1 SYNOPSIS

   if ( SQL::ReservedWords::PostgreSQL->is_reserved( $word ) ) {
       print "$word is a reserved PostgreSQL word!";
   }

=head1 DESCRIPTION

Determine if words are reserved by PostgreSQL.

=head1 METHODS

=over 4

=item is_reserved( $word )

Returns a boolean indicating if C<$word> is reserved by either PostgreSQL 7.3, 7.4,
8.0 or 8.1.

=item is_reserved_by_postgresql7( $word )

Returns a boolean indicating if C<$word> is reserved by either PostgreSQL 7.3 or 7.4.

=item is_reserved_by_postgresql8( $word )

Returns a boolean indicating if C<$word> is reserved by either PostgreSQL 8.0 or 8.1.

=item reserved_by( $word )

Returns a list with PostgreSQL versions that reserves C<$word>.

=item words

Returns a list with all reserved words.

=back

=head1 EXPORTS

Nothing by default. Following subroutines can be exported:

=over 4

=item is_reserved

=item is_reserved_by_postgresql7

=item is_reserved_by_postgresql8

=item reserved_by

=item words

=back

=head1 SEE ALSO

L<SQL::ReservedWords>

L<http://www.postgresql.org/docs/manuals/>

=head1 AUTHOR

Christian Hansen C<chansen@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
