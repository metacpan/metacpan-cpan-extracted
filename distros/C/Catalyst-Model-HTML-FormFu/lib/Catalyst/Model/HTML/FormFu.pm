# $Id: /mirror/perl/Catalyst-Model-HTML-FormFu/trunk/lib/Catalyst/Model/HTML/FormFu.pm 36884 2007-12-25T06:25:05.268411Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>

package Catalyst::Model::HTML::FormFu;
use strict;
use warnings;
use base qw(Catalyst::Model);
our $VERSION = '1.00001';
use Class::C3;
use Config::Any;
use Data::Visitor::Callback;
use HTML::FormFu;

BEGIN
{
    Class::C3::initialize();
}

__PACKAGE__->mk_accessors($_) for qw(context visitor config_dir constructor_args cache_backend stash_key _cache);

sub ACCEPT_CONTEXT
{
    my $self = shift;
    $self->context($_[0]);
    return $self;
}

sub load_form
{
    my $self   = shift;
    my $c      = eval { $_[0]->isa('Catalyst') } ? shift : $self->context;
    my $config = shift;

    my $method = 
        (eval { $config->isa('Path::Class::File') } || ! ref $config) ?
            '_load_from_file' :
            '_load_from_hash'
    ;
    my $form =  $self->$method($c, $config);

    # Actuall process the form
    $form->process( $c->request );
    if (my $key = $self->stash_key) {
        $c->stash->{$key} = $form;
    }
    return $form;
}

sub cache
{
    my ($self, $c) = @_;

    my $cache = $self->_cache;
    if (! $cache) {
        my $backend = $self->cache_backend;
        if ($c->can('cache') && $backend) {
            $cache = $c->cache( $backend );
            $self->_cache($cache);
        }
    }
    return $cache;
}

sub _load_from_file
{
    my ($self, $c, $file) = @_;

    if (! ref $file) {
        $file = Path::Class::File->new($file);
    }

    if (! $file->is_absolute) {
        # if this exists in the config...
        my $dir = $self->config_dir;
        $file = $dir ?
            Path::Class::Dir->new($dir)->file($file) :
            $c->path_to(qw(root formfu), $file)
        ;
    }

    # finally
    $file = $file->stringify;
    my $mtime = (stat($file))[9];

    my $cached_data;
    my $cache = $self->cache($c);
    if ($cache) {
        $cached_data = $cache->get($file);
        # If the cached data is older than the file, reload
        if ($cached_data) {
            if ($cached_data->{mtime} < $mtime) {
                $c->log->debug("HTML::FormFu config file $file has been modified since last load time. Throwing away cache and reloading") if $c->log->is_debug;
                undef $cached_data;
            } else {
                # No changes, return the cached form
                return $cached_data->{form};
            }
        }
    }

    my $loaded = Config::Any->load_files({ files => [$file], use_ext => 1 });
    my $config = $loaded->[0]->{$file} ||
        Catalyst::Exception->throw("Could not load form $file");
    $config    = $self->_filter_dynamic_values($c, $config);
    my $form      = $self->_construct_formfu($c, $config);
    $cache->set($file, { form => $form, mtime => $mtime }) if $cache;
    return $form;
}

sub _load_from_hash
{
    my ($self, $c, $config) = @_;

    my $form;
    my $cache = $self->_cache($c);
    my $key;
    if ($cache) {
        $key = do {
            require Data::Dumper;
            require Digest::MD5;
            local $Data::Dumper::Indent   = 1;
            local $Data::Dumper::Sortkeys = 1;
            local $Data::Dumper::Terse    = 1;

            Digest::MD5::md5_hex( Data::Dumper::Dumper($config) );
        };
        $form = $cache->get($key);
    }

    if (! $form) {
        $config = $self->_filter_dynamic_values($c, $config);
        $form   = $self->_construct_formfu($c, $config);

        $cache->set($key, $form) if $cache;
    }

    return $form;
}

sub _construct_formfu
{
    my ($self, $c, $config) = @_;

    my $constructor_args = $self->constructor_args || {};
    $constructor_args->{query_type} = 'Catalyst';
    $constructor_args->{tt_args} ||= {};
    $constructor_args->{tt_args}->{INCLUDE_PATH} ||= $c->path_to('root', 'formfu')->stringify;

    my $form = HTML::FormFu->new($constructor_args);
    $form->populate($config);

    return $form;
}

