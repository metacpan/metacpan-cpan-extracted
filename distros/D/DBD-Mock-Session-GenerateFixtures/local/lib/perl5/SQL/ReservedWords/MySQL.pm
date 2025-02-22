package SQL::ReservedWords::MySQL;

use strict;
use warnings;
use vars '$VERSION';

$VERSION = '0.8';

use constant MYSQL32 => 0x01;
use constant MYSQL40 => 0x02;
use constant MYSQL41 => 0x04;
use constant MYSQL50 => 0x08;
use constant MYSQL51 => 0x10;

{
    require Sub::Exporter;

    my @exports = qw[
        is_reserved
        is_reserved_by_mysql3
        is_reserved_by_mysql4
        is_reserved_by_mysql5
        reserved_by
        words
    ];

    Sub::Exporter->import( -setup => { exports => \@exports } );
}

{
    my %WORDS = (
        ACCESSIBLE          =>                                         MYSQL51,
        ADD                 => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        ALL                 => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        ALTER               => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        ANALYZE             => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        AND                 => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        AS                  => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        ASC                 => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        ASENSITIVE          =>                               MYSQL50 | MYSQL51,
        BEFORE              =>                     MYSQL41 | MYSQL50 | MYSQL51,
        BETWEEN             => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        BIGINT              => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        BINARY              => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        BLOB                => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        BOTH                => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        BY                  => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        CALL                =>                               MYSQL50 | MYSQL51,
        CASCADE             => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        CASE                => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        CHANGE              => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        CHAR                => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        CHARACTER           => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        CHECK               =>           MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        COLLATE             =>                     MYSQL41 | MYSQL50 | MYSQL51,
        COLUMN              => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        COLUMNS             => MYSQL32 | MYSQL40 | MYSQL41,
        CONDITION           =>                               MYSQL50 | MYSQL51,
        CONNECTION          =>                               MYSQL50 | MYSQL51,
        CONSTRAINT          => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        CONTINUE            =>                               MYSQL50 | MYSQL51,
        CONVERT             =>                     MYSQL41 | MYSQL50 | MYSQL51,
        CREATE              => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        CROSS               => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        CURRENT_DATE        => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        CURRENT_TIME        => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        CURRENT_TIMESTAMP   => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        CURRENT_USER        =>                     MYSQL41 | MYSQL50 | MYSQL51,
        CURSOR              =>                               MYSQL50 | MYSQL51,
        DATABASE            => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        DATABASES           => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        DAY_HOUR            => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        DAY_MICROSECOND     =>                     MYSQL41 | MYSQL50 | MYSQL51,
        DAY_MINUTE          => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        DAY_SECOND          => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        DEC                 => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        DECIMAL             => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        DECLARE             =>                               MYSQL50 | MYSQL51,
        DEFAULT             => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        DELAYED             => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        DELETE              => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        DESC                => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        DESCRIBE            => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        DETERMINISTIC       =>                               MYSQL50 | MYSQL51,
        DISTINCT            => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        DISTINCTROW         => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        DIV                 =>                     MYSQL41 | MYSQL50 | MYSQL51,
        DOUBLE              => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        DROP                => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        DUAL                =>                     MYSQL41 | MYSQL50 | MYSQL51,
        EACH                =>                               MYSQL50 | MYSQL51,
        ELSE                => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        ELSEIF              =>                               MYSQL50 | MYSQL51,
        ENCLOSED            => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        ESCAPED             => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        EXISTS              => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        EXIT                =>                               MYSQL50 | MYSQL51,
        EXPLAIN             => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        FALSE               =>                     MYSQL41 | MYSQL50 | MYSQL51,
        FETCH               =>                               MYSQL50 | MYSQL51,
        FIELDS              => MYSQL32 | MYSQL40 | MYSQL41,
        FLOAT               => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        FLOAT4              => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        FLOAT8              => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        FOR                 => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        FORCE               =>           MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        FOREIGN             => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        FROM                => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        FULLTEXT            => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        GOTO                =>                               MYSQL50 | MYSQL51,
        GRANT               => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        GROUP               => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        HAVING              => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        HIGH_PRIORITY       => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        HOUR_MICROSECOND    =>                     MYSQL41 | MYSQL50 | MYSQL51,
        HOUR_MINUTE         => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        HOUR_SECOND         => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        IF                  => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        IGNORE              => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        IN                  => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        INDEX               => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        INFILE              => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        INNER               => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        INOUT               =>                               MYSQL50 | MYSQL51,
        INSENSITIVE         =>                               MYSQL50 | MYSQL51,
        INSERT              => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        INT                 => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        INT1                => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        INT2                => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        INT3                => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        INT4                => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        INT8                => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        INTEGER             => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        INTERVAL            => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        INTO                => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        IS                  => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        ITERATE             =>                               MYSQL50 | MYSQL51,
        JOIN                => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        KEY                 => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        KEYS                => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        KILL                => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        LABEL               =>                               MYSQL50 | MYSQL51,
        LEADING             => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        LEAVE               =>                               MYSQL50 | MYSQL51,
        LEFT                => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        LIKE                => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        LIMIT               => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        LINEAR              =>                                         MYSQL51,
        LINES               => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        LOAD                => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        LOCALTIME           =>           MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        LOCALTIMESTAMP      =>           MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        LOCK                => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        LONG                => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        LONGBLOB            => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        LONGTEXT            => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        LOOP                =>                               MYSQL50 | MYSQL51,
        LOW_PRIORITY        => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        MATCH               => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        MEDIUMBLOB          => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        MEDIUMINT           => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        MEDIUMTEXT          => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        MIDDLEINT           => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        MINUTE_MICROSECOND  =>                     MYSQL41 | MYSQL50 | MYSQL51,
        MINUTE_SECOND       => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        MOD                 =>                     MYSQL41 | MYSQL50 | MYSQL51,
        MODIFIES            =>                               MYSQL50 | MYSQL51,
        NATURAL             => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        NOT                 => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        NO_WRITE_TO_BINLOG  =>                     MYSQL41 | MYSQL50 | MYSQL51,
        NULL                => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        NUMERIC             => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        ON                  => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        OPTIMIZE            => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        OPTION              => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        OPTIONALLY          => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        OR                  => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        ORDER               => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        OUT                 =>                               MYSQL50 | MYSQL51,
        OUTER               => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        OUTFILE             => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        PRECISION           => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        PRIMARY             => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        PRIVILEGES          => MYSQL32 | MYSQL40 | MYSQL41,
        PROCEDURE           => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        PURGE               => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        RAID0               => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50,
        RANGE               =>                                         MYSQL51,
        READ                => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        READS               =>                               MYSQL50 | MYSQL51,
        READ_ONLY           =>                                         MYSQL51,
        READ_WRITE          =>                                         MYSQL51,
        REAL                => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        REFERENCES          => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        REGEXP              => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        RELEASE             =>                               MYSQL50 | MYSQL51,
        RENAME              => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        REPEAT              =>                               MYSQL50 | MYSQL51,
        REPLACE             => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        REQUIRE             =>           MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        RESTRICT            => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        RETURN              =>                               MYSQL50 | MYSQL51,
        REVOKE              => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        RIGHT               => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        RLIKE               => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        SCHEMA              =>                               MYSQL50 | MYSQL51,
        SCHEMAS             =>                               MYSQL50 | MYSQL51,
        SECOND_MICROSECOND  =>                     MYSQL41 | MYSQL50 | MYSQL51,
        SELECT              => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        SENSITIVE           =>                               MYSQL50 | MYSQL51,
        SEPARATOR           =>                     MYSQL41 | MYSQL50 | MYSQL51,
        SET                 => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        SHOW                => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        SMALLINT            => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        SONAME              => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50,
        SPATIAL             =>                     MYSQL41 | MYSQL50 | MYSQL51,
        SPECIFIC            =>                               MYSQL50 | MYSQL51,
        SQL                 =>                               MYSQL50 | MYSQL51,
        SQLEXCEPTION        =>                               MYSQL50 | MYSQL51,
        SQLSTATE            =>                               MYSQL50 | MYSQL51,
        SQLWARNING          =>                               MYSQL50 | MYSQL51,
        SQL_BIG_RESULT      => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        SQL_CALC_FOUND_ROWS =>           MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        SQL_SMALL_RESULT    => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        SSL                 =>           MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        STARTING            => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        STRAIGHT_JOIN       => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        TABLE               => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        TABLES              => MYSQL32 | MYSQL40 | MYSQL41,
        TERMINATED          => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        THEN                => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        TINYBLOB            => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        TINYINT             => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        TINYTEXT            => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        TO                  => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        TRAILING            => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        TRIGGER             =>                               MYSQL50 | MYSQL51,
        TRUE                =>                     MYSQL41 | MYSQL50 | MYSQL51,
        UNDO                =>                               MYSQL50 | MYSQL51,
        UNION               => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        UNIQUE              => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        UNLOCK              => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        UNSIGNED            => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        UPDATE              => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        UPGRADE             =>                               MYSQL50 | MYSQL51,
        USAGE               => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        USE                 => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        USING               => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        UTC_DATE            =>                     MYSQL41 | MYSQL50 | MYSQL51,
        UTC_TIME            =>                     MYSQL41 | MYSQL50 | MYSQL51,
        UTC_TIMESTAMP       =>                     MYSQL41 | MYSQL50 | MYSQL51,
        VALUES              => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        VARBINARY           => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        VARCHAR             => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        VARCHARACTER        =>                     MYSQL41 | MYSQL50 | MYSQL51,
        VARYING             => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        WHEN                => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        WHERE               => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        WHILE               =>                               MYSQL50 | MYSQL51,
        WITH                => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        WRITE               => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        X509                =>           MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        XOR                 =>           MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        YEAR_MONTH          => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
        ZEROFILL            => MYSQL32 | MYSQL40 | MYSQL41 | MYSQL50 | MYSQL51,
    );

    sub is_reserved {
        return $WORDS{ uc(pop || '') } || 0;
    }

    sub is_reserved_by_mysql3 {
        return &is_reserved & MYSQL32;
    }

    sub is_reserved_by_mysql4 {
        my $flags = &is_reserved;
        return    $flags & MYSQL40 
               || $flags & MYSQL41;
    }

    sub is_reserved_by_mysql5 {
        my $flags = &is_reserved;
        return    $flags & MYSQL50 
               || $flags & MYSQL51;
    }

    sub reserved_by {
        my $flags       = &is_reserved;
        my @reserved_by = ();

        push @reserved_by, 'MySQL 3.2' if $flags & MYSQL32;
        push @reserved_by, 'MySQL 4.0' if $flags & MYSQL40;
        push @reserved_by, 'MySQL 4.1' if $flags & MYSQL41;
        push @reserved_by, 'MySQL 5.0' if $flags & MYSQL50;
        push @reserved_by, 'MySQL 5.1' if $flags & MYSQL51;

        return @reserved_by;
    }

    sub words {
        return sort keys %WORDS;
    }
}

