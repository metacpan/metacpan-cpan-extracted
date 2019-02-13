#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019 -- leonerd@leonerd.org.uk

package App::AVR::Fuses;

use strict;
use warnings;
use feature qw( say );
use 5.010;

our $VERSION = '0.01';

use File::ShareDir qw( module_dir );
use Getopt::Long qw( GetOptionsFromArray );
use List::Util qw( first );

use YAML ();

my $SHAREDIR = module_dir( __PACKAGE__ );

=head1 NAME

C<App::AVR::Fuses> - support module for F<avr-fuses>

=head1 DESCRIPTION

This module contains the support code for the F<avr-fuses> command.

=cut

sub usage
{
   my ( $err ) = @_;

   my ( $basename ) = $0 =~ m{/([^/]+)$};
   ( $err ? \*STDERR : \*STDOUT )->print( <<"EOF" );
Usage: $basename [YAML-FILE] FUSES...

Options:
   -h, -help              - display this help

   -v, --verbose          - print more verbose messages

   -p, --part NAME        - specify AVR part name as an alternative to giving
                            the YAML-FILE path

   -f, --fuse FUSE=VALUE  - preset the given fuse value
                            FUSE:  lfuse | hfuse | efuse
                            VALUE: 123 | 0456 | 0x78
EOF

   exit $err;
}

sub run
{
   my $class = shift;
   my @argv = @_;

   my $yamlpath;

   my %current;

   GetOptionsFromArray(
      \@argv,

      'h|help' => sub { usage(0) },

      'v|verbose' => \my $VERBOSE,

      'p|part=s' => sub {
         my $partname = $_[1];
         $partname = "ATmega\U$1" if $partname =~ m/^(?:atmega|m)(.*)$/i;
         $partname = "ATtiny\U$1" if $partname =~ m/^(?:attiny|t)(.*)$/i;

         $yamlpath = "$SHAREDIR/$partname.yaml";
         unless( -f $yamlpath ) {
            print STDERR "No YAML file found at $yamlpath\n";
            exit 1;
         }
      },

      'f|fuse=s' => sub {
         my ( $fuse, $val ) = $_[1] =~ m/^(.*?)=(.*)$/ or die "Unable to parse --fuse\n";
         $val = oct $val if $val =~ m/^0/;
         $current{lc substr $fuse, 0, 1} = $val;
      },
   ) or usage(1);

   $yamlpath //= shift @argv;

   defined $yamlpath
      or usage(1);

   my $self = $class->new(
      yamlpath => $yamlpath,
   );

   $self->set_fusereg( $_ => $current{$_} ) for keys %current;

   foreach my $arg ( @argv ) {
      my ( $name, $val ) = $arg =~ m/^(\w+)=(.*)$/ or
         die "Unable to parse '$arg'\n";

      if( $val eq "?" ) {
         say join "\n",
            "Possible values for $name are:",
            $self->list_values_for_fuse( $name );

         return 1;
      }

      $self->set_fuse( uc $name, $val );
   }

   if( $VERBOSE ) {
      # Explain the current fuse values
      foreach my $name ( $self->{fuses}->@* ) {
         my $fuseinfo = $self->{fusemap}{$name};

         my $mask = $fuseinfo->{mask} + 0; # force number because YAML loading

         my $val = $self->{regs}{ $fuseinfo->{reg} } & $mask;

         if( $fuseinfo->{values} ) {
            my $chosen = first { $_->{value} == $val } $fuseinfo->{values}->@*;
            $val = "$chosen->{name} - $chosen->{caption}";
         }
         else {
            $val = $val ? "1" : "0";
         }

         say "using $name=$val";
      }
   }

   say join " ", $self->gen_fuses_avrdude;
}

sub new
{
   my $class = shift;
   my %opts = @_;

   my $data = YAML::LoadFile( $opts{yamlpath} );

   my %regs;

   my $self = bless {
      ( map { $_ => $data->{$_} } qw( reginfos fuses fusemap ) ),

      regs => \%regs,
   }, $class;

   # Initialise defaults
   $regs{ $_->{name} } = $_->{default} for $self->{reginfos}->@*;

   return $self;
}

sub set_fusereg
{
   my $self = shift;
   my ( $name, $value ) = @_;

   exists $self->{regs}{$name} or
      die "Unrecognised fuse register name $name\n";

   $self->{regs}{$name} = $value;
}

sub set_fuse
{
   my $self = shift;
   my ( $name, $val ) = @_;

   my $fuseinfo = $self->{fusemap}{$name} or
      die "No such fuse $name\n";

   my $reg = $fuseinfo->{reg};
   my $mask = $fuseinfo->{mask} + 0; # force number because YAML loading

   my $regval = $self->{regs}{$reg};

   $regval &= ~$mask;

   if( $fuseinfo->{values} ) {
      my $chosen = first { $_->{name} eq $val } $fuseinfo->{values}->@*;
      defined $chosen or
         die "Unrecognised value for $name\n";

      $regval |= $chosen->{value};
   }
   else {
      $regval |= $mask if $val;
   }

   $self->{regs}{$reg} = $regval;
}

sub list_values_for_fuse
{
   my $self = shift;
   my ( $name ) = @_;

   my $fuseinfo = $self->{fusemap}{$name} or
      die "No such fuse $name\n";

   if( $fuseinfo->{values} ) {
      return map {
         "  $_->{name} - $_->{caption}"
      } $fuseinfo->{values}->@*;
   }
   else {
      return (
         "  1",
         "  0",
      );
   }
}

sub gen_fuses_avrdude
{
   my $self = shift;

   my @output;

   foreach my $reginfo ( $self->{reginfos}->@* ) {
      my $regname = $reginfo->{name};

      # avrdude format -U lfuse:w:0x62:m 
      push @output, "-U", sprintf "%sfuse:w:0x%02X:m", $regname, $self->{regs}{$regname};
   }

   return @output;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
