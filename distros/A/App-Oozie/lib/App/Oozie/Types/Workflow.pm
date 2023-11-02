package App::Oozie::Types::Workflow;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.015'; # VERSION

use App::Oozie::Constants qw(
    RE_LINEAGE_DATA_ITEM
    MIN_LEN_JUSTIFICATION
);
use Email::Valid;
use Sub::Quote qw( quote_sub );
use Type::Library -base;
use Type::Tiny;
use Type::Utils -all;

BEGIN {
    extends 'Types::Standard';
}

my $Email = declare Email => as Str,
    constraint => quote_sub q{
        my $input = shift;
        $input && Email::Valid->address( $input );
    },
;

my $LineageDataItem = declare LineageDataItem => as Str,
    constraint => quote_sub(
        q{
            my $input = shift;
            $input && $input =~ $pattern
        },
        {
            '$pattern' => RE_LINEAGE_DATA_ITEM,
        },
    ),
;

my $Justification_min_len = MIN_LEN_JUSTIFICATION;
my $Justification = declare Justification => as Str,
    constraint => quote_sub(
        q{
            my $input = shift;
            if ( ! $input ) {
                return;
            }
            $input =~ s{ \A \s+}{}xms;
            $input =~ s{ \s+ \z }{}xms;
            my $len = length $input; # Do nothing as this is marked optional
            if ( $len < $min_length ) {
                warn sprintf "Justification defined with %s characters while at least %s characters are needed",
                                 $len,
                                 $min_length,
                ;
                return;
            }
            # looks alright
            return 1;
        },
        {
           '$min_length' => \$Justification_min_len,
        },
    ),
;

my $WorkflowMeta = declare WorkflowMeta => as Dict[
    lineage => Maybe[ Optional[
        Dict[
            inputs  => Optional[ ArrayRef[ $LineageDataItem ] ],
            outputs => Optional[ ArrayRef[ $LineageDataItem ] ],
        ]
    ]],
    ownership => Dict[
        emails        => Optional[ ArrayRef[ $Email ] ],
        justification => Optional[ $Justification ],
        org_id        => Optional[ Str ],
        team          => Optional[ Str ],
    ],
];

my $DummyWorkflowMeta = declare DummyWorkflowMeta => as Dict[
    lineage => Maybe[ Dict[
        inputs  => Optional[ ArrayRef[ Str ] ],
        outputs => Optional[ ArrayRef[ Str ] ],
    ]],
    ownership => Dict[
        emails        => Optional[ ArrayRef[ Str ] ],
        justification => Optional[ Str ],
        org_id        => Optional[ Str ],
        team          => Optional[ Str ],
    ],
];

union WorkflowMetaOrDummy => [ $WorkflowMeta, $DummyWorkflowMeta ];

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::Types::Workflow

=head1 VERSION

version 0.015

=head1 SYNOPSIS

    use App::Oozie::Types::Workflow qw( WorkflowMeta );

=head1 DESCRIPTION

Internal types.

=head1 NAME

App::Oozie::Types::Workflow - Internal types.

=head1 Types

=head2 DummyWorkflowMeta

=head2 Email

=head2 Justification

=head2 LineageDataItem

=head2 WorkflowMeta

=head1 SEE ALSO

L<App::Oozie>.

=head1 AUTHORS

=over 4

=item *

David Morel

=item *

Burak Gursoy

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
