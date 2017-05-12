
# The original notice of B::Size:
# B::TerseSize.pm
# Copyright (c) 1999-2000 Doug MacEachern. All rights reserved.
# This module is free software; you can redistribute and/or modify
# it under the same terms as Perl itself.

package B::Size2;

use strict;
use warnings;
use XSLoader ();
use B ();

BEGIN {
    our $VERSION = '2.07';

    XSLoader::load(__PACKAGE__, $VERSION);
}

{
    no warnings qw (redefine prototype);
    *B::OP::size   = \&B::Sizeof::OP;
    *B::UNOP::size = \&B::Sizeof::UNOP;
}

use constant _CHECK_SVPAD_OUR_FOR_MAGIC => $] < 5.016;

use constant _SVpad_NAME => 0x40000000; # sv.h
use constant _SVpad_OUR  => 0x00040000; # sv.h

sub _SvPAD_OUR { # see SvPAD_OUR()@sv.h
    my($sv) = @_;
    return ($sv->FLAGS() & _SVpad_NAME|_SVpad_OUR) == (_SVpad_NAME|_SVpad_OUR);
}

sub B::SVOP::size {
    my($op) = @_;
    if ($op->desc eq 'constant array element') { # aelemfast
        return B::Sizeof::SVOP;
    }
    else {
        return B::Sizeof::SVOP + $op->sv->size;
    }
}

sub B::GVOP::size {
    my $op = shift;
    B::Sizeof::GVOP; #XXX more to measure?
}

sub B::PVOP::size {
    B::Sizeof::PVOP + length(shift->pv);
}

*B::BINOP::size  = \&B::Sizeof::BINOP;
*B::LOGOP::size  = \&B::Sizeof::LOGOP;
*B::LISTOP::size = \&B::Sizeof::LISTOP;

sub B::PMOP::size {
    my $op = shift;
    my $size = B::Sizeof::PMOP + B::Sizeof::REGEXP;
    $size += $op->REGEXP_size;
}

sub B::PV::size {
    my $sv = shift;
    B::Sizeof::SV + B::Sizeof::XPV + $sv->LEN;
}

sub B::IV::size {
    B::Sizeof::SV + B::Sizeof::XPVIV;
}

sub B::NV::size {
    B::Sizeof::SV + B::Sizeof::XPVNV;
}

sub B::PVIV::size {
    my $sv = shift;
    B::IV::size + $sv->LEN;
}

sub B::PVNV::size {
    my $sv = shift;
    B::NV::size + $sv->LEN;
}

sub B::PVLV::size {
    my $sv = shift;
    B::Sizeof::SV + B::Sizeof::XPVLV +
    B::Sizeof::MAGIC + $sv->LEN;
}

sub B::PVMG::size {
    my $sv = shift;
    my $size = B::Sizeof::SV + B::Sizeof::XPVMG;

    if (_CHECK_SVPAD_OUR_FOR_MAGIC && !_SvPAD_OUR($sv)){
        my(@chain) = $sv->MAGIC;
        for my $mg (@chain) {
            $size += B::Sizeof::MAGIC + $mg->LENGTH;
        }
    }
    if (defined(my $tied = tied(${ $sv->object_2svref }))) {
        return $size + B::svref_2object($tied)->size;
    }
    $size;
}

sub B::AV::size {
    my $sv = shift;
    my $size = B::Sizeof::AV + B::Sizeof::XPVAV;
    if (defined(my $tied = tied(@{ $sv->object_2svref }))) {
        return $size + B::svref_2object($tied)->size;
    }
    my @vals = $sv->ARRAY;
    for (my $i = 0; $i <= $sv->MAX; $i++) {
        my $sizecv = $vals[$i]->can('size') if $vals[$i];
        $size += $sizecv ? $sizecv->($vals[$i]) : B::Sizeof::SV;
    }
    $size;
}

