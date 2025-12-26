package AnyEvent::FTP::Client::Site;

use strict;
use warnings;
use 5.010;

# ABSTRACT: Dispatcher for site specific ftp commands
our $VERSION = '0.20'; # VERSION

sub new
{
  my($class, $client) = @_;
  bless { client => $client }, $class;
}

sub AUTOLOAD
{
  our $AUTOLOAD;
  my $self = shift;
  my $name = $AUTOLOAD;
  $name =~ s/^.*://;
  $name =~ s/_(.)/uc $1/eg;
  my $class = join('::', qw( AnyEvent FTP Client Site ), ucfirst($name) );
  eval qq{ use $class () };
  die $@ if $@;
  $class->new($self->{client});
}

# don't autoload DESTROY
sub DESTROY { }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::FTP::Client::Site - Dispatcher for site specific ftp commands

=head1 VERSION

version 0.20

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Ryo Okamoto

Shlomi Fish

José Joaquín Atria

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
