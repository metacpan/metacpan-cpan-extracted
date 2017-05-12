package AFS::VOS;
#------------------------------------------------------------------------------
# RCS-Id: "@(#)$RCS-Id: src/VOS/VOS.pm 7a64d4d Wed May 1 22:05:49 2013 +0200 Norbert E Gruener$"
#
# © 2005-2012 Norbert E. Gruener <nog@MPA-Garching.MPG.de>
# © 2003-2004 Alf Wachsmann <alfw@slac.stanford.edu> and
#             Norbert E. Gruener <nog@MPA-Garching.MPG.de>
#
# This library is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#------------------------------------------------------------------------------

use Carp;
use AFS ();
use Scalar::Util qw(looks_like_number);

use vars qw(@ISA $VERSION);

@ISA     = qw(AFS);
$VERSION = 'v2.6.4';

sub DESTROY {
    my (undef, undef, undef, $subroutine) = caller(1);
    if (! defined $subroutine or $subroutine !~ /eval/) { undef $_[0]; }  # self->DESTROY
    else { AFS::VOS::_DESTROY($_[0]); }                                   # undef self
}

sub setquota {
    my $self   = shift;
    my $volume = shift;
    my $quota  = shift || 0;
    my $clear  = shift || 0;

    if (defined $quota and !looks_like_number($quota)) { warn "VOS::setquota: QUOTA is not an INTEGER ...\n"; return 0; }
    else                                               { $quota = int($quota); }
    if (defined $clear and !looks_like_number($clear)) { warn "VOS::setquota: CLEAR is not an INTEGER ...\n"; return 0; }
    else                                               { $clear = int($clear); }

    $self->_setfields($volume, $quota, $clear);
}

sub backupsys {
    my $self = shift;
    my ($prefix, $server, $partition, $exclude, $xprefix, $dryrun) = @_;

    my (@Prefix, @XPrefix, $pcount);

    if (!defined $dryrun)    { $dryrun = 0; }
    if (!defined $xprefix)   { @XPrefix = (); }
    elsif (! ref($xprefix))  { @XPrefix = split(/ /, $xprefix); }
    else                     { @XPrefix = @{$xprefix}; }
    if (!defined $exclude)   { $exclude = 0; }
    if (!defined $partition) { $partition = ''; }
    if (!defined $server)    { $server = ''; }
    if (!defined $prefix)    { @Prefix = (''); }
    elsif (! ref($prefix))   { @Prefix = split(/ /, $prefix); }
    else                     { @Prefix = @{$prefix}; }
    if (!($pcount = @Prefix)) {@Prefix = (''); }

    return($self->_backupsys(\@Prefix, $server, $partition, $exclude, \@XPrefix, $dryrun))
}

1;
