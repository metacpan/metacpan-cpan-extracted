package Bio::GMOD::Blast::Graph::BaseObj;
BEGIN {
  $Bio::GMOD::Blast::Graph::BaseObj::AUTHORITY = 'cpan:RBUELS';
}
BEGIN {
  $Bio::GMOD::Blast::Graph::BaseObj::VERSION = '0.06';
}
#####################################################################
#
# Cared for by Shuai Weng <shuai@genome.stanford.edu>
#
# Originally created by John Slenk <jces@genome.stanford.edu>
#
# You may distribute this module under the same terms as perl itself
#-----------------------------------------------------------------


###############################################################
sub new {
###############################################################
    my( $class, @args ) = @_;

    my( $self ) = {};
    bless( $self, $class );
    $self->init( @args );

    return( $self );
}

###############################################################
sub init {
###############################################################
    my( $self ) = shift;

}
###############################################################
1;
###############################################################

__END__
=pod

=encoding utf-8

=head1 NAME

Bio::GMOD::Blast::Graph::BaseObj

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

