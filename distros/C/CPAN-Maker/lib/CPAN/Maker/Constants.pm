package CPAN::Maker::Constants;

use strict;
use warnings;

use parent qw( Exporter );

our $VERSION = '1.9.1';

our @EXPORT_OK = ();

use Readonly;

# chars
Readonly our $FAT_ARROW => q{=>};
Readonly our $INDENT    => 4;
Readonly our $NL        => qq{\n};

# defaults
Readonly our $DEFAULT_PERL_VERSION => '5.010';
Readonly our $NO_VERSION           => 0;

our %EXPORT_TAGS = (
  'defaults' => [
    qw{
      $DEFAULT_PERL_VERSION
      $NO_VERSION
    }
  ],
  'chars' => [
    qw{
      $FAT_ARROW
      $INDENT
      $NL
    }
  ],
);

foreach my $k ( keys %EXPORT_TAGS ) {
  push @EXPORT_OK, @{ $EXPORT_TAGS{$k} };
} ## end foreach my $k ( keys %EXPORT_TAGS)

$EXPORT_TAGS{'all'} = [@EXPORT_OK];

1;

## no critic (RequirePodSections)

__END__

=pod

=head1 NAME

CPAN::Maker::Constants - constants to support CPAN::Maker

=head1 SYNOPSIS

 use CPAN::Maker::Constants qw(all);

=head1 DESCRIPTION

Import tags:

 chars
 defaults

=head1 AUTHOR

Rob Lauer - <rlauer6@comcast.net>

=cut
