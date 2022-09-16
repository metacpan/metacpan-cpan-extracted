package Babble::Plugin::PostfixDeref;

use Moo;

my $term_derefable = q{
            # Copied from <PerlTerm> rule in PPR::X@0.001002
            # The remaining alternatives can all take postfix dereferencers...
            # ...
              (?:
                    (?= \$ )  (?&PerlScalarAccess)
              |
                    (?= \@ )  (?&PerlArrayAccess)
              |
                    (?=  % )  (?&PerlHashAccess)
              |
                    (?&PerlAnonymousSubroutine)
              |
                    (?>(?&PerlNullaryBuiltinFunction))  (?! (?>(?&PerlOWS)) \( )
              |
                    (?&PerlDoBlock) | (?&PerlEvalBlock)
              |
                    (?&PerlCall)
              |
                    (?&PerlVariableDeclaration)
              |
                    (?&PerlTypeglob)
              |
                    (?>(?&PerlParenthesesList))

                    # Can optionally do a [...] lookup straight after the parens,
                    # followd by any number of other look-ups
                    (?:
                        (?>(?&PerlOWS)) (?&PerlArrayIndexer)
                        (?:
                            (?>(?&PerlOWS))
                            (?>
                                (?&PerlArrayIndexer)
                            |   (?&PerlHashIndexer)
                            |   (?&PerlParenthesesList)
                            )
                        )*+
                    )?+
              |
                    (?&PerlAnonymousArray)
              |
                    (?&PerlAnonymousHash)
              |
                    (?&PerlDiamondOperator)
              |
                    (?&PerlContextualMatch)
              |
                    (?&PerlQuotelikeS)
              |
                    (?&PerlQuotelikeTR)
              |
                    (?&PerlQuotelikeQX)
              |
                    (?&PerlLiteral)
              )
};

my $scalarnospace_post = q{
            # Copied from <PerlScalarAccessNoSpace> rule in PPR::X@0.001002
            # Then any nuber of arrowed accesses
            # (this is an inlined subset of (?&PerlTermPostfixDereference))...
            (?:
                ->
                (?>
                    # A series of simple brackets can omit interstitial arrows...
                    (?:  (?&PerlArrayIndexer)
                    |    (?&PerlHashIndexer)
                    )++

                |   # An array or hash slice...
                    \@ (?> (?>(?&PerlArrayIndexer)) | (?>(?&PerlHashIndexer)) )
                )
            )*+

            # Followed by at most one of these terminal arrowed dereferences...
            (?:
                ->
                (?>
                    # An array or scalar deref...
                    [\@\$] \*

                |   # An array count deref...
                    \$ \# \*
                )
            )?+
};

sub transform_to_plain {
  my ($self, $top) = @_;
  for my $argument (qw(postderef postderef_qq)) {
    $top->remove_use_argument(experimental => $argument);
    $top->remove_use_argument(feature => $argument);
  }
  my $tf = sub {
    my ($m, $in_quotelike) = @_;
    my $interpolate = defined $in_quotelike && $in_quotelike;
    my ($term, $postfix) = $m->subtexts(qw(term postfix));
    #warn "Term: $term"; warn "Postfix: $postfix";
    my $grammar = $m->grammar_regexp;
    my $strip_re = qr{
      ( (?>(?&PerlOWS)) -> (?>(?&PerlOWS))
        (?>
             \$\#\*
           | \$\*
           | (?> (?&PerlQualifiedIdentifier) | (?&PerlVariableScalar) )
           (?: (?>(?&PerlOWS)) (?&PerlParenthesesList) )?+
           | (?:
                 (?>(?&PerlOWS))
                 (?> (?&PerlParenthesesList) | (?&PerlArrayIndexer) | (?&PerlHashIndexer) )
             )++
        )
      )
      ${grammar}
    }x;
    while ($postfix =~ s/^${strip_re}//) {
      my $stripped = $1;
      if ($stripped =~ /(\$\#?)\*$/) {
        my $sigil = $1;
        $term = $sigil.'{'.$term.'}';
        if( $interpolate ) {
          $term = "\@{[ $term ]}";
        }
      } else {
        $term .= $stripped;
      }
    }
    if ($postfix) {
      my ($sigil, $rest) = ($postfix =~ /^\s*->\s*([\@%])(.*)$/);
      $rest = '' if $rest eq '*';
      $term = $sigil.'{'.$term.'}'.$rest;
      if( $interpolate ) {
        # NOTE This can be interpolated safely
        # because:
        #   1. The delimiters are balanced so use inside of
        #      `qq{ ... }` or `qq[ ... ]` is safe.
        #   2. The contents of $term can only contain expressions that
        #      have `$` and `@` sigils, so any expression contained in
        #      $term which is used within `qq@ ... @` will not have the
        #      `@` sigil (same with the `qq$ ... $` and `$` sigil).
        $term = "\@{[ $term ]}";
      }
    }
    $m->submatches->{term}->replace_text($term);
    $m->submatches->{postfix}->replace_text('');
  };
  $top->each_match_within(Term => [
    [ term => "(?> $term_derefable )" ],
    [ postfix => '(?&PerlTermPostfixDereference)' ],
  ] => $tf);

  # NOTE ScalarAccessNoSpace is used within the
  # ScalarAccessNoSpaceNoArrow rule, but any such
  # matches here via that rule would be invalid input
  # to begin with.
  $top->each_match_within(ScalarAccessNoSpace => [
    [ term => q{
            (?>(?&PerlVariableScalarNoSpace))

            # Optional arrowless access(es) to begin...
            (?: (?&PerlArrayIndexer) | (?&PerlHashIndexer) )*+
      } ],
    [ postfix => $scalarnospace_post ],
  ] => sub { $tf->(shift, 1) });
  # NOTE ArrayAccessNoSpace also needs to implemented.
}

1;
__END__

=head1 NAME

Babble::Plugin::PostfixDeref - Plugin for postfix dereferencing

=head1 SYNOPSIS

Converts usage of the postderef syntax from

    $foo->@*

to

    @{$foo}

=head1 SEE ALSO

L<postderef feature|feature/"The 'postderef' and 'postderef_qq' features">

=cut
