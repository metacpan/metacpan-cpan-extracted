package Babble::Plugin::SubstituteAndReturn;

use Moo;

our ($REGMARK, $REGERROR);

my %OP_TYPE_DATA = (
  s => {
    rule  => 'QuotelikeS',
    flags => qr/([msixpodualgcern]*+)$/,
  },
  y => {
    rule  => 'QuotelikeTR',
    flags => qr/([cdsr]*+)$/,
  },
);

my $OP_TYPE_RE = qr{
  \A
  (?:
          s       (*MARK:s)
    | (?: y|tr )  (*MARK:y)
  )
}x;

sub _get_flags {
  my ($text) = @_;

  if ( $text =~ $OP_TYPE_RE ) {
    return $OP_TYPE_DATA{$REGMARK}{flags};
  }

  return '';
}

sub _transform_binary {
  my ($self, $top) = @_;

  my $chained_re = qr{
    \G
      (
        (?>(?&PerlOWS)) =~ (?>(?&PerlOWS))
        ((?>
            (?&PerlSubstitution)
          | (?&PerlTransliteration)
        ))
      )
      @{[ $top->grammar_regexp ]}
  }x;

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
      while( $top_text =~ /$chained_re/g ) {
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

  do {
    my @subst_pos; # sorted positions
    # Look for substitution without binding operator:
    # First look for an expression that begins with Substitution.
    $top->each_match_of( Expression => sub {
      my ($m) = @_;
      my $expr_text = $m->text;
      my @start_pos = do {
        if( $expr_text =~ $OP_TYPE_RE ) {
          my $rule = $OP_TYPE_DATA{$REGMARK}{rule};
          my @pos = $m->match_positions_of($rule);
          return unless @pos && $pos[0][0] == 0;
          @{ $pos[0] };
        } else {
          return;
        }
      };
      my $text = substr($expr_text, $start_pos[0], $start_pos[1]);
      my ($flags) = $text =~ _get_flags($text);
      return unless $flags =~ /r/;
      push @subst_pos, $m->start;
    });

    # Insert context variable and binding operator
    my $diff = 0;
    my $replace = '$_ =~ ';
    while( my $pos = shift @subst_pos ) {
      $top->replace_substring($pos + $diff, 0, $replace);
      $diff += length $replace;
    }
  };
}

sub transform_to_plain {
  my ($self, $top) = @_;

  $self->_transform_contextualise($top);

  $self->_transform_binary($top);
}

sub check_bail_out_early {
  my ($self, $top) = @_;
  $top->text !~ m/ \b (?: s|y|tr ) \b /xs;
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
