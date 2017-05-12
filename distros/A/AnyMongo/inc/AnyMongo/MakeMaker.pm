package inc::AnyMongo::MakeMaker;
use Moose;
extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';
override _build_WriteMakefile_args => sub { +{
        %{ super() },
        OBJECT  => q/$(O_FILES)/,
} };

__PACKAGE__->meta->make_immutable;

1;