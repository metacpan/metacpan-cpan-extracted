[![Actions Status](https://github.com/nigelhorne/Data-Fetch/workflows/.github/workflows/all.yml/badge.svg)](https://github.com/nigelhorne/Data-Fetch/actions)
[![Travis Status](https://travis-ci.org/nigelhorne/Data-Fetch.svg?branch=master)](https://travis-ci.org/nigelhorne/Data-Fetch)
[![Appveyor Status](https://ci.appveyor.com/api/projects/status/1t1yhvagx00c2qi8?svg=true)](https://ci.appveyor.com/project/nigelhorne/cgi-info)
[![Appveyor status](https://ci.appveyor.com/api/projects/status/uexrsduxn2yk58on/branch/master?svg=true)](https://ci.appveyor.com/project/nigelhorne/data-fetch/branch/master)
[![Coveralls Status](https://coveralls.io/repos/github/nigelhorne/Data-Fetch/badge.svg?branch=master)](https://coveralls.io/github/nigelhorne/Data-Fetch?branch=master)
[![CPAN](https://img.shields.io/cpan/v/Data-Fetch.svg)](http://search.cpan.org/~nhorne/Data-Fetch/)
[![Kritika Analysis Status](https://kritika.io/users/nigelhorne/repos/5642353356298438/heads/master/status.svg)](https://kritika.io/users/nigelhorne/repos/5642353356298438/heads/master/)
[![Kwalitee](https://cpants.cpanauthors.org/dist/Data-Fetch.png)](http://cpants.cpanauthors.org/dist/Data-Fetch)

# NAME

Data::Fetch - give advance warning that you'll be needing a value

# VERSION

Version 0.06

# SYNOPSIS

Sometimes we know in advance that we'll be needing a value which is going to take a long time to compute or determine.
This module fetches the value in the background so that you don't need to wait so long when you need the value.

    use CalculatePi;
    use Data::Fetch;
    my $fetcher = Data::Fetch->new();
    my $pi = CalculatePi->new(places => 1000000);
    $fetcher->prime(object => $pi, message => 'as_string');     # Warn we'll run $pi->as_string() in the future
    # Do other things
    print $fetcher->get(object => $pi, message => 'as_string'), "\n";   # Runs $pi->as_string()

# SUBROUTINES/METHODS

## new

Creates a Data::Fetch object.  Takes no argument.

## prime

Say what is is you'll be needing later.
Call in an array context if get() is to be used in an array context.

Takes two mandatory parameters:

    object - the object you'll be sending the message to
    message - the message you'll be sending

Takes one optional parameter:

    arg - passes this argument to the message

## get

Retrieve get a value you've primed.
Call in an array context only works if prime() was called in an array context, or the value wasn't primed

Takes two mandatory parameters:

    object - the object you'll be sending the message to
    message - the message you'll be sending

Takes one optional parameter:

    arg - passes this argument to the message

If you don't prime it will still work and store the value for subsequent calls,
but in this scenerio you gain nothing over using CHI to cache your values.

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

Can't pass more than one argument to the message.

I would not advise using this to call messages that change values in the object.

Changing a value between prime and get will not necessarily get you the data you want. That's the way it works
and isn't going to change.

If you change a value between two calls of get(), the earlier value is always used.  This is definitely a feature
not a bug.

Please report any bugs or feature requests to `bug-data-fetch at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Fetch](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Fetch).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SEE ALSO

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Fetch

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/release/Data-Fetch](https://metacpan.org/release/Data-Fetch)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Fetch](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Fetch)

- CPANTS

    [http://cpants.cpanauthors.org/dist/Data-Fetch](http://cpants.cpanauthors.org/dist/Data-Fetch)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Data-Fetch](http://matrix.cpantesters.org/?dist=Data-Fetch)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Data-Fetch](http://cpanratings.perl.org/d/Data-Fetch)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Data::Fetch](http://deps.cpantesters.org/?module=Data::Fetch)

# LICENSE AND COPYRIGHT

Copyright 2010-2020 Nigel Horne.

This program is released under the following licence: GPL2
