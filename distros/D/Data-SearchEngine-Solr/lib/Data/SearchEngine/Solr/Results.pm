package Data::SearchEngine::Solr::Results;
{
  $Data::SearchEngine::Solr::Results::VERSION = '0.20';
}
use Moose;

extends 'Data::SearchEngine::Results';

with (
    'Data::SearchEngine::Results::Faceted',
    'Data::SearchEngine::Results::Spellcheck'
);

1;
__END__
=pod

=head1 NAME

Data::SearchEngine::Solr::Results

=head1 VERSION

version 0.20

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Cold Hard Code, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

