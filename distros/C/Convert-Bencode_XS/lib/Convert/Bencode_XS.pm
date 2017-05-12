package Convert::Bencode_XS;

use 5.006;
use strict;

our $VERSION = '0.06';

use Carp;
use base qw(Exporter DynaLoader);

__PACKAGE__->bootstrap($VERSION);

our @EXPORT_OK = qw(&bencode &bdecode &cleanse $COERCE);
our %EXPORT_TAGS = (
    all     => \@EXPORT_OK,
    code    =>  [qw(&bencode &bdecode)],
);

our $COERCE = 1;

=head1 NAME

Convert::Bencode_XS - Faster conversions to/from Bencode format

=head1 SYNOPSIS

 use Convert::Bencode_XS qw(bencode bdecode);
 use Data::Dumper;
 
 print "Serializing:\n", bencode([123, [''], "XXX"]), "\n\n";
 
 print Dumper bdecode('d3:fool3:bar4:stube6:numberi123ee');

 __END__
 Serializing:
 li123el0:e3:XXXe

 $VAR1 = {
   'number' => '123',
   'foo' => [
               'bar',
               'stub'
            ]
 };
  

=head1 DESCRIPTION

=over 4

=item bencode($stuff)

Returns a bencoded string representing what's in $stuff. $stuff can be
either a scalar, an array reference or a hash reference. Every nesting of
these data structures is allowed, other ones will croak.

=item bdecode($bencoded)

Returns a Perl data structure: it could be either a scalar, array reference
or hash reference depending on what's in $bencoded. Dictionaries are 
converted in hashes, lists in arrays, scalars in strings. 
If $COERCE (see below) is set
to a false value then scalars encoded like integers will be cleanse() before
being returned so that a re-serialization of the structure will give back
exactly the same bencoded string.

=back

=head1 TO COERCE AND TO CLEANSE

Read on just if you are having problems serializing some data using this module:
it should work "as is" for 99% of cases. But if you're unlucky enough
maybe you need to read this chapter.

The original definition of the Bencode protocol poses some problems 
when ported to
languages other than Python, cause: 

1) there is a distinction between integers and strings 

2) integers are allowed to be any length. 

This is kinda contradictory so we have to come up with specialized 
solutions to serialize certain types of data. For instance, strings that
looks like integers. This is cause there is little distinction between the two
in Perl. So, by default, bencode() will serialize all strings that looks like
integers as integers. Example: 

 print bencode("123");
 # outputs "i123e"

If you don't want this to happen you can do this:

 $Convert::Bencode_XS::COERCE = 0; #this is 1 by default
 print bencode("123");
 # outputs "3:123"

Setting $Convert::Bencode_XS::COERCE to a false value will serialize everything
that is a string as a string. But what about numbers? If they are hardcoded
into your program
there should be no problem. Otherwise you need to cleanse them. Example:

 use Convert::Bencode_XS qw(:all); # imports also cleanse() and $COERCE
 
 $COERCE = 0;

 print bencode(123);
 # outputs "i123e"
 
 my ($num) = "abc123def" =~ /(\d+)/;
 print bencode($num);
 # outputs "3:123", but we know it is a number!
 cleanse($num);  #  cleanse() to the rescue!
 print bencode($num);
 # outputs "i123e"

Problems may arise if you want to use a arbitrary sequence of integers as
a real integer, mainly because it could surpass the maximum allowed by
your platform. (At the moment there is no solution for that). See the tests
in this distribution to have a better idea of what works and what not.

=head1 WHY?

Convert::Bencode_XS exists for a couple of reasons, first of all performance.
Especially bdecode() is between 10 and 200 times faster than 
Convert::Bencode version (depending on file): 
the great speed increase is in part due to the iterative
algorithm used. bencode() is written in C for better performance, but
it still uses a recursive algorithm. It manages to be
around 3 to 5 times faster than Convert::Bencode version.
Check out the "extras" directory in this distribution for benchmarks.

The second reason is fun and i wished to try out something i learnt about XS
programming.

=head1 BUGS

=head2 In bencode()

- No detection of recursive references yet

Next come not real BUGS but more liberal interpretation of the protocol:

- Hashes keys are forced to be strings. So if we find a number we don't
croak, but we use it as a string.

- Strings like "007" will be treated as strings and encoded as such


=head1 SEE ALSO

The Bencode format is described at 
http://bitconjurer.org/BitTorrent/protocol.html

The original Python bencode and bdecode functions can be found in file
bencode.py in the BitTorrent sources.

See also Convert::Bencode by R. Kyle Murphy for a PurePerl implementation.

=head1 AUTHOR

Giulio Motta, E<lt>giulienk@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003-2006 by Giulio Motta

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
