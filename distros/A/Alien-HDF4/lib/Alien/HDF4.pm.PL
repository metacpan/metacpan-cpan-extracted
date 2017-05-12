#!perl -w

use strict;
use warnings;
use Data::Dumper;
require 'common.pl';

my $version = get_version();
my $config_hash = get_build();

my $cfg = join '', <DATA>;
$cfg =~ s/#VERSION#/$version/;
my $out = shift;
io($out)->print($cfg) or die "$out: $!\n";

__DATA__
package Alien::HDF4;

use strict;
use warnings;

our $VERSION = '#VERSION#';

sub Inline {
  require Alien::HDF4::Install::Files;
  goto &Alien::HDF4::Install::Files::Inline;
}

1;

__END__

=head1 NAME

Alien::HDF4 - Encapsulate install info for HDF4

=head1 SYNOPSIS

  # PDL/Makefile.PL
  use ExtUtils::Depends;
  my $pkg = ExtUtils::Depends->new(qw(PDL Alien::HDF4)); # HDF4 config info

  use Inline with => 'Alien::HDF4';

=head1 DESCRIPTION

Use in your F<Makefile.PL> as above. Produces config info usable via
L<ExtUtils::Depends>.

=head1 AUTHOR

Ed J

=head1 SEE ALSO

L<ExtUtils::Depends>.
