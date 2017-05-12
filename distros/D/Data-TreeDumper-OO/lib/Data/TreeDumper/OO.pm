package Data::TreeDumper::OO;
$Data::TreeDumper::OO::VERSION = '0.09';
use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA         = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT      = qw();

use Data::TreeDumper 0.24 ;

#----------------------------------------------------------------------------------------------------

sub new 
{
my($class, %setup_data) = @_;

return bless({%Data::TreeDumper::setup, %setup_data}, $class);
}

#------------------------------------------------------------------------------------------
sub Dump
{
my($self, $structure_to_dump, $title, %overrides) = @_;

$title = defined $title ? $title : '' ;

return
	(
	Data::TreeDumper::TreeDumper
			(
			  $structure_to_dump
			, {
			    TITLE                  => $title
			  , FILTER                 => $self->{FILTER}
			  , LEVEL_FILTERS          => $self->{LEVEL_FILTERS}
			  , START_LEVEL            => $self->{START_LEVEL}
			  , USE_ASCII              => $self->{USE_ASCII}
			  , MAX_DEPTH              => $self->{MAX_DEPTH}
			  , INDENTATION            => $self->{INDENTATION}
			  , VIRTUAL_WIDTH          => $self->{VIRTUAL_WIDTH}
			  , DISPLAY_OBJECT_TYPE    => $self->{DISPLAY_OBJECT_TYPE}
			  , DISPLAY_INHERITANCE    => $self->{DISPLAY_INHERITANCE}
			  , DISPLAY_AUTOLOAD       => $self->{DISPLAY_AUTOLOAD}
			  , DISPLAY_TIE            => $self->{DISPLAY_TIE}
			  , DISPLAY_ADDRESS        => $self->{DISPLAY_ADDRESS}
			  , DISPLAY_ROOT_ADDRESS   => $self->{DISPLAY_ROOT_ADDRESS}
			  , DISPLAY_PERL_ADDRESS   => $self->{DISPLAY_PERL_ADDRESS}
			  , DISPLAY_PERL_SIZE      => $self->{DISPLAY_PERL_SIZE}
			  , NUMBER_LEVELS          => $self->{NUMBER_LEVELS}
			  , COLOR_LEVELS           => $self->{COLOR_LEVELS}
			  , NO_OUTPUT              => $self->{NO_OUTPUT}
			  , RENDERER               => $self->{RENDERER}
			  , GLYPHS                 => $self->{GLYPHS}
			  , NO_NO_ELEMENTS         => $self->{NO_NO_ELEMENTS}
			  , QUOTE_HASH_KEYS        => $self->{QUOTE_HASH_KEYS}
			  , QUOTE_VALUES           => $self->{QUOTE_VALUES}
			  , REPLACEMENT_LIST       => $self->{REPLACEMENT_LIST}
			  , DISPLAY_PATH           => $self->{DISPLAY_PATH}
			  
			  , __DATA_PATH            => $self->{__DATA_PATH}
			  , __TYPE_SEPARATORS      => $self->{__TYPE_SEPARATORS}
			  
			  , %overrides
			  }
			)
	) ;
}

#------------------------------------------------------------------------------------------

sub DumpMany
{
my $self = shift ;

my @trees           = grep {'ARRAY' eq ref $_} @_ ;
my %global_override = grep {'ARRAY' ne ref $_} @_ ;

my $dump = '' ;

for my $tree (@trees)
	{
	my ($structure_to_dump, $title, %override) = @{$tree} ;
	
	$dump .= $self->Dump($structure_to_dump, $title, %global_override, %override) ;
	}

return($dump) ;
}

#------------------------------------------------------------------------------------------
sub SetFilter
{
my($self, $filter) = @_;

croak "Filter must be a code reference!" unless ('CODE' eq ref $filter) ;

$self->{FILTER} = $filter ;
}

#------------------------------------------------------------------------------------------
sub SetLevelFilters
{
my($self, $filters) = @_;

croak "Filter must be an array reference!" unless ('ARRAY' eq ref $filters) ;

$self->{LEVEL_FILTERS} = $filters ;
}

#------------------------------------------------------------------------------------------
sub SetStartLevel
{
my($self, $start_level) = @_ ;
$self->{START_LEVEL} = $start_level;
}

#------------------------------------------------------------------------------------------
sub NoOutput
{
my($self, $no_output) = @_ ;
$self->{NO_OUTPUT} = $no_output ;
}

#------------------------------------------------------------------------------------------
sub UseAscii
{
my($self, $use_ascii) = @_ ;
$self->{USE_ASCII} = $use_ascii ;
}

#------------------------------------------------------------------------------------------
sub UseAnsi
{
my($self, $use_ansi) = @_ ;
$self->{USE_ASCII} = (!$use_ansi) ;
}

#------------------------------------------------------------------------------------------
sub SetMaxDepth
{
my($self, $max_depth) = @_ ;
$self->{MAX_DEPTH} = $max_depth ;
}

#------------------------------------------------------------------------------------------
sub SetIndentation
{
my($self, $indentation) = @_ ;
$self->{INDENTATION} = $indentation ;
}

#------------------------------------------------------------------------------------------
sub ReplacementList
{
my($self, $replacement) = @_ ;
$self->{REPLACEMENT_LIST} = $replacement ;
}

#------------------------------------------------------------------------------------------
sub QuoteHashKeys
{
my($self, $quote) = @_ ;
$self->{QUOTE_HASH_KEYS} = $quote ;
}

#------------------------------------------------------------------------------------------
sub QuoteValues
{
my($self, $quote) = @_ ;
$self->{QUOTE_VALUES} = $quote ;
}

#------------------------------------------------------------------------------------------
sub DisplayNoElements
{
my($self, $no_no_elements) = @_ ;
$self->{NO_NO_ELEMENTS} = ! $no_no_elements;
}

#------------------------------------------------------------------------------------------
sub SetVirtualWidth
{
my($self, $width) = @_ ;
$self->{VIRTUAL_WIDTH} = $width ;
}

#------------------------------------------------------------------------------------------
sub DisplayRootAddress
{
my($self, $display_root_address) = @_ ;
$self->{DISPLAY_ROOT_ADDRESS} = $display_root_address ;
}

#------------------------------------------------------------------------------------------
sub DisplayAddress
{
my($self, $display_address) = @_ ;
$self->{DISPLAY_ADDRESS} = $display_address ;
}

#------------------------------------------------------------------------------------------
sub DisplayPath
{
my($self, $display_path) = @_ ;
$self->{DISPLAY_PATH} = $display_path;
}

#------------------------------------------------------------------------------------------
sub DisplayObjectType
{
my($self, $display_object_type) = @_ ;
$self->{DISPLAY_OBJECT_TYPE} = $display_object_type ;
}

#------------------------------------------------------------------------------------------
sub DisplayInheritance
{
my($self, $display_inheritance) = @_ ;
$self->{DISPLAY_INHERITANCE} = $display_inheritance ;
}

#------------------------------------------------------------------------------------------
sub DisplayAutoload
{
my($self, $display_autoload) = @_ ;
$self->{DISPLAY_AUTOLOAD} = $display_autoload ;
}

#------------------------------------------------------------------------------------------
sub Displaytie
{
my($self, $display_tie) = @_ ;
$self->{DISPLAY_TIE} = $display_tie ;
}

#------------------------------------------------------------------------------------------
sub DisplayPerlSize
{
my($self, $display_perl_size) = @_ ;
$self->{DISPLAY_PERL_SIZE} = $display_perl_size;
}

#------------------------------------------------------------------------------------------
sub DisplayPerlAddress
{
my($self, $display_perl_address) = @_ ;
$self->{DISPLAY_PERL_ADDRESS} = $display_perl_address ;
}

#------------------------------------------------------------------------------------------
sub NumberLevels
{
my($self, $number_levels) = @_ ;
$self->{NUMBER_LEVELS} = $number_levels;
}

#------------------------------------------------------------------------------------------
sub ColorLevels
{
my($self, $color_levels) = @_ ;
$self->{COLOR_LEVELS} = $color_levels ;
}

#------------------------------------------------------------------------------------------
sub SetGlyphs
{
my($self, $glyphs) = @_ ;
$self->{GLYPHS} = $glyphs ;
}

#------------------------------------------------------------------------------------------
sub SetRenderer
{
my($self, $renderer) = @_ ;
$self->{RENDERER} = $renderer ;
}

#------------------------------------------------------------------------------------------

1 ;

__END__
=head1 NAME

Data::TreeDumper::OO - Object oriented interface to Data::TreeDumper

=head1 SYNOPSIS

  use Data::TreeDumper ;
  use Data::TreeDumper::OO ;
  
  my $sub = sub {} ;
  
  my $s = 
  {
  A => 
  	{
  	a => 
  		{
  		}
  	, bbbbbb => $sub
  	, c123 => $sub
  	, d => \$sub
  	}
  	
  , C =>
	{
  	b =>
  		{
  		a => 
  			{
  			a => 
  				{
  				}
  				
  			, b => sub
  				{
  				}
  			, c => 42
  			}
  			
  		}
  	}
  , ARRAY => [qw(elment_1 element_2 element_3)]
  } ;
    
  
  my $dumper = new Data::TreeDumper::OO() ;
  $dumper->UseAnsi(1) ;
  $dumper->SetMaxDepth(2) ;
  $dumper->SetFilter(\&Data::TreeDumper::HashKeysSorter) ;
  
  print $dumper->Dump($s, "Using OO interface") ;
  print $dumper->DumpMany
	  (
	    [$s, "title", MAX_DEPTH => 1]
	  , [$s2, "other_title", DISPLAY_ADDRESS => 0]
	  , USE_ASCII => 1
	  , MAX_DEPTH => 5
	  ) ;
  
=head1 Output

  title:
  |- A [H1]
  |  |- a [H2]
  |  |- bbbbbb = CODE(0x8139fa0) [C3]
  |  |- c123 [C4 -> C3]
  |  `- d [R5]
  |     `- REF(0x8139fb8) [R5 -> C3]
  |- ARRAY [A6]
  |  |- 0 [S7] = elment_1
  |  |- 1 [S8] = element_2
  |  `- 2 [S9] = element_3
  `- C [H10]
     `- b [H11]
        `- a [H12]
           |- a [H13]
           |- b = CODE(0x81ab130) [C14]
           `- c [S15] = 42
    
=head1 DESCRIPTION

Object oriented interface to Data::TreeDumper.

=head2 Object oriented Methods

  # constructor
  my $dumper = new Data::TreeDumper::OO(MAX_DEPTH => 1) ;
  
  $dumper->UseAnsi(1) ;
  $dumper->UseAscii(1) ;
  $dumper->SetMaxDepth(2) ;
  $dumper->SetIndentation('   ') ;
  $dumper->SetVirtualWidth(80) ;
  $dumper->SetFilter(\&Data::TreeDumper::HashKeysSorter) ;
  $dumper->SetLevelFilters({1 => \&Filter_1, 5 => \&Filter_5) ;
  $dumper->SetStartLevel(0) ;
  $dumper->QuoteHashKeys(1) ;
  $dumper->QuoteValues(0) ;
  $dumper->DisplayNoElements(1) ;
  $dumper->DisplayRootAddress(1) ;
  $dumper->DisplayAddress(0) ;
  $dumper->DisplayObjectType(0) ;
  $dumper->Displayinheritance(0) ;
  $dumper->DisplayAutoload(0) ;
  $dumper->DisplayTie(0) ;
  $dumper->DisplayPerlAddress(1) ;
  $dumper->DisplayPerlSize(0) ;
  $dumper->NumberLevels(2) ;
  $dumper->ColorLevels(\&ColorLevelSub) ;
  $dumper->SetGlyphs(['.  ', '.  ', '.  ', '.  ']) ;
  $dumper->NoOutput(1) ;
  $dumper->SetRenderer('DHTML') ;
  
  $dumper->Dump($s, "Using OO interface", %OVERRIDES) ;
  $dumper->DumpMany
            (
	      [$s, "dump1", %OVERRIDES]
	    , [$s, "dump2", %OVERRIDES]
	    , %OVERRIDES
	    ) ;
  	
=head1 DEPENDENCY

L<Data::TreeDumper>.

=head1 EXPORT

None.

=head1 SEE ALSO

L<Data::TreeDumper> - the base class for this module.

L<Data::Dumper> - convert perl data values
or variables to equivalent Perl syntax.

L<Data::Dumper::GUI> - a graphical interface on top of L<Data::Dumper>.

L<Data::Dumper::Sorted> - like L<Data::Dumper> but sorts hash keys
into alphabetic order.

L<Data::Dumper::HTML> - dump data into HTML with syntax highlighting.

L<Data::Dumper::Simple> and L<Data::Dumper::Names> work like L<Data::Dumper>
but include the original variable names in the output.

L<Data::Dumper::Perltidy> - combines L<Data::Dumper> and L<Perl::Tidy>
to stringify data in a pretty-printed format.

=head1 REPOSITORY

L<https://github.com/neilbowers/Data-TreeDumper-OO>

=head1 AUTHOR

Khemir Nadim ibn Hamouda. <nadim@khemir.net>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003-2014 Nadim Ibn Hamouda el Khemir. All rights reserved.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

If you find any value in this module, mail me!
All hints, tips, flames and wishes are welcome at <nadim@khemir.net>.

=cut

