
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

# Simply create a hash of messages for this language
__PACKAGE__->define_messages({
    lang                  => 'de_DE',
    charset               => 'utf-8',

    js_invalid_start      => 'Ihre Angaben enthalten %s Fehler:',
    js_invalid_end        => 'Bitte korrigieren Sie diese Felder und versuchen Sie es erneut.',

    js_invalid_input      => '- Sie müssen einen gültigen Wert für das Feld "%s" angeben',
    js_invalid_select     => '- Sie müssen eine Auswahl für "%s" vornehmen',
    js_invalid_multiple   => '- Sie müssen mindestens eine der Optionen für "%s" auswählen',
    js_invalid_checkbox   => '- Sie müssen eine Auswahl für "%s" vornehmen',
    js_invalid_radio      => '- Sie müssen eine Auswahl für "%s" vornehmen',
    js_invalid_password   => '- Sie müssen einen gültigen Wert für das Feld "%s" angeben',
    js_invalid_textarea   => '- Sie müssen das Feld "%s" ausfüllen',
    js_invalid_file       => '- Sie müssen einen Dateinamen für das Feld "%s" angeben',
    js_invalid_number     => '- Ungültiger nummerischer Wert für in "%s"',
    js_invalid_date       => '- Ungültiges datum in "%s"',
    js_invalid_url        => '- Ungültige oder fehlerhafte Url in "%s"',
    js_invalid_email      => '- Ungültige Email-Adresse in "%s"',
    js_invalid_time       => '- Ungültige Zeit in "%s"',
   'js_invalid_datetime-local'    => '- Datum-Uhrzeit in "%s" ist ungültig',
    js_invalid_datetime_local     => '- Datum-Uhrzeit in "%s" ist ungültig',
    js_invalid_datetime   => '- Datum-Uhrzeit in "%s" ist ungültig',
    js_invalid_default    => '- Sie müssen einen gültigen Wert für das Feld "%s" angeben',

    js_noscript           => 'Bitte aktivieren Sie JavaScript '
                           . 'oder benutzen Sie einen neueren Webbrowser.',

    form_required_text    => 'Sie müssen Angaben für die %shervorgehobenen%s Felder machen.',

    form_invalid_text     => 'Ihre Angaben enthalten %s Fehler. '
                           . 'Bitte korrigieren Sie %sdiese%s Felder und versuchen Sie es erneut.',

    form_invalid_input    => 'Sie müssen einen gültigen Wert angeben',
    form_invalid_hidden   => 'Sie müssen einen gültigen Wert angeben',
    form_invalid_select   => 'Sie müssen eine Auswahl vornehmen',
    form_invalid_checkbox => 'Sie müssen eine Auswahl vornehmen',
    form_invalid_radio    => 'Sie müssen eine Auswahl vornehmen',
    form_invalid_password => 'Sie müssen einen gültigen Wert angeben',
    form_invalid_textarea => 'Sie müssen dieses Feld ausfüllen',
    form_invalid_file     => 'Sie müssen einen Dateinamen angeben',
    form_invalid_default  => 'Sie müssen einen gültigen Wert angeben',

    form_grow_default     => 'Weitere %s',
    form_select_default   => '-Auswahl-',
    form_other_default    => 'Andere:',
    form_submit_default   => 'Senden',
    form_reset_default    => 'Zurücksetzen',
    
    form_confirm_text     => 'Vielen Dank für Ihre Angaben %s.',

    mail_confirm_subject  => '%s Eingangsbestätigung',
    mail_confirm_text     => <<EOT,
Ihre Angaben sind bei uns %s eingegangen ,
und werden in Kürze bearbeitet.

Falls Sie Fragen haben, kontaktieren Sie uns bitte, indem Sie
auf diese Email antworten.
EOT
    mail_results_subject  => '%s Eingang',
});

1;
__END__

