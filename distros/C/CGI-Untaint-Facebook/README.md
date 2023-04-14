# NAME

CGI::Untaint::Facebook - Validate a string is a valid Facebook URL or ID

# VERSION

Version 0.16

# SYNOPSIS

CGI::Untaint::Facebook validate if a given ID in a form is a valid Facebook ID.
The ID can be either a full Facebook URL, or a page on facebook, so
'http://www.facebook.com/nigelhorne' and 'nigelhorne' will both return true.

    use CGI::Info;
    use CGI::Untaint;
    use CGI::Untaint::Facebook;
    # ...
    my $info = CGI::Info->new();
    my $params = $info->params();
    # ...
    my $u = CGI::Untaint->new($params);
    my $tid = $u->extract(-as_Facebook => 'web_address');
    # $tid will be lower case

# SUBROUTINES/METHODS

## is\_valid

Validates the data.
Returns a boolean if $self->value is a valid Facebook URL.

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

Please report any bugs or feature requests to `bug-cgi-untaint-url-facebook at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Untaint-Twitter](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Untaint-Twitter).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SEE ALSO

CGI::Untaint::url

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Untaint::Facebook

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Untaint-Facebook](http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Untaint-Facebook)

- Search CPAN

    [http://search.cpan.org/dist/CGI-Untaint-Facebook](http://search.cpan.org/dist/CGI-Untaint-Facebook)

# ACKNOWLEDGEMENTS

# LICENSE AND COPYRIGHT

Copyright 2012-2023 Nigel Horne.

This program is released under the following licence: GPL2
