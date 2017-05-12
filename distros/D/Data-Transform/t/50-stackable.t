# vim: filetype=perl

# Exercises Filter::Stack (and friends) without the rest of POE.

use strict;
use lib qw(./mylib ../mylib);

use Test::More;

plan tests => 26;

use_ok('Data::Transform::Stackable');
use_ok('Data::Transform::Grep');
use_ok('Data::Transform::Map');
use_ok('Data::Transform::Line');

# Create a filter stack to test.

my $filter_stack = Data::Transform::Stackable->new(
  Filters => [
    Data::Transform::Map->new(
      Put => sub { $_[0] =~ s/(?:\){3}|\({3})//g; $_[0] }, 
      Get => sub { "((($_[0])))" }, # transform gets
    ),

    Data::Transform::Grep->new(
      Put => sub { 1            }, # always put
      Get => sub { $_[0] =~ /1/ }, # only get /1/
    ),

    Data::Transform::Line->new( Literal => "!" ),
  ]
);

ok(defined($filter_stack), "filter stack created");

{
  # testing Meta passthrough (copied from TestFilter)
  my $eof = Data::Transform::Meta::EOF->new;
  my $result;

  $result = $filter_stack->get([$eof]);
  cmp_ok(@$result, '>=', 1, 'got output for EOF from get');
  isa_ok($result->[-1], 'Data::Transform::Meta::EOF', '.. and the last item');

  $result = $filter_stack->put([$eof]);
  cmp_ok(@$result, '>=', 1, 'got output for EOF from put');
  isa_ok($result->[-1], 'Data::Transform::Meta::EOF', '.. and the last item');
}

my $block = $filter_stack->get( [ "test one (1)" ] );
ok(!@$block, "partial get returned nothing");

my $pending = $filter_stack->get_pending();
is_deeply(
  $pending, [ "(((test one (1))))" ],
  "filter stack has correct get_pending"
);

$block = $filter_stack->get( [ "test two (2)", "!test three (100)!" ] );
is_deeply(
  $block, [ "(((test one (1))))(((", "test three (100)" ],
  "filter stack returned correct data"
);
$pending = $filter_stack->get_pending();
is_deeply(
  $pending, [ ")))" ],
  "filter stack has correct get_pending"
);

# Make a copy of the block.  Bad things happen when both blocks have
# the same reference because we're passing by reference a lot.

my $stream = $filter_stack->put( $block );

is_deeply(
  $stream,
  [ "test one (1)!", "test three (100)!", ],
  "filter stack serialized correct data"
);

{
  my @filters_should_be = qw(
		Data::Transform::Map
                Data::Transform::Grep
                Data::Transform::Line
	);
  my @filters_are  = $filter_stack->filter_types();
  is_deeply(\@filters_are, \@filters_should_be,
    "filter types stacked correctly");
}


# test pushing and popping
{
  my @filters_strlist = map { "$_" } $filter_stack->filters();

  my $filter_pop = $filter_stack->pop();
  ok(
    ref($filter_pop) eq "Data::Transform::Line",
    "popped the correct filter"
  );

  my $filter_shift = $filter_stack->shift();
  ok(
    ref($filter_shift) eq 'Data::Transform::Map',
    "shifted the correct filter"
  );

  $filter_stack->push( $filter_pop );
  $filter_stack->unshift( $filter_shift );

  my @filters_strlist_end = map { "$_" } $filter_stack->filters();
  is_deeply(\@filters_strlist_end, \@filters_strlist,
    "repushed, reshifted filters are in original order");
}

# push error checking
{
  my @filters_strlist = map { "$_" } $filter_stack->filters();

  eval { $filter_stack->push(undef) };
  ok(!!$@, "undef is not a filter");

  eval { $filter_stack->push(['i am not a filter']) };
  ok(!!$@, "bare references are not filters");

  eval { $filter_stack->push(bless(['i am not a filter'], "foo$$")) };
  ok(!!$@, "random blessed references are not filters");
  # not blessed into a package that ISA Data::Transform

  eval { $filter_stack->push(123, "two not-filter things") };
  ok(!!$@, "multiple non-filters are not filters");

  my @filters_strlist_end = map { "$_" } $filter_stack->filters();
  is_deeply(\@filters_strlist_end, \@filters_strlist,
    "filters unchanged despite errors");
}

# test cloning
{
  my @filters_strlist = map { "$_" } $filter_stack->filters();
  my @filter_types = $filter_stack->filter_types();

  my $new_stack = $filter_stack->clone();

  isnt("$new_stack", "$filter_stack", "cloned stack is different");
  isnt(join('---', @filters_strlist),
    join('---', $new_stack->filters()),
    "filters are different");
  is_deeply(\@filter_types, [$new_stack->filter_types()],
    "but types are the same");
}

exit 0;
