package Acme::Perl::VM::Context;
use Mouse;


sub type{
    (my $type = ref($_[0])) =~ s/^Acme::Perl::VM::Context:://;

    return $type;
}

no Mouse;
__PACKAGE__->meta->make_immutable();

package Acme::Perl::VM::Context::BLOCK;
use Mouse;
use Acme::Perl::VM qw($PL_comppad);

extends 'Acme::Perl::VM::Context';

has gimme => (
    is  => 'rw',
    isa => 'Int',

    required => 1,
);
has oldsp => (
    is  => 'rw',
    isa => 'Int',

    required => 1
);
has oldcop => (
    is  => 'rw',
    isa => 'B::COP',

    required => 1,
);
has oldmarksp => (
    is  => 'rw',
    isa => 'Int',

    required => 1,
);
has oldscopesp => (
    is  => 'rw',
    isa => 'Int',

    required => 1,
);

sub CURPAD_SAVE{
    my($cx) = @_;

    $cx->oldcomppad($PL_comppad);
    return;
}

sub CURPAD_SV{
    my($cx, $ix) = @_;

    return $cx->oldcomppad->ARRAYelt($ix);
}


no Mouse;
__PACKAGE__->meta->make_immutable();

package Acme::Perl::VM::Context::SUB;
use Mouse;
extends 'Acme::Perl::VM::Context::BLOCK';

has cv => (
    is  => 'rw',
    isa => 'B::CV',

    required => 1,
);

has olddepth => (
    is  => 'rw',
    isa => 'Int',
);
has hasargs => (
    is  => 'rw',
    isa => 'Bool',

    required => 1,
);

has retop => (
    is  => 'rw',
    isa => 'B::OBJECT', # NULL or B::OP

    required => 1,
);

has oldcomppad => (
    is  => 'rw',
    isa => 'B::AV',
);
has savearray => (
    is  => 'rw',
    isa => 'ArrayRef',
);
has argarray => (
    is  => 'rw',
    isa => 'B::AV',
);

has lval => (
    is  => 'rw',
    isa => 'Bool',
);

sub BUILD{
    my($cx) = @_;

    $cx->olddepth($cx->cv->DEPTH);
    return;
}

no Mouse;
__PACKAGE__->meta->make_immutable();

package Acme::Perl::VM::Context::EVAL;
use Mouse;
extends 'Acme::Perl::VM::Context::BLOCK';

no Mouse;
__PACKAGE__->meta->make_immutable();

package Acme::Perl::VM::Context::LOOP;
use Mouse;
extends 'Acme::Perl::VM::Context::BLOCK';

use Acme::Perl::VM qw($PL_op $PL_curcop);

has label => (
    is  => 'rw',
    isa => 'Maybe[Str]',
);
has resetsp => (
    is  => 'rw',
    isa => 'Int',

    required => 1,
);
has myop => (
    is  => 'rw',
    isa => 'B::LOOP',
);
has nextop => (
    is  => 'rw',
    isa => 'B::OP',
);

sub BUILD{
    my($cx) = @_;

    $cx->label($PL_curcop->label);
    $cx->myop($PL_op);
    $cx->nextop($PL_op->nextop);

    return;
}

sub ITERVAR(){ undef }

no Mouse;
__PACKAGE__->meta->make_immutable();

package Acme::Perl::VM::Context::FOREACH;
use Mouse;
use Acme::Perl::VM::B qw(USE_ITHREADS);
extends 'Acme::Perl::VM::Context::LOOP';

has padvar => (
    is  => 'rw',
    isa => 'Bool',

    required => 1,
);
has for_def => (
    is => 'rw',
    isa => 'Bool',

    required => 1,
);

has iterdata => (
    is  => 'rw',
    isa => 'Defined',

    required => 1,
);
if(USE_ITHREADS){
    has oldcomppad => (
        is  => 'rw',
        isa => 'B::AV',
    );
}

has itersave => (
    is => 'rw',
);
has iterlval => (
    is  => 'rw',
);
has iterary => (
    is  => 'rw',
);
has iterix => (
    is  => 'rw',
    isa => 'Int',
);
has itermax => (
    is  => 'rw',
    isa => 'Int',
);

sub type(){ 'LOOP' } # this is a LOOP

sub BUILD{
    my($cx) = @_;
    $cx->ITERDATA_SET($cx->iterdata);
    return;
}


sub ITERVAR{
    my($cx) = @_;
    if(USE_ITHREADS){
        if($cx->padvar){
            return $cx->CURPAD_SV($cx->iterdata);
        }
        else{
            return $cx->iterdata->SV;
        }
    }
    else{
        return $cx->iterdata;
    }
}
sub ITERDATA_SET{
    my($cx, $idata) = @_;
    if(USE_ITHREADS){
        $cx->CURPAD_SAVE();
    }

    $cx->itersave($cx->ITERVAR);
}

no Mouse;
__PACKAGE__->meta->make_immutable();

package Acme::Perl::VM::Context::GivenWhen;
use Mouse;
extends 'Acme::Perl::VM::Context::BLOCK';

no Mouse;
__PACKAGE__->meta->make_immutable();

package Acme::Perl::VM::Context::GIVEN;
use Mouse;
extends 'Acme::Perl::VM::Context::GivenWhen';

no Mouse;
__PACKAGE__->meta->make_immutable();

package Acme::Perl::VM::Context::WHEN;
use Mouse;
extends 'Acme::Perl::VM::Context::GivenWhen';

no Mouse;
__PACKAGE__->meta->make_immutable();

package Acme::Perl::VM::Context::SUBST;
use Mouse;
extends 'Acme::Perl::VM::Context';

no Mouse;
__PACKAGE__->meta->make_immutable();

__END__

=head1 NAME

Acme::Perl::VM::Context - Context classes for APVM

=head1 SYNOPSIS

    use Acme::Perl::VM;

=head1 SEE ALSO

L<Acme::Perl::VM>.

=cut
