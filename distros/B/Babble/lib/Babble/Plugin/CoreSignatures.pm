package Babble::Plugin::CoreSignatures;

use strictures 2;
use Moo;

sub extend_grammar { } # PPR::X can already parse everything we need

# .......bbbbbSSSSSSSa
# sub foo :Bar ($baz) {

# .......bSSSSSSSaaaaa
# sub foo ($baz) :Bar {

sub transform_to_signatures {
  my ($self, $top) = @_;
  my $tf = sub {
    my $s = (my $m = shift)->submatches;
    if ((my $after = $s->{after}->text) =~ /\S/) {
      $s->{after}->replace_text('');
      $s->{before}->replace_text($s->{before}->text.$after);
    }
  };
  $self->_transform_signatures($top, $tf);
}

sub transform_to_oldsignatures {
  my ($self, $top) = @_;
  my $tf = sub {
    my $s = (my $m = shift)->submatches;
    if ((my $before = $s->{before}->text) =~ /\S/) {
      $s->{before}->replace_text('');
      $s->{after}->replace_text($before.$s->{after}->text);
    }
  };
  $self->_transform_signatures($top, $tf);
}

sub transform_to_plain {
  my ($self, $top) = @_;
  $top->remove_use_argument(experimental => 'signatures');
  $top->remove_use_argument('Mojo::Base' => '-signatures', 1);
  my $tf = sub {
    my $s = (my $m = shift)->submatches;

    # shift attributes after first before we go hunting for :prototype
    if ((my $before = $s->{before}->text) =~ /\S/) {
      $s->{before}->replace_text('');
      $s->{after}->replace_text($before.$s->{after}->text);
    }

    my $proto = '';
    {
      my $try = $s->{after};
      local $try->{top_rule} = 'Attributes';
      my $grammar = $m->grammar->clone;
      $grammar->add_rule(Attribute =>
        '(?&PerlOWS) :? (?&PerlOWS)
         (?&PerlIdentifier)
         (?: (?= \( ) (?&PPR_X_quotelike_body) )?+'
      )->replace_rule(Attributes =>
        '(?=(?&PerlOWS):)(?&PerlAttribute)
         (?&PerlAttribute)*'
      );
      local $try->{grammar} = $grammar;
      my $each; $each = sub {
        my ($attr) = @_;
        if ($attr->text =~ /prototype(\(.*?\))/) {
          $proto = $1;
          $attr->replace_text('');
          $each = sub {
            my ($attr) = @_;
            $attr->transform_text(sub { s/^(\s*)/${1}:/ }) unless $attr->text =~ /^\s*:/;
            $each = sub {};
          };
        }
      };
      $try->each_match_of(Attribute => sub { $each->(@_) });
      undef($each);
    }

    s/\A\s*\(//, s/\)\s*\Z// for my $sig_orig = $s->{sig}->text;
    my $grammar_re = $m->grammar_regexp;
    my @sig_parts = grep defined($_),
                      $sig_orig =~ /((?&PerlAssignment)) ${grammar_re}/xg;

    my (@sig_text, @defaults);

    foreach my $idx (0..$#sig_parts) {
      my $part = $sig_parts[$idx];
      if ($part =~ s/^(\S+?)\s*=\s*(.*?)(,$|$)/$1$3/) {
        push @defaults, "$1 = $2 if \@_ <= $idx;";
      }
      push @sig_text, $part;
    }

    my $sig_text =
      @sig_text
      ? 'my ('.(join ', ', @sig_text).') = @_;'
      : '';
    my $code = join ' ', $sig_text, @defaults;
    $s->{body}->transform_text(sub { s/^{/{ ${code}/ });
    if ($proto) {
      $s->{sig}->transform_text(sub {
        s/\A(\s*)\(.*\)(\s*)\Z/${1}${proto}${2}/;
      });
    } else {
      $s->{sig}->replace_text('');
    }
  };
  $self->_transform_signatures($top, $tf);
}

sub _transform_signatures {
  my ($self, $top, $tf) = @_;
  my @common = (
    '(?:', # 5.20, 5.28+
      [ before => '(?: (?&PerlOWS) (?>(?&PerlAttributes)) )?+' ],
      [ sig => '(?&PerlOWS) (?&PerlParenthesesList)' ], # not optional for us
      [ after => '(?&PerlOWS)' ],
    '|', # 5.22 - 5.26
      [ before => '(?&PerlOWS)' ],
      [ sig => '(?&PerlParenthesesList) (?&PerlOWS)' ], # not optional for us
      [ after => '(?: (?>(?&PerlAttributes)) (?&PerlOWS) )?+' ],
    ')',
    [ body => '(?&PerlBlock)' ],
  );
  $top->each_match_within('SubroutineDeclaration' => [
    'sub \b (?&PerlOWS) (?&PerlOldQualifiedIdentifier)',
    @common,
  ], $tf);
  $top->each_match_within('AnonymousSubroutine' => [
    'sub \b',
    @common,
  ], $tf);
}

1;
__END__

=head1 NAME

Babble::Plugin::CoreSignatures - Plugin for signatures feature

=head1 SYNOPSIS

Supports converting from signatures syntax to plain C<@_> unpacking, for
example from

    sub foo :prototype($) ($sig) { }

to

    sub foo ($) { my ($sig) = @_; }

=head1 SEE ALSO

L<signatures feature|feature/"The 'signatures' feature">

=cut
