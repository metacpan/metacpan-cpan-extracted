#--------------------------------------------------------------------#
# Chef::Rest::Client Test Cases                                      #
# @author : Bhavin Patel                                             #
#--------------------------------------------------------------------#

# requried modules

use Test::More;

subtest 'Additional required modules' => sub {
	map 
	{
		use_ok( $_ );
	}
	(
		'File::Basename',
		'File::Spec::Functions',
		'parent',
		'Crypt::OpenSSL::RSA',
		'File::Slurp',
		'LWP::UserAgent',
		'Mojo::JSON',
		'Module::Load',
		'vars',
		
	);

};

subtest 'all module check' => sub {

	my @base;
		use File::Basename qw { dirname };
		use File::Spec::Functions qw { splitdir rel2abs };

  		@base = ( splitdir( rel2abs ( dirname ( __FILE__ ) ) ) );
  		pop @base;    
  		push @INC , join  '/', @base, 'lib';

	map
	{
		use_ok($_);
	}
	(
		'Chef',

		'Chef::Encoder',
		'Chef::Header',
		'Chef::REST',

		'Chef::REST::Client',

		'Chef::REST::Client::search',
		
		'Chef::REST::Client::recipe',

		'Chef::REST::Client::runlist',
		
		'Chef::REST::Client::clients',
				
		'Chef::REST::Client::EndPoints',

		'Chef::REST::Client::sandboxes',
		
		'Chef::REST::Client::principals',

		'Chef::REST::Client::envrunlist',

		'Chef::REST::Client::role',
		'Chef::REST::Client::roles',

		'Chef::REST::Client::node',
		'Chef::REST::Client::nodes',		

		'Chef::REST::Client::data',
		'Chef::REST::Client::databag',
		
		'Chef::REST::Client::cookbook',
		'Chef::REST::Client::cookbooks',

		'Chef::REST::Client::attribute',
		'Chef::REST::Client::attributes',

		'Chef::REST::Client::environment',
		'Chef::REST::Client::environments',
		
		'Chef::REST::Client::cookbook_version',
		'Chef::REST::Client::cookbook_versions',

	);

};

done_testing;