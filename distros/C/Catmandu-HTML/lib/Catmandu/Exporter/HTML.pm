package Catmandu::Exporter::HTML;

our $VERSION = '0.02';

use Catmandu::Sane;
use Moo;
use namespace::clean;

with 'Catmandu::Exporter';

sub add {
    my ($self,$data) = @_;

    my $token = $data->{html} // [];

    for (@$token) {
        my $type = $_->[0];

        if ($type eq 'S') {
            $self->fh->print($_->[4]);
        }
        elsif ($type eq 'E') {
            $self->fh->print($_->[2]);
        }
        elsif ($type eq 'T') {
            $self->fh->print($_->[1]);
        }
        elsif ($type eq 'C') {
            $self->fh->print($_->[1]);
        }
        elsif ($type eq 'D') {
            $self->fh->print($_->[1]);
        }
        elsif ($type eq 'PI') {
            $self->fh->print($_->[2]);
        }
    }
}

sub commit {
    my $self = $_[0];
    $self->fh->close;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Exporter::HTML - a HTML exporter

=head1 SYNOPSIS

    # From the commandline
    $ catmandu convert HTML --fix myfixes to HTML < ex/test.html

    # From Perl

    use Catmandu;

    # Print to STDOUT
    my $exporter = Catmandu->exporter('HTML');

    $exporter->add_many($arrayref);
    $exporter->add_many($iterator);
    $exporter->add_many(sub { });

    $exporter->add($hashref);

    printf "exported %d objects\n" , $exporter->count;

    # Get an array ref of all records exported
    my $data = $exporter->as_arrayref;

=head1 DESCRIPTION

This is a L<Catmandu::Exporter> for converting Perl into HTML.

=head1 SEE ALSO

L<Catmandu::Importer::LIDO>, L<HTML::TokeParser>

=cut
