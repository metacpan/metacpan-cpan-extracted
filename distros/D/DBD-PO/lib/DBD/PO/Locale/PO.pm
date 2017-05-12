package DBD::PO::Locale::PO;

use strict;
use warnings;

use version; our $VERSION = qv('0.21.5');

use Carp qw(croak);
use English qw(-no_match_vars $EVAL_ERROR $OS_ERROR);

use parent qw(Exporter);
our @EXPORT_OK = qw(
    @FORMAT_FLAGS
    $ALLOW_LOST_BLANK_LINES
);

our @FORMAT_FLAGS = qw(
    c-format
    objc-format
    sh-format
    python-format
    lisp-format
    elisp-format
    librep-format
    scheme-format
    smalltalk-format
    java-format
    csharp-format
    awk-format
    object-pascal-format
    ycp-format
    tcl-format
    perl-format
    perl-brace-format
    php-format
    gcc-internal-format
    qt-format
    kde-format
    boost-format
);

our $ALLOW_LOST_BLANK_LINES = 1;

sub new {
    my ($this, %options) = @_;

    my $class = ref $this || $this;
    my $self = bless {}, $class;
    $self->eol( $options{eol} );
    $self->_flags({});
    for (qw(
        msgctxt          msgid          msgid_plural
        previous_msgctxt previous_msgid previous_msgid_plural
        msgstr msgstr_n
        comment automatic reference fuzzy obsolete
        loaded_line_number
    )) {
        if ( defined $options{"-$_"} ) {
            $self->$_( $options{"-$_"} );
        }
    }
    for my $format (@FORMAT_FLAGS) {
        if ( defined $options{"-$format"} ) {
            $self->format_flag($format => 1);
        }
        if ( defined $options{"-no-$format"} ) {
            $self->format_flag($format => 0);
        }
    }

    return $self;
}

sub eol {
    my ($self, @params) = @_;

    if (@params) {
        my $eol = shift @params;
        $self->{eol} = $eol;
    }

    return defined $self->{eol}
           ? $self->{eol}
           : "\n";
}

# create methods
for (qw(
    msgctxt          msgid          msgid_plural
    previous_msgctxt previous_msgid previous_msgid_plural
    msgstr
    comment automatic reference obsolete
    _flags loaded_line_number
)) {
    my $name = $_;
    no strict 'refs'; ## no critic (NoStrict)
    *{$name} = sub {
    my ($self, @params) = @_;

    return @params
           ? $self->{$name} = shift @params
           : $self->{$name};
    };
}

sub msgstr_n {
    my ($self, @params) = @_;

    if (@params) {
        my $hashref = shift @params;

        # check that we have a hashref.
        ref $hashref eq 'HASH'
            or croak 'Argument to msgstr_n must be a hashref: { n => "string n", ... }.';

        # Check that the keys are all numbers.
        for ( keys %{$hashref} ) {
            croak 'Keys to msgstr_n hashref must be numbers'
                if ! defined $_ || m{\D}xms;
        }

        # Write all the values in the hashref.
        @{ $self->{msgstr_n} }{ keys %{$hashref} } = values %{$hashref};
    }

    return $self->{msgstr_n};
}

sub add_flag {
    my ($self, $flag_name) = @_;

    $self->_flags()->{$flag_name} = 1;

    return $self;
}

sub remove_flag {
    my ($self, $flag_name) = @_;

    delete $self->_flags()->{$flag_name};

    return $self;
}

sub has_flag {
    my ($self, $flag_name) = @_;

    my $flags = $self->_flags();
    exists $flags->{$flag_name}
        or return;

    return $flags->{$flag_name};
}

sub fuzzy {
    my ($self, @params) = @_;

    if (@params) {
        my $value = shift @params;
        return
            $value
            ? $self->add_flag('fuzzy')
            : $self->remove_flag('fuzzy');
    }

    return $self->has_flag('fuzzy');
}

