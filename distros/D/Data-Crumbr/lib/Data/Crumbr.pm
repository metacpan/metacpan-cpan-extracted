package Data::Crumbr;
$Data::Crumbr::VERSION = '0.1.2';
# ABSTRACT: Render data structures for easy searching and parsing

# Inlined Mo
use Mo qw< default coerce >;

use strict;
use warnings;
use Carp;
use English qw< -no_match_vars >;
use Exporter qw< import >;
use Scalar::Util qw< blessed >;

our @EXPORT      = qw< crumbr >;
our @EXPORT_OK   = @EXPORT;
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

has encoder => (
   default => sub { __encoder() },
   coerce  => \&__encoder,
);

sub __load_class {
   my ($class) = @_;
   (my $packname = "$class.pm") =~ s{::}{/}gmxs;
   require $packname;
   return $class;
} ## end sub __load_class

sub crumbr {
   my %args = (@_ && ref($_[0])) ? %{$_[0]} : @_;
   if (defined(my $name = delete $args{profile})) {
      my $class   = __PACKAGE__ . "::Default::$name";
      my $profile = __load_class($class)->profile();
      my $encoder = delete($args{encoder}) // {};
      %$encoder = (
         %$profile,
         %$encoder,    # allow some overriding
         class => '::Default',    # but not on this one
      );
      %args = (encoder => $encoder);
   } ## end if (defined(my $name =...))
   my $wh = __PACKAGE__->new(%args);
   return sub { $wh->encode(@_) };
} ## end sub crumbr

sub __encoder {
   my ($e) = @_;
   if (!blessed($e)) {
      my ($class, @parameters) = $e;
      if (ref($e) eq 'HASH') {
         $class      = delete $e->{class};
         @parameters = %$e;
      }
      $class = '::Default' unless defined $class;
      $class = __PACKAGE__ . $class
        if substr($class, 0, 2) eq '::';
      $e = __load_class($class)->new(@parameters);
   } ## end if (!blessed($e))
   return $e;
} ## end sub __encoder

sub encode {
   my ($self, $data) = @_;
   my $encoder = $self->encoder();
   $encoder->reset();

   my @stack = ({closers => ''}, {data => $data, type => ref($data)},);
 ITERATION:
   while (@stack > 1) {    # frame #0 is dummy
      my $frame = $stack[-1];
      if ($frame->{type} eq 'ARRAY') {
         if (!scalar(@{$frame->{data}})) {
            $encoder->array_leaf(\@stack);
         }
         else {
            my $iterator = $frame->{iterator} //=
              $encoder->array_keys_iterator($frame->{data});
            if (defined(my $key = $iterator->())) {
               $frame->{encoded} = $encoder->array_key($key);
               $frame->{closers} =
                 $encoder->array_close() . $stack[-2]{closers};
               my $child_data = $frame->{data}[$key];
               push @stack,
                 {
                  data => $child_data,
                  type => ref($child_data),
                 };
               next ITERATION;
            } ## end if (defined(my $key = ...))
         } ## end else [ if (!scalar(@{$frame->...}))]
      } ## end if ($frame->{type} eq ...)
      elsif ($frame->{type} eq 'HASH') {
         if (!scalar(keys %{$frame->{data}})) {
            $encoder->hash_leaf(\@stack);
         }
         else {
            my $iterator = $frame->{iterator} //=
              $encoder->hash_keys_iterator($frame->{data});
            if (defined(my $key = $iterator->())) {
               $frame->{encoded} = $encoder->hash_key($key);
               $frame->{closers} =
                 $encoder->hash_close() . $stack[-2]{closers};
               my $child_data = $frame->{data}{$key};
               push @stack,
                 {
                  data => $child_data,
                  type => ref($child_data),
                 };
               next ITERATION;
            } ## end if (defined(my $key = ...))
         } ## end else [ if (!scalar(keys %{$frame...}))]
      } ## end elsif ($frame->{type} eq ...)
      else {    # treat as leaf scalar
         $encoder->scalar_leaf(\@stack);
      }

      # only leaves or end-of-container arrive here
      pop @stack;
   } ## end ITERATION: while (@stack > 1)

   return $encoder->result();
} ## end sub encode

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Data::Crumbr - Render data structures for easy searching and parsing

=head1 VERSION

version 0.1.2

