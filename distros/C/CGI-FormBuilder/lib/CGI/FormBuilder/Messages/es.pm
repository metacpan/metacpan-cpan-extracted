
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

# First, create a hash of messages for this language
__PACKAGE__->define_messages({
    lang                  => 'es_ES',
    charset               => 'utf-8',

    js_invalid_start      => '%s error(es) fueron encontrados en su formulario:',
    js_invalid_end        => 'Por favor corrija en el/los campo(s) e intente de nuevo\n', 
    js_invalid_input      => 'Introduzca un valor válido para el campo: "%s"',
    js_invalid_select     => 'Escoja una opción de la lista: "%s"', 
    js_invalid_multiple   => '- Escoja una o más opciones de la lista: "%s"',
    js_invalid_checkbox   => '- Revise una o más de las opciones: "%s"',
    js_invalid_radio      => '- Escoja una de las opciones de la lista: "%s"',
    js_invalid_password   => '- Valor incorrecto para el campo: "%s"',
    js_invalid_textarea   => '- Por favor, rellene el campo: "%s"',
    js_invalid_file       => '- El nombre del documento es inválido para el campo: "%s"',
    js_invalid_default    => 'Introduzca un valor válido para el campo: "%s"',

    js_noscript           => 'Por favor habilite Javascript en su navegador o use una versión más reciente',

    form_required_text    => 'Los campos %sresaltados%s son obligatorios',
    form_invalid_text     => 'Se encontraron %s error(es) al realizar su pedido. Por favor corrija los valores en los campos %sresaltados%s y vuelva a intentarlo.',

    form_invalid_input    => 'Valor inválido',
    form_invalid_hidden   => 'Valor inválido',
    form_invalid_select   => 'Escoja una opción de la lista',
    form_invalid_checkbox => 'Escoja una o más opciones',
    form_invalid_radio    => 'Escoja una opción',
    form_invalid_password => 'Valor incorrecto',
    form_invalid_textarea => 'Por favor, rellene el campo',
    form_invalid_file     => 'Nombre del documento inválido',
    form_invalid_default  => 'Valor inválido',

    form_grow_default     => 'Más %s',
    form_select_default   => '-Seleccione-',
    form_other_default    => 'Otro:',
    form_submit_default   => 'Enviar',
    form_reset_default    => 'Borrar',
    form_confirm_text     => '¡Lo logró! ¡El sistema ha recibido sus datos! %s.',

    mail_confirm_subject  => '%s Confirmación de su pedido.',
    mail_confirm_text     => '¡El sistema ha recibido sus datos! %s., Si desea hacer alguna pregunta, por favor responda a éste correo electrónico.',
    mail_results_subject  => '%s Resultado de su pedido.'
});

1;
__END__

