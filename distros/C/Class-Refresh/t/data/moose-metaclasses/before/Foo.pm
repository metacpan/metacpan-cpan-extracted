package Foo;
use Moose;

$::reloaded{foo}++;

Moose::Util::MetaRole::apply_metaroles(
    for             => __PACKAGE__,
    class_metaroles => { class => ['Foo::Meta::Class'] },
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;
