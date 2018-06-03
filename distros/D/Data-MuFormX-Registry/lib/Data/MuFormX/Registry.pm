package Data::MuFormX::Registry;

use Module::Pluggable::Object;
use Moo;

our $VERSION = '0.001';

sub config { return %{+{}} }

has 'config' => (
  is=>'ro',
  required=>0,
  predicate=>'has_init_arg_config',
  reader=>'init_arg_config');

has 'form_namespace' => (
  is=>'ro',
  required=>1,
  lazy=>1, 
  builder=>'_build_form_namespace');

  sub _default_form_namespace_part { 'Form' }

  sub _build_form_namespace {
    my $package = ref($_[0]);
    my @parts = split('::', $package);
    my @prefix = (@parts[0..($#parts-1)]);
    my $form_namespace = join('::',
      @prefix,
      $_[0]->_default_form_namespace_part);
    return $form_namespace;
  }

has 'form_packages' => (
  is=>'ro',
  required=>1,
  lazy=>1,
  builder=>'_build_form_packages');
  
  sub _build_form_packages {
    my $self = shift;
    my @search = ref($self->form_namespace) ?
      @{$self->form_namespace} :
        ($self->form_namespace);

    my %packages = ();
    foreach my $search(@search, 'Data::MuForm::CommonForms') {
      my @packages = Module::Pluggable::Object->new(
        require => 1,
        search_path => $search,
      )->plugins;
      $packages{$search} = \@packages;
    }
    return \%packages;
  }

sub normalized_config {
  my $self = shift;
  my %normalized_config = $self->config;
  if($self->has_init_arg_config) {
    %normalized_config = (%normalized_config, %{$self->init_arg_config});
  }
  return %normalized_config;
}

has 'forms_by_ns' => (
  is=>'ro',
  required=>1,
  lazy=>1,
  builder=>'_build_forms_by_ns');

  sub _build_forms_by_ns {
    my $self = shift;
    my %normalized_config = $self->normalized_config;
    my %form_packages = %{$self->form_packages};
    my %names = ();

    foreach my $ns (keys %form_packages) {
      foreach my $package (@{$form_packages{$ns}}) {
        my ($name) = ($package=~/^$ns\:\:(.+)$/);
        my $config = ($normalized_config{$name}||+{});
        $names{$name} = +{
          package => $package,
          config => $config,
          form => $package->new(
            $self->expand_config($config)),
        };
      }
    }
    return \%names;
  }

sub form_names { return keys %{$_[0]->forms_by_ns} }

sub create {
  my ($self, $ns, @proto) = @_;
  my %info = %{ $self->forms_by_ns->{$ns} || die "No component called '$ns'" };

  if(@proto) {
    my %args = ref($proto[0]) ? %{$proto[0]} : @proto; # allow both hash and hashref
    my %config = $self->expand_config($info{config});
    my $package = $info{package};
    return $package->new(%config, %args);

  } else {
    return $info{form} ;
  }
}

sub expand_config {
  my ($self, $config_proto) = @_;
  return unless $config_proto;
  if(ref($config_proto) eq 'CODE') {
    my $config = $config_proto->($self);
    return %{$config};
  } elsif(ref($config_proto) eq 'HASH') {
    return %{$config_proto};
  } else {
    die "Not sure how to resolve $config_proto";
  }
}

sub process_form_args {
  my ($self, $package, %args) = @_;
  return %args;
}

1;

=head1 NAME

Data::MuFormX::Registry - Registry of Form classes

=head1 SYNOPSIS

Given some L<Data::MuForms> in a common namespace:

    package MyApp::Form::Login;

    use Moo;
    use Data::MuForm::Meta;

    extends 'Data::MuForm';

    has_field 'username' => (
      type => 'Text',
      required => 1 );

    package MyApp::Form::Email;

    use Moo;
    use Data::MuForm::Meta;

    extends 'Data::MuForm';

    has_field 'username' => (
      type => 'Text',
      required => 1 );

Create a 'registry' object that will load a prepare all the forms:

    my $registry = Data::MuFormX::Registry->new(form_namespace=>'MyApp::Form');
    my $login = $registry->create('Login'); # $login ISA MyApp::Form::Login

You may also subclass for hardcoded defaults

    package MyApp::MyRegistry;

    use Moo;
    extends 'Data::MuFormX::Registry';

    1;

    # 'form_namespace defaults to 'MyApp::Form'
    my $registry = MyApp::MyRegistry->new;

=head1 DESCRIPTION

B<NOTE> Early access; the docs do not describe all existing features (read
the source :) ) and I reserve the right to break stuff if that's the only way
to fix deep problems.  On the other hand there's not a ton of stuff here so
its probably ok...

This is a wrapper on top of L<Module::Pluggable::Object> to make it easier
to load up and create a namespace of L<Data::MuForm> based form validation
classes.  At its heart it makes it so you don't have to say 'use Form;' for
every form you need in a package.  It also adds a way to centralize some
form initialization work.  This may or may not recommend itself to you.  I
think it makes it easier to reuse forms in different packages (for example in
different L<Mojolicous> controllers).  On the other hand it injects a proxy
layer such that '$registry->create("Login")' is not 100% transparent in that
you are getting an instance of 'MyApp::Form::Login'.  You may consider this
a type of action at a distance that makes your code harder to maintain.

If you have a lot of L<Data::MuForm> based form validation classes you may find
it more useful.  I also believe it helps you follow the 'code against an interface
not an class' best practice.  As you wish ;)

=head1 METHOD

This class exposes the follow methods for intended public use.

=head2 new

Create a new registry object.  You can set the following initial arguments:

=over 4

=item form_namespace

Either a scalar or array ref of the base namespaces used to find forms.

=item config

configuration values used when creating form objects.

=back

=head2 create

Create a new form.  Requires a form name.  May accept a hash of additional initialization
values (which are merged with any global configuration.  Examples:

    my $transaction = $registry->create('Transaction');
    my $login = $registry->create('Login', user_rs=>$users);

If you do not need to pass any extra arguments we  reuse a pre-initialized copy of
the form rather than build a new one as a performance enhancement.

=head2 form_names

Returns an array of the form names, which can be used in L</create>.  Do not
rely on return order!

=head2 config

Global configuration information for all forms.

Intended to be overridden in a subclass to provide form defaults.  For example:

    package MyRegistry;

    use Moo;
    extends 'Data::MuFormX::Registry';

    sub config {
      'Login' => + {
        min_username_length => 11,
      },
      'NewNodes' => sub {
        my ($self) = @_;
        return +{
          example1 => 1,
          example2 => 1,
        };
      },
    }

This method should return a hash where the key is the form name and the value is
either a hashref used as part of the instantiation of the form or a coderef which
recieves the registry instance and should return a hashref.  The second form is
useful in cases where you have a form that itself has other forms as subforms or
when you custom subclass contains additional information of value to the form (such
as a database connection).

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Data::MuForm>, L<Module::Pluggable::Object>

=head1 COPYRIGHT & LICENSE
 
Copyright 2018, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
