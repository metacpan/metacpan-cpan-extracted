package Class::Protected;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01.02';
our $DEBUG = 0;

use Carp;

use Class::Maker;

use Class::Proxy;

use Decision::ACL;
use Decision::ACL::Rule;
use Decision::ACL::Constants qw(:rule);

use IO::Extended qw(:all);

our $uid;

Class::Maker::class
{
	isa => [qw( Class::Proxy )],

	public =>
	{
		hash => [qw( table )],

		ref => { acl => 'Decision::ACL' },
	},

	default =>
	{
		events =>
		{
			method => sub
			{
				my ( $this, $e, $m, $victim, $args ) = @_;

				my $uid = shift @{$args};

				unless( ACL_RULE_ALLOW eq $this->test_acl( pkg => ref ${ $victim }, method => ${ $m }, uid => $Class::Protected::uid ) )
				{
					croak sprintf "Die because of ACL restrictions on protected class '%s'. '%s' is rejected to access method '%s'", ref ${ $victim }, $Class::Protected::uid, ${$m} ;
				}
			},
		},
	},
};

sub add_acl_rule : method
{
	my $this = shift;

	my %rule = @_;
	
return $this->acl->push_rule( Decision::ACL::Rule->new( \%rule ) );
}

sub test_acl : method
{
	my $this = shift;

	my %rule = @_;
	
return $this->acl->run_acl( \%rule );
}		
		# guard is only working on blessed references (tie interface for Class::Proxy could
		# wave this constrain).
1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Class::Protected - restricting class/method access via ACL's

=head1 SYNOPSIS

  use Class::Protected;

       # We build the ACL

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
		# Restrict access to $u's methods (see $ACL above)

	my $prot = Class::Protected->new( victim => Human->new( firstname => 'john', lastname => 'doe' ), acl => $acl );

	$Class::Protected::uid = 'murat';

	print $prot->firstname, "\n";	# everything ok since $Class::Protected::uid eq 'murat' (ACL allow)

	$Class::Protected::uid = 'james';

	print $prot->firstname, "\n";	# dies because ACL deny on user


=head1 DESCRIPTION

With this module you can protect the methods of any object. The access is handled via an ACL (L<Decision::ACL>).
C<Class::Protected> is implemented via a proxy object (L<Class::Proxy>).

=head2 METHODS

=over 4

=item new()

The constructor takes following parameters, which are also instance methods.

=over 4

=item victim (default: none)

The instance to be protected.

=item acl (default: none)

The C<Decision::ACL> object.

=back

=back

=head2 USER

The current user id should be stored to C<$Class::Protected::uid>.

=head2 EXPORT

None by default.

=head1 AUTHOR

M. Uenalan, E<lt>muenalan@cpan.orgE<gt>

=head1 SEE ALSO

L<Class::Proxy>, L<Decision::ACL>.

=cut
