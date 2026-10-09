package SessionPgTest::Ddl;
use strict;
use warnings;
use English qw( -no_match_vars );

# The DDL the tests run against is EXTRACTED FROM THE MODULE'S OWN POD, so the
# table the documentation tells you to create is the table that gets tested. A
# documented schema that drifts from the working one is the failure this
# arrangement exists to prevent.
#
# Shared by t/session_pg.t and t/concurrency.t.
#
# Perl 5.12, as the module: no signatures, no s///r.
#
#   SessionPgTest::Ddl::apply( $dbh, 'myschema', 'DDL' )
#       or die $SessionPgTest::Ddl::REASON;

our $REASON;

my $MODULE = 'lib/Dancer2/Session/Pg.pm';

sub ddl_from_pod {
    my ($section) = @_;
    undef $REASON;

    open my $fh, '<:encoding(UTF-8)', $MODULE
      or do { $REASON = "cannot read $MODULE: $OS_ERROR"; return };
    local $INPUT_RECORD_SEPARATOR = undef;
    my $pod = <$fh>;
    close $fh or do { $REASON = "cannot close $MODULE: $OS_ERROR"; return };

    # Every literal space here is written [ ] ON PURPOSE. Under /x a bare space
    # is stripped, and this pattern would silently become "=head2DDL", which
    # matches nothing at all.
    my ($body) = $pod =~ m/^=head2[ ]\Q$section\E[ ]*\n(.*?)(?=^=head[12][ ])/msx;
    if ( !defined $body ) {
        $REASON = "no =head2 '$section' in $MODULE";
        return ();
    }

    # Verbatim paragraphs are the indented lines; prose starts at column 0.
    # Keep EVERY line indented four or more -- a continuation line carrying a
    # COMMENT's string literal is indented eight, and dropping it silently
    # produces a COMMENT statement with no text and a syntax error further on.
    my @sql = grep { m/\A[ ]{4}/msx } split m/\n/msx, $body;
    s/\A[ ]{4}//msx for @sql;
    return join "\n", @sql;
}

# Split SQL on statement boundaries WITHOUT cutting inside a string literal.
# The COMMENT ON texts contain semicolons, and a naive split on ";" slices one
# in half and produces a syntax error three statements later.
sub split_sql {
    my ($sql) = @_;
    my @statements;
    my $current   = q{};
    my $in_string = 0;
    for my $char ( split m//msx, $sql ) {
        if ( $char eq q{'} ) { $in_string = !$in_string; $current .= $char; next; }
        if ( $char eq q{;} && !$in_string ) { push @statements, $current; $current = q{}; next; }
        $current .= $char;
    }
    push @statements, $current;
    return grep { m/\S/msx } @statements;
}

# Create $schema and apply the named POD section to it, rewriting the `web.`
# qualifier the documentation uses. Returns true, or false with $REASON set.
sub apply {
    my ( $dbh, $schema, $section ) = @_;

    my $ddl = ddl_from_pod($section);
    return () if !defined $ddl;

    if ( $ddl !~ m/CREATE[ ]TABLE/msx ) {
        $REASON = "=head2 '$section' yielded no CREATE TABLE";
        return ();
    }

    $ddl =~ s/\bweb[.]/$schema./msxg;
    $dbh->do("CREATE SCHEMA $schema");
    $dbh->do($_) for split_sql($ddl);
    return 1;
}

1;
