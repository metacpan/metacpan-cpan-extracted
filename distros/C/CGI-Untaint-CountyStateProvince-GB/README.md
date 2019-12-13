CGI-Untaint-CountyStateProvince-GB
==================================

[![Linux Build Status](https://travis-ci.org/nigelhorne/CGI-Untaint-CountyStateProvince-GB.svg?branch=master)](https://travis-ci.org/nigelhorne/CGI-Untaint-CountyStateProvince-GB)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/xbcdo4fx8onmoohf/branch/master?svg=true)](https://ci.appveyor.com/project/nigelhorne/cgi-untaint-countystateprovince-gb/branch/master)
[![Dependency Status](https://dependencyci.com/github/nigelhorne/CGI-Untaint-CountyStateProvince-GB/badge)](https://dependencyci.com/github/nigelhorne/CGI-Untaint-CountyStateProvince-GB)

# NAME

CGI::Untaint::CountyStateProvince::GB - Add British counties to CGI::Untaint::CountyStateProvince tables

# VERSION

Version 0.12

# SYNOPSIS

Adds a list of British counties to the list of counties/state/provinces
which are known by the CGI::Untaint::CountyStateProvince validator so that
an HTML form sent by CGI contains a valid county.

You must include CGI::Untaint::CountyStateProvince::GB after including
CGI::Untaint, otherwise it won't work.

    use CGI::Info;
    use CGI::Untaint;
    use CGI::Untaint::CountyStateProvince::GB;
    my $info = CGI::Info->new();
    my $u = CGI::Untaint->new($info->params());
    # Succeeds if state = 'Kent', fails if state = 'Queensland';
    $u->extract(-as_CountyStateProvince => 'state');
    # ...

# SUBSOUTINES/METHODS

## is\_valid

Validates the data. See CGI::Untaint::is\_valid.

## value

Sets the raw data which is to be validated.  Called by the superclass, you
are unlikely to want to call it.

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

Please report any bugs or feature requests to `bug-cgi-untaint-csp-gb at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Untaint-CountyStateProvince](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Untaint-CountyStateProvince).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SEE ALSO

CGI::Untaint::CountyStateProvince, CGI::Untaint

# SUPPORT

You can find documentation for this module with the perldoc command.

        perldoc CGI::Untaint::CountyStateProvince::GB

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Untaint-CountyStateProvince-GB](http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Untaint-CountyStateProvince-GB)

- CPAN Ratings

    [http://cpanratings.perl.org/d/CGI-Untaint-CountyStateProvince-GB](http://cpanratings.perl.org/d/CGI-Untaint-CountyStateProvince-GB)

- Search CPAN

    [http://search.cpan.org/dist/CGI-Untaint-CountyStateProvince-GB](http://search.cpan.org/dist/CGI-Untaint-CountyStateProvince-GB)

# ACKNOWLEDGEMENTS

# LICENSE AND COPYRIGHT

Copyright 2012-19 Nigel Horne.

This program is released under the following licence: GPL2
