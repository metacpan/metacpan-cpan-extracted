package Data::Perl;
$Data::Perl::VERSION = '0.002011';
# ABSTRACT: Base classes wrapping fundamental Perl data types.

BEGIN {
  require Exporter;
  our @ISA = qw(Exporter);
  our @EXPORT = qw(hash array counter string code bool number);
}

use strictures 1;

use Data::Perl::Collection::Array;
use Data::Perl::Collection::Hash;
use Data::Perl::Code;
use Data::Perl::Number;
use Data::Perl::Bool;
use Data::Perl::String;
use Data::Perl::Counter;

sub array { Data::Perl::Collection::Array->new(@_) }

sub hash { Data::Perl::Collection::Hash->new(@_) }

sub code { Data::Perl::Code->new(shift||sub {}) }

sub number { Data::Perl::Number->new(shift||0) }

sub bool { Data::Perl::Bool->new(shift||0) }

sub string { Data::Perl::String->new(shift||'') }

sub counter { Data::Perl::Counter->new(shift||0) }

1;

=pod

=encoding UTF-8

=head1 NAME

Data::Perl - Base classes wrapping fundamental Perl data types.

=head1 VERSION

version 0.002011

=head1 SYNOPSIS

  use Data::Perl;

  my $array = array(1,2,3, qw/a b c/);

  $array->count; # 6

  my @elements = $array->grep(sub {/b/}); # (b)

  my $hash = hash(a => 1, b => 2);

  $hash->keys; # ('a', 'b');

  my $number = number(5);

  $number->add(10); # 15

  my $string = string("foo\n");

  $string->chomp; # return 1, chomps string

  my $counter = counter();

  $counter->inc; # counter is now 1

  my $sub = code(sub { 'foo' });

  $sub->execute; # returns 'foo'

  $foo

=head1 DESCRIPTION

Data::Perl is a collection of classes that wrap fundamental data types that
exist in Perl. These classes and methods as they exist today are an attempt to
mirror functionality provided by Moose's Native Traits. One important thing to
note is all classes currently do no validation on constructor input.

Data::Perl is a container class for the following classes:

=over 4

=item * L<Data::Perl::Collection::Hash>

=item * L<Data::Perl::Collection::Array>

=item * L<Data::Perl::String>

=item * L<Data::Perl::Number>

=item * L<Data::Perl::Counter>

=item * L<Data::Perl::Bool>

=item * L<Data::Perl::Code>

=back

=head1 ALPHA API

The API provided by these modules is as of now considered alpha and undecided.
The API B<WILL> change.  If you are writing code that you will not touch again
for years, do not use this until this warning is removed.

=head1 PROVIDED FUNCTIONS

Data::Perl exports helper constructor functions to interface with the above classes:

=over 4

=item * B<hash(key, value, ...)>

Returns a Data::Perl::Collection::Hash object initialized with the optionally passed in key/value args.

=item * B<array(@args)>

Returns a Data::Perl::Collection::Array object initialized with the optionally passed in values.

=item * B<string($arg)>

Returns a Data::Perl::String object initialized with the optionally passed in scalar arg.

=item * B<number($arg)>

Returns a Data::Perl::Number object initialized with the optionally passed in scalar arg.

=item * B<counter($arg)>

Returns a Data::Perl::Counter object initialized with the optionally passed in scalar arg.

=item * B<bool($arg)>

Returns a Data::Perl::Bool object initialized with the truth value of the passed in scalar arg.

=item * B<code($arg)>

Returns a Data::Perl::Code object initialized with the optionally passed in scalar coderef as an arg.

=back

=head1 THANKS

Much thanks to the L<Moose> team for their work with native traits, for which
much of this work is based.

=head1 SEE ALSO

=over 4

=item * L<MooX::HandlesVia>

=back

=head1 AUTHOR

Matthew Phillips <mattp@cpan.org>

=head1 MAINTAINER

Toby Inkster <tobyink@cpan.org> since version 0.002010.

=head1 CONTRIBUTORS

=for stopwords Graham Knop Jon Portnoy kristof.pap@gmail.com Matt Phillips Toby Inkster

=over 4

=item *

Graham Knop <haarg@haarg.org>

=item *

Jon Portnoy <avenj@cobaltirc.org>

=item *

kristof.pap@gmail.com <kristof.pap@gmail.com>

=item *

Matt Phillips <mattp@cpan.org>

=item *

Toby Inkster <tobyink@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Matthew Phillips <mattp@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
==pod

