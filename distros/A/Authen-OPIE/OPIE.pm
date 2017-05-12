package Authen::OPIE;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw(opie_challenge opie_verify);
$VERSION = '1.00';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined Auth::OPIE macro $constname";
	}
    }
    no strict 'refs';
    *$AUTOLOAD = sub () { $val };
    goto &$AUTOLOAD;
}

bootstrap Authen::OPIE $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Authen::OPIE - Perl module for opie (onetime password in everything)

=head1 SYNOPSIS

  use Authen::OPIE qw(opie_challenge, opie_verify);

  $challenge = opie_challenge($login);
  $result = opie_verify($login, $response);

=head1 DESCRIPTION

This module gives perl access to the challenge and verify aspects of the opie library. To issue a challenge you pass the login name to opie_challenge it returns a string like otp-md5 2390 ra5690 ext.  This is the challenge you pass on to whatever is communicating with you.  In return you'll get a response from them with which you call opie_verify.  opie_verify returns a 0 if it is the proper response to the challenge (they passed) and 1 otherwise (they failed).

opie is available from http://www.inner.net/opie
opie must be installed and set up on the box before this module is useful (though be aware that you might not want to do a straight install as opie replaces su and login).

When running the test you can use opiekey to generate a response to the challenge.


=head1 WARRANTY

This module comes with no warranty either expressed or implied.  I am not
responsible for any damages that may result from the use of this module,
including but not limited to monetary loss, mental distress, or general
mayhem


=head1 AUTHOR

Eric Estabrooks, eric@urbanrage.com, Copyright 2000,2001

=head1 SEE ALSO

perl(1) opiekey(1)

=cut
