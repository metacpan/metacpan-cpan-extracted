package Babble::Match;

use Babble::Grammar;
use Babble::SymbolGenerator;
use Mu;
use List::Util 1.45;

ro 'top_rule';
rwp 'text';

lazy 'grammar' => sub {
  $_[0]->can('parent')
    ? $_[0]->parent->grammar
    : Babble::Grammar->new
  } => handles => [ 'grammar_regexp' ];

lazy 'symbol_generator' => sub {
  $_[0]->can('parent')
    ? $_[0]->parent->symbol_generator
    : Babble::SymbolGenerator->new
  } => handles => [ 'gensym' ];

lazy top_re => sub {
  my ($self) = @_;
  my $top = $self->_rule_to_re($self->top_rule);
  return "\\A${top}\\Z";
};

my %SUBMATCHES_COMPILE_CACHE;
lazy submatches => sub {
  my ($self) = @_;
  return {} unless ref(my $top = $self->top_rule);
  my @subrules;
  my $re = join '', map {
    ref($_)
      ? do {
          push @subrules, $_;
          my ($name, $rule) = @$_;
          "(${rule})"
        }
      : $_
  } @$top;
  return {} unless @subrules;
  my $submatch_re = qq[ \\A${re}\\Z ${\$self->grammar_regexp} ];
  my $_re;
  my @values = $self->text =~ (
    Babble::Config::CACHE_RE ? $SUBMATCHES_COMPILE_CACHE{$submatch_re} : $_re ||=
    do {
      warn "Cache miss submatches\n" if Babble::Config::CACHE_RE && Babble::Config::DEBUG_CACHE_MISS;
      use re 'eval';
      my $re = qr/$submatch_re/x;
      no re 'eval';
      $re;
    });
  die "Match failed" unless @values;
  my %submatches;
  require Babble::SubMatch;
  foreach my $idx (0 .. $#subrules) {
    # there may be more than one capture with the same name if there's an
    # alternation in the rule, or one may be optional, so we skip if that
    # part of the pattern failed to capture
    next unless defined $values[$idx];
    my ($name, $rule) = @{$subrules[$idx]};
    $submatches{$name} = Babble::SubMatch->new(
      top_rule => [ $rule ],
      start => $-[$idx+1],
      text => $values[$idx],
      parent => $self,
    );
  }
  return \%submatches;
};

sub subtexts {
  my ($self, @names) = @_;
  unless (@names) {
    my %s = %{$self->submatches};
    return +{ map +( $_ => $s{$_}->text ), keys %s };
  }
  map +($_ ? $_->text : undef), @{$self->submatches}{@names};
}

sub _rule_to_re {
  my $re = $_[1];
  return "(?&Perl${re})" unless ref($re);
  return join '', map +(ref($_) ? $_->[1] : $_), @$re;
}

sub is_valid {
  my ($self) = @_;
  return !!$self->text =~ /${\$self->top_re} ${\$self->grammar_regexp}/x;
}

my %MATCH_POS_COMPILE_CACHE;
sub match_positions_of {
  my ($self, $of) = @_;
  our @F;
  my $wrapped = $self->grammar->clone->extend_rule(
                  $of => sub { '('.$_[0].')'.'(?{ push @Babble::Match::F, [ pos() - length($^N), length($^N) ] })' }
                )->grammar_regexp;
  my @found = do {
    local @F;
    local $_ = $self->text;
    my $mp_re = qq/${\$self->top_re} ${wrapped}/;
    my $_re;
    $_ =~ ( Babble::Config::CACHE_RE ? $MATCH_POS_COMPILE_CACHE{$mp_re} : $_re ||=
      do {
        warn "Cache miss match_positions_of(): @{[ $self->top_re ]}\n" if Babble::Config::CACHE_RE && Babble::Config::DEBUG_CACHE_MISS;
        use re 'eval';
        my $re = qr/$mp_re/x;
        no re 'eval';
        $re;
      }
    );
    @F;
  };
  return map { [ split ',', $_ ] }
          List::Util::uniqstr
          map { join ",", @$_ } @found;
}

sub each_match_of {
  my ($self, $of, $call) = @_;
  my @found = $self->match_positions_of($of);
  return unless @found;
  require Babble::SubMatch;
  while (my $f = shift @found) {
    my $match = substr($self->text, $f->[0], $f->[1]);
    my $obj = Babble::SubMatch->new(
                top_rule => $of,
                start => $f->[0],
                text => $match,
                parent => $self,
              );
    $call->($obj);
    if (my $len_diff = length($obj->text) - $f->[1]) {
      foreach my $later (@found) {
        if ($later->[0] <= $f->[0]) {
          $later->[1] += $len_diff;
        } else {
          $later->[0] += $len_diff;
        }
      }
    }
  }
  return $self;
}

sub each_match_within {
  my ($self, $within, $rule, $call) = @_;
  my $match_re = $self->_rule_to_re($rule);
  my $extend_grammar = $self->grammar->clone;
  $extend_grammar->add_rule(
    BabbleInnerMatch => $match_re,
  )->augment_rule($within => '(?&PerlBabbleInnerMatch)');
  local $self->{grammar} = $extend_grammar;
  $self->each_match_of(BabbleInnerMatch => sub {
    $_[0]->{top_rule} = $rule; # intentionally hacky, should go away (or rwp) later
    $call->($_[0]);
  });
  return $self;
}

sub replace_substring {
  my ($self, $start, $length, $replace) = @_;
  my $text = $self->text;
  substr($text, $start, $length, $replace);
  $self->_set_text($text);
  foreach my $submatch (values %{$self->submatches}) {
    next unless defined $submatch;
    if ($submatch->start > $start) {
      $submatch->{start} += length($replace) - $length;
    }
  }
  return $self;
}

sub remove_use_argument {
  my ($self, $use, $argument, $keep_empty) = @_;
  $self->each_match_within(
    UseStatement =>
    [ "use\\s+${use}\\s+", [ explist => '.*?' ], ';' ],
    sub {
      my ($m) = @_;
      my $explist = $m->submatches->{explist};
      return unless my @explist_names = eval $explist->text;
      my @remain = grep $_ ne $argument, @explist_names;
      return unless @remain < @explist_names;
      unless (@remain) {
        ($keep_empty ? $explist : $m)->replace_text('');
        return;
      }
      $explist->replace_text('qw('.join(' ', @remain).')');
    }
  );
}

sub remove_use_statement {
  my ($self, $use) = @_;
  $self->each_match_within(
    UseStatement =>
    [ "use\\s+${use}.*?;" ],
    sub { shift->replace_text('') },
  );
}

1;
