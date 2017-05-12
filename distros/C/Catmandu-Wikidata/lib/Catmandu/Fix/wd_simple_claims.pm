package Catmandu::Fix::wd_simple_claims;
#ABSTRACT: Simplify claims of a Wikidata entity record
our $VERSION = '0.06'; #VERSION
use Catmandu::Sane;
use Moo;

# TODO: also support other snak types
# See https://www.mediawiki.org/wiki/Wikibase/DataModel for more
sub simplify_snak {
    my ($snak) = @_;
    delete $snak->{property}; # redundant
    if ($snak->{datavalue}) { # innecessary nesting
        for (keys %{$snak->{datavalue}}) {
            $snak->{$_} = $snak->{datavalue}->{$_};
        }
        if ($snak->{datatype} eq 'wikibase-item') {
            $snak->{value} = $snak->{value}->{'numeric-id'};;
        }
        delete $snak->{type}; # equals to datatype
        delete $snak->{datavalue};
    }
}

sub fix {
    my ($self, $data) = @_;

    my $claims = $data->{claims} or return $data;

    while (my ($property,$cs) = each %$claims) {
        for my $c (@$cs) {
            delete $c->{id};                        # internal
            delete $c->{type};                      # always "statement"
            simplify_snak($c->{mainsnak});
            for (keys %{$c->{mainsnak}}) {          # innecessary nesting
                $c->{$_} = $c->{mainsnak}->{$_};
            }
            delete $c->{mainsnak};
            if ($c->{references}) {
                for my $r (@{$c->{references}}) {
                    delete $r->{hash};             # internal
                    next unless $r->{snaks};
                    for my $snaks (values %{$r->{snaks}}) {
                        for my $snak (@$snaks) {
                            simplify_snak($snak);
                        }
                    }
                }
            }
        }
    }

    $data;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catmandu::Fix::wd_simple_claims - Simplify claims of a Wikidata entity record

=head1 VERSION

version 0.06

=head1 DESCRIPTION

This L<Catmandu::Fix> modifies a Wikidata entity record by simplifying its claims. 

=head1 SEE ALSO

L<Catmandu::Fix::wd_simple> applies both L<Catmandu::Fix::wd_simple_claims> and
L<Catmandu::Fix::wd_simple_strings>.

=head1 AUTHOR

Jakob Voß

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
