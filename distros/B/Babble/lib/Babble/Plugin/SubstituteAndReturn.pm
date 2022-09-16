package Babble::Plugin::SubstituteAndReturn;

use Moo;

my $s_FLAGS_RE = qr/([msixpodualgcern]*+)$/;
my $y_FLAGS_RE = qr/([cdsr]*+)$/;

sub _get_flags {
  my ($text) = @_;
  $text =~ /^s/ ? $s_FLAGS_RE : $y_FLAGS_RE;
}

sub _transform_binary {
  my ($self, $top) = @_;
  my $replaced;
  do {
    $replaced = 0;
    $top->each_match_within(BinaryExpression => [
       [ 'left' => '(?>(?&PerlPrefixPostfixTerm))' ],
       '(?>(?&PerlOWS)) =~ (?>(?&PerlOWS))',
       [ 'right' => '(?>
                        (?&PerlSubstitution)
                      | (?&PerlTransliteration)
                     )' ],
    ] => sub {
      my ($m) = @_;
      my ($left, $right);
      eval {
        ($left, $right) = $m->subtexts(qw(left right));
        1
      } or return;
      my ($flags) = $right =~ _get_flags($right);
      return unless (my $newflags = $flags) =~ s/r//g;

      # find chained substitutions
      #   ... =~ s///r =~ s///r =~ s///r
      my $top_text = $top->text;
      pos( $top_text ) = $m->start + length $m->text;
      my $chained_subs_length = 0;
      my @chained_subs;
      while( $top_text =~ /
        \G
          (
            (?>(?&PerlOWS)) =~ (?>(?&PerlOWS))
            ((?>
                (?&PerlSubstitution)
              | (?&PerlTransliteration)
            ))
          )
          @{[ $m->grammar_regexp ]}
        /xg ) {
        $chained_subs_length += length $1;
        push @chained_subs, $2;
      }
      for my $subst_c (@chained_subs) {
        my ($f_c) = $subst_c =~ _get_flags($subst_c);
        die "Chained substitution must use the /r modifier"
          unless (my $nf_c = $f_c) =~ s/r//g;
        $subst_c =~ s/\Q${f_c}\E$/${nf_c}/;
      }

      $right =~ s/\Q${flags}\E$/${newflags}/;
      $left =~ s/\s+$//;
      my $genlex = '$'.$m->gensym;

      if( @chained_subs ) {
        my $chained_for = 'for ('.$genlex.') { '
          . join("; ", @chained_subs)
          . ' }';
        $top->replace_substring(
          $m->start,
          length($m->text) + $chained_subs_length,
          '(map { (my '.$genlex.' = $_) =~ '.$right.'; '.$chained_for.' '.$genlex.' }'
          .' '.$left.')[0]'
        );
      } else {
        $m->replace_text(
          '(map { (my '.$genlex.' = $_) =~ '.$right.'; '.$genlex.' }'
          .' '.$left.')[0]'
        );
      }

      $replaced++;
    });
  } while( $replaced );
}

sub _transform_contextualise {
  my ($self, $top) = @_;

  my $contextual_subst = 0;
  do {
    my %subst_pos;
    # Look for substitution without binding operator:
    # First look for an expression that begins with Substitution.
    $top->each_match_within(Expression => [
      [ subst => '(?>
                      (?&PerlSubstitution)
                    | (?&PerlTransliteration)
                  )' ],
    ] => sub {
      my ($m) = @_;
      my ($subst) = @{$m->submatches}{qw(subst)};
      my ($flags) = $subst->text =~ _get_flags($subst->text);
      return unless $flags =~ /r/;
      $subst_pos{$m->start} = 1;
    });
    # Then remove Substitution within a BinaryExpression
    $top->each_match_within(BinaryExpression => [
       [ 'left' => '(?>(?&PerlPrefixPostfixTerm))' ],
       '(?>(?&PerlOWS)) =~ (?>(?&PerlOWS))',
       [ 'right' => '(?>
                         (?&PerlSubstitution)
                       | (?&PerlTransliteration)
                     )' ],
    ] => sub {
      my ($m) = @_;
      delete $subst_pos{ $m->start + $m->submatches->{right}->start };
    });

    # Insert context variable and binding operator
    my @subst_pos = sort keys %subst_pos;
    $contextual_subst = @subst_pos;
    my $diff = 0;
    my $replace = '$_ =~ ';
    while( my $pos = shift @subst_pos ) {
      $top->replace_substring($pos + $diff, 0, $replace);
      $diff += length $replace;
    }
  } while( $contextual_subst);
}

sub transform_to_plain {
  my ($self, $top) = @_;

  $self->_transform_contextualise($top);

  $self->_transform_binary($top);
}

1;
__END__

=head1 NAME

Babble::Plugin::SubstituteAndReturn - Plugin for /r flag for substitution and transliteration

=head1 SYNOPSIS

Converts usage of the C<s///r> and C<tr///r> syntax to substitution and
transliteration without the C</r> flag.

=head1 SEE ALSO

L<E<sol>r flag|Syntax::Construct/"/r">

=cut
