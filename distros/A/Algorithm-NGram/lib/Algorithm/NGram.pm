package Algorithm::NGram;
use strict;
use warnings;

use Carp qw (croak);
use Class::Accessor::Fast;
use List::Util qw (shuffle);
use Storable;

use base qw/Class::Accessor::Fast/;
__PACKAGE__->mk_accessors(qw/ngram_width token_table tokens dirty/);

use constant {
    START_TOK => ':STARTTOK:',
    END_TOK => ':ENDTOK:',
};

our $VERSION = '0.9';

=head1 NAME

Algorithm::NGram

=head1 SYNPOSIS

    use Algorithm::NGram;
    my $ng = Algorithm::NGram->new(ngram_width => 3); # use trigrams

    # feed in text
    $ng->add_text($text1); # analyze $text1
    $ng->add_text($text2); # analyze $text2

    # feed in arbitrary sequence of tokens
    $ng->add_start_token;
    $ng->add_tokens(qw/token1 token2 token3/);
    $ng->add_end_token;

    my $output = $ng->generate_text;

=head1 DESCRIPTION

This is a module for analyzing token sequences with n-grams. You can
use it to parse a block of text, or feed in your own tokens. It can
generate new sequences of tokens from what has been fed in.

=head1 EXPORT

None.

=head1 METHODS

=over 4

=item new

Create a new n-gram analyzer instance.

B<Options:>

=over 4

=item ngram_width

This is the "window size" of how many tokens the analyzer will keep
track of. A ngram_width of two will make a bigram, a ngram_width of
three will make a trigram, etc...

=back

=cut

sub new {
    my ($class, %opts) = @_;

    # trigram by default
    my $ngram_width = delete $opts{ngram_width} || 3;

    my $token_table = delete $opts{token_table} || {};
    my $tokens = delete $opts{tokens} || [];

    my $self = {
        ngram_width => $ngram_width,
        token_table => $token_table,
        tokens => $tokens,
    };

    bless $self, $class;
    $self->dirty(1);

    return $self;
}

=item ngram_width

Returns token window size (e.g. the "n" in n-gram)

=cut

=item token_table

Returns n-gram table

=cut

=item add_text

Splits a block of text up by whitespace and processes each word as a
token. Automatically calls C<add_start_token()> at the beginning of
the text and C<add_end_token()> at the end.

=cut

# process a block of text, auto-tokenizing it
sub add_text {
    my ($self, $text) = @_;

    $self->add_start_token;

    # tokenize text
    foreach my $tok (split(/ /, $text)) {
        $tok =~ s/ +//g; # remove spaces

        next unless $tok;

        $self->add_token($tok);
    }

    $self->add_end_token;
}

=item add_tokens

Adds an arbitrary list of tokens.

=cut

*add_token = \&add_tokens;
sub add_tokens {
    my ($self, @tokens) = @_;
    push @{$self->{tokens}}, @tokens;
    $self->dirty(1);
}

=item add_start_token

Adds the "start token." This is useful because you often will want to
mark the beginnings and ends of a token sequence so that when
generating your output the generator will know what tokens start a
sequence and when to end.

=cut

sub add_start_token {
    my ($self) = @_;
    $self->add_token(START_TOK);
}

=item add_end_token

Adds the "end token." See C<add_start_token()>.

=cut

sub add_end_token {
    my ($self) = @_;
    $self->add_token(END_TOK);
}

=item analyze

Generates an n-gram frequency table. Returns a hashref of
I<< N => tokens => count >>, where N is the number of tokens (will be from 2
to ngram_width). You will not normally need to call this unless you
want to get the n-gram frequency table.

=cut

