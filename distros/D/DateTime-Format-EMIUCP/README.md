# NAME

DateTime::Format::EMIUCP - Parse time formats for EMI-UCP protocol

# SYNOPSIS

    use DateTime::Format::EMIUCP;

    my $scts = DateTime::Format::EMIUCP->parse_datetime('030212065530');
    print $scts->ymd; # 2012-02-03
    print $scts->hms; # 06:55:30

    my $vp = DateTime::Format::EMIUCP->parse_datetime('0302120655');
    print $vp->ymd; # 2012-02-03
    print $vp->hms; # 06:55:00

# DESCRIPTION

These formats are part of EMI-UCP protocol message. EMI-UCP protocol is
primarily used to connect to short message service centers (SMSCs) for mobile
telephones.

SCTS is a string of 12 numeric characters which represents Service Center
time-stamp in ddMMyyHHmmss format.

DSCTS is a string of 12 numeric characters which represents Delivery
time-stamp in ddMMyyHHmmss format.

DDT is a string of 10 numeric characters which represents deferred delivery
time in ddMMyyHHmm format.

VP is a string of 10 numeric characters which represents validity period time
in ddMMyyHHmm format.

See EMI-UCP Interface 5.2 Specification for further explanations.

# METHODS

- DateTime \_$dt\_ = $fmt->parse\_datetime(Str \_$scts\_)

Given a string in the pattern specified in the constructor, this method will
return a new DateTime object.

Year number below 70 means the date before year 2000.

If given a string that doesn't match the pattern, the formatter will croak.

# PREREQUISITES

- [DateTime::Format::Builder](http://search.cpan.org/perldoc?DateTime::Format::Builder)

# SEE ALSO

[DateTime::Format::EMIUCP::DDT](http://search.cpan.org/perldoc?DateTime::Format::EMIUCP::DDT),
[DateTime::Format::EMIUCP::DSCTS](http://search.cpan.org/perldoc?DateTime::Format::EMIUCP::DSCTS),
[DateTime::Format::EMIUCP::SCTS](http://search.cpan.org/perldoc?DateTime::Format::EMIUCP::SCTS),
[DateTime::Format::EMIUCP::VP](http://search.cpan.org/perldoc?DateTime::Format::EMIUCP::VP),
[DateTime](http://search.cpan.org/perldoc?DateTime).

# BUGS

If you find the bug or want to implement new features, please report it at
[http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-Format-EMIUCP](http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-Format-EMIUCP)

The code repository is available at
[http://github.com/dex4er/perl-DateTime-Format-EMIUCP](http://github.com/dex4er/perl-DateTime-Format-EMIUCP)

# AUTHOR

Piotr Roszatycki <dexter@cpan.org>

# LICENSE

Copyright (c) 2012 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See [http://dev.perl.org/licenses/artistic.html](http://dev.perl.org/licenses/artistic.html)