1;

__END__

=head1 NAME

SQL::ReservedWords::MySQL - Reserved SQL words by MySQL

=head1 SYNOPSIS

   if ( SQL::ReservedWords::MySQL->is_reserved( $word ) ) {
       print "$word is a reserved MySQL word!";
   }

=head1 DESCRIPTION

Determine if words are reserved by MySQL.

=head1 METHODS

=over 4

=item is_reserved( $word )

Returns a boolean indicating if C<$word> is reserved by either MySQL 3.2, 4.0,
4.1, 5.0 or 5.1.

=item is_reserved_by_mysql3( $word )

Returns a boolean indicating if C<$word> is reserved by MySQL 3.2.

=item is_reserved_by_mysql4( $word )

Returns a boolean indicating if C<$word> is reserved by either MySQL 4.0 or 4.1.

=item is_reserved_by_mysql5( $word )

Returns a boolean indicating if C<$word> is reserved by either MySQL 5.0 or 5.1.

=item reserved_by( $word )

Returns a list with MySQL versions that reserves C<$word>.

=item words

Returns a list with all reserved words.

=back

=head1 EXPORTS

Nothing by default. Following subroutines can be exported:

=over 4

=item is_reserved

=item is_reserved_by_mysql3

=item is_reserved_by_mysql4

=item is_reserved_by_mysql5

=item reserved_by

=item words

=back

=head1 SEE ALSO

L<SQL::ReservedWords>

L<http://dev.mysql.com/doc/>

=head1 AUTHOR

Christian Hansen C<chansen@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
