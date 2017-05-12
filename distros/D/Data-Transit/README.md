transit-pl
==========
Transit is a format layered on top of JSON and MessagePack which encodes the type into the data being sent. This library provides support for converting to/from Transit in Perl. If you want information on the format in general, you can get that [here](https://github.com/cognitect/transit-format).

Current version is 0.8.04.  This is a first draft, so there are still a lot of sharp edges.

Usage
=====
``` perl
use Data::Transit;

my $writer = Data::Transit::writer($fh, 'json');
$writer->write($value);

my $reader = Data::Transit::reader('json');
my $val = $reader->read($value);
```

For example:

``` perl
use Data::Transit;

my $output;
open my ($output_fh), '>>', \$output;
my $writer = Data::Transit::writer($fh, 'json');
$writer->write(["abc", 12345]);

my $reader = Data::Transit::reader('json');
my $vals = $reader->read($output);
```

Instead of json, you may also provide json-verbose and message-pack;

Type Mappings
=============
Perl converts a lot of different types into basic strings, and keys in maps have to be strings.  As a result, the only way to fully avoid key collisions is to have some sort of naming scheme, but this violates the spirit of Transit. Put another way, we're accepting the possibility of collisions in exchange for something that maps more closely to idiomatic perl.

In an effort to keep the dependencies of this library to a minimum, any types that correspond to something outside of perls core modules has been excluded. If demand becomes high enough, I will write a separate package to extend heavily into CPAN types.

Custom Types
------------
Custom types are registered at when the write/read handler is created:

``` perl
package Point;

sub new {
	my ($class, $x, $y) = @_;
	return bless {x => $x, y => $y}, $class;
}

package PointWriteHandler;

sub new {
	my ($class, $verbose) = @_;
	return bless {verbose => $verbose}, $class;
}

sub tag {
	return 'point';
}

sub rep {
	my ($self, $p) = @_;
	return [$p->{x},$p->{y}] if $self->{verbose};
	return "$p->{x},$p->{y}";
}

sub stringRep {
	return undef;
}

sub getVerboseHandler {
	return __PACKAGE__->new(1);
}

package PointReadHandler;

sub new {
	my ($class, $verbose) = @_;
	return bless {
		verbose => $verbose,
	}, $class;
}

sub fromRep {
	my ($self, $rep) = @_;
	return Point->new(@$rep) if $self->{verbose};
	return Point->new(split /,/,$rep);
}

sub getVerboseHandler {
	return __PACKAGE__->new(1);
}

package main;

my $point = Point->new(2,3);

my $output;
open my ($output_fh), '>>', \$output;
Data::Transit::writer("json", $output_fh, handlers => {
    Point => PointWriteHandler->new(),
})->write($point);

my $result = Data::Transit::reader("json", handlers => {
	point => PointReadHandler->new(),
})->read($output);

is_deeply($point, $result);# true
```
