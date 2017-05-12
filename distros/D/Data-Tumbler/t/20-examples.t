#!/usr/bin/env perl

use Test::Most;
use Data::Dumper;

use Data::Tumbler;

my @output;
my $tumbler;

my $buffer = "";
my $fh;

if ( $] < 5.008 )
{
    require IO::String;
    $fh = IO::String->new($buffer);
}
else
{
    open $fh, '>', \$buffer
	or die "Can't reopen STDOUT to a variable: $!";
}
select $fh;

note "Example 1";
# ---snip---
    $tumbler = Data::Tumbler->new(

        add_path => sub {
            my ($path, $name) = @_;
            return [ @$path, $name ];
        },

        add_context => sub {
            my ($context, $value) = @_;
            return [ @$context, $value ]
        },

        consumer  => sub {
            my ($path, $context, $payload) = @_;
            print "@$path: @$context\n";
        },
    );

    $tumbler->tumble(
        [   # provider code refs
            sub { (red => 42, green => 24, mauve => 19) },
            sub { (circle => 1, square => 2) },
            # ...
        ],
        [], # initial path
        [], # initial context
        [], # initial payload
    );
# ---snip---

is "\n$buffer", q{
green circle: 24 1
green square: 24 2
mauve circle: 19 1
mauve square: 19 2
red circle: 42 1
red square: 42 2
}
    or warn $buffer;


$buffer = "";
if ( $] < 5.008 )
{
    $fh = IO::String->new($buffer);
}
else
{
    open $fh, '>', \$buffer
	or die "Can't reopen STDOUT to a variable: $!";
}
select $fh;

note "Example 2";
# ---snip---

    use List::Util qw(sum);

    $tumbler = Data::Tumbler->new(

        # The default add_path is as shown above
        # The default add_context is as shown above

        consumer  => sub {
            my ($path, $context, $payload) = @_;
            printf "path: %-20s  context: %-12s  payload: %s\n",
                join("/", @$path),
                join(", ", @$context),
                join(", ", map { "$_=>$payload->{$_}" } sort keys %$payload);
        },
    );

    $tumbler->tumble(
        [   # providers
            sub {
                my ($path, $context, $payload) = @_;

                my %variants = (red => 42, green => 24, mauve => 19);

                return %variants;
            },
            sub {
                my ($path, $context, $payload) = @_;

                # change paint to matt based on context
                $payload->{paint} = 'matt' if sum(@$context) > 20;

                my %variants = (circle => 10, square => 20);

                # add an extra triangular variant for mauve
                $variants{triangle} = 13 if grep { $_ eq 'mauve' } @$path;

                return %variants;
            },
            sub {
                my ($path, $context, $payload) = @_;

                # skip all variants if path contains anything red or circular
                return if grep { $_ eq 'red' or $_ eq 'circle' } @$path;

                $payload->{spotty} = 1 if sum(@$context) > 35;

                my %variants = (small => 17, large => 92);

                return %variants;
            },
            # ...
        ],
        [], # initial path
        [], # initial context
        { paint => 'gloss' }, # initial payload
    );
# ---snip---

is "\n$buffer", q{
path: green/square/large    context: 24, 20, 92    payload: paint=>matt, spotty=>1
path: green/square/small    context: 24, 20, 17    payload: paint=>matt, spotty=>1
path: mauve/square/large    context: 19, 20, 92    payload: paint=>gloss, spotty=>1
path: mauve/square/small    context: 19, 20, 17    payload: paint=>gloss, spotty=>1
path: mauve/triangle/large  context: 19, 13, 92    payload: paint=>gloss
path: mauve/triangle/small  context: 19, 13, 17    payload: paint=>gloss
}
    or warn $buffer;

done_testing;
