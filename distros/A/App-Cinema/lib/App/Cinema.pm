package App::Cinema;
use Moose;
use Catalyst::Runtime '5.70';
use Catalyst qw/
  -Debug
  ConfigLoader
  Static::Simple
  StackTrace

  Authentication
  Authorization::Roles
  Session
  Session::Store::FastMmap
  Session::State::Cookie
  /;

BEGIN {
	our $VERSION = '1.171';
}

#after this line, the $VERSION of other classes are configured
__PACKAGE__->setup;

1;

=head1 NAME

App::Cinema - a demo website for Catalyst framework

=head1 DESCRIPTION



=head1 AUTHOR

Jeff Mo - <mo0118@gmail.com>

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
