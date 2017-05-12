# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 24;
BEGIN
{
    use_ok('AnyEvent::POE_Reference');
    use_ok('Storable');
    use_ok('Compress::Zlib');
};

use AnyEvent::Util;

#########################

my $ser_uncomp1 = AnyEvent::POE_Reference->new('Storable');
isa_ok($ser_uncomp1, 'AnyEvent::POE_Reference');

my $ser_uncomp2 = AnyEvent::POE_Reference->new('Storable', 0);
isa_ok($ser_uncomp2, 'AnyEvent::POE_Reference');

ok($ser_uncomp1 == $ser_uncomp2, "Returns unique object");

#########################

my $ser_comp1 = AnyEvent::POE_Reference->new('Storable', 1);
isa_ok($ser_comp1, 'AnyEvent::POE_Reference');

my $ser_comp2 = AnyEvent::POE_Reference->new('Storable', 42);
isa_ok($ser_comp2, 'AnyEvent::POE_Reference');

ok($ser_comp1 == $ser_comp2, "Returns unique object");

#########################

my @serializers = (
    $ser_uncomp1,
    $ser_comp2,
    [ 'Storable' ],
    [ 'Storable', 0 ],
    [ 'Storable', 1 ],
    );

SKIP: {
    if (eval { require YAML })
    {
	push(@serializers,
	     AnyEvent::POE_Reference->new('YAML'),
	     AnyEvent::POE_Reference->new('YAML', 1),
	     [ 'YAML' ],
	     [ 'YAML', 0 ],
	     [ 'YAML', 1 ]);
    }
    else
    {
	skip 'YAML not installed', 5;
    }
};

SKIP: {
    if (eval { require FreezeThaw })
    {
	push(@serializers,
	     AnyEvent::POE_Reference->new('FreezeThaw'),
	     AnyEvent::POE_Reference->new('FreezeThaw', 1),
	     [ 'FreezeThaw' ],
	     [ 'FreezeThaw', 0 ],
	     [ 'FreezeThaw', 1 ]);
    }
    else
    {
	skip 'FreezeThaw not installed', 5;
    }
};

my @ser = (\@serializers, [ @serializers ]);
my @handle;

sub next_serializer
{
    my $idx = shift;

    my $ref_serializers = $ser[$idx];

    my $ref_item = shift @$ref_serializers;

    if (ref $ref_item eq 'ARRAY')
    {
	return @$ref_item;
    }

    return $ref_item || ();
}

my $condvar = AnyEvent->condvar;

my $last_ref = [ "abcd", 0, "zzz" ];
sub read_loop
{
    my $idx = shift;

    return sub
    {
	my($fh, $ref_data) = @_;

	ok("@$last_ref" eq "@$ref_data", "Serialization comp $last_ref->[1]");

	my $other = ($idx ^ 1);
	if (my @ser_data = next_serializer($other))
	{
	    $handle[$other]->push_read(
		poe_reference => @ser_data, read_loop($other));

	    $last_ref->[1]++;
	    $handle[$idx]->push_write(
		poe_reference => next_serializer($idx), $last_ref);
	}
	else
	{
	    $condvar->send;
	}
    };
}

my($fh1, $fh2) = portable_socketpair;

@handle = (AnyEvent::Handle->new(
	       fh => $fh1,
	       timeout => 5,
	       on_error => sub { fail("IO error"); $condvar->send }),
	   AnyEvent::Handle->new(
	       fh => $fh2,
	       timeout => 5,
	       on_error => sub { fail("IO error"); $condvar->send }));

$handle[0]->push_read(poe_reference => next_serializer(0), read_loop(0));
$handle[1]->push_write(poe_reference => next_serializer(1), $last_ref);

$condvar->recv;
