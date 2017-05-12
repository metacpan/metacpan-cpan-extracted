# This script is useful for testing Net::SMTP configuration. If run with
# no arguments, eg "perl smtp.pl", it will attempt to send mail from you
# to you. If this succeeds, you're probably good to go.
# If not you may want to try "ping mailhost" since that's the default
# SMTP server, and/or search for the file "libnet.cfg" in your perl
# site/lib area and see what it thinks the SMTP server is.
# You can send to an explicit address by specifying it on the cmdline.

use Net::SMTP;

my $smtp = Net::SMTP->new;
die "$0: Error: Net::SMTP may be mis-configured" unless defined $smtp;
my $from = $ENV{CLEARCASE_USER}||$ENV{USERNAME}||$ENV{LOGNAME}||$ENV{USER};
my $to = shift || $from;
$smtp->debug(1);
$smtp->mail($from) &&
    $smtp->to($to, {SkipBad => 1}) &&
    $smtp->data() &&
    $smtp->datasend("To: $to\n") &&
    $smtp->datasend("Subject: TESTING\n") &&
    $smtp->datasend("\n") &&
    $smtp->datasend("Test message ...") &&
    $smtp->dataend() &&
    $smtp->quit ||
    die "$0: Error: Net::SMTP: $!";
