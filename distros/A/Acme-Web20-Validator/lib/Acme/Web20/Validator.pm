#$Id: Validator.pm,v 1.1 2005/11/14 03:39:09 naoya Exp $
package Acme::Web20::Validator;
use strict;
use warnings;
use base qw(Class::Accessor);
use Carp;
use LWP::UserAgent;
use Text::ASCIITable;
use Acme::Web20::Validator::Rule;

our $VERSION = 0.01;

__PACKAGE__->mk_accessors(qw(ua is_validated ok_count));

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->_init(@_);
    $self;
}

sub _init {
    my $self = shift;
    $self->{_rules} = [];
    $self->ua(LWP::UserAgent->new);
    $self->ua->agent(__PACKAGE__ . "/" . $VERSION);
    $self->ok_count(0);
}

sub add_rule {
    my $self = shift;
    push @{$self->{_rules}}, @_;
}

sub clear {
    my $self = shift;
    $self->ok_count(0);
    $self->is_validated(0);
}

sub set_all_rules {
    shift->add_rule(Acme::Web20::Validator::Rule->new->plugins);
}

sub rules_size {
    my $self = shift;
    return scalar @{$self->{_rules}};
}

sub validate {
    my $self = shift;
    $self->is_validated and return @{$self->{_rules}};
    my $response = $self->_get_remote(@_);
    for my $rule (@{$self->{_rules}}) {
        unless (ref $rule) {
            eval "use $rule";
            if ($@) {
                warn $@;
                next;
            }
            $rule = $rule->new
        }
        $rule->validate($response);
        $self->ok_count($self->ok_count + 1) if $rule->is_ok;
    }
    $self->is_validated(1);
    return @{$self->{_rules}};
}

sub validation_report {
    my $self = shift;
    my @rules = $self->is_validated ? @{$self->{_rules}} : $self->validate(@_);
    my $t = Text::ASCIITable->new;
    $t->setCols('Rule', 'Result');
    $t->addRow($_->name, $_->is_ok ? 'Yes!' : 'No') for @rules;
    return $t->draw;
}

sub _get_remote {
    my $self = shift;
    my $url = shift or croak 'usage: $validator->validate($url)';
    my $response = $self->ua->get($url);
    croak "Could'nt get $url " . $response->status_line
        unless $response->is_success;
    return $response;
}

1;

__END__

=head1 NAME

Acme::Web20::Validator - Web 2.0 Validation

=head1 SYNOPSIS

  use Acme::Web20::Validator;
  my $v = Acme::Web20::Validator->new;
  $v->add_rule(
    'Acme::Web20::Validator::Rule::HasAnyFees',
    'Acme::Web20::Validator::Rule::UseCatalyst',
    ...
  );
  print $v->validation_report('http://web2.0validator.com/');
  printf "The score is %d out of %d", $validator->ok_count, $v->rule_size;

  ## OR

  my $v = Acme::Web20::Validator->new;
  $v->set_all_rules;
  $v->validate('http://web2.0validator.com/');
  print $v->validation_report;

  ## OR
  my $v = Acme::Web20::Validator->new;
  $v->set_all_rules;
  my @rules = $v->validate('http://web2.0validator.com/');
  print $_->name . "\t" . $_->is_ok for (@rules);

=head1 DESCRIPTION

Acme::Web20::Validator is a Web 2.0 Validation module for your website.
This module is inspired from Web 2.0 Validator (http://web2.0validator.com/).

The definition of web 2.0 changes on a daily basis but currently
supports are:

  UsePrototype
  UseCatalyst
  UseRails
  MentionsWeb20
  UseLighttpd
  HasAnyFeeds
  ReferToDelicious
  XHtmlStrict
  UseCSS
  UseFeedBurner
  HasTrackbackURI

And the Rule is also pluggable with Module::Pluggable, so you can add
any rules by yourself. For example:

  package Acme::Web20::Validator::Rule::MyRule;
  use strict;
  use warnings;
  use base qw (Acme::Web20::Validator::Rule);
  __PACKAGE__->name('Your rule's description');

  sub validate {
      my $self = shift;
      my $res = shift; ## HTTP::Response via LWP
      ...
      $self->is_ok(1) if ...;
  }

  1;

=head1 METHODS

=head2 new

  my $v = Acme::Web20::Validator->new;

Creates and returns a validator instance.

=head2 add_rule

  $v->add_rule(
    'Acme::Web20::Validator::Rule::HasAnyFees',
    'Acme::Web20::Validator::Rule::UseCatalyst',
  )

Adds validation rules to the validator.

=head2 set_all_rules

  $v->set_all_rules;

Adds Acme::Web20::Validator::Rule::* to the validator.

=head2 validate

  my @rules = $v->validate($url);
  print $rules[0]->name;
  print $rules[0]->is_ok ? 'Yes!' : 'No';

Validates the website and returns rules which know the result of each
validation and rule's description.

=head2 validation_report

  print $v->validation_report($url)

  ## OR
  $v->validate($url);
  print $v->validation_report;

Returns a validation report formatted by Text::ASCIITable.

=head2 rules_size

Returns a number of rules validator has.

=head2 ok_count

Returns a number of OK after validation.

=head2 clear

  $v->validation_report($url[0]);
  $v->clear;
  $v->validation_report($url[1]);
  $v->clear;
  ...

Clears validation result in the instance for reusing. If you want to
validate for other rules, create a new instance instead of reusing
them.

=head1 SEE ALSO

L<Module::Pluggable>

=head1 TODO

Improve Catalyst, Rails checking logic.
Add more rules.

=head1 AUTHOR

Naoya Ito, E<lt>naoya@bloghackers.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
