#!perl
use strict;
use warnings;

use Test::More tests => 73;

use Array::Splice qw ( splice_aliases );

# Check reference counts
our $test;
my (%destroyed,@expect_to_destroy,@insertion,%xref);

sub DESTROY { $destroyed{+shift}++ };

sub expect_to_destroy_ref {
    @expect_to_destroy = map { "$_" } @_;
    %destroyed = ();
}

sub expect_to_destroy {
    expect_to_destroy_ref map { \$_ } @_;
}

sub expect_to_insert : lvalue {
    @insertion = map { ''.\$_ } @_;
    @_[0..$#_];
}

sub were_right_things_destroyed {
    #use Data::Dumper; print Dumper \@expect_to_destroy, \%destroyed;
    my @not_destroyed = map{ $xref{$_} || $_ } grep { ! delete $destroyed{$_} } @expect_to_destroy;
    my @unexpected_destroy =map{ $xref{$_} || $_ } sort keys %destroyed;
    ok(!@not_destroyed,"$test, expected destruction");
    print "#  not_destroyed: @not_destroyed\n" if @not_destroyed;
    ok(!@unexpected_destroy,"$test, unexpected destruction");
    print "#  unexpected_destroy: @unexpected_destroy\n" if @unexpected_destroy;
    @expect_to_destroy = ();
}

sub were_right_things_inserted {
    my @inserted = map { ''.\$_ } @_;
    is_deeply(\@inserted,\@insertion,"$test, insertion");
    @insertion = ();
}

my (@a,@b);

sub begin_test {
    $test = shift || '';
    @a = map { "a$_" } '00'..'19';
    @b = map { "b$_" } '00'..'19';
    %xref = ();
    for (@a,@b) {
	bless \$_;
	$xref{\$_}=$_;
    }
}

sub cleanup {
    were_right_things_destroyed;
    expect_to_destroy @a,@b;
    (@a,@b)=();
    local $test = "$test, cleanup";
    were_right_things_destroyed;
}

{ 
    begin_test 'Test the test';
    were_right_things_inserted expect_to_insert @b;
    expect_to_destroy $a[-1];
    pop @a;
    cleanup;
}

{
    begin_test 'Shrink, void context';
    expect_to_destroy @a[5..9];
    splice_aliases @a, 5, 5, splice @b, 0, 2;
    cleanup;
}

{
    begin_test 'Shrink, scalar context';
    expect_to_destroy @a[5..8];
    my $foo = \ scalar splice_aliases @a, 5, 5, expect_to_insert splice @b, 0, 4;
    were_right_things_inserted @a[5..8];
    were_right_things_destroyed;
    expect_to_destroy_ref $foo;
    undef $foo;
    cleanup;
}

{
    begin_test 'Shrink, list context';
    expect_to_destroy;
    my @foo = map {\$_} splice_aliases @a, 5, 5;
    were_right_things_destroyed;
    expect_to_destroy_ref @foo;
    @foo = ();
    cleanup;
}

{
    begin_test 'Same size, void context';
    expect_to_destroy @a[5..9];
    splice_aliases @a, 5, 5, expect_to_insert splice @b, 0, 5;
    cleanup;
}

{
    begin_test 'Same size, scalar context';
    expect_to_destroy @a[5..8];
    my $foo = \scalar splice_aliases @a, 5, 5, splice @b, 0, 5;
    were_right_things_destroyed;
    expect_to_destroy_ref $foo;
    undef $foo;
    cleanup;
}

{
    begin_test 'Same size, list context';
    expect_to_destroy;
    my @foo = map { \$_ } splice_aliases @a, 5, 5, expect_to_insert splice @b, 0, 5;
    were_right_things_inserted @a[5..9];
    were_right_things_destroyed;
    expect_to_destroy_ref @foo;
    @foo = ();
    cleanup;
}

{
    begin_test 'Grow, void context';
    expect_to_destroy @a[5..9];
    splice_aliases @a, 5, 5, expect_to_insert splice @b, 0, 10;
    were_right_things_inserted @a[5..14];
    cleanup;
}

{
    begin_test 'Grow, scalar context';
    expect_to_destroy @a[5..8];
    my $foo = \scalar splice_aliases @a, 5, 5, splice @b, 0, 10;
    were_right_things_destroyed;
    expect_to_destroy_ref $foo;
    undef $foo;
    were_right_things_destroyed;
    cleanup;
}

{
    begin_test 'Grow, list context';
    expect_to_destroy;
    my @foo = map { \$_ } splice_aliases @a, 5, 5, splice @b, 0, 10;
    were_right_things_destroyed;
    expect_to_destroy_ref @foo;
    @foo = ();
    cleanup;
}

# Pure insertions
{
    begin_test 'Unshift';
    splice_aliases @a,0,0, expect_to_insert splice @b, 0, 10;
    were_right_things_inserted @a[0..9];
    cleanup;
}

{
    begin_test 'Insert relative end';
    splice_aliases @a,-2,0, expect_to_insert splice @b, 0, 10;
    were_right_things_inserted @a[18..27];
    cleanup;
}

{
    begin_test 'Insert';
    splice_aliases @a,5,0, expect_to_insert splice @b, 0, 10;
    were_right_things_inserted @a[5..14];
    cleanup;
}
