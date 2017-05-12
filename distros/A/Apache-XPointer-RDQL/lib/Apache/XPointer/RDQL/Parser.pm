# $Id: Parser.pm,v 1.6 2004/11/16 04:36:26 asc Exp $
use strict;

package Apache::XPointer::RDQL::Parser;
use base qw (RDQL::Parser);

$Apache::XPointer::RDQL::Parser::VERSION = '1.1';

=head1 NAME

Apache::XPointer::RDQL::Parser - Apache::XPointer::RDQL specific methods for RDQL::Parser

=head1 SYNOPSIS

 use Apache:::XPointer::RDQL::Parser;

 my $query  = "SELECT ...";
 my $parser = Apache::XPointer::RDQL::Parser->new();

 $parser->parse($query);

 foreach my $var ($parser->bind_variables()) {

     my ($prefix, $localname) = $parser->bind_predicate($var);
     my $uri = $parser->lookup_namespaceURI($prefix);
 }

=head1 DESCRIPTION

Apache::XPointer::RDQL specific methods for RDQL::Parser.

=cut

=head1 OBJECT METHODS

This pacakages subclasses I<RDQL::Parser> a defines the following helper methods :

=cut

use overload qq("") => sub {
    my $self = shift;
    return $self->query_string();
};

sub parse {
    my $self = shift;
    my $query = shift;

    $self->{'__query'} = $query;
    return $self->SUPER::parse($query);
}

=head2 $obj->query_string()

Returns the original RDQL query string.

=cut

sub query_string {
    my $self = shift;
    return $self->{'__query'};
}

=head2 $obj->bind_variables()

Returns a list.

=cut

sub bind_variables {
    my $self = shift;

    return map {
	$_ =~ /^\?(.*)/;
	$1;
    } @{$self->{'resultVars'}};
}

=head2 $obj->bind_predicate($bind_variable)

Returns a list containting a prefix and a localname.

=cut

sub bind_predicate {
    my $self          = shift;
    my $bind_variable = shift;

    foreach my $spo (@{$self->{'triplePatterns'}}) {
	if ($spo->[2] eq "?$bind_variable") {

	    $spo->[1] =~ /^<([^:]+)::([^>]+)>$/;
	    return ($1,$2);
	}
    }

    return undef;
}

=head2 $obj->lookup_namespaceURI($prefix)

Returns a string.

=cut

sub lookup_namespaceURI {
    my $self   = shift;
    my $prefix = shift;

    if (! exists($self->{'prefixes'}->{$prefix})) {
	return undef;
    }
    
    return $self->{'prefixes'}->{$prefix};
}

=head1 VERSION

1.1

=head1 DATE

$Date: 2004/11/16 04:36:26 $

=head1 AUTHOR

Aaron Straup Cope E<lt>ascope@cpan.orgE<gt>

=head1 SEE ALSO

L<Apache::XPointer>

L<RDQL::Parser>

=head1 LICENSE

Copyright (c) 2004 Aaron Straup Cope. All rights reserved.

This is free software, you may use it and distribute it under
the same terms as Perl itself.

=cut

return 1;
