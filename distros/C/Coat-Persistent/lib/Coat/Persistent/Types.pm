package Coat::Persistent::Types;

use strict;
use warnings;

use Class::Date;
use Coat::Types;

subtype 'UnixTimestamp'
    => as 'Int'
    => where { /^\d+$/ && $_ > 0 };

coerce 'UnixTimestamp'
    => from 'Class::Date'
    => via { $_->epoch };

coerce 'Class::Date'
    => from 'UnixTimestamp'
    => via { Class::Date->new($_) };

coerce 'Class::Date'
    => from 'Date'
    => via { Class::Date->new($_) };

coerce 'Class::Date'
    => from 'DateTime'
    => via { Class::Date->new($_) };

subtype 'DateTime'
    => as 'Str'
    => where { /^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d$/ };

coerce 'DateTime'
    => from 'UnixTimestamp'
    => via { Class::Date->new($_)->string };

coerce 'UnixTimestamp'
    => from 'DateTime'
    => via { Class::Date->new($_)->epoch };

# date

subtype 'Date'
    => as 'Str'
    => where { /^\d{4}-\d\d-\d\d$/ };

coerce 'Date'
    => from 'UnixTimestamp'
    => via { 
        my $date = Class::Date->new($_);
        my $str = $date->ymd;
        $str =~ s/\//-/g;
        return $str;
    };

coerce 'UnixTimestamp'
    => from 'Date'
    => via { Class::Date->new($_)->epoch };

'Coat::Persistent::Types';
__END__
=pod

=head1 NAME 

Coat::Persistent::Types

=head1 DESCRIPTION

This module provides a set of types and coercions that are of common use when
dealing with an database.

By loading this module you are able to use all the types defined here for your
attribute definitions (either for the 'isa' option or fore the 'store_as' one).

=head1 TYPES

=over 4

=item C<UnixTimestamp> 

An Int that is strictly greater than 0 and that represent the time since
1970-01-01 00:00:01

=item C<Date>

A string representing the date with the following format: YYYY-MM-DD

=item C<DateTime>

=back

=head1 COERCIONS

All the types defined are coerceable from the type UnixTimestamp and the type
UnixTimestamp can be coerced to all the types defined.

=head1 EXAMPLE

    package Stuff;

    use Coat::Persistent::Types;

    # we have a date field, we want to store it and to handle it as string
    # formated like YYYY-MM-DD
    has_p birth_date => (
        is => 'ro',
        isa => 'Date',
    );

    # we have a datetime that's changed whenever the object si touched.
    # we want to handle the data as a timestamp, and to store it as DateTime string.
    has_p last_update => (
        is => 'rw',
        isa => 'UnixTimestamp',
        store_as => 'DateTime',
    );

    # or if you'd rather have a Class::Date object than a UnixTimestamp :
    has_p last_update => (
        is => 'rw',
        isa => 'Class::Date',
        store_as => 'DateTime',
    );

=item C<Class::Date>

All the types defined in this module are coerceable from or to the type UnixTimestamp.

=back

=head1 SEE ALSO

L<Coat::Types> L<Coat::Persistent::Types::>

=head1 AUTHOR

Alexis Sukrieh <sukria@cpan.org>
http://www.sukria.net

=cut
