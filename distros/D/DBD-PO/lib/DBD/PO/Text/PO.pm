package DBD::PO::Text::PO;

use strict;
use warnings;

our $VERSION = '2.08';

use Carp qw(croak);
use English qw(-no_match_vars $OS_ERROR);
use Params::Validate qw(:all);
use DBD::PO::Locale::PO qw(@FORMAT_FLAGS $ALLOW_LOST_BLANK_LINES);
use Socket qw($CRLF);
use Set::Scalar;

use parent qw(Exporter);
our @EXPORT_OK = qw(
    $EOL_DEFAULT
    $SEPARATOR_DEFAULT
    $CHARSET_DEFAULT
    @COL_NAMES
);

our $EOL_DEFAULT       = $CRLF;
our $SEPARATOR_DEFAULT = "\n";
our $CHARSET_DEFAULT   = 'iso-8859-1';

our @COL_NAMES;
my  @COL_PARAMETERS;
my  @COL_METHODS;
our $LOST_BLANK_LINES;

sub init {
    my (undef, @config) = @_;

    my $config = Set::Scalar->new(@config);
    my $allowed = Set::Scalar->new(
        qw( :all :plural :previous :format allow_lost_blank_lines ),
        @FORMAT_FLAGS,
    );
    my $not_allowed = $config - $allowed;
    if ( ! $not_allowed->is_empty() ) {
        croak 'Unkonwn config parameter: ', join ', ', $not_allowed->elements();
    }
    if ( $config->has(':all') ) {
        $config->delete(':all');
        $config->insert(qw(:plural :previous :format allow_lost_blank_lines));
    }
    my $has_plural = $config->has(':plural');
    $config->delete(':plural');
    my $has_previous = $config->has(':previous');
    $config->delete(':previous');
    if ( $config->has(':format') ) {
        $config->delete(':format');
        $config->insert(@FORMAT_FLAGS);
    }
    $ALLOW_LOST_BLANK_LINES = $config->has('allow_lost_blank_lines');
    $config->delete('allow_lost_blank_lines');

    my @cols = (
        # typical
        [ qw( msgid     -msgid     msgid     ) ], # original text
        [ qw( msgstr    -msgstr    msgstr    ) ], # translation
        [ qw( comment   -comment   comment   ) ], # translater comment
        [ qw( automatic -automatic automatic ) ], # automatic comment
        [ qw( reference -reference reference ) ],
        [ qw( msgctxt   -msgctxt   msgctxt   ) ], # context
        # flags
        [ qw( fuzzy     -fuzzy     fuzzy     ) ],
        # switch to ignore
        [ qw( obsolete  -obsolete  obsolete  ) ],
        # plural only
        (
            $has_plural
            ? (
                [ qw( msgid_plural -msgid_plural msgid_plural ) ],
                                   # dummy       # dummy
                [ qw( msgstr_0     -msgstr_0     msgstr_0     ) ], # singular or zero
                [ qw( msgstr_1     -msgstr_1     msgstr_1     ) ], # plural   or singular
                [ qw( msgstr_2     -msgstr_2     msgstr_2     ) ], # plural
                [ qw( msgstr_3     -msgstr_3     msgstr_3     ) ], # plural
                [ qw( msgstr_4     -msgstr_4     msgstr_4     ) ], # plural
                [ qw( msgstr_5     -msgstr_5     msgstr_5     ) ], # plural
            )
            : ()
        ),
        # prevoius
        (
            $has_previous
            ? (
                [ qw( previous_msgctxt      -previous_msgctxt      previous_msgctxt      ) ],
                [ qw( previous_msgid        -previous_msgid        previous_msgid        ) ],
                [ qw( previous_msgid_plural -previous_msgid_plural previous_msgid_plural ) ],
            )
            : ()
        ),
        # format-flags
        (
            map { ## no critic (ComplexMappings)
                (my $col_name = $_) =~ tr{-}{_};
                                     # dummy
                ([ $col_name, "-$_", $_ ]);
            } $config->elements()
        ),
    );

    @COL_NAMES       = map {$_->[0]} @cols; # for SQL
    @COL_PARAMETERS  = map {$_->[1]} @cols; # for DBD::PO::Locale::PO->new(...)
    @COL_METHODS     = map {$_->[2]} @cols; # it is the method for the $po object

    return;
}
init();

my $dequote = sub {
    my $string = shift;

    return if $string eq 'NULL';
    if ($string =~ s{\A _Q_U_O_T_E_D_:}{}xms) {
        $string =~ s{\\\\}{\\}xmsg;
    }

    return $string;
};

