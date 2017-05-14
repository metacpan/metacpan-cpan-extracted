package CatalystX::OAuth2::ClientPersistor;
use Moose::Role;

# ABSTRACT: Work-around for persisting oauth2-authenticated users safely

requires qw(for_session);

after for_session => sub {
  my ( $self, $c, $user ) = @_;
  if ( $user->Moose::Util::does_role('CatalystX::OAuth2::ClientContainer') ) {
    $user->clear_oauth2;
  } else {
    $user->oauth2(undef) if $user->can('oauth2');
  }
};

1;

__END__

=pod

=head1 NAME

CatalystX::OAuth2::ClientPersistor - Work-around for persisting oauth2-authenticated users safely

=head1 VERSION

version 0.001004

=head1 AUTHOR

Eden Cardim <edencardim@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Suretec Systems Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
