use strict;
use warnings;

package Boolean::String;

# ABSTRACT: Strings with boolean values independent of perl's assumptions


use Sub::Exporter -setup => {
    exports => [ qw( true false ) ],
    groups => { default => [ qw( true false ) ] },
};


sub true {
    my $string = shift;

    return bless \"$string", 'Boolean::String::True';
}


sub false {
    my $string = shift;

    return bless \"$string", 'Boolean::String::False';
}


package # hide from PAUSE
    Boolean::String::True;

use overload
    bool     => sub { return 1 },
    '""'     => sub { return ${ shift() } },
    fallback => 1,
;


package # hide from PAUSE
    Boolean::String::False;

use overload
    bool     => sub { return 0 },
    '""'     => sub { return ${ shift() } },
    fallback => 1,
;

1;



=pod

=head1 NAME

Boolean::String - Strings with boolean values independent of perl's assumptions

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Boolean::String;

    $message = false 'Record not found';

    $message = true 'Record found';

=head1 DESCRIPTION

Boolean::String allows you to overload a string with a value in boolean context. Normally, perl considers all strings except the empty string to be true. Boolean::String allows you to change this assumption.

=head1 FUNCTIONS

=head2 true

This expects a single string, and returns an object that is true in boolean context and the passed in string in string context.

    $true_string = true '...';

=head2 false

This expects a single string, and returns an object that is false in boolean context and the passed in string in string context.

    $false_string = false '...';

=head1 IMPORTING

The functions are exported by default. Boolean::String uses L<Sub::Exporter|Sub::Exporter> for its import/export business. This makes it easy to change the names of the imported functions, like so:

    # import 'true_because' and 'false_because'
    use Boolean::String -all => { -suffix => '_because' };

    # import 'success' and 'failure'
    use Boolean::String true => { -as => 'success' }, false => { -as => 'failure' };

There's a whole slew of flexibility that Sub::Exporter brings to the table, so check it out if your importing needs are more involved than this.

=head1 SEE ALSO

=head2 L<Scalar::Util's dualvar|Scalar::Util/dualvar>

dualvar allows you to have different values for numeric and string contexts. Unfortunately, Boolean::String's functionality cannot be implemented with this (simply setting the numeric value to 0/1), because perl derives a variable's value in boolean context from its value in string context, not numeric context.

=head2 L<Sub::Exporter's import semantics|Sub::Exporter/CALLING THE EXPORTER>

Sub::Exporter handles the importing of the functions, so if you want to do something fancy, that's where you can find out how.

=head1 AUTHOR

everybody <everybody at cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by everybody.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

