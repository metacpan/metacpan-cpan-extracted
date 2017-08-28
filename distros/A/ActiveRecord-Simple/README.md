ActiveRecord::Simple
====================

ActiveRecord::Simple - Simple to use lightweight implementation of ActiveRecord pattern.

It is fast, don't have any dependencies and realy easy to use.

The basic setup of your package should be:

    package Model::Foo;

    use base 'ActiveRecord::Simple';

    __PACKAGE__->table_name('foo');
    __PACKAGE__->columns(['id', 'bar', 'baz']);
    __PACKAGE__->primary_key('id');

    1;

And then, you can use your package in a program:

    use Foo;

    my $foo = Foo->new({ bar => 'value', baz => 'value' });
    $foo->save();

    # or
    my $foo = Foo->get(1);
    say $foo->bar;

    # or
    $foo->bar('new value')->save();

    say $foo->bar;

That's it. ActiveRecord::Simple provides a variety of techniques to make your work with
data little easier. It contains only a basic set of operations, such as
search, create, update and delete data.

See pod documentation of the module for more information about using
ActiveRecord::Simple.

What we've got?
===============

Flexible search

    Person->find(1); # by ID
    Person->find([1, 2, 3]); # by several ID's
    Person->find({ name => 'Foo' }); # by parameters
    Person->find({ city => City->find({name => 'Paris'})->fetch }); # parameters as an objects
    Person->find('name = ? OR lastname = ?', 'Foo', 'Bar'); # by condition

    Person->last;
    Person->first;

Easy fetch

    # Just one object:
    my $bill = Person->find({ name => 'Bill' })->fetch;

    # Only 3 objects:
    my @list = Person->find('age > ?', 21)->fetch(3);

    # All objects:
    my @list = Person->find->fetch;

    # Even more:
    while (my $person = Person->find->fetch) {
        say $person->name;
    }

Simple ordering:

    Person->find->order_by('name');
    Person->find->order_by('name', 'last_name');
    Person->find->order_by('name')->desc;

Limit, Offset:

    Person->find->limit(3);
    Person->find->offset(10);
    Person->find->limit(3)->offset(12);

Left joins:

    my $person = Person->find->with('misc_info')->fetch;
    say $person->name;
    say $person->misc_info->zip;

And, of course, all of this together:

    my $new_customer =
        Person->find
              ->only('name')
              ->oreder_by('date_register')
              ->desc
              ->limit(1)
              ->with('misc_info', 'payment_info')
              ->fetch;

    say $new_customer->name;
    say $new_customer->misc_info->zip;
    say $new_customer->payment_info->last_payment;

Also one-to-one, one-to-many, many-to-one and many-to-many relations, smart_saving and even more.

And, of course, you don't need use "table_name", "primary_key" etc. Just use this:

    __PACKAGE__->load_info(); ### All info will be loaded from database automatically.

Check it out!


INSTALLATION
============

To install this module, run the following commands:

	$ perl Makefile.PL
	$ make
	$ make test
	$ make install

or:

        $ sudo cpan ActiveRecord::Simple

SUPPORT AND DOCUMENTATION
=========================

After installing, you can find documentation for this module with the
perldoc command.

    perldoc ActiveRecord::Simple

Feel free to join us at google groups:
https://groups.google.com/forum/#!forum/activerecord-simple

Also the github page:
http://shootnix.github.io/activerecord-simple/

LICENSE AND COPYRIGHT
=====================

Copyright (C) 2013-2017 shootnix

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

CREDITS
=======

@shootnix
@kberov
@chorny
@lifeofguenter
@neilbowers
@dsteinbrunner
@reindeer
@grinya007