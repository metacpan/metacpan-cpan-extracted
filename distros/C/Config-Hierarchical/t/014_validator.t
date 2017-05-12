# utilities test

use strict ;
use warnings ;
use Test::Exception ;

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Test::NoWarnings qw(had_no_warnings);
use Test::Warn ;

use Data::TreeDumper ;
use Config::Hierarchical ; 

sub PositiveValueValidator
{
my ($value) = @_; 
return($value >= 0)
} ;

sub NegativeValueValidator
{
my ($value) = @_; 
return($value < 0)
} ;


{
local $Plan = {'local validator' => 1} ;

my $config = new Config::Hierarchical
		(
		INTERACTION            =>
			{
			# work around error in Test::Warn
			WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
			},
		) ;
		
throws_ok
	{
	$config->Set
		(
		NAME => 'CC',
		VALUE => -1, 
		VALIDATORS => {positive_value => \&PositiveValueValidator,},
		) ;	
	} qr/Invalid value '-1' for variable 'CC'. Local validator 'positive_value' defined at .*/, "local validator" ;
}

{
local $Plan = {'local validator + verbose + validator OK' => 3} ;

warnings_like
	{
	my $config = new Config::Hierarchical
			(
			INTERACTION            =>
				{
				# work around error in Test::Warn
				INFO  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
				},
				
			VERBOSE => 1,
			) ;
			
	lives_ok
		{
		warnings_like
			{
			$config->Set
				(
				NAME => 'CC',
				VALUE => 1, 
				VALIDATORS => {positive_value => \&PositiveValueValidator,},
				) ;	
			}
			[
			qr/etting 'CURRENT::CC'/,
			qr/running local validator/,
			], 'verbose' ;
		
		} "local validator OK" ;
	}
	[
	qr/Creating Config::Hierarchical/
	], 'creation information' ;
}

{
local $Plan = {'validator override' => 2} ;

warnings_like
	{
	my $config = new Config::Hierarchical
			(
			CATEGORY_NAMES => ['CLI', 'CURRENT',] ,
			DEFAULT_CATEGORY => 'CURRENT' ,
			
			INTERACTION            =>
				{
				# work around error in Test::Warn
				WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
				},
				
			VALIDATORS =>
				[
				{
				CATEGORY_NAMES => ['CURRENT'] ,
				NAMES          => ['CC', 'LD'],
				VALIDATORS     => {the_validator => \&PositiveValueValidator},
				},
				
				{
				CATEGORY_NAMES => ['CURRENT',] ,
				NAMES          => ['CC', 'LD'],
				VALIDATORS     => {the_validator => \&NegativeValueValidator, },
				},
				],
			) ;
			
	throws_ok
		{
		$config->Set(NAME => 'CC', VALUE => 1,) ;	
		} qr/Invalid value '1' for variable 'CC'. Validator 'the_validator' defined at .*/, 'using overridden validator' ;
		
	#~ diag $config->GetDump() ;
	
	} 
	[
	qr/Overriding variable 'CC' validator 'the_validator'/,
	qr/Overriding variable 'LD' validator 'the_validator'/,
	], 'validator override' ;
}

{
local $Plan = {'validator invalid setup' => 10} ;

throws_ok
	{
	my $config = new Config::Hierarchical
			(
			INTERACTION            =>
				{
				# work around error in Test::Warn
				WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
				},
			VALIDATORS =>
				[
				{
				CATEGORY_NAMES => ['INVALID'] ,
				NAMES          => ['CC', 'LD'],
				VALIDATORS     => {positive_value => \&PositiveValueValidator},
				},
				]
			) ;
	} qr/Invalid category 'INVALID' in validator setup /, 'validator invalid category' ;
	

throws_ok
	{
	my $config = new Config::Hierarchical
			(
			INTERACTION            =>
				{
				# work around error in Test::Warn
				WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
				},
			VALIDATORS => [1], 
			) ;
	} qr/Invalid validator definition/, 'validator is not hash ref' ;
	
throws_ok
	{
	my $config = new Config::Hierarchical
			(
			INTERACTION            =>
				{
				# work around error in Test::Warn
				WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
				},
			VALIDATORS =>
				[
				{
				CATEGORY_NAMES => ['CURRENT'] ,
				NAMES          => ['CC', 'LD'],
				VALIDATORS     => {positive_value => \&PositiveValueValidator},
				INVALID => 1,
				},
				]
			) ;
	} qr/Invalid validator definition/, 'too many arguments' ;
	
throws_ok
	{
	my $config = new Config::Hierarchical
			(
			INTERACTION            =>
				{
				# work around error in Test::Warn
				WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
				},
			VALIDATORS =>
				[
				{
				NAMES          => ['CC', 'LD'],
				VALIDATORS     => {positive_value => \&PositiveValueValidator},
				FILLER => 1,
				},
				]
			) ;
	} qr/Invalid validator definition/, 'missing CATEGORY_NAMES' ;
	
throws_ok
	{
	my $config = new Config::Hierarchical
			(
			INTERACTION            =>
				{
				# work around error in Test::Warn
				WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
				},
			VALIDATORS =>
				[
				{
				NAMES          => ['CC', 'LD'],
				VALIDATORS     => {positive_value => \&PositiveValueValidator},
				CATEGORY_NAMES => 1,
				},
				]
			) ;
	} qr/Invalid validator definition/, 'CATEGORY_NAMES of wrong type' ;
	
throws_ok
	{
	my $config = new Config::Hierarchical
			(
			INTERACTION            =>
				{
				# work around error in Test::Warn
				WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
				},
			VALIDATORS =>
				[
				{
				CATEGORY_NAMES          => ['CURRENT'],
				VALIDATORS     => {positive_value => \&PositiveValueValidator},
				FILLER => 1,
				},
				]
			) ;
	} qr/Invalid validator definition/, 'missing NAMES' ;
	
throws_ok
	{
	my $config = new Config::Hierarchical
			(
			INTERACTION            =>
				{
				# work around error in Test::Warn
				WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
				},
			VALIDATORS =>
				[
				{
				CATEGORY_NAMES          => ['CURRENT'],
				VALIDATORS     => {positive_value => \&PositiveValueValidator},
				NAMES => 1,
				},
				]
			) ;
	} qr/Invalid validator definition/, 'NAMES of wrong type' ;
	
throws_ok
	{
	my $config = new Config::Hierarchical
			(
			INTERACTION            =>
				{
				# work around error in Test::Warn
				WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
				},
			VALIDATORS =>
				[
				{
				CATEGORY_NAMES          => ['CURRENT'],
				NAMES => ['CC'],
				FILLER => 1,
				},
				]
			) ;
	} qr/Invalid validator definition/, 'missing VALIDATORS' ;
	
throws_ok
	{
	my $config = new Config::Hierarchical
			(
			INTERACTION            =>
				{
				# work around error in Test::Warn
				WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
				},
			VALIDATORS =>
				[
				{
				CATEGORY_NAMES          => ['CURRENT'],
				NAMES => ['CC'],
				VALIDATORS     =>  1,
				},
				]
			) ;
	} qr/Invalid validator definition/, 'VALIDATORS of wrong type' ;

throws_ok
	{
	my $config = new Config::Hierarchical
			(
			INTERACTION            =>
				{
				# work around error in Test::Warn
				WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
				},
			VALIDATORS =>
				[
				{
				CATEGORY_NAMES          => ['CURRENT'],
				NAMES => ['CC'],
				VALIDATORS     =>  { wrong_type => 1},
				},
				]
			) ;
	} qr/Invalid validator 'wrong_type' \(must be a code reference\)/, 'VALIDATORS of wrong type' ;
}

{
local $Plan = {'verbose' => 1} ;

warnings_like
	{
	my $config = new Config::Hierarchical
			(
			VERBOSE => 1,
			
			CATEGORY_NAMES => ['CLI', 'CURRENT',] ,
			DEFAULT_CATEGORY => 'CURRENT' ,
				
			VALIDATORS =>
				[
				{
				CATEGORY_NAMES => ['CLI', 'CURRENT',] ,
				NAMES          => ['CC', 'LD'],
				VALIDATORS     => {positive_value => \&PositiveValueValidator},
				},
				],
				
			INTERACTION            =>
				{
				# work around error in Test::Warn
				INFO  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp "$message\n"; },
				},
			) ;

	$config->Set(CATEGORY => 'CLI', NAME => 'CC', VALUE => 0 ,) ;
	}
	[
	qr/Creating Config::Hierarchical 'Anonymous'/, 
	qr/Adding validator 'positive_value'.*'CLI::CC'/,
	qr/Adding validator 'positive_value'.*'CLI::LD'/,
	qr/Adding validator 'positive_value'.*'CURRENT::CC'/,
	qr/Adding validator 'positive_value'.*'CURRENT::LD'/,
	qr/Setting 'CLI::CC' to '0'/,
	qr/running validator 'positive_value'.*on 'CLI::CC'/,
	], 'verbosity' ;
}

{
local $Plan = {'multiple validator set before value exists' => 1} ;

my $config = new Config::Hierarchical
		(
		CATEGORY_NAMES => ['CLI', 'CURRENT',] ,
		DEFAULT_CATEGORY => 'CURRENT' ,
		
		INTERACTION            =>
			{
			# work around error in Test::Warn
			WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
			},
			
		VALIDATORS =>
			[
			{
			CATEGORY_NAMES => ['CLI'] ,
			NAMES          => ['CC', 'LD'],
			VALIDATORS     => {positive_value => \&PositiveValueValidator},
			},
			
			{
			CATEGORY_NAMES => ['CURRENT',] ,
			NAMES          => ['CC', 'LD'],
			VALIDATORS     => {positive_value => \&PositiveValueValidator},
			},
			],
		) ;

$config->Set(CATEGORY => 'CLI', NAME => 'CC', VALUE => 0 ,) ;
$config->Set(CATEGORY => 'CURRENT', NAME => 'CC', VALUE => 0 ,) ;

throws_ok
	{
	$config->Set(NAME => 'LD', VALUE => -1 ,) ;
	} qr/Invalid value '-1' for variable 'LD'. Validator 'positive_value' defined at/, "" ;
}

{
local $Plan = {'multiple category validator' => 2} ;

my $config = new Config::Hierarchical
		(
		CATEGORY_NAMES => ['CLI', 'CURRENT',] ,
		DEFAULT_CATEGORY => 'CURRENT' ,
		
		INTERACTION            =>
			{
			# work around error in Test::Warn
			WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
			},
		VALIDATORS =>
			[
			{
			CATEGORY_NAMES => ['CLI', 'CURRENT'] ,
			NAMES          => ['CC', 'LD'],
			VALIDATORS     => {positive_value => \&PositiveValueValidator},
			},
			],
		) ;

$config->Set(CATEGORY => 'CLI', NAME => 'CC', VALUE => 0 ,) ;
$config->Set(CATEGORY => 'CURRENT', NAME => 'CC', VALUE => 0 ,) ;

throws_ok
	{
	$config->Set(CATEGORY => 'CLI', NAME => 'LD', VALUE => -1 ,) ;
	} qr/Invalid value '-1' for variable 'LD'. Validator 'positive_value' defined at/, 'CLI validator' ;
	
throws_ok
	{
	$config->Set(CATEGORY => 'CURRENT', NAME => 'LD', VALUE => -1 ,) ;
	} qr/Invalid value '-1' for variable 'LD'. Validator 'positive_value' defined at/, 'CURRENT validator' ;
}

{
local $Plan = {'validators check for current value' => 4} ;

my $config = new Config::Hierarchical
		(
		CATEGORY_NAMES => ['CLI', 'CURRENT',] ,
		DEFAULT_CATEGORY => 'CURRENT' ,
		INTERACTION            =>
			{
			# work around error in Test::Warn
			WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
			},
		) ;

$config->Set(CATEGORY => 'CLI', NAME => 'CC', VALUE => -1 ,) ;
$config->Set(CATEGORY => 'CURRENT', NAME => 'CC', VALUE => -1 ,) ;

lives_ok
	{
	$config->AddValidator
			(
			CATEGORY_NAMES => ['CLI'] ,
			NAMES          => ['CC', 'LD'],
			VALIDATORS     => {minus_one => sub{$_[0] == -1}},
			) ;
	}'AddValidator ok' ;

throws_ok
	{
	$config->AddValidator
			(
			CATEGORY_NAMES => ['CLI'] ,
			NAMES          => ['CC', 'LD'],
			VALIDATORS     => {positive_value => \&PositiveValueValidator},
			) ;
	} qr/Invalid value '-1' for variable 'CC'. Validator 'positive_value' defined at/, 'AddValidator CLI' ;

#~ diag $config->GetDump() ;

warning_like
	{
	throws_ok
		{
		$config->AddValidator
				(
				CATEGORY_NAMES => ['CLI', 'CURRENT'] ,
				NAMES          => ['CC', 'LD'],
				VALIDATORS     => {positive_value => \&PositiveValueValidator},
				) ;
		} qr/Invalid value '-1' for variable 'CC'. Validator 'positive_value' defined at/, 'AddValidator CLI CURRENT';
	} qr/Overriding variable 'CC' validator 'positive_value/, 'overriding validator';
}

{
local $Plan = {'no override message' => 1} ;

my $config = new Config::Hierarchical
		(
		CATEGORY_NAMES => ['<PROTECTED>', 'CURRENT'] ,
		DEFAULT_CATEGORY => 'CURRENT' ,

		INTERACTION            =>
			{
			# work around error in Test::Warn
			WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
			},
		VALIDATORS =>
			[
			{
			CATEGORY_NAMES => ['PROTECTED'] ,
			NAMES          => ['CC'],
			VALIDATORS     => {positive_value => \&PositiveValueValidator},
			},
			]
		) ;
		
$config->Set(NAME => 'CC', VALUE => 1, OVERRIDE => 1) ;	

had_no_warnings() ;
}

{
local $Plan = {'no override message' => 1} ;

my $config = new Config::Hierarchical
		(
		CATEGORY_NAMES => ['<PARENT>', 'CURRENT'] ,
		DEFAULT_CATEGORY => 'CURRENT' ,

		INTERACTION            =>
			{
			# work around error in Test::Warn
			WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
			},
		VALIDATORS =>
			[
			{
			CATEGORY_NAMES => ['PARENT'] ,
			NAMES          => ['CC'],
			VALIDATORS     => {positive_value => \&PositiveValueValidator},
			},
			]
		) ;
		
$config->Set(NAME => 'CC', VALUE => 1, OVERRIDE => 1) ;	

had_no_warnings() ;
}

{
local $Plan = {'same value, no override message' => 1} ;

my $config = new Config::Hierarchical
		(
		CATEGORY_NAMES => ['PARENT', 'CURRENT'] ,
		DEFAULT_CATEGORY => 'CURRENT' ,

		INTERACTION            =>
			{
			# work around error in Test::Warn
			WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
			},
		VALIDATORS =>
			[
			{
			CATEGORY_NAMES => ['PARENT'] ,
			NAMES          => ['CC'],
			VALIDATORS     => {positive_value => \&PositiveValueValidator},
			},
			]
		) ;
		
#~ $config->Set(CATEGORY => 'PARENT', NAME => 'CC', VALUE => 1) ;	
$config->Set(NAME => 'CC', VALUE => 1, OVERRIDE => 1) ;	

had_no_warnings() ;
}

{
local $Plan = {'variable name validator' => 5} ;

throws_ok
	{
	my $config = new Config::Hierarchical( SET_VALIDATOR => qr//) ;
	} qr/Invalid 'SET_VALIDATOR' definition, expecting a sub reference/, 'non sub ref name validator' ;

sub my_set_validator
	{
	my ($config, $options, $location) = @_ ;
	
	# check the variable name
	if($options->{NAME} !~ /^CFG_[A-Z]+/)
		{
		$config->{INTERACTION}{DIE}->("$config->{NAME}: Invalid variable name '$options->{NAME}' at at '$location'!")
		}
	}
	
throws_ok
	{
	my $config = new Config::Hierarchical(SET_VALIDATOR => \&my_set_validator) ;
	$config->Set(NAME => 'CC', VALUE => 1) ;
	
	} qr/Invalid variable name 'CC' at /, 'invalid variable name' ;

lives_ok
	{
	my $config = new Config::Hierarchical(SET_VALIDATOR => \&my_set_validator) ;
	
	$config->Set(NAME => 'CFG_A', VALUE => 1) ;
	} 'valid variable name' ;

lives_ok
	{
	my $config = new Config::Hierarchical(SET_VALIDATOR =>\&my_set_validator) ;
	
	$config->Set(NAME => 'CC', VALUE => 1,  SET_VALIDATOR => sub{}) ;
	} 'set_validator override' ;

had_no_warnings() ;
}
