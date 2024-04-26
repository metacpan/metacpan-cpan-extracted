package Data::Dumper::UnDumper;
$Data::Dumper::UnDumper::VERSION = '0.01';
# ABSTRACT: load Data::Dumper output, including self-references

use 5.006;
use strict;
use warnings;

=head1 NAME

Data::Dumper::UnDumper - load Dumper output including $VAR1 refs


=head1 SYNOPSIS

Load in a L<Data::Dumper> output via eval, including supporting C<$VAR1>
style references etc as emitted if you don't set the C<Purity> option:

    use Data::Dumper::UnDumper;
    
    my $complex_ref = { ... };
    my $dumped = Data::Dumper::Dumper($complex_ref);

    my $undumped = Data::Dumper::UnDumper::undumper($dumped);

=head1 DESCRIPTION

Firstly, a safety warning: loading L<Data::Dumper> output, which is designed
to be C<eval>ed, is a big safety risk if the data comes from an untrusted
source.  It's evaled as Perl code, so it can do anything you could write a
Perl program to.  Future versions of this module may use L<Safe> to mitigate
that risk somewhat, but it's still there - to support object references,
C<bless> would have to be allowed.

So, given the choice, what should you use instead?  Any of the many serialisation
options that don't serialise as code - for e.g. JSON, YAML, etc.

I wrote this module, though, because I didn't have a choice - I was receiving
L<Data::Dumper> output which had been written to a log in the past by some code,
without using the C<<$Data::Dumper::PURITY>> setting, so it included C<$VAR1>
references, including re-used L<JSON::PP> objects.

This has been lightly tested with the default output from C<Data::Dumper::Dump()>.
It's quite likely that you could have L<Data::Dumper> generate output this will
not handle by setting some of the dumping options.

=head1 SUBROUTINES

=head2 undumper

Given the output of L<Data::Dumper>'s C<Dumper> / C<Dump> method, "undump"
it, deserialising it back in to a Perl scalar/object, handling `$VAR1`
references.

=cut

sub undumper {
    my $dumper_in = shift;
    # First, remove the leading $VAR1 assignment, we're going to assign to
    # our own var.
    $dumper_in =~ s{^\$VAR1 = }{};

    # Next, for all the VAR1 refs, turn them into a string we can eval later
    # They'll turn into a quoted form of e.g. "DUMPERREF:$_->{'foo'}" or whatever
    $dumper_in =~ s{\$VAR1->(.+)(,|$)}{
        my $cap = $1;
        my $end = $2;
        $cap =~ s/\{/\\{/g;
        $cap =~ s/\}/\\}/g;
        "q{DUMPERREF:\$obj->$cap}".$end
    }xge;

    # Right, now we can eval it (FIXME: do this as safely as an eval can be done,
    # e.g. using Safe)
    my $obj = eval $dumper_in;

    # Firstly, if the Data::Dumper-ed thing was just e.g. a plain scalar, we
    # have no more work to do
    if (!ref $obj) {
        return $obj;
    }

    # Start recursing (passing the ref as both args, this first call will
    # then start walking and recursing
    _recurse_resolve($obj, $obj);

    return $obj;

}

# Given a reference to the object we undumpered walk through its values
# (array / hash values), recursing whenever another level is encountered.
sub _recurse_resolve {
    my ($value, $obj, $depth) = @_;

    if ($depth++ > 50) {
        die "Too many levels of recursion resolving this dumper input "
            . " - stopping at depth $depth on value $value";
    }

    if (ref $value eq 'ARRAY') {
        for (@$value) { _recurse_resolve($_, $obj, $depth); }
    } elsif (ref $value eq 'HASH') {
        for (values %$value) { _recurse_resolve($_, $obj, $depth); }
    } else {
        # A plain value, resolve it if it's a DUMPERREF
        if ($value =~ /^DUMPERREF:(.+)$/) {
            # We need to unescape the escaped braces first, then what we're
            # left with should be safe to eval (FIXME prob use Safe here?)
            my $ref = $1;
            $ref =~ s/\\\{/\{/g;
            $ref =~ s/\\\}/\}/g;
            $value = eval $ref;

            # If the value we get is a token, then this was a ref to another
            # ref, and we need to resolve that too
            if ($value =~ /^DUMPERREF:(.+)$/) {
                _recurse_resolve($value, $obj, $depth);
            }
            $_[0] = $value;
        }
    }
}


=head1 SEE ALSO

=over

=item L<Data::Undump>

Doesn't support cyclical references, blessed objects.

=item L<Data::Undump::PPI>

Safer as it uses PPI not C<eval>, but doesn't support blessed objects
or refs.

=item plain old eval

For simple Data::Dumper output you can of course just C<eval> it, but that
falls down when the output includes references to other parts of the object
e.g. C<< 'foo' => $VAR1->{'bar'} >>

=back


=head1 AUTHOR

David Precious (BIGPRESH), C<< <davidp@preshweb.co.uk> >>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2023-2024 by David Precious

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 ACKNOWLEDGEMENTS

=cut


1; # End of Data::Dumper::UnDumper
