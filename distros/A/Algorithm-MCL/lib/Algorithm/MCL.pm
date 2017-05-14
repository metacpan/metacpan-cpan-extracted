package Algorithm::MCL;

# ABSTRACT: perl module implementing Markov Cluster Algorithm using PDL



use PDL;
use Inline 'Pdlpp';
use Mouse;

no PDL::NiceSlice;

BEGIN {
  $PDL::BIGPDL = 1;
}


has '_allVerts' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has '_vectors' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has '_orderedAllVerts' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );



sub addEdge {
  my $self = shift;
  my ( $vertex1, $vertex2, $edgeWeight ) = @_;

  $self->addDirectEdge($vertex1, $vertex2, $edgeWeight);
  $self->addDirectEdge($vertex2, $vertex1, $edgeWeight);
}



sub addDirectEdge {
  my $self = shift;
  my ( $from, $to, $edgeWeight ) = @_;

  $edgeWeight ||= 1;

  unless ( $self->_allVerts->{$from} ) {
    push @{$self->_orderedAllVerts}, "$from";
    $self->_allVerts->{$from} = $from;
  }
  unless ( $self->_allVerts->{$to} ) {
    push @{$self->_orderedAllVerts}, "$to";
    $self->_allVerts->{$to} = $to;
  }

  my $vertexEdges = $self->_vectors->{ $from };
  unless ( $vertexEdges )
    {
      $vertexEdges = {};
      $self->_vectors->{ $from } = $vertexEdges;
    }

  $vertexEdges->{ $to } = $edgeWeight;

  my $toVertexEdges = $self->_vectors->{ $to };
  unless ( $toVertexEdges )
    {
      $toVertexEdges = {};
      $self->_vectors->{ $to } = $toVertexEdges;
    }

  unless (defined $toVertexEdges->{$from})
    {
      $toVertexEdges->{$from} = 0;
    }
}



sub run {
  my $self = shift;

  my @verts = @{$self->_orderedAllVerts};
  my $numOfVerts = scalar @verts;

  my $vertsOffsets = {};
  for (my $kk=0; $kk < $numOfVerts; ++$kk)
    {
      $vertsOffsets->{ $verts[ $kk ] } = $kk;
    }

  my $matrix = zeros($numOfVerts, $numOfVerts);

  for (my $ii=0; $ii < $numOfVerts; ++$ii)
    {
      my $vector = $self->_vectors->{ $verts[ $ii ] };
      for (my $jj=0; $jj < $numOfVerts; ++$jj)
	{
	  if (exists $vector->{ $verts[ $jj ] })
	    {
	      $matrix->set( $ii, $jj, $vector->{ $verts[ $jj ] } );
	    }
	}
    }

  $matrix->inplace->addLoops;
  $matrix->inplace->makeStochastic;

  my $resultMatrix = $self->mcl( $matrix );

  my $clusters = $self->extractClusters($resultMatrix, $numOfVerts);

  return $clusters;
}


sub mcl {
  my $self = shift;
  my ( $matrix ) = @_;

  my $chaos = 1;
  while ($chaos > 0.0001) {
    my $mx = $matrix x $matrix;
    my $cList = $mx->inplace->inflate;
    $chaos = $cList->max;
    $matrix = $mx;
  }
  $matrix->inplace->cleanSmall;

  return $matrix;
}


sub extractClusters {
  my $self = shift;
  my ( $resultMatrix, $numOfVerts ) = @_;

  my $clIdxs = $resultMatrix->getClustersIndex;

  my $clusters = [];
  for ( my $ii=0; $ii < $numOfVerts; ++$ii )
    {
      if ($clIdxs->at( $ii ))
	{
	  my $cluster = [];
	  push @$cluster, $self->getIdxObj( $ii );
	  for ( my $jj=0; $jj < $numOfVerts; ++$jj )
	    {
	      if ($resultMatrix->at( $ii, $jj ))
		{
		  if ( $ii != $jj )
		    {
		      push @$cluster, $self->getIdxObj( $jj );
		      $clIdxs->set( $jj, 0 );
		    }
		}
	    }
	  push @$clusters, $cluster
	}
    }

  return $clusters;
}


sub getIdxObj {
  my $self = shift;
  my ( $idx ) = @_;

  return$self->_allVerts->{$self->_orderedAllVerts->[$idx]};
}



__PACKAGE__->meta->make_immutable();





=pod

=head1 NAME

