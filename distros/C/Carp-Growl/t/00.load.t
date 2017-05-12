use Test::More tests => 1;
use lib 't/testlib';
my $fatal;

BEGIN {
#    use_ok('Carp::Growl');
    eval { require Carp::Growl; }
        or $fatal = $@;
}
diag("Testing Carp::Growl $Carp::Growl::VERSION");
warn $fatal if $fatal;

if (    $fatal
    and $fatal !~ /^IO::Socket::INET: connect: / )
{
    fail;
}
elsif ($fatal) {
    diag(
        "Probably, you don't have the notice-system which Growl::Any supports."
    );
    diag("This test pass forcibly, but you should recognize that it is not");
    diag("helpful using this module without 'notice-system'");
    pass;
}
else {
    pass;
}
