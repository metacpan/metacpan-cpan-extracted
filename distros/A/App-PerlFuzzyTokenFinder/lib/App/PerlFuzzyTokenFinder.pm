package App::PerlFuzzyTokenFinder;
use 5.008001;
use strict;
use warnings;

use PPI;

our $VERSION = "0.02";

sub tokenize {
    my ($class, $expr) = @_;

    my $tokenizer = PPI::Tokenizer->new(\$expr);
    my $exclude_whitespace = [ grep { ! $_->isa('PPI::Token::Whitespace') } @{$tokenizer->all_tokens} ];

    return $exclude_whitespace;
}

# target_tokens: ArrayRef[PPI::Token]
# find_tokens: ArrayRef[PPI::Token]
sub matches {
    my ($class, $target_tokens, $find_tokens) = @_;

    for my $start (@$target_tokens) {
        return 1 if $class->_try_match($start, $find_tokens);
    }

    return 0;
}

sub _try_match {
    my ($class, $target_token, $find_tokens) = @_;

    my $idx = 0;
    while (1) {
        last unless defined $target_token;

        my $find = $find_tokens->[$idx];

        return 1 unless defined $find;

        if ($find->content eq '...') {
            return 0 if $target_token->content eq ';';

            # asterisk
            my $find_next = $find_tokens->[$idx + 1];
            return 1 unless defined $find_next;

            if ($class->_snext_token($target_token) && $class->_snext_token($target_token)->content eq $find_next->content) {
                $target_token = $class->_snext_token($target_token);
                $idx++;
            } else {
                $target_token = $class->_snext_token($target_token);
            }
        } else {
            if ($target_token->content eq $find->content) {
                $target_token = $class->_snext_token($target_token);
                $idx++;
            } else {
                return 0;
            }
        }
    }

    return 0;
}

# point $token to next significant token
sub _snext_token {
    my ($class, $token) = @_;

    do {
        $token = $token->next_token;
        return undef unless $token;
    } while ($token && $token->isa('PPI::Token::Whitespace'));

    return $token;
}


1;
__END__

=encoding utf-8

=head1 NAME

App::PerlFuzzyTokenFinder - Fuzzy finder for Perl statements

=head1 SYNOPSIS

    use App::PerlFuzzyTokenFinder;

=head1 DESCRIPTION

App::PerlFuzzyTokenFinder is a fuzzy finder for Perl statements.

=head1 SEE ALSO

L<perl-fuzzy-token-finder> for command-line usage.

=head1 LICENSE

Copyright (C) utgwkk.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

utgwkk E<lt>utagawakiki@gmail.comE<gt>

=cut

