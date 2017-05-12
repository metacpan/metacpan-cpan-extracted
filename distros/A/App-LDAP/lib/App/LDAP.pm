package App::LDAP;

our $VERSION = '0.1.2';

use Modern::Perl;

use Moose;
use MooseX::Singleton;

use App::LDAP::Command;

with 'App::LDAP::Role';

sub run {
  my ($self,) = @_;

  App::LDAP::Config->read;
  App::LDAP::Secret->read;

  App::LDAP::Connection->new(
      config()->{uri},
      port       => config()->{port},
      version    => config()->{ldap_version},
      onerror    => 'die',
  );

  App::LDAP::Command
      ->dispatch(@ARGV)
      ->new_with_options
      ->prepare()
      ->run();
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
__END__

=head1 NAME

App::LDAP - CLI tool providing common manipulation on LDAP servers

=head1 SYNOPSIS

    use App::LDAP;

    App::LDAP->new->run;

=head1 DESCRIPTION

App::LDAP is intent on providing client-side solution of
L<RFC 2307|http://www.ietf.org/rfc/rfc2307.txt>,
L<RFC 2798|http://www.ietf.org/rfc/rfc2798.txt>.

=head1 AUTHOR

shelling E<lt>navyblueshellingford@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) shelling

The MIT License

=cut
