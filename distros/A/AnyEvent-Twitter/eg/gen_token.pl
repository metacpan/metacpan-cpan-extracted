#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use JSON;
use AnyEvent;
use AnyEvent::Twitter;

my %p;

print "Register your app at https://dev.twitter.com/apps\n\n";
print "Paste your\n";

$p{consumer_key} = do {
    print "\tconsumer_key    : ";
    my $key = <STDIN>;
    chomp $key;
    $key;
};

$p{consumer_secret} = do {
    print "\tconsumer_secret : ";
    my $secret = <STDIN>;
    chomp $secret;
    $secret;
};

our %TOKEN;
my $cv = AE::cv;
$cv->begin;
AnyEvent::Twitter->get_request_token(
    consumer_key    => $p{consumer_key},
    consumer_secret => $p{consumer_secret},
    callback_url    => 'oob',
    cb => sub {
        my ($location, $response, $body, $header) = @_;
        %TOKEN = %$response;

        print "\n",
              "Access the authorization URL and get the PIN at \n\n",
              "$location\n\n";

        $cv->end;
    },
);
$cv->recv;

my $pin = do {
    print "\tInput the PIN   : ";
    my $p = <STDIN>;
    chomp $p;
    $p;
};

$cv = AE::cv;
$cv->begin;
AnyEvent::Twitter->get_access_token(
    consumer_key       => $p{consumer_key},
    consumer_secret    => $p{consumer_secret},
    oauth_token        => $TOKEN{oauth_token},
    oauth_token_secret => $TOKEN{oauth_token_secret},
    oauth_verifier     => $pin,
    cb => sub {
        my ($token, $body, $header) = @_;
        $p{access_token}         = $token->{oauth_token};
        $p{access_token_secret}  = $token->{oauth_token_secret};
        $cv->end;
    },
);
$cv->recv;

print "\n",
      "access_token        is $p{access_token}\n",
      "access_token_secret is $p{access_token_secret}\n\n",
      "Do you want to save these parameters to a file? [y/N] : ";

my $out = <STDIN>;
chomp $out;

if ($out && $out =~ /y/i) {
    print "\n",
          "You can save it as JSON.\n",
          "Input the file name to save : ";

    my $file = <STDIN>;
    chomp $file;

    print "\n",
          "Which style do you prefer?\n",
          "\t1) Old style for AnyEvent::Twitter\n",
          "\t2) New style for AnyEvent::Twitter, which is compatible with AnyEvent::Twitter::Stream (recommended)\n",
          "[ 1 / 2 ] : ";

    my $style = <STDIN>;
    chomp $style;

    open my $fh, '>', $file or die $!;

    if ($style eq '1') {
        print {$fh} encode_json(\%p);
    } elsif ($style eq '2') {
        my %new = (
            consumer_key    => $p{consumer_key},
            consumer_secret => $p{consumer_secret},
            token           => $p{access_token},
            token_secret    => $p{access_token_secret},
        );

        print {$fh} encode_json(\%new);
    } else {
        die "Unknown option";
    }

    close $fh or die $!;

    print "\n",
          "Check $file now!\n";
}

print "Done.\n\n";

exit;

__END__

