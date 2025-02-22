package SQL::ReservedWords::Oracle;

use strict;
use warnings;
use vars '$VERSION';

$VERSION = '0.8';

use constant ORACLE7  => 0x01;
use constant ORACLE8  => 0x02;
use constant ORACLE9  => 0x04;
use constant ORACLE10 => 0x08;

{
    require Sub::Exporter;

    my @exports = qw[
        is_reserved
        is_reserved_by_oracle7
        is_reserved_by_oracle8
        is_reserved_by_oracle9
        is_reserved_by_oracle10
        reserved_by
        words
    ];

    Sub::Exporter->import( -setup => { exports => \@exports } );
}

{
    my %WORDS = (
        ACCESS       => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        ADD          => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        ALL          => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        ALTER        => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        AND          => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        ANY          => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        AS           => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        ASC          => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        AUDIT        => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        BETWEEN      => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        BY           => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        CHAR         => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        CHECK        => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        CLUSTER      => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        COLUMN       => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        COMMENT      => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        COMPRESS     => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        CONNECT      => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        CREATE       => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        CURRENT      => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        DATE         => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        DECIMAL      => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        DEFAULT      => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        DELETE       => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        DESC         => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        DISTINCT     => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        DROP         => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        ELSE         => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        EXCLUSIVE    => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        EXISTS       => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        FILE         => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        FLOAT        => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        FOR          => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        FROM         => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        GRANT        => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        GROUP        => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        HAVING       => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        IDENTIFIED   => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        IMMEDIATE    => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        IN           => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        INCREMENT    => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        INDEX        => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        INITIAL      => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        INSERT       => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        INTEGER      => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        INTERSECT    => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        INTO         => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        IS           => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        LEVEL        => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        LIKE         => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        LOCK         => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        LONG         => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        MAXEXTENTS   => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        MINUS        => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        MLSLABEL     =>           ORACLE8 | ORACLE9 | ORACLE10,
        MODE         => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        MODIFY       => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        NOAUDIT      => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        NOCOMPRESS   => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        NOT          => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        NOWAIT       => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        NULL         => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        NUMBER       => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        OF           => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        OFFLINE      => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        ON           => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        ONLINE       => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        OPTION       => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        OR           => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        ORDER        => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        PCTFREE      => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        PRIOR        => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        PRIVILEGES   => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        PUBLIC       => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        RAW          => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        RENAME       => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        RESOURCE     => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        REVOKE       => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        ROW          => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        ROWID        => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        ROWLABEL     => ORACLE7,
        ROWNUM       => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        ROWS         => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        SELECT       => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        SESSION      => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        SET          => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        SHARE        => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        SIZE         => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        SMALLINT     => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        START        => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        SUCCESSFUL   => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        SYNONYM      => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        SYSDATE      => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        TABLE        => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        THEN         => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        TO           => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        TRIGGER      => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        UID          => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        UNION        => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        UNIQUE       => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        UPDATE       => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        USER         => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        VALIDATE     => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        VALUES       => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        VARCHAR      => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        VARCHAR2     => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        VIEW         => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        WHENEVER     => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        WHERE        => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10,
        WITH         => ORACLE7 | ORACLE8 | ORACLE9 | ORACLE10
    );

    sub is_reserved {
        return $WORDS{ uc(pop || '') } || 0;
    }

    sub is_reserved_by_oracle7 {
        return &is_reserved & ORACLE7;
    }

    sub is_reserved_by_oracle8 {
        return &is_reserved & ORACLE8;
    }

    sub is_reserved_by_oracle9 {
        return &is_reserved & ORACLE9;
    }

    sub is_reserved_by_oracle10 {
        return &is_reserved & ORACLE10;
    }

    sub reserved_by {
        my $flags       = &is_reserved;
        my @reserved_by = ();

        push @reserved_by, 'Oracle 7'   if $flags & ORACLE7;
        push @reserved_by, 'Oracle 8i'  if $flags & ORACLE8;
        push @reserved_by, 'Oracle 9i'  if $flags & ORACLE9;
        push @reserved_by, 'Oracle 10g' if $flags & ORACLE10;

        return @reserved_by;
    }

    sub words {
        return sort keys %WORDS;
    }
}

1;

__END__

=head1 NAME

SQL::ReservedWords::Oracle - Reserved SQL words by Oracle

=head1 SYNOPSIS

   if ( SQL::ReservedWords::Oracle->is_reserved( $word ) ) {
       print "$word is a reserved Oracle word!";
   }

=head1 DESCRIPTION

Determine if words are reserved by Oracle Database.

=head1 METHODS

=over 4

=item is_reserved( $word )

Returns a boolean indicating if C<$word> is reserved by either Oracle7, 
Oracle8i, Oracle9i or Oracle10g.

=item is_reserved_by_oracle7( $word )

Returns a boolean indicating if C<$word> is reserved by Oracle7.

=item is_reserved_by_oracle8( $word )

Returns a boolean indicating if C<$word> is reserved by Oracle8i.

=item is_reserved_by_oracle9( $word )

Returns a boolean indicating if C<$word> is reserved by Oracle9i.

=item is_reserved_by_oracle10( $word )

Returns a boolean indicating if C<$word> is reserved by Oracle10g.

=item reserved_by( $word )

Returns a list with Oracle versions that reserves C<$word>.

=item words

Returns a list with all reserved words.

=back

=head1 EXPORTS

Nothing by default. Following subroutines can be exported:

=over 4

=item is_reserved

=item is_reserved_by_oracle7

=item is_reserved_by_oracle8

=item is_reserved_by_oracle9

=item is_reserved_by_oracle10

=item reserved_by

=item words

=back

=head1 SEE ALSO

L<SQL::ReservedWords>

L<http://www.oracle.com/technology/documentation/>

=head1 AUTHOR

Christian Hansen C<chansen@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
