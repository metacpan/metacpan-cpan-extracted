package Ark::Plugin::I18N;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use Ark::Plugin;

use I18N::LangTags ();
use I18N::LangTags::Detect;

require Locale::Maketext::Simple;

sub BUILD {
    my $self  = shift;
    my $stash = $self->class_stash;

    return if $stash->{setup_finished};

    my $class = ref($self->app);
    (my $module_path = $class) =~ s!::!/!g;

    my $path  = $self->path_to('lib', $module_path, 'I18N');

    eval <<"";
        package $class;
        Locale::Maketext::Simple->import(
            Class  => '$class',
            Path   => '$path',
            Export => '_loc',
            Decode => 1
        );

    if ($@) {
        $self->log( error => qq/Couldn't initialize i18n "$class\::I18N", "$@"/ );
    }
    else {
        $self->log( debug => qq/Initialized i18n "$class\::I18N"/);
    }

    $stash->{setup_finished}++;
}

sub languages {
    my ($self, $languages) = @_;

    if ($languages) {
        $self->{languages} = ref($languages) eq 'ARRAY' ? $languages : [$languages];
    }
    else {
        $self->{languages} ||= [
            I18N::LangTags::implicate_supers(
                I18N::LangTags::Detect->http_accept_langs(
                    $self->request->header('Accept-Language'),
                ),
            ),
            'i-default',
        ];
    }

    if (my $mt = $self->app->can('_loc_lang')) {
        $mt->(@{ $self->{languages} });
    }
    $self->{languages};
}

sub language {
    my $self  = shift;
    my $class = ref($self->app);

    "${class}::I18N"->get_handle(@{ $self->languages })->language_tag;
}

{
    no warnings 'once';
    *loc = \&localize;
}

sub localize {
    my $self = shift;
    $self->languages;

    my $loc = $self->app->can('_loc') or return;
    if (ref $_[1] eq 'ARRAY') {
        return $loc->( $_[0], @{ $_[1] } );
    }
    else {
        return $loc->(@_);
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Ark::Plugin::I18N - Ark plugin for I18N

=head1 SYNOPSIS

    use Ark::Plugin::I18N;

=head1 DESCRIPTION

Ark::Plugin::I18N is Ark plugin for I18N.

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

Songmu E<lt>y.songmu@gmail.comE<gt>
