
###########################################################################
# Copyright (c) Nate Wiger http://nateware.com. All Rights Reserved.
# Please visit http://formbuilder.org for tutorials, support, and examples.
###########################################################################

package CGI::FormBuilder::Messages::locale;

use strict;
use utf8;

use CGI::FormBuilder::Messages::default;
use base 'CGI::FormBuilder::Messages::default';

our $VERSION = '3.20';

# Define messages for this language
__PACKAGE__->define_messages({
    lang                  => 'no_NO',
    charset               => 'utf-8',

    js_invalid_start      => '%s feil ble funnet i skjemaet:',
    js_invalid_end        => 'Vær vennlig å rette opp disse feltene og prøv igjen.',

    js_invalid_input      => '- Ulovlig innhold i "%s" feltet',
    js_invalid_select     => '- Gjør ett valg fra "%s" listen',
    js_invalid_multiple   => '- Gjør ett eller flere valg fra "%s" listen',
    js_invalid_checkbox   => '- Avmerk ett eller fler av "%s" valgene',
    js_invalid_radio      => '- Velg ett av "%s" valgene',
    js_invalid_password   => '- Ulovlig verdi i "%s" feltet',
    js_invalid_textarea   => '- Vennligst skriv noe i "%s" feltet',
    js_invalid_file       => '- Ulovlig filnavn i "%s" feltet',
    js_invalid_default    => '- Ulovlig innhold i "%s" feltet',

    js_noscript           => 'Vennligst tillat bruk av Javascript eller bruk en nyere webleser.',

    form_required_text    => 'Felt som er %smarkert%s er påkrevet.',

    form_invalid_text     => '%s feil ble funnet i skjemaet. '
                           . 'Vennligst rett opp feil i felter som er %smarkert%s under.',

    form_invalid_input    => 'Ulovlig innhold',
    form_invalid_hidden   => 'Ulovlig innhold',
    form_invalid_select   => 'Gjør ett valg fra listen',
    form_invalid_checkbox => 'Avmerk ett eller flere valg',
    form_invalid_radio    => 'Avmerk ett valg',
    form_invalid_password => 'Ulovlig verdi',
    form_invalid_textarea => 'Dette feltet må være utfylt',
    form_invalid_file     => 'Ulovlig filnavn',
    form_invalid_default  => 'Ulovlig innhold',

    form_grow_default     => 'Tillegg %s',
    form_select_default   => '-velg-',
    form_other_default    => 'Andre:',
    form_submit_default   => 'Send',
    form_reset_default    => 'Tømm',

    form_confirm_text     => 'Vellykket! Ditt skjema er mottatt %s.',

    mail_results_subject  => '%s Sendingsresultat',
    mail_confirm_subject  => '%s Sendingsbekreftelse',
    mail_confirm_text     => <<EOT,
Ditt skjema er mottatt %s,
og vil bli behandlet så snart som mulig..

Om du har spørsmål, ta kontakt med oss ved å svare på denne e-post.
EOT
});

1;
__END__