sub B::HV::size {
    my $sv = shift;
    my $size = B::Sizeof::HV + B::Sizeof::XPVHV;
    #$size += length($sv->NAME);

    if (defined(my $tied = tied(%{ $sv->object_2svref }))) {
        return $size + B::svref_2object($tied)->size;
    }

    $size += ($sv->MAX * (B::Sizeof::HE + B::Sizeof::HEK));

    my %vals = $sv->ARRAY;
    while (my($k,$v) = each %vals) {
        $size += length($k) + $v->size;
    }

    $size;
}

sub B::RV::size {
    B::Sizeof::SV + B::Sizeof::XRV();
}

sub B::CV::size {
    B::Sizeof::SV + B::Sizeof::XPVCV + 0000; #__ANON__
}

sub B::BM::size {
    my $sv = shift;
    B::Sizeof::SV + B::Sizeof::XPVBM() + $sv->LEN;
}

sub B::FM::size {
    B::Sizeof::SV + B::Sizeof::XPVFM;
}

sub B::IO::size {
    B::Sizeof::SV + B::Sizeof::XPVIO;
}

sub B::SPECIAL::size {
    B::Sizeof::SV + 0; #?
}

sub B::NULL::size {
    B::Sizeof::SV + 0; #?
}

sub B::SPECIAL::PV {
    my $sv = shift;
    $B::specialsv_name[$$sv];
}

sub B::RV::sizeval {
    my $sv = shift;
    sprintf "0x%lx", $$sv;
}

sub B::PV::sizeval {
    my $sv = shift;
    my $pv = $sv->PV;
    escape_html(\$pv) if $ENV{MOD_PERL};
    $pv;
}

sub B::AV::sizeval {
    "MAX => " . shift->MAX;
}

sub B::HV::sizeval {
    "MAX => " . shift->MAX;
}

sub B::IV::sizeval {
    my($sv) = @_;
    return $sv->FLAGS & (B::SVf_IOK|B::SVp_IOK)
        ? $sv->IV
        : B::NULL::sizeval($sv);
}

sub B::NV::sizeval {
    my($sv) = @_;
    return $sv->FLAGS & (B::SVf_NOK|B::SVp_NOK)
        ? $sv->NV
        : B::NULL::sizeval($sv);
}

sub B::NULL::sizeval {
    my $sv = shift;
    sprintf "0x%lx", $$sv;
}

sub B::SPECIAL::sizeval {
    my $sv = shift;
    sprintf "0x%lx", $$sv;
}

sub B::SPECIAL::FLAGS {
    0;
}

sub B::NULL::FLAGS {
    0;
}

sub B::CV::is_alias {
    my($cv, $package) = @_;
    my $stash  = $cv->GV->STASH->NAME;
    if($package ne $stash) {
    my $name = $cv->GV->NAME;
    #print "$package\::$name aliased to $stash\::$name\n";
    return $stash;
    }
    0;
}

sub B::Size::SV_size {
    B::svref_2object(shift)->size;
}

#bleh
my %esc = (
   '&' => 'amp',
   '>' => 'gt',
   '<' => 'lt',
   '"' => 'quot',
);

my $esc = join '', keys %esc;

sub escape_html {
    my $str = shift;
    $$str =~ s/([$esc])/&$esc{$1};/g if $$str;
}

1;
__END__

=head1 NAME

B::Size2 - Measure size of Perl OPs and SVs

=head1 SYNOPSIS

  use B ();
  use B::Size2 ();

  say B::svref_2object($value)->size;

=head1 DESCRIPTION

I<< B::Size2 is a fork of B::Size 0.09 for maintainance >>.

=head1 SEE ALSO

L<B::Size2::Terse>

L<B::Size> - the original version but no longer maintained

=head1 AUTHORS

Fuji, Goro (gfx) E<lt>gfuji@cpan.orgE<gt>

=head1 ORIGINAL AUTHORS

Doug MacEachern

=cut
