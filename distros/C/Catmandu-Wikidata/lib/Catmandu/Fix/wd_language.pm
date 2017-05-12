package Catmandu::Fix::wd_language;
#ABSTRACT: Limit string values in a Wikidata entity record to a selected language
our $VERSION = '0.06'; #VERSION
use Catmandu::Sane;
use Moo;

with 'Catmandu::Fix::Base';

has language => (is => 'ro', required => 1);
has force => (is => 'ro');

around BUILDARGS => sub {
    my ($orig, $class, $language) = @_;
    $orig->($class, { language => $language });
};

sub emit {
    my ($self, $fixer) = @_;

    my $language = $self->language;
    my $var  = $fixer->var;
    my $code = $fixer->capture( sub { _fix_code($_[0],$language) } );

    return "${code}->(${var})";
}

sub _fix_code {
    my ($data, $language) = @_;

    foreach my $what (qw(labels descriptions)) {
        next unless exists $data->{$what};
        my $field = $data->{$what};
        if (ref $field) { # keep simple strings as given
            my $string = $field->{$language};
            if (defined $string) {
                $data->{$what} = ref $string ? $string->{value} : $string;
            } else {
                delete $data->{$what};
            }
        }
    }

    if (exists $data->{labels}) {
        $data->{label} = delete $data->{labels};
    }

    if (exists $data->{descriptions}) {
        $data->{description} = delete $data->{descriptions};
    }

    if (ref $data->{aliases} and ref $data->{aliases} eq 'HASH') {
        my $aliases = $data->{aliases}->{$language};
        if (defined $aliases) {
            $data->{aliases} = [
                map { ref $_ ? $_->{value} : $_ } @$aliases
            ];
        } else {
            $data->{aliases} = [ ];
        }
    }

    # TODO: only delete of string of requested language was found (or force)

    $data;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catmandu::Fix::wd_language - Limit string values in a Wikidata entity record to a selected language

=head1 VERSION

version 0.06

=head1 DESCRIPTION

This L<Catmandu::Fix> modifies a Wikidata entity record, as imported by
L<Catmandu::Importer::Wikidata>, by deleting all language tagged strings (in
C<aliases>, C<labels>, and C<descriptions>) except a selected language. The
strings are also simplified as done with L<Catmandu::Fix::wd_simple_strings>.

=head1 AUTHOR

Jakob Voß

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
