package Babble::Plugin::SKT;

use Moo;

sub extend_grammar {
  my ($self, $g) = @_;
  $g->add_rule(TryCatch =>
    'try(?&PerlOWS)(?&PerlBlock)'
    .'(?:(?&PerlOWS)catch(?&PerlOWS)(?&PerlBlock))?+'
  );
  $g->augment_rule(Statement => '(?&PerlTryCatch)');
}

sub transform_to_plain {
  my ($self, $top) = @_;
  $top->remove_use_statement('Syntax::Keyword::Try');
  $top->each_match_within(TryCatch => [
    'try(?&PerlOWS)', [ try_block => '(?&PerlBlock)' ],
    '(?:(?&PerlOWS)catch(?&PerlOWS)', [ catch_block => '(?&PerlBlock)' ], ')?+'
  ] => sub {
    my ($m) = @_;
    my ($try, $catch) = $m->subtexts(qw(try_block catch_block));
    my $text = do {
      if ($catch) {
        $try =~ s/\s*}$/; 1 }/;
        'unless (eval '.$try.') '.$catch;
      } else {
        'eval '.$try;
      }
    };
    $m->replace_text('{ local $@; '.$text.' }');
  });
}

1;
__END__

=head1 NAME

Babble::Plugin::SKT - Plugin to convert Syntax::Keyword::Try to eval

=head1 SEE ALSO

L<Syntax::Keyword::Try>

=cut
