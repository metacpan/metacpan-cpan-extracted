package Catmandu::Importer::HTML;

our $VERSION = '0.02';

use Catmandu::Sane;
use Moo;
use HTML::TokeParser;
use namespace::clean;

with 'Catmandu::Importer';

sub generator {
    my ($self) = @_;
    my $n = 0;

    my $parser = HTML::TokeParser->new($self->fh);

    sub {
        state $ready = 0;
        return undef if ($ready++);

        my $record = {};

        while (my $token = $parser->get_token) {
            push @{$record->{html}} , $token;
        }

        $record;
    };
}

1;

__END__

=pod

=head1 NAME

Catmandu::Importer::HTML - An HTML importer

=head1 SYNOPSIS

    # From the command line
    $ catmandu convert HTML to YAML < ex/test.html

    # From Perl
    use Catmandu;

    my $importer = Catmandu->importer('HTML',file => 'ex/test.html');

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 DESCRIPTION

This is a L<Catmandu::Importer> for converting HTML data using the
L<HTML::TokeParser> parser.

=head1 CONFIGURATION

=over

=item file

Read input from a local file given by its path. Alternatively a scalar
reference can be passed to read from a string.

=item fh

Read input from an L<IO::Handle>. If not specified, L<Catmandu::Util::io> is used to
create the input stream from the C<file> argument or by using STDIN.

=item encoding

Binmode of the input stream C<fh>. Set to C<:utf8> by default.

=item fix

An ARRAY of one or more fixes or file scripts to be applied to imported items.

=back

=head1 METHODS

Every L<Catmandu::Importer> is a L<Catmandu::Iterable> all its methods are
inherited.

=head1 SEE ALSO

L<Catmandu::Importer>, L<HTML::TokeParser>

=cut
