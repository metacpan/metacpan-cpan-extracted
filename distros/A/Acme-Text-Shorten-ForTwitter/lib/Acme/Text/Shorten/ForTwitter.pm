package Acme::Text::Shorten::ForTwitter;
# ABSTRACT: Shorten text for use in tweets

use Moo;
use Module::Pluggable require => 1;

my (%base_rules, %default_rules);

for my $p (__PACKAGE__->plugins()) {
  die "Plugin $p does not implement modify_base_rules method!\n" unless $p->can('modify_base_rules');

  $p->modify_base_rules(\%base_rules);
}

sub import {
  my ($pkg, @args) = @_;

  %default_rules = ();

  unshift @args, 'all' unless grep { $_ =~ /(^\+|^all$)/ } @args;

  for my $arg (@args) {
    if ($arg eq 'all') {
      %default_rules = %base_rules;
    } elsif ($arg =~ s/^-//) {
      die "Unknown rule $arg\n" unless $base_rules{$arg};

      delete $default_rules{$arg};
    } elsif ($arg =~ s/^\+//) {
      die "Unknown rule $arg\n" unless $base_rules{$arg};

      $default_rules{$arg} = $base_rules{$arg};
    } else {
      die "Unknown option $arg\n";
    }
  }
}

has rules => (
  is => 'lazy',
  isa => sub {
    die "$_[0] must be a hashref\n" unless ref $_[0] && ref $_[0] eq 'HASH';
  },
  default => sub {
    return { %default_rules }
  }
);

sub add_rule {
  my ($self, $name, $rule) = @_;

  die "rule $name already exits\n" if $self->rules->{$name};

  unless ($rule) {
    die "No default rule named $name\n" unless $default_rules{$name};

    $self->rules->{$name} = $default_rules{$name};

    return;
  }

  die "rule must be a subroutine\n" unless ref $rule && ref $rule eq 'CODE';

  $self->rules->{$name} = $rule;

  return;
}

sub remove_rule {
  my ($self, $name) = @_;

  die "rule $name does not exist\n" unless $self->rules->{$name};

  delete $self->rules->{$name};

  return;
}

sub shorten {
  my $self = shift;
  my $text = shift;

  for my $rule (values %{ $self->rules }){
    $rule->(\$text);
  }

  return $text;
}

1;
__END__

=head1 NAME

Acme::Text::Shorten::ForTwitter - Shorten text for use in tweets

=head1 SYNOPSIS

  # Use all available plugins
  use Acme::Text::Shorten::ForTwitter;

  my $shortener = Acme::Text::Shorten::ForTwitter->new;

  print $shortener->shorten("I am happy to see you");
  # I'm happy to see u

  # Only load specific plugins:
  use Acme::Text::Shorten::ForTwitter qw(+texting);

  # Load all plugins except a few
  use Acme::Text::Shorten::ForTwitter qw(-texting);

  # Add a base rule
  $shortener->add_rule('texting');

  # Add a custom rule
  $shortener->add_rule('/dev/null' => sub { my $text = shift; $$text = ''; });

  # Remove a rule
  $shortener->remove_rule('contractoins');

=head1 DESCRIPTION

This module makes writing content-rich tweets easier by helping
you shorten things as much as possible while still maintaining
the original content's meaning.

Various plugins are shipped with this module by default, and you
can write your own or install more from CPAN (if any are available.)

See L</"Writing Plugins"> below for information on writing plugins.

=head2 Class Methods

=head3 new

  my $shortener = Acme::Text::Shorten::ForTwitter->new;

Creates a new shortener with all of the rules selected at
import time.

=head2 Object Methods

=head3 shorten

  print $shortener->shorten("What is going on?");

Takes text as input and transforms it to a shorter version
if possible. It achieves this by running through all enabled
rules and attempting to apply them to the input.

=head3 add_rule

  $shortener->add_rule("name");

  $shortener->add_rule("name", sub { 
    my $text = shift; $$text =~ s/hello/hi/; 
  });

In the first form, adds a named rule from one of the loaded
plugins to the list of rules to use. Will die if the named
rule cannot be found.

In the second form, adds a custom rule. The subroutine should
take a reference to a scalar, and should modify the scalar
as needed.

=head3 remove_rule

  $shortener->remove_rule("name");

Removes the named rule from the shortener. Will die if the named
rule cannot be found.

=head1 Writing Plugins

A plugin should look like this:

  package Acme::Text::Shorten::ForTwitter::Plugin::MyPlugin;

  use strict;
  use warnings;

  sub modify_base_rules {
    my $pkg = shift;
    my $base = shift;

    $base->{rule_name} = sub {
      my $text = shift;

      $$text =~ s/\bsome long thing/some short thing\b/g;
    };

    return;
  }

It will automatically be loaded when
L<Acme::Text::Shorten::ForTwitter> is loaded.

=head1 AUTHOR

Matthew Horsfall (alh) - <wolfsage@gmail.com>

=cut
