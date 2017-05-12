package Business::3DSecure;

use strict;
use warnings;

use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD );

use Carp;

require Exporter;

@ISA = qw( Exporter AutoLoader );
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = '0.02';


my %fields = (
  is_success       => undef,
  result_code      => undef,
  test_transaction => undef,
  require_avs      => undef,
  transaction_type => undef,
  error_message    => undef,
  authorization    => undef,
  server           => undef,
  port             => undef,
  path             => undef,
  server_response  => undef,
);

sub new 
{
  my ( $class, $processor, %data ) = @_;

  Carp::croak( "unspecified processor" ) unless $processor;

  my $subclass = "${class}::$processor";

  if ( !defined( &$subclass ) ) 
  {
    eval "use $subclass";
    Carp::croak( "unknown processor $processor ($@)" ) if $@;
  }

  my $self = bless { processor => $processor }, $subclass;

  $self->build_subs( keys %fields );
  $self->set_defaults() if ( $self->can( "set_defaults" ) );

  foreach( keys %data ) 
  {
    my $key = lc( $_ );
    my $value = $data{ $_ };

    $key =~ s/^\-//;

    $self->build_subs( $key );
    $self->$key( $value );
  }

  return $self;
}

sub content 
{
  my ( $self, %params ) = @_;

  if ( %params ) 
  {
    $self->transaction_type( $params{ type } ) if ( $params{ type } );
    %{ $self->{ _content } } = %params;
  }

  return %{ $self->{ _content } };
}

sub required_fields 
{
  my ( $self, @fields ) = @_;

  my %content = $self->content();

  foreach( @fields ) 
  {
    Carp::croak( "missing required field $_" ) unless exists $content{ $_ };
  }
}

sub get_fields 
{
  my ( $self, @fields ) = @_;

  my %content = $self->content();
  my %new = ();

  foreach( @fields ) 
  { 
    $new{ $_ } = $content{ $_ }; 
  }

  return %new;
}

sub remap_fields 
{
  my ( $self, %map ) = @_;

  my %content = $self->content();

  foreach( %map ) 
  {
    $content{ $map{ $_ } } = $content{ $_ };
  }

  $self->content( %content );
}

sub submit 
{
  my ( $self ) = @_;

  Carp::croak( "Processor subclass did not override submit function" );
}

sub dump_contents 
{
  my ( $self ) = @_;

  my %content = $self->content();
  my $dump = "";

  foreach( keys %content ) 
  {
    $dump .= "$_ = $content{$_}\n";
  }

  return $dump;
}

# didnt use AUTOLOAD because Net::SSLeay::AUTOLOAD passes right to
# AutoLoader::AUTOLOAD, instead of passing up the chain
sub build_subs 
{
  my $self = shift;

  foreach ( @_ ) 
  {
    eval "sub $_ { my \$self = shift; if(\@_) { \$self->{$_} = shift; } return \$self->{$_}; }";
  }
}

1;

__END__

=head1 NAME

Business::3DSecure - Perl extension for 3D Secure Credit Card Verification

=head1 SYNOPSIS

  use Business::3DSecure;

  my $authentication = new Business::3DSecure( $processor );
  $authentication->content(  %content );

  $authentication->submit();

  $authentication->is_success() 



=head1 DESCRIPTION

This Module provide an interface to 3DSecure Authentication, it has been patterned of the Business::OnlinePayment module to provide an easy to understand interface

=head1 METHODS AND FUNCTIONS

=head2 new( $processor );

Create a new Business::3DSecure object, $processor is required, and defines the online processor to use.  

=head2 build_subs
 
Autoloading facility for methods to be returned by subclasses

=head2 content

Method to submit data to subclass

=head2 dump_contents

Dumps all key value pairs submited from content
 
=head2 get_fields

Gets all required and optional fields for submission

=head2 remap_fields

Remaps any fields from the incoming client code to the subclasses fields

=head2 required_fields

Checks if all required fields are there 

=head2 submit

Submits the 3DSecure call

=head1 AUTHOR

Clayton Cottingham , C<< <clayton@wintermarket.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-business-3dsecure at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-3DSecure>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Business::3DSecure

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Business-3DSecure>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Business-3DSecure>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-3DSecure>

=item * Search CPAN

L<http://search.cpan.org/dist/Business-3DSecure>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Clayton Cottingham of Wintermarket Networks www.wintermarket.net , all rights reserved.


This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
