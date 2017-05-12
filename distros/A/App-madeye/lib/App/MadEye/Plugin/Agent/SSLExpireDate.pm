package App::MadEye::Plugin::Agent::SSLExpireDate;
use strict;
use warnings;
use App::MadEye::Plugin::Agent::Base;
use Net::SSL::ExpireDate;

sub is_dead {
    my ($self, $target) = @_;

    my $conf     = $self->config->{config};
    my $type     = $conf->{type} or die "missing type";
    my $duration = $conf->{duration} or die "missing duration";

    my $ed = Net::SSL::ExpireDate->new( $type, $target );

    if ($ed->is_expired($duration)) {
        return "$target will expire at " . $ed->expire_date->ymd;
    } else {
        return; # ok.
    }
}

1;
__END__

=for stopwords SSL

=head1 NAME

App::MadEye::Plugin::Agent::SSLExpireDate - monitoring SSL expire date

=head1 SCHEMA

    type: map
    mapping:
        duration:
            type: str
            required: yes
        type:
            type: str
            required: yes
        target:
            type: seq
            required: yes
            sequence:
                - type: str

=head1 AUTHORS

Tokuhiro Matsuno

=head1 SEE ALSO

L<Net::SSL::ExpireDate>, L<App::MadEye>

