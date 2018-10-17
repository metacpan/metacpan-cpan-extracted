#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Warnings;

use Commandable::Invocation;

# tokens
{
   my $inv = Commandable::Invocation->new( "some words go here" );

   is( $inv->peek_token, "some", '->peek_token' );
   is( $inv->pull_token, "some", '->pull_token' );

   is( $inv->pull_token, "words", '->pull_token again' );

   is( $inv->pull_token, "go", '->pull_token again' );

   is( $inv->pull_token, "here", '->pull_token again' );

   is( $inv->peek_token, undef, '->peek_token at EOF' );
   is( $inv->pull_token, undef, '->pull_token at EOF' );
}

# remaining
{
   my $inv = Commandable::Invocation->new( "more tokens here" );

   is( $inv->remaining, "more tokens here", '->remaining initially' );

   $inv->pull_token;
   is( $inv->remaining, "tokens here", '->remaining after ->pull_token' );
}

# "quoted tokens"
{
   my $inv = Commandable::Invocation->new( q("quoted token" here) );

   is( $inv->remaining, q("quoted token" here), '->remaining initially' );

   is( $inv->pull_token, "quoted token", '->pull_token yields string' );

   is( $inv->remaining, "here", '->remaining after ->pull_token' );

   $inv = Commandable::Invocation->new( q("three" "quoted" "tokens") );

   is( $inv->pull_token, "three", '->pull_token splits multiple quotes' );
}

# \" escaping
{
   my $inv = Commandable::Invocation->new( q(\"quoted\" string token) );

   is( $inv->pull_token, '"quoted"', '->pull_token yields de-escaped quote' );
   is( $inv->pull_token, 'string',   '->pull_token after de-escaped quote' );

   $inv = Commandable::Invocation->new( q(\\\\backslash) );

   is( $inv->pull_token, "\\backslash", '->pull_token yields de-escaped backslash' );
}

# putback
{
   my $inv = Commandable::Invocation->new( "c" );
   $inv->putback_tokens( qw( a b ) );

   is( $inv->peek_token, "a", '->peek_token after putback' );
   is( $inv->pull_token, "a", '->pull_token after putback' );

   is( $inv->pull_token, "b", '->pull_token after putback' );

   is( $inv->pull_token, "c", '->pull_token after putback' );

   $inv->putback_tokens( "foo", "bar splot" );
   is( $inv->remaining, q(foo "bar splot"), '->remaining after putback' );
}

# new_from_tokens
{
   my $inv = Commandable::Invocation->new_from_tokens( "one", "two", "three four" );

   is( $inv->pull_token, "one",        '->pull_token from new_from_tokens' );
   is( $inv->pull_token, "two",        '->pull_token from new_from_tokens' );
   is( $inv->pull_token, "three four", '->pull_token from new_from_tokens' );
}

done_testing;
