package Data::AnyXfer::Elastic::CreateIndex;


#############################################################
use Carp;
croak 'This module has now been deprecated. '
. 'Please use Data::AnyXfer::Elastic::Indices directly.';
#############################################################


use v5.16.3;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);



with 'Data::AnyXfer::Elastic::Role::CreateIndex';

=head1 NAME

Data::AnyXfer::Elastic::CreateIndex - Creates Elasticsearch Indices

=head1 SYNOPSIS

    use Data::AnyXfer::Elastic::CreateIndex;

    my $bool = Data::AnyXfer::Elastic::CreateIndex->new->create_index(
        {   {   name            => 'interiors_2013',    # required
                mappings        => \%mappings,          # optional
                settings        => \%settings,          # optional
                warmers         => \%warmers,           # optional
                aliases         => \%aliases,           # optional
                delete_previous => 1,                   # optional
            }
        }
    );

=head1 DESCRIPTION

This module provides a method for creating Elasticsearch Indices. Modules pulls
role L<Data::AnyXfer::Elastic::Role::CreateIndex> in.

=cut

use namespace::autoclean;

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

