package CHI::Cascade::Value;

use strict;
use warnings;

my %states = (
    # value = undef                     -> no in cache
    CASCADE_NO_CACHE                    => 1 << 0,

    # value = undef | old_value         -> other process is computing this target or its any dependencies
    CASCADE_COMPUTING                   => 1 << 1,

    # value = undef | old_value         -> recomputing is deferred
    CASCADE_DEFERRED                    => 1 << 2,

    # value = old_value | actual_value  -> the value from cache (not computed now)
    CASCADE_FROM_CACHE                  => 1 << 3,

    # value = actual_value              -> this value is actual
    CASCADE_ACTUAL_VALUE                => 1 << 4,

    # value = actual_value & recomuted now      -> this value is recomputed right now
    CASCADE_RECOMPUTED                  => 1 << 5,

    # value = undef | old_value | value passed by exception -> code of target or code of any dependencies has raised an exception
    CASCADE_CODE_EXCEPTION              => 1 << 6,

    # value = old_value | actual_value - value may be actual or not but actual term isn valid (only if 'run' is run with 'actual_term' option)
    CASCADE_ACTUAL_TERM                 => 1 << 7,

    # Some dependencies are affected for recomputing, but no recomputing now - only TTL period and value from cache
    CASCADE_TTL_INVOLVED                => 1 << 8
);

for ( keys %states ) {
    no strict 'refs';
    no warnings 'redefine';

    my $bit = $states{$_};

    *{ $_ } = sub () { $bit }
}


use parent 'Exporter';

{
    no strict 'refs';

    our %EXPORT_TAGS = (
        state           => [ map { "$_" } grep { /^CASCADE_/ && *{$_}{CODE} } keys %{ __PACKAGE__ . "::" } ]
    );
    Exporter::export_ok_tags( keys %EXPORT_TAGS );
}

sub new {
    my ($class, %opts) = @_;

    my $self = bless { %opts }, ref($class) || $class;

    $self->{state} ||= 0;

    $self;
}

sub is_value {
    shift->{is_value};
}

sub state {
    my $self = shift;

    if (@_) {
        $self->{state} |= $_[0];
        return $self;
    }
    $self->{state};
}

sub state_as_str {
    my $state = $_[1];

    return '' if ! $state;

    my @names;

    for ( keys %states ) {
        push @names, $_
          if ( $state & $states{$_} );
    }

    join( " | ", sort @names );
}

sub value {
    my $self = shift;

    if (@_) {
        $self->{is_value} = 1;
        $self->{value} = $_[0];
        return $self;
    }
    $self->{value};
}

sub thrown_from_code {
    my $self = shift;

    if (@_) {
        $self->{thrown_from_code} = $_[0];
        return $self;
    }
    $self->{thrown_from_code};
}

1;

__END__

=head1 NAME

CHI::Cascade::Value - a class for valid values

=head1 SYNOPSIS

You can use it class for a returning of values by exceptions. For example:

    die CHI::Cascade::Value->new

This throws an exception with nothing value. If you do it from your recompute
code your L<CHI::Cascade/run> method will return an old value from cache or if
it's not in cache it will return an C<undef> value.

Or

    die CHI::Cascade::Value->new->value( $any_value );
    die CHI::Cascade::Value->new->value( undef );

This throws an exception with valid value. Please note that C<undef> is valid
value too! But bacause the L<CHI::Cascade/run> method returns only a value (not
instance of L<CHI::Cascade::Value> object) there is not recommended to use
C<undef> values (C<run> method returns C<undef> when it cannot get a value right
now).

Please use it class only in special cases - when you need to break recopmuting,
want to return an specific value only for once execution of L<CHI::Cascade/run>
method and don't want to save value in cache.

=head1 CONSTRUCTOR

    $value = CHI::Cascade::Value->new;

It will create instance $value with nothing value

=head1 METHODS

=over

=item value

Examples:

    $value->value
    $value->value( $new_value )

You can use it to get/set a value of $value. An C<undef> value is valid too!
First version returns a value, second sets a value and returns C<$value>.

=item is_value

    $value->is_value