sub format_flag {
    my ($self, $flag_name, @params) = @_;

    if (@params) { # set or clear the flags
        my $value = shift @params;
        if (! defined($value) || ! length $value) {
            $self->remove_flag($flag_name);
            $self->remove_flag("no-$flag_name");
            return;
        }
        elsif ($value) {
            $self->add_flag($flag_name);
            $self->remove_flag("no-$flag_name");
            return 1;
        }
        else {
            $self->add_flag("no-$flag_name");
            $self->remove_flag($flag_name);
            return 0;
        }
    }
    # check the flags
    return 1 if $self->has_flag($flag_name);
    return 0 if $self->has_flag("no-$flag_name");

    return;
}

sub dump { ## no critic (BuiltinHomonyms)
    my $self = shift;

    my $obsolete = $self->obsolete() ? '#~ ' : q{};
    my $dump = q{};
    if ( defined $self->comment() ) {
        $dump .= $self->_dump_multi_comment( $self->comment(), '# ' );
    }
    if ( defined $self->automatic() ) {
        $dump .= $self->_dump_multi_comment( $self->automatic(), '#. ' );
    }
    if ( defined $self->reference() ) {
        $dump .= $self->_dump_multi_comment( $self->reference(), '#: ' );
    }
    my $flags = join q{}, map {", $_"} sort keys %{ $self->_flags() };
    if ($flags) {
        $dump .= "#$flags"
                 . $self->eol();
    }
    if ( defined $self->previous_msgctxt() ) {
        $dump .= '#| msgctxt '
                 . $self->quote( $self->previous_msgctxt() );
    }
    if ( defined $self->previous_msgid() ) {
        $dump .= '#| msgid '
                 . $self->quote( $self->previous_msgid() );
    }
    if ( defined $self->previous_msgid_plural() ) {
        $dump .= '#| msgid_plural '
                 . $self->quote( $self->previous_msgid_plural() );
    }
    if ( defined $self->msgctxt() ) {
        $dump .= "${obsolete}msgctxt "
                 . $self->quote( $self->msgctxt() );
    }
    $dump .= "${obsolete}msgid "
             . $self->quote( $self->msgid() );
    if ( defined $self->msgid_plural() ) {
        $dump .= "${obsolete}msgid_plural "
                 . $self->quote( $self->msgid_plural() );
    }
    if ( defined $self->msgstr() ) {
        $dump .= "${obsolete}msgstr "
                 . $self->quote( $self->msgstr() );
    }
    if ( my $msgstr_n = $self->msgstr_n() ) {
        $dump .= join
            q{},
            map {
                "${obsolete}msgstr[$_] "
                . $self->quote( $msgstr_n->{$_} );
            } sort {
                $a <=> $b
            } keys %{$msgstr_n};
    }

    $dump .= $self->eol();

    return $dump;
}

sub _dump_multi_comment {
    my $self    = shift;
    my $comment = shift;
    my $leader  = shift;

    my $eol = $self->eol();

    return join q{}, map {
        "$leader$_$eol";
    } split m{\Q$eol\E}xms, $comment;
}

