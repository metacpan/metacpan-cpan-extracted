use lib '../lib';
use v5.36;
use Acme::Free::Advice::Unsolicited;
use Getopt::Long;
use Pod::Usage;
use open qw[:std :encoding(UTF-8)];

# Test
#~ @ARGV = qw[-id 2];
#~ @ARGV = qw[-help];
#~ @ARGV = qw[-all];
#~ @ARGV = qw[-json];
#~ @ARGV = qw[-id 5 -json];
#~ @ARGV = qw[-json -id 333];
#~ @ARGV = qw[-all -json];
#~ @ARGV = qw[-id 216];
#
my $raw = 0;
my ( $id, $all );

sub _echo ($slip) {    # JSON::Tiny is loaded in Acme::Free::Advice::Unsolicited anyway
    $raw ? JSON::Tiny::encode_json($slip) : $slip;
}
GetOptions( 'json' => \$raw, 'help' => sub { pod2usage( -exitval => 1 ) }, 'id=i' => \$id, 'all!' => \$all );
if ( defined $all ) {
    my @slips = Acme::Free::Advice::Unsolicited::all();
    exit say $raw ? '[]' : 'No advice matches query' unless +@slips;
    exit !say _echo( \@slips ) if $raw;
    say _echo($_) for @slips;
    exit !@slips;
}
my $slip = Acme::Free::Advice::Unsolicited::advice($id);
exit !( $slip ? say _echo($slip) : !say( $raw ? 'null' : '' ) );
__END__

=head1 NAME

advice_kk - Seek unsolicited advice from Keven Kelly in the terminal

=head1 SYNOPSIS

    advice_kk                     # gather random wisdom
    advice_kk -id 5               # specific advice by ID
    advice_kk -id 5 -json         # specific advice by ID but you're a robot
    advice_kk -all                # get all advice
    advice_kk -help               # get help

=head1 OPTIONS

    -json               Echo raw JSON encoded data
    -id     <number>    Specify an ID
    -all                Gather all advice
    -help               Display this help message

=head1 DESCRIPTION

This script wraps Acme::Free::Advice::Unsolicited.

=head1 LICENSE & LEGAL

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2. Other copyrights, terms, and conditions may apply to data transmitted through this module.

Unsolicited advice provided by L<Kevin Kelly|https://kk.org/>.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