=head1 SYNOPSIS

   use Data::Crumber; # imports `crumbr`

   # some data to work with
   my $data = { what => 'ever', hey => 'you' };

   # crumbr provides an anonyous sub back. This has defaults
   my $csub = crumbr();

   # use it to encode the data
   my $encoded = $crumbr->($data);
   # {"here"}{"hey"}:"you"
   # {"here"}{"what"}:"ever"

   # URI profile simplifies things but loses something
   $encoded = crumbr(profile => 'URI')->($data);
   # here/hey "you"
   # here/what "ever"

   # JSON profile produces valid JSON "slices"
   $encoded = crumbr(profile => 'JSON')->($data);
   # {"here":{"hey":"you"}}
   # {"here":{"what":"ever"}}

   # Object Oriented Interface
   my $crobj = Data::Crumbr->new();
   $encoded = $crobj->encode($data); # same as default

=head1 DESCRIPTION

Data::Crumbr lets you render data structures in a way that can then be
easily searched and parsed in "slices". The basic idea is that data
shaped in this way will then be easily filtered in the shell for
extracting interesting parts.

The input data structure is traversed is if it is a tree (so no
circular structures please!), and a I<record> is generated for each leaf
in the tree. Depending on the backend and the configurations, the full
path from the root to the parent of the leaf is represented as a
sequence of keys (which can be hash keys or array indexes) followed by
the value. This should make your life easier e.g. in the shell, so that
you can specify the full path to the data structure part you're
interested into with common Unix tools like C<grep> and/or C<sed>.

=head2 Example

Suppose you have the following data structure in Perl:

   my $data = {
      one => '1',
      two => 2,
      three => 3.1,
      four => '4.0',
      true => \1,
      false => \0,
      array => [
         qw< what ever >,
         { inner => 'part', empty => [] }
       ],
      hash => {
         'with ♜' => {},
         ar => [ 1..3 ],
         something => "funny \x{263A} ☻",
      },
   };

If you encode this e.g. in JSON, it will be easy to parse with
the right program, but not from the shell, even if you pretty
print it:

   {
      "hash" : {
         "something" : "funny ☺ ☻",
         "with ♜" : {},
         "ar" : [
            1,
            2,
            3
         ]
      },
      "one" : "1",
      "array" : [
         "what",
         "ever",
         {
            "inner" : "part",
            "empty" : []
         }
      ],
      "four" : "4.0",
      "true" : true,
      "two" : 2,
      "three" : 3.1,
      "false" : false
   }

How do you get the second item in the array C<ar>i inside the
hash C<hash>? Would you do better with YAML instead?

   ---
   array:
     - what
     - ever
     - empty: []
       inner: part
   false: !!perl/ref
     =: 0
   four: 4.0
   hash:
     ar:
       - 1
       - 2
       - 3
     something: funny ☺ ☻
     with ♜: {}
   one: 1
   three: 3.1
   true: !!perl/ref
     =: 1
   two: 2

Not really. Data::Crumbr lets you represent the data in a
more verbose but easily consumable way for the shell. Hence,
this:

   use Data::Crumbr;
   print crumbr()->($data), "\n";

will give you this:

   {"array"}[0]:"what"
   {"array"}[1]:"ever"
   {"array"}[2]{"empty"}:[]
   {"array"}[2]{"inner"}:"part"
   {"false"}:false
   {"four"}:"4.0"
   {"hash"}{"ar"}[0]:1
   {"hash"}{"ar"}[1]:2
   {"hash"}{"ar"}[2]:3
   {"hash"}{"something"}:"funny \u263A \u263B"
   {"hash"}{"with \u265C"}:{}
   {"one"}:"1"
   {"three"}:3.1
   {"true"}:true
   {"two"}:2

Now it should pretty easy for a shell program to get at the
data, e.g. with this C<sed> substitution:

   sed -ne 's/^{"hash"}{"ar"}\[2\]://p'

=head2 Profiles

If you don't like the default encoding, you can get a different
one by using a I<profile>. This is a set of configurations for
C<Data::Crumbr::Default>, which is a pretty generic class for
representing a wide class of possible record-oriented encodings.

A C<Data::Crumbr::Default> encoder is defined in terms of the following
parameters:

=over

=item C<array_open>

sequence to put when an array is opened

=item C<array_close>

sequence to put when an array is closed

=item C<array_key_prefix>

sequence to put before an array's index

=item C<array_key_suffix>

sequence to put after an array's index

=item C<array_key_encoder>

a reference to a function that encodes an array's index

=item C<hash_open>

sequence to put when a hash is opened

=item C<hash_close>

sequence to put when a hash is closed

=item C<hash_key_prefix>

sequence to put before a hash's key

=item C<hash_key_suffix>

sequence to put after a hash's key

=item C<hash_key_encoder>

a reference to a function that encodes a hash's key

=item C<value_encoder>

a reference to a function that encodes a leaf value

=item C<keys_separator>

sequence to separate the keys breadcrumb

=item C<value_separator>

sequence to separate the keys from the value

=back

By default, Data::Crumbr ships with the following profiles:

=over

=item B<< Default >>

