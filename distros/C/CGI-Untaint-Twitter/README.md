# NAME

CGI::Untaint::Twitter - Validate a Twitter ID in a CGI script

# VERSION

Version 0.05

# SYNOPSIS

CGI::Untaint::Twitter is a subclass of CGI::Untaint used to
validate if the given Twitter ID is valid.

    use CGI::Info;
    use CGI::Untaint;
    use CGI::Untaint::Twitter;
    # ...
    my $info = CGI::Info->new();
    my $params = $info->params();
    # ...
    my $u = CGI::Untaint->new($params);
    my $tid = $u->extract(-as_Twitter => 'twitter');
    # $tid will be lower case

# SUBROUTINES/METHODS

## is\_valid

Validates the data.
Returns a boolean if $self->value is a valid twitter ID.

## init

Set various options and override default values.

    use CGI::Info;
    use CGI::Untaint;
    use CGI::Untaint::Twitter {
        access_token => 'xxxxxx', access_token_secret => 'yyyyy',
        consumer_key => 'xyzzy', consumer_secret => 'plugh',
    };

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

Twitter only allows 150 requests per hour.  If you exceed that,
`CGI::Untaint::Twitter` won't validate and will assume all ID's are valid.

Please report any bugs or feature requests to `bug-cgi-untaint-twitter at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Untaint-Twitter](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Untaint-Twitter).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SEE ALSO

CGI::Untaint

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Untaint::Twitter

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Untaint-Twitter](http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Untaint-Twitter)

- CPAN Ratings

    [http://cpanratings.perl.org/d/CGI-Untaint-Twitter](http://cpanratings.perl.org/d/CGI-Untaint-Twitter)

- Search CPAN

    [http://search.cpan.org/dist/CGI-Untaint-Twitter](http://search.cpan.org/dist/CGI-Untaint-Twitter)

# ACKNOWLEDGEMENTS

# LICENSE AND COPYRIGHT

Copyright 2012-2019 Nigel Horne.

This program is released under the following licence: GPL
