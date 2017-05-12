package Data::Localize::Auto;
use Moo;
use Data::Localize;
BEGIN {
    if (Data::Localize::DEBUG) {
        require Data::Localize::Log;
        Data::Localize::Log->import;
    }
}

extends 'Data::Localize::Localizer';

sub localize_for {
    my ($self, %args) = @_;
    my ($id, $args) = @args{ qw(id args) };

    my $value = $id;
    if (Data::Localize::DEBUG()) {
        print STDERR "[Data::Localize::Auto]: localize_for - $id -> ",
            defined($value) ? $value : '(null)', "\n";
    }
    return $self->format_string('auto', $value, @$args) if $value;
    return ();
}

1;

=head1 NAME

Data::Localize::Auto - Fallback Localizer

=head1 SYNOPSIS

    # Internal use only

=head1 METHODS

=head2 register

=head2 get_lexicon

Does nothing

=head2 localize_for

Uses the string ID as the localization source

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 COPYRIGHT

=over 4

=item The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=back

=cut
