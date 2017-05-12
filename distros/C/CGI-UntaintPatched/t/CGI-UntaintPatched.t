# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CGI-UntaintPatched.t'

#########################


use Test::More tests => 7;
BEGIN { use_ok('CGI::UntaintPatched') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $data = {
    name  => "Bart Simpson",
    grade => '',                # Forms return empty string for empty inputs
    age   => '',
    count => undef,
};


ok my $h = CGI::UntaintPatched->new($data), "Create the handler";
ok defined(my $res = $h->extract("-as_printable" => 'name')),
	"Extracted '$data->{name}' as printable.";
ok !defined($res = $h->extract("-as_printable" => 'grade')),
	"Extract '' as printable gives undef.";
ok $h->error =~ /No input for/, "Error is: " . $h->error ;
ok !defined($res = $h->extract("-as_integer" => 'count')),
	"Extract undef as integer gives undef.";
ok $h->error =~ /No parameter for/,"Error is: " . $h->error ;