returns C<true> if value was set by L</value> method or C<false> else.

=item state

    use CHI::Cascade::Value ':state';
    $state_bits = $value->state;
    $value = $value->state( CASCADE_* );

A getting or setting of state bits of value object.

=item state_as_str

    my $value = $cascade->run( 'my_target', state => \$state );
    my $str = CHI::Cascade::Value->state_as_str( $state );

Returns a string presentation of state bits (see below L</"STATE BITS">).
Strings of bits are ordered by alphabetical before concatenation. Here some
examples:

    # It means you get actual value and this was recomputed right now
    CASCADE_ACTUAL_VALUE | CASCADE_RECOMPUTED

    # It happens when returned value of CHI::Cascade::run is undef and here is reason why:
    # value right now is being computed in other process and no old value in cache
    CASCADE_COMPUTING | CASCADE_NO_CACHE

This method is useful for debugging or logging processes.

=back

=head1 STATE BITS

Since version 0.26 the CHI::Cascade introduces the concept of state bits. An
every value object (even which has not valid value) has a history is described
by these state bits. To use this bit mask we can know how this value was gotten.
These bits are returned by L<CHI::Cascade/run> in L<CHI::Cascade/state>
variable.

=over

=item CASCADE_NO_CACHE

A value of target was missed in cache. Only as information as value was fetched

=item CASCADE_COMPUTING

A value of target to be computing in other process. So L<CHI::Cascade/run> will
return to you a B<undef> (if it misses in cache) or B<old value from cache>.

=item CASCADE_DEFERRED

A value of target should be recomputed but was not recomputed because
L<CHI::Cascade/run> was executed with L<CHI::Cascade/defer> option as B<true>.
This useful when you want to control an excution of codes of targets yourself.

=item CASCADE_FROM_CACHE

A value of target is B<old> or B<actual> value and was fetched from cache.

=item CASCADE_ACTUAL_VALUE

A value of target is B<actual> value (should not be recomputed)

=item CASCADE_RECOMPUTED

A value of target was recomputed by your request right now (was called
L<CHI::Cascade/code> in your process)

=item CASCADE_CODE_EXCEPTION

This state bit occurs only if exception was thrown from code or any dependencies
and it has the type L<CHI::Cascade::Value> (the expression C<<
$@->isa('CHI::Cascade::Value') >> is C<true>). If there to be thrown an other
type expression it will be rethrown from L<CHI::Cascade/run>. A value of
target returned by L<CHI::Cascade/run> can be:

=over

=item undef

A cache doesn't have any value of target

=item old value from cache

If L<CHI::Cascade/code> if a code or any code of dependencies threw exception as
L<CHI::Cascade::Value> object without value and a cache has any value for target
(i.e. C<< die CHI::Cascade::Value->new >>)

=item value was thrown by exception

If value was thrown by C<< die CHI::Cascade::Value->new->value(123) >> and even same: C<< die
CHI::Cascade::Value->new->value(undef) >>) for example.

=back

=item CASCADE_ACTUAL_TERM

The method L<CHI::Cascade/run> was run with or rule for this target has an
L<actual_term|CHI::Cascade/actual_term> option and the C<actual term> period has
not passed from last time of a dependencies checking (a value returned by C<run>
can be old and if it's true then the CASCADE_ACTUAL_VALUE will not be
set).

=item CASCADE_TTL_INVOLVED

A returned value is not actual value and already is old because some dependence
is newly than value which depends from this. But you describes an option C<ttl>
in L<CHI::Cascade/rule>. If you had passed the option C<ttl> like C<\$ttl> to
L<CHI::Cascade/run> method there in $ttl will be fractal number of "time to
live" - how many seconds are left before the computation (of course, if you will
call C<run> again for that target). This feature is useful for global reset
mechanism (one I<reset> target as global dependence and other rules from its
have a C<ttl> parameter in I<rules>).

=back

=head1 AUTHOR

This module has been written by Perlover <perlover@perlover.com>

=head1 LICENSE

This module is free software and is published under the same terms as Perl
itself.

=head1 SEE ALSO

L<CHI::Cascade>

=cut
