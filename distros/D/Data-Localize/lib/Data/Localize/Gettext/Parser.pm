package Data::Localize::Gettext::Parser;
use Moo;

has encoding => (
    is       => 'ro',
    required => 1,
);

has use_fuzzy => (
    is       => 'ro',
    required => 1,
);

has keep_empty => (
    is       => 'ro',
    required => 1,
);

sub parse_file {
    my ($self, $file) = @_;

    my $enc = ':encoding(' . $self->encoding . ')';
    open(my $fh, "<$enc", $file) or die "Could not open $file: $!";

    my @block = ();
    my %lexicons;
    while ( defined( my $line = <$fh> ) ) {
        $line =~ s/[\015\012]*\z//;                  # fix CRLF issues

        if ( $line =~ /^\s*$/ ) {
            $self->_process_block(\@block, \%lexicons) if @block;
            @block = ();
            next;
        }

        push @block, $line;
    }

    $self->_process_block(\@block, \%lexicons) if @block;

    return \%lexicons;
}

sub _process_block {
    my ($self, $block, $lexicons) = @_;

    my $msgid = q{};
    my $msgstr = q{};
    my $value;
    my $is_fuzzy = 0;

    # Note that we are ignoring the various types of comments allowed in a .po
    # file - see
    # http://www.gnu.org/software/gettext/manual/gettext.html#PO-Files for
    # more details.
    #
    # We do not handle the msgstr[0]/msgstr[1] type of string.
    #
    # Finally, we don't handle msgctxt at all.
    for my $line (@{$block} ) {
        if ( $line =~ /^msgid\s+"(.*)"\s*$/ ) {
            $value = \$msgid;

            ${$value} .= $1;
        }
        elsif ( $line =~ /^msgstr\s+"(.*)"\s*$/ ) {
            $value = \$msgstr;

            ${$value} .= $1;
        }
        elsif ( $line =~ /^"(.*)"\s*$/ ) {
            ${$value} .= $1;
        }
        elsif ( $line =~ /#,\s+.*fuzzy.*$/ ) {
            $is_fuzzy = 1;
        }
    }

    return unless length $msgstr || $self->keep_empty();

    return if $is_fuzzy && ! $self->use_fuzzy();

    s/\\(n|\\|\")/ $1 eq 'n'  ? "\n" : $1 eq '\\' ? "\\" : '"' /ge for $msgid, $msgstr;

    $lexicons->{$msgid} = $msgstr;

    return;
}

1;

__END__

=head1 NAME

Data::Localize::Gettext::Parser - .po Parser 

=head1 SYNOPSIS

    use Data::Localize::Gettext::Parser;
    my $p = Data::Localize::Gettext::Parser->new();
    my $lexicons = $p->parse_file( $file );

=head1 METHODS

=head2 parse_file( $file )

Parses a .po file, and returns the lexicons that are defined

=cut
