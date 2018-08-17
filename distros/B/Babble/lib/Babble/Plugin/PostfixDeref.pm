package Babble::Plugin::PostfixDeref;

use Moo;

my $scalar_post = q{
  (?:
    (?>(?&PerlOWS))
    (?:
      (?:
        (?>(?&PerlOWS))      -> (?>(?&PerlOWS))
        (?&PerlParenthesesList)
      |
        (?>(?&PerlOWS))  (?: ->    (?&PerlOWS)  )?+
        (?> \$\* | (?&PerlArrayIndexer) | (?&PerlHashIndexer) )
      )
      (?:
        (?>(?&PerlOWS))  (?: ->    (?&PerlOWS)  )?+
                   (?> \$\* | (?&PerlArrayIndexer) | (?&PerlHashIndexer) | (?&PerlParenthesesList) )
      )*+
    )?+
    (?:
      (?>(?&PerlOWS)) -> (?>(?&PerlOWS))
      [\@%]
      (?> \* | (?&PerlArrayIndexer) | (?&PerlHashIndexer) )
    )?+
  )
};

sub transform_to_plain {
  my ($self, $top) = @_;
  $top->remove_use_argument(experimental => 'postderef');
  $top->remove_use_argument(feature => 'postderef');
  # TODO: cry about lvalues assignment to postfix derefs
  my $tf = sub {
    my ($m) = @_;
    my ($term, $postfix) = $m->subtexts(qw(term postfix));
    #warn "Term: $term"; warn "Postfix: $postfix";
    my $grammar = $m->grammar_regexp;
    my $strip_re = qr{
      ( (?>(?&PerlOWS)) -> (?>(?&PerlOWS))
        (?>
           (?> (?&PerlQualifiedIdentifier) | (?&PerlVariableScalar) )
           (?: (?>(?&PerlOWS)) (?&PerlParenthesesList) )?+
           | (?&PerlParenthesesList)
           | (?&PerlArrayIndexer)
           | (?&PerlHashIndexer)
           | \$\*
        )
      )
      ${grammar}
    }x;
    while ($postfix =~ s/^${strip_re}//) {
      my $stripped = $1;
      if ($stripped =~ /\$\*$/) {
        $term = '(map $$_, '.$term.')[0]';
      } else {
        $term .= $stripped;
      }
    }
    if ($postfix) {
      my ($sigil, $rest) = ($postfix =~ /^\s*->\s*([\@%])(.*)$/);
      $rest = '' if $rest eq '*';
      $term = '(map '.$sigil.'{$_}'.$rest.', '.$term.')';
    }
    $m->submatches->{term}->replace_text($term);
    $m->submatches->{postfix}->replace_text('');
  };
  $top->each_match_within(PrefixPostfixTerm => [
    '(?: (?>(?&PerlPrefixUnaryOperator))  (?&PerlOWS) )*+',
    [ term => '(?>(?&PerlTerm))' ],
    [ postfix => '(?&PerlTermPostfixDereference)' ],
    '(?: (?>(?&PerlOWS)) (?&PerlPostfixUnaryOperator) )?+'
  ] => $tf);
  $top->each_match_within(ScalarAccess => [
    [ term => '(?>(?&PerlVariableScalar))' ],
    [ postfix => $scalar_post ],
  ] => $tf);
}

1;
