CGI-Untaint-CountyStateProvince-US
==================================

[![Linux Build Status](https://travis-ci.org/nigelhorne/CGI-Untaint-CountyStateProvince-US.svg?branch=master)](https://travis-ci.org/nigelhorne/CGI-Untaint-CountyStateProvince-US)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/8tnjroo7inoa65fk/branch/master?svg=true)](https://ci.appveyor.com/project/nigelhorne/cgi-untaint-countystateprovince-us/branch/master)
[![Dependency Status](https://dependencyci.com/github/nigelhorne/CGI-Untaint-CountyStateProvince-US/badge)](https://dependencyci.com/github/nigelhorne/Untaint-CountyStateProvince-US-Info)
[![Coverage Status](https://coveralls.io/repos/github/nigelhorne/CGI-Untaint-CountyStateProvince-US/badge.svg?branch=master)](https://coveralls.io/github/nigelhorne/CGI-Untaint-CountyStateProvince-US?branch=master)

# NAME

CGI::Untaint::CountyStateProvince::US - Add U.S. states to CGI::Untaint::CountyStateProvince tables

# VERSION

Version 0.05

# SYNOPSIS

The module validates that a given input,
represents a valid U.S. state.
It supports both full state names (e.g., "Maryland") and two-letter state abbreviations (e.g., "MD").

Adds a list of U.S. states to the list of counties/states/provinces
which are known by the CGI::Untaint::CountyStateProvince validator allowing you
to verify that a field in an HTML form contains a valid U.S. state.

You must include CGI::Untaint::CountyStateProvince::US after including
CGI::Untaint, otherwise it won't work.

    use CGI::Info;
    use CGI::Untaint;
    use CGI::Untaint::CountyStateProvince::US;
    my $info = CGI::Info->new();
    my $u = CGI::Untaint->new($info->params());
    # Succeeds if state = 'MD' or 'Maryland', fails if state = 'Queensland';
    $u->extract(-as_CountyStateProvince => 'state');
    # ...

# SUBROUTINES/METHODS

## is\_valid

Validates the data, setting the data to be the two-letter abbreviation for the
given state.  See CGI::Untaint::is\_valid.

## value

Sets the raw data to be validated.
Called by the superclass,
you are unlikely to want to call it.

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

Only two-letter abbreviations are allowable,
so 'Mass' won't work for Massachusetts.

Please report any bugs or feature requests to `bug-cgi-untaint-csp-us at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Untaint-CountyStateProvince](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Untaint-CountyStateProvince).
I will be notified,
and then you'll automatically be notified of the progress of your bug as I make changes.

# SEE ALSO

[CGI::Untaint::CountyStateProvince](https://metacpan.org/pod/CGI%3A%3AUntaint%3A%3ACountyStateProvince), [CGI::Untaint](https://metacpan.org/pod/CGI%3A%3AUntaint), [Locale::SubCountry](https://metacpan.org/pod/Locale%3A%3ASubCountry)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Untaint::CountyStateProvince::US

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Untaint-CountyStateProvince-US](http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Untaint-CountyStateProvince-US)

- Search CPAN

    [http://search.cpan.org/dist/CGI-Untaint-CountyStateProvince-US](http://search.cpan.org/dist/CGI-Untaint-CountyStateProvince-US)

# ACKNOWLEDGEMENTS

# LICENSE AND COPYRIGHT

Copyright 2012-2025 Nigel Horne.

This program is released under the following licence: GPL2
