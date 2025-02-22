package SQL::ReservedWords;

use strict;
use warnings;
use vars '$VERSION';

$VERSION = '0.8';

use constant SQL1992 => 0x01;
use constant SQL1999 => 0x02;
use constant SQL2003 => 0x04;

{
    require Sub::Exporter;

    my @exports = qw[
        is_reserved
        is_reserved_by_sql1992
        is_reserved_by_sql1999
        is_reserved_by_sql2003
        reserved_by
        words
    ];

    Sub::Exporter->import( -setup => { exports => \@exports } );
}

{
    my %WORDS = (
        ABSOLUTE                          => SQL1992 | SQL1999,
        ACTION                            => SQL1992 | SQL1999,
        ADD                               => SQL1992 | SQL1999 | SQL2003,
        AFTER                             =>           SQL1999,
        ALL                               => SQL1992 | SQL1999 | SQL2003,
        ALLOCATE                          => SQL1992 | SQL1999 | SQL2003,
        ALTER                             => SQL1992 | SQL1999 | SQL2003,
        AND                               => SQL1992 | SQL1999 | SQL2003,
        ANY                               => SQL1992 | SQL1999 | SQL2003,
        ARE                               => SQL1992 | SQL1999 | SQL2003,
        ARRAY                             =>           SQL1999 | SQL2003,
        AS                                => SQL1992 | SQL1999 | SQL2003,
        ASC                               => SQL1992 | SQL1999,
        ASENSITIVE                        =>           SQL1999 | SQL2003,
        ASSERTION                         => SQL1992 | SQL1999,
        ASYMMETRIC                        =>           SQL1999 | SQL2003,
        AT                                => SQL1992 | SQL1999 | SQL2003,
        ATOMIC                            =>           SQL1999 | SQL2003,
        AUTHORIZATION                     => SQL1992 | SQL1999 | SQL2003,
        AVG                               => SQL1992,
        BEFORE                            =>           SQL1999,
        BEGIN                             => SQL1992 | SQL1999 | SQL2003,
        BETWEEN                           => SQL1992 | SQL1999 | SQL2003,
        BIGINT                            =>                     SQL2003,
        BINARY                            =>           SQL1999 | SQL2003,
        BIT                               => SQL1992 | SQL1999,
        BIT_LENGTH                        => SQL1992,
        BLOB                              =>           SQL1999 | SQL2003,
        BOOLEAN                           =>           SQL1999 | SQL2003,
        BOTH                              => SQL1992 | SQL1999 | SQL2003,
        BREADTH                           =>           SQL1999,
        BY                                => SQL1992 | SQL1999 | SQL2003,
        CALL                              => SQL1992 | SQL1999 | SQL2003,
        CALLED                            =>           SQL1999 | SQL2003,
        CASCADE                           => SQL1992 | SQL1999,
        CASCADED                          => SQL1992 | SQL1999 | SQL2003,
        CASE                              => SQL1992 | SQL1999 | SQL2003,
        CAST                              => SQL1992 | SQL1999 | SQL2003,
        CATALOG                           => SQL1992 | SQL1999,
        CHAR                              => SQL1992 | SQL1999 | SQL2003,
        CHARACTER                         => SQL1992 | SQL1999 | SQL2003,
        CHARACTER_LENGTH                  => SQL1992,
        CHAR_LENGTH                       => SQL1992,
        CHECK                             => SQL1992 | SQL1999 | SQL2003,
        CLOB                              =>           SQL1999 | SQL2003,
        CLOSE                             => SQL1992 | SQL1999 | SQL2003,
        COALESCE                          => SQL1992,
        COLLATE                           => SQL1992 | SQL1999 | SQL2003,
        COLLATION                         => SQL1992 | SQL1999,
        COLUMN                            => SQL1992 | SQL1999 | SQL2003,
        COMMIT                            => SQL1992 | SQL1999 | SQL2003,
        CONDITION                         => SQL1992 | SQL1999 | SQL2003,
        CONNECT                           => SQL1992 | SQL1999 | SQL2003,
        CONNECTION                        => SQL1992 | SQL1999,
        CONSTRAINT                        => SQL1992 | SQL1999 | SQL2003,
        CONSTRAINTS                       => SQL1992 | SQL1999,
        CONSTRUCTOR                       =>           SQL1999,
        CONTAINS                          => SQL1992,
        CONTINUE                          => SQL1992 | SQL1999 | SQL2003,
        CONVERT                           => SQL1992,
        CORRESPONDING                     => SQL1992 | SQL1999 | SQL2003,
        COUNT                             => SQL1992,
        CREATE                            => SQL1992 | SQL1999 | SQL2003,
        CROSS                             => SQL1992 | SQL1999 | SQL2003,
        CUBE                              =>           SQL1999 | SQL2003,
        CURRENT                           => SQL1992 | SQL1999 | SQL2003,
        CURRENT_DATE                      => SQL1992 | SQL1999 | SQL2003,
        CURRENT_DEFAULT_TRANSFORM_GROUP   =>           SQL1999 | SQL2003,
        CURRENT_PATH                      => SQL1992 | SQL1999 | SQL2003,
        CURRENT_ROLE                      =>           SQL1999 | SQL2003,
        CURRENT_TIME                      => SQL1992 | SQL1999 | SQL2003,
        CURRENT_TIMESTAMP                 => SQL1992 | SQL1999 | SQL2003,
        CURRENT_TRANSFORM_GROUP_FOR_TYPE  =>           SQL1999 | SQL2003,
        CURRENT_USER                      => SQL1992 | SQL1999 | SQL2003,
        CURSOR                            => SQL1992 | SQL1999 | SQL2003,
        CYCLE                             =>           SQL1999 | SQL2003,
        DATA                              =>           SQL1999,
        DATE                              => SQL1992 | SQL1999 | SQL2003,
        DAY                               => SQL1992 | SQL1999 | SQL2003,
        DEALLOCATE                        => SQL1992 | SQL1999 | SQL2003,
        DEC                               => SQL1992 | SQL1999 | SQL2003,
        DECIMAL                           => SQL1992 | SQL1999 | SQL2003,
        DECLARE                           => SQL1992 | SQL1999 | SQL2003,
        DEFAULT                           => SQL1992 | SQL1999 | SQL2003,
        DEFERRABLE                        => SQL1992 | SQL1999,
        DEFERRED                          => SQL1992 | SQL1999,
        DELETE                            => SQL1992 | SQL1999 | SQL2003,
        DEPTH                             =>           SQL1999,
        DEREF                             =>           SQL1999 | SQL2003,
        DESC                              => SQL1992 | SQL1999,
        DESCRIBE                          => SQL1992 | SQL1999 | SQL2003,
        DESCRIPTOR                        => SQL1992 | SQL1999,
        DETERMINISTIC                     => SQL1992 | SQL1999 | SQL2003,
        DIAGNOSTICS                       => SQL1992 | SQL1999,
        DISCONNECT                        => SQL1992 | SQL1999 | SQL2003,
        DISTINCT                          => SQL1992 | SQL1999 | SQL2003,
        DO                                => SQL1992 | SQL1999 | SQL2003,
        DOMAIN                            => SQL1992 | SQL1999,
        DOUBLE                            => SQL1992 | SQL1999 | SQL2003,
        DROP                              => SQL1992 | SQL1999 | SQL2003,
        DYNAMIC                           =>           SQL1999 | SQL2003,
        EACH                              =>           SQL1999 | SQL2003,
        ELEMENT                           =>                     SQL2003,
        ELSE                              => SQL1992 | SQL1999 | SQL2003,
        ELSEIF                            => SQL1992 | SQL1999 | SQL2003,
        END                               => SQL1992 | SQL1999 | SQL2003,
        EQUALS                            =>           SQL1999,
        ESCAPE                            => SQL1992 | SQL1999 | SQL2003,
        EXCEPT                            => SQL1992 | SQL1999 | SQL2003,
        EXCEPTION                         => SQL1992 | SQL1999,
        EXEC                              => SQL1992 | SQL1999 | SQL2003,
        EXECUTE                           => SQL1992 | SQL1999 | SQL2003,
        EXISTS                            => SQL1992 | SQL1999 | SQL2003,
        EXIT                              => SQL1992 | SQL1999 | SQL2003,
        EXTERNAL                          => SQL1992 | SQL1999 | SQL2003,
        EXTRACT                           => SQL1992,
        FALSE                             => SQL1992 | SQL1999 | SQL2003,
        FETCH                             => SQL1992 | SQL1999 | SQL2003,
        FILTER                            =>           SQL1999 | SQL2003,
        FIRST                             => SQL1992 | SQL1999,
        FLOAT                             => SQL1992 | SQL1999 | SQL2003,
        FOR                               => SQL1992 | SQL1999 | SQL2003,
        FOREIGN                           => SQL1992 | SQL1999 | SQL2003,
        FOUND                             => SQL1992 | SQL1999,
        FREE                              =>           SQL1999 | SQL2003,
        FROM                              => SQL1992 | SQL1999 | SQL2003,
        FULL                              => SQL1992 | SQL1999 | SQL2003,
        FUNCTION                          => SQL1992 | SQL1999 | SQL2003,
        GENERAL                           =>           SQL1999,
        GET                               => SQL1992 | SQL1999 | SQL2003,
        GLOBAL                            => SQL1992 | SQL1999 | SQL2003,
        GO                                => SQL1992 | SQL1999,
        GOTO                              => SQL1992 | SQL1999,
        GRANT                             => SQL1992 | SQL1999 | SQL2003,
        GROUP                             => SQL1992 | SQL1999 | SQL2003,
        GROUPING                          =>           SQL1999 | SQL2003,
        HANDLER                           => SQL1992 | SQL1999 | SQL2003,
        HAVING                            => SQL1992 | SQL1999 | SQL2003,
        HOLD                              =>           SQL1999 | SQL2003,
        HOUR                              => SQL1992 | SQL1999 | SQL2003,
        IDENTITY                          => SQL1992 | SQL1999 | SQL2003,
        IF                                => SQL1992 | SQL1999 | SQL2003,
        IMMEDIATE                         => SQL1992 | SQL1999 | SQL2003,
        IN                                => SQL1992 | SQL1999 | SQL2003,
        INDICATOR                         => SQL1992 | SQL1999 | SQL2003,
        INITIALLY                         => SQL1992 | SQL1999,
        INNER                             => SQL1992 | SQL1999 | SQL2003,
        INOUT                             => SQL1992 | SQL1999 | SQL2003,
        INPUT                             => SQL1992 | SQL1999 | SQL2003,
        INSENSITIVE                       => SQL1992 | SQL1999 | SQL2003,
        INSERT                            => SQL1992 | SQL1999 | SQL2003,
        INT                               => SQL1992 | SQL1999 | SQL2003,
        INTEGER                           => SQL1992 | SQL1999 | SQL2003,
        INTERSECT                         => SQL1992 | SQL1999 | SQL2003,
        INTERVAL                          => SQL1992 | SQL1999 | SQL2003,
        INTO                              => SQL1992 | SQL1999 | SQL2003,
        IS                                => SQL1992 | SQL1999 | SQL2003,
        ISOLATION                         => SQL1992 | SQL1999,
        ITERATE                           =>           SQL1999 | SQL2003,
        JOIN                              => SQL1992 | SQL1999 | SQL2003,
        KEY                               => SQL1992 | SQL1999,
        LANGUAGE                          => SQL1992 | SQL1999 | SQL2003,
        LARGE                             =>           SQL1999 | SQL2003,
        LAST                              => SQL1992 | SQL1999,
        LATERAL                           =>           SQL1999 | SQL2003,
        LEADING                           => SQL1992 | SQL1999 | SQL2003,
        LEAVE                             => SQL1992 | SQL1999 | SQL2003,
        LEFT                              => SQL1992 | SQL1999 | SQL2003,
        LEVEL                             => SQL1992 | SQL1999,
        LIKE                              => SQL1992 | SQL1999 | SQL2003,
        LOCAL                             => SQL1992 | SQL1999 | SQL2003,
        LOCALTIME                         =>           SQL1999 | SQL2003,
        LOCALTIMESTAMP                    =>           SQL1999 | SQL2003,
        LOCATOR                           =>           SQL1999,
        LOOP                              => SQL1992 | SQL1999 | SQL2003,
        LOWER                             => SQL1992,
        MAP                               =>           SQL1999,
        MATCH                             => SQL1992 | SQL1999 | SQL2003,
        MAX                               => SQL1992,
        MEMBER                            =>                     SQL2003,
        MERGE                             =>                     SQL2003,
        METHOD                            =>           SQL1999 | SQL2003,
        MIN                               => SQL1992,
        MINUTE                            => SQL1992 | SQL1999 | SQL2003,
        MODIFIES                          =>           SQL1999 | SQL2003,
        MODULE                            => SQL1992 | SQL1999 | SQL2003,
        MONTH                             => SQL1992 | SQL1999 | SQL2003,
        MULTISET                          =>                     SQL2003,
        NAMES                             => SQL1992 | SQL1999,
        NATIONAL                          => SQL1992 | SQL1999 | SQL2003,
        NATURAL                           => SQL1992 | SQL1999 | SQL2003,
        NCHAR                             => SQL1992 | SQL1999 | SQL2003,
        NCLOB                             =>           SQL1999 | SQL2003,
        NEW                               =>           SQL1999 | SQL2003,
        NEXT                              => SQL1992 | SQL1999,
        NO                                => SQL1992 | SQL1999 | SQL2003,
        NONE                              =>           SQL1999 | SQL2003,
        NOT                               => SQL1992 | SQL1999 | SQL2003,
        NULL                              => SQL1992 | SQL1999 | SQL2003,
        NULLIF                            => SQL1992,
        NUMERIC                           => SQL1992 | SQL1999 | SQL2003,
        OBJECT                            =>           SQL1999,
        OCTET_LENGTH                      => SQL1992,
        OF                                => SQL1992 | SQL1999 | SQL2003,
        OLD                               =>           SQL1999 | SQL2003,
        ON                                => SQL1992 | SQL1999 | SQL2003,
        ONLY                              => SQL1992 | SQL1999 | SQL2003,
        OPEN                              => SQL1992 | SQL1999 | SQL2003,
        OPTION                            => SQL1992 | SQL1999,
        OR                                => SQL1992 | SQL1999 | SQL2003,
        ORDER                             => SQL1992 | SQL1999 | SQL2003,
        ORDINALITY                        =>           SQL1999,
        OUT                               => SQL1992 | SQL1999 | SQL2003,
        OUTER                             => SQL1992 | SQL1999 | SQL2003,
        OUTPUT                            => SQL1992 | SQL1999 | SQL2003,
        OVER                              =>           SQL1999 | SQL2003,
        OVERLAPS                          => SQL1992 | SQL1999 | SQL2003,
        PAD                               => SQL1992 | SQL1999,
        PARAMETER                         => SQL1992 | SQL1999 | SQL2003,
        PARTIAL                           => SQL1992 | SQL1999,
        PARTITION                         =>           SQL1999 | SQL2003,
        PATH                              => SQL1992 | SQL1999,
        POSITION                          => SQL1992,
        PRECISION                         => SQL1992 | SQL1999 | SQL2003,
        PREPARE                           => SQL1992 | SQL1999 | SQL2003,
        PRESERVE                          => SQL1992 | SQL1999,
        PRIMARY                           => SQL1992 | SQL1999 | SQL2003,
        PRIOR                             => SQL1992 | SQL1999,
        PRIVILEGES                        => SQL1992 | SQL1999,
        PROCEDURE                         => SQL1992 | SQL1999 | SQL2003,
        PUBLIC                            => SQL1992 | SQL1999,
        RANGE                             =>           SQL1999 | SQL2003,
        READ                              => SQL1992 | SQL1999,
        READS                             =>           SQL1999 | SQL2003,
        REAL                              => SQL1992 | SQL1999 | SQL2003,
        RECURSIVE                         =>           SQL1999 | SQL2003,
        REF                               =>           SQL1999 | SQL2003,
        REFERENCES                        => SQL1992 | SQL1999 | SQL2003,
        REFERENCING                       =>           SQL1999 | SQL2003,
        RELATIVE                          => SQL1992 | SQL1999,
        RELEASE                           =>           SQL1999 | SQL2003,
        REPEAT                            => SQL1992 | SQL1999 | SQL2003,
        RESIGNAL                          => SQL1992 | SQL1999 | SQL2003,
        RESTRICT                          => SQL1992 | SQL1999,
        RESULT                            =>           SQL1999 | SQL2003,
        RETURN                            => SQL1992 | SQL1999 | SQL2003,
        RETURNS                           => SQL1992 | SQL1999 | SQL2003,
        REVOKE                            => SQL1992 | SQL1999 | SQL2003,
        RIGHT                             => SQL1992 | SQL1999 | SQL2003,
        ROLE                              =>           SQL1999,
        ROLLBACK                          => SQL1992 | SQL1999 | SQL2003,
        ROLLUP                            =>           SQL1999 | SQL2003,
        ROUTINE                           => SQL1992 | SQL1999,
        ROW                               =>           SQL1999 | SQL2003,
        ROWS                              => SQL1992 | SQL1999 | SQL2003,
        SAVEPOINT                         =>           SQL1999 | SQL2003,
        SCHEMA                            => SQL1992 | SQL1999,
        SCOPE                             =>           SQL1999 | SQL2003,
        SCROLL                            => SQL1992 | SQL1999 | SQL2003,
        SEARCH                            =>           SQL1999 | SQL2003,
        SECOND                            => SQL1992 | SQL1999 | SQL2003,
        SECTION                           => SQL1992 | SQL1999,
        SELECT                            => SQL1992 | SQL1999 | SQL2003,
        SENSITIVE                         =>           SQL1999 | SQL2003,
        SESSION                           => SQL1992 | SQL1999,
        SESSION_USER                      => SQL1992 | SQL1999 | SQL2003,
        SET                               => SQL1992 | SQL1999 | SQL2003,
        SETS                              =>           SQL1999,
        SIGNAL                            => SQL1992 | SQL1999 | SQL2003,
        SIMILAR                           =>           SQL1999 | SQL2003,
        SIZE                              => SQL1992 | SQL1999,
        SMALLINT                          => SQL1992 | SQL1999 | SQL2003,
        SOME                              => SQL1992 | SQL1999 | SQL2003,
        SPACE                             => SQL1992 | SQL1999,
        SPECIFIC                          => SQL1992 | SQL1999 | SQL2003,
        SPECIFICTYPE                      =>           SQL1999 | SQL2003,
        SQL                               => SQL1992 | SQL1999 | SQL2003,
        SQLCODE                           => SQL1992,
        SQLERROR                          => SQL1992,
        SQLEXCEPTION                      => SQL1992 | SQL1999 | SQL2003,
        SQLSTATE                          => SQL1992 | SQL1999 | SQL2003,
        SQLWARNING                        => SQL1992 | SQL1999 | SQL2003,
        START                             =>           SQL1999 | SQL2003,
        STATE                             =>           SQL1999,
        STATIC                            =>           SQL1999 | SQL2003,
        SUBMULTISET                       =>                     SQL2003,
        SUBSTRING                         => SQL1992,
        SUM                               => SQL1992,
        SYMMETRIC                         =>           SQL1999 | SQL2003,
        SYSTEM                            =>           SQL1999 | SQL2003,
        SYSTEM_USER                       => SQL1992 | SQL1999 | SQL2003,
        TABLE                             => SQL1992 | SQL1999 | SQL2003,
        TABLESAMPLE                       =>                     SQL2003,
        TEMPORARY                         => SQL1992 | SQL1999,
        THEN                              => SQL1992 | SQL1999 | SQL2003,
        TIME                              => SQL1992 | SQL1999 | SQL2003,
        TIMESTAMP                         => SQL1992 | SQL1999 | SQL2003,
        TIMEZONE_HOUR                     => SQL1992 | SQL1999 | SQL2003,
        TIMEZONE_MINUTE                   => SQL1992 | SQL1999 | SQL2003,
        TO                                => SQL1992 | SQL1999 | SQL2003,
        TRAILING                          => SQL1992 | SQL1999 | SQL2003,
        TRANSACTION                       => SQL1992 | SQL1999,
        TRANSLATE                         => SQL1992,
        TRANSLATION                       => SQL1992 | SQL1999 | SQL2003,
        TREAT                             =>           SQL1999 | SQL2003,
        TRIGGER                           =>           SQL1999 | SQL2003,
        TRIM                              => SQL1992,
        TRUE                              => SQL1992 | SQL1999 | SQL2003,
        UNDER                             =>           SQL1999,
        UNDO                              => SQL1992 | SQL1999 | SQL2003,
        UNION                             => SQL1992 | SQL1999 | SQL2003,
        UNIQUE                            => SQL1992 | SQL1999 | SQL2003,
        UNKNOWN                           => SQL1992 | SQL1999 | SQL2003,
        UNNEST                            =>           SQL1999 | SQL2003,
        UNTIL                             => SQL1992 | SQL1999 | SQL2003,
        UPDATE                            => SQL1992 | SQL1999 | SQL2003,
        UPPER                             => SQL1992,
        USAGE                             => SQL1992 | SQL1999,
        USER                              => SQL1992 | SQL1999 | SQL2003,
        USING                             => SQL1992 | SQL1999 | SQL2003,
        VALUE                             => SQL1992 | SQL1999 | SQL2003,
        VALUES                            => SQL1992 | SQL1999 | SQL2003,
        VARCHAR                           => SQL1992 | SQL1999 | SQL2003,
        VARYING                           => SQL1992 | SQL1999 | SQL2003,
        VIEW                              => SQL1992 | SQL1999,
        WHEN                              => SQL1992 | SQL1999 | SQL2003,
        WHENEVER                          => SQL1992 | SQL1999 | SQL2003,
        WHERE                             => SQL1992 | SQL1999 | SQL2003,
        WHILE                             => SQL1992 | SQL1999 | SQL2003,
        WINDOW                            =>           SQL1999 | SQL2003,
        WITH                              => SQL1992 | SQL1999 | SQL2003,
        WITHIN                            =>           SQL1999 | SQL2003,
        WITHOUT                           =>           SQL1999 | SQL2003,
        WORK                              => SQL1992 | SQL1999,
        WRITE                             => SQL1992 | SQL1999,
        YEAR                              => SQL1992 | SQL1999 | SQL2003,
        ZONE                              => SQL1992 | SQL1999
    );

    sub is_reserved {
        return $WORDS{ uc(pop || '') } || 0;
    }

    sub is_reserved_by_sql1992 {
        return &is_reserved & SQL1992;
    }

    sub is_reserved_by_sql1999 {
        return &is_reserved & SQL1999;
    }

    sub is_reserved_by_sql2003 {
        return &is_reserved & SQL2003;
    }

    sub reserved_by {
        my $flags       = &is_reserved;
        my @reserved_by = ();

        push @reserved_by, 'SQL:1992' if $flags & SQL1992;
        push @reserved_by, 'SQL:1999' if $flags & SQL1999;
        push @reserved_by, 'SQL:2003' if $flags & SQL2003;

        return @reserved_by;
    }

    sub words {
        return sort keys %WORDS;
    }
}

