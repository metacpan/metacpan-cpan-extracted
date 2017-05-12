package CatalystX::Features::Plugin::I18N;
$CatalystX::Features::Plugin::I18N::VERSION = '0.26';
use strict;
use warnings;
use parent 'Catalyst::Plugin::I18N';
use MRO::Compat;

sub setup {
    my $c = shift;

    $c->next::method(@_);

    my $appname = ref $c || $c;

    foreach my $feature ( $c->features->list ) {
        my $path = Path::Class::dir( $feature->lib, $appname, 'I18N' );

        my $pattern = File::Spec->catfile($path, '*.[pm]o');
        $pattern =~ s{\\}{/}g; # to counter win32 paths

        my $subclass = $Catalyst::Plugin::I18N::options{Subclass} || 'I18N' ;

        eval <<"";
            package $appname\::$subclass;
            Locale::Maketext::Lexicon->import({ '*' => [Gettext => '$pattern' ] });

        if ($@) {
            $c->log->error(qq/Couldn't initialize i18n "$appname\::I18N", "$@"/);
        }
        else {
            $c->log->debug(qq/Initialized i18n "$appname\::I18N"/) if $c->debug;
        }
    
    }
}

=head1 NAME

CatalystX::Features::Plugin::I18N - Makes C::P::I18N know about features

=head1 VERSION

version 0.26

=head1 DESCRIPTION

This plugin will search for a C<I18N> dir under C<MyApp> in your features directory, then add it to 
the localization lexicon. 

Duplicate entries are treated on a last come, first serve based. The last feature loaded will have precedence 
over the rest. 

=head1 AUTHORS

	Rodrigo de Oliveira (rodrigolive), C<rodrigolive@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
