package App::Ikaros::Config::Loader;
use strict;
use warnings;

sub new {
    my ($class, $options) = @_;

    $options->{config} ||= 'config/ikaros.yaml';
    unless (-f $options->{config}) {
        die "cannot find ikaros's config file : $options->{config}";
    }

    my $engine_name = $options->{config_type};
    ($engine_name) = $options->{config} =~ /\.(yaml)$/ unless $engine_name;

    unless ($engine_name =~ /(yaml|dsl)/) {
        die "unknown engine [$engine_name]";
    }
    my $engine = 'App/Ikaros/Config/Loader/Engine/' . uc($engine_name);
    require "$engine.pm";
    $engine =~ s|/|::|g;
    return bless {
        config => $options->{config},
        engine => $engine->new($options->{config_options})
    }, $class;
}

sub load {
    my ($self) = @_;
    return $self->{engine}->load($self->{config});
}

1;
