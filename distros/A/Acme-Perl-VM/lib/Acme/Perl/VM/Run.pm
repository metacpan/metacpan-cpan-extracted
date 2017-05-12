package Acme::Perl::VM::Run;

use strict;
use warnings;
use Acme::Perl::VM    qw(:perl_h);
use B qw(main_start comppadlist);

no warnings 'void';
INIT{
    return if APVM_DUMMY;

    if(is_not_null(main_start)){
        ENTER;
        SAVETMPS;

        $PL_curcop ||= bless \do{ my $addr = 0 }, 'B::COP'; # dummy cop

        $PL_op = main_start;
        PAD_SET_CUR(comppadlist, 1);

        $PL_runops->();

        FREETMPS;
        LEAVE;
    }
    exit;
}

1;
__END__

=head1 NAME

Acme::Perl::VM::Run - Runs a Perl script in APVM

=head1 SYNOPSIS

    #!perl -w
    use Acme::Perl::VM::Run;

    print "Hello, world!\n";

=head1 SEE ALSO

L<Acme::Perl::VM>.

=cut

