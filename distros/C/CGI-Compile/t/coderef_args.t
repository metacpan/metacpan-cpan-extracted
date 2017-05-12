use Test::More;
use t::Capture;
use CGI::Compile;

my $sub = CGI::Compile->compile("t/args.cgi");

my $stdout = capture_out(sub { $sub->(1,2,3) });
like $stdout, qr/Hello \@_: 1,2,3 \@ARGV: 1,2,3\z/;

done_testing;
