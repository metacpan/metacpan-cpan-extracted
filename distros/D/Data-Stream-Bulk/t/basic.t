#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Data::Stream::Bulk::Nil;
use Data::Stream::Bulk::Array;
use Data::Stream::Bulk::Callback;
use Data::Stream::Bulk::FileHandle;
use Data::Stream::Bulk::Util qw(bulk nil cat filter unique);

{
	my $d = Data::Stream::Bulk::Nil->new;

	ok( $d->is_done, "Nil is always done" );
	ok( !$d->next, "no next block" );

	isa_ok( nil, "Data::Stream::Bulk::Nil", "nil() helper" );

	ok( nil->loaded, "nil is realized" );

	isa_ok( bulk(), "Data::Stream::Bulk::Nil", "bulk() helper with no items" );

	isa_ok( nil->cat(nil), "Data::Stream::Bulk::Nil", "cating nil with nil results in nil" );

	isa_ok( cat(), "Data::Stream::Bulk::Nil", "cat with no args returns nil" );

	isa_ok( cat(nil), "Data::Stream::Bulk::Nil", "cat of nil is nil" );
	isa_ok( cat(nil, nil, nil, nil), "Data::Stream::Bulk::Nil", "cat of several nil is nil" );

	is_deeply( [ nil->items ], [], "no items" );
	is_deeply( [ nil->all ], [], "nothing at all" );

	isa_ok( nil->filter(sub {[]}), "Data::Stream::Bulk::Nil" );
}

{
	my @array = qw(foo bar gorch baz);

	my $d = Data::Stream::Bulk::Array->new( array => \@array );

	ok( $d->loaded, "array is realized" );

	ok( !$d->is_done, "not done" );

	is_deeply( $d->next, \@array, "next" );

	ok( $d->is_done, "now it's done" );

	ok( !$d->next, "no next block" );

	is_deeply( bulk(@array)->next, \@array, "bulk() helper" );

	isa_ok( nil->cat(bulk(@array)), "Data::Stream::Bulk::Array", "nil cat Array results in Array" );

	my $cat = bulk(qw(foo bar))->cat(bulk(qw(gorch baz)));

	isa_ok( $cat, "Data::Stream::Bulk::Array", "Array cat Array resuls in Array" );

	is_deeply( $cat->next, \@array, "concatenated array into one block" );

	is_deeply( [ cat(bulk(qw(foo bar)), bulk(qw(gorch baz)))->all ], \@array, "cat helper function" );
}

{
	my @array = qw(foo bar gorch baz);

	my $d = Data::Stream::Bulk::Array->new( array => \@array );

	ok( !$d->is_done, "not done" );

	is_deeply( [ $d->items ], \@array, "items method" );

	ok( $d->is_done, "now it's done" );

	ok( !$d->next, "no next block" );
}

{
	my @array = qw(foo bar);

	my $cb = sub { @array && [ shift @array ] };

	my $d = Data::Stream::Bulk::Callback->new( callback => $cb );

	ok( !$d->is_done, "not done" );
	is_deeply( [ $d->items ], [ "foo" ], "items method" );
	ok( !$d->is_done, "not done" );
	is_deeply( [ $d->items ], [ "bar" ], "items method" );
	ok( !$d->is_done, "not done" );
	is_deeply( [ $d->items ], [ ], "items method" );

	ok( $d->is_done, "now it's done" );

	ok( !$d->next, "no next" );
}

{
	my @copy = my @array = qw(foo bar gorch);

	my $cb = sub { @array && [ shift @array ] };

	my $d = Data::Stream::Bulk::Callback->new( callback => $cb );

	ok( !$d->loaded, "callback is not realized" );

	is_deeply( [ $d->all ], \@copy, "all method" );

	ok( $d->is_done, "done" );
}

{
	my @array = qw(foo bar);

	my $cb = sub { @array && [ shift @array ] };

	my $d = Data::Stream::Bulk::Callback->new( callback => $cb )->cat(bulk(qw(gorch baz)));

	isa_ok( $d, "Data::Stream::Bulk::Cat" );

	ok( !$d->is_done, "not done" );
	is_deeply( [ $d->items ], [ "foo" ], "items method" );
	ok( !$d->is_done, "not done" );
	is_deeply( [ $d->items ], [ "bar" ], "items method" );
	ok( !$d->is_done, "not done" );
	is_deeply( [ $d->items ], [ qw(gorch baz) ], "reached array" );
	ok( !$d->is_done, "not done" );
	is_deeply( [ $d->items ], [ ], "items method" );

	ok( $d->is_done, "now it's done" );

	ok( !$d->next, "no next" );
}

