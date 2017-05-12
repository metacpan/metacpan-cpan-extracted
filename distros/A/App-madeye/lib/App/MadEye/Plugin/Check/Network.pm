package App::MadEye::Plugin::Check::Network;
use strict;
use warnings;
use base qw/Class::Component::Plugin/;
use Furl;

sub check : Hook {
    my ($self, $context, $args) = @_;

    my $conf = $self->config->{config};

    my $ua = Furl->new( timeout => $conf->{timeout} || 10 );

    for my $url (@{$conf->{urls}}) {
        if ( $ua->head($url)->is_success ) {
            return; # success!
        }
    }

    die "failed to connect : @{ $conf->{urls} }";
}

1;
__END__

=head1 NAME

App::MadEye::Plugin::Check::User - network is alive?

=head1 SYNOPSIS

    - module: Check::Network
      config:
        urls:
          - http://livedoor.com/
          - http://gmail.com/

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<App::MadEye>
