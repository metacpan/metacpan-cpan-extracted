##############################################################################
#
#  Config::Terse is laconic configuration files parser.
#  Vladi Belperchinov-Shabanski "Cade" <cade@biscom.net> <cade@datamax.bg>
#
#  DISTRIBUTED UNDER GPLv2
#
##############################################################################
package Config::Terse;
use Exporter;
use Carp qw( croak );
use Data::Dumper;
use strict;

our @ISA = qw( Exporter );

our @EXPORT = qw(
                  terse_config_load
                );

our $VERSION = '0.01';

##############################################################################

sub terse_config_load
{
  my $fn  = shift;
  my %opt = @_;

  $opt{ uc $_ } ||= $opt{ lc $_ } for qw( CASE ORDERED MAIN );

  my $opt_case;
  $opt_case = 'UC';
  $opt_case = 'LC' if $opt{ 'CASE' } =~ /L|LC|LO|LOW|LOWER/i;
  $opt_case = 'NC' if $opt{ 'CASE' } =~ /N|NC|ASIS/i;

  my $opt_ordered = $opt{ 'ORDERED' };
  my $opt_main    = $opt{ 'MAIN'    };

  my $kc = sub 
              { 
              my $s = shift; 
              return uc $s if $opt_case eq 'UC';
              return lc $s if $opt_case eq 'LC';
              return    $s if $opt_case eq 'NC';
              };

  my %h;

  if( $opt_ordered )
    {
    require Tie::IxHash;
    tie %h, 'Tie::IxHash';
    }

  my $section = $kc->( $opt_main );

  my $lh = $h{ $section } = {}; # last section hash
  
  open( my $if, $fn );
  while( my $line = <$if> )
    {
    next if $line =~ /^\s*[#;]/; # skip comments
    $line =~ s/[\r\n]+$//;       # trip trailing cr/lf
    next unless $line =~ /\S/;   # skip empty lines
    
    if( $line =~ /^\s*=(\S+)(.*)/ )
      {
      my $section = $kc->( $1 );
      my %sh; # section hash
      tie %sh, 'Tie::IxHash' if $opt_ordered;
      $lh = \%sh;

      my $args = $2;
      my @args = split /\s+/, $args;

      my $lg; # last group
      for my $arg ( @args )
        {
        if( $arg =~ /^\+(\S+)/ )
          {
          my $is = $kc->( $1 ); # inherit section
          my $ih;
          if( $lg )
            {
            croak "section [$lg:$section] cannot inherit from [$lg:$is] does not exist" unless exists $h{ $lg }{ $is };
            $ih = $h{ $lg }{ $is };
            }
          else
            {
            croak "section [$section] cannot inherit from [$is] does not exist" unless exists $h{ $is };
            $ih = $h{ $is };
            }  
          %$lh = ( %$lh, %$ih );
          next;
          }
        if( $arg =~ /^\@(\S+)/ )
          {
          $lg = $kc->( $1 );
          $h{ $lg }{ $section } = \%sh;
          }
        }
      $h{ $section } = \%sh unless $lg;

      next;
      # end section code
      }
    if( $line =~ /^\s*(\S+)\s*(.*)/ )
      {
      my $k = $kc->( $1 ); # key
      my $v = $2; # value
      $lh->{ $k } = $v;
      next;
      # end key=value code
      }  
    }
  close( $if );

  return \%h;
}

##############################################################################

=pod

=head1 NAME

Config::Terse is laconic configuration files parser.

=head1 SYNOPSIS

    #!/usr/bin/perl
    use strict;
    use Config::Terse;

    my $cfg = terse_config_load( 'try.cfg' );

    use Data::Dumper;
    print Dumper( $cfg );

=head1 DESCRIPTION

Config::Terse parses configuration files with very compact syntax, which 
may seem rude or unfriendly. It provides sections with keyword/value pairs, 
sections inheritance and named groups of sections.

Each line in the config file contains whitespace-delimited key and value:

  key         value
  anotherkey  other value
  koe         ne se chete

Sections begin with equal sign on new line, followed by the section name:

  =newsection
  
  sectionkey1  value
  newkey       value

Sections may inherit other sections. Inherited sections are specified with 
plus sign and name after the section name:

  =newsection  +othersection1  +othersection2  ...

Sections may be grouped in groupss. Group names are specified with "at" sign (@)
followed by the group name, after the section name:

  =apple  @fruits
  
Inheritance and groups can be combined but order is important! All inherited
sections specified before group is taken from the main (root) sections.
Inherited sections after group name is taken from the same group (if such
exists. 

Sections can be added to multiple groups. They will be linked together and
changing one section key will be visible in the other groups.

Here is an example:

  =green
    color  green
    
  =tree  @fruits
    isatree  yes
    
  =apple +green  @fruits  +tree
    name  this is a green apple tree
    
The "apple" section will inherit "green" section, then will be put in the
"fruits" group and finally will inherit the "tree" section from "fruits".

All section and key names are converted to upper case by default.

The result perl hash structure for all the examples combined will be:

  $VAR1 = {
            'GREEN' => {
                         'COLOR' => 'green'
                       },
            'MAIN' => {
                        'ANOTHERKEY' => 'other value',
                        'KEY' => 'value',
                        'KOE' => 'ne se chete'
                      },
            'FRUITS' => {
                          'TREE' => {
                                      'ISATREE' => 'yes'
                                    },
                          'APPLE' => {
                                       'COLOR' => 'green',
                                       'NAME' => 'this is a green apple tree',
                                       'ISATREE' => 'yes'
                                     }
                        },
            'NEWSECTION' => {
                              'SECTIONKEY1' => 'value',
                              'NEWKEY' => 'value'
                            }
          };

Default section name is 'MAIN'. It is used for keys in files without any 
sections or for keys in the leading part of a file where no section has been 
defined yet. Default section name can be changed with 'MAIN' option and will 
be modified by the 'CASE' option. See 'OPTIONS' section below.

=head1 OPTIONS

Few options can be added when loading new config file:

    # make all sections and keys names upper case (default)
    my $cfg = terse_config_load( 'try.cfg', CASE => 'UC' );
  
    # make all sections and keys names lower case
    my $cfg = terse_config_load( 'try.cfg', CASE => 'LC' );

    # leave all sections and keys names asis, no case conversion
    my $cfg = terse_config_load( 'try.cfg', CASE => 'NC' );

    # keep sections and keys in the order they were seen
    my $cfg = terse_config_load( 'try.cfg', ORDERED => 1 );

    # set MAIN section name
    my $cfg = terse_config_load( 'try.cfg', MAIN => '*' );

    # combined options
    my $cfg = terse_config_load( 'try.cfg', CASE    => 'LC', 
                                            MAIN    => '*', 
                                            ORDERED => 1 );

=head1 GITHUB REPOSITORY

  https://github.com/cade-vs/perl-config-terse
  
  git clone git://github.com/cade-vs/perl-config-terse.git

=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"

  <cade@biscom.net> <cade@datamax.bg> <cade@cpan.org>

  http://cade.datamax.bg

=cut

1;
