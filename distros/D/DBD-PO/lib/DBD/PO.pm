package DBD::PO;

use strict;
use warnings;

our $VERSION = '2.10';
our $ATTRIBUTION = __PACKAGE__
                   . ' by Steffen Winkler <steffenw at cpan.org>';

use parent qw(DBD::File);

use DBD::PO::dr;
use DBD::PO::db;
use DBD::PO::Statement;
use DBD::PO::Table;
use DBD::PO::st;
use DBD::PO::Text::PO;

sub init {
    my (undef, @params) = @_;

    return DBD::PO::Text::PO->init(@params);
}

sub get_all_header_keys {
    return DBD::PO::db->get_all_header_keys();
}

1;

__END__

=head1 NAME

DBD::PO - DBI driver for PO files

$Id: PO.pm 434 2010-01-24 13:15:34Z steffenw $

$HeadURL: https://dbd-po.svn.sourceforge.net/svnroot/dbd-po/trunk/DBD-PO/lib/DBD/PO.pm $

=head1 VERSION

2.10

=head1 SYNOPSIS

=head2 connect

    use Carp qw(croak);
    use DBI ();
    use Socket qw($LF);

    # The next line is mostly obsolete
    # and was introduced for performance settings only.
    require DBD::PO; DBD::PO->init(qw(...));

    my $dbh = DBI->connect(
        'DBI:PO:'
        . 'f_dir=dir_x;'      # optional:
                              #  The default database is './',
                              #  here set to the directory 'dir_x'.
                              #  The default value is often unuseful.
        . "po_separator=\n;"  # optional:
                              #  The default 'po_separator' to set/get
                              #  concatinated data is "\n",
                              #  here set to "\n" unnecessary.
                              #  The default value is mostly useful
                              #  because the internal representation
                              #  of line ending is \n (Windows too).
                              #  This is different for binary IO.
        . "po_eol=$LF;"       # optional:
                              #  The default 'po_eol' (po end of line)
                              #  is network typical like 'use Socket qw($CRLF)',
                              #  here set to $LF like 'use Socket qw($LF)'.
                              #  The default value is mostly useful.
        . 'po_charset=utf-8', # optional:
                              #  Write nothing for 'iso-8859-1' files
                              #  and use bytes internal.
                              #  (It is not a good idea.)
                              #  Write 'utf-8' for 'utf-8' files
                              #  and use unicode chars internal.
                              #  Write 'iso-8859-1' for 'iso-8859-1' files
                              #  and use unicode chars internal
                              #  and so on for other charsets.
                              #  The default value is mostly not useful.
        undef,                # Username is not used.
        undef,                # Password is not used.
        {
            RaiseError => 1,  # The easy way to handle exceptions.
            PrintError => 0,  # The easy way to handle exceptions as warnings.
        },
    ) or croak 'Cannot connect: ' . DBI->errstr();

=head2 create table

Note that no column names will be stored.
They are fixed.
Thus all other information including column type (INTEGER or CHAR(x),
for example), column attributes (NOT NULL, PRIMARY KEY, ...)
will silently be discarded.

Table names cannot be arbitrary, due to restrictions of the SQL syntax.
I recommend that table names are valid SQL identifiers: The first
character is alphabetic, followed by an arbitrary number of alphanumeric
characters. If you want to use other files, the file names must start
with '/', './' or '../' and they must not contain white space.

For conditional execution use CREATE TABLE IF EXISTS statement.

Columns:

=over 14

=item * msgid

The text to translate (emty string for header).

The 'msgid' can contain Locale::Maketext placeholders.
They have to be stored in gettext format.
To change the format, use the database handle function 'maketext_to_gettext'.

=item * msgstr

The translation.

The 'msgid' can contain Locale::Maketext placeholder.
They have to be stored in gettext format.
To change the format, use the database handle function 'maketext_to_gettext'.

=item * comment

The translator comment text concatinated by 'po_separator'.

=item * automatic

The automatic comment text concatinated by 'po_separator'.

=item * reference

