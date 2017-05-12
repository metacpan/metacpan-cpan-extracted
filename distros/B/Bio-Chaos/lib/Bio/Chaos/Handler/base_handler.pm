# $Id: base_transformer.pm,v 1.2 2004/03/08 21:45:53 cjm Exp $
# POD documentation - main docs before the code

=head1 NAME

Bio::Chaos::Handler::base_transformer - DESCRIPTION of Object

=head1 SYNOPSIS

   # don't instantiate directly - instead do
   my $seqio = Bio::Chaos::Handler->new(-format => "base_transformer", -file => \STDIN);

=head1 DESCRIPTION


=head1 FEEDBACK


=head1 AUTHOR - Chris Mungall

Email cjm at fruitfly dot org


=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut

package Bio::Chaos::Handler::base_handler;

use strict;
use vars qw(@ISA);
use FileHandle;
use Bio::Root::IO;
use Bio::Root::Root;

use base qw(Data::Stag::BaseHandler Bio::Chaos::Root);


sub printfunc {
    my $self = shift;
    my $H = $self->handler;
    return 
      sub {
	  $H->event(out => shift);
	  return;
      }
}

sub out {
    my $self = shift;
    my $fmt = shift;
    my $str = @_ ? sprintf($fmt, @_) : $fmt;
    my $H = $self->handler;
    $H->event(out=>$str);
    return;
}

sub printrow {
    my $self = shift;
    my @cols = @_;
    print join("\t", @cols), "\n";
}

1;
