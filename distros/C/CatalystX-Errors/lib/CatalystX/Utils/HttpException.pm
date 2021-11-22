package CatalystX::Utils::HttpException;

use Moose;
use Carp;

with 'Catalyst::Exception::Interface';

has 'info' => (is=>'ro', predicate=>'has_info');
has 'status' => (is=>'ro', isa=>'Int', lazy=>1, required=>1, default=>sub { 500 } );
has 'errors' => (is=>'ro', isa=>'ArrayRef', lazy=>1, required=>1, default=>sub {['The system has generated unspecifed errors.']} );

sub import {
  my $class = shift;
  my $target = caller;
  unless($target->can('throw_http')) {
    eval qq[
      package $target;
      use Carp;

      sub throw_http {
        my (\$status, \%args) = \@_;
        croak \$class->new(\%args, status => \$status);
      }
    ];
  }
}

sub as_string {
    my ($self) = @_;
    return join '; ', @{$self->errors};
}

sub throw {
    my $class = shift;
    my (%args) = @_;
    my $error = $class->new(%args);
    local $Carp::CarpLevel = 1;
    croak $error;
}
 
sub rethrow {
    my ($self) = @_;
    croak $self;
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

CatalystX::Utils::HttpException - A basic way to throw exceptions

=head1 SYNOPSIS

  use CatalystX::Utils::HttpException;

  throw_http $code, %extra;

  ## OR ##
  
  CatalystX::Utils::HttpException->throw(500, %extra);

  ## OR Subclass for your use case ##
  
  package MyApp::Exception::Custom;

  use Moose;
  extends 'CatalystX::Utils::HttpException';

  has '+status' => (init_arg=>undef, default=>sub {418});
  has '+errors' => (init_arg=>undef, default=>sub {['Coffee not allowed!']});

=head1 DESCRIPTION

If you need to throw an exception from code called by L<Catalyst>, such as code deep
inside your L<DBIx::Class> classes and you want to signal how to handle the issue
you an use this. You can also use this to subclass your own custom messages that will
get properly handled in a web context.

=head1 SEE ALSO
 
L<CatalystX::Errors>.

=head1 AUTHOR
 
L<CatalystX::Errors>.
    
=head1 COPYRIGHT & LICENSE
 
L<CatalystX::Errors>.

=cut
