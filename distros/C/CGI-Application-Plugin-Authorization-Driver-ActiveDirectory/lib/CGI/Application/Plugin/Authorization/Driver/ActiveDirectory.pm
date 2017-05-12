package CGI::Application::Plugin::Authorization::Driver::ActiveDirectory;

use strict;
use warnings;

use base qw(CGI::Application::Plugin::Authorization::Driver);
use Net::LDAP;

our $VERSION = '0.01';

=head1 NAME

CGI::Application::Plugin::Authorization::Driver::ActiveDirectory - ActiveDirectory Authorization driver


=head1 SYNOPSIS

 use base qw(CGI::Application);
 use CGI::Application::Plugin::Authorization;

 __PACKAGE__->authz->config(
     DRIVER => [ 'ActiveDirectory',
		HOST      => 'ad.foo.org',
		BINDDN    => 'myself',
		BINDPW    => 'mypass',
		PRINCIPAL => 'foo.org',
	 ],
 );


=head1 METHODS

=head2 authorize_user

This method accepts a username followed by a list of group names and will return
true if the user belongs to at least one of the groups.

=cut

sub authorize_user {
    my $self     = shift;
    my $username = shift;
    my @groups   = @_;

    # verify that all the options are OK
    my @_options = $self->options;
	die "The ActiveDirectory driver requires a hash of options" if @_options % 2;
	my %options = @_options;

	use Net::LDAP;
	my $ldap = Net::LDAP->new($options{HOST}) or die "$@";

	my $mesg = $ldap->bind(
			$options{BINDDN}.'@'.$options{PRINCIPAL},
			password => $options{BINDPW},
	);
	$mesg->code && die $mesg->error; #die if error
	
	my $search_base = join(',',map("DC=".$_,split /\./, $options{PRINCIPAL}));
	$mesg = $ldap->search( # perform a search
			base   => $search_base,
			filter => "(&(objectClass=organizationalPerson)(objectClass=user)(sAMAccountName=$username))",
	);
	$mesg->code && die $mesg->error; #die if error

	foreach my $entry ($mesg->entries) {
			my @ad_groups = @{$entry->get_value('memberOf', asref => 1)};
			foreach my $ad_group (@ad_groups) {
					my @tmp_arr = split /,/, $ad_group;
					my $tmp_string = shift @tmp_arr;
					if($tmp_string =~ /^CN=(.*)$/i)
					{
							#here we have clear AD group name in $1
							my $clear_ad_group = $1;
							foreach my $group (@groups) {
									if($group eq $clear_ad_group)
									{
											$ldap->unbind;
											return 1; #authorized
									}
							}
					}
			}
	}

	return 0; #unauthorized if we r here
}


=head1 SEE ALSO

L<CGI::Application::Plugin::Authorization::Driver>, L<CGI::Application::Plugin::Authorization>, perl(1)


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Dmitry Sukhanov <hawkmoon@cpan.org>. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

=cut

1;
