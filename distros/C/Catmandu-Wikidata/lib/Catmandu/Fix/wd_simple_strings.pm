package Catmandu::Fix::wd_simple_strings;
#ABSTRACT: Simplify labels, descriptions, and aliases of Wikidata entity records
our $VERSION = '0.06'; #VERSION
use Catmandu::Sane;
use Moo;

sub fix {
    my ($self, $data) = @_;

    foreach my $what (qw(labels descriptions)) {
        my $hash = $data->{$what};
        if ($hash) {
            foreach my $lang (keys %$hash) {
                $hash->{$lang} = $hash->{$lang}->{value};
            };
        }
    }

    if (my $hash = $data->{aliases}) {
        foreach my $lang (keys %$hash) {
            $hash->{$lang} = [ map { $_->{value} } @{$hash->{$lang}} ];
        }
    }

    $data;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catmandu::Fix::wd_simple_strings - Simplify labels, descriptions, and aliases of Wikidata entity records

=head1 VERSION

version 0.06

=head1 DESCRIPTION

This L<Catmandu::Fix> modifies a Wikidata entity record by simplifying the
labels, aliases, and descriptions. In particular it converts

    "en": { "language: "en", "value": "foo" }

    "en": [ { "language: "en", "value": "foo" }, 
            { "language: "en", "value": "bar" } ]

to

    "en": "foo"

    "en": ["foo","bar"]

=head1 SEE ALSO

L<Catmandu::Fix::wd_simple> applies both L<Catmandu::Fix::wd_simple_strings>
and L<Catmandu::Fix::wd_simple_claims>.

=head1 AUTHOR

Jakob Voß

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