my $array_from_anything = sub {
    my ($self, $anything) = @_;

    my @array = map { ## no critic (ComplexMappings)
        my $dequoted = $dequote->($_);
        split m{\Q$self->{separator}\E}xms, $dequoted;
    } ref $anything eq 'ARRAY'
      ? @{$anything}
      : defined $anything
        ? $anything
        : ();

    return \@array;
};

sub new { ## no critic (RequireArgUnpacking)
    my ($class, $options) = validate_pos(
        @_,
        {type => SCALAR},
        {type => HASHREF},
    );
    $options = validate_with(
        params => $options,
        spec   => {
            eol       => {type => SCALAR, default => $EOL_DEFAULT},
            separator => {type => SCALAR, default => $SEPARATOR_DEFAULT},
            charset   => {type => SCALAR | UNDEF, optional => 1},
        },
        called => "2nd parameter of new('$class', \$hash_ref)",
    );

    if ($options->{charset}) {
        $options->{encoding} = ":encoding($options->{charset})";
    }

    return bless $options, $class;
}

sub write_entry { ## no critic (ExcessComplexity)
    my ($self, $file_name, $file_handle, $col_ref) = @_;

    my %line;
    for my $index (0 .. $#COL_NAMES) {
        my $parameter = $COL_PARAMETERS[$index];
        my $values    = $array_from_anything->($self, $col_ref->[$index]);
        if ( ## no critic (CascadingIfElse)
            $parameter eq '-comment'
            || $parameter eq '-automatic'
            || $parameter eq '-reference'
        ) {
            if (@{$values}) {
                $line{$parameter} = join $self->{eol}, @{$values};
            }
        }
        elsif (
            $parameter eq '-obsolete'
            || $parameter eq '-fuzzy'
        ) {
            $line{$parameter} = $values->[0] ? 1 : 0;
        }
        elsif (
            my ($prefix) = $parameter =~ m{\A - ( [a-z-]+ ) -format \z}xms
        ) {
            my $flag = $values->[0];
            # translate:
            # perl_false => nothing set
            # -something => -no-flag = 1
            # something  => -flag = 1
            if ($flag) {
                $line{
                    (
                        $flag =~ m{\A -}xms
                        ? '-no'
                        : q{}
                    )
                    . "-$prefix-format"
                } = 1;
            }
        }
        elsif ( $parameter =~ m{\A -msgstr_ ( \d ) \z}xms ) {
            if ( @{$values} ) {
                $line{'-msgstr_n'}->{$1} = join "\n", @{$values};
            }
        }
        else {
            if ( @{$values} ) {
                $line{$parameter} = join "\n", @{$values};
                if (! tell $file_handle) {
                    if ($parameter eq '-msgid') {
                        croak 'A header has no msgid';
                    }
                    else { # -msgstr
                        if ($line{$parameter} !~ m{\b charset =}xms) { ## no critic (DeepNests)
                            croak 'This can not be a header';
                        }
                    }
                }
            }
            else {
                if ($parameter eq '-msgid' && tell $file_handle) {
                    croak 'A line has to have a msgid';
                }
                elsif ($parameter eq '-msgstr' && ! tell $file_handle) {
                    croak 'A header has to have a msgstr';
                }
            }
        }
        ++$index;
    }
    my $line = DBD::PO::Locale::PO->new(
        eol      => $self->{eol},
        '-msgid' => q{},
        (
            exists $line{'-msgid_plural'}
            ? ('-msgstr_n' => { 0 => q{} })
            : ('-msgstr'   => q{})
        ),
        %line,
    )->dump();
    print {$file_handle} $line
        or croak "Print $file_name: $OS_ERROR";

    return $self;
}

