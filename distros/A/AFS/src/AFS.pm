package AFS;

#------------------------------------------------------------------------------
# RCS-Id: "@(#)$RCS-Id: src/AFS.pm 7a64d4d Wed May 1 22:05:49 2013 +0200 Norbert E Gruener$"
#
# This library is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# © 2001-2011 Norbert E. Gruener <nog@MPA-Garching.MPG.de>
# © 1994 Board of Trustees, Leland Stanford Jr. University.
#
#  The original library is covered by the following copyright:
#
#     Redistribution and use in source and binary forms are permitted
#     provided that the above copyright notice and this paragraph are
#     duplicated in all such forms and that any documentation,
#     advertising materials, and other materials related to such
#     distribution and use acknowledge that the software was developed
#     by Stanford University.  The name of the University may not be used
#     to endorse or promote products derived from this software without
#     specific prior written permission.
#     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
#     IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#     WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#------------------------------------------------------------------------------

use Carp;

require Exporter;
require AutoLoader;
require DynaLoader;

use vars qw(@ISA $VERSION);

@ISA = qw(Exporter AutoLoader DynaLoader);

$VERSION = 'v2.6.4';

@CELL = qw (
            configdir
            expandcell
            getcell
            getcellinfo
            localcell
           );

@MISC = qw (
            afsok
            checkafs
            setpag
           );

@PTS = qw (
           newpts
           ascii2ptsaccess
           ptsaccess2ascii
          );

@CM = qw (
          cm_access
          checkconn
          checkservers
          checkvolumes
          flush
          flushcb
          flushvolume
          getcacheparms
          getcellstatus
          getfid
          getquota
          getvolstats
          isafs
          lsmount
          mkmount
          pioctl
          rmmount
          setcachesize
          setcellstatus
          setquota
          sysname
          unlog
          whereis
          whichcell
          wscell

          get_server_version
          get_syslib_version
          XSVERSION
          getcrypt
          setcrypt
         );

@ACL = qw (
           ascii2rights
           cleanacl
           copyacl
           crights
           getacl
           modifyacl
           newacl
           rights2ascii
           setacl
          );

@KA = qw (
          ka_AuthServerConn
          NOP_ka_Authenticate
          ka_CellToRealm
          ka_ExpandCell
          ka_GetAdminToken
          ka_GetAuthToken
          ka_GetServerToken
          ka_LocalCell
          ka_ParseLoginName
          ka_ReadPassword
          ka_SingleServerConn
          ka_StringToKey
          ka_UserAthenticateGeneral
          ka_UserReadPassword
          ka_des_string_to_key
          ka_nulltoken
         );

@KTC = qw (
           ktc_ForgetAllTokens
           ktc_GetToken
           ktc_ListTokens
           ktc_SetToken
           ktc_principal
           newprincipal
);

# Items to export into callers namespace by default
# (move infrequently used names to @EXPORT_OK below)
@EXPORT = (@CELL, @MISC, @PTS, @CM, @ACL, @KA, @KTC);

# Other items we are prepared to export if requested
@EXPORT_OK = qw(
                raise_exception
                constant
                convert_numeric_names
                error_message
               );

@ALL = (@EXPORT, @EXPORT_OK);

# convenience functions
#sub newacl { use AFS::ACL; AFS::ACL->new(@_); }
sub newacl { require AFS::ACL; AFS::ACL->import; AFS::ACL->new(@_); }

sub newpts { AFS::PTS->_new(@_); }

sub newprincipal { AFS::KTC_PRINCIPAL->_new(@_); }
sub ktc_principal { AFS::KTC_PRINCIPAL->_new(@_); }

sub ka_LocalCell { return &localcell; }
sub ka_ExpandCell { expandcell($_[0]); }
sub ka_CellToRealm { uc(expandcell($_[0])); }

sub afsok { $AFS::CODE == 0; }
sub checkafs { die "$_[0]: $AFS::CODE" if $AFS::CODE; }
sub get_server_version {
    my $server   = shift;
    my $hostname = shift;
    my $verbose  = shift;

    my %port = (
                'fs'  => 7000,
                'cm'  => 7001,
                'pts' => 7002,
                'vls' => 7003,
                'kas' => 7004,
                'vos' => 7005,
                'bos' => 7007,
               );

    if (! defined $port{$server}) { die "Server $server unknown ...\n"; }

    $hostname = 'localhost' unless defined $hostname;
    $verbose  = 0           unless defined $verbose;

    AFS::_get_server_version($port{$server}, $hostname, $verbose);
}


# acl helpers...
sub getacl { require AFS::ACL; AFS::ACL->import; AFS::_getacl(@_); }

sub modifyacl {
    my($path, $macl) = @_;
    my($acl);

    if ($acl = getacl($path)) {
        $acl->addacl($macl);
        return setacl($path, $acl);
    }
    else { return 0; }
}

sub copyacl {
    my($from, $to, $follow) = @_;
    my($acl);

    $follow = 1 unless defined $follow;
    if ($acl = _getacl($from, $follow)) { return setacl($to, $acl, $follow); }
    else { return 0; }

}

sub cleanacl {
    my($path, $follow) = @_;
    my($acl);

    $follow = 1 unless defined $follow;
    if ($acl = _getacl($path, $follow)) { return setacl($path, $acl, $follow); }
    else { return 0; }
}

# package AFS::PTS_SERVER;
# sub new { AFS::PTS->_new(@_); }

use AFS::KTC_PRINCIPAL;
# package AFS::KTC_PRINCIPAL;
# sub new { AFS::KTC_PRINCIPAL->_new(@_); }

use AFS::KAS;
# *** CAUTION ***
# these functions are now stored in AFS::KAS.pm  !!!
#package AFS::KA_AUTHSERVER;
# package AFS::KAS;

# sub getentry    { $_[0]->KAM_GetEntry($_[1],$_[2]); }
# sub debug       { $_[0]->KAM_Debug(&AFS::KAMAJORVERSION); }
# sub getstats    { $_[0]->KAM_GetStats(&AFS::KAMAJORVERSION); }
# sub randomkey   { $_[0]->KAM_GetRandomKey; }
# sub create      { $_[0]->KAM_CreateUser($_[1],$_[2],$_[3]); }
# sub setpassword { $_[0]->KAM_SetPassword($_[1],$_[2],$_[3],$_[4]); }
# sub delete      { $_[0]->KAM_DeleteUser($_[1],$_[2]); }
# sub listentry   { $_[0]->KAM_ListEntry($_[1],$_[2],$_[3]); }
# sub setfields   { $_[0]->KAM_SetFields($_[1],$_[2],$_[3],$_[4],$_[5],$_[6],$_[7],$_[8]); }


package AFS;

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.
    # taken from perl v5.005_02 for backward compatibility

    my $constname;

    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/ || $!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined AFS macro $constname";
	}
    }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
	if ($] >= 5.00561) {
	    *$AUTOLOAD = sub () { $val };
	}
	else {
	    *$AUTOLOAD = sub { $val };
	}
    }
    goto &$AUTOLOAD;
}

END {
    AFS::_finalize();
}

bootstrap AFS;

# Preloaded methods go here.  Autoload methods go after __END__, and are
# processed by the autosplit program.

1;
__END__

