package SQL::ReservedWords::SQLServer;

use strict;
use warnings;
use vars '$VERSION';

$VERSION = '0.8';

use constant SQLSERVER7    => 0x01;
use constant SQLSERVER2000 => 0x02;
use constant SQLSERVER2005 => 0x04;

{
    require Sub::Exporter;

    my @exports = qw[
        is_reserved
        is_reserved_by_sqlserver7
        is_reserved_by_sqlserver2000
        is_reserved_by_sqlserver2005
        reserved_by
        words
    ];

    Sub::Exporter->import( -setup => { exports => \@exports } );
}

{
    my %WORDS = (
        ADD                  => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        ALL                  => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        ALTER                => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        AND                  => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        ANY                  => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        AS                   => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        ASC                  => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        AUTHORIZATION        => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        AVG                  => SQLSERVER7,
        BACKUP               => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        BEGIN                => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        BETWEEN              => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        BREAK                => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        BROWSE               => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        BULK                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        BY                   => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        CASCADE              => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        CASE                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        CHECK                => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        CHECKPOINT           => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        CLOSE                => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        CLUSTERED            => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        COALESCE             => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        COLLATE              =>              SQLSERVER2000 | SQLSERVER2005,
        COLUMN               => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        COMMIT               => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        COMMITTED            => SQLSERVER7,
        COMPUTE              => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        CONFIRM              => SQLSERVER7,
        CONSTRAINT           => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        CONTAINS             => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        CONTAINSTABLE        => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        CONTINUE             => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        CONTROLROW           => SQLSERVER7,
        CONVERT              => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        COUNT                => SQLSERVER7,
        CREATE               => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        CROSS                => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        CURRENT              => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        CURRENT_DATE         => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        CURRENT_TIME         => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        CURRENT_TIMESTAMP    => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        CURRENT_USER         => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        CURSOR               => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        DATABASE             => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        DBCC                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        DEALLOCATE           => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        DECLARE              => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        DEFAULT              => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        DELETE               => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        DENY                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        DESC                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        DISK                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        DISTINCT             => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        DISTRIBUTED          => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        DOUBLE               => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        DROP                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        DUMMY                => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        DUMP                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        ELSE                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        END                  => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        ERRLVL               => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        ERROREXIT            => SQLSERVER7,
        ESCAPE               => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        EXCEPT               => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        EXEC                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        EXECUTE              => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        EXISTS               => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        EXIT                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        FETCH                => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        FILE                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        FILLFACTOR           => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        FLOPPY               => SQLSERVER7,
        FOR                  => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        FOREIGN              => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        FREETEXT             => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        FREETEXTTABLE        => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        FROM                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        FULL                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        FUNCTION             =>              SQLSERVER2000 | SQLSERVER2005,
        GOTO                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        GRANT                => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        GROUP                => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        HAVING               => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        HOLDLOCK             => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        IDENTITY             => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        IDENTITYCOL          => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        IDENTITY_INSERT      => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        IF                   => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        IN                   => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        INDEX                => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        INNER                => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        INSERT               => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        INTERSECT            => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        INTO                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        IS                   => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        ISOLATION            => SQLSERVER7,
        JOIN                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        KEY                  => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        KILL                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        LEFT                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        LEVEL                => SQLSERVER7,
        LIKE                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        LINENO               => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        LOAD                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        MAX                  => SQLSERVER7,
        MIN                  => SQLSERVER7,
        MIRROREXIT           => SQLSERVER7,
        NATIONAL             => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        NOCHECK              => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        NONCLUSTERED         => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        NOT                  => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        NULL                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        NULLIF               => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        OF                   => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        OFF                  => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        OFFSETS              => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        ON                   => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        ONCE                 => SQLSERVER7,
        ONLY                 => SQLSERVER7,
        OPEN                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        OPENDATASOURCE       => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        OPENQUERY            => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        OPENROWSET           => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        OPENXML              =>              SQLSERVER2000 | SQLSERVER2005,
        OPTION               => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        OR                   => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        ORDER                => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        OUTER                => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        OVER                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        PERCENT              => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        PERM                 => SQLSERVER7,
        PERMANENT            => SQLSERVER7,
        PIPE                 => SQLSERVER7,
        PLAN                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        PRECISION            => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        PREPARE              => SQLSERVER7,
        PRIMARY              => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        PRINT                => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        PRIVILEGES           => SQLSERVER7,
        PROC                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        PROCEDURE            => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        PROCESSEXIT          => SQLSERVER7,
        PUBLIC               => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        RAISERROR            => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        READ                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        READTEXT             => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        RECONFIGURE          => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        REFERENCES           => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        REPEATABLE           => SQLSERVER7,
        REPLICATION          => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        RESTORE              => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        RESTRICT             => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        RETURN               => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        REVOKE               => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        RIGHT                => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        ROLLBACK             => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        ROWCOUNT             => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        ROWGUIDCOL           => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        RULE                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        SAVE                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        SCHEMA               => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        SELECT               => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        SERIALIZABLE         => SQLSERVER7,
        SESSION_USER         => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        SET                  => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        SETUSER              => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        SHUTDOWN             => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        SOME                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        STATISTICS           => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        SUM                  => SQLSERVER7,
        SYSTEM_USER          => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        TABLE                => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        TAPE                 => SQLSERVER7,
        TEMP                 => SQLSERVER7,
        TEMPORARY            => SQLSERVER7,
        TEXTSIZE             => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        THEN                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        TO                   => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        TOP                  => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        TRAN                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        TRANSACTION          => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        TRIGGER              => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        TRUNCATE             => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        TSEQUAL              => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        UNCOMMITTED          => SQLSERVER7,
        UNION                => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        UNIQUE               => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        UPDATE               => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        UPDATETEXT           => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        USE                  => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        USER                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        VALUES               => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        VARYING              => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        VIEW                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        WAITFOR              => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        WHEN                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        WHERE                => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        WHILE                => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        WITH                 => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
        WORK                 => SQLSERVER7,
        WRITETEXT            => SQLSERVER7 | SQLSERVER2000 | SQLSERVER2005,
    );

    sub is_reserved {
        return $WORDS{ uc(pop || '') } || 0;
    }
    
    sub is_reserved_by_sqlserver7 {
        return &is_reserved & SQLSERVER7;
    }    
    
    sub is_reserved_by_sqlserver2000 {
        return &is_reserved & SQLSERVER2000;
    }

    sub is_reserved_by_sqlserver2005 {
        return &is_reserved & SQLSERVER2005;
    }
    
    sub reserved_by {
        my $flags       = &is_reserved;
        my @reserved_by = ();

        push @reserved_by, 'SQL Server 7'    if $flags & SQLSERVER7;
        push @reserved_by, 'SQL Server 2000' if $flags & SQLSERVER2000;
        push @reserved_by, 'SQL Server 2005' if $flags & SQLSERVER2005;

        return @reserved_by;
    }

    sub words {
        return sort keys %WORDS;
    }
}

