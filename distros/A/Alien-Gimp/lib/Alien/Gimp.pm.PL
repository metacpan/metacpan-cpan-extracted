#!perl -w

use strict;
use warnings;
require 'common.pl';

my $version = ag_getversion();
my $config_hash = ag_getconfig();

my $cfg = join '', <DATA>;
$cfg =~ s/#CFG#/Data::Dumper->Dump([$config_hash], ['*config'])/e;
$cfg =~ s/#VERSION#/$version/;
my $out = shift;
io($out)->print($cfg) or die "$out: $!\n";

__DATA__
package Alien::Gimp;

use strict;
use warnings;

our $VERSION = '#VERSION#';

my #CFG#

sub gimp { $config{gimp} }
sub gimptool { $config{gimptool} }
sub gimpplugindir { $config{gimpplugindir} }

sub Inline {
  require Alien::Gimp::Install::Files;
  goto &Alien::Gimp::Install::Files::Inline;
}

1;

__END__

=head1 NAME

Alien::Gimp - Encapsulate install info for GIMP

=head1 SYNOPSIS

  # Gimp/Makefile.PL
  use ExtUtils::Depends;
  my $pkg = ExtUtils::Depends->new(qw(Gimp Alien::Gimp)); # GIMP config info

  use Alien::Gimp;
  say Alien::Gimp->gimpplugindir;

=head1 DESCRIPTION

Use in your F<Makefile.PL> as above. Produces config info usable via
L<ExtUtils::Depends>.

Available methods:

=head2 gimp

The path of the GIMP executable.

=head2 gimptool

The path of the F<gimptool> executable.

=head2 gimpplugindir

The path of the GIMP plug-in directory.

=head1 AUTHOR

Ed J

=head1 SEE ALSO

L<Gimp>, L<ExtUtils::Depends>.
