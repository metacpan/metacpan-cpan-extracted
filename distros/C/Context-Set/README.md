# NAME

Context - A preference manager.

# INTRODUCTION

Context is a preference manager that aims at solving the problem of storing configuration properties accross
an ever growing collection of contexts that often characterises enterprise systems.

For instance, you might want to have a 'page colour' setting that is global to your system,
but allow users to choose their own if they want.

Additionally, you might want to allow your users to specifically define a page color when
they view a specific 'list of stuff' in your system. Or allow the system to specify a page color
for all lists, or a specific one to certain lists, but still allowing users to override that.

Multiplication of preferences and management of their priorities can cause a lot of confusion
and headaches. This module is an attempt to help you to keep those things tidy and in control.

# SYNOPSIS

To use Context, the best way is probably to use a Context::Manager that will
keep your contexts tidy for you.

    my $cm = Context::Manager->new();
    $cm->universe()->set\_property('page.colour' , 'blue');

    my $users = $cm->restrict('users');
    $users->set\_property('page.colour', 'green');

    my $user1 = $cm->restrict('users' , 1);
    $user1->set\_property('page.colour' , 'red');



    $user1->get\_property('page.colour'); # red

    my $user2 = $cm->restrict('users' , 2);
    $user2->get\_property('page.colour') ; # green

    my $lists = $cm->restrict('lists');
    my $list1 = $cm->restrict->($lists, 1);

    my $u1l1 = $cm->unite($user1, list1);
    $u1l1->set\_property('page.colour', 'purple');

    $u1l1->get\_property('page.colour'); # purple

    my $u1l2 = $cm->unite($user1 , $cm->restrict('lists' , 2));
    $u1l2->get\_property('page.colour') ; # red

# VERSION

Version 0.01

## fullname

Returns the fully qualified name of this context. The fullname of a context identifies the context
in the UNIVERSE in a unique manner.

## restrict

Produces a new Context::Restriction of this one.

Usage:

    ## Restrict to all users.
    my $context = $this->restrict('users');

    ## Further restriction to user 1
    $context = $context->restrict('1');

## unite

Returns the Context::Union of this and the other context.

usage:

    my $u = $this->unite($other\_context);

## set_property

Sets the given property to the given value. Never dies.

Usage:

    $this->set\_property('pi' , 3.14159 );
    $this->set\_property('fibo', [ 1, 2, 3, 5, 8, 12, 20 ]);



## get_property

Gets the property that goes by the given name. Dies if no property with the given name can be found.

my $pi = $this->get\_property('pi');

## has_property

Returns true if there is a property of this name in this context.

Usage:

    if( $this->has\_property('pi') ){
       ...
    }

# AUTHOR

Jerome Eteve, `<jerome.eteve at gmail.com>`

# BUGS

Please report any bugs or feature requests to `bug-context at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Context](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Context).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Context



You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

[http://rt.cpan.org/NoAuth/Bugs.html?Dist=Context](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Context)

- AnnoCPAN: Annotated CPAN documentation

[http://annocpan.org/dist/Context](http://annocpan.org/dist/Context)

- CPAN Ratings

[http://cpanratings.perl.org/d/Context](http://cpanratings.perl.org/d/Context)

- Search CPAN

[http://search.cpan.org/dist/Context/](http://search.cpan.org/dist/Context/)

# LICENSE AND COPYRIGHT

Copyright 2012 Jerome Eteve.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

