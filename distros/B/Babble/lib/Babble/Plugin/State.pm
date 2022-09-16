package Babble::Plugin::State;

use Moo;

sub transform_to_plain {
  my ($self, $top) = @_;
  $top->remove_use_argument(feature => 'state');
  my $make_tf = sub { my ($lead) = @_; sub {
    my ($m) = @_;
    my @states;
    my @gensym;
    $m->each_match_within(Assignment => [
      'state \b (?>(?&PerlOWS))',
      [ type => '(?: (?&PerlQualifiedIdentifier) (?&PerlOWS) )?+' ],
      [ declares => '(?>(?&PerlLvalue))' ],
      '(?>(?&PerlOWS))',
      [ attributes => '(?&PerlAttributes)?+' ],
      '(?: (?>(?&PerlOWS)) = (?>(?&PerlOWS))',
        [ assigns => '(?&PerlConditionalExpression)' ],
      ')*+',
    ] => sub {
      my ($m) = @_;
      my $st = $m->subtexts;
      push @states, $st;
      if (my $assigns = $st->{assigns}) {
        my $genlex = '$'.$m->gensym;
        my $text = '('
          .$genlex
          .' ? '.$st->{declares}
          .' : ++'.$genlex.' and '.$st->{declares}.' = '.$assigns
          .')';
        push @gensym, $genlex;
        $m->replace_text($text);
        return;
      }
      $m->replace_text('do { no warnings qw(void); '.$st->{declares}.' }');
    });
    if (@states) {
      my $state_statements = join ' ',
         (@gensym ? 'my ('.join(', ', @gensym).');' : ()),
         (map {
           'my '.$_->{type}.$_->{declares}
           .($_->{attributes} ? ' '.$_->{attributes} : '')
           .';'
         } @states);
      $m->transform_text(sub {
        s/\A/${lead}{ ${state_statements} /;
        s/\Z/ }/;
      });
    }
  } };
  $top->each_match_of(AnonymousSubroutine => $make_tf->('do '));
  $top->each_match_of(SubroutineDeclaration => $make_tf->(''));
}

1;
__END__

=head1 NAME

Babble::Plugin::State - Plugin for state keyword

=head1 SYNOPSIS

Converts usage of C<state> variable to C<my>.

=head1 SEE ALSO

L<state feature|feature/"The 'state' feature">

=cut
