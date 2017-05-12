package Carp::POE;
BEGIN {
  $Carp::POE::AUTHORITY = 'cpan:HINRIK';
}
{
  $Carp::POE::VERSION = '0.10';
}

use strict;
use warnings FATAL => 'all';
use Carp ();
use POE::Session;
use base qw(Exporter);

our @EXPORT      = qw(confess croak carp);
our @EXPORT_OK   = qw(cluck verbose);
our @EXPORT_FAIL = qw(verbose);

# from POE::Session
my ($file, $line) = (CALLER_FILE, CALLER_LINE);

{
    no warnings 'once';
    *export_fail = *Carp::export_fail;
    *confess     = *Carp::confess;
    *cluck       = *Carp::cluck;
}

sub croak {
    _is_handler()
        ? die _caller_info(@_), "\n"
        : die Carp::shortmess(@_), "\n"
    ;
}

sub carp {
    _is_handler()
        ? warn _caller_info(@_), "\n"
        : warn Carp::shortmess(@_), "\n"
    ;
}

sub _is_handler {
    return 1 if (caller(3))[0] eq 'POE::Kernel';
}

sub _caller_info {
    my @args = @_;
    {
        package
        DB;
        my @throw_away = caller(2);
        return "@args at $DB::args[$file] line $DB::args[$line]";
    }
}

1;

=encoding utf8

=head1 NAME

Carp::POE - Carp adapted to POE

=head1 SYNOPSIS

 use Carp::POE;
 use POE;
 
 POE::Session->create(
     package_states => [
         main => [qw( _start test_event )]
     ],
 );

 $poe_kernel->run();

 sub _start {
     $_[KERNEL]->yield(test_event => 'fail');
 }
 
 sub test_event {
     my $arg = $_[ARG0];
     if ($arg ne 'correct') {
         carp "Argument is incorrect!";
     }
 }

=head1 DESCRIPTION

This module provides the same functions as L<Carp|Carp>, but modifies
the behavior of C<carp()> and C<croak()> if called inside a L<POE|POE>
event handler. The file names/line numbers in the emitted warnings are
replaced with L<POE::Session|POE::Session>'s C<$_[CALLER_FILE]> and
C<$_[CALLER_LINE]>. This is useful as it will direct you to the code
that posted the event instead of directing you to some subroutine in
POE::Session which actually called the event handler.

Calls to C<carp()> and C<croak()> in subroutines that are not POE event
handlers will not be effected, so it's always safe to C<use Carp::POE>
instead of C<Carp>.

=head1 TODO

Do something clever with C<cluck()> and C<confess()>.

=head1 BUGS

Those go here: L<http://rt.cpan.org/Public/Dist/Display.html?Name=Carp%3A%3APOE>

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson <hinrik.sig@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2008-2010 Hinrik E<Ouml>rn SigurE<eth>sson

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
