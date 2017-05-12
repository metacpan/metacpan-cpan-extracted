# $Id: Options.pm,v 1.9 2003/11/18 19:45:45 rkh Exp $
# @@banner@@

=head1 NAME

Bio::Prospect::Options -- Package for representing options

S<$Id: Options.pm,v 1.9 2003/11/18 19:45:45 rkh Exp $>

=head1 SYNOPSIS

 use Bio::Prospect::Options;
 use Bio::Prospect::LocalClient;
 use Bio::SeqIO;
                                                                                                                                    
 my $in = new Bio::SeqIO( -format=> 'Fasta', '-file' => $ARGV[0] );
 my $po = new Bio::Prospect::Options( seq=>1, svm=>1, global_local=>1,
                 templates=>[qw(1bgc 1alu 1rcb 1eera)] );
 my $pf = new Bio::Prospect::LocalClient( {options=>$po} );

 while ( my $s = $in->next_seq() ) {
   my @threads = $pf->thread( $s );
 }

=head1 DESCRIPTION

B<Bio::Prospect::Options> represent options. 

=cut

package Bio::Prospect::Options;

use warnings;
use strict;
use fields qw/ global fssp scop seqfile phdfile tfile
				templates /;
use vars qw( $VERSION );
$VERSION = sprintf( "%d.%02d", q$Revision: 1.9 $ =~ /(\d+)\.(\d+)/ );



sub new
  {
  my $type = shift;
  my $self = @_ ? initialize(@_) : {};
  return( bless($self, $type) );
  }

sub initialize
  {
  my %self;
  if (ref $_[0])							# new blah ( { opt=>arg, ... } )
	{ %self = %{$_[0]}; }
  elsif ( $#_ % 2 )							# new blah (   opt=>arg, ...   )
	{ %self = @_; }
  return \%self;
  }

1;
