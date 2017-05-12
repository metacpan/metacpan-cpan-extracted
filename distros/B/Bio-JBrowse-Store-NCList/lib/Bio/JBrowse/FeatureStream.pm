package Bio::JBrowse::FeatureStream;
BEGIN {
  $Bio::JBrowse::FeatureStream::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::JBrowse::FeatureStream::VERSION = '0.1';
}
use strict;
use warnings;

my %must_flatten =
   map { $_ => 1 }
   qw( name id start end score strand description note );
# given a hashref like {  tagname => [ value1, value2 ], ... }
# flatten it to numbered tagnames like { tagname => value1, tagname2 => value2 }
sub _flatten_multivalues {
    my ( $self, $h ) = @_;
    my %flattened;

    for my $key ( keys %$h ) {
        my $v = $h->{$key};
        if( @$v == 1 ) {
            $flattened{ $key } = $v->[0];
        }
        elsif( $must_flatten{ lc $key } ) {
            for( my $i = 0; $i < @$v; $i++ ) {
                $flattened{ $key.($i ? $i+1 : '')} = $v->[$i];
            }
        } else {
            $flattened{ $key } = $v;
        }
    }

    return \%flattened;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Bio::JBrowse::FeatureStream

=head1 AUTHOR

Robert Buels <rbuels@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Robert Buels.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
