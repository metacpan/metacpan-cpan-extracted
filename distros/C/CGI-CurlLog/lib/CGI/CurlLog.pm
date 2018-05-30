package CGI::CurlLog;
use strict;
use warnings;

our $VERSION = "0.03";
our %opts = (
    file => undef,
    response => 1,
    options => "-k",
    timing => 0,
);

sub import {
    my ($package, %args) = @_;
    for my $key (keys %args) {
        $opts{$key} = $args{$key};
    }

    if (!$opts{file}) {
        $opts{fh} = \*STDERR;
    }
    else {
        my $file2 = $opts{file};
        if ($file2 =~ m{^~/}) {
            my $home = $ENV{HOME} || (getpwuid($<))[7];
            $file2 =~ s{^~/}{$home/};
        }
        open $opts{fh}, ">>", $file2 or die "Can't open $opts{file}: $!";
    }
    select($opts{fh});
    $| = 1;
    select(STDOUT);

    if (!$ENV{"GATEWAY_INTERFACE"}) {
        return 1;
    }
    my $cmd = "curl ";
    my $url = $ENV{"HTTPS"} ? "https://" : "http://";
    $url .= $ENV{"HTTP_HOST"} || $ENV{"SERVER_NAME"} || $ENV{"SERVER_ADDR"};
    $url .= $ENV{"REQUEST_URI"};
    if ($url =~ /[=&;?]/) {
        $cmd .= "\"$url\" ";
    }
    else {
        $cmd .= "$url ";
    }
    if ($opts{options}) {
        $cmd .= "$opts{options} ";
    }
    if ($ENV{"REQUEST_METHOD"}) {
        if ($ENV{"REQUEST_METHOD"} ne "GET" || $ENV{"CONTENT_LENGTH"}) {
            $cmd .= "-X $ENV{REQUEST_METHOD} ";
        }
    }
    if ($ENV{"CONTENT_TYPE"}) {
        $cmd .= "-H \"Content-Type: $ENV{CONTENT_TYPE}\" ";
    }
    if ($ENV{"HTTP_ACCEPT"}) {
        $cmd .= "-H \"Accept: $ENV{HTTP_ACCEPT}\" ";
    }
    if ($ENV{"HTTP_AUTHORIZATION"}) {
        $cmd .= "-H \"Authorization: $ENV{HTTP_AUTHORIZATION}\" ";
    }
    if ($ENV{"HTTP_COOKIE"}) {
        $cmd .= "-H \"Cookie: $ENV{HTTP_COOKIE}\" ";
    }
    # if ($ENV{"HTTP_USER_AGENT"}) {
    #     $cmd .= "-H \"UserAgent: $ENV{HTTP_USER_AGENT}\" ";
    # }
    if ($ENV{"CONTENT_LENGTH"}) {
        my $input = do {local $/; <STDIN>};
        close STDIN;
        open STDIN, "<", \$input;
        my $input2 = $input;
        $input2 =~ s{([\\\$"])}{\\$1}g;
        $cmd .= "-d \"$input2\" ";
    }
    $cmd =~ s/\s*$//;

    print {$opts{fh}} "# " . localtime() . " request from $ENV{REMOTE_ADDR}\n";
    print {$opts{fh}} "$cmd\n";

    $opts{response2} = "";
    if ($opts{response}) {
        open $opts{stdout}, ">&", STDOUT;
        close STDOUT;
        open STDOUT, ">", \$opts{response2};
    }
    $opts{time1} = time();
}

END {
    if ($opts{response}) {
        open STDOUT, ">&", $opts{stdout};
        print $opts{response2};
        $opts{response2} =~ s/\r//g;
        $opts{response2} =~ s/\s*$//g;
        print {$opts{fh}} "# " . localtime() . " response\n";
        print {$opts{fh}} $opts{response2} . "\n";
    }
    if ($opts{timing}) {
        $opts{time2} = time();
        my $diff = $opts{time2} - $opts{time1};
        print {$opts{fh}} "# ${diff}s\n";
    }
    print {$opts{fh}} "\n";
}

1;

__END__

=encoding utf8

=head1 NAME

CGI::CurlLog - Log CGI parameters as curl commands

=head1 SYNOPSIS

    use CGI::CurlLog;

=head1 DESCRIPTION

This module can be used to log CGI parameters as curl commands so
you can redo requests to CGI scripts on your server. Just include
a statement "use CGI::CurlLog;" to the top of your CGI script and
then check the log file for curl commands. The default log file
location is STDOUT, but you can change it like this:

    use CGI::CurlLog file => "~/curl.log";

You can set whether to include the response in the log like this:

    use CGI::CurlLog response => 1;

You can include timing details about how long the cgi script took
to run like this:

    use CGI::CurlLog timing => 1;

=head1 METACPAN

L<https://metacpan.org/pod/CGI::CurlLog>

=head1 REPOSITORY

L<https://github.com/zorgnax/cgicurllog>

=head1 AUTHOR

Jacob Gelbman, E<lt>gelbman@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Jacob Gelbman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

