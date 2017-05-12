package CQL::TermNode;

use strict;
use warnings;
use base qw( CQL::Node );
use Carp qw( croak );
use CQL::Utils qw( indent xq renderPrefixes );

=head1 NAME

CQL::TermNode - represents a terminal Node in a CQL Parse Tree

=head1 SYNOPSIS

=head1 DESCRIPTION

CQL::TermNode represents a terminal in a CQL parse tree. A term node 
consists of the string itself with optional qualifier string and relation.
Examples could include:

=over 4

=item * george

=item * dc.creator=george

=back

=head1 METHODS

=head2 new()

The constructor which has must have at least a term attribute, and 
can also include optional qualifier and modifier terms.

=cut

sub new {
    my ($class,%args) = @_;
    croak( "must supply term parameter" ) if ! exists( $args{term} );
    return bless \%args, ref($class) || $class; 
}

=head2 getQualifier()

Get the qualifier in the terminal.

=cut

sub getQualifier {
    return shift->{qualifier};
}

=head2 getRelation()

Get the relation in the terminal.

=cut 

sub getRelation {
    return shift->{relation};
}

=head2 getTerm()

Get the actual term string in the terminal.

=cut

sub getTerm {
    return shift->{term};
}

=head2 toCQL()

Returns a CQL representation of the terminal node.

=cut

sub toCQL {
    my $self = shift;
    my $qualifier = maybeQuote( $self->getQualifier() );
    my $term = maybeQuote( $self->getTerm() );
    my $relation = $self->getRelation();

    my $cql;
    if ( $qualifier and $qualifier !~ /srw\.serverChoice/i ) { 
        $cql = join( ' ', $qualifier, $relation->toCQL(), $term);
    } else {
        $cql = $term;
    }
    return $cql;
}

=head2 toSwish()

=cut

sub toSwish {
    my $self = shift;
    my $qualifier = maybeQuote( $self->getQualifier() );
    my $term = maybeQuote( $self->getTerm() );
    my $relation = $self->getRelation();
    my $swish; 
    if ( $qualifier and $qualifier !~ /srw\.serverChoice/i ) { 
        $swish = join( ' ', $qualifier, $relation->toSwish(), $term );
    } else {
        $swish = $term;
    }
    return $swish;
}

=head2 toXCQL()

=cut

sub toXCQL {
    my ($self,$level,@prefixes) = @_;
    $level  = 0 unless $level;
    my $xml = 
        indent($level) . "<searchClause>\n" .
        renderPrefixes($level+1,@prefixes) .
        indent($level+1) . "<index>".xq($self->getQualifier())."</index>\n";
    if ( $self->getRelation() ) {
        $xml .= $self->getRelation()->toXCQL($level+1);
    }
    $xml .= 
        indent($level+1) . "<term>" . xq($self->getTerm()) . "</term>\n" . 
        indent($level) . "</searchClause>\n";
    return $self->addNamespace( $level, $xml );
}

=head2 toLucene()

=cut

sub toLucene {
    my $self      = shift;
    my $qualifier = maybeQuote( $self->getQualifier() );
    my $term      = maybeQuote( $self->getTerm() );
    my $relation  = $self->getRelation();

    my $query; 
    if ( $qualifier and $qualifier !~ /srw\.serverChoice/i ) { 
        my $base      = $relation->getBase();
        my @modifiers = $relation->getModifiers();

        foreach my $m ( @modifiers ) {
            if( $m->[ 1 ] eq 'fuzzy' ) {
                $term = "$term~";
            }
        }

	if( $base eq '=' ) {
	        $base = ':';
	}
	else {
		croak( "Lucene doesn't support relations other than '='" );
	}
        return "$qualifier$base$term";
    }
    else {
        return $term;
    }
}

sub maybeQuote {
    my $str = shift;
    return if ! defined $str;
    if ( $str =~ m|[" \t=<>/()]| ) { 
        $str =~ s/"/\\"/g;
        $str = qq("$str");
    }
    return $str;
}

1;
