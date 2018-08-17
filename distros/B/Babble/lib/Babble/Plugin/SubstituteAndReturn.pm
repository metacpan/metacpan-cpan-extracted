package Babble::Plugin::SubstituteAndReturn;

use Moo;

sub transform_to_plain {
  my ($self, $top) = @_;
  $top->each_match_within(BinaryExpression => [
     [ 'left' => '(?>(?&PerlPrefixPostfixTerm))' ],
     '(?>(?&PerlOWS)) =~ (?>(?&PerlOWS))',
     [ 'right' => '(?>(?&PerlSubstitution))' ],
  ] => sub {
    my ($m) = @_;
    my ($left, $right) = $m->subtexts(qw(left right));
    my ($flags) = $right =~ /([msixpodualgcern]*+)$/;
    return unless (my $newflags = $flags) =~ s/r//g;
    $right =~ s/\Q${flags}\E$/${newflags}/;
    $left =~ s/\s+$//;
    my $genlex = '$'.$m->gensym;
    $m->replace_text(
      '(map { (my '.$genlex.' = $_) =~ '.$right.'; '.$genlex.' }'
      .' '.$left.')[0]'
    );
  });
}

1;
