
package App::Chained::Test ;

use strict ;
use warnings ;
use Carp ;
use English qw( -no_match_vars ) ;

use lib qw(lib) ;
use parent 'App::Chained' ;

our $VERSION = '0.03' ;

=head1 THIS WRAPPER DOCUMENTATION

This will be automatically extracted as we set the B<help> fields to B<\&App::Chained::get_help_from_pod> 

=cut

sub run
{
my ($invocant, @setup_data) = @_ ;

my $class = ref($invocant) || $invocant ;
confess 'Invalid constructor call!' unless defined $class ;

my %options = (A => 'default', B => undef) ;

my $chained_app = 
	App::Chained->new
		(
		INTERACTION => {WARN => sub {warn @_}},
		
		help => \&App::Chained::get_help_from_pod, 
		version =>  $VERSION,
		apropos => undef,
		faq => undef,
		
		getopt_data => 	
			[
				['A=s' => \$options{A}, 'test from hash', 'long description'],
				['B' => \$options{B}, 'test from hash', 'long description'],
				['CCC|C=s' => \my $option, 'description', 'long description'],
			],
		
		sub_apps =>
			{
			# code example for code contained in a perl module
			test_module =>
				{
				description => 'module',
				apropos => [qw(module)],
				
				# save some private data we'll be re-using from the callbacks
				_MODULE_RUNNER => 
					sub
					{
					my ($self, $command, $arguments) =  @_ ;
					eval <<'EOE' ; 
					use lib qw(.) ;
					use test;
					
					test::main($arguments) ;
EOE
					$self->{INTERACTION}{DIE}("Error: Module run returned:\n\n" . $@) if($@) ;
					#~ system 'check_forbidden_words_nd/check_forbidden_words ' . join(' ', @{$arguments}) ;
					},
				
				run =>
					sub
					{
					my ($self, $command, $arguments) =  @_ ;
					$command->{_MODULE_RUNNER}($self, $command, $arguments) ;
					},
					
				help =>
					sub
					{
					my ($self, $command, $arguments) =  @_ ;
					$command->{_MODULE_RUNNER}($self, $command, ['--help']) ;
					},
					
				options =>
					sub
					{
					my ($self, $command, $arguments) =  @_ ;
					
					use Capture::Tiny qw(capture);
					
					my $runner = $command->{_MODULE_RUNNER} ;
					my ($stdout, $stderr) = 	capture { $runner->($self, $command, ['--dump_options']) };

					return split /\n/, $stdout ;
					},
				},
				
			# code example for code contained in an executable
			test_application =>
				{
				description => 'executable',
				run =>
					sub
					{
					my ($self, $command, $arguments) =  @_ ;
					system './test_application ' . join(' ', @{$arguments}) ;
					},
					
				help => sub {system "./test_application --help"},
				apropos => [qw(executable)],
				#~ options => sub{ ... },
				},
			},
			
		@setup_data,
		) ;

bless $chained_app, $class ;

$chained_app->parse_command_line() ;

# pass option  A and B to our sub command
#~ push @{$chained_app->{command_options}}, ('--A' => $options{A} ) if defined $options{A} ;
#~ push @{$chained_app->{command_options}}, ('--B_changed_to_X' => $options{B} ) if defined $options{B} ;

#~ use Data::TreeDumper ;
#~ print DumpTree $chained_app->{command_options}, 'options' ;

# run the command if we so want
$chained_app->SUPER::run() ;
}

#---------------------------------------------------------------------------------

package main ;

App::Chained::Test->run(command_line_arguments => \@ARGV) ;

