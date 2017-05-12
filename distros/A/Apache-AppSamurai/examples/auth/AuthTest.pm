# Apache::AppSamurai::AuthTest - Sample AppSamurai authentication plugin.

##### DO NOT USE THIS!  THIS IS A SAMPLE! #################################
#### Feel free to base your custom authenticaiton module on it, though ####

# $Id: AuthTest.pm,v 1.4 2007/09/13 07:00:16 pauldoom Exp $

package Apache::AppSamurai::AuthTest;
use strict;

use vars qw($VERSION @ISA);
$VERSION = substr(q$Revision: 1.4 $, 10, -1);

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

    if (($user eq 'satan') && ($pass eq '6666')) {
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
