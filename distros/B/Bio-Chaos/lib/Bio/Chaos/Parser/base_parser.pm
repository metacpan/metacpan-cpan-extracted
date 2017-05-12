# $Id: BaseParser.pm,v 1.6 2004/03/11 17:22:57 cjm Exp $
# POD documentation - main docs before the code

=head1 NAME

Bio::Parser::BaseParser - DESCRIPTION of Object

=head1 SYNOPSIS

   # don't instantiate directly - instead do
   my $seqio = Bio::Parser->new(-format => "BaseParser", -file => \STDIN);

=head1 DESCRIPTION


=head1 FEEDBACK

=head1 AUTHOR - Chris Mungall

Email cjm at fruitfly dot org


=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut

package Bio::Chaos::Parser::base_parser;

use strict;
use vars qw(@ISA);
use FileHandle;
use base qw(Data::Stag::BaseGenerator);


sub fh {
    my $self = shift;
    $self->{_fh} = shift if @_;
    return $self->{_fh};
}

sub linebuffer {
    my $self = shift;
    $self->{_linebuffer} = shift if @_;
    return $self->{_linebuffer};
}

sub _readline {
    my $self = shift;
    my $lb = $self->linebuffer;
    if ($lb) {
	return pop @$lb
    }
    my $fh = $self->fh;
    my $line = <$fh>;
    return $line;
}

sub _pushback {
    my $self = shift;
    my $line = shift;
    push(@{$self->{_linebuffer}}, $line);
    return;
}

sub parse_fh {
    my $self = shift;
    my $fh = shift;
    $self->fh($fh);
    $self->pre_parse();
    while ($self->next_record) {
    }
    $self->post_parse();
}

sub pre_parse {
    my $self = shift;
    $self->start_event($self->record_tag);
}

sub post_parse {
    my $self = shift;
    $self->end_event($self->record_tag);
}

sub record_tag {
    return "record";
}

sub load_module {

    my $self = shift;
    my $classname = shift;
    my $mod = $classname;
    $mod =~ s/::/\//g;

    if ($main::{"_<$mod.pm"}) {
    }
    else {
	eval {
	    require "$mod.pm";
	};
	if ($@) {
	    $self->throw("No such module: $classname;;\n$@");
	}
    }
}



1;
