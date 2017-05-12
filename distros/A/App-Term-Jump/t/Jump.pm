
use strict ;
use warnings ;

package t::Jump ;

require Exporter ;

our @ISA = qw(Exporter) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
our @EXPORT = qw(jump_test) ;
our $VERSION = '0.5' ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings qw(had_no_warnings);
use Test::Deep ;
use Test::More qw(no_plan) ;

use Cwd ;
use Test::MockModule ;
use Directory::Scratch ;
use File::Path::Tiny ;
use File::Spec ;
use Data::TreeDumper ;
use Data::TreeDumper::Utils qw(:all) ;
use Clone qw(clone) ;
use YAML ;
use File::Slurp ;

use App::Term::Jump ;

#------------------------------------------------------------------------------------------------------------------------

=head1

Implements I<jump_test>.

Each invocation of I<jump_test> will create a temporary directory and a structure of directories under it.

The tests listes in the call will be run sequentialy. I<jump_test> will stop at the first error an report 
the error as well as all the necessary information to debug the error.

=cut

sub jump_test
{
my (%setup_arguments) = @_ ;

$setup_arguments{caller} = join(':', @{[caller()]}[1 .. 2]) ;
$setup_arguments{name} =~ s/ +/_/g ;

if(exists $setup_arguments{directories_and_db})
	{
	@setup_arguments{'temporary_directory_structure', 'db_start'} = get_directories_and_db($setup_arguments{directories_and_db}) ;
	delete $setup_arguments{directories_and_db} ;
	}

my $start_directory = cwd() ;
my $test_directory = cwd() ;
my $using_temporary_directory = 0 ;

my ($jump_options, $command_line_arguments) = App::Term::Jump::parse_command_line() ; # sets default db and config

# temporary test directory
if(exists $setup_arguments{temporary_directory_structure})
	{
	my $temporary_directory_root = File::Spec->tmpdir() . "/jump_test_$setup_arguments{name}_" ;
	my $allowed_characters_in_directory_name = ['a' .. 'z'] ;
	$test_directory = create_directory_structure($setup_arguments{temporary_directory_structure}, $temporary_directory_root, '1234', $allowed_characters_in_directory_name) ;

	chdir($test_directory) or die "Error: Can't cd to temporary directory: $!\n" ;
	$using_temporary_directory++ ;

	# database --------------------------------------------------

	my @db_interpolated ;
	while (my ($k, $v) = each %{$setup_arguments{db_start}})
		{
		$k =~ s/TD/$test_directory/g ;
		$k =~ s/TEMPORARY_DIRECTORY/$test_directory/g ;
		push @db_interpolated, $k, $v ;
		}

	$jump_options->{db_location} = "$test_directory/temporary_jump_database" ;
	App::Term::Jump::write_db($jump_options, {@db_interpolated}) ;
	}

local $ENV{APP_TERM_JUMP_DB} = $jump_options->{db_location} if exists $jump_options->{db_location} ;
 
# tests -------------------------------------------------------

my $test_index = -1 ;
my $error ;

for my $test (@{$setup_arguments{tests}})
	{
	$test_index++ ;
	my $test_name = $test->{name} ||= "missing name '$setup_arguments{caller}'" ;

	do {diag "Skipping test '$test_name'\n"; next} if $test->{skip} ;

	# configuration ----------------------------------------------
	if(exists $test->{configuration})
		{ 
		$jump_options->{config_location} = "$test_directory/temporary_jump_configuration" ;

		File::Slurp::write_file($jump_options->{config_location}, $test->{configuration}) or die $! ;

		$test->{configuration_warning} = "temporarily overridding config!" if exists $setup_arguments{configuration} ;
		}
	elsif(exists $setup_arguments{configuration})
		{ 
		$jump_options->{config_location} = "$test_directory/temporary_jump_configuration" ;

		File::Slurp::write_file($jump_options->{config_location}, $setup_arguments{configuration}) or die $! ;
		}

	local $ENV{APP_TERM_JUMP_CONFIG} = $jump_options->{config_location} if exists $jump_options->{config_location} ;

	$test->{cd} =~ s/TD/$test_directory/g if exists $test->{cd} ;
	exists $test->{cd} ? chdir($test->{cd}) : chdir($test_directory) ;

	die "Error: need 'command' or 'commands' fields in a test '$test_name::$test_index'" , DumpTree($test)
		if ! exists $test->{command} &&  ! exists $test->{commands} ;

 	if(exists $test->{command})
		{
	 	die "Error: can't have 'command' and 'commands' fields in a test '$test_name::$test_index'" if exists $test->{commands} ;
		$test->{commands} = [$test->{command}] ;
		delete $test->{command} ;
		}
	
	$test->{db_expected} = {map { my $key = $_ ; s/TD/$test_directory/g ; s/TEMPORARY_DIRECTORY/$test_directory/g ; $_ => $test->{db_expected}{$key} }  keys %{$test->{db_expected}}}
		if exists $test->{db_expected} ;

	$test->{captured_output_expected} = [map { s/TD/$test_directory/g ; s/TEMPORARY_DIRECTORY/$test_directory/g ; $_ }  @{$test->{captured_output_expected}}]
		if exists $test->{captured_output_expected} ;

	$test->{matches_expected} = [map { s/TD/$test_directory/g ; s/TEMPORARY_DIRECTORY/$test_directory/g ; $_ }  @{$test->{matches_expected}}]
		if exists $test->{matches_expected} ;

	use IO::Capture::Stdout;
	my $capture = IO::Capture::Stdout->new();
	$capture->start();

	my $run_test_command = 
		sub
		{
		my ($commands) = @_ ;

		for my $command (@{ $commands })
			{
			$command =~ s/^\s+// ;
			$command =~ s/TD/$test_directory/g ;
			$command =~ s/TEMPORARY_DIRECTORY/$test_directory/g ;

			my ($matches, $parsed_options) ;
			eval ('($matches, $parsed_options)  = App::Term::Jump::' . $command) ;

			die $@ if $@ ;

			$test->{parsed_options} = $parsed_options if $test->{parsed_options} ;

			$test->{weight} =  $matches->[0]{weight} if @{$matches} ;
			$test->{weight_path} = $matches->[0]{cumulated_path_weight} if @{$matches} ;
			$test->{matches} = $matches ;
			}
		} ;

	if(exists $test->{warnings_expected})
		{
		warnings_like
		        {
			$run_test_command->($test->{commands}) ;
	        	} $test->{warnings_expected}, "warnings expected '$test_name::$test_index'" ;
		}
	else
		{
		$run_test_command->($test->{commands}) ;
		}

	$capture->stop() ;
	$test->{captured_output} = [map {chomp ; $_} $capture->read()] if exists $test->{captured_output_expected} ;
	
	$test->{db_after_command} = App::Term::Jump::read_db($jump_options) ;

	do { cmp_deeply($test->{captured_output}, $test->{captured_output_expected}, "output-$setup_arguments{name}-$test_name::$test_index") or $error++}
		if exists $test->{captured_output_expected} ;

	do 
		{
		 cmp_deeply
			(
			[ map{$_->{source} || $_->{path}} @{ $test->{matches} }],
			$test->{matches_expected},
			"matches-$setup_arguments{name}-$test_name::$test_index"
			) or $error++
		}
		if exists $test->{matches_expected} ;

	do { is($test->{weight}, $test->{weight_expected}, "weight-$setup_arguments{name}-$test_name::$test_index") or $error++}
		if exists $test->{weight_expected} ;
	
	do { is($test->{weight_path}, $test->{weight_path_expected}, "weight_path-$setup_arguments{name}-$test_name::$test_index") or $error++}
		if exists $test->{weight_path_expected} ;
	
	do { cmp_deeply($test->{db_after_command}, $test->{db_expected}, "DB contents-$setup_arguments{name}-$test_name::$test_index") or $error++ }
		if exists $test->{db_expected} ;
  
	if($error || $test->{show_test})
		{
		$setup_arguments{test_failed_index} = $test_index ;

		splice @{$setup_arguments{tests}}, $test_index + 1 ;

		#TODO: check if previous test->db_after_command is the same as current
		# uncluter, and make it clear it it the same, otherwise make it clear it changed

		diag DumpTree \%setup_arguments, "test: $setup_arguments{name}",
			DISPLAY_ADDRESS => 0, 
		        FILTER => \&first_nsort_last_filter,
			FILTER_ARGUMENT =>
				{
				AT_START_FIXED => ['name', 'commands'],
				#AT_END => [qr/AB/],
				} ;

        	#diag "test commands: pushd $test_directory ; APP_TERM_JUMP_DB='./database' jump_test --show_database xxx $test_directory\n" ;
		#diag "tree $test_directory\n" ;
		#diag "cat $test_directory/temporary_jump_database" ;
	
		last ;
		}
	else
		{
		# uncluter output 
		$setup_arguments{tests}[$test_index -1] = 'ok' unless $test_index == 0 ;
		$test = {db_after_command => $test->{db_after_command}} ;
		}
	}

chdir($start_directory) ;
File::Path::Tiny::rm($test_directory) if $using_temporary_directory && ! $error ;
}

