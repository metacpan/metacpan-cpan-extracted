use strict;
use warnings;
package Conclave::OTK::Queries;
# ABSTRACT: query provider for OTK

use Template;
use Conclave::OTK::Queries::OWL;

sub new {
  my ($class, $format) = @_;
  my $self = bless({}, $class);

  my $provider = "Conclave::OTK::Queries::$format";

  my $template_config = {
      INCLUDE_PATH => [ 'templates' ],
    };
  my $template = Template->new({
      LOAD_TEMPLATES => [ $provider->new($template_config) ],
    });

  $self->{format} = $format;
  $self->{template} = $template;

  return $self;
}

sub process {
  my ($self, $template_name, $vars) = @_;

  my $sparql;
  $self->{template}->process($template_name, $vars, \$sparql);

  return $sparql
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Conclave::OTK::Queries - query provider for OTK

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  TODO

=head1 DESCRIPTION

  TODO

=head1 AUTHOR

Nuno Carvalho <smash@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2015 by Nuno Carvalho <smash@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
