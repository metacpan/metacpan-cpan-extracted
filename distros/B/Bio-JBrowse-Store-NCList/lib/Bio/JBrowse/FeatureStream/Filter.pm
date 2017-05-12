package Bio::JBrowse::FeatureStream::Filter;
BEGIN {
  $Bio::JBrowse::FeatureStream::Filter::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::JBrowse::FeatureStream::Filter::VERSION = '0.1';
}
# ABSTRACT: filter another stream using a subroutine
use strict;
use warnings;

use base 'Bio::JBrowse::FeatureStream';



sub new {
    my ( $class, $stream, $filter_sub ) = @_;

    my $self;
    my @buffer;
    return $self = bless sub {
        return shift @buffer || do {
            while( !@buffer && ( my $f = $stream->() ) ) {
                push @buffer, $self->_apply_filter( $filter_sub, $f );
            }
            shift @buffer;
        };
    }, $class;
}

sub _apply_filter {
    my ( $self, $filter_sub, $feature ) = @_;

    return $feature if $filter_sub->( $feature );
    return map $self->_apply_filter( $filter_sub, $_ ),
               @{ $feature->{subfeatures} || [] };
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Bio::JBrowse::FeatureStream::Filter - filter another stream using a subroutine

=head1 METHODS

=head2 new( $stream, $filter_sub )

Filter a stream of features according to whether the given subroutine
returns true for a feature.  Recurses to subfeatures and returns those
if the sub returns true for them, but not the parent feature.

=head1 AUTHOR

Robert Buels <rbuels@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Robert Buels.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