i.e. the profile you get by default, and what you saw in action in the
example above. It has the following settings:

=over

=item *

no openers and closers:

   array_open  => ''
   array_close => ''
   hash_open   => ''
   hash_close  => ''

=item *

array keys are printed verbatim, surrounded by square brackets:

   array_key_prefix  => '['
   array_key_suffix  => ']'
   array_key_encoder => Data::Crumbr::Util::id_encoder

=item *

hash keys encoded as JSON strings, surrounded by curly brackets:

   hash_key_prefix   => '['
   hash_key_suffix   => ']'
   hash_key_encoder  => Data::Crumbr::Util::json_leaf_encoder

=item *

no separator between keys (because they already stand out very clearly,
but a colon to separate the sequence of keys from the value:

   keys_separator  => ''
   value_separator => ':'

=item *

leaf values encoded as JSON scalars:

   value_encoder => Data::Crumbr::Util::json_leaf_encoder

=back

This is quite verbose, but lets you specify very precisely what you are
looking for because the hash keys stand out clearly with respect to
array identifiers, i.e. there's no chance that you will mistake an array
index for a hash key (because they are embedded in different bracket
types).

=item B<< JSON >>

this profile always provides you compact JSON-compliant string
representations that contain only one single leaf value.

It has the following characteristics:

=over

=item *

openers and closers are what you would expect for JSON objects and
arrays:

   array_open  => '['
   array_close => ']'
   hash_open   => '{'
   hash_close  => '}'

=item *

there is only one non-empty suffix, i.e. the hash key suffix, so that
we can separate the hash key from the value with C<:> according to JSON:

   array_key_prefix => ''
   array_key_suffix => ''
   hash_key_prefix  => ''
   hash_key_suffix  => ':'

=item *

array keys are not printed:

   array_key_encoder => sub { }

=item *

hash keys are JSON encoded:

   hash_key_encoder  => Data::Crumbr::Util::json_encoder()

=item *

no separators are needed:

   keys_separator  => ''
   value_separator => ''

=item *

leaf values encoded as JSON scalars:

   value_encoder => Data::Crumbr::Util::json_leaf_encoder

=back

=item B<< URI >>

this is the simplest of the profiles, and sacrifices the possibility to
distinguish between hash and array keys to the altar of simplicity.

It has the following characteristics:

=over

=item *

no openers, closers, prefixes or suffixes:

   array_open  => ''
   array_close => ''
   array_key_prefix => ''
   array_key_suffix => ''

   hash_open   => ''
   hash_close  => ''
   hash_key_prefix => ''
   hash_key_suffix => ''

=item *

array keys are printed verbatim

=item *

hash keys are URI encoded

   hash_key_encoder  => Data::Crumbr::Util::uri_encoder

=item *

keys are separated by a slash character C</> and values are separated by
a single space C< >:

   keys_separator  => '/'
   value_separator => ' '

=item *

leaf values encoded as JSON scalars:

   value_encoder => Data::Crumbr::Util::json_leaf_encoder

=back

=back

=head1 INTERFACE

There are two ways to use Data::Crumber: a function C<crumbr>,
that is exported by default, and the object-oriented interface.

=over

=item B<< crumbr >>

   $subref = crumbr(%args); # OR
   $subref = crumbr(\%args);

get a I<crumbr> generator based on provided C<%args>.

Returns a reference to a sub, which can then be called upon a data
structure in order to get the I<crumbed> version.

The input arguments can be:

=over

=item C<< encoder >>

details about the encoder, see L</Profiles> for the available key-value
pairs. In addition, you can also set the following:

=over

=item C<< output >>

the output channel to use for sending encoded data. This can be:

=over

=item * I<filename>

this will be opened in raw mode and used to send the output

=item * I<filehandle>

used directly

=item * I<array reference>

each output line will be pushed as a new element in the array

=item * I<object reference>

which is assumed to support the C<print()> method, that will be called
with each generated line

=item * I<sub reference>

which will be called with each generated line

=back

=back

=item C<< profile >>

the name of a profile to use as a base - see L</Profiles>. Settings in
the profile are always overridden by corresponding ones in the provided
encoder, if any.

=back

=item B<< encode >>

   $dc->encode($data_structure);

generate the encoding for the provided C<$data_structure>. Output is
generated depending on how it is specified, see L</crumbr> above.

=item B<< new >>

   my $dc = Data::Crumber->new(encoder => \%args);

create a new instance of C<Data::Crumbr>. Data provided for the
C<encoder> parameter (i.e. C<%args>) are those discussed in
L</Profiles>.

The new instance can then be used to encode data using the C</encode>
method.

=back

=head1 AUTHOR

Flavio Poletti <polettix@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Flavio Poletti <polettix@cpan.org>

This module is free software.  You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
