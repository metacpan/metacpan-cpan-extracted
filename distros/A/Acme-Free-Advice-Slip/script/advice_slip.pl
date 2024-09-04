use lib '../lib';
use v5.38;
no warnings 'experimental::builtin';
use Acme::Free::Advice::Slip;
use Getopt::Long;
use Pod::Usage;

# Test
#~ @ARGV = qw[-id 2];
#~ @ARGV = qw[-help];
#~ @ARGV = qw[-search time];
#~ @ARGV = qw[-json];
#~ @ARGV = qw[-search time -json];
#~ @ARGV = qw[-id 5 -json];
#~ @ARGV = qw[-json -id 333];
#~ @ARGV = qw[-json -id 2];
#~ @ARGV = qw[-help];
#
my $raw = 0;
my ( $id, $query );

sub _echo ($slip) {    # JSON::Tiny is loaded in Acme::Free::Advice::* anyway
    $raw ?
        JSON::Tiny::encode_json(
        builtin::blessed $slip ? {%$slip} : [
            map {
                {%$_}
            } @$slip
        ]
        ) :
        $slip;
}
GetOptions( 'json' => \$raw, 'help' => sub { pod2usage( -exitval => 1 ) }, 'id=i' => \$id, 'search=s' => \$query );
if ( defined $query ) {
    my @slips = Acme::Free::Advice::Slip::search($query);
    exit say $raw ? '[]' : 'No advice matches query' unless +@slips;
    exit !say _echo( \@slips ) if $raw;
    say _echo($_) for @slips;
    exit !@slips;
}
my $slip = Acme::Free::Advice::Slip::advice($id);
exit !( $slip ? say _echo($slip) : !say( $raw ? 'null' : '' ) );
__END__

=head1 NAME

advice_slip - Seek wisdom in the terminal

=head1 SYNOPSIS

    advice_slip                     # gather random wisdom
    advice_slip -id 5               # specific advice by ID
    advice_slip -search time        # query advice by keyword
    advice_slip -json -search hero  # get help like you're a robot
    advice_slip -help               # get help

=head1 OPTIONS

    -json               Echo raw JSON encoded data
    -id     <number>    Specify an ID
    -search <string>    Specify a search query
    -help               Display this help message

=head1 DESCRIPTION

This script wraps Acme::Free::Advice::Slip.

=head1 LICENSE & LEGAL

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2. Other copyrights, terms, and conditions may apply to data transmitted through this module.

L<AdviceSlip.com|https://adviceslip.com/> is brought to you by L<Tom Kiss|https://tomkiss.net/>.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