Algorithm::MCL - perl module implementing Markov Cluster Algorithm using PDL

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use Algorithm::MCL;
    
    my $obj1 = new MyClass;
    my $ref2 = {};
    my $ref3 = \"abc";
    my $ref4 = \$val1;
    my $ref5 = [];
    
    my $mcl1 = Algorithm::MCL->new();
    
    # create graph by adding edges
    $mcl1->addEdge($obj1, $ref2);
    $mcl1->addEdge($obj1, $ref3);
    $mcl1->addEdge($ref2, $ref3);
    $mcl1->addEdge($ref3, $ref4);
    $mcl1->addEdge($ref4, $ref5);

    # run MCL algorithm on created graph
    my $clusters1 = $mcl1->run();
    
    # get clusters
    foreach my $cluster ( @$clusters1 ) {
       print "Cluster size: ". scalar @$cluster. "\n";
    }
    
    
    ####################################
    
    my $val1 = \"aaa";
    my $val2 = \"bbb";
    my $val3 = \"ccc";
    my $val4 = \"ddd";
    my $val5 = \"eee";
    
    my $mcl2 = Algorithm::MCL->new();
    $mcl2->addEdge($val1, $val2);
    $mcl2->addEdge($val1, $val3);
    $mcl2->addEdge($val2, $val3);
    $mcl2->addEdge($val3, $val4);
    $mcl2->addEdge($val4, $val5);
    
    my $clusters2 = $mcl2->run();
    
    foreach my $cluster ( @$clusters2 ) {
        print "Found Cluster\n";
        foreach my $vertex ( @$cluster ) {
            print "  Cluster element: $$vertex \n";
        }
    }

=head1 DESCRIPTION

This module is perl implementation of Markov Cluster Algorithm (MCL) based on Perl Data Language (PDL).

MCL is algorithm of finding clusters of vertices in graph. More information about MCL can be found at L<http://micans.org/mcl/>. There is also perl script implementing MCL - minimcl L<http://www.micans.org/mcl/scripts/minimcl>.

This module try to solve two problems:

=over 2

=item *

easy integration MCL in perl scripts and modules. Algorithm::MCL accept references as input and every reference will be found later in some cluster.

=item *

performance and scale. Algorithm::MCL use Perl Data Language for most of its processing and should run very fast on very big clusters. Main Algorithm::MCL procedures are written with "pdlpp".

=back

=head1 METHODS

=head2 new()

create new Algorithm::MCL object that accumulate graph edges and process data.

=head2 addEdge($ref1, $ref2, $distance)

add new edge to graph. first two parameters are reference to vertex objects. third parameter is "connection strength measurement" between vetices. "connection strength measurement" should be number between 0 and 1, higher number means stronger connectivity. if "connection strength measurement" is not defined it set to 1.

=head2 run()

apply MCL algorithm on graph. return reference to array that every element is reference to cluser array.

=head1 AUTHOR

Pinkhas Nisanov <pinkhas@nisanov.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Pinkhas Nisanov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__DATA__

__Pdlpp__



pp_def('getClustersIndex',
    Pars => 'a(m, n);  [o]idxs(m);',
    Code => q{
        int ii;
        int m_size = $SIZE(m);
        for (ii=0; ii<m_size; ii++) {
            int clFlag = 0;
            if ($a(m=>ii, n=>ii) > 0) {
                clFlag = 1;
            }
            $idxs(m=>ii) = clFlag;
        }
    }
);



pp_def('addLoops',
    Pars => 'a(m, n);',
    Code => q{
        int ii;
        int m_size = $SIZE(m);
        int n_size = $SIZE(n);
        for (ii=0; ii<m_size; ii++) {
            int jj;
            double vmax;
            vmax = 0;
            for (jj=0; jj<n_size; jj++) {
                if ($a(m=>ii,n=>jj) > vmax) {
                    vmax = $a(m=>ii, n=>jj);
                }
            }
            if ( vmax == 0 ) {
                vmax = 1;
            }
            $a(m=>ii, n=>ii) = vmax;
        }
    }
);



pp_def('inflate',
    Pars => 'a(n);  [o]chaos();',
    Code => q{
        double vsum;
        vsum = 0;
        double sumsq;
        sumsq = 0;
        double vmax;
        vmax = 0;
        loop(n) %{
            if ($a() != 0) {
                if ($a() < 0.00001) {
                    $a() = 0;
                }
                else {
                    $a() = $a() * $a();
                    vsum += $a();
                }
            }
        %}
        if (vsum > 0) {
            loop(n) %{
                $a() = $a() / vsum;
                sumsq = sumsq + $a() * $a();
                if ($a() > vmax) {
                    vmax = $a();
                }
            %}
        }
        $chaos() = vmax - sumsq;
    }
);


pp_def('makeStochastic',
    Pars => 'a(n);',
    Code => q{
        double vsum;
        vsum = 0;
        loop(n) %{
            if ($a() != 0) {
                if ($a() < 0.00001) {
                    $a() = 0;
                }
                else {
                    vsum += $a();
                }
            }
        %}
        if (vsum > 0) {
            loop(n) %{
                $a() = $a() / vsum;
            %}
        }
    }
);


pp_def('cleanSmall',
    Pars => 'a(n);',
    Code => q{
        loop(n) %{
            if ($a() < 0.1) {
                $a() = 0;
            }
        %}
    }
);


pp_done();