sub read_entry {
    my ($self, $file_name, $file_handle) = @_;

    if (! defined $self->{line_number}) {
        $self->{line_number} = 0;
    }
    my $po = DBD::PO::Locale::PO->load_entry(
        $file_name,
        $file_handle,
        \$self->{line_number},
        $self->{eol},
    );
    # EOF
    if (! $po) {
        delete $self->{line_number};
        return [];
    }
    # run a line, it is a po object
    my @cols;
    my $index = 0;
    METHOD:
    for my $method (@COL_METHODS) {
        if ( ## no critic (CascadingIfElse)
            $method eq 'comment'
            || $method eq 'automatic'
            || $method eq 'reference'
        ) {
            my $comment = $po->$method();
            $cols[$index]
                = defined $comment
                  ? (
                      join  $self->{separator},
                      split m{\Q$self->{eol}\E}xms,
                      $comment
                  )
                  : q{};
        }
        elsif (
            $method eq 'obsolete'
            || $method eq 'fuzzy'
        ) {
            $cols[$index] = $po->$method() ? 1 : 0;
        }
        elsif ( $method =~ m{\A [a-z-]+ -format \z}xms) {
            my $flag = $po->format_flag($method);
            # translate:
            # undef => 0
            # 0     => -1
            # 1     => 1
            $cols[$index] = defined $flag
                            ? (
                                $flag ? 1 : -1 ## no critic (MagicNumbers)
                            )
                            : 0;
        }
        elsif (
            $method =~ m{
                \A (?:
                    msgstr
                    | (?: msg | previous_msg ) (?: ctxt | id | id_plural )
                ) \z
            }xms
        ) {
            my $data = $po->$method();
            if (! defined $data) {
                $data = q{};
            }
            $cols[$index]
                = join  $self->{separator},
                  split m{\\n}xms,
                        $data;
        }
        elsif ( my ($n) = $method =~ m{\A msgstr_ ( \d ) \z}xms ) {
            my $data = $po->msgstr_n();
            if ($data) {
                $data = $data->{$n};
            }
            if (! defined $data) {
                $data = q{};
            }
            $cols[$index]
                = join  $self->{separator},
                  split m{\\n}xms,
                        $data;
        }
        else {
            croak "Strange extract method $method";
        }
        ++$index;
    }

    return \@cols;
}

1;

__END__

=head1 NAME

DBD::PO::Text::PO - read or write a PO file entry by entry

$Id: PO.pm 412 2009-08-29 08:58:24Z steffenw $

$HeadURL: https://dbd-po.svn.sourceforge.net/svnroot/dbd-po/trunk/DBD-PO/lib/DBD/PO/Text/PO.pm $

=head1 VERSION

2.08

=head1 SYNOPSIS

=head2 write

    use strict;
    use warnings;

    use Carp qw(croak);
    use English qw(-no_match_vars $OS_ERROR);
    require IO::File;
    require DBD::PO::Text::PO;

    my $file_handle = IO::File->new();
    $file_handle->open(
        $file_name,
        '> :encoding(utf-8)',
    ) or croak "Can not open file $file_name: $OS_ERROR;
    my $text_po = DBD::PO::Text::PO->new({
        eol     => "\n",
        charset => 'utf-8',
    });

    # header
    $text_po->write_entry(
        $file_name,
        $file_handle,
        [
            q{},
            'Content-Type: text/plain; charset=utf-8',
        ],
    );

    # line
    $text_po->write_entry(
        $file_name,
        $file_handle,
        [
            'id',
            'text',
        ],
    );

=head2 read

    use strict;
    use warnings;

    use Carp qw(croak);
    use English qw(-no_match_vars $OS_ERROR);
    require IO::File;
    require DBD::PO::Text::PO;

    my $file_handle = IO::File->new();
    $file_handle->open(
        $file_name,
        '< :encoding(utf-8)',
    ) or croak "Can not open file $file_name: $OS_ERROR;
    my $text_po = DBD::PO::Text::PO->new({
        eol     => "\n",
        charset => 'utf-8',
    });

    # header
    my $header_array_ref = $text_po->read_entry($file_name, $file_handle);

    # line
    while ( @{ my $array_ref = $text_po->read_entry($file_name, $file_handle) } ) {
        print "id: $array_ref->[0], text: $array_ref->[1]\n";
    }

=head1 DESCRIPTION

The DBD::PO::Text::PO was written as wrapper between
DBD::PO and DBD::PO::Locale::PO.

Do not use this module without DBD::PO!

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

=head1 SUBROUTINES/METHODS

=head2 init

    DBD::PO::Text::PO->init(...);

This is a class method to optimize the size of arrays.
The default settings are performant.

Do not call this method during you have an active object!

Parameters:

=over 4

=item * :plural

Allow all plural forms.

=item * :previous

Allow all previus forms.

=item * :format

Allow all format flags.

=item * :all

Allow all.

=item * c-format as example

Allow the format flag 'c-format'.
For all the other format flags see L<DBD::PO::Locale::PO>.

=back

=head2 method new

=head2 method write_entry

=head2 method read_entry

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

Carp

English

L<Params::Validate>

L<DBD::PO::Locale::PO>

Socket

L<Set::Scalar>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

not known

=head1 SEE ALSO

L<DBD::File>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut