[![Linux Build Status](https://travis-ci.org/nigelhorne/CGI-ACL.svg?branch=master)](https://travis-ci.org/nigelhorne/CGI-ACL)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/5wa2lsb6c86x9jp0?svg=true)](https://ci.appveyor.com/project/nigelhorne/cgi-acl)
[![Dependency Status](https://dependencyci.com/github/nigelhorne/CGI-ACL/badge)](https://dependencyci.com/github/nigelhorne/CGI-ACL)
[![Coverage Status](https://coveralls.io/repos/github/nigelhorne/CGI-ACL/badge.svg?branch=master)](https://coveralls.io/github/nigelhorne/CGI-ACL?branch=master)

# CGI::ACL

Decide whether to allow a client to run this script

# VERSION

Version 0.02

# SYNOPSIS

Does what it says on the tin.

    use CGI::Info;
    use CGI::ACL;

    my $acl = CGI::ACL->new();
    # ...
    my $denied = $acl->all_denied(info => CGI::Info->new());

# SUBROUTINES/METHODS

## new

Creates a CGI::ACL object.

## allow\_ip

Give an IP (or CIDR) that we allow to connect to us

    use CGI::ACL;

    # Allow Google to connect to us
    my $acl = CGI::ACL->new()->allow_ip(ip => '8.35.80.39');

## deny\_country

Give a country, or a reference to a list of countries, that we will not allow to access us

    use CGI::ACL;

    # Don't allow the UK to connect to us
    my $acl = CGI::ACL->new()->deny_country('UK');

## all\_denied

If any of the restrictions return false, return false, which should allow access

    use CGI::Info;
    use CGI::Lingua;
    use CGI::ACL;

    # Allow Google to connect to us
    my $acl = CGI::ACL->new()->allow_ip(ip => '8.35.80.39');

    if($acl->all_denied(info => CGI::Info->new())) {
        print 'You are not allowed to view this site';
        return;
    }

    $acl = CGI::ACL->new()->deny_country(country => 'br');

    if($acl->all_denied(lingua => CGI::Lingua->new(supported => ['en']))) {
        print 'Brazilians cannot view this site for now';
        return;
    }

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

Please report any bugs or feature requests to `bug-cgi-acl at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-ACL](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-ACL).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SEE ALSO

[CGI::Info](https://metacpan.org/pod/CGI::Info)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::ACL

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-ACL](http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-ACL)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/CGI-ACL](http://annocpan.org/dist/CGI-ACL)

- CPAN Ratings

    [http://cpanratings.perl.org/d/CGI-ACL](http://cpanratings.perl.org/d/CGI-ACL)

- Search CPAN

    [http://search.cpan.org/dist/CGI-ACL/](http://search.cpan.org/dist/CGI-ACL/)

# LICENSE AND COPYRIGHT

Copyright 2017 Nigel Horne.

This program is released under the following licence: GPL
