package Babble::Plugin::DefinedOr;

use Moo;

sub transform_to_plain {
  my ($self, $top) = @_;
  $top->each_match_within(Statement => [
    [ before => '(?>(?&PerlPrefixPostfixTerm))' ],
    [ op => '(?>(?&PerlOWS) //=)' ], '(?>(?&PerlOWS))',
    [ after => '(?>(?&PerlPrefixPostfixTerm))' ],
    '(?>(?&PerlOWS))',
    [ trail => '
        (?&PerlStatementModifier)?+
        (?>(?&PerlOWS))
        (?> ; | (?= \} | \z ))
      ' ],
  ] => sub {
    my ($m) = @_;
    my ($before, $after, $trail) = $m->subtexts(qw(before after trail));
    s/^\s+//, s/\s+$// for ($before, $after);
    my $assign = 'defined($_) or $_ = '.$after.' for '.$before;
    if (length($trail) > 1) {
      $assign = 'do { '.$assign.' } '
    }
    $m->replace_text($assign.$trail);
  });
  my $tf = sub {
    my ($m) = @_;
    my ($before, $after) = $m->subtexts(qw(before after));
    s/^\s+//, s/\s+$// for ($before, $after);
    if ($m->submatches->{op}->text =~ /=$/) {
      $after = '$_ = '.$after;
    }
    $m->replace_text('(map +(defined($_) ? $_ : '.$after.'), '.$before.')[0]');
  };
  $top->each_match_within(BinaryExpression => [
    [ before => '(?>(?&PerlPrefixPostfixTerm))' ],
    [ op => '(?>(?&PerlOWS) //)' ], '(?>(?&PerlOWS))',
    [ after => '(?>(?&PerlPrefixPostfixTerm))' ],
  ] => $tf);
  $top->each_match_within(Assignment => [
    [ before => '(?>(?&PerlPrefixPostfixTerm))' ],
    [ op => '(?>(?&PerlOWS) //=)' ], '(?>(?&PerlOWS))',
    [ after => '(?>(?&PerlPrefixPostfixTerm))' ],
  ] => $tf);
}

1;
