package Data::Localize::Localizer;
use utf8;
use Moo;
use Carp ();
use Data::Localize;
use Encode ();

BEGIN {
    if (Data::Localize::DEBUG) {
        require Data::Localize::Log;
        Data::Localize::Log->import
    }
}

has _localizer => (
    is => 'rw',
    weak_ref => 1,
);

has initialized => (
    is => 'rw',
    default => 0,
    init_arg => undef,
);

has formatter => (
    is => 'rw',
    lazy => 1,
    isa => sub { $_[0]->isa('Data::Localize::Format') },
    builder => "_build_formatter",
    required => 1,
    handles => { format_string => 'format' },
);

sub _build_formatter {
    Module::Load::load('Data::Localize::Format::Maketext');
    return Data::Localize::Format::Maketext->new();
}

sub BUILD {
    $_[0]->initialized(1);
}

sub register {
    my ($self, $loc) = @_;
    if ($self->_localizer) {
        Carp::confess("Localizer $self is already attached to another Data::Localize object ($loc)");
    }
    $self->_localizer( $loc );
}

sub localize_for {
    my ($self, %args) = @_;
    my ($lang, $id, $args) = @args{ qw(lang id args) };

    my $value = $self->get_lexicon($lang, $id) or return ();
    if (Data::Localize::DEBUG()) {
        debugf("localize_for - '%s' -> '%s'",
            $id,
            defined($value) ? Encode::encode_utf8($value) : '(null)'
        );
    }
    if ( $value ) {
        return $self->format_string($lang, $value, @$args);
    }
    return ();
}

1;

__END__

=head1 NAME

Data::Localize::Localizer - Localizer Base Class

=head1 SYNOPSIS

    package MyLocalizer;
    use Moo;

    extends 'Data::Localize::Localizer';

    no Moo;

=head1 METHODS

=head2 register

Does basic registration for the localizer. If you're overriding
this method, be sure to call the super class' register() method!

=head2 localize_for

=head2 format_string

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
