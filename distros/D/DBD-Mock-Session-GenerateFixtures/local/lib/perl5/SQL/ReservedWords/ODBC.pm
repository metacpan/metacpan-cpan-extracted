package SQL::ReservedWords::ODBC;

use strict;
use warnings;
use vars '$VERSION';

$VERSION = '0.8';

use constant ODBC30 => 0x01;

{
    require Sub::Exporter;

    my @exports = qw[
        is_reserved
        is_reserved_by_odbc3
        reserved_by
        words
    ];

    Sub::Exporter->import( -setup => { exports => \@exports } );
}

{
    my %WORDS = (
        ABSOLUTE             => ODBC30,
        ACTION               => ODBC30,
        ADA                  => ODBC30,
        ADD                  => ODBC30,
        ALL                  => ODBC30,
        ALLOCATE             => ODBC30,
        ALTER                => ODBC30,
        AND                  => ODBC30,
        ANY                  => ODBC30,
        ARE                  => ODBC30,
        AS                   => ODBC30,
        ASC                  => ODBC30,
        ASSERTION            => ODBC30,
        AT                   => ODBC30,
        AUTHORIZATION        => ODBC30,
        AVG                  => ODBC30,
        BEGIN                => ODBC30,
        BETWEEN              => ODBC30,
        BIT                  => ODBC30,
        BIT_LENGTH           => ODBC30,
        BOTH                 => ODBC30,
        BY                   => ODBC30,
        CASCADE              => ODBC30,
        CASCADED             => ODBC30,
        CASE                 => ODBC30,
        CAST                 => ODBC30,
        CATALOG              => ODBC30,
        CHAR                 => ODBC30,
        CHARACTER            => ODBC30,
        CHARACTER_LENGTH     => ODBC30,
        CHAR_LENGTH          => ODBC30,
        CHECK                => ODBC30,
        CLOSE                => ODBC30,
        COALESCE             => ODBC30,
        COLLATE              => ODBC30,
        COLLATION            => ODBC30,
        COLUMN               => ODBC30,
        COMMIT               => ODBC30,
        CONNECT              => ODBC30,
        CONNECTION           => ODBC30,
        CONSTRAINT           => ODBC30,
        CONSTRAINTS          => ODBC30,
        CONTINUE             => ODBC30,
        CONVERT              => ODBC30,
        CORRESPONDING        => ODBC30,
        COUNT                => ODBC30,
        CREATE               => ODBC30,
        CROSS                => ODBC30,
        CURRENT              => ODBC30,
        CURRENT_DATE         => ODBC30,
        CURRENT_TIME         => ODBC30,
        CURRENT_TIMESTAMP    => ODBC30,
        CURRENT_USER         => ODBC30,
        CURSOR               => ODBC30,
        DATE                 => ODBC30,
        DAY                  => ODBC30,
        DEALLOCATE           => ODBC30,
        DEC                  => ODBC30,
        DECIMAL              => ODBC30,
        DECLARE              => ODBC30,
        DEFAULT              => ODBC30,
        DEFERRABLE           => ODBC30,
        DEFERRED             => ODBC30,
        DELETE               => ODBC30,
        DESC                 => ODBC30,
        DESCRIBE             => ODBC30,
        DESCRIPTOR           => ODBC30,
        DIAGNOSTICS          => ODBC30,
        DISCONNECT           => ODBC30,
        DISTINCT             => ODBC30,
        DOMAIN               => ODBC30,
        DOUBLE               => ODBC30,
        DROP                 => ODBC30,
        ELSE                 => ODBC30,
        END                  => ODBC30,
        'END-EXEC'           => ODBC30,
        ESCAPE               => ODBC30,
        EXCEPT               => ODBC30,
        EXCEPTION            => ODBC30,
        EXEC                 => ODBC30,
        EXECUTE              => ODBC30,
        EXISTS               => ODBC30,
        EXTERNAL             => ODBC30,
        EXTRACT              => ODBC30,
        FALSE                => ODBC30,
        FETCH                => ODBC30,
        FIRST                => ODBC30,
        FLOAT                => ODBC30,
        FOR                  => ODBC30,
        FOREIGN              => ODBC30,
        FORTRAN              => ODBC30,
        FOUND                => ODBC30,
        FROM                 => ODBC30,
        FULL                 => ODBC30,
        GET                  => ODBC30,
        GLOBAL               => ODBC30,
        GO                   => ODBC30,
        GOTO                 => ODBC30,
        GRANT                => ODBC30,
        GROUP                => ODBC30,
        HAVING               => ODBC30,
        HOUR                 => ODBC30,
        IDENTITY             => ODBC30,
        IMMEDIATE            => ODBC30,
        IN                   => ODBC30,
        INCLUDE              => ODBC30,
        INDEX                => ODBC30,
        INDICATOR            => ODBC30,
        INITIALLY            => ODBC30,
        INNER                => ODBC30,
        INPUT                => ODBC30,
        INSENSITIVE          => ODBC30,
        INSERT               => ODBC30,
        INT                  => ODBC30,
        INTEGER              => ODBC30,
        INTERSECT            => ODBC30,
        INTERVAL             => ODBC30,
        INTO                 => ODBC30,
        IS                   => ODBC30,
        ISOLATION            => ODBC30,
        JOIN                 => ODBC30,
        KEY                  => ODBC30,
        LANGUAGE             => ODBC30,
        LAST                 => ODBC30,
        LEADING              => ODBC30,
        LEFT                 => ODBC30,
        LEVEL                => ODBC30,
        LIKE                 => ODBC30,
        LOCAL                => ODBC30,
        LOWER                => ODBC30,
        MATCH                => ODBC30,
        MAX                  => ODBC30,
        MIN                  => ODBC30,
        MINUTE               => ODBC30,
        MODULE               => ODBC30,
        MONTH                => ODBC30,
        NAMES                => ODBC30,
        NATIONAL             => ODBC30,
        NATURAL              => ODBC30,
        NCHAR                => ODBC30,
        NEXT                 => ODBC30,
        NO                   => ODBC30,
        NONE                 => ODBC30,
        NOT                  => ODBC30,
        NULL                 => ODBC30,
        NULLIF               => ODBC30,
        NUMERIC              => ODBC30,
        OCTET_LENGTH         => ODBC30,
        OF                   => ODBC30,
        ON                   => ODBC30,
        ONLY                 => ODBC30,
        OPEN                 => ODBC30,
        OPTION               => ODBC30,
        OR                   => ODBC30,
        ORDER                => ODBC30,
        OUTER                => ODBC30,
        OUTPUT               => ODBC30,
        OVERLAPS             => ODBC30,
        PAD                  => ODBC30,
        PARTIAL              => ODBC30,
        PASCAL               => ODBC30,
        POSITION             => ODBC30,
        PRECISION            => ODBC30,
        PREPARE              => ODBC30,
        PRESERVE             => ODBC30,
        PRIMARY              => ODBC30,
        PRIOR                => ODBC30,
        PRIVILEGES           => ODBC30,
        PROCEDURE            => ODBC30,
        PUBLIC               => ODBC30,
        READ                 => ODBC30,
        REAL                 => ODBC30,
        REFERENCES           => ODBC30,
        RELATIVE             => ODBC30,
        RESTRICT             => ODBC30,
        REVOKE               => ODBC30,
        RIGHT                => ODBC30,
        ROLLBACK             => ODBC30,
        ROWS                 => ODBC30,
        SCHEMA               => ODBC30,
        SCROLL               => ODBC30,
        SECOND               => ODBC30,
        SECTION              => ODBC30,
        SELECT               => ODBC30,
        SESSION              => ODBC30,
        SESSION_USER         => ODBC30,
        SET                  => ODBC30,
        SIZE                 => ODBC30,
        SMALLINT             => ODBC30,
        SOME                 => ODBC30,
        SPACE                => ODBC30,
        SQL                  => ODBC30,
        SQLCA                => ODBC30,
        SQLCODE              => ODBC30,
        SQLERROR             => ODBC30,
        SQLSTATE             => ODBC30,
        SQLWARNING           => ODBC30,
        SUBSTRING            => ODBC30,
        SUM                  => ODBC30,
        SYSTEM_USER          => ODBC30,
        TABLE                => ODBC30,
        TEMPORARY            => ODBC30,
        THEN                 => ODBC30,
        TIME                 => ODBC30,
        TIMESTAMP            => ODBC30,
        TIMEZONE_HOUR        => ODBC30,
        TIMEZONE_MINUTE      => ODBC30,
        TO                   => ODBC30,
        TRAILING             => ODBC30,
        TRANSACTION          => ODBC30,
        TRANSLATE            => ODBC30,
        TRANSLATION          => ODBC30,
        TRIM                 => ODBC30,
        TRUE                 => ODBC30,
        UNION                => ODBC30,
        UNIQUE               => ODBC30,
        UNKNOWN              => ODBC30,
        UPDATE               => ODBC30,
        UPPER                => ODBC30,
        USAGE                => ODBC30,
        USER                 => ODBC30,
        USING                => ODBC30,
        VALUE                => ODBC30,
        VALUES               => ODBC30,
        VARCHAR              => ODBC30,
        VARYING              => ODBC30,
        VIEW                 => ODBC30,
        WHEN                 => ODBC30,
        WHENEVER             => ODBC30,
        WHERE                => ODBC30,
        WITH                 => ODBC30,
        WORK                 => ODBC30,
        WRITE                => ODBC30,
        YEAR                 => ODBC30,
        ZONE                 => ODBC30,
    );

    sub is_reserved {
        return $WORDS{ uc(pop || '') } || 0;
    }

    sub is_reserved_by_odbc3 {
        return &is_reserved & ODBC30;
    }

    sub reserved_by {
        my $flags       = &is_reserved;
        my @reserved_by = ();

        push @reserved_by, 'ODBC 3.0' if $flags & ODBC30;

        return @reserved_by;
    }

    sub words {
        return sort keys %WORDS;
    }
}

1;

__END__

=head1 NAME

SQL::ReservedWords::ODBC - Reserved SQL words by ODBC

=head1 SYNOPSIS

   if ( SQL::ReservedWords::ODBC->is_reserved( $word ) ) {
       print "$word is a reserved ODBC word!";
   }

=head1 DESCRIPTION

Determine if words are reserved by ODBC.

=head1 METHODS

=over 4

=item is_reserved( $word )

Returns a boolean indicating if C<$word> is reserved by ODBC 3.0.

=item is_reserved_by_odbc3( $word )

Returns a boolean indicating if C<$word> is reserved by ODBC 3.0.

=item reserved_by( $word )

Returns a list with ODBC versions that reserves C<$word>.

=item words

Returns a list with all reserved words.

=back

=head1 EXPORTS

Nothing by default. Following subroutines can be exported:

=over 4

=item is_reserved

=item is_reserved_by_odbc3

=item reserved_by

=item words

=back

=head1 SEE ALSO

L<SQL::ReservedWords>.

Microsoft ODBC 3.0 Programmer's Reference, Volume 2, Appendix C.

=head1 AUTHOR

Christian Hansen C<chansen@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
