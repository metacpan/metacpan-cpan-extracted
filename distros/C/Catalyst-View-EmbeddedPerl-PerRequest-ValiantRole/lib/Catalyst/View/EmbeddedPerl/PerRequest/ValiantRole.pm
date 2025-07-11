package Catalyst::View::EmbeddedPerl::PerRequest::ValiantRole;

use Moose::Role;
use Valiant::HTML::Util::Form;
use Valiant::HTML::Util::Pager;

our $VERSION = '0.001007';
eval $VERSION;

# https://metacpan.org/pod/Valiant::HTML::Util::TagBuilder
my @TAG_BUILDER = qw( tags tag content_tag join_tags text link_to );

# https://metacpan.org/pod/Valiant::HTML::Util::FormTags
my @FORM_TAGS = qw( field_value field_id field_name button_tag checkbox_tag fieldset_tag
        legend_tag form_tag label_tag radio_button_tag option_tag text_area_tag 
        input_tag password_tag hidden_tag submit_tag select_tag options_for_select
        options_from_collection_for_select );

# https://metacpan.org/pod/Valiant::HTML::Util::Form
my @FORM = qw( form_for fields_for form_with fields );

# https://metacpan.org/pod/Valiant::HTML::Util::Pager
my @PAGER = qw( pager_for );

has _form_helpers => (
  is => 'ro',
  required => 1,
  lazy => 1,
  handles => [@TAG_BUILDER, @FORM_TAGS, @FORM],
  builder => '_build_form_helpers');

  sub _build_form_helpers {
    my $self = shift;
    return Valiant::HTML::Util::Form->new(
      view => $self,
      context => $self->ctx,
      controller => $self->ctx->controller);
  }

has _pager_helpers => (
  is => 'ro',
  required => 1,
  lazy => 1,
  handles => [@PAGER],
  builder => '_build_pager_helpers');

  sub _build_pager_helpers {
    my $self = shift;
    return Valiant::HTML::Util::Pager->new(
      view => $self,
      context => $self->ctx,
      controller => $self->ctx->controller);
  }


sub _generate_html_helpers {
  my $self = shift;
  return my @helpers = map {
    my $helper_name = $_;
    $helper_name => sub {
      my ($self, $c, @args) = @_;
      return $self->$helper_name(@args);
    };
  } (@TAG_BUILDER, @FORM_TAGS, @FORM, @PAGER);
}

around 'default_helpers' => sub {
  my ($orig, $self, @args) = @_;
  return (
    $self->$orig(@args),
    $self->_generate_html_helpers(),
  );
};

around 'modify_temple_args' => sub  {
  my ($orig, $self, @args) = @_;
  my %args = $self->$orig(@args);
  return ( %args, auto_escape => 1 );
};

1;

=head1 NAME

Catalyst::View::EmbeddedPerl::PerRequest::ValiantRole - Add Valiant Formbuilder methods

=head1 SYNOPSIS

Declare a view in your Catalyst application:

  package Example::View::Hello;

  use Moose;
  extends 'Catalyst::View::EmbeddedPerl::PerRequest';
  with 'Catalyst::View::EmbeddedPerl::PerRequest::ValiantRole';

  has 'name' => (is => 'ro', isa => 'Str');

  __PACKAGE__->config(prepend => 'use v5.40', content_type=>'text/html; charset=UTF-8');
  __PACKAGE__->meta->make_immutable;

  __DATA__
  %= form_for('person', sub ($self, $fb, $model) {
    %= $fb->input('name');
    %= $fb->input('age');
  % });

Produces the following output:

    <form accept-charset="UTF-8" enctype="application/x-www-form-urlencoded" method="post">
      <input id="person_name" name="person.name" type="text" value=""/>
      <input id="person_age" name="person.age" type="text" value=""/>
    </form>

=head1 DESCRIPTION

This is just a role that proxies methods from L<Valiant::HTML::Util::Form> into you
instance of L<Catalyst::View::EmbeddedPerl::PerRequest>.  These are used to create
HTML form elements.  All methods are also exposed as helpers directly into your
template.

Since L<Valiant::HTML::Util::Form> inherits from L<Valiant::HTML::Util::FormTags>,
which inherits from L<Valiant::HTML::Util::TagBuilder>, this adds quite a few methods
to your namespace:

From L<Valiant::HTML::Util::TagBuilder>

    tags tag content_tag join_tags text link_to

From L<Valiant::HTML::Util::FormTags>

    field_value field_id field_name button_tag checkbox_tag fieldset_tag
    legend_tag form_tag label_tag radio_button_tag option_tag text_area_tag 
    input_tag password_tag hidden_tag submit_tag select_tag options_for_select
    options_from_collection_for_select

From L<Valiant::HTML::Util::Form>

    form_for fields_for form_with fields

You will also have all the methods that are public for L<Catalyst::View::EmbeddedPerl::PerRequest>.

=head1 HTML ESCAPING

By default the view will escape all output to prevent cross site scripting attacks.
If you want to output raw HTML you can use the C<raw> helper.  For example:

  <%= raw $self->html %>

See L<Template::EmbeddedPerl::SafeString> for more information.

You can disable this feature by setting the C<auto_escape> option to false in the
view configuration.  For example if you are not using this to generate HTML output
you might not want it.

=head1 COOKBOOK

Ideas for using this module.

=head2 Creating a base view

Given you will need to make a lot of view classes (at least one class per template) you
might be well off to create a common base class:

    package Example::View::HTML;

    use Moose;

    extends 'Catalyst::View::EmbeddedPerl::PerRequest';
    with 'Catalyst::View::EmbeddedPerl::PerRequest::ValiantRole';

    __PACKAGE__->meta->make_immutable;
    __PACKAGE__->config(
      prepend => 'use v5.40', 
      content_type=>'text/html; charset=UTF-8'
    );

Used like this:

    package Example::View::Hello;

    use Moose;
    extends 'Example::View::HTML';

    has 'name' => (is => 'ro', isa => 'Str');

    __PACKAGE__->meta->make_immutable;
    __DATA__
    %= form_for('person', sub ($self, $fb, $model) {
        %= $fb->input('name');
        %= $fb->input('age');
    % });


=head1 SEE ALSO

Related reading

=over 4

=item * L<Catalyst>

The Catalyst web framework.

=item * L<Catalyst::View::BasePerRequest>

The base class for per-request views in Catalyst.

=item * L<Template::EmbeddedPerl>

Module used for processing embedded Perl templates.

=item * L<Catalyst::View::EmbeddedPerl>

The view for which this role applies

=back

=head1 AUTHOR

John Napiorkowski C<< <jjnapiork@cpan.org> >>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
