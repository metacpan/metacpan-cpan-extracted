package maint::inc::PreloadPodWeaver;

use Moose;
extends 'Dist::Zilla::Plugin';

sub register_component {
	require Pod::Elemental::Transformer::TF_CAPI;
	require Pod::Elemental::Transformer::TF_Sig;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
