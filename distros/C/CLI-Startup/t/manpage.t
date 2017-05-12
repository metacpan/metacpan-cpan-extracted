# Test the print_manpage functionality

use Test::More;
use Test::Trap;

eval "use CLI::Startup 'startup'";
plan skip_all => "Can't load CLI::Startup" if $@;

# Simulate an invocation with --manpage
{
    local @ARGV = ('--manpage');

    trap { startup({ x => 'dummy option' }) };
    ok $trap->leaveby eq 'exit', "App exited";
    ok $trap->exit == 0, "Normal exit";
    ok $trap->stdout, "Stuff printed to stdout";
    ok $trap->stderr eq '', "Nothing printed to stderr";
    like $trap->stdout, qr/My::Module - An example module/, "POD contents printed";
}

done_testing();

__END__
=head1 NAME

My::Module - An example module

=head1 SYNOPSIS

=head2 NAME

My::Module - An example module

=head2 SYNOPSIS

    use My::Module;
    my $object = My::Module->new();
    print $object->as_string;

=head1 DESCRIPTION

This module does not really exist, it
was made for the sole purpose of
demonstrating how POD works.

=head2 Methods

=over 12

=item C<new>

Returns a new My::Module object.

=item C<as_string>

Returns a stringified representation of
the object. This is mainly for debugging
purposes.

=back

=head1 LICENSE

This is released under the Artistic 
License. See L<perlartistic>.

=head1 AUTHOR

Juerd - L<http://juerd.nl/>

=head1 SEE ALSO

L<perlpod>, L<perlpodspec>

=cut
