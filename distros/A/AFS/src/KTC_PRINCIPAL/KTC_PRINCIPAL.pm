package AFS::KTC_PRINCIPAL;
#------------------------------------------------------------------------------
# RCS-Id: "@(#)$RCS-Id: src/KTC_PRINCIPAL/KTC_PRINCIPAL.pm 7a64d4d Wed May 1 22:05:49 2013 +0200 Norbert E Gruener$"
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

sub ListTokens {
    my $class  = shift;

    AFS::ktc_ListTokens(@_);
}

sub ParseLoginName {
    my $class = shift;

    AFS::ka_ParseLoginName(@_);
}

sub new {
    # this whole construct is to please the old version from Roland
    if ($_[0] =~ /AFS::KTC_PRINCIPAL/) { my $class  = shift; }
    my $name  = shift;
    my $inst  = shift;
    my $cell  = shift;

    my @args = ();
    push @args, $name if defined $name;
    push @args, $inst if defined $inst;
    push @args, $cell if defined $cell;
    AFS::KTC_PRINCIPAL::_new('AFS::KTC_PRINCIPAL', @args);
}


# struct ktc_principal {
#     char name[MAXKTCNAMELEN];
#     char instance[MAXKTCNAMELEN];
#     char cell[MAXKTCREALMLEN];
# };

1;
