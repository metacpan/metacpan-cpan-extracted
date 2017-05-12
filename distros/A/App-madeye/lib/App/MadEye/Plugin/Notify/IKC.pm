package App::MadEye::Plugin::Notify::IKC;
use strict;
use warnings;
use base qw/App::MadEye::Plugin::Base/;
use Text::Truncate qw/truncstr/;
use POE::Component::IKC::ClientLite;

sub notify :Hook {
    my ($self, $context, $args) = @_;

    my $config = $self->config->{config};

    my $client = POE::Component::IKC::ClientLite->create_ikc_client(
        ip      => $config->{daemon_ip},
        port    => $config->{daemon_port},
        name    => "AppMadEye$$",
        timeout => $config->{timeout},
    ) or die "cannot connect to $config->{daemon_ip}:$config->{daemon_port}";

    for my $line (split /\n/, _format($args, $config->{cutoff_length})) {
        $client->post($config->{key}, $line);
    }
    $client->post($config->{key}, "> all");
}

sub _format {
    my ($args, $cutoff_length) = @_;

    my $text = '';
    while (my ($module, $targets) = each %$args) {
        $module = _moniker($module);
        $text .= "= $module\n" .  truncstr(_format_target($targets), $cutoff_length) . "\n";
    }
    $text;
}

sub _format_target {
    my $targets = shift;

    my $text = '';
    for my $target (@$targets) {
        $text .= "- $target->{target}\n";
        $text .= "$target->{message}\n";
    }
    $text;
}

sub _moniker {
    my $module = shift;
    $module =~ s/.+:://;
    $module;
}

1;
__END__

=head1 NAME

App::MadEye::Plugin::Notify::IKC - notify with POE

=head1 SCHEMA

    type: map
    mapping:
        daemon_port:
            type: int
            required: yes
        daemon_ip:
            type: str
            required: yes
        timeout:
            required: yes
            type: int
        key:
            required: yes
            type: str
        cutoff_length:
            required: yes
            type: int

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<App::MadEye>, L<POE>, L<POE::Component::IKC>

