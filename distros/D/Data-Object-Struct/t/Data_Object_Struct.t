use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Struct

=cut

=abstract

Struct Class for Perl 5

=cut

=synopsis

  package main;

  use Data::Object::Struct;

  my $person = Data::Object::Struct->new(
    fname => 'Aron',
    lname => 'Nienow',
    cname => 'Jacobs, Sawayn and Nienow'
  );

  # $person->fname # Aron
  # $person->lname # Nienow
  # $person->cname # Jacobs, Sawayn and Nienow

  # $person->mname
  # Error!

  # $person->mname = 'Clifton'
  # Error!

  # $person->{mname} = 'Clifton'
  # Error!

=cut

=integrates

Data::Object::Role::Buildable
Data::Object::Role::Immutable
Data::Object::Role::Proxyable

=cut

=description

This package provides a class that creates struct-like objects which bundle
attributes together, is immutable, and provides accessors, without having to
write an explicit class.

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  is $result->fname, 'Aron';
  is $result->lname, 'Nienow';
  is $result->cname, 'Jacobs, Sawayn and Nienow';

  like do { eval {  $result->mname }; $@ },
    qr/Can't locate object method "mname" via package "Data::Object::Struct"/;

  is $result->fname('Riva'), 'Aron';
  is $result->lname('Emmerich'), 'Nienow';
  like do { eval {  $result->fname = 'Riva' }; $@ },
    qr/Can't modify non-lvalue subroutine call/;

  like do { eval {  $result->{fname} = 'Riva' }; $@ },
    qr/Modification of a read-only value/;

  is $result->fname, 'Aron';
  is $result->lname, 'Nienow';

  $result
});

ok 1 and done_testing;
