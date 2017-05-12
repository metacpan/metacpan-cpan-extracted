package Catalyst::TraitFor::Controller::LocaleSelect;
use MooseX::MethodAttributes::Role;
use namespace::autoclean;

=head1 NAME

Catalyst::TraitFor::Controller::LocaleSelect - Provides locale selection mechanism for controllers

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

before 'auto' => sub {
    my ( $self, $c ) = @_;

    my $config = $self->_build_language_config($c);

    my $allowed = { map { $_ => 1 } @{ $config->{allowed} } };
    $config->{selected} = $self->_lang_for_request($c, $allowed) 
                       || $self->_lang_for_set($c, $allowed)
                       || $self->_lang_from_cookie($c, $allowed)
                       || $self->_lang_from_agent($c, $allowed)
                       || $config->{default};

    $c->languages( [ $config->{selected} ] );
    $c->stash( locale => $config );
};

sub _lang_for_request {
    my ( $self, $c, $allowed ) = @_;

    my $language = delete $c->req->params->{'locale'};
    if ( $language && exists $allowed->{ $language } ) {   
        return $language;
    }
    return 0;
}

sub _lang_for_set {
    my ( $self, $c, $allowed ) = @_;

    my $language = delete $c->req->params->{'set_locale'};
    if ( $language && exists $allowed->{ $language } ) {   
        $c->res->cookies->{'locale'} = {
            value   => $language,
            expires => '+5y'
        };
        return $language;
    }
    return 0;
}

sub _lang_from_cookie {
    my ( $self, $c, $allowed ) = @_;

    my $language = $c->req->cookie('locale');
    if ( $language && exists $allowed->{ $language->value } ) {   
        return $language->value;
    }
    return 0;
}

sub _lang_from_agent {
    my ( $self, $c, $allowed ) = @_;

    my @langs = grep { exists $allowed->{$_} } @{ $c->languages };
    if (@langs) {
        return $langs[0];
    }
    return 0;
}

sub _build_language_config {
    my ( $self, $c ) = @_;

    # Build defaults
    my $config = $c->config->{LocaleSelect} || {};
    unless ( exists $config->{allowed} && ref $config->{allowed} ) {
        if ( $config->{allowed} ) {
            $config->{allowed} = [ $config->{allowed} ];
        }
        else {
            $config->{allowed} = ['en'];
            $config->{default} = 'en';
        }
    }
    $config->{default} = $config->{allowed}[0]
        unless $config->{default};

    return $config;
}

=head2 auto

This will run before your auto action, so the locale info is available even if you need it on your auto action.

=cut

sub auto : Private { 1 }

=head1 SYNOPSIS

On your app class

    use Catalyst qw/
        ...    
        I18N        # or Data::Localize
        ...
    /;

    __PACKAGE__->config(
        LocaleSelect => {
            allowed => [ qw/ en es / ],
            default => 'en'
        }
    );

In your controller ( Apply to root controller to be application wide )

    package MyApp::Controller::Root;
    use Moose;
    use namespace::autoclean;

    BEGIN { extends 'Catalyst::Controller' }
    with 'Catalyst::TraitFor::Controller::LocaleSelect';
    
    # ...
    
    1;

=head1 DESCRIPTION

This controller role will provide locale selection capabilities to your controllers. 
You can apply it to the root controller to have it working application wide. 

Once in use, the controller have auto locale selection among your configured allowed locales. When  no one reported by the user agent are allowed, the default will be in use.

This role will give to all actions on the controller two more capabilities:
    
=over 4

=item * 

One time locale selection if exists param('locale') and have an allowed value.

=item 

* Cookie based locale lock-in selection using param('set_locale').

=back

It will also populate the locale key on the stash for later extra use:

    $c->stash( locale => {
        allowed  => [ 'en', 'es' ],
        default  => 'en',
        selected => 'es'             # the one selected for the request
    });

=head1 LOCALE SELECTION PRIORITY

=over 4

=item 1.

If locale parameter exists, this will be selected. 

=item 2. 

If set_locale parameter exists, it will be used an cookie stored for later use.

=item 3.

If cookie exists...

=item 4. 

If any of the browser supported locales exists...

=item 5.

The default one.

=back

=head1 AUTHOR

Diego Kuperman, C<< <diego at freekeylabs.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-traitfor-controller-localeselect at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-TraitFor-Controller-LocaleSelect>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::TraitFor::Controller::LocaleSelect

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-TraitFor-Controller-LocaleSelect>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-TraitFor-Controller-LocaleSelect>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-TraitFor-Controller-LocaleSelect>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-TraitFor-Controller-LocaleSelect/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010 Diego Kuperman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Catalyst::TraitFor::Controller::LocaleSelect
