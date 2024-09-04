use lib '../lib';
use v5.36;
use Acme::Insult;
use Getopt::Long;
use Pod::Usage;
use open qw[:std :encoding(UTF-8)];

# Test
#~ @ARGV = qw[];
#~ @ARGV = qw[-json];
#~ @ARGV = qw[-h];
#~ @ARGV = qw[-evil];
#~ @ARGV = qw[-pirate];
#~ @ARGV = qw[-glax];
#~ @ARGV = qw[-flavors];
#
my $raw = 0;
my $flavor;

sub _echo ($insult) {
    $raw && eval 'require JSON::Tiny' ? JSON::Tiny::encode_json( {%$insult} ) : $insult;
}
GetOptions(
    \my %h, 'language=s',
    'help'     => sub { pod2usage( -exitval => 1 ) },
    'flavors!' => sub { exit !say 'Supported insult flavors: ' . join ', ', Acme::Insult::flavors() },
    'json!'    => \$raw,
    'glax!'    => sub { $flavor = 'glax' },
    'evil!'    => sub { $flavor = 'evil' },
    'pirate!'  => sub { $flavor = 'pirate' },
);
my $shade = Acme::Insult::insult($flavor);
exit !( $shade ? say _echo($shade) : !say( $raw ? 'null' : '' ) );
__END__

=head1 NAME

insult - Generate insults on the terminal

=head1 SYNOPSIS

    insult                               # generate a random insult
    insult -json                         # insult someone if you're a robot
    insult -glax                         # generate an insult with libInsult
    insult -evil                         # generate an especially poor taste
    insult -pirate                       # generate a pirate themed insult
    insult -help                         # get help

=head1 OPTIONS

    -json               Echo raw JSON encoded data
    -flavors            List supported insult flavors
    -glax               Generate an insult with Acme::Insult::Glax
    -evil               Generate an insult with Acme::Insult::Evil
    -pirate             Generate an insult with Acme::Insult::Pirate
    -help               Display this help message

=head1 DESCRIPTION

This script wraps Acme::Insult.

=head1 LICENSE & LEGAL

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2. Other copyrights, terms, and conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
