[![Travis Status](https://travis-ci.org/nigelhorne/CGI-ACL.svg?branch=master)](https://travis-ci.org/nigelhorne/CGI-ACL)
[![Appveyor status](https://ci.appveyor.com/api/projects/status/5wa2lsb6c86x9jp0?svg=true)](https://ci.appveyor.com/project/nigelhorne/cgi-acl)
[![Coveralls Status](https://coveralls.io/repos/github/nigelhorne/CGI-ACL/badge.svg?branch=master)](https://coveralls.io/github/nigelhorne/CGI-ACL?branch=master)
[![CPAN](https://img.shields.io/cpan/v/CGI-ACL.svg)](http://search.cpan.org/~nhorne/CGI-ACL/)
[![Kritika Analysis Status](https://kritika.io/users/nigelhorne/repos/5642353356298438/heads/master/status.svg)](https://kritika.io/users/nigelhorne/repos/5642353356298438/heads/master/)
[![Kwalitee](https://cpants.cpanauthors.org/dist/CGI-ACL.png)](http://cpants.cpanauthors.org/dist/CGI-ACL)

# NAME

CGI::ACL - Decide whether to allow a client to run this script

# VERSION

Version 0.04

# SYNOPSIS

Does what it says on the tin.

    use CGI::Lingua;
    use CGI::ACL;

    my $acl = CGI::ACL->new();
    # ...
    my $denied = $acl->all_denied(info => CGI::Lingua->new(supported => 'en'));

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
    my $acl = CGI::ACL->new()->deny_country('GB');

    # Don't allow any countries to connect to us (a sort of 'default deny')
    my $acl = CGI::ACL->new()->deny_country('*');

## allow\_country

Give a country, or a reference to a list of countries, that we will allow to access us

    use CGI::ACL;

    # Allow only the UK and US to connect to us
    my @allow_list = ('GB', 'US');
    my $acl = CGI::ACL->new()->deny_country('*')->allow_country(country => \@allow_list);

## all\_denied

If any of the restrictions return false then return false, which should allow access.
Note that by default localhost isn't allowed access, call allow\_ip('127.0.0.1') to enable it.

    use CGI::Lingua;
    use CGI::ACL;

    # Allow Google to connect to us
    my $acl = CGI::ACL->new()->allow_ip(ip => '8.35.80.39');

    if($acl->all_denied()) {
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

[CGI::Lingua](https://metacpan.org/pod/CGI%3A%3ALingua)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::ACL

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/release/CGI-ACL](https://metacpan.org/release/CGI-ACL)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-ACL](https://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-ACL)

- CPANTS

    [http://cpants.cpanauthors.org/dist/CGI-ACL](http://cpants.cpanauthors.org/dist/CGI-ACL)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=CGI-ACL](http://matrix.cpantesters.org/?dist=CGI-ACL)

- CPAN Ratings

    [http://cpanratings.perl.org/d/CGI-ACL](http://cpanratings.perl.org/d/CGI-ACL)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=CGI::ACL](http://deps.cpantesters.org/?module=CGI::ACL)

# LICENSE AND COPYRIGHT

Copyright 2017-2021 Nigel Horne.

This program is released under the following licence: GPL2
