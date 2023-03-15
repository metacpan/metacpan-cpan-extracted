[![Kwalitee](https://cpants.cpanauthors.org/dist/Class-Simple-Readonly-Cached.png)](http://cpants.cpanauthors.org/dist/Class-Simple-Readonly-Cached)
[![Tweet](https://img.shields.io/twitter/url/http/shields.io.svg?style=social)](https://twitter.com/intent/tweet?text=Cache+messages+to+an+object+#perl&url=https://github.com/nigelhorne/class-simple-readonly-cached&via=nigelhorne)

# NAME

Class::Simple::Readonly::Cached - cache messages to an object

# VERSION

Version 0.09

# SYNOPSIS

A sub-class of [Class::Simple](https://metacpan.org/pod/Class%3A%3ASimple) which caches calls to read
the status of an object that are otherwise expensive.

It is up to the caller to maintain the cache if the object comes out of sync with the cache,
for example by changing its state.

You can use this class to create a caching layer to an object of any class
that works on objects which doesn't change its state based on input:

      use Class::Simple::Readonly::Cached;

      my $obj = Class::Simple->new();
      $obj->val('foo');
      $obj = Class::Simple::Readonly::Cached->new(object => $obj, cache => {});
      my $val = $obj->val();
      print "$val\n";     # Prints "foo"
    
      #... set $obj to be some other class which will take an argument 'a',
      #   with a value 'b'
    
      $val = $obj->val(a => 'b'); # You

# SUBROUTINES/METHODS

## new

Creates a Class::Simple::Readonly::Cached object.

It takes one mandatory parameter: cache,
which is either an object which understands clear(), get() and set() calls,
such as an [CHI](https://metacpan.org/pod/CHI) object;
or is a reference to a hash where the return values are to be stored.

It takes one optional argument: object,
which is an object which is taken to be the object to be cached.
If not given, an object of the class [Class::Simple](https://metacpan.org/pod/Class%3A%3ASimple) is instantiated
and that is used.

    use Gedcom;

    my %hash;
    my $person = Gedcom::Person->new();
    ... # Set up some data
    my $object = Class::Simple::Readonly::Cached(object => $person, cache => \%hash);
    my $father1 = $object->father();    # Will call gedcom->father() to get the person's father
    my $father2 = $object->father();    # Will retrieve the father from the cache without calling person->father()

Takes one optional argument: quiet,
if you attempt to cache an object that is already cached, rather than create
another copy you receive a warning and the previous cached copy is returned.
The 'quiet' option, when non-zero, silences the warning.

## object

Return the encapsulated object

## state

Returns the state of the object

    print Data::Dumper->new([$obj->state()]->Dump();

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

Doesn't work with [Memoize](https://metacpan.org/pod/Memoize).

Please report any bugs or feature requests to [https://github.com/nigelhorne/Class-Simple-Readonly-Cached/issues](https://github.com/nigelhorne/Class-Simple-Readonly-Cached/issues).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SEE ALSO

[Class::Simple](https://metacpan.org/pod/Class%3A%3ASimple), [CHI](https://metacpan.org/pod/CHI)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class::Simple::Readonly::Cached

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/release/Class-Simple-Readonly-Cached](https://metacpan.org/release/Class-Simple-Readonly-Cached)

- Source Repository

    [https://github.com/nigelhorne/Class-Simple-Readonly-Cached](https://github.com/nigelhorne/Class-Simple-Readonly-Cached)

- CPANTS

    [http://cpants.cpanauthors.org/dist/Class-Simple-Readonly-Cached](http://cpants.cpanauthors.org/dist/Class-Simple-Readonly-Cached)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Class-Simple-Readonly-Cached](http://matrix.cpantesters.org/?dist=Class-Simple-Readonly-Cached)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Class-Simple-Readonly-Cached](http://cpanratings.perl.org/d/Class-Simple-Readonly-Cached)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Class::Simple::Readonly::Cached](http://deps.cpantesters.org/?module=Class::Simple::Readonly::Cached)

- Search CPAN

    [http://search.cpan.org/dist/Class-Simple-Readonly-Cached/](http://search.cpan.org/dist/Class-Simple-Readonly-Cached/)

# LICENSE AND COPYRIGHT

Author Nigel Horne: `njh@bandsman.co.uk`
Copyright (C) 2019-2023 Nigel Horne

Usage is subject to licence terms.
The licence terms of this software are as follows:
Personal single user, single computer use: GPL2
All other users (including Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at the
above e-mail.
