package DBD::PO::db; ## no critic (Capitalization)

use strict;
use warnings;

our $VERSION = '2.05';

use DBD::File;
use parent qw(-norequire DBD::File::db);

use Carp qw(croak);
use Params::Validate qw(:all);
use Storable qw(dclone);
use SQL::Statement; # for SQL::Parser
use SQL::Parser;
use DBD::PO::Locale::PO;
use DBD::PO::Text::PO qw($EOL_DEFAULT $SEPARATOR_DEFAULT $CHARSET_DEFAULT);

our $imp_data_size = 0; ## no critic (PackageVars)

my (@HEADER_KEYS, @HEADER_FORMATS, @HEADER_DEFAULTS, @HEADER_REGEX);
{
    my @header = (
        [ project_id_version        => 'Project-Id-Version: %s'        ],
        [ report_msgid_bugs_to      => 'Report-Msgid-Bugs-To: %s <%s>' ],
        [ pot_creation_date         => 'POT-Creation-Date: %s'         ],
        [ po_revision_date          => 'PO-Revision-Date: %s'          ],
        [ last_translator           => 'Last-Translator: %s <%s>'      ],
        [ language_team             => 'Language-Team: %s <%s>'        ],
        [ mime_version              => 'MIME-Version: %s'              ],
        [ content_type              => 'Content-Type: %s; charset=%s'  ],
        [ content_transfer_encoding => 'Content-Transfer-Encoding: %s' ],
        [ plural_forms              => 'Plural-Forms: %s'              ],
        [ extended                  => '%s: %s'                        ],
    );
    @HEADER_KEYS     = map {$_->[0]} @header;
    @HEADER_FORMATS  = map {$_->[1]} @header;
    @HEADER_DEFAULTS = (
        undef,
        undef,
        undef,
        undef,
        undef,
        undef,
       '1.0',
        ['text/plain', undef],
        '8bit',
        undef,
        undef,
    );
    @HEADER_REGEX = (
        qr{\A \QProject-Id-Version:\E        \s* (.*) \s* \z}xmsi,
        [
            qr{\A \QReport-Msgid-Bugs-To:\E  \s* ([^<]*) \s+ < ([^>]*) > \s* \z}xmsi,
            qr{\A \QReport-Msgid-Bugs-To:\E  \s* (.*) () \s* \z}xmsi,
        ],
        qr{\A \QPOT-Creation-Date:\E         \s* (.*) \s* \z}xmsi,
        qr{\A \QPO-Revision-Date:\E          \s* (.*) \s* \z}xmsi,
        [
            qr{\A \QLast-Translator:\E       \s* ([^<]*) \s+ < ([^>]*) > \s* \z}xmsi,
            qr{\A \QLast-Translator:\E       \s* (.*) () \s* \z}xmsi,
        ],
        [
            qr{\A \QLanguage-Team:\E         \s* ([^<]*) \s+ < ([^>]*) > \s* \z}xmsi,
            qr{\A \QLanguage-Team:\E         \s* (.*) () \s* \z}xmsi,
        ],
        qr{\A \QMIME-Version:\E              \s* (.*) \s* \z}xmsi,
        qr{\A \QContent-Type:\E              \s* ([^;]*); \s* charset=(\S*) \s* \z}xmsi,
        qr{\A \QContent-Transfer-Encoding:\E \s* (.*) \s* \z}xmsi,
        qr{\A \QPlural-Forms:\E              \s* (.*) \s* \z}xmsi,
        qr{\A ([^:]*) :                      \s* (.*) \s* \z}xms,
    );
}

