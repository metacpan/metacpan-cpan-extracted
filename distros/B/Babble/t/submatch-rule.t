use strictures 2;
use Test::More;
use Babble::Match;

{
package # hide from PAUSE
  ClassKeyword;

use Moo;
use B ();

sub extend_grammar {
  my ($self, $g) = @_;
  $g->add_rule(ClassExtends => q{
    extends (?&PerlOWS) (?&PerlQualifiedIdentifier)
  });
  $g->add_rule(RolesList => q{
    (?&PerlQualifiedIdentifier)
    (?: (?&PerlOWS) , (?&PerlOWS) (?&PerlQualifiedIdentifier) )*?
  });
  $g->add_rule(ClassRoles => q{
    with (?&PerlOWS) (?&PerlRolesList)
  });
  $g->add_rule(ClassDef => q{
    class (?&PerlOWS) (?&PerlQualifiedIdentifier)
    (?: (?&PerlOWS) (?&PerlClassExtends) )?
    (?: (?&PerlOWS) (?&PerlClassRoles) )?
    (?&PerlOWS)
    (?&PerlBlock)
  });
  $g->augment_rule(Keyword => '(?&PerlClassDef)');
}

sub transform_to_plain {
  my ($self, $top) = @_;
  $top->each_match_within(Keyword => [
    [ kw => 'class(?&PerlOWS)'],
    [ name =>  '(?&PerlQualifiedIdentifier)'],
    [ extends => '(?: (?&PerlOWS) (?&PerlClassExtends) )?' ],
    [ roles   => '(?: (?&PerlOWS) (?&PerlClassRoles) )?'   ],
    [ space => '(?&PerlOWS)' ],
    [ block => '(?&PerlBlock)' ],
  ] => sub {
    my ($m) = @_;
    my $gr = $m->grammar_regexp;
    my ($kw, $name, $extends, $roles, $space, $block)
      = @{$m->submatches}{qw(kw name extends roles space block)};

    my $extends_text = $extends->text;
    $extends_text =~ s/\A (?&PerlOWS) extends (?&PerlOWS) $gr//mx;

    my $roles_text = $roles->text;
    $roles_text =~ s/\A (?&PerlOWS) with (?&PerlOWS) $gr//mx;
    my @roles = grep defined, split /(?:(?&PerlOWS)) , (?: (?&PerlOWS)) $gr/mx, $roles_text;

    my $block_text = $block->text;
    my $prefix = "package @{[ $name->text ]}; use Moo;";

    $prefix .= " extends ".B::perlstring($extends_text). ";" if $extends_text;
    $prefix .= " with ".join(", ", map B::perlstring($_), @roles). ";" if @roles;

    $block_text =~ s/\{/{ $prefix/;
    $_->replace_text('') for $kw, $name, $extends, $roles, $space;

    $block->replace_text($block_text);
  });
}
}

my @cand = (
  [ 'class Foo::Bar { 42 }',
    q|{ package Foo::Bar; use Moo; 42 }|, ],
  [ 'class Baz extends Foo::Bar { 42 }',
    q|{ package Baz; use Moo; extends "Foo::Bar"; 42 }|, ],
  [ 'class Baz extends Foo with Foo::Role::Trackable { 42 }',
    q|{ package Baz; use Moo; extends "Foo"; with "Foo::Role::Trackable"; 42 }|, ],
  [ 'class Baz extends Foo with Trackable, Aliasable { 42 }',
    q|{ package Baz; use Moo; extends "Foo"; with "Trackable", "Aliasable"; 42 }|, ],
);

my $ck = ClassKeyword->new;

my $g = Babble::Grammar->new;

$ck->extend_grammar($g);

foreach my $cand (@cand) {
  my ($from, $to) = @$cand;
  my $top = $g->match('Document' => $from);
  $ck->transform_to_plain($top);
  is($top->text, $to, "${from}");
}

done_testing;
