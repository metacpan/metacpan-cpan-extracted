use strict;
use warnings;
use Test::More;
use Data::MuForm::Test;

{
   package SignupForm;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has '+name' => ( default => 'user_create_form' );

    sub build_field_id {
       my ( $self, $field ) = @_;
       return $field->name . '_' . $self->id;
    }

=comment
elements:
  - type: Text
    name: name
    auto_id: "%n_%f"
    label: "Your Name"
    filters:
      - type: TrimEdges
      - type: +StarterView::FormFu::Filter::Normalize
    constraints:
      - Required
      - type: Regex
        regex: '\S'
        message: 'Please enter your name'
    container_attributes:
      class: type_text
    attributes:
      placeholder: "Your Name"
      class: type_text
=cut
    has_field 'name' => (
      type => 'Text',
      label => 'Your Name',
      required => 1,
      'msg.required' => 'Please enter your name',
      render_args => {
        wrapper_attr => { class => 'type_text' },
        element_attr => { placeholder => 'Your Name', class => 'type_text' },
      },
    );

=comment
  - type: Email
    name: email_address
    auto_id: "%n_%f"
    label: "Email"
    filters:
      - type: TrimEdges
      - type: +StarterView::FormFu::Filter::Normalize
    constraints:
      - Required
      - type: Callback
        message: 'Email address must be specified and not already signed up. <a href="/login">Click here to log in or recover your password.</a>'
      - Email
    container_attributes:
      class: type_text
    attributes:
      placeholder: "Your Email Address"
=cut
    has_field 'email_address' => (
      type => 'Email',
      label => 'Email',
      input_type => 'email',
      required => 1,
      render_args => {
        wrapper_attr => { class => 'type_text' },
        element_attr => { placeholder => 'Your Email Address' },
      },
    );

=comment
  - type: Block
    id: hint
    attributes:
      class: email_hint_text
=comment
  - type: Block
    load_config_file: user/password-field.yml

elements:
  - type: Password
    name: password
    id: password
    label: "Create Password"
    filters:
      - type: TrimEdges
    constraints:
      - Required
      - type: +StarterView::FormFu::Validator::PasswordStrength
      - type: MinLength
        min: 6
        message: "Must be at least 6 characters"
    validators:
      - type: +StarterView::FormFu::Validator::PasswordBlacklist
        message: 'Please choose a more secure password, as this password has been flagged as insecure.'
    attributes:
      class: required w95pPhone pt0Phone pb0Phone font13Phone lh15Phone mb6Phone type_text
      placeholder: "Create Password"
      minlength: 6
    container_attributes:
      class: type_text
    layout:
      - label
      - field
      - errors
      - comment
      - javascript

=cut

    has_field 'password' => (
        type => 'Password',
        label => 'Create Password',
        required => 1,
        minlength => 6,
        render_args => {
            wrapper_attr => { class => 'type_text' },
            element_attr => { class => 'required w95pPhone pt0Phone pb0Phone font13Phone lh15Phone mb6Phone type_text',
                              placeholder => 'Create Password' },
        },
    );

=comment
  - type: Tel
    name: phone_number
    auto_id: "%n_%f"
    label: "Phone Number"
    filters:
      - type: TrimEdges
      - type: +StarterView::FormFu::Filter::Normalize
    container_attributes:
      class: type_text
    constraints:
      - Required
      - type: Regex
        regex: '\d{3}.*\d{3}.*\d{4}'
        message: 'Please enter phone number with area code (eg. xxx-xxx-xxxx).'
    attributes:
      placeholder: "Your Phone Number"
=cut

    has_field 'phone_number' => (
      type => 'Text',
      label => 'Phone Number',
      required => 1,
      apply => [ { check => qr/\d{3}.*\d{3}.*\d{4}/, message => 'Please enter phone number with area code (eg. xxx-xxx-xxxx).' }],
    );

=comment
  - type: Select
    name: position
    auto_id: "%n_%f"
    label: "- Your Current Title -"
    load_config_file: common/options/org/positions.yml
  - type: Text
    name: org_name
    auto_id: "%n_%f"
    label: "Company Name"
    filters:
      - type: TrimEdges
      - type: +StarterView::FormFu::Filter::Normalize
    constraints:
      - Required
    attributes:
      placeholder: "Your Company Name"
    container_attributes:
      class: type_text
=cut

=comment
  - type: Text
    name: zipcode
    id: zipcode
    name: zipcode
    label_loc: common.form.business_zipcode.label
    filters:
      - type: TrimEdges
      - type: +StarterView::FormFu::Filter::Normalize
    constraints:
      - Required
    placeholder_loc: common.form.business_zipcode.placeholder
    attributes:
      maxlength: 11
    container_attributes:
      class: type_text
=cut

=comment
  - type: Text
    name: website
    auto_id: "%n_%f"
    label: "Company Website (optional)"
    filters:
      - type: TrimEdges
      - type: +StarterView::FormFu::Filter::Normalize
    attributes:
      placeholder: "Your Company Website"
    container_attributes:
      class: type_text
=cut

=comment
# Value populated via Jquery within app/view/user/common/create-form-base.html
  - type: Hidden
    name: org_type
    auto_id: "%n_%f"
=cut

=comment
  - type: Select
    name: org_ats
    auto_id: "%n_%f"
    label: "What ATS do you use?"
    # options below shouldn't matter as they are replaced by StarterView::Util::Text::ATS_list
    options:
      - ['', '- What ATS do you use? -']
      - ['adp', 'ADP']
      - ['greenhouse', 'Greenhouse']
      - ['icims', 'iCIMS']
      - ['jobvite', 'Jobvite']
      - ['kenexabrassring', 'Kenexa Brassring']
      - ['lever', 'Lever']
      - ['silkroad', 'Silkroad']
      - ['successfactors', 'SuccessFactors']
      - ['taleo', 'Taleo']
      - ['ultipro', 'Ultipro']
      - ['other', 'Other']
      - ['none', 'None']
    container_attributes:
      style: "display: none;"
=cut

=comment
  - type: Select
    name: org_hire_budget
    auto_id: "%n_%f"
    label: "What is your hiring budget?"
    # options:
      # - ['', '- What''s your monthly hiring budget? -']
      # - ['<500', 'Less than $500']
      # - ['500-2500', '$500 - $2,500']
      # - ['2501-5000', '$2,501 - $5,000']
      # - ['5000+', '$5,000+']
    container_attributes:
      style: "display: none;"
=cut

=comment
  - type: Select
    name: requested_plan
    auto_id: "%n_%f"
    label: 'Number of Jobs'
    load_config_file: common/options/org/plans.yml
=cut

=comment
  - type: Select
    name: source_type_user_reported
    id: source_type_user_reported
    attributes:
      class: source_type_user_reported
      data-where-field: source_type_user_reported_specific
    label: "How did you hear about us?"
=cut

=comment
  - type: Text
    name: source_type_user_reported_specific
    auto_id: "%n_%f"
    filters:
      - type: TrimEdges
      - type: +StarterView::FormFu::Filter::Normalize
    label: "Radio/TV station or mail offer code (optional)"
    attributes:
      class: source_type_user_reported_specific
    container_attributes:
      style: 'display:none;'
      class: type_text source_type_user_reported_specific_wrapper
=cut

=comment
  - type: Submit
    name: submitted
    auto_id: "%n_%f"
    value: "Continue"
    attributes:
      class: create_submit_button
=cut

=comment
  - type: Checkbox
    name: agrees_to_terms
    auto_id: "%n_%f"
    label_loc: common.tos.user.create_min_step2_number_jobs
    value: 1
    default: 0
    constraints:
      - Required
    container_attributes:
      style: 'display:none;'
    attributes:
      checked: checked
=cut

=comment
  - type: Block
    id: agrees_to_tcpa_terms_wrapper_bottom
    attributes:
      style: "padding-top: 20px;"
    elements:
    - type: Checkbox
      name: agrees_to_tcpa_terms
      auto_id: "%n_%f"
      value: 1
      default: 0
      label_xml: "<span class='tcpa-terms'>I agree to let ZipRecruiter contact me by phone at the number above <a href='javascript:void(0);' data-tooltip-placement='top' rel='tooltip' title='With your free trial, you can receive offers for ZipRecruiter services by phone or text at the number you provided when you signed up.  We might contact you using an automatic telephone dialing system or leave a prerecorded message if we can’t reach you.  We find that customers appreciate receiving these offers, though consent is not required as a condition of signing up for service or purchasing anything from ZipRecruiter.  You can also revoke consent at any time by e-mailing businessaffairs@ziprecruiter.com and including &quot;Revocation of Telephone Consent&quot; in the subject line.'></a></span>"
      attributes:
        checked: checked
      container_attributes:
        style: "margin-bottom: 0"
=cut

=comment
    - type: Block
      name: agrees_to_tcpa_terms_alert
      tag: div
      attributes:
        class: agrees_to_terms_alert info
      content_xml: "<div>By opting out of calls you may miss out on help optimizing your job ads, certain promotional offers, and/or other account management communications.</div>"
=cut

=comment
  - type: Block
    tag: div
    attributes:
      class: agrees_to_terms_wrapper
    elements:
    - type: Block
      id: 'terms_and_privacy'
      content_loc: common.tos.user.create_min_step2_number_jobs
=cut
}

my $form = SignupForm->new;
ok( $form );

# removed 'text label js-float-labels-wrapper' from div class.
my $expected = q{
<div class="type_text">
  <label for="name_user_create_form">Your Name</label>
  <input name="name" type="text" class="type_text" id="name_user_create_form" placeholder="Your Name" value="">
</div>
};
my $rendered = $form->field('name')->render;
is_html( $rendered, $expected, 'name field rendered ok' );

# removed 'email label js-float-labels-wrapper filled' from div class
$expected = q{
<div class="type_text">
  <label for="email_address_user_create_form">Email</label>
  <input name="email_address" type="email" id="email_address_user_create_form" placeholder="Your Email Address" value="">
</div>
};
$rendered = $form->field('email_address')->render;
is_html( $rendered, $expected, 'email_address field rendered ok' );

# password field
# removed 'password label js-float-labels-wrapper filled'
$expected = q{
<div class="type_text">
  <label for="password">Create Password</label>
  <input name="password" type="password" class="required w95pPhone pt0Phone pb0Phone font13Phone lh15Phone mb6Phone type_text" id="password" minlength="6" placeholder="Create Password">
</div>
};

done_testing;