my $maketext_to_gettext_scalar = sub {
    my $string = shift;

    defined $string
        or return;
    $string =~ s{
        \[ \s*
        (?:
            ( [A-Za-z*\#] [A-Za-z_]* ) # $1 - function call
            \s* , \s*
            _ ( [1-9]\d* )             # $2 - variable
            ( [^\]]* )                 # $3 - arguments
            |                          # or
            _ ( [1-9]\d* )             # $4 - variable
        )
        \s* \]
    }
    {
        $4 ? "%$4" : "%$1(%$2$3)"
    }xmsge;

    return $string;
};

sub maketext_to_gettext {
    my ($self, @strings) = @_;

    return
        @strings > 1
        ? map { $maketext_to_gettext_scalar->($_) } @strings
        : @strings
          ? $maketext_to_gettext_scalar->( $strings[0] )
          : ();
}

sub quote {
    my($self, $string, $type) = @_;

    defined $string
        or return 'NULL';
    if (
        defined($type)
        && (
            $type == DBI::SQL_NUMERIC()
            || $type == DBI::SQL_DECIMAL()
            || $type == DBI::SQL_INTEGER()
            || $type == DBI::SQL_SMALLINT()
            || $type == DBI::SQL_FLOAT()
            || $type == DBI::SQL_REAL()
            || $type == DBI::SQL_DOUBLE()
            || $type == DBI::SQL_TINYINT()
        )
    ) {
        return $string;
    }
    my $is_quoted;
    for (
        $string =~ s{\\}{\\\\}xmsg,
        $string =~ s{'}{\\'}xmsg,
    ) {
       $is_quoted ||= $_;
    }

    return $is_quoted
           ? "'_Q_U_O_T_E_D_:$string'"
           : "'$string'";
}

## no critic (MagicNumbers)
my %hash2array = (
    'Project-Id-Version'        => 0,
    'Report-Msgid-Bugs-To-Name' => [1, 0],
    'Report-Msgid-Bugs-To-Mail' => [1, 1],
    'POT-Creation-Date'         => 2,
    'PO-Revision-Date'          => 3,
    'Last-Translator-Name'      => [4, 0],
    'Last-Translator-Mail'      => [4, 1],
    'Language-Team-Name'        => [5, 0],
    'Language-Team-Mail'        => [5, 1],
    'MIME-Version'              => 6,
    'Content-Type'              => [7, 0],
    charset                     => [7, 1],
    'Content-Transfer-Encoding' => 8,
    'Plural-Forms'              => 9,
);
my $index_extended = 10;
## use critic (MagicNumbers)

my $valid_keys_regex = '(?xsm-i:\A (?: '
                       . join(
                           q{|},
                           map {
                               quotemeta $_
                           } keys %hash2array, 'extended'
                       )
                       . ' ) \z)';

sub _hash2array {
    my ($hash_data, $charset) = @_;
    caller eq __PACKAGE__
        or croak 'Do not call a private sub';
    validate_with(
        params => $hash_data,
        spec   => {
            (
                map {
                    ($_ => {type => SCALAR, optional => 1});
                } keys %hash2array
            ),
            extended => {type => ARRAYREF, optional => 1},
        },
    );

    my $array_data = dclone(\@HEADER_DEFAULTS);
    $array_data->[ $hash2array{charset}->[0] ]->[$hash2array{charset}->[1] ]
        = $charset;
    KEY:
    for my $key (keys %{$hash_data}) {
        if ($key eq 'extended') {
            $array_data->[$index_extended] = $hash_data->{extended};
            next KEY;
        }
        if (ref $hash2array{$key} eq 'ARRAY') {
            $array_data->[ $hash2array{$key}->[0] ]->[ $hash2array{$key}->[1] ]
                = $hash_data->{$key};
            next KEY;
        }
        $array_data->[ $hash2array{$key} ] = $hash_data->{$key};
    }

    return $array_data;
};

sub get_all_header_keys {
    return [keys %hash2array];
}

sub build_header_msgstr { ## no critic (ArgUnpacking)
    my ($dbh, $anything) = validate_pos(
        @_,
        {isa   => 'DBI::db'},
        {type  => UNDEF | ARRAYREF | HASHREF},
    );

    my $charset = $dbh->FETCH('po_charset')
                  ? $dbh->FETCH('po_charset')
                  : $CHARSET_DEFAULT;
    my $array_data = ref $anything eq 'HASH'
                     ? _hash2array($anything, $charset)
                     : $anything;
    my @header;
    HEADER_KEY:
    for my $index (0 .. $#HEADER_KEYS) {
        my $data = $array_data->[$index]
                   || $HEADER_DEFAULTS[$index];
        defined $data
            or next HEADER_KEY;
        my $key    = $HEADER_KEYS[$index];
        my $format = $HEADER_FORMATS[$index];
        my @data = defined $data
                   ? (
                       ref $data eq 'ARRAY'
                       ? @{ $data }
                       : $data
                   )
                   : ();
        if ($key eq 'content_type') {
            if ($charset) {
                $data[1] = $charset;
            }
        }
        @data
            or next HEADER_KEY;
        if ($key eq 'extended') {
            @data % 2
               and croak "$key pairs are not pairwise";
            while (my ($name, $value) = splice @data, 0, 2) {
                push @header, sprintf $format, $name, $value;
            }
        }
        else {
            my $row = sprintf $format, map {defined $_ ? $_ : q{}} @data;
            $row =~ s{\s* <> \z}{}xms; # delete an empty mail address
            push @header, $row;
        }
    }

    return join "\n", @header;
}

sub get_header_msgstr { ## no critic (ArgUnpacking)
    my ($dbh, $hash_ref) = validate_pos(
        @_,
        {isa   => 'DBI::db'},
        {type  => HASHREF},
    );

    my $sth = $dbh->prepare(<<"EOT") or croak $dbh->errstr();
        SELECT msgstr
        FROM $hash_ref->{table}
        WHERE msgid = ''
EOT
    $sth->execute()
        or croak $sth->errstr();
    my ($msgstr) = $sth->fetchrow_array()
        or croak $sth->errstr();
    $sth->finish()
        or croak $sth->errstr();

    return $msgstr;
}

sub split_header_msgstr { ## no critic (ArgUnpacking)
    my ($dbh, $anything) = validate_pos(
        @_,
        {isa   => 'DBI::db'},
        {type  => SCALAR | HASHREF},
    );

    my $msgstr = (ref $anything eq 'HASH')
                 ? $dbh->func($anything, 'get_header_msgstr')
                 : $anything;

    my $po = DBD::PO::Locale::PO->new(
        eol => defined $dbh->FETCH('eol')
               ? $dbh->FETCH('eol')
               : $EOL_DEFAULT,
    );
    my $separator = defined $dbh->FETCH('separator')
                    ? $dbh->FETCH('separator')
                    : $SEPARATOR_DEFAULT;
    my @cols;
    my @lines = split m{\Q$separator\E}xms, $msgstr;
    LINE:
    while (1) {
        my $line = shift @lines;
        defined $line
           or last LINE;
        # run the regex for the selected column
        my $index = 0;
        HEADER_REGEX:
        for my $header_regex (@HEADER_REGEX) {
            if (! $header_regex) {
                ++$index;
                next HEADER_REGEX;
            }
            my @result;
            # more regexes are necessary
            if (ref $header_regex eq 'ARRAY') {
                # run from special to more common regex
                INNER_REGEX:
                for my $inner_regex ( @{$header_regex} ) {
                    @result = $line =~ $inner_regex;
                    last INNER_REGEX if @result;
                }
            }
            # only 1 regex is necessary
            else {
                @result = $line =~ $header_regex;
            }
            # save the result to the selected column
            if (@result) {
                # some columns are multiline
                defined $cols[$index]
                ? (
                    ref $cols[$index] eq 'ARRAY'
                    ? push @{ $cols[$index] }, @result
                    : do {
                        $cols[$index] = [ $cols[$index], @result ];
                    }
                )
                : (
                    $cols[$index] = @result > 1
                                    ? \@result
                                    : $result[0]
                );
                next LINE;
            }
            ++$index;
        }
    }

    return \@cols;
}

sub get_header_msgstr_data { ## no critic (ArgUnpacking)
    my ($dbh, $anything, $key) = validate_pos(
        @_,
        {isa  => 'DBI::db'},
        {type => ARRAYREF | SCALAR | HASHREF},
        {
            type      => SCALAR | ARRAYREF,
            callbacks => {
                check_keys => sub {
                    my $check_key = shift;
                    if (ref $check_key eq 'ARRAY') {
                        return 1;
                    }
                    else {
                        return $check_key =~ $valid_keys_regex;
                    }
                },
            },
        },
    );

    my $array_ref = (ref $anything eq 'ARRAY')
                    ? $anything
                    : $dbh->func($anything, 'split_header_msgstr');

    if (ref $key eq 'ARRAY') {
        return [
            map {
                get_header_msgstr_data($dbh, $array_ref, $_);
            } @{$key}
        ];
    }

    my $index = $key eq 'extended'
                ? $index_extended
                : $hash2array{$key};
    if (ref $index eq 'ARRAY') {
        return $array_ref->[ $index->[0] ]->[ $index->[1] ];
    }

    return $array_ref->[$index];
}

1;

__END__

=head1 NAME

DBD::PO::db - database class for DBD::PO

$Id: db.pm 380 2009-05-02 07:05:20Z steffenw $

$HeadURL: https://dbd-po.svn.sourceforge.net/svnroot/dbd-po/trunk/DBD-PO/lib/DBD/PO/db.pm $

=head1 VERSION

2.05

=head1 SYNOPSIS

do not use

=head1 DESCRIPTION

database class for DBD::PO

=head1 SUBROUTINES/METHODS

=head2 method maketext_to_gettext

=head2 method quote

=head2 method get_all_header_keys

=head2 method build_header_msgstr

=head2 method get_header_msgstr

=head2 method split_header_msgstr

=head2 method get_header_msgstr_data

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

parent

Carp

Storable

L<DBD::File>

L<Params::Validate>

L<SQL::Statement>

L<SQL::Parser>

L<DBD::PO::Locale::PO>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

not known

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 - 2009,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut