package App::PerlNitpick::Rule::QuoteSimpleStringWithSingleQuote;
# ABSTRACT: Re-quote strings with single quotes ('') if they look "simple"

=encoding UTF-8

=head1 DESCRIPTION

This nitpicking rule re-quote simple strings with single-quote.
For example, C<"coffee"> becomes C<'coffee'>.

=head2 Simple strings ?

Simple strings is a subset of strings that satisfies all of these
constraints:

    - is a string literal (not variable)
    - is quoted with: q, qq, double-quote ("), or single-quote (')
    - is a single-line string
    - has no interpolations inside
    - has no quote characters inside
    - has no sigil characters inside
    - has no metachar

For example, here's a short list of simple strings:

    - q<肆拾貳>
    - qq{Latte Art}
    - "Spring"
    - "Error: insufficient vespene gas"

While here are some counter examples:

    - "john.smith@example.com"
    - "'s-Gravenhage"
    - 'Look at this @{[ longmess() ]}'
    - q<The symbol $ is also known as dollor sign.>

Roughly speaking, given a string, if you can re-quote it with single-quote (')
without changing its value -- then it is a simple string.

=cut

use Moose;
use PPI::Document;

sub rewrite {
    my ($self, $doc) = @_;

    for my $tok (@{$doc->find(sub { $_[1]->isa('PPI::Token::Quote::Double') }) || []}) {
        next if $tok->interpolations;
        my $value = $tok->string;
        next if index($value, "\n") > 0;
        $tok->simplify;
    }

    my @todo;
    for my $tok (@{ $doc->find(sub { $_[1]->isa('PPI::Token::Quote::Interpolate') }) || []}) {
        my $value = $tok->string;
        next if $value =~ /[\\\$@%\'\"]/ || index($value, "\n") > 0;
        push @todo, $tok;
    }

    for my $tok (@{ $doc->find(sub { $_[1]->isa('PPI::Token::Quote::Literal') }) || []}) {
        my $value = $tok->string;
        next if $value =~ /\'/ || index($value, "\n") > 0;
        push @todo, $tok;
    }

    for my $tok (@todo) {
        my $value = $tok->string;
        # I probably know what I am doing.
        $tok->{content} = "'" . $tok->string . "'";
        bless $tok, 'PPI::Token::Quote::Single';
    }

    return $doc;
}

1;
