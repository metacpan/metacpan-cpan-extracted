
###########################################################################
# Copyright (c) Nate Wiger http://nateware.com. All Rights Reserved.
# Please visit http://formbuilder.org for tutorials, support, and examples.
###########################################################################

#
# This is an example of how to create a Messages module. If you 
# create one for a language that FormBuilder does not include, 
# please post it to the mailing list, so that it is included in
# future releases.
#
# To create one, simply replace __LANG__ with your language, for
# example, "uk_UA". Then, change all the values on the right side
# of the define_messages hash to the correct strings for your language.
#
# Save the file as __LANG__.pm, for example, "uk_UA.pm". You can
# then use this in FormBuilder as:
#
#   my $form = CGI::FormBuilder->new(messages => ':uk_UA');
#
# That's it!
#

package CGI::FormBuilder::Messages::locale;

use strict;
use utf8;

use CGI::FormBuilder::Messages::default;
use base 'CGI::FormBuilder::Messages::default';

our $VERSION = '3.10';

# Define messages for this language
__PACKAGE__->define_messages({
    lang                  => '__LANG__',
    charset               => 'utf-8',

    js_invalid_start      => '%s error(s) were encountered with your submission:',
    js_invalid_end        => 'Please correct these fields and try again.',

    js_invalid_input      => '- Invalid entry for the "%s" field',
    js_invalid_select     => '- Select an option from the "%s" list',
    js_invalid_multiple   => '- Select one or more options from the "%s" list',
    js_invalid_checkbox   => '- Check one or more of the "%s" options',
    js_invalid_radio      => '- Choose one of the "%s" options',
    js_invalid_password   => '- Invalid entry for the "%s" field',
    js_invalid_textarea   => '- Please fill in the "%s" field',
    js_invalid_file       => '- Invalid filename for the "%s" field',
    js_invalid_default    => '- Invalid entry for the "%s" field',

    js_noscript           => 'Please enable Javascript or use a newer browser.',

    form_required_text    => 'Fields that are %shighlighted%s are required.',

    form_invalid_text     => '%s error(s) were encountered with your submission. '
                           . 'Please correct the fields %shighlighted%s below.',

    form_invalid_input    => 'Invalid entry',
    form_invalid_hidden   => 'Invalid entry',
    form_invalid_select   => 'Select an option from this list',
    form_invalid_checkbox => 'Check one or more options',
    form_invalid_radio    => 'Choose an option',
    form_invalid_password => 'Invalid entry',
    form_invalid_textarea => 'Please fill this in',
    form_invalid_file     => 'Invalid filename',
    form_invalid_default  => 'Invalid entry',

    form_grow_default     => 'Additional %s',
    form_select_default   => '-select-',
    form_other_default    => 'Other:',
    form_submit_default   => 'Submit',
    form_reset_default    => 'Reset',
    
    form_confirm_text     => 'Success! Your submission has been received %s.',

    mail_confirm_subject  => '%s Submission Confirmation',
    mail_confirm_text     => <<EOT,
Your submission has been received %s,
and will be processed shortly.

If you have any questions, please contact our staff by replying
to this email.
EOT
    mail_results_subject  => '%s Submission Results',
});

1;
__END__

