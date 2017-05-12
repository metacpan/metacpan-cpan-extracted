package CPAN::Flatten::Distribution::Factory;
use strict;
use warnings;
use HTTP::Tiny;
use CPAN::Meta::YAML;
use CPAN::Flatten::Distribution;

my $SELF = __PACKAGE__->_new(
    distfile_url => "http://cpanmetadb-provides.herokuapp.com/v1.2/package",
    ua => HTTP::Tiny->new(timeout => 10),
);

sub from_pacakge {
    my ($class, $package, $version) = @_;
    my $need_reason = wantarray;

    my ($distfile, $provides, $requirements) = $SELF->fetch_distfile($package, $version);
    if (!$distfile) {
        return unless $need_reason;
        return (undef, "failed to fetch distfile for $package");
    }

    CPAN::Flatten::Distribution->new(
        distfile => $distfile,
        provides => $provides,
        requirements => $requirements,
    );
}

sub _new {
    my ($class, %opt) = @_;
    bless {%opt}, $class;
}

sub fetch_distfile {
    my ($self, $package, $version) = @_;
    my $res = $self->{ua}->get( $self->{distfile_url} . "/$package" );
    return unless $res->{success};

    if (my $yaml = CPAN::Meta::YAML->read_string($res->{content})) {
        my $meta = $yaml->[0] or return;
        return ($meta->{distfile}, $meta->{provides}, $meta->{requirements});
    }
    return;
}

1;
