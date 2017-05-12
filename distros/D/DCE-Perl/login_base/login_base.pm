package DCE::login_base;

use strict;
use Carp;
use vars qw($VERSION @ISA $AUTOLOAD);

require DynaLoader;
require AutoLoader;

@ISA = qw(DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

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
		croak "Your vendor has not defined DCE::login_base macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap DCE::login_base $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__


=head1 NAME

DCE::login_base - Constants from sec_login_*.h 

=head1 SYNOPSIS

  use DCE::login_base;

=head1 DESCRIPTION

These constant methods are inherited by DCE::Login, a developer should not 
need to use this module and its methods directly.

=head1 AUTHOR

h2xs

=head1 SEE ALSO

perl(1), DCE::Login(3), DCE::Registry(3).

=cut

