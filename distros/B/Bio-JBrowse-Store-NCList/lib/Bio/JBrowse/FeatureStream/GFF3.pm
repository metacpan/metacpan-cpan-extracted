package Bio::JBrowse::FeatureStream::GFF3;
BEGIN {
  $Bio::JBrowse::FeatureStream::GFF3::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::JBrowse::FeatureStream::GFF3::VERSION = '0.1';
}
use strict;
use warnings;

use base 'Bio::JBrowse::FeatureStream';

sub new {
    my ( $class, @parsers ) = @_;

    return sub {} unless @parsers;

    my @items;
    my $cur_p = shift @parsers;
    my $item_stream = sub {
        return shift @items || do {
            my $i;
            until( ref $i eq 'ARRAY' ) {
                $i = $cur_p->next_item
                    or $cur_p = shift @parsers
                    or return;
            }
            @items = @$i;
            shift @items;
        };
    };

    my $self;
    $self = sub {
        my $item = $item_stream->() or return;
        return $self->_convert( $item );
    };
    return bless $self, $class;
}

sub _convert {
    my ( $self, $f ) = @_;

    # numify and correct offset of start
    $f->{start} -= 1 if defined $f->{start};

    # convert strand to 1/0/-1/undef if necessary
    { no warnings 'uninitialized';
      $f->{strand} = ( { '+' => 1, '-' => -1 }->{$f->{strand}} || $f->{strand} || undef );
    }

    # numify end, score, phase, strand
    for (qw( end score phase strand )) {
        $f->{$_} += 0 if defined $f->{$_};
    }

    my $a = delete $f->{attributes};
    my %h;
    for my $key ( keys %$f) {
        my $lck = lc $key;
        my $v = $f->{$key};
        if( defined $v && ( ref($v) ne 'ARRAY' || @$v ) ) {
            unshift @{ $h{ $lck } ||= [] }, $v;
        }
    }
    # rename child_features to subfeatures
    if( $h{child_features} ) {
        $h{subfeatures} = [
            map {
                [ map $self->_convert( $_ ), map @$_, @$_ ]
            } @{delete $h{child_features}}
        ];
    }
    if( $h{derived_features} ) {
        $h{derived_features} = [
            map {
                [ map $self->_convert( $_ ), map @$_, @$_ ]
            } @{$h{derived_features}}
        ];
    }

    my %skip_attributes = ( Parent => 1 );
    for my $key ( sort keys %{ $a || {} } ) {
        my $lck = lc $key;
        if( !$skip_attributes{$key} ) {
            push @{ $h{$lck} ||= [] }, @{$a->{$key}};
        }
    }

    my $flat = $self->_flatten_multivalues( \%h );
    return $flat;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Bio::JBrowse::FeatureStream::GFF3

=head1 AUTHOR

Robert Buels <rbuels@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Robert Buels.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