# Quote a string properly
sub quote {
    my $self   = shift;
    my $string = shift;

    if (! defined $string) {
        return q{""};
    }
    my %named = (
        ## no critic (InterpolationOfLiterals)
        #qq{\a} => qq{\\a}, # BEL
        #qq{\b} => qq{\\b}, # BS
        #qq{\t} => qq{\\t}, # TAB
        qq{\n}  => qq{\\n}, # LF
        #qq{\f} => qq{\\f}, # FF
        #qq{\r} => qq{\\r}, # CR
        qq{"}   => qq{\\"},
        qq{\\}  => qq{\\\\},
        ## use critic (InterpolationOfLiterals)
    );
    $string =~ s{
        ( [^ !#$%&'()*+,\-.\/0-9:;<=>?@A-Z\[\]\^_`a-z{|}~] )
    }{
        ord $1 < 0x80
        ? (
            exists $named{$1}
            ? $named{$1}
            : sprintf '\x%02x', ord $1
        )
        : $1;
    }xmsge;
    $string = qq{"$string"};
    # multiline
    my $eol = $self->eol();
    if ($string =~ s{\A ( " .*? \\n )}{""$eol$1}xms) {
        $string =~ s{\\n}{\\n"$eol"}xmsg;
    }

    return "$string$eol";
}

sub dequote {
    my $self   = shift;
    my $string = shift;
    my $eol    = shift || $self->eol();

    if (! defined $string) {
        $string = q{};
    }
    # multiline
    if ($string =~ s{\A "" \Q$eol\E}{}xms) {
        $string =~ s{\\n"\Q$eol\E"}{\\n}xmsg;
    }
    $string =~ s{( [\$\@] )}{\\$1}xmsg; # make uncritical
    ($string) = $string =~ m{
        \A
        (
            "
            (?: \\\\ | \\" | [^"] )*
            "
            # eol
        )
    }xms; # check the quoted string and untaint
    return q{} if ! defined $string;
    my $dequoted = eval $string; ## no critic (StringyEval)
    croak qq{Can not eval string "$string": $EVAL_ERROR} if $EVAL_ERROR;

    return $dequoted;
}

sub save_file_fromarray {
    my ($self, @params) = @_;

    return $self->_save_file(@params, 0);
}

sub save_file_fromhash {
    my ($self, @params) = @_;

    return $self->_save_file(@params, 1);
}

sub _save_file {
    my $self     = shift;
    my $file     = shift;
    my $entries  = shift;
    my $as_hash  = shift;

    open my $out, '>', $file ## no critic (BriefOpen)
        or croak "Open $file: $OS_ERROR";
    if ($as_hash) {
        for (sort keys %{$entries}) {
            print {$out} $entries->{$_}->dump()
                or croak "Print $file: $OS_ERROR";
        }
    }
    else {
        for (@{$entries}) {
            print {$out} $_->dump()
                or croak "Print $file: $OS_ERROR";
        }
    }
    close $out
        or croak "Close $file $OS_ERROR";

    return $self;
}

sub load_file_asarray {
    my $self = shift;
    my $file = shift;
    my $eol  = shift || "\n";

    if (ref $file) {
        return $self->_load_file($file, $file, $eol, 0);
    }
    open my $in, '<', $file
        or croak "Open $file: $OS_ERROR";
    my $array_ref = $self->_load_file($file, $in, $eol, 0);
    close $in
        or croak "Close $file: $OS_ERROR";

    return $array_ref;
}

sub load_file_ashash {
    my $self = shift;
    my $file = shift;
    my $eol  = shift || "\n";

    if (ref $file) {
        return $self->_load_file($file, $file, $eol, 1);
    }
    open my $in, '<', $file
        or croak "Open $file: $OS_ERROR";
    my $hash_ref = $self->_load_file($file, $in, $eol, 1);
    close $in
        or croak "Close $file: $OS_ERROR";

    return $hash_ref;
}

sub _load_file {
    my $self        = shift;
    my $file_name   = shift;
    my $file_handle = shift;
    my $eol         = shift;
    my $ashash      = shift;

    my $line_number = 0;
    my (@entries, %entries);
    while (
        my $po = $self->load_entry(
            $file_name,
            $file_handle,
            \$line_number,
            $eol,
        )
    ) {
        # ashash
        if ($ashash) {
            if ( $po->_hash_key_ok(\%entries) ) {
                $entries{ $po->msgid() } = $po;
            }
        }
        # asarray
        else {
            push @entries, $po;
        }
    }

    return $ashash
           ? \%entries
           : \@entries;
}

sub load_entry { ## no critic (ExcessComplexity)
    my $self            = shift;
    my $file_name       = shift;
    my $file_handle     = shift;
    my $line_number_ref = shift;
    my $eol             = shift || "\n";

    my $class = ref $self || $self;
    my %last_line_of_section; # to find the end of an entry
    my $current_section_key;  # to add lines

    my ($current_line_number, $current_pos);
    my $safe_current_position = sub {
        # safe information to can roll back
        $current_line_number = ${$line_number_ref};
        $ALLOW_LOST_BLANK_LINES
            or return;
        $current_pos         = tell $file_handle;
        defined $current_pos
            or croak "Can not tell file pointer of file $file_name: $OS_ERROR";
    };
    $safe_current_position->();

    my $is_new_entry = sub {
        $current_section_key = shift;
        if (
            $ALLOW_LOST_BLANK_LINES
            && exists $last_line_of_section{ $current_section_key }
            && $last_line_of_section{ $current_section_key }
               != ${$line_number_ref} - 1
        ) {
            # roll back
            ${$line_number_ref} = $current_line_number;
            seek $file_handle, $current_pos, 0
                or croak "Can not seek file pointer of file $file_name: $OS_ERROR";
            return 1; # this is a new entry
        }
        $last_line_of_section{ $current_section_key } = ${$line_number_ref};
        return;
    };

    my $po;             # build an object during read an entry
    my %buffer;         # find the different msg...
    my $current_buffer; # to add lines
    LINE:
    while (my $line = <$file_handle>) {
        $line =~ s{\Q$eol\E \z}{}xms;
        my $line_number = ++${$line_number_ref};
        my ($obsolete, $key, $value);
        # Empty line. End of an entry.
        if ( $line =~ m{\A \s* \z}xms ) { ## no critic (CascadingIfElse)
            last LINE if $po;
        }
        # strings
        elsif (
            ($obsolete, $key, $value)
                = $line =~ m{\A ( \# ~ \s+ )? ( msgctxt | msgid | msgid_plural | msgstr ) \s+ (.*)}xms
        ) {
            last LINE if $is_new_entry->($key);
            $po ||= $class->new(eol => $eol, -loaded_line_number => $line_number);
            $buffer{$key} = $self->dequote($value, $eol);
            $current_buffer = \$buffer{$key};
            if ($obsolete) {
                $po->obsolete(1);
            }
        }
        # contined string
        elsif ( $line =~ m{\A (?: \# ~ \s+ )? "}xms ) {
            ${$current_buffer} .= $self->dequote($line, $eol);
            $last_line_of_section{ $current_section_key } = $line_number;
        }
        # translated string, plural
        elsif (
            ($obsolete, $key, $value)
                = $line =~  m{\A ( \# ~ \s+ )? msgstr \[ (\d+) \] \s+ (.*)}xms
        ) {
            last LINE if $is_new_entry->('msgstr_n');
            $buffer{msgstr_n}->{$key} = $self->dequote($value, $eol);
            $current_buffer = \$buffer{msgstr_n}->{$key};
            if ($obsolete) {
                $po->obsolete(1);
            }
        }
        # reference
        elsif ( ($value) = $line =~ m{\A \# : \s+ (.*)}xms ) {
            last LINE if $is_new_entry->('comment');
            $po ||= $class->new(eol => $eol, -loaded_line_number => $line_number);
            # maybe more in 1 line
            $value = join $eol, split m{\s+}xms, $value;
            $po->reference(
                defined $po->reference()
                ? $po->reference() . "$eol$value"
                : $value
            );
        }
        # flags
        elsif ( ($value) = $line =~ m{\A \# , \s+ (.*)}xms) {
            last LINE if $is_new_entry->('comment');
            $po ||= $class->new(eol => $eol, -loaded_line_number => $line_number);
            for my $flag ( split m{\s* , \s*}xms, $value ) {
                $po->add_flag($flag);
            }
        }
        # Translator comments
        elsif (
            $line =~ m{\A \# \s+ (.*)}xms
            || $line =~ m{\A \# ()\z}xms
        ) {
            $value = $1;
            last LINE if $is_new_entry->('comment');
            $po ||= $class->new(eol => $eol, -loaded_line_number => $line_number);
            $po->comment(
                defined $po->comment()
                ? $po->comment() . "$eol$value"
                : $value
            );
        }
        # Automatic comments
        elsif ( ($value) = $line =~ m{\A \# \. \s* (.*)}xms ) {
            last LINE if $is_new_entry->('comment');
            $po ||= $class->new(eol => $eol, -loaded_line_number => $line_number);
            $po->automatic(
                defined $po->automatic()
                ? $po->automatic() . "$eol$value"
                : $value
            );
        }
        # previous
        elsif (
            ($key, $value)
                = $line =~ m{\A \# \| \s+ ( msgctxt | msgid | msgid_plural ) \s+ (.*)}xms
        ) {
            last LINE if $is_new_entry->('comment');
            $po ||= $class->new(eol => $eol, -loaded_line_number => $line_number);
            $key = "previous_$key";
            $buffer{$key} = $self->dequote($value, $eol);
            $current_buffer = \$buffer{$key};
        }
        else {
            warn "Strange line at $file_name line $line_number: $line\n";
        }
        $safe_current_position->();
    }
    if ($po) {
        for my $key (qw(
            msgctxt msgid msgid_plural
            previous_msgctxt previous_msgid previous_msgid_plural
            msgstr msgstr_n
        )) {
            if ( defined $buffer{$key} ) {
                $po->$key( $buffer{$key} );
            }
        }
        return $po;
    }

    return; # no entry found
}

sub _hash_key_ok {
    my ($self, $entries) = @_;

    my $key = $self->msgid();

    if ($entries->{$key}) {
        # don't overwrite non-obsolete entries with obsolete ones
        return if $self->obsolete() && ! $entries->{$key}->obsolete();
        # don't overwrite translated entries with untranslated ones
        return if $self->msgstr() !~ m{\w}xms
                  && $entries->{$key}->msgstr() =~ m{\w}xms;
    }

    return 1;
}

1;

__END__

=head1 NAME

DBD::PO::Locale::PO - Perl module for manipulating .po entries from GNU gettext

$Id: PO.pm 412 2009-08-29 08:58:24Z steffenw $

$HeadURL: https://dbd-po.svn.sourceforge.net/svnroot/dbd-po/trunk/DBD-PO/lib/DBD/PO/Locale/PO.pm $

=head1 VERSION

v0.21.5

=head1 SYNOPSIS

    require DBD::PO::Locale::PO;

    $po = DBD::PO::Locale::PO->new([eol => $eol, ['-option' => 'value', ...]])
    [$string =] $po->comment(['new string']);
    [$string =] $po->automatic(['new string']);
    [$string =] $po->reference(['new string']);
    [$string =] $po->msgctxt(['new string']);
    [$string =] $po->previous_msgctxt(['new string']);
    [$string =] $po->msgid(['new string']);
    [$string =] $po->previous_msgid(['new string']);
    [$string =] $po->msgid_plural(['new string']);
    [$string =] $po->previous_msgid_plural(['new string']);
    [$string =] $po->msgstr(['new string']);
    [$string =] $po->msgstr_n([{0 => 'new string', 1 => ...}]);
    [$boolean =] $po->obsolete([$boolean]);
    [$value =] $po->fuzzy([value]);
    [$value =] $po->add_flag('c-format');
    [$value =] $po->add_flag('...-format');
    print $po->dump();

    $quoted_string = $po->quote($string);
    $string = $po->dequote($quoted_string);
    $string = DBD::PO::Locale::PO->dequote($quoted_string, $eol);

    $aref = DBD::PO::Locale::PO->load_file_asarray(<filename>);
    $href = DBD::PO::Locale::PO->load_file_ashash(<filename>);
    DBD::PO::Locale::PO->save_file_fromarray(<filename>, $aref);
    DBD::PO::Locale::PO->save_file_fromhash(<filename>, $href);

=head1 DESCRIPTION

This module simplifies management of GNU gettext .po files and is an
alternative to using emacs po-mode. It provides an object-oriented
interface in which each entry in a .po file is a DBD::PO::Locale::PO object.

=head1 SUBROUTINES/METHODS

=over 28

=item method new

    my $po = DBD::PO::Locale::PO->new();
    my $po = DBD::PO::Locale::PO->new(%options);

Specify an eol or accept the default "\n".

    eol => "\r\n"

Create a new DBD::PO::Locale::PO object to represent a po entry.
You can optionally set the attributes of the entry by passing
a list/hash of the form:

    '-option' => 'value', '-option' => 'value', etc.

Where options are msgid, msgid_plural, msgstr, msgstr_n, msgctxt,
comment, automatic, reference, obsolete, fuzzy. See accessor methods below.

To generate a po file header, add an entry with an empty
msgid, like this:

    $po = DBD::PO::Locale::PO->new(
        '-msgid'  => q{},
        '-msgstr' =>
            "Project-Id-Version: PACKAGE VERSION\n"
            . "PO-Revision-Date: YEAR-MO-DA HO:MI +ZONE\n"
            . "Last-Translator: FULL NAME <EMAIL@ADDRESS>\n"
            . "Language-Team: LANGUAGE <LL@li.org>\n"
            . "MIME-Version: 1.0\n"
            . "Content-Type: text/plain; charset=CHARSET\n"
            . "Content-Transfer-Encoding: ENCODING\n",
    );

=item method eol

Set or get the eol string from the object.

=item method msgid

Set or get the untranslated string from the object.

This method expects the new string in unquoted form
but returns the current string in quoted form.

=item method previous_msgid

Like before but the previous one.

=item method msgid_plural

Set or get the untranslated plural string from the object.

This method expects the new string in unquoted form
but returns the current string in quoted form.

=item method previous_msgid_plural

Like before but the previous one.

=item method msgstr

Set or get the translated string from the object.

This method expects the new string in unquoted form
but returns the current string in quoted form.

=item method msgstr_n

Get or set the translations if there are purals involved. Takes and
returns a hashref where the keys are the 'N' case and the values are
the strings. eg:

    $po->msgstr_n(
        {
            0 => 'found %d singular translation',
            1 => 'found %d plural translation case 1',
            2 => 'found %d plural translation case 2',
            3 => 'found %d plural translation case 3',
            4 => 'found %d plural translation case 4',
            5 => 'found %d plural translation case 5',
        }
    );

This method expects the new strings in unquoted form
but returns the current strings in quoted form.

=item method msgctxt

Set or get the translation context string from the object.

This method expects the new string in unquoted form
but returns the current string in quoted form.

=item method previous_msgctxt

Like before but the previous one.

=item method obsolete

Returns 1 if the entry is obsolete.
Obsolete entries have their msgid, msgid_plural, msgstr, msgstr_n and msgctxt
lines commented out with "#~"

When using load_file_ashash, non-obsolete entries
will always replace obsolete entries with the same msgid.

=item method comment

Set or get translator comments from the object.

If there are no such comments, then the value is undef.
Otherwise, the value is a string
that contains the comment lines delimited with "\n".
The string includes neither the S<"# "> at the beginning of
each comment line nor the newline at the end of the last comment line.

=item method automatic

Set or get automatic comments from the object (inserted by
emacs po-mode or xgettext).

If there are no such comments, then the value is undef.
Otherwise, the value is a string
that contains the comment lines delimited with "\n".
The string includes neither the S<"#. "> at the beginning of
each comment line nor the newline at the end of the last comment line.

=item method reference

Set or get reference marking comments from the object (inserted
by emacs po-mode or gettext).

=item method fuzzy

Set or get the fuzzy flag on the object ("check this translation").
When setting, use 1 to turn on fuzzy, and 0 to turn it off.

=item method format_flag

The format name at this example is perl.

Set or get the perl-format or no-perl-format flag on the object.

This can take 3 values:
1 implies perl-format, 0 implies no-perl-format, and undefined implies neither.

Allowed names are:
c-format,
objc-format,
sh-format,
python-format,
lisp-format,
elisp-format,
librep-format,
scheme-format,
smalltalk-format,
java-format,
csharp-format,
awk-format,
object-pascal-format,
ycp-format,
tcl-format,
perl-format,
perl-brace-format,
php-format,
gcc-internal-format,
qt-format,
kde-format,
boost-format.

=item method has_flag

    if ($po->has_flag('perl-format')) {
        ...
    }

Returns true if the flag exists in the entry's #, comment

=item method add_flag

    $po->add_flag('perl-format');

Adds the flag to the #, comment

=item method remove_flag

    $po->remove_flag('perl-format');

Removes the flag from the #, comment

=item method loaded_line_number

When using one of the load_file_as* methods,
this will return the line number that the entry started at in the file.

=item method dump

Returns the entry as a string, suitable for output to a po file.

=item method quote

Applies po quotation rules to a string, and returns the quoted string.
The quoted string will have all existing double-quote characters
escaped by backslashes, and will be enclosed in double quotes.

=item method dequote

Returns a quoted po string to its natural form.

=item method load_file_asarray

Given the filename of a po-file,
reads the file and returns a reference
to a list of DBD::PO::Locale::PO objects
corresponding to the contents of the file, in the same order.

=item method load_file_ashash

Given the filename of a po-file,
reads the file and returns a reference
to a hash of DBD::PO::Locale::PO objects
corresponding to the contents of the file.
The hash keys are the untranslated strings,
so this is a cheap way to remove duplicates.
The method will prefer to keep entries that have been translated.

=item method save_file_fromarray

Given a filename and a reference to a list of DBD::PO::Locale::PO objects,
saves those objects to the file, creating a po-file.

=item method save_file_fromhash

Given a filename and a reference to a hash of DBD::PO::Locale::PO objects,
saves those objects to the file, creating a po-file.
The entries are sorted alphabetically by untranslated string.

=item method load_entry

Method was added to read entry by entry.

    use Carp qw(croak);
    use English qw(-no_match_vars $OS_ERROR);
    use Socket qw($CRLF);
    use DBD::PO::Locale::PO;

    open my $file_handle, '<', $file_name
        or croak $OS_ERROR;
    $eol = $CRLF;
    my $line_number = 0;
    while (
        my $po = DBD::PO::Locale::PO->load_entry(
            $file_name,
            $file_handle,
            \$line_number,
            $eol, # optional, default "\n"
        )
    ) {
        do_something_with($po);
    }

=back

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

Carp

English

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

If you load_file_as* then save_file_from*, the output file may have slight
cosmetic differences from the input file (an extra blank line here or there).
(And the quoting of binary values can be changed, but all this is not a Bug.)

msgid, msgid_plural, msgstr, msgstr_n and msgctxt
expect a non-quoted string as input, but return quoted strings.
The maintainer of Locale::PO was hesitant to change this in fear
of breaking the modules/scripts of people already using Locale::PO.
(Fixed in DBD::PO::Locale::PO)

Locale::PO requires blank lines between entries,
but Uniforum style PO files don't have any. (Fixed)

=head1 SEE ALSO

L<Locale::Maketext::Lexicon> xgettext.pl

L<http://www.gnu.org/software/gettext/manual/gettext.html>

=head1 AUTHOR

Steffen Winkler C<< <steffenw at cpan.org> >>

This module is a bugfixed, changed and extended copy
of Module L<Locale::PO>, version '0.21'.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 - 2009,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut