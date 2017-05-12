package DCE::aclbase;

use strict;
use Carp;
use vars qw($VERSION @ISA $AUTOLOAD);

require DynaLoader;
require AutoLoader;

@ISA = qw(DynaLoader);

$VERSION = '1.00';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined DCE::aclbase macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap DCE::aclbase $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__


=head1 NAME

DCE::aclbase - Constants from dce/aclbase.h

=head1 SYNOPSIS

  use DCE::aclbase;

=head1 DESCRIPTION


=head1 AUTHOR

h2xs

=head1 SEE ALSO

DCE::ACL(3), perl(1).

=cut