Where the text to translate is from, concatinated by 'po_separator'.

=item * msgctxt

This is the context.

=item * fuzzy

The translation is finished (0) or not (1).

=item * obsolete

The translation is used (0) or not (1).

=item * ..._format (...-format, no-...-format)

There are c-format, php-format and so on, see L<DBD::PO::Locale::PO>.

To use these format flags call
C<DBD::PO->init(qw(c-format php-format ...);>
or C<DBD::PO->init(':format');>
or C<DBD::PO->init(':all');> early.

Flag, not set (0), set (1) or negative set (-1).

=item * msgid_plural

The same like msgid but for plural.

To use these format flags call
C<DBD::PO->init(':plural');>
or C<DBD::PO->init(':all');> early.

=item * msgstr_0 .. msgstr_5

Insted of msgstr for plural item 0 .. 5.

To use these format flags call
C<DBD::PO->init(':plural');>
or C<DBD::PO->init(':all');> early.

=item * previous_msgctxt

As comment formatted former msgctxt.

To use these format flags call
C<DBD::PO->init(':previous');>
or C<DBD::PO->init(':all');> early.

=item * previous_msgid

As comment formatted former msgid.

To use these format flags call
C<DBD::PO->init(':previous');>
or C<DBD::PO->init(':all');> early.

=item * previous_msgid_plural

As comment formatted former msgid_plural.

To use these format flags call
C<DBD::PO->init(':previous');>
or C<DBD::PO->init(':all');> early.

=back

..._format, msgid_plural, msgstr_0 .. msgstr_5 and previous_...
are normally switched off.
See method init.

    $dbh->do(<<'EOT');
        CREATE TABLE
            table.po (
                msgid                 VARCHAR,
                msgstr                VARCHAR,
                comment               VARCHAR,
                automatic             VARCHAR,
                reference             VARCHAR,
                msgctxt               VARCHAR,
                fuzzy                 INTEGER,
                obsolete              INTEGER,
                ..._format            INTEGER,
                msgid_plural          VARCHAR,
                msgstr_0              VARCHAR,
                msgstr_1              VARCHAR,
                msgstr_2              VARCHAR,
                msgstr_3              VARCHAR,
                msgstr_4              VARCHAR,
                msgstr_5              VARCHAR,
                previous_msgctxt      VARCHAR,
                previous_msgid        VARCHAR,
                previous_msgid_plural VARCHAR
            )
    EOT

=head2 write the header

=head3 build msgstr

The charset will set to the as parameter 'po_charset' given value
at the connect method.
Note that the default encoding is nothing, not 'utf-8'.

=head4 minimized example

    my $header_msgstr = $dbh->func(
        undef,
        # function name
        'build_header_msgstr',
    );

=head4 full example

    my $header_msgstr = $dbh->func(
        {
            'Project-Id-Version'        => 'Project name',
            'Report-Msgid-Bugs-To-Name' => 'Bug Reporter',
            'Report-Msgid-Bugs-To-Mail' => 'report.msgid.bugs.to@example.org',
            'POT-Creation-Date'         => 'the POT creation date',
            'PO-Revision-Date'          => 'the PO revision date',
            'Last-Translator-Name'      => 'Steffen Winkler',
            'Last-Translator-Mail'      => 'steffenw@example.org',
            'Language-Team-Name'        => 'MyTeam',
            'Language-Team-Mail'        => 'cpan@example.org',
            # Do not set the following values.
            # They will be set automaticly.
            'MIME-Version'              => '1.0',
            'Content-Type'              => 'text/plain',
            charset                     => $po_charset || 'iso-8859-1',
            'Content-Transfer-Encoding' => '8bit',
            # an English/German example
            'Plural-Forms'              => 'nplurals=2; plural=n != 1;',
            # place here pairs for extra parameters
            extended                    => [qw(
                X-Poedit-Language      German
                X-Poedit-Country       GERMANY
                X-Poedit-SourceCharset utf-8
            )],
        },
        # function name
        'build_header_msgstr',
    );

=head2 write header row

Write the header row always at first!

    use Socket qw($CRLF);
    my $separator = $CRLF; # But it is more easy
                           # to use the po_separator default \n
                           # and than the join is obsolete
                           # because the strings typical including \n.

    my $header_comment = join(
        $separator,
        'This is a translator comment for the header.',
        'And this is line 2 of.',
    );

    $dbh->do(<<'EOT', undef, $header_comment, $header_msgstr);
        INSERT INTO table.po (
            comment,
            msgstr
        ) VALUES (?, ?)
EOT

=head2 write a row

=head2 without Locale::Maketext placeholders

    my $sth = $dbh->prepare(<<'EOT');
        INSERT INTO table.po (
            msgid,
            msgstr,
            reference
        ) VALUES (?, ?, ?)
    EOT

    $sth->execute(
        join(
            $separator,
            'text to translate',
            '2nd line of text',
        ),
        join(
            $separator,
            'translation',
            '2nd line of translation',
        ),
        join(
            $separator,
            'my_program: 17',
            'my_program: 269',
        ),
    );

=head2 with Locale::Maketext placeholders

    my $sth = $dbh->prepare(<<'EOT');
        INSERT INTO table.po (
            msgid,
            msgstr,
            reference
        ) VALUES (?, ?, ?)
    EOT

    $sth->execute(
        $dbh->func(
            # mapping:
            # - scalar to scalar
            # - or array to array
            # - here 2 values given to 2 returns
            join(
                $separator,
                'text to translate',
                '2nd line of text',
            ),
            join(
                $separator,
                'translation',
                '2nd line of translation',
            ),
            'maketext_to_gettext',
        ),
        join(
            $separator,
            'my_program: 17',
            'my_program: 269',
        ),
    );

=head2 read the header

=head3 read only 1 header information

Scalar to scalar mapping.

    my $charset = $dhh->func(
        {table => 'table_name'},
        'charset',
        'get_header_msgstr_data',
    );

=head3 read more header informations

Arrayref to arrayref mapping.

    my $array_ref = $dbh->func(
        {table => 'table_name'},
        [qw(charset Project-Id-Version)],
        'get_header_msgstr_data',
    );
    my ($charset, $project_id_version) = @{$array_ref};

=head2 read a row

    $sth = $dbh->prepare(<<'EOT');
        SELECT msgstr
        FROM   table.po
        WHERE  msgid = ?
    EOT

    $sth->execute(
        join(
            $separator,
            'text to translate',
            '2nd line of text',
        ),
    );

    my ($msgstr) = $sth->fetchrow_array();

=head2 update rows

    $dbh->do(<<'EOT');
        UPDATE table.po
        SET    msgstr = '',
               fuzzy = 1
        WHERE  msgid = 'my_id'
    EOT

=head2 delete rows

    $dbh->do(<<'EOT');
        DELETE FROM table.po
        WHERE       obsolete = 1
    EOT

=head2 drop table

For conditional execution use DROP TABLE IF EXISTS statement.

    $dbh->do(<<'EOT');
        DROP TABLE table.po
    EOT

=head2 disconnect

    $dbh->disconnect();

=head2 dot's in file suffix and SQL

In case of join tables, SQL::Statement does not allow a file suffix.

File suffix can be used here:

    SELECT msgstr
    FROM   de.po
    WHERE  msgid <> ''

But not here:

    SELECT     de.po.msgstr, ru.po.msgstr
    FROM       de.po
    INNER JOIN ru.po
    ON         de.po.msgid = ru.po.msgid
    WHERE      de.po.msgid <> ''

Set a mapping hash like:

    $dbh->{po_tables}->{'de'} = {file => 'de.po'};
    $dbh->{po_tables}->{'ru'} = {file => 'ru.po'};

Do not write the suffix now:

    SELECT     de.msgstr, ru.msgstr
    FROM       de
    INNER JOIN ru
    ON         de.msgid = ru.msgid
    WHERE      de.msgid <> ''

or the same here:

    SELECT msgstr
    FROM   de
    WHERE  msgid <> ''

=head1 DESCRIPTION

The DBD::PO module is yet another driver for the DBI
(Database independent interface for Perl).
This one is based on the SQL 'engine' SQL::Statement
and the abstract DBI driver DBD::File and implements access to
so-called PO files (GNU gettext).
Such files are readable by Locale::Maketext.

See DBI for details on DBI, L<SQL::Statement> for details on
SQL::Statement and L<DBD::File> for details on the base class
DBD::File.

     ---------------------
    |         DBI         |
     ---------------------
               |
     ---------------------     -----------     ---------------
    |       DBD::PO       |---| DBD::File |---| SQL-Statement |
     ---------------------     -----------     ---------------
               |
     ---------------------
    |  DBD::PO::Text::PO  |
     ---------------------
               |
     ---------------------
    | DBD::PO::Locale::PO |
     ---------------------
               |
         table_file.po

=head1 EXAMPLE

Inside of this Distribution is a directory named example.
Run this *.pl files.

=head1 SUBROUTINES/METHODS

=head2 init

    DBD::PO->init(...);

This is a class method to optimize the size of arrays.
The default settings are performant.

Do not call this method during you have an active connection!

Parameters:

=over 5

=item * :plural

Allow all plural forms.

=item * :format

Allow all format flags.

=item * :all

Allow all.

=item * c-format as example

Allow the format flag 'c-format'.
For all the other format flags see L<DBD::PO::Locale::PO>.

=item * allow_lost_blank_lines

If no blank line is between PO entrys inside of the PO file,
this switch allows to read the damaged file.

=back

=head2 get_all_header_keys

Use this method to show all header data for debugging.

    $all_header_keys_ref = DBD::PO->get_all_header_keys();

    my $header_data_ref = $dbh->func(
        {table => $table},        # wich table
        $all_header_keys_ref,     # what to get
        'get_header_msgstr_data', # function name
    );

or

    $all_header_keys_ref = $dbh->func(
        'get_all_header_keys', # function_name
    );

    my $header_data_ref = $dbh->func(
        {table => $table},        # wich table
        $all_header_keys_ref,     # what to get
        'get_header_msgstr_data', # function name
    );

=head1 DIAGNOSTICS

see DBI

=head1 CONFIGURATION AND ENVIRONMENT

see DBI

=head1 DEPENDENCIES

Carp

Socket

parent

DBI

L<SQL::Statement>

L<Params::Validate>

=head2 Prerequisites

The only system dependent feature that DBD::File uses, is the C<flock()>
function. Thus the module should run (in theory) on any system with
a working C<flock()>, in particular on all Unix machines and on Windows
NT. Under Windows 95 and MacOS the use of C<flock()> is disabled, thus
the module should still be usable,

Unlike other DBI drivers, you don't need an external SQL engine
or a running server. All you need are the following Perl modules,
available from any CPAN mirror.

=head2 SQL

The level of SQL support available depends on the version of
SQL::Statement installed.
Any version will support *basic*
CREATE, INSERT, DELETE, UPDATE, and SELECT statements.
Only versions of SQL::Statement 1.0 and above support additional
features such as table joins, string functions, etc.
See the documentation of the latest version of SQL::Statement for details.

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

The module is using flock() internally. However, this function is not
available on platforms. Using flock() is disabled on MacOS and Windows
95: There's no locking at all (perhaps not so important on these
operating systems, as they are for single users anyways).

=head1 SEE ALSO

DBI

L<DBD::File> as base class

L<SQL::Statement> and L<SQL::Statement::Syntax> as Parser

L<Locale::PO> has bugs, more than documented

L<DBD::CSV> my guideline

L<http://www.gnu.org/software/gettext/manual/gettext.html>

L<http://en.wikipedia.org/wiki/Gettext>

L<http://translate.sourceforge.net/wiki/l10n/pluralforms>

L<http://rassie.org/archives/247> The choice of the right module for the translation.

L<Locale::Maketext::Lexicon> see xgettext.pl

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 - 2010,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut