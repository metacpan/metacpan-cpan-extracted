# set_get_default test

use strict ;
use warnings ;
use Test::Exception ;
use Test::Warn ;
#~ use Test::NoWarnings qw(had_no_warnings) ;

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Data::TreeDumper ;

use Config::Hierarchical ; 
use Eval::Context ;

{
local $Plan = {'eval' => 11} ;

sub eval_engine
{
#~ make Get() ConfigGet() $config->{} $config{}  $variable '%config' available

my ($config, $arguments) = @_ ;

my $hash_ref = $config->GetHashRef() ;

my $code = $arguments->{EVAL} ;
$code =~ s/%([a-zA-Z0-9]+)/Get('$1')/g ; # %A, %B test with my %hash  = () ;

my $context 
	= new Eval::Context
		(
		PRE_CODE => "use strict;\nuse warnings;\n\n",
		FILE => $arguments->{FILE},
		LINE => $arguments->{LINE},
		INSTALL_SUBS =>	
			{
			Get => sub {my ($name) = @_ ; $config->Get(NAME => $name) ;}, # Get('A')
			ConfigGet => sub {$config->Get(@_) ;}, # ConfigGet(NAME => 'A', ...)
			},
		INSTALL_VARIABLES => 
			[
			(map {["\$$_" => $hash_ref->{$_} ]} keys %$hash_ref), # $A, $B, $C
			['%config' => $hash_ref], # $config{A}, not shared
			['$config' => $hash_ref], # $config->{A}, not shared
			],
			
		INTERACTION => # we want a less verbose output
			{
			EVAL_DIE => sub {my($self, $error) = @_ ; croak $error },
			},
		) ;

my $value = eval { $context->eval(CODE => $code, FILE => $arguments->{FILE}, LINE => $arguments->{LINE}) ; } ;

if($@)
	{
	$config->{INTERACTION}{DIE}->
		("Error: Config::Hierarchical evaluating variable '$arguments->{NAME}' at $arguments->{FILE}:$arguments->{LINE}:\n\t ". $@)
	}
	
return $value ;
}

my $config = new Config::Hierarchical
				(
				CATEGORY_NAMES         => [ 'PARENT', 'LOCAL', 'CURRENT', ],
				DEFAULT_CATEGORY       => 'CURRENT',
				INTERACTION            =>
					{
					# work around error in Test::Warn
					WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
					DIE => 	sub { croak $_[0] }, # less verbose output
					},
						
				EVALUATOR => \&eval_engine,
				
				INITIAL_VALUES  =>
					[
					{NAME => 'A',  VALUE => '1'},
					{NAME => 'B',  VALUE => '3'},
					{NAME => 'C', EVAL => '%A'},
					] ,
				) ;

$config->SetMultiple
	(
	[NAME => 'D',  EVAL => q~ Get('B') * 2 * $A ~],
	[NAME => 'E',  EVAL => '%B . "hi"'],
	#[NAME => 'F',  EVAL => '%B - 20', VALIDATORS => { positive => sub{$_[0] > 0} }],
	[NAME => 'G', EVAL => q~ $A x 2 ~],
	[NAME => 'H', EVAL => q~ $config{A} * 2 ~],
	[NAME => 'I', EVAL => q~ $config->{B} * 2 ;~],
	[NAME => 'J', EVAL => q~ ConfigGet(NAME => 'B') ;~],
	) ;

is($config->Get(NAME => 'C'), 1, 'eval with %') ;
is($config->Get(NAME => 'D'), 6, 'eval with function call') ;
is($config->Get(NAME => 'E'), '3hi', 'eval % and perl code') ;
is($config->Get(NAME => 'G'), '11', 'eval $A') ;
is($config->Get(NAME => 'H'), '2', 'eval using %hash') ;
is($config->Get(NAME => 'I'), '6', 'eval using $hash') ;
is($config->Get(NAME => 'J'), $config->Get(NAME => 'B'), 'eval using GetConfig()') ;

throws_ok
	{
	$config->Set(NAME => 'F', EVAL => '$Z', VALUE => 42) ;
	} qr /Anonymous: Can't have 'VALUE' and 'EVAL'/, 'EVAL and VALUE';
	
throws_ok
	{
	$config->Set(NAME => 'F', EVAL => '%B - 20', VALIDATORS => { positive => sub{$_[0] > 0} }) ;
	} qr /Invalid value '-17' for variable 'F'/, 'evaled variables are validated';
	
throws_ok
	{
	$config->Set(NAME => 'F', EVAL => '$Z') ;
	} qr /Global symbol "\$Z" requires explicit package name/, 'strict variable definition';

throws_ok
	{
	$config->Set(NAME => 'K', EVAL => q~ ConfigGet('B' => 'C') ;~) ;
	} qr /Anonymous: Invalid Option 'B'/, 'error within the eval';

# eval using an unset variable
#	function call
#	function call, undefined sub
#	multiline code
#	local variable (closure)
#	string where something is not to be evaled
}


{
local $Plan = {'eval in safe' => 5} ;

my $config = new Config::Hierarchical
	(
	EVALUATOR => # test the code without transformation but in a safe compartment
		sub 	
		{
		my ($config, $options) = @_ ;
		my $context = new Eval::Context(SAFE => {}) ;
		$context->eval(CODE => $options->{EVAL}, FILE => $options->{FILE}, LINE => $options->{LINE}) ; 
		},
	) ;

throws_ok
	{
	$config->Set(NAME => 'D',  EVAL => q~ unknown_function('B')~) ;
	} qr/Undefined subroutine &main::unknown_function/, 'unknown function' ;

warning_like
	{
	throws_ok
		{
		$config->Set(NAME => 'E',  EVAL => q~ Get('B)~) ;
		#~ } qr/Can't find string terminator "'" anywhere before EOF at 'Anonymous_called_at_t_020_eval.t:200' line 11/, 'die of syntax error '
		} qr/Can't find string terminator "'" anywhere before EOF at 'Anonymous_called_at_t_020_eval.t:/, 'die of syntax error '
	} 
	[
	qr/Bareword found where operator expected /,
	qr/Missing operator before Anonymous_called_at_/,
	qr/String found where operator expected/,
	qr/Missing operator before ?/
	], 'syntax error warnings' ;
	
throws_ok
	{
	$config->Set(NAME => 'F',  EVAL => q~ unlink('dksjldkfjlkd')~) ;
	} qr/'unlink' trapped by operation mask/, 'catch unlink' ;


throws_ok
	{
	$config->Set(NAME => 'G',  EVAL => q~ open FILE, '<dksjldkfjlkd' ;~) ;
	} qr/'open' trapped by operation mask/, 'catch open' ;
}

{
local $Plan = {'bad EVALUATOR' => 1} ;

throws_ok
	{
	my $config = new Config::Hierarchical(EVALUATOR => 1) ;
	} qr/Anonymous: Invalid 'EVALUATOR' definition, expecting a sub reference/, 'bad evaluator definition' ;
}

{
local $Plan = {'no EVALUATOR' => 1} ;

throws_ok
	{
	my $config = new Config::Hierarchical() ;
	$config->Set(NAME => 'D',  EVAL => q~~) ;

	} qr/Anonymous: No 'EVALUATOR' defined/, 'bad evaluator definition' ;
}