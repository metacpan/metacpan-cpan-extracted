package Catalyst::Model::FormFu;
BEGIN {
  $Catalyst::Model::FormFu::VERSION = '0.004';
}

# ABSTRACT: Speedier interface to HTML::FormFu for Catalyst

use strict;
use warnings;
use HTML::FormFu;
use HTML::FormFu::Library;
use Scalar::Util qw(weaken);
use Moose;
use namespace::clean -except => 'meta';

extends 'Catalyst::Model';
with 'Catalyst::Component::InstancePerContext';

has model_stash             => ( is => 'ro', isa => 'HashRef' );
has constructor             => ( is => 'ro', isa => 'HashRef', default => sub { {} } );
has context_stash           => ( is => 'ro', isa => 'Str', default => 'context' );
has config_callback         => ( is => 'ro', isa => 'Bool', default => 1 );
has forms                   => ( is => 'ro', isa => 'HashRef' );
has cache                   => ( is => 'ro', isa => 'HashRef', builder => '_build_cache' );
has languages_from_context  => ( is => 'ro', isa => 'Bool', default => 0 );
has localize_from_context   => ( is => 'ro', isa => 'Bool', default => 0 );
has default_action_use_name => ( is => 'ro', isa => 'Bool', default => 0 );
has default_action_use_path => ( is => 'ro', isa => 'Bool', default => 0 );


sub _build_cache
{
    my $self = shift;

    my %cache;

    while ( my ($id, $config_file) = each %{$self->forms} )
    {
        my %args = ( query_type => 'Catalyst', %{$self->constructor} );
        my $form = HTML::FormFu->new(\%args);
        $form->load_config_file($config_file);
        $cache{$id} = $form;
    }

    return \%cache;
}

