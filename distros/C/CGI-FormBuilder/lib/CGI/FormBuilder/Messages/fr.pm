
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
    lang                  => 'fr_FR',
    charset               => 'utf-8',

    js_invalid_start      => '%s erreur(s) rencontrée(s) dans votre formulaire:',
    js_invalid_end        => 'Veuillez corriger ces champs et recommencer.',

    js_invalid_input      => '- Valeur incorrecte dans le champ "%s"',
    js_invalid_select     => '- Choisissez une option dans la liste "%s"',
    js_invalid_multiple   => '- Choisissez une ou plusieurs options dans la liste "%s"',
    js_invalid_checkbox   => '- Cochez une ou plusieurs des options "%s"',
    js_invalid_radio      => '- Choisissez l\'une des options "%s" ',
    js_invalid_password   => '- Valeur incorrecte dans le champ "%s"',
    js_invalid_textarea   => '- Veuillez remplir le champ "%s"',
    js_invalid_file       => '- Nom de fichier incorrect dans le champ "%s"',
    js_invalid_default    => '- Valeur incorrecte dans le champ "%s"',

    js_noscript           => 'Veuillez activer JavaScript ou '
                           . 'utiliser un navigateur plus récent.',

    form_required_text    => 'Les champs %ssoulignés%s sont obligatoires.',

    form_invalid_text     => '%s erreur(s) rencontrée(s) dans votre formulaire. '
                           . 'Veuillez corriger les champs %ssoulignés%s '
                           . 'ci-dessous.',

    form_invalid_input    => 'Valeur incorrecte',
    form_invalid_hidden   => 'Valeur incorrecte',
    form_invalid_select   => 'Choisissez l\'une des option de cette liste',
    form_invalid_checkbox => 'Cochez une ou plusieurs options',
    form_invalid_radio    => 'Choisissez une option',
    form_invalid_password => 'Valeur incorrecte',
    form_invalid_textarea => 'Veuillez saisir une valeur',
    form_invalid_file     => 'Nom de fichier incorrect',
    form_invalid_default  => 'Valeur incorrecte',

    form_grow_default     => '%s supplémentaire',
    form_select_default   => '-sélectionnez-',
    form_other_default    => 'Autres:',
    form_submit_default   => 'Envoyer',
    form_reset_default    => 'Formulaire vierge',

    form_confirm_text     => 'Réussi! Votre formulaire %s a été reçu.',

    mail_confirm_subject  => 'Confirmation du formulaire %s',
    mail_confirm_text     => <<EOT,
Votre formulaire %s a été bien reçu, et sera traité sous peu. 

Pour toute question, veuillez contacter nos services 
en répondant à cet email.'
EOT
    mail_results_subject  => 'Résultats du formulaire %s',
});

1;
__END__