1;

__END__

=head1 NAME

SQL::ReservedWords::SQLServer - Reserved SQL words by SQL Server

=head1 SYNOPSIS

   if ( SQL::ReservedWords::SQLServer->is_reserved( $word ) ) {
       print "$word is a reserved SQL Server word!";
   }

=head1 DESCRIPTION

Determine if words are reserved by SQL Server.

=head1 METHODS

=over 4

=item is_reserved( $word )

Returns a boolean indicating if C<$word> is reserved by SQL Server 7, 2000 or 2005.

=item is_reserved_by_sqlserver7( $word )

Returns a boolean indicating if C<$word> is reserved by SQL Server 7.

=item is_reserved_by_sqlserver2000( $word )

Returns a boolean indicating if C<$word> is reserved by SQL Server 2000.

=item is_reserved_by_sqlserver2005( $word )

Returns a boolean indicating if C<$word> is reserved by SQL Server 2005.

=item reserved_by( $word )

Returns a list with SQL Server versions that reserves C<$word>.

=item words

Returns a list with all reserved words.

=back

=head1 EXPORTS

Nothing by default. Following subroutines can be exported:

=over 4

=item is_reserved

=item is_reserved_by_sqlserver7

=item is_reserved_by_sqlserver2000

=item is_reserved_by_sqlserver2005

=item reserved_by

=item words

=back

=head1 SEE ALSO

http://msdn2.microsoft.com/en-us/library/ms130214.aspx

=head1 AUTHOR

Christian Hansen C<chansen@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
