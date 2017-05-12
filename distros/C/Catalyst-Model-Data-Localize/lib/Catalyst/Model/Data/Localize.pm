package Catalyst::Model::Data::Localize;
use Moose;
use Data::Localize;

extends 'Catalyst::Model';
with 'Catalyst::Component::InstancePerContext';

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

no Moose;

our $VERSION = '0.00007';
our $AUTHORITY = 'cpan:DMAKI';

sub build_per_context_instance {
    my ($self, $c) = @_;

    my $localize = $self->{localize};
    if (! $localize) {
        $self->__init_localizer($c);
        $localize = $self->{localize} ||
            die "Could not create a Data::Localize instance";
    }

    if (my $language = $self->{languages}) {
        $localize->set_languages(@$language);
    } else {
        # if we're being called at the beginning of the context, then
        # we won't have have access to $c->req...
        eval {
            my @langs = $localize->detect_languages_from_header(
                $c->req->header('Accept-Language')
            );

            $localize->set_languages(@langs);
        };
    }
    return $localize;
}

sub __init_localizer {
    my ($self, $c) = @_;
    my $config = $c->config->{'Model::Data::Localize'} || 
        $c->config->{'Model::Localize'} || 
        {}
    ;

    # by default, set "auto" to true
    if (! exists $config->{auto}) {
        $config->{auto} = 1;
    }

    my $localizers = $config->{localizers} ||= [];
    if (ref $localizers ne 'ARRAY') {
        $localizers = [ $localizers ];
        $config->{localizers} = $localizers;
    }

    if (scalar (@$localizers)  <= 0) {
        # attempt to auto-detect common paths
        my $modpath = ref $c || $c;
        $modpath =~ s/::/\//g;
        $modpath .= '.pm';
        my $path = $INC{ $modpath };

        $path =~ s/\.pm$//;

        # find in MyApp::I18N, and possibly (for those of us using a setup
        # like MyApp::Catalyst or MyApp::Web), one level above
        my @paths = # map { File::Spec->canonpath($_) } (
(
            File::Spec->catdir($path, 'I18N'),
            File::Spec->catdir($path, File::Spec->updir(), 'I18N'),
        );
        foreach my $curpath (@paths) {
            my $gettext = File::Spec->catfile($curpath, '*.po');
            $c->log->debug("Looking for gettext-based localization files under\n\t$gettext") if $c->log->is_debug;
            if (defined glob($gettext)) {
                push @{ $localizers }, {
                    class => 'Gettext',
                    paths => [ $gettext ]
                }
            }

            my $namespace = File::Spec->catfile($path, '*.pm');
            $c->log->debug("Looking for namespace-based localization files under\n\t$namespace") if $c->log->is_debug;
            if (defined glob($namespace)) {
                push @{ $localizers }, {
                    class => 'Namespace',
                    namespaces => [ join('::', ref($c) || $c, 'I18N' ) ]
                }
            }
        }
    }

    if ($config->{languages}) {
        if (ref $config->{languages} ne 'ARRAY') {
            $config->{languages} = [ $config->{languages} ];
        }
    }
    $self->{localize} = Data::Localize->new(%$config);
    $self->{languages} = $config->{languages};
}

1;

__END__

=head1 NAME

Catalyst::Model::Data::Localize - Catalyst Model Over Data::Localize

=head1 SYNOPSIS

    $c->model('Data::Localize') # or Localize. whatever
      ->localize($key, @args);

=head1 DESCRIPTION

WARNING: Data::Localize, which this module is based on, is still in alpha
quality. This module should also be treated as such.

This is a thin wrapper around Data::Localize. The only thing it does that
a plain Catalyst::Model::Adaptor + Data::Localize can do is the automatic
discovery of I18N files (if they are placed under likely locations).

For example, these files will automatically be found:

    # suppose our Catalyst app is at  lib/MyApp.pm
    lib/MyApp/I18N/ja.pm
    lib/MyApp/I18N/ja.po

Also, for those like me that don't like to put a catalyst app at the project's
top namespace, we look for one level above, too:

    # suppose our Catalyst app is at  lib/MyApp/Web.pm
    lib/MyApp/I18N/ja.pm
    lib/MyApp/I18N/ja.po

The default behavior is to detect the language setting from the HTTP headers.
If you want to override it, simply place an explicit call somehwere in your
action chain:

    my $loc = $c->model('Data::Localize');
    $loc->set_languages('ja'); # or whatever you prefer
    $loc->localize($key, @args);

=head1 CONFIGURATION

Configuration can be done via the 'Model::Data::Localize' slot:

    <Model::Data::Localize>
        auto 1
        <localizers>
            class Gettext
            path  /path/to/gettext/files/*.po
        </localizers>
    </Model::Data::Localize>

If you want Catalyst::Plugin::I18N compatible style method generation on the
context object, look at Catalyst::Plugin::Data::Localize, which is just a 
really thin wrapper over this module.

C<languages> parameter is a bit special, as it overrides the default behavior
to detect the desired language from HTTP headers.

    # Always use ja
    <Model::Data::Localize>
        languages ja
    </Model::Data::Localize>

=head1 TODO

Tests. Yes, I know.

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut