package Apache2::REST::Writer::yaml ;
use strict ;

use YAML;

use Data::Dumper ;

=head1 NAME

Apache2::REST::Writer::yaml - Apache2::REST::Response Writer for yaml

=cut

=head2 new

=cut

sub new{
    my ( $class ) = @_;
    return bless {} , $class;
}

=head2 mimeType

Getter

=cut

sub mimeType{
    return 'text/yaml';
}

=head2 asBytes

Returns the response as yaml UTF8 bytes for output.

=cut

sub asBytes{
    my ($self,  $resp ) = @_ ;
    ## Shallow unblessed copy
    my %resp = %$resp ;
    my $yaml = Dump(\%resp) ;
    ## yaml is a perl string, not bytes.
    return Encode::encode_utf8($yaml) ;
}

1;
