use strict;
use warnings;
use IO::Zlib;
use File::Fetch;
use File::Spec;
use IO::Zlib;
use CPAN::DistnameInfo;

my $mirror = 'http://www.cpan.org/';

my $mailrc = '01mailrc.txt.gz';
my $packages = '02packages.details.txt.gz';

my $location = '.';

my @files = ('authors/01mailrc.txt.gz','modules/02packages.details.txt.gz');

foreach my $file ( @files ) {
  my $url = join '', $mirror, $file;

  my $ff = File::Fetch->new( uri => $url );
  my $stat = $ff->fetch( to => $location );
  next unless $stat;
  warn "Downloaded '$stat'\n";
}

my %authors;
my $mrc = IO::Zlib->new( $mailrc, "rb" ) or die "$!\n";

while (<$mrc>) {
  chomp;
  my ( $alias, $pauseid, $long ) = split ' ', $_, 3;
  $long =~ s/^"//;
  $long =~ s/"$//;
  my ($name, $email) = $long =~ /(.*) <(.+)>$/;
  $authors{$pauseid} = $name;
}

close $mrc;

my %poe_authors;

my $fh = IO::Zlib->new( '02packages.details.txt.gz', "rb" ) or die "$!\n";

while (<$fh>) {
  last if /^\s*$/;
}
while (<$fh>) {
  chomp;
  my ($module,$version,$package_path) = split ' ', $_;
  next unless $module =~ /BeLike/;
  my $dist = CPAN::DistnameInfo->new( $package_path );
  next unless $dist;
  next if $poe_authors{ $dist->cpanid };
  $poe_authors{ $dist->cpanid } = $authors{ $dist->cpanid };
}
close $fh;

my @authors;

push @authors, qq{  $_ => q[$poe_authors{$_}],\n} for sort keys %poe_authors;

print <<HEADER;
package Acme::CPANAuthors::ToBeLike;

#ABSTRACT: BeLike other CPAN Authors

use strict;
use warnings;

use Acme::CPANAuthors::Register (
HEADER

print "$_" for @authors;

print <<MIDDLE;
);

q[BeLikeEveryoneElse];

=pod

=head1 SYNOPSIS

    use Acme::CPANAuthors;

    my \$authors  = Acme::CPANAuthors->new('ToBeLike');

    my \$number   = \$authors->count;
    my \@ids      = \$authors->id;
    my \@distros  = \$authors->distributions("BINGOS");
    my \$url      = \$authors->avatar_url("BINGOS");
    my \$kwalitee = \$authors->kwalitee("BINGOS");
    my \$name     = \$authors->name("BINGOS");

=head1 DESCRIPTION

This class provides a hash of emulatable CPAN Authors' PAUSE ID and name to the L<Acme::CPANAuthors> module.

It is generated from the indexed modules on CPAN C<02packages.details.txt> finding CPAN authors who have
a module indexed with C<BeLike> in the name.

=head1 CONTAINED AUTHORS

MIDDLE

print "$_" for @authors;

print <<TAIL;

=head1 SEE ALSO

L<Acme::CPANAuthors>

L<Task>

=cut
TAIL

unlink $mailrc;
unlink $packages;
