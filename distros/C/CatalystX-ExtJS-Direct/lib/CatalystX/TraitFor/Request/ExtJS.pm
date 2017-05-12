#
# This file is part of CatalystX-ExtJS-Direct
#
# This software is Copyright (c) 2014 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package CatalystX::TraitFor::Request::ExtJS;
$CatalystX::TraitFor::Request::ExtJS::VERSION = '2.1.5';
# ABSTRACT: Sets the request method via a query parameter
use Moose::Role;

use namespace::autoclean;
use JSON::XS;

#has 'is_ext_upload' => ( isa => 'Bool', is => 'rw', lazy_build => 1 );

sub is_ext_upload {
    my ($self) = @_;
    return $self->header('Content-Type')
      && $self->header('Content-Type') =~ /^multipart\/form-data/
      && ( !$self->{content_type} || $self->{content_type} ne 'application/json');
}

around 'method' => sub {
    my ( $orig, $self, $method ) = @_;
    return $self->$orig($method) if($method);
    return $self->query_params->{'x-tunneled-method'} || $self->$orig();
    

};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CatalystX::TraitFor::Request::ExtJS - Sets the request method via a query parameter

=head1 VERSION

version 2.1.5

=head1 METHODS

=head2 is_extjs_upload

Returns true if the current request looks like a request from ExtJS and has
multipart form data, so usually an upload. 

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