sub _filter_dynamic_values
{
    my ($self, $c, $config) = @_;

    my $visitor = $self->visitor;
    if (! $visitor) {
        $visitor = Data::Visitor::Callback->new(
            plain_value => sub {
                my ($visitor, $value) = @_;
                if ($value !~ /^__dynamic\(([^\)]+)\)__$/) {
                    return $value;
                }

                my $method = $1;
                return $self->$method($self->context);
            }
        );
        $self->visitor($visitor);
    }

    return $visitor->visit($config);
}

1;

__END__

=head1 NAME

Catalyst::Model::HTML::FormFu - FormFu In Your Model (Deprecated)

=head1 SYNOPSIS

  # Install formfu elements
  # (See perldoc Catalyst::Helper::Model::HTML::FormFu)
  ./script/myapp_create.pl model YourModelName FormFu [dirname]

  # In your app
  MyApp->config(
    'Model::HTML::FormFu' => {
      cache_backend   => 'formfu', # optional
      config_dir      => '/path/to/basedir/', # optional
      contructor_args => { ... },  # optional
      stash_key       => 'form',   # optional
    }
  );

  # in your controller
  sub foo : Local
  {
     my ($self, $c) = @_;
     $c->model('FormFu')->load_form('path/to/file.yml');
  }

=head1 DESCRIPTION

  *** WARNING ***
  This module has been deprecated.
  Please consider using Catalyst::Controller::HTML::FormFu instead.
  ***************

Catalyst::Model::HTML::FormFu allows you to use HTML::FormFu from your Catalyst
model, fully with caching and support for inserting dynamic values.

=head1 STASH KEY

When a form is loaded via load_form(), you can automatically tell 
Catalyst::Model::HTML::FormFu to populate a stash key, so you can immediately
use it in your template.

Just specify the stash_key config parameter:

  MyApp->config(
    'Model::HTML::FormFu' => {
       stash_key => 'form'
    }
  );

In your controller, just load the form:

  sub foo : Local {
    my($self, $c) = @_;
    my $form = $c->model('FormFu')->load_form('path/to/form.yml');
    if ($form->submitted_and_valid) {
       ...
    }
  }

Then you can simply say in your template:

  [% form %]

=head1 DYNAMIC VALUES

If you use the following construct anywhere in your config, the values
will be replaced by dyamic values:

  - type: text
    value: __dynamic(method_name)__

The value will be replaced by the return value from calling $model->method_name($c)

For example, if you want to pull out values from the database and put them
in a select field:

  # config
  - type: select
    options: __dynamic(select_from_db)__

  # MyApp::Model::HTML::FormFu
  sub select_from_db {
    my ($self, $c) = @_;
    my @values = $c->model('DBIC')->resultset('SelectValues')->all;
    # munge @values so that it conforms to HTML::FormFu's spec
    ....

    return \@values;
  }

=head1 CONFIG DIR

You can configure which directory the model looks for config files.
simply specify the 'config_dir' key in your config

  MyApp->config(
    'Model::HTML::FormFu' => {
      config_dir => '/path/to/basedir'
    }
  )

If unspecified, it will look under $c->path_to('root')

=head1 CACHE

FormFu objects will be used many times through the life cycle of your
Catalyst application and since forms don't change, caching an already
constructed form will make your forms much faster.

Caching is done through Catalyst::Plugin::Cache. Setup one, and 
Catalyst::Model::HTML::FormFu will use default cache backend. If you create
multiple cache backends and want to use a particular one of those, specify
it in the config:

  MyApp->config(
    'Model::HTML::FormFu' => {
      cache_backend => 'formfu'
    }
  )
  
=head1 METHODS

=head2 load_form($config)

Loads HTML::FormFu from config. $config can either be the path to the
config file, or a hash that contains the config.

=head2 cache($c)

Loads the appropriate cache object. This defaults to the cache object
setup by Catalyst::Plugin::Cache, with the name specified in 
MyApp->config->{Model::HTML::FormFu}->{cache_backend}

=head2 ACCEPT_CONTEXT

=head1 AUTHOR

2007 Copyright (c) Daisuke Maki C<daisuke@endeworks.jp>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut