package Crypt::Passwd;

########
# Crypt::Passwd - Perl 5 Interface for the UFC Crypt library
#
# Luis E. Munoz, lem@true.net
########

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(unix_std_crypt unix_ext_crypt);
$VERSION = '0.03';

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
		croak "Your vendor has not defined Crypt::Passwd macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap Crypt::Passwd $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Crypt::Passwd - Perl wrapper around the UFC Crypt

=head1 SYNOPSIS

  use Crypt::Passwd;
  
  $crypted_password = unix_std_crypt("password", "salt");
  $ultrix_password = unix_ext_crypt("password", "salt");

=head1 DESCRIPTION

This module provides an interface layer between Perl 5 and Michael
Glad's UFC Crypt library.

The interface is comprised in two functions, described below.

I<unix_std_crypt(passwd, salt)> provides an interface to the traditional
crypt() function, as implemented by the UFC library. It returns the crypted
password, perturbed with the salt.

I<unix_ext_crypt(passwd, salt)> provides the interface to the crypt16()
function, present in Ultrix and Digital Unix systems as implemented
in the UFC Library.

This code is provided as is, with no warranties. It is subject to the same
terms and conditions that Perl and the UFC Crypt library.

=head1 AUTHOR

Luis E. Munoz, lem@cantv.net

=head1 SEE ALSO

perl(1), crypt(3), fcrypt(3), crypt16(3)

=cut



