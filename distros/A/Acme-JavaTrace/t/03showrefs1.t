use strict;
use Test::More tests => 1;
use Acme::JavaTrace 'showrefs';
use Data::Dumper;

my $text = "Advice from Klortho #11901: You cant just make shit up and expect the computer to know what you mean, Retardo!";

my @attrs = (
    $Data::Dumper::VERSION <= 2.121
        ? (text => $text)
        : (type => 'error', text => $text)
);

eval {
    die bless { @attrs }, 'Exception'
};

like( $@, 
      qq|/^Caught exception object: Exception=HASH\\(0x[0-9a-fA-F]+\\): bless\\( \\{\n|.
      qq|\\s+'text' => '\Q$text\E',?\n|.
      ($Data::Dumper::VERSION <= 2.121 ? '' : qq|\\s+'type' => 'error',?\n|) .
      qq|\\}, 'Exception' \\)/|, 
      "checking the trace"
);