{
	my @array = qw(foo bar);
	my $cb = sub { @array && [ shift @array ] };

	my $d = nil->cat(bulk(qw(gorch baz))->cat(Data::Stream::Bulk::Callback->new( callback => $cb )->cat(bulk(qw(oi))->cat(nil->cat(bulk("vey"))))->cat(nil))->cat(nil))->cat(nil)->cat(Data::Stream::Bulk::Callback->new( callback => $cb )->cat(bulk(qw(last))));

	isa_ok( $d, "Data::Stream::Bulk::Cat" );

	ok( !$d->loaded, "concatenation is not realized" );

	is_deeply(
		[ map { ref } @{ $d->streams } ],
		[
			"Data::Stream::Bulk::Array", # qw(gorch baz)
			"Data::Stream::Bulk::Callback", # first cb
			"Data::Stream::Bulk::Array", # "oi" cat "vey"
			"Data::Stream::Bulk::Callback", # second CB
			"Data::Stream::Bulk::Array", # "last"
		],
		"list_cat simplified concatenation",
	);

	ok( !$d->is_done, "not done" );
	is_deeply( [ $d->items ], [ qw(gorch baz) ], "array block" );
	ok( !$d->is_done, "not done" );
	is_deeply( [ $d->items ], [ "foo" ], "items method" );
	ok( !$d->is_done, "not done" );
	is_deeply( [ $d->items ], [ "bar" ], "items method" );
	ok( !$d->is_done, "not done" );
	is_deeply( [ $d->items ], [ qw(oi vey) ], "items method" );
	ok( !$d->is_done, "not done" );
	is_deeply( [ $d->items ], [ "last" ], "items method" );
	ok( !$d->is_done, "not done" );
	is_deeply( [ $d->items ], [ ], "items method" );

	ok( $d->is_done, "now it's done" );

	ok( !$d->next, "no next" );

	is_deeply(
		[ map { ref } @{ $d->streams } ],
		[ ],
		"no streams in concatenated",
	);
}

{
	my $d = filter { [ grep { /o/ } @$_ ] } bulk(qw(foo bar gorch baz));

	isa_ok( $d, "Data::Stream::Bulk::Array" );

	ok( !$d->is_done, "not done" );
	is_deeply( [ $d->items ], [ qw(foo gorch) ], "items method" );

	ok( $d->is_done, "done" );

	ok( !$d->next, "no next" );
}

{
	my @array = ( [qw(foo bar), "", ], [qw(gorch baz)] );

	my $cb = sub { shift @array };

	my $d = Data::Stream::Bulk::Callback->new( callback => $cb )->filter(sub {
		return [ grep { length } @$_ ];
	})->filter(sub{
		return [ grep { /o/ } @$_ ];
	});

	isa_ok( $d, "Data::Stream::Bulk::Filter" );

	ok( !$d->is_done, "not done" );
	is_deeply( [ $d->items ], [ "foo" ], "items method" );
	ok( !$d->is_done, "not done" );
	is_deeply( [ $d->items ], [ "gorch" ], "items method" );
	ok( !$d->is_done, "not done" );
	is_deeply( [ $d->items ], [ ], "items method" );

	ok( $d->is_done, "now it's done" );

	ok( !$d->next, "no next" );
}

{
	my @array = ( [qw(foo bar bar)], [qw(gorch foo baz)] );

	my $cb = sub { shift @array };

	my $d = unique(Data::Stream::Bulk::Callback->new( callback => $cb ));

	ok( !$d->is_done, "not done" );
	is_deeply( [ $d->items ], [ qw(foo bar) ], "items method" );
	ok( !$d->is_done, "not done" );
	is_deeply( [ $d->items ], [ qw(gorch baz) ], "items method" );
	ok( !$d->is_done, "not done" );
	is_deeply( [ $d->items ], [ ], "items method" );
}

{
	my ( $foo, $bar, $gorch ) = ( [], {}, "gorch" );
	my $a = unique(bulk($foo, $bar, $foo, $foo, $gorch, $bar));

	isa_ok( $a, "Data::Stream::Bulk::Array", "unique on array returns array" );

	is_deeply([ $a->all ], [ $foo, $bar, $gorch ], "unique with refs" );
}

{
    my $i = 0;
    my $cb = sub {
        $i++;
        return if $i > 6;
        return [ ($i) x $i ];
    };

    my $s = Data::Stream::Bulk::Callback->new(callback => $cb)->chunk(5);

    isa_ok( $s, 'Data::Stream::Bulk::Chunked' );

    ok( !$s->is_done, "stream is not done");
    is_deeply( $s->next, [ 1, 2, 2, 3, 3, 3 ] );
    is_deeply( $s->next, [ 4, 4, 4, 4, 5, 5, 5, 5, 5 ] );
    is_deeply( $s->next, [ 6, 6, 6, 6, 6, 6 ] );
    ok( !defined($s->next), "stream is done" );
    ok( $s->is_done, "stream is done" );
}

{
    my $text = <<'TEXT';
foo
bar baz

quux
TEXT
    chomp $text;

    open my $fh, '<', \$text or die "Couldn't open string: $!";
    my $s = Data::Stream::Bulk::FileHandle->new(filehandle => $fh);

    isa_ok( $s, 'Data::Stream::Bulk::FileHandle' );

    ok( !$s->is_done, "stream is not done");
    is_deeply( $s->next, [ "foo\n" ] );
    is_deeply( $s->next, [ "bar baz\n" ] );
    is_deeply( $s->next, [ "\n" ] );
    is_deeply( $s->next, [ "quux" ] );
    ok( !defined($s->next), "stream is done");
    ok( $s->is_done, "stream is done" );
}

done_testing;
