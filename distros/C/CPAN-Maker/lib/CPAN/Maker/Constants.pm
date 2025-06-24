package CPAN::Maker::Constants;

use strict;
use warnings;

use parent qw{ Exporter };

our $VERSION = '1.5.46';  ## no critic (RequireInterpolation)

our @EXPORT_OK = ();

use Readonly;

# booleans
Readonly our $TRUE       => 1;
Readonly our $FALSE      => 0;
Readonly our $SUCCESS    => 1;
Readonly our $FAILURE    => 0;
Readonly our $SH_FAILURE => 1;
Readonly our $SH_SUCCESS => 0;

# chars
Readonly our $DASH         => q{-};
Readonly our $DOT          => q{.};
Readonly our $DOUBLE_COLON => q{::};
Readonly our $EMPTY        => q{};
Readonly our $FAT_ARROW    => q{=>};
Readonly our $INDENT       => 4;
Readonly our $NL           => qq{\n};
Readonly our $SLASH        => q{/};
Readonly our $SPACE        => q{ };

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
  'booleans' => [
    qw{
      $TRUE
      $FALSE
      $SUCCESS
      $FAILURE
      $SH_FAILURE
      $SH_SUCCESS
    }
  ],
  'chars' => [
    qw{
      $DASH
      $DOUBLE_COLON
      $DOT
      $EMPTY
      $FAT_ARROW
      $INDENT
      $NL
      $SLASH
      $SPACE
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
 booleans
 defaults

=head1 AUTHOR

Rob Lauer - <rlauer6@comcast.net>

=cut
