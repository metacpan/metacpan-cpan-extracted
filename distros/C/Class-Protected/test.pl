# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use Class::Protected;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

	use Class::NiceApi;

	use Class::Protected;

	use IO::Extended qw(:all);
	
	use Class::Maker::Examples::Human;

	my $acl = Class::NiceApi->new( victim => Decision::ACL->new(), style => 'custom', table => { run_acl => 'RunACL' } );
	
	$acl->push_rule(
		Decision::ACL::Rule->new({
			now => 0,
			
			action => 'allow', # Action to be applied when rule is concerned, allow, deny, permit or block.
			
			fields =>
			{
				pkg => 'User',	
				
				method => 'firstname',

				uid => 'murat',
			}
		}),
	);
	
	$acl->push_rule(
		Decision::ACL::Rule->new({			
			now => 0,
			
			action => 'deny',
			
			fields =>
			{
				pkg => 'User',	
				
				method => 'firstname',
									
				uid => 'john',
			}
		})
	);	

	$acl->push_rule(
		Decision::ACL::Rule->new({
			now => 0,
			
			action => 'deny',
			
			fields =>
			{
				pkg => 'User',	
					
				method => 'ALL',
													
				uid => 'james',
			}
		})
	);	

	for ( qw(murat john) )
	{
		println "$_ was ",

			{ Class::Protected::ACL_RULE_ALLOW() => 'granted', Class::Protected::ACL_RULE_DENY() => 'rejected' }->{

				$acl->run_acl(
					{
					pkg => 'User',

					method => 'firstname',

					uid => $_ ,
					}
				)
			};
	}
		# here we restrict access to $u's methods (see $ACL above)

	my $prot = Class::Protected->new( victim => Human->new( firstname => 'john', lastname => 'doe' ), acl => $acl );

	$Class::Protected::uid = 'murat';
	
	print $prot->firstname, "\n";	# everything ok since $Login::uid eq 'murat' (ACL allow)

	$Class::Protected::uid = 'james';

	print $prot->firstname, "\n";	# dies because ACL deny on user

__END__