# ---------------------------------------------------------------------------------------------------

sub create_directory_structure
{
my ($directory_structure, $temporary_directory_root, $template, $allowed_characters_in_directory_name) = @_ ;

my $temp_directory = create_temporary_directory($temporary_directory_root, $template, $allowed_characters_in_directory_name) or die "Error: Can't create temporary directory\n" ;

_create_directory_structure($directory_structure, $temp_directory) ;

return $temp_directory ;
}

# ---------------------------------------------------------------------------------------------------

sub _create_directory_structure
{
my ($directory_structure, $start_directory) = @_ ;
 
while( my ($entry_name, $contents) = each %{$directory_structure})
        {
        for($contents)
                {
                'HASH' eq ref $_ and do
                        {
                        File::Path::Tiny::mk("$start_directory/$entry_name") or die "Could not make directory '$start_directory/$entry_name': $!" ;
                        _create_directory_structure($contents, "$start_directory/$entry_name") ;
                        last ;
                        } ;
                         
                'ARRAY' eq ref $_ and do
                        {
			open my $file, '>', "$start_directory/$entry_name" or die "Could not open file '$start_directory/$entry_name': $!" ;
			print $file join("\n", @{ $contents }) ;
                        last ;
                        } ;
                         
                die "invalid element '$start_directory/$entry_name' in tree structure\n" ;
                }
        }
}

