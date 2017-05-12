package Bio::GMOD::Blast::Graph::MyMath;
BEGIN {
  $Bio::GMOD::Blast::Graph::MyMath::AUTHORITY = 'cpan:RBUELS';
}
BEGIN {
  $Bio::GMOD::Blast::Graph::MyMath::VERSION = '0.06';
}
#####################################################################
#
# Cared for by Shuai Weng <shuai@genome.stanford.edu>
#
# Originally created by John Slenk <jces@genome.stanford.edu>
#
# You may distribute this module under the same terms as perl itself
#-----------------------------------------------------------------

require Exporter;
@ISA = qw( Exporter );
@EXPORT_OK = qw( max round floor ceil );

sub max
{
    my( $a, $b ) = @_;

    return( ($a > $b) ? $a : $b );
}

sub round
{
    my( $float ) = shift;
    return( int($float+0.5) );
}

sub floor
{
    my( $float ) = shift;
    return( int($float) );
}

sub ceil
{
    my( $float ) = shift;
    return( int($float+0.5) );
}

1;


__END__
=pod

=encoding utf-8

=head1 NAME

Bio::GMOD::Blast::Graph::MyMath

=head1 AUTHORS

=over 4

=item *

Shuai Weng <shuai@genome.stanford.edu>

=item *

John Slenk <jces@genome.stanford.edu>

=item *

Robert Buels <rmb32@cornell.edu>

=item *

Jonathan "Duke" Leto <jonathan@leto.net>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by The Board of Trustees of Leland Stanford Junior University.

This is free software, licensed under:

  The Artistic License 1.0

=cut

