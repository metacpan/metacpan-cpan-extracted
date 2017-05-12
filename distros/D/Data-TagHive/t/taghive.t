use 5.12.0;
use warnings;

use Test::More;
use Test::Fatal;
use Try::Tiny;

use lib 't/lib';
use Test::TagHive;

new_taghive;

taghive->add_tag('fauxbox.type:by-seat.seats:17');

has_tag($_) for qw(
  fauxbox
  fauxbox.type
  fauxbox.type:by-seat
  fauxbox.type:by-seat.seats
  fauxbox.type:by-seat.seats:17
);

hasnt_tag($_) for qw(
  pobox
  fauxbox.type:by-seat.seats:92
);

is_deeply(
  [ sort { $a cmp $b } taghive->all_tags ],
  [ sort qw(
    fauxbox
    fauxbox.type
    fauxbox.type:by-seat
    fauxbox.type:by-seat.seats
    fauxbox.type:by-seat.seats:17
  ) ],
  "all tags in ->all_tags",
);

{
  my $error = exception { taghive->add_tag('fauxbox.type:by-usage') };
  ok($error, "we can't add a tag with a conflicting value");
  like($error, qr/conflict at \Qfauxbox.type\E\b/, "...we get expected error");
}

{
  my $error = exception { taghive->add_tag('fauxbox.type:by-usage.seats:17') };
  ok($error, "we can't add a tag with a conflicting value");
  like($error, qr/conflict at \Qfauxbox.type\E\b/, "...we get expected error");
}

{
  my $error = exception { taghive->add_tag('fauxbox:foo'); };
  ok($error, "we can't add a tag with a value when there was no value");
  like($error, qr/conflict at fauxbox\b/, "...we get expected error");
}

{
  my $error = exception { taghive->add_tag('fauxbox.type.xyz'); };
  ok($error, "can't add descend with no value where one is already present");
  like($error, qr/conflict at \Qfauxbox.type\E\b/, "...we get expected error");
}

for my $method (qw(add_tag has_tag)) {
  my $error = exception { taghive->$method('not a tag!'); };
  ok($error, "can't pass invalid tag to $method");
  like($error, qr/invalid tagstr/, "...we get expected error");
}

{
  new_taghive->add_tag('foo');

  taghive->add_tag('foo');
  pass("we can re-add an exact valueless tag");

  taghive->add_tag('foo:bar');
  pass("we can add a value to a valueless tag, if it has no descendants");

  taghive->add_tag('bar');
  taghive->add_tag('bar.baz');
  my $error = exception { taghive->add_tag('bar:quux') };
  like($error, qr/conflict/, "...but not if it DOES have descendants");
}

done_testing;