# ---------------------------------------------------------------------------------------------------

my $temporary_directory_increment = 0 ;

# ---------------------------------------------------------------------------------------------------

sub create_temporary_directory
{
my ($temporary_directory_root, $template, $allowed_characters_in_directory_name) = @_ ;

$temporary_directory_increment++ ;

my $dir ;
my $number_of_allowed_characters = @{$allowed_characters_in_directory_name} ;

for (1 .. 500)
	{
	my $template_try = $template =~ s/./$allowed_characters_in_directory_name->[int(rand($number_of_allowed_characters))]/ger ; 
	my $path = $temporary_directory_root . '_' . $$ . '_' . $temporary_directory_increment . '_' . $template_try ;

	if(File::Path::Tiny::mk($path))
		{
		$dir = $path ;
		last ;
		} 
	}

die "Could not create temporary directory '$temporary_directory_root': $!" unless defined $dir ;

return $dir ;
}

# ---------------------------------------------------------------------------------------------------

sub get_directories_and_db
{
my ($yaml) = @_ ;

my %db_paths ;

my $get_db_paths = sub
	{
	my ($structure, undef, $path) = @_ ;

	if('HASH' eq ref $structure)
		{
		if(exists $structure->{in_db})
			{
			$path =~ s[\{'(.+?)'\}][$1/]g;
			$path = 'TEMPORARY_DIRECTORY/' . $path ;
			$path =~ s[/$][] ;

			$db_paths{$path} = $structure->{in_db} ;

			delete $structure->{in_db} ;
			}
		}

	return(Data::TreeDumper::DefaultNodesToDisplay($structure)) ;
	} ;

$yaml = "---\n$yaml\n" ;
my $directory_structure = Load($yaml) ;

DumpTree $directory_structure, 'munged', NO_OUTPUT => 1, FILTER => $get_db_paths ;

#diag "YAML\n$yaml\n";
#diag DumpTree $directory_structure, 'Directories' ;
#diag DumpTree \%db_paths, 'DB' ;

return ($directory_structure, \%db_paths) ;
}

# ---------------------------------------------------------------------------------------------------

1 ;

