package App::MadEye::Rule::Interval;
use strict;
use warnings;
use base qw/App::MadEye::Rule/;
use Cache::FileCache;
use YAML;

sub dispatch {
    my ($self, $context, $args) = @_;

    my $interval_time = $self->config->{interval_time} or die "missing interval_time";
    my $cache_root    = $self->config->{cache_root}    or die "missing cache_root";

    my $key = YAML::Dump($args->{target}).__PACKAGE__;
    $context->log(info => "Interval: $args->{target}, $args->{plugin}");

    my $cache = Cache::FileCache->new( { cache_root => $cache_root, } );
    if ($cache->get($key)) {
        return 1; # not notify
    } else {
        $cache->set($key => "Boofy", $interval_time);
        return 0;
    }
}

1;

# 監視間隔が短いとわんわん通知がくるので、この時間内なら問題があっても
# 再通知しない。

__END__

=head1 NAME

App::MadEye::Rule::Interval - notification interval

=head1 SCHEMA

    type: map
    mapping:
        interval_time:
            type: int
            required: yes
        cache_root:
            type: str
            required: yes

=head1 SEE ALSO

L<App::MadEye>, L<Cache::FileCache>


