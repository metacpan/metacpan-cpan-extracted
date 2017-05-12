package Catalyst::Model::Net::Amazon;

use 5.008001;
use strict;
use warnings;

use base qw/ Catalyst::Model /;

use Carp qw/ croak /;
use Catalyst::Utils ();
use Net::Amazon;
use NEXT;

our $VERSION = '0.01002';

sub new {
    my $self  = shift->NEXT::new(@_);
    my $class = ref($self);
    
    my ( $c, $arg_ref ) = @_;
    
    $arg_ref ||= {};
    
    croak "->config->{token} must be set for $class\n" if !$self->{token};
    
    my $args = Catalyst::Utils::merge_hashes( $arg_ref, $self->config );
    
    $self->{'.net-amazon'} = Net::Amazon->new( %$args );
    
    return $self;
}

sub ACCEPT_CONTEXT {
    return shift->{'.net-amazon'};
}

1;

__END__

=head1 NAME

Catalyst::Model::Net::Amazon - Catalyst model for Net::Amazon SOAP interface

=head1 SYNOPSIS

    # Use the helper to add an Net::Amazon model to your application...
    script/myapp_create.pl create model Net::Amazon Net::Amazon
    
    # This creates the following file...
    # lib/MyApp/Model/Net/Amazon.pm
    
    package MyApp::Model::Net::Amazon;
    
    use base qw/ Catalyst::Model::S3 /;
    
    __PACKAGE__->config(
        token => 'my amazon secret token',
    );
    
    1;
    
    
    # Then in your Catalyst controller, you just need to do...
    my $ua = $c->model('Net::Amazon');
    
    my $response = $ua->search( asin => '0201360683' );
    
    if ( $response->is_success ) {
        print $response->as_string, "\n";
    } else {
        print "Error: ", $response->message, "\n";
    }

=head1 METHODS

=head2 new

Instantiate a new L<Net::Amazon> Model. See 
L<Net::Amazon's new method|Net::Amazon/new> for the options available.

=head1 SEE ALSO

L<Catalyst::Helper::Net::Amazon>, L<Net::Amazon>

L<Catalyst::Model::S3>

=head1 AUTHOR

Carl Franks, C<cfranks@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Carl Franks

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
