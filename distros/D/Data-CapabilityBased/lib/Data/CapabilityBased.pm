package Data::CapabilityBased;

use strict;
use warnings;

our $VERSION = '0.001000';

=head1 NAME

Data::CapabilityBased - Ask your data not what it is, but what it can do for your program

=head1 SYNOPSIS

  use Data::Store;
  use Data::Collection;
  use Data::Stream;
  use Data::Query;

=head1 DESCRIPTION

The Data::CapabilityBased module itself is, and will always be, an empty
placeholder providing an overview of the concepts of the project and links
to the known distributions making use of this code. Sub namespaces of this
module will likely contain helper modules to ease bla blah finish this bit
when we find out if we need them.

This distribution is uploaded in the absence of code in order to function
as a central point to document the design of the capabilities as we flesh
them out and start building the compliance suites; please see the
L<Data::Store>, L<Data::Collection>, L<Data::Stream>, L<Data::Query> for
the progress made so far towards this.

=head1 MANIFESTO

The principle behind this system is: when you're being passed something that's
being treated as simply data, you shouldn't be thinking about -what- you've
been passed but merely whether you can use it in the manner you need to. So,
to pick an example I deal with every day, you have code that needs to process
a set of objects. Think -

  method do_something ($to) {
    foreach my $target (@$to) {
      $to->frotz;
    }
  }

Now, of course, this is great if $to is an arrayref. But otherwise you're in
trouble. So, you think "hey, I'll add a type check:" 

  method do_something ($to) {
    confess "Dammit, Jim, I'm a deckchair not an osculator"
      unless ref($to) eq 'ARRAY';
    ...
    
But now what happens if it's an object that arrayifies? BOOM. (a good example
of this from my world would be a DBIx::Class::ResultSet). 

Well. We could test it's something that arrayifies:

  method do_something ($to) {
    confess "Out of Cleese error. Call stack has Goon away."
      unless (ref($to) eq 'ARRAY' || (blessed($to) && $to->can('(@{}')));
    ...

but for a start that's really ugly, and more importantly it only handles
the case that we want to do @$to. Which is probably fine, except now we're
going to slurp whatever contents of that resultset were into memory at once.
If it contains a million records, we just made your computer cry (and probably
your sysadmin developercidal).

So, what's a better approach? Well, what if we could say to our data "hey,
I know you're capable of returning me a series of objects, but I really just
want to run something on all of them" - so, something like

  method do_something ($to) {
    $to->each(sub { $_->frotz });
  }

but then how do we know if this is something that can provide a suitable
each method ... and what do we do about plain arrayrefs, which don't have
methods at all? Well, given autoboxing can provide an ->each method on an
arrayref, we can do something like:

  use Data::Collection::Capabilities qw(Eachable);
  use Data::Collection::Autobox;

  method do_something (Eachable $to) {

and then an arrayref will be automatically autoboxed with an ->each method
that supports this interface, and report that it provides the capability, and
a collection object that declares its capabilities will pass the type test
as well.

=head1 AUTHOR

  Matt S. Trout (mst) <mst@shadowcat.co.uk> http://www.shadowcat.co.uk/

=head1 LICENSE

This library is free software under the same license as perl itself.

=cut