sub analyze {
    my $self = shift;

    $self->{token_table} = {};

    my @all_tokens = @{$self->tokens};

    for (my $i = 1; $i <= $self->ngram_width; $i++) {
        for (my $tok_idx = 0; $tok_idx < @all_tokens; $tok_idx++) {
            my $tok_idx_end = $tok_idx + $i - 1;
            $tok_idx_end = @all_tokens if $tok_idx_end > @all_tokens;

            # get tokens
            my @tokens = @all_tokens[$tok_idx ... $tok_idx_end];

            # get the token that follows this ngram
            my $next_tok = $all_tokens[$tok_idx_end + 1];
            next unless $next_tok && @tokens;

            # don't care about what follows END_TOK
            next if $tokens[0] eq END_TOK;

            my $token_key = $self->token_key(@tokens);

            # increment the count of $next_tok after this ngram
            $self->{token_table}->{$i}->{$token_key}->{$next_tok}++;
        }
    }

    $self->dirty(0);

    return $self->{token_table};
}

=item generate_text

After feeding in text tokens, this will return a new block of text
based on whatever text was added.

=cut

sub generate_text {
    my ($self, %opts) = @_;

    my @toks = $self->generate(%opts);
    return join(' ', @toks);
}

=item generate

Generates a new sequence of tokens based on whatever tokens have
previously been fed in.

=cut

sub generate {
    my ($self, %opts) = @_;

    # update n-gram if things have changed
    $self->analyze
        if $self->dirty && ! $opts{no_analyze};

    my @ret_toks;
    my $tok = START_TOK;

    my @cur_toks = ();

    do {
        push @ret_toks, $tok if $tok ne START_TOK;

        push @cur_toks, $tok;
        shift @cur_toks while @cur_toks > $self->ngram_width;

        $tok = $self->next_tok(@cur_toks);
    } while $tok && $tok ne END_TOK;

    return @ret_toks;
}

=item next_tok

Given a list of tokens, will pick a possible token to come next.

=cut

sub next_tok {
    my ($self, @toks) = @_;

    return undef unless %{$self->token_table};

    my $tok_next = $self->token_lookup(@toks);
    croak "No next tokens defined for tokens " . $self->token_key(@toks)
        unless defined $tok_next;

    my @possible_toks;

    while (my ($next_tok, $count) = each %$tok_next) {
        push @possible_toks, $next_tok for 1 .. $count;
    }

    @possible_toks = shuffle @possible_toks;
    my $tok = shift @possible_toks;

    return $tok;
}

=item token_lookup

Returns a hashref of the counts of tokens that follow a sequence of tokens.

=cut

sub token_lookup {
    my ($self, @toks) = @_;

    my $tok_count = @toks;
    croak "token_lookup passed more than ngram_width tokens"
        unless $tok_count <= $self->ngram_width;

    my $tok_key = $self->token_key(@toks);

    return $self->{token_table}->{$tok_count}->{$tok_key} || undef;
}

=item token_key

Serializes a sequence of tokens for use as a key into the n-gram
table. You will not normally need to call this.

=cut

sub token_key {
    my ($self, @toks) = @_;
    return join('-', @toks);
}

=item serialize

Returns the tokens and n-gram (if one has been generated) in a string

=cut

sub serialize {
    my ($self) = @_;

    my $save = {
        ngram_width => $self->ngram_width,
        tokens      => $self->tokens,
        ngram       => $self->token_table,
    };

    return Storable::nfreeze($save);
}

=item deserialize($string)

Deserializes a string and returns an C<Algorithm::NGram> instance

=cut

sub deserialize {
    my ($class, $str) = @_;
    croak "Empty string passed to deserialize" unless $str;

    my $save = Storable::thaw($str)
        or croak "Invalid serialized data passed to deserialize";

    my $tokens = $save->{tokens} || [];
    my $ngram  = $save->{ngram};
    my $width  = $save->{ngram_width} or croak "No n-gram width saved";

    my $instance = $class->new(
                               ngram_width => $width,
                               token_table => $ngram,
                               tokens => $tokens,
                               );

    $instance->dirty(0) if $ngram;

    return $instance;
}

1;

__END__

=back

=head1 SEE ALSO

L<Text::Ngram>, L<Text::Ngrams>

=head1 AUTHOR

Mischa Spiegelmock, E<lt>mspiegelmock@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Mischa Spiegelmock

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
