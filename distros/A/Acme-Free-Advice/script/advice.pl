use lib '../lib';
use v5.36;
use Acme::Free::Advice;
use Getopt::Long;
use Pod::Usage;
use open qw[:std :encoding(UTF-8)];

# Test
#~ @ARGV = qw[];
#~ @ARGV = qw[-json];
#~ @ARGV = qw[-h];
#~ @ARGV = qw[-unsolicited];
#~ @ARGV = qw[-unsolicited -json];
#~ @ARGV = qw[-slip];
#~ @ARGV = qw[-slip -json];
#~ @ARGV = qw[-flavors];
#
my $raw = 0;
my $flavor;

sub _echo ($advice) {
    $raw && eval 'require JSON::Tiny' ? JSON::Tiny::encode_json( {%$advice} ) : $advice;
}
GetOptions(
    \my %h, 'language=s',
    'help'         => sub { pod2usage( -exitval => 1 ) },
    'flavors!'     => sub { exit !say 'Supported advice flavors: ' . join ', ', Acme::Free::Advice::flavors() },
    'json!'        => \$raw,
    'slip!'        => sub { $flavor = 'slip' },
    'unsolicited!' => sub { $flavor = 'unsolicited' }
);
my $advice = Acme::Free::Advice::advice($flavor);
exit !( $advice ? say _echo($advice) : !say( $raw ? 'null' : '' ) );
__END__

=head1 NAME

advice - Generate advice on the terminal

=head1 SYNOPSIS

    advice                               # generate a random advice
    advice -json                         # grab advice if you're a robot
    advice -slip                         # generate an advice slip
    advice -unsolicited                  # generate unsolicited advice from Kevin Kelly
    advice -help                         # get help

=head1 OPTIONS

    -json               Echo raw JSON encoded data
    -flavors            List supported advice flavors
    -slip               Generate an advice with Acme::Free::Advice::Slip
    -unsolicited        Generate an advice with Acme::Free::Advice::Unsolicited
    -help               Display this help message

=head1 DESCRIPTION

This script wraps Acme::Free::Advice.

=head1 LICENSE & LEGAL

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2. Other copyrights, terms, and conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
