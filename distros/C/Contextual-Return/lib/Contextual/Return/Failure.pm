package Contextual::Return::Failure;
our $VERSION = 0.000_003;

use Contextual::Return;
BEGIN { *_in_context = *Contextual::Return::_in_context }

use warnings;
use strict;

my %handler_for;

sub _FAIL_WITH {
    # Unpack and vet args...
    my $flag = shift;
    my $selector_ref;
    if (ref $flag eq 'HASH') {
        $selector_ref = $flag;
        $flag = undef;
    }
    else {
        $selector_ref = shift;
        die _in_context 'Usage: FAIL_WITH $flag_opt, \%selector, @args'
            if ref $selector_ref ne 'HASH';
    }
    die _in_context "Selector values must be sub refs"
        if grep {ref ne 'CODE'} values %{$selector_ref};

    # Search for handler sub;
    my $handler;
    if (defined $flag) {
        ARG:
        while (@_) {
            last ARG if shift(@_) eq $flag;
        }
        my $selector = shift @_;
        if (ref $selector eq 'CODE') {
            $handler = $selector;
            @_ = ();
        }
        else {
            @_ = $selector;
        }
    }

    SELECTION:
    for my $selection (reverse @_) {
        if (exists $selector_ref->{$selection}) {
            $handler = $selector_ref->{$selection};
            last SELECTION;
        }
        elsif ($flag) {
            die _in_context "Invalid option: $flag => $selection";
        }
    }

    # (Re)set handler...
    if ($handler) {
        my $caller_loc = join '|', (CORE::caller 1)[0,1];
        if (exists $handler_for{$caller_loc}) {
            warn _in_context "FAIL handler for package ", scalar CORE::caller, " redefined";
        }
        $handler_for{$caller_loc} = $handler;
    }
};

sub _FAIL (;&) {
    # Generate args...
    my $arg_generator_ref = shift;
    my @args;
    if ($arg_generator_ref) {
        package DB;
        ()=CORE::caller(1);
        @args = $arg_generator_ref->(@DB::args);
    }

    # Handle user-defined failure semantics...
    my $caller_loc = join '|', (CORE::caller 1)[0,1];
    if (exists $handler_for{$caller_loc} ) {
        # Fake out caller() and Carp...
        local $Contextual::Return::uplevel = 1;

        return $handler_for{$caller_loc}->(@args);
    }

    my $exception = @args == 1 ? $args[0]
                  : @args > 0  ? join(q{}, @args)
                  :              "Call to " . (CORE::caller 1)[3] . "() failed"
                  ;

    # Join message with croak() semantics, if string...
    if (!ref $exception) {
        $exception .= _in_context @_;
    }

#    # Check for immediate failure...
#    use Want qw( want );
#    return 0 if want 'BOOL';
#    die $exception if !want 'SCALAR';

    # Return a delayed failure object...
    return
        BOOL    { 0 }
        DEFAULT {
            if (ref $exception) {
                my $message = "$exception";
                $message =~ s/$/\n/;
                die _in_context $message, "Attempted to use failure value";
            }
            else {
                die _in_context $exception, "Attempted to use failure value";
            }
        }
        METHOD {
            error => sub { _in_context $exception }
        }
}

1;

__END__

=head1 NAME

Contextual::Return::Failure - Utility module for Contextual::Return

=head1 NOTE

Contains no user serviceable parts. See L<Contextual::Return> instead.

=head1 AUTHOR

Damian Conway  C<< <DCONWAY@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Damian Conway C<< <DCONWAY@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

