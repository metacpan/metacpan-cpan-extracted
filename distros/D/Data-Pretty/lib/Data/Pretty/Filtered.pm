package Data::Pretty::Filtered;
use strict;
use warnings;
use vars qw( $VERSION );
our $VERSION = 'v0.1.0';

use Data::Pretty ();
use Carp ();

use parent 'Exporter';
our @EXPORT_OK = qw(add_dump_filter remove_dump_filter dump_filtered);

sub add_dump_filter {
    my $filter = shift;
    unless (ref($filter) eq "CODE") {
        Carp::croak("add_dump_filter argument must be a code reference");
    }
    push(@Data::Pretty::FILTERS, $filter);
    return $filter;
}

sub remove_dump_filter {
    my $filter = shift;
    @Data::Pretty::FILTERS = grep $_ ne $filter, @Data::Pretty::FILTERS;
}

sub dump_filtered {
    my $filter = pop;
    if (defined($filter) && ref($filter) ne "CODE") {
        Carp::croak("Last argument to dump_filtered must be undef or a code reference");
    }
    local @Data::Pretty::FILTERS = ($filter ? $filter : ());
    return &Data::Pretty::dump;
}

1;

=head1 NAME

Data::Pretty::Filtered - Pretty printing with filtering

=head1 DESCRIPTION

The following functions are provided:

=head1 FUNCTIONS

=head2 add_dump_filter( \&filter )

This registers a filter function to be used by the regular L<Data::Pretty::dump()|Data::Pretty/dump> function. By default no filters are active.

Since registering filters has a global effect is might be more appropriate to use the dump_filtered() function instead.

=head2 remove_dump_filter( \&filter )

Unregister the given callback function as filter callback. This undoes the effect of L<add_filter>.

=head2 dump_filtered(..., \&filter )

Works like L<Data::Pretty::dump()|Data::Pretty/dump>, but the last argument should be a filter callback function. As objects are visited the filter callback is invoked at it might influence how objects are dumped.

Any filters registered with L</add_filter()> are ignored when this interface is invoked. Actually, passing C<undef> as C<\&filter> is allowed and C<< dump_filtered(..., undef) >> is the official way to force unfiltered dumps.

=head1 FILTER CALLBACK

A filter callback is a function that will be invoked with 2 arguments: a context object and reference to the object currently visited.  

The return value should either be a hash reference or C<undef>.

    sub filter_callback {
        my($ctx, $object_ref) = @_;
        ...
        return { ... }
    }

If the filter callback returns C<undef> (or nothing) then normal processing and formatting of the visited object happens.

If the filter callback returns a hash it might replace or annotate the representation of the current object.

=head1 FILTER CONTEXT

The L<context object|Data::Pretty::FilterContext> provides methods that can be used to determine what kind of object is currently visited and where it's located. Please check the L<module documentation|Data::Pretty::FilterContext>

=head2 FILTER RETURN HASH

The following elements has significance in the returned hash:

=over 4

=item * C<dump> => C<$string>

Incorporates the given string as the representation for the current value

=item * C<object> => C<$value>

C<dump> the given value instead of the one visited and passed in as $object.

This is basically the same as specifying C<< dump => Data::Pretty::dump($value) >>.

=item * C<comment> => C<$comment>

Prefixes the value with the given comment string

=item * C<bless> => C<$class>

Makes it look as if the current object is of the given C<$class> instead of the class it really has (if any). The internals of the object is dumped in the regular way. The C<$class> can be the empty string to make C<Data::Pretty> pretend the object was not blessed at all.

=item * C<hide_keys> => ['key1', 'key2',...]

=item * C<hide_keys> => \&code

If the C<$object> is a hash dump is as normal but pretend that the listed keys did not exist. If the argument is a function then the function is called to determine if the given key should be hidden.

=back

=head1 SEE ALSO

L<Data::Pretty>, L<Data::Pretty::FilterContext>

=head1 CREDITS

Credits to Gisle Aas for the original L<Data::Dump> version and to Breno G. de Oliveira for maintaining it.

=head1 COPYRIGHT & LICENSE

Copyright(c) 2023 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
