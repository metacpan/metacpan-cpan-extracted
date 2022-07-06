package CatalystX::Utils::HttpException;

use Moose;
use Carp;

with 'CatalystX::Utils::DoesHttpException';

sub import {
  my $class = shift;
  my @imports = @_;
  my $target = caller;

  foreach my $import_sub (@imports) {
    if( ($import_sub eq 'throw_http') && (!$target->can('throw_http')) ) {
        eval qq[
          package $target;
          use Carp;

          sub throw_http {
            my (\$status, \%args) = \@_;
            croak \$class->new(\%args, status_code => \$status);
          }
        ];
    }
  }
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

CatalystX::Utils::HttpException - A basic way to throw exceptions

=head1 SYNOPSIS

  use CatalystX::Utils::HttpException 'throw_http';

  throw_http $code, %extra;

  ## OR ##
  
  CatalystX::Utils::HttpException->throw(500, %extra);

  ## OR Subclass for your use case (although just consuming the role 'CatalystX::Utils::DoesHttpException'
  ## is probably cleaner
  
  package MyApp::Exception::Custom;

  use Moose;
  extends 'CatalystX::Utils::HttpException';

  sub status_code { 418 }
  sub error { 'Coffee not allowed' }


=head1 DESCRIPTION

If you need to throw an exception from code called by L<Catalyst>, such as code deep
inside your L<DBIx::Class> classes and you want to signal how to handle the issue
you an use this. You can also use this to subclass your own custom messages that will
get properly handled in a web context.

This class is semi deprecated (not recommended anymore for creating custom exception classes
and you should use the role L<CatalystX::Utils::DoesHttpException> which this consumes
directly.

=head1 SEE ALSO
 
L<CatalystX::Errors>.

=head1 AUTHOR
 
L<CatalystX::Errors>.
    
=head1 COPYRIGHT & LICENSE
 
L<CatalystX::Errors>.

=cut