1;

__END__

=head1 NAME

SQL::ReservedWords - Reserved SQL words by ANSI/ISO

=head1 SYNOPSIS

   if ( SQL::ReservedWords->is_reserved( $word ) ) {
       print "$word is a reserved SQL word!";
   }

=head1 DESCRIPTION

Determine if words are reserved by ANSI/ISO SQL standard.

=head1 METHODS

=over 4

=item is_reserved( $word )

Returns a boolean indicating if C<$word> is reserved by either C<SQL:1992>,
C<SQL:1999> or C<SQL:2003>.

=item is_reserved_by_sql1992( $word )

Returns a boolean indicating if C<$word> is reserved by C<SQL:1992>.

=item is_reserved_by_sql1999( $word )

Returns a boolean indicating if C<$word> is reserved by C<SQL:1999>.

=item is_reserved_by_sql2003( $word )

Returns a boolean indicating if C<$word> is reserved by C<SQL:2003>.

=item reserved_by( $word )

Returns a list with SQL standards that reserves C<$word>.

=item words

Returns a list with all reserved words.

=back

=head1 EXPORTS

Nothing by default. Following subroutines can be exported:

=over 4

=item is_reserved

=item is_reserved_by_sql1992

=item is_reserved_by_sql1999

=item is_reserved_by_sql2003

=item reserved_by

=item words

=back

=head1 SEE ALSO

L<SQL::ReservedWords::DB2>

L<SQL::ReservedWords::MySQL>

L<SQL::ReservedWords::ODBC>

L<SQL::ReservedWords::Oracle>

L<SQL::ReservedWords::PostgreSQL>

L<SQL::ReservedWords::SQLite>

L<SQL::ReservedWords::SQLServer>

ISO/IEC 9075:1992 Database languages -- SQL

ISO/IEC 9075-2:1999 Database languages -- SQL -- Part 2: Foundation (SQL/Foundation)

ISO/IEC 9075-2:2003 Database languages -- SQL -- Part 2: Foundation (SQL/Foundation)

=head1 AUTHOR

Christian Hansen C<chansen@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
