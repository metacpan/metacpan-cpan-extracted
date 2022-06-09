use strict;
use Test::More tests => 5;
use English;

unlike(perl_subprocess(q{
        use CGI::Carp::WarningsToBrowser;
    }),
    qr/Content-type:/i,
    "zero warnings, zero errors");


like(perl_subprocess(q{
        use CGI::Carp::WarningsToBrowser;
        warn "testing one two three";
    }),
    qr/Content-type: text\/html.*<pre\b.*testing one two three/s,
    "response header auto-generated");


my $one_warning_zero_errors = 
    perl_subprocess('
        use CGI::Carp::WarningsToBrowser;
        print "CoNtEnT-tYpE: text/html\n\n";
        warn "testing four five six";
    ');

unlike($one_warning_zero_errors,
    qr/Content-type: text\/html/,
    "one warning, zero errors, part 1");

like($one_warning_zero_errors,
    qr/<pre\b.*testing four five six/s,
    "one warning, zero errors, part 2");


my $one_warning_one_error = 
    perl_subprocess(q{
        use CGI::Carp qw(fatalsToBrowser);
        use CGI::Carp::WarningsToBrowser;
        # Unfortunately, after CGI::Carp::die() forwards the die message to the
        # browser, it goes ahead and does a real die() at the very end, using
        # the original die() message. I don't need or want this message
        # appearing during the tests.
        close STDERR;
        warn "testing seven eight nine";
        die "dead";
    });

# the javascript that moves the warnings to the top of the HTML document should
# not be included if CGI::Carp's fatalsToBrowser() has been triggered
#unlike($one_warning_one_error,
#    qr/document.getElementById\('CGI::Carp::WarningsToBrowser'\)/,
#    "one warning, one error, part 1");

like($one_warning_one_error,
    qr/<pre\b.*testing seven eight nine/s,
    "one warning, one error, part 2");


# Creates a child process running perl, and passes it some Perl code to execute
# via -e. Returns what the child process outputs via its STDOUT.
#
# TODO: Does this work properly under Win32? (I assume it works okay under
# Cygwin?)
sub perl_subprocess {
    my ($perl_code) = @_;
    open(my $child_stdout, '-|',
            $EXECUTABLE_NAME,
            '-Ilib',
            '-e', 
            $perl_code)
        or die "Can't fork: $!";
    my $stdout = join('', <$child_stdout>);
    close $child_stdout;
    return $stdout;
}
