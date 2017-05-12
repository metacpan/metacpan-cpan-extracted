package AFS::KTC_TOKEN;
#------------------------------------------------------------------------------
# RCS-Id: "@(#)$RCS-Id: src/KTC_TOKEN/KTC_TOKEN.pm 7a64d4d Wed May 1 22:05:49 2013 +0200 Norbert E Gruener$"
#
# © 2001-2010 Norbert E. Gruener <nog@MPA-Garching.MPG.de>
#
# This library is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#------------------------------------------------------------------------------

use AFS ();

use vars qw(@ISA $VERSION);

@ISA     = qw(AFS);
$VERSION = 'v2.6.4';

sub nulltoken {
    my $class  = shift;

    AFS::ka_nulltoken;
}

sub GetAdminToken {
    my $class  = shift;

    AFS::ka_GetAdminToken(@_);
}

sub GetAuthToken {
    my $class  = shift;

    AFS::ka_GetAuthToken(@_);
}

sub GetServerToken {
    my $class  = shift;

    AFS::ka_GetServerToken(@_);
}

sub GetToken {
    my $class  = shift;

    AFS::ktc_GetToken(@_);
}

sub FromString {
    my $class  = shift;

    AFS::ktc_FromString(@_);
}

sub SetToken {
    my $class  = shift;

    AFS::ktc_SetToken(@_);
}

sub UserAuthenticateGeneral {
    my $class = shift;

    AFS::ka_UserAthenticateGeneral(@_);
}

sub ForgetAllTokens {
    my $class = shift;

    AFS::ktc_ForgetAllTokens;
}


# struct ktc_token {
#     afs_int32 startTime;
#     afs_int32 endTime;
#     struct ktc_encryptionKey sessionKey;
#     short kvno;  /* XXX UNALIGNED */
#     int ticketLen;
#     char ticket[MAXKTCTICKETLEN];
# };

1;
