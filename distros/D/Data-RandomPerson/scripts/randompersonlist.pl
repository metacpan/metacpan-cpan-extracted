#! /usr/bin/env perl
use strict;
use warnings;

use Data::RandomPerson;
use Getopt::Long;
use Pod::Usage;

binmode(STDOUT, ":encoding(UTF-8)");

my $help   = 0;
my $type   = '';
my $number = 30;

GetOptions(
    'help|?' => \$help,
    'type=s' => \$type,
    'number=i' => \$number,
) or pod2usage();

pod2usage(-verbose  => 2) if $help;

my %types = map {$_ => 1} Data::RandomPerson::available_types();
if ($type && !$types{$type}) {
    print STDERR "$0: Unknown type '" . $type . "'. ";
    print STDERR "The following types are available:\n\n";
    print STDERR join("\n", sort keys %types);
    die "\n";
}

my $r = Data::RandomPerson->new(type => $type);

for (1..$number) {
    my $p = $r->create();
    print $p->{firstname}, ' ', $p->{lastname}, "\n";
}

__END__

=head1 NAME

randompersonlist.pl - Create a list of random person names

=head1 DESCRIPTION

Generating lists of random person names is arguably the best feature
of L<Data::RandomPerson> and this script helps you output a lists
of names quickly.

=head1 SYNOPSIS

randompersonlist.pl [options]

  Options (all optional):
    --type         type of names
    --number       number of persons generated

=head1 Options

=over 8

=item B<--type>

Optional type of name list used. Currently available:
Arabic, Dutch, English, ModernGreek, Spanish.

If you specify a type that does not exist, you'll get an error
message plus the list of possible options.

If you do not specify this option, you'll use the standard 'Last',
'Female' and 'Male' lists which are rather big and seem to contain
names from all around the globe.

=item B<--number>

The number of results that should be printed. Defaults to 30.

=back