sub build_per_context_instance {

    my ($self, $c) = @_;

    my %args;

    # cache and query
    $args{cache} = $self->cache;
    $args{query} = $c->request;

    ### stash
    $args{stash}{$self->context_stash} = $c;
    weaken $args{stash}{$self->context_stash};
    $args{stash}{schema} = $c->model($self->model_stash->{schema}) if $self->model_stash;

    ### config_callback
    $args{config_callback}{plain_value} = sub
    {
        return unless defined $_;

        if ( /__uri_for\(/ )
        {
            s{__uri_for\((.+?)\)__}
             { $c->uri_for( split( '\s*,\s*', $1 ) ) }eg
         }

        if ( /__path_to\(/ )
        {
            s{__path_to\(\s*(.+?)\s*\)__}
             { $c->path_to( split( '\s*,\s*', $1 ) ) }eg
        }

        if ( /__config\(/ )
        {
            s{__config\((.+?)\)__}
             { $c->config->{$1}  }eg
        }
    } if $self->config_callback;

    ### action
    if ($self->default_action_use_name)
    {
        $args{action} = $c->uri_for($c->{action}->name);

        $c->log->debug("FormFu - Setting default action by name: $args{action}")
            if $c->debug;
    }
    elsif ($self->default_action_use_path)
    {
        $args{action} = $c->request->base . $c->request->path;

        $c->log->debug("FormFu - Setting default action by path: $args{action}")
            if $c->debug;
    }

    ### languages
    $args{languages} = $c->languages if $self->languages_from_context;

    ### localize_object
    $args{add_localize_object} = $c if $self->localize_from_context;

    return HTML::FormFu::Library->new(%args);
}

__PACKAGE__->meta->make_immutable;


__END__
=pod

=for :stopwords Peter Shangov precompiled BackPAN Daisuke Maki FormFu FormFu's

=head1 NAME

Catalyst::Model::FormFu - Speedier interface to HTML::FormFu for Catalyst

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    package MyApp
    {

        use parent 'Catalyst';

        __PACKAGE__->config( 'Model::FormFu' => {
            model_stash => { schema => 'MySchema' },
            constructor => { config_file_path => 'myapp/root/forms' },
            forms => {
                form1 => 'form1.yaml',
                form2 => 'form2.yaml',
            ]
        } );

    }

    package MyApp::Controller::WithForms
    {
        use parent 'Catalyst::Controller';

        sub edit :Local
        {
            my ($self, $c, @args) = @_;

            my $form1 = $c->model('FormFu')->form('form1');

            if ($form1->submitted_and_valid)
            ...
        }

    }

    package MyApp::Model::FormFu
    {
        use parent 'Catalyst::Model::FormFu';
    }

=head1 DESCRIPTION

C<Catalyst::Model::FormFu> is an alternative interface for using L<HTML::FormFu> within L<Catalyst>. It differs from L<Catalyst::Controller::HTML::FormFu> in the following ways:

=over 4

=item *

It initializes all required form objects when your app is started, and returns clones of these objects in your actions. This avoids having to call L<HTML::FormFu/load_config_file> and L<HTML::FormFu/populate> every time you display a form, leading to performance improvements in persistent applications.

=item *

It does not inherit from L<Catalyst::Controller>, and so is safe to use with other modules that do so, in particular L<Catalyst::Controller::ActionRole>.

=back

Note that this is a completely different module from the original C<Catalyst::Model::FormFu> by L<Daisuke Maki|http://search.cpan.org/~dmaki/>, which is now only available on the BackPAN (L<http://backpan.perl.org/authors/id/D/DM/DMAKI/Catalyst-Model-FormFu-0.01001.tar.gz>).

=head1 CONFIGURATION OPTIONS

C<Catalyst::Model::FormFu> accepts the following configuration options

=over

=item forms

A hashref where keys are the names by which the forms will be accessed, and the values are the configuration files that will be loaded for the respective forms.

=item constructor

A hashref of options that will be passed to C<HTML::FormFu-E<gt>new(...)> for every form that is created.

=item model_stash

A hashref with a C<stash> key whose value is the name of a Catalyst model class that will be place in the form stash for use by L<HTML::FormFu::Model::DBIC>.

=item config_callback

If true (the default), a coderef is passed to C<< $form->config_callback->{plain_value} >>
which replaces any instance of C<__uri_for(URI)__> found in form config files
with the result of passing the C<URI> argument to L<Catalyst/uri_for>.

The form C<< __uri_for(URI, PATH, PARTS)__ >> is also supported, which is
equivalent to C<< $c->uri_for( 'URI', \@ARGS ) >>. At this time, there is no
way to pass query values equivalent to
C<< $c->uri_for( 'URI', \@ARGS, \%QUERY_VALUES ) >>.

The second codeword that is being replaced is C<__path_to( @DIRS )__>. Any
instance is replaced with the result of passing the C<DIRS> arguments to
L<Catalyst/path_to>.
Don't use quotation marks as they would become part of the path.

=item default_action_use_name

If set to a true value the action for the form will be set to the currently
called action name.

=item default_action_use_path

If set to a true value the action for the form will be set to the currently
called action path.

The action path includes concurrent to action name additional parameters which
were code inside the path.

Example:

    action: /foo/bar
    called uri contains: /foo/bar/1

    # default_action_use_name => 1 leads to:
    $form->action = /foo/bar

    # default_action_use_path => 1 leads to:
    $form->action = /foo/bar/1

=item context_stash

To allow your form validation packages, etc, access to the catalyst context,
a weakened reference of the context is copied into the form's stash.

    $form->stash->{context};

This setting allows you to change the key name used in the form stash.

Default value: C<context>

=item languages_from_context

If you're using a L10N / I18N plugin such as L<Catalyst::Plugin::I18N> which
provides a C<languages> method that returns a list of valid languages to use
for the current request - and you want to use FormFu's built-in I18N packages,
then setting L</languages_from_context>

=item localize_from_context

If you're using a L10N / I18N plugin such as L<Catalyst::Plugin::I18N> which
provides it's own C<localize> method, you can set L<localize_from_context> to
use that method for FormFu's localization.

=back

=head1 USAGE

Use the C<form> method of the model to fetch one or more forms by their names. The form is loaded with the current request parameters and processed.

=head1 SEE ALSO

=over 4

=item *

L<Catalyst::Controller::HTML::FormFu>

=item *

L<HTML::FormFu::Library>

=back

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Peter Shangov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

