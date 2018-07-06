package Form::KLS;

use Moo;
use Data::MuForm::Meta;
extends 'Data::MuForm';

#use StarterView::Util::Text qw(looks_like_number);

#with 'StarterView::Form::Role::RenderHiddenFields';

=head1 NAME

StarterView::Form::Jobs::KeywordLocationSearch

=head1 SYNOPSIS

  Job seeker search form with keyword (job title) and location fields. This form
  also supports sticky search filters when paired with
  L<StarterView::Form::Jobs::SearchFilter>.

=cut

has '+http_method' => (
  default => 'get',
);

has '+action' => (
  default => '/candidate/search',
);

has '+is_html5'  => (
  default => 1
);

has '+name' => (
  default => 'job_search_form'
);

#has '+field_traits' => (
#  default => sub { ['StarterView::Form::Role::AddFormNameToFieldId'] }
#);

=head1 FIELDS

=head2 job_search_id

  The (encrypted) id of the search for searches that have been saved.

=cut

has_field 'job_search_id' => (
  type => 'Hidden',
# do_wrapper => 0,
);

=head2 search

  Job title or keyword text field. Either this field or the location
  field is required.

=cut

has_field 'search' => (
  type => 'Text',
  label => 'Job title or keyword',
);

=head2 location

  Location text field. Either this field or the search field is required.

=cut

has_field 'location' => (
  type => 'Text',
# build_label_method => \&build_location_label,
  methods => { build_label => *build_location_label },
);
sub build_location_label {
  my $self = shift; # field method
# my $loc = ZR::I18N::Localizer->new( { domain => 'jobs/search' } );
# return $loc->localize('City, state or zip');
  return 'City, state or zip';
}

=head2 radius

  This field makes the current search radius filter sticky.

  This field is inactive by default, and can be activated by including the field
  name in the list of C<active> fields passed to C<process>.

=cut

has_field 'radius' => (
  type => 'Hidden',
  inactive => 1,
);

=head2 days

  This field makes the current search posted date filter sticky.

=cut

has_field 'days' => (
  type => 'Hidden',
);

=head2 submit

  Search submit button.

=cut

has_field 'submit' => (
  type => 'Submit',
  value => 'Search Jobs',
);

=head1 RENDERING

=head2 build_render_list

  This function builds the list of fields that should be rendered in the form.
  For the search form these are the two visible fields, the submit button and
  any (sticky) hidden fields that have a value.

  The list of hidden fields with a value is obtained through the
  L<StarterView::Form::Role::RenderHiddenFields> role.

=cut

sub build_render_list {
  my ( $self ) = @_;

  # Always render the visible parts of the form.
  my $visible = ['search', 'location', 'submit'];

  # Render only those hidden fields with values
  my @hidden = $self->hidden_fields_with_a_value;

  return [ @hidden, @$visible ];
}

=head1 VALIDATION

=head2 validate

  Form level validation. This form requires at least the search field or the
  location field.

=cut

sub validate {
  my ( $self ) = @_;
  unless ($self->field('search')->value || $self->field('location')->value) {
    $self->add_form_error('A job title, keyword or location is required');
  }
}

=head2 validate_radius

  Radius filter field validation. The radius filter value must be a positive
  numeric value.

=cut

sub validate_radius {
  my ( $self, $field ) = @_;
  my $value = $field->value;
  $field->add_error('Invalid radius') unless looks_like_number($value) && ($value > 0);
}

sub looks_like_number {
  my $str = shift // return 0;
  return 0 unless Scalar::Util::looks_like_number($str);  # check if numeric
  return 0 if ($str =~ /[^\d\.\-\+]/);                    # eliminate Inf/-Inf
  return 1;                                               # looks good!
}

=head2 validate_days

  Post date filter field validation. The post date filter value must be a
  positive integer value.

=cut

sub validate_days {
  my ( $self, $field ) = @_;
  my $value = $field->value;
  $field->add_error('Invalid days since posted') unless $value =~ /^[1-9][0-9]*$/;
}

sub hidden_fields_with_a_value {
  my ( $self ) = @_;
  my @fields = grep {;
    ($_->type eq 'Hidden') && $_->value;
  } $self->sorted_fields;
  return @fields;
}

sub render_hidden_fields {
  my ( $self ) = @_;
  my @inputs = map {;
    $_->render;
  } $self->hidden_fields_with_a_value;
  return join('', @inputs);
} 

__PACKAGE__->meta->make_immutable;

1;
