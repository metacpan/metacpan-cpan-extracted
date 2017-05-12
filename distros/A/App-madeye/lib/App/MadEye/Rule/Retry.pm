package App::MadEye::Rule::Retry;
use strict;
use warnings;
use base qw/App::MadEye::Rule/;
use Cache::FileCache;
use YAML;

sub dispatch {
    my ($self, $context, $args) = @_;

    my $expire_time = $self->config->{expire_time} or die "missing expire_time";
    my $cache_root  = $self->config->{cache_root}  or die "missing cache_root";

    my $key = YAML::Dump($args->{target});

    $context->log(info => "Retry: $args->{target}, $args->{plugin}");

    my $cache = Cache::FileCache->new( { cache_root => $cache_root, } );
    my $retry = $cache->get($key) ? 0 : 1;
    $cache->set($key => "Boofy", $expire_time);

    return $retry;
}

1;

# HTTPD とかは頻繁に再起動するので、一回ぐらい落ちてても無視してほしい。

__END__

=head1 NAME

App::MadEye::Rule::Retry - please retry...

=head1 SCHEMA

    type: map
    mapping:
        expire_time:
            type: int
            required: yes
        cache_root:
            type: str
            required: yes

=head1 SEE ALSO

L<App::MadEye>, L<Cache::FileCache>


