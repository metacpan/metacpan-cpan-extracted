package Acme::Perl::VM::B;

use strict;
use warnings;

use Exporter qw(import);

use B();
our @EXPORT = grep{ /^[A-Z]/ } @B::EXPORT_OK; # constants
push @EXPORT, qw(sv_undef svref_2object);
B->import(@EXPORT);

unless(defined &OPpPAD_STATE){
    constant->import(OPpPAD_STATE => 0x00);
    push @EXPORT, qw(OPpPAD_STATE);
}
unless(defined &G_WANT){
    constant->import(G_WANT => G_SCALAR() | G_ARRAY() | G_VOID());
    push @EXPORT, qw(G_WANT);
}
unless(defined &OPpITER_REVERSED){
    constant->import(OPpITER_REVERSED => 0x00);
    push @EXPORT, qw(OPpITER_REVERSED);
}

push @EXPORT, qw(NULL TRUE FALSE USE_ITHREADS sv_yes sv_no);
use constant {
    NULL         => bless(\do{ my $addr = 0 }, 'B::SPECIAL'),
    TRUE         => 1,
    FALSE        => 0,
    USE_ITHREADS => defined(&B::regex_padav),

    sv_yes       => B::sv_yes,
    sv_no        => B::sv_no,
};


package
    B::OBJECT;

use B qw(class);

sub dump{
    my($obj) = @_;
    require Devel::Peek;
    Devel::Peek::Dump($obj->object_2svref);
    return;
}

package
    B::OP;

sub dump{
    my($obj) = @_;
    require B::Debug;

    $obj->debug;
    return;
}

package
    B::SPECIAL;

my %special_sv = (
    ${ B::sv_undef() } => \(undef),
    ${ B::sv_yes() }   => \(1 == 1),
    ${ B::sv_no() }    => \(1 != 1),
);

unless(@B::specialsv_name){
    @B::specialsv_name = qw(
        Nullsv
        &PL_sv_undef
        &PL_sv_yes
        &PL_sv_no
        pWARN_ALL
        pWARN_NONE
        pWARN_STD
    );
}

sub object_2svref{
    my($obj) = @_;

    return $special_sv{ $$obj } || do{
        Carp::confess($obj->special_name, ' is not a normal SV object');
    };
}

sub setval{
    my($obj) = @_;

    Acme::Perl::VM::apvm_die('Modification of read-only value (%s) attempted', $obj->special_name);
}

sub STASH(){ undef }

sub POK(){ 0 }
sub ROK(){ 0 }

sub special_name{
    my($obj) = @_;
    return $B::specialsv_name[$$obj] || sprintf 'SPECIAL(0x%x)', $$obj;
}

package
    B::SV;

# for sv_setsv()
sub setsv{
    my($dst, $src) = @_;

    my $dst_ref = $dst->object_2svref;
    ${$dst_ref} = ${$src->object_2svref};
    bless $dst, ref(B::svref_2object( $dst_ref ));

    return $dst;
}

# for sv_setpv()/sv_setiv()/sv_setnv() etc.
sub setval{
    my($dst, $val) = @_;

    my $dst_ref = $dst->object_2svref;
    ${$dst_ref} = $val;
    bless $dst, ref(B::svref_2object( $dst_ref ));

    return $dst;
}

sub clear{
    my($sv) = @_;

    ${$sv->object_2svref} = undef;
    return;
}

sub toCV{
    my($sv) = @_;
    Carp::croak(sprintf 'Cannot convert %s to a CV', B::class($sv));
}

sub STASH(){ undef }

package
    B::PVMG;

sub ROK{
    my($obj) = @_;
    my $dummy = ${ $obj->object_2svref }; # invoke mg_get()
    return $obj->SUPER::ROK;
}

package
    B::CV;

sub toCV{ $_[0] }

sub clear{
    Carp::croak('Cannot clear a CV');
}

sub ROK(){ 0 }

package
    B::GV;


sub toCV{ $_[0]->CV }

sub clear{
    Carp::croak('Cannot clear a CV');
}

sub ROK(){ 0 }

package
    B::AV;

sub setsv{
    my($sv) = @_;
    Carp::croak('Cannot call setsv() for ' . B::class($sv));
}

sub clear{
    my($sv) = @_;

    @{$sv->object_2svref} = ();
    return;
}

unless(__PACKAGE__->can('OFF')){
    # some versions of B::Debug requires this
    constant->import(OFF => 0);
}

sub ROK(){ 0 }

package
    B::HV;

sub ROK(){ 0 }

*setsv = \&B::AV::setsv;

sub clear{
    my($sv) = @_;

    %{$sv->object_2svref} = ();
    return;
}

sub fetch{
    my($hv, $key, $lval) = @_;

    if($lval){
        return B::svref_2object(\$hv->object_2svref->{$key});
    }
    else{
        my $ref = $hv->object_2svref;

        if(exists $ref->{$key}){
            return B::svref_2object(\$ref->{$key});
        }
        else{
            return Acme::Perl::VM::B::NULL;
        }
    }
}

sub fetch_ent{
    my($hv, $keysv, $lval) = @_;
    return $hv->fetch(${ $keysv->object_2svref }, $lval);
}

sub exists{
    my($hv, $key) = @_;
    return exists $hv->object_2svref->{$key};
}
sub exists_ent{
    my($hv, $keysv) = @_;
    return exists $hv->object_2svref->{${ $keysv->object_2svref}};
}

sub store{
    my($hv, $key, $val) = @_;

    $hv->object_2svref->{$key} = ${ $val->object_2svref };
    return B::svref_2object(\$hv->object_2svref->{$key}) if defined wantarray;
}
sub store_ent{
    my($hv, $keysv, $val) = @_;

    $hv->object_2svref->{${ $keysv->object_2svref }} = ${ $val->object_2svref };
    return B::svref_2object(\$hv->object_2svref->{${ $keysv->object_2svref }}) if defined wantarray;
}
1;

__END__

=head1 NAME

Acme::Perl::VM::B - Extra B functions and constants

=head1 SYNOPSIS

    use Acme::Perl::VM;

=head1 SEE ALSO

L<Acme::Perl::VM>.

=cut
