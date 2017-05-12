package CGI::CurlLog;
use strict;
use warnings;

our $VERSION = "0.02";

if (!$ENV{"GATEWAY_INTERFACE"}) {
    return 1;
}

our $log_file ||= "~/curl.log";
our $log_output = defined $log_output ? $log_output : 1;
our $curl_options = defined $curl_options ? $curl_options : "-k";

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
if ($curl_options) {
    $cmd .= "$curl_options ";
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

my $logfh;
if ($log_file eq "STDOUT") {
    $logfh = \*STDOUT;
}
elsif ($log_file eq "STDERR") {
    $logfh = \*STDERR;
}
elsif ($log_file =~ m{^~/}) {
    my $home = (getpwuid($>))[7];
    $log_file =~ s{^~/}{$home/};
    open $logfh, ">>", $log_file or die "Can't open $log_file: $!";
}
else {
    open $logfh, ">>", $log_file or die "Can't open $log_file: $!";
}
select($logfh);
$| = 1;
select(STDOUT);

print $logfh "# " . localtime() . " request from $ENV{REMOTE_ADDR}\n";
print $logfh "$cmd\n";
if (!$log_output) {
    close $logfh;
}

my $stdout;
my $output = "";

if ($log_output) {
    open $stdout, ">&", STDOUT;
    close STDOUT;
    open STDOUT, ">", \$output;
}

END {
    return if !$log_output;
    open STDOUT, ">&", $stdout;
    print $output;
    $output =~ s/\r//g;
    print $logfh "# " . localtime() . " response\n";
    print $logfh $output . "\n";
    close $logfh;
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
location is in ~/curl.log, but you can change it by setting the
$log_file package variable in a begin block before including the
library.

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

