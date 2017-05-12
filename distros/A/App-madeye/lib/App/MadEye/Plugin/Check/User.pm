package App::MadEye::Plugin::Check::User;
use strict;
use warnings;
use base qw/Class::Component::Plugin/;
use POSIX qw(getuid getpwuid);

sub check :Hook {
    my ($self, $context, $args) = @_;

    my $user = $self->config->{config}->{user};

    my @pw = getpwuid getuid;
    my $current_user = $pw[0];
    if ($current_user ne $user) {
        die "this script must run by $user user!(not $current_user)";
    }
}

1;
__END__

=head1 NAME

App::MadEye::Plugin::Check::User - check uid

=head1 SYNOPSIS

    - module: Check::User
      config:
        user: tokuhirom

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<App::MadEye>
