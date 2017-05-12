package Catmandu::Fix::wd_simple;
#ABSTRACT: Simplify Wikidata entity records
our $VERSION = '0.06'; #VERSION
use Catmandu::Sane;
use Moo;

use Catmandu::Fix::wd_simple_strings;
use Catmandu::Fix::wd_simple_claims;
use Catmandu::Fix::wd_language as => 'wd_language';

has language => (is => 'ro', required => 0);

sub fix {
    my ($self, $data) = @_;

    wd_language($data, $self->language) if $self->language;
    Catmandu::Fix::wd_simple_strings::fix($self,$data);
    Catmandu::Fix::wd_simple_claims::fix($self,$data);

    if (my $hash = $data->{sitelinks}) {
        foreach my $lang (keys %$hash) {
            delete $hash->{$lang}->{site};
        }
    }

    $data;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catmandu::Fix::wd_simple - Simplify Wikidata entity records

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    wd_simple()
    wd_simple(language:"de")

=head1 DESCRIPTION

This L<Catmandu::Fix> simplifies a Wikidata entity record by applying both
L<Catmandu::Fix::wd_simple_strings> and L<Catmandu::Fix::wd_simple_claims>. It
further simplifies sitelinks by removing redundant fields.

=head1 AUTHOR

Jakob Voß

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
