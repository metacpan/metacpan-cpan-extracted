package Authen::Smb;

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
@EXPORT_OK = qw(
	NTV_LOGON_ERROR
	NTV_NO_ERROR
	NTV_PROTOCOL_ERROR
	NTV_SERVER_ERROR
);
$VERSION = '0.96';

sub authen {
  my @args = @_;

  # Truncate everything to length 80 to avoid poor coding practices in the
  # smbvalid.a (buffer overflows) PMK--fixme in smbvalid.a when possible.
  for my $i ( 0..$#args ) {
    $args[$i] = substr($args[$i], 0, 80);
  }

  my($username, $password, $server, $backup, $domain) = @args;

  my $res = Valid_User($username, $password, $server, $backup, $domain);
  $res
}


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
		croak "Your vendor has not defined Authen::Smb macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap Authen::Smb $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Authen::Smb - Perl extension to authenticate against an SMB server

=head1 SYNOPSIS

  use Authen::Smb;
  my $authResult = Authen::Smb::authen('myUser', 
                                       'myPassword',
                                       'myPDC',
                                       'myBDC',
                                       'myNTDomain');

  if ( $authResult == Authen::Smb::NO_ERROR ) {
    print "User successfully authenticated.\n";
  } else {
    print "User not authenticated with error level $authResult\n";
  }

=head1 DESCRIPTION

Authen::Smb allows you to authenticate a user against an NT domain.  You can
specify both a primary and a backup server to use for authentication.  The
NT names of the machines should be used for specifying servers.

An authentication request will return one of four values:

NTV_NO_ERROR (0)
NTV_SERVER_ERROR (1)
NTV_PROTOCOL_ERROR (2)
NTV_LOGON_ERROR (3)

NTV_NO_ERROR is the only return value possible for a successful authentication.
All other return values indicate failure, of one sort or another.

=head1 EXPORT_OK constants

  NTV_LOGON_ERROR
  NTV_NO_ERROR
  NTV_PROTOCOL_ERROR
  NTV_SERVER_ERROR


=head1 AUTHOR

Patrick Michael Kane, modus@pr.es.to
Based on the smbval library from the samba package
Additions for Apache::AuthenNTLM by Gerald Richter <richter@dev.ecos.de>

=head1 SEE ALSO

perl(1).

=cut
