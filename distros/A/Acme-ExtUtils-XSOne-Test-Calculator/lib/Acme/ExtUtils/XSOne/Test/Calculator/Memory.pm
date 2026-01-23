package Acme::ExtUtils::XSOne::Test::Calculator::Memory;

use strict;
use warnings;
use Acme::ExtUtils::XSOne::Test::Calculator;

1;

__END__

=head1 NAME

Acme::ExtUtils::XSOne::Test::Calculator::Memory - Memory storage and calculation history

=head1 SYNOPSIS

    # Import specific functions
    use Acme::ExtUtils::XSOne::Test::Calculator::Memory qw(store recall ans clear);

    store(0, 42);
    my $val = recall(0);   # 42
    my $last = ans();      # last calculation result
    clear();               # clear all memory and history

    # Or use fully qualified names
    use Acme::ExtUtils::XSOne::Test::Calculator;

    my $count = Acme::ExtUtils::XSOne::Test::Calculator::Memory::history_count();
    my ($op, $a, $b, $result) = Acme::ExtUtils::XSOne::Test::Calculator::Memory::get_history_entry(0);

=head1 EXPORTABLE FUNCTIONS

All functions can be imported by name:

    store recall clear ans history_count get_history_entry
    max_memory_slots max_history_entries is_valid_slot
    used_slots sum_all_slots add_to

=head1 DESCRIPTION

This module provides memory storage and calculation history functionality
as part of the L<Acme::ExtUtils::XSOne::Test::Calculator> distribution.

The memory and history are shared across all Calculator submodules, which
demonstrates the key feature of L<ExtUtils::XSOne>: multiple XS packages
sharing C-level static state.

=head1 FUNCTIONS

=head2 store

    my $success = store($slot, $value);

Stores C<$value> in memory slot C<$slot>. Returns true on success,
false if the slot is invalid. Valid slots are C<0> through C<max_memory_slots() - 1>.

=head2 recall

    my $value = recall($slot);

Returns the value stored in memory slot C<$slot>, or C<0> if the slot
is invalid or empty.

=head2 clear

    clear();

Clears all memory slots, resets the calculation history, and resets
the last result to C<0>.

=head2 ans

    my $last = ans();

Returns the result of the last calculation performed by any Calculator
submodule.

=head2 history_count

    my $count = history_count();

Returns the number of entries in the calculation history.

=head2 get_history_entry

    my ($operation, $operand1, $operand2, $result) = get_history_entry($index);

Returns the history entry at C<$index> as a four-element list:
the operation character, two operands, and the result.
Croaks if C<$index> is out of range.

=head2 max_memory_slots

    my $max = max_memory_slots();

Returns the maximum number of memory slots available (currently 10).

=head2 max_history_entries

    my $max = max_history_entries();

Returns the maximum number of history entries that can be stored
(currently 100).

=head2 is_valid_slot

    my $bool = is_valid_slot($slot);

Returns true if C<$slot> is a valid memory slot number.

=head2 used_slots

    my $count = used_slots();

Returns the number of memory slots that contain non-zero values.

=head2 sum_all_slots

    my $total = sum_all_slots();

Returns the sum of all values stored in memory slots.

=head2 add_to

    add_to($slot, $value);

Adds C<$value> to the current value in memory slot C<$slot>.
Does nothing if the slot is invalid.

=head1 SEE ALSO

L<Acme::ExtUtils::XSOne::Test::Calculator>,
L<Acme::ExtUtils::XSOne::Test::Calculator::Basic>,
L<Acme::ExtUtils::XSOne::Test::Calculator::Scientific>,
L<Acme::ExtUtils::XSOne::Test::Calculator::Trig>

=cut
