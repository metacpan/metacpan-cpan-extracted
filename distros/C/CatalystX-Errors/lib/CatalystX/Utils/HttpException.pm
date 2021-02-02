package CatalystX::Utils::HttpException;

sub import {
  my $class = shift;
  my $target = caller;

  eval qq[
    package $target;
    sub throw_http {
      my (\$status, \%args) = \@_;
      die \$class->new(\%args, status => \$status);
    }
  ];
}

sub new {
  my ($class, %args) = @_;
  return bless \%args, $class;
}

sub meta { return shift->{meta} }
sub status { return shift->{status} }
sub errors { return shift->{errors} }

1;

=head1 NAME

CatalystX::Utils::HttpException - A basic way to throw exceptions

=head1 SYNOPSIS

  use CatalystX::Utils::HttpException;

  throw_http $code, %extra

=head1 DESCRIPTION

If you need to throw an exception from code called by L<Catalyst>, such as code deep
inside your L<DBIx::Class> classes and you want to signal how to handle the issue
you an use this. Actually I find the approach somewhat dubious but people seem to want
it and I'd rather provide a canonical approach.

=head1 SEE ALSO
 
L<CatalystX::Errors>.

=head1 AUTHOR
 
L<CatalystX::Errors>.
    
=head1 COPYRIGHT & LICENSE
 
L<CatalystX::Errors>.

=cut
