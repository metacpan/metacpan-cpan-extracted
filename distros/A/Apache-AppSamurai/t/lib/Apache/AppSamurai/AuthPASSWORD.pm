# Apache::AppSamurai::Auth(&^*(^%&^ - Test auth modules

##### DO NOT USE THIS!  See examples/auth/AuthTest.pm for a start #####

# $Id: AuthPASSWORD.pm,v 1.1 2007/08/23 07:46:54 pauldoom Exp $

package Apache::AppSamurai::AuthPASSWORD;
use strict;

# Keep VERSION (set manually) and REVISION (set by CVS)
use vars qw($VERSION $REVISION @ISA);
$VERSION = '0.01';
$REVISION = substr(q$Revision: 1.1 $, 10);

use Carp;
use Apache::AppSamurai::AuthBase;

@ISA = qw( Apache::AppSamurai::AuthBase );

sub Configure {
    my $self = shift;
    
    # Pull defaults from AuthBase and save.
    $self->SUPER::Configure();
    my $conft = $self->{conf};

    # Initial configuration.  Put defaults here before the @_ args are
    # pulled in.
    $self->{conf} = { %{$conft},
		      TestThing => "MegaGarbage",
		      @_,
		  };
    return 1;
}

sub Initialize {
    my $self = shift;

    # Well, this is a dumb test module, so there isn't anything to do.

    return 1;
}


# Make a backdoor.  Yes, in case you didn't read above, let me reiterate:
# DO NOT USE THIS MODULE IN PRODUCTION!!!!
sub Authenticator {
    my $self = shift;
    my $user = shift;
    my $pass = shift;

    # This is the sort of hard-hitting security coding I deserve
    # an award for....
    if (($user) && ($pass =~ /password/i)) {
	return 1; # Ok!
    }

    # DEFAULT DENY #
    return 0;
}
    
1;

__END__

=head1 NAME

Apache::AppSamurai::AuthWhatchamcallit

=head1 SYNOPSIS

=head1 DESCRIPTION

Describe this thing

=head1 USAGE

=head1 METHODS

=head1 EXAMPLES

=head1 SEE ALSO

L<Apache::AppSamurai>, L<Apache::AppSamurai::AuthBase>

=head1 AUTHOR

=head1 BUGS

=head1 SUPPORT

=head1 COPYRIGHT & LICENSE

=cut
