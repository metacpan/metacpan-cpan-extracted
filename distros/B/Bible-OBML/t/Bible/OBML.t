use Test2::V0;
use Bible::OBML;

my $self = Bible::OBML->new;
isa_ok( $self, 'Bible::OBML' );

can_ok( $self, $_ ) for ( qw(
    indent_width reference_acronym fnxref_acronym wrap_at wrap_lines wrap_indents reference
    data html obml
) );

sub deindent {
    my $text = join( "\n", @_ );
    $text =~ s/^[ ]{4}//mg;
    $text =~ s/(?:^\s+|\s+$)//g;
    return $text;
}

my $obml = deindent(q$
    ~ 2 Corinthians 6:8-12 ~

    |8| Jesus said, "*I am the ^way^{Mt 5:29; Ro 14:13, 20; 1Co 3:9; 8:9, 13; 9:12;
    10:32; 2Co 5:20} and the truth and the light.* |9| *For it is written:*"

        The \Lord\ is a mighty fortress[literally ^castle^],
            the Creator of all things.
        |10| In the time of my favor I heard you,
            and in the day of salvation I helped you.

    = Header =

    |11| Then stuff happened.

    # This is a comment.

        # This is also a comment.

    == Sub-Header ==

    |12| Then more stuff happened.
$);

my $html = deindent(q$
    <obml><reference>2 Corinthians 6:8-12</reference>

    <p><verse_number>8</verse_number>Jesus said, "<woj>I am the <i>way</i><crossref>Mt 5:29; Ro 14:13, 20; 1Co 3:9; 8:9, 13; 9:12; 10:32; 2Co 5:20</crossref> and the truth and the light.</woj> <verse_number>9</verse_number><woj>For it is written:</woj>"</p>

    <p><indent level="1">The <small_caps>Lord</small_caps> is a mighty fortress<footnote>literally <i>castle</i></footnote>,</indent><br>
    <indent level="2">the Creator of all things.</indent><br>
    <indent level="1"><verse_number>10</verse_number>In the time of my favor I heard you,</indent><br>
    <indent level="2">and in the day of salvation I helped you.</indent></p>

    <header>Header</header>

    <p><verse_number>11</verse_number>Then stuff happened.</p>

    <sub_header>Sub-Header</sub_header>

    <p><verse_number>12</verse_number>Then more stuff happened.</p></obml>
$);

is( $self->obml($obml)->html, $html, 'obml -> html' );
is( $self->html($html)->html, $html, 'html -> html' );

( my $clean_obml = $obml ) =~ s/^\s*#.*?\n//mg;
is( $self->html($html)->obml, $clean_obml, 'html -> obml' );
is( $self->obml($obml)->obml, $clean_obml, 'obml -> obml' );

my $data = $self->obml($obml)->data;
is( $data, $self->html($html)->data, 'data == data' );
is( $data, $self->data($data)->data, 'data -> data' );

is( $self->data($data)->html, $html,       'data -> html' );
is( $self->data($data)->obml, $clean_obml, 'data -> obml' );

done_testing;
