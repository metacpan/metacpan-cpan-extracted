
###########################################################################
# Copyright (c) Nate Wiger http://nateware.com. All Rights Reserved.
# Please visit http://formbuilder.org for tutorials, support, and examples.
###########################################################################

package CGI::FormBuilder::Messages::locale;

use strict;
use utf8;

use CGI::FormBuilder::Messages::default;
use base 'CGI::FormBuilder::Messages::default';

our $VERSION = '3.10';

# Define messages for this language
__PACKAGE__->define_messages({
    lang                  => 'ru_RU',
    charset               => 'utf-8',

    js_invalid_start      => 'При отправке формы было обнаружено %s ошибок:',
    js_invalid_end        => 'Пожалуйста, исправьте эти поля и попробуйте снова.',

    js_invalid_input      => '- Неправильное значение поля "%s"',
    js_invalid_select     => '- Выберите опцию из списка "%s"',
    js_invalid_multiple   => '- Выберите одну или более опций из списка "%s"',
    js_invalid_checkbox   => '- Установите одну или более опции "%s"',
    js_invalid_radio      => '- Выберите одну из опций "%s"',
    js_invalid_password   => '- Неправильное значение поля "%s"',
    js_invalid_textarea   => '- Пожалуйста, заполните поле "%s"',
    js_invalid_file       => '- Неправильное имя файла в поле "%s"',
    js_invalid_default    => '- Неправильное значение поля "%s"',

    js_noscript           => 'Пожалуйста, разрешите Javascript или используйте более новый браузер.',

    form_required_text    => 'Поля, которые %sподсвечены%s, являются обязательными.',

    form_invalid_text     => 'При отправке формы было обнаружено %s ошибок. '
                           . 'Пожалуйста, исправьте поля, которые %sподсвечены%s ниже.',

    form_invalid_input    => 'Неправильное значение',
    form_invalid_hidden   => 'Неправильное значение',
    form_invalid_select   => 'Выберите опцию из списка',
    form_invalid_checkbox => 'Установите одну или более опций',
    form_invalid_radio    => 'Выберите опцию',
    form_invalid_password => 'Неправильное значение',
    form_invalid_textarea => 'Пожалуйста, заполните это',
    form_invalid_file     => 'Неправильное имя файла',
    form_invalid_default  => 'Неправильное значение',

    form_grow_default     => 'Дополнительный %s',
    form_select_default   => '-выберите-',
    form_other_default    => 'Другое:',
    form_submit_default   => 'Отправить',
    form_reset_default    => 'Сброс',
    
    form_confirm_text     => 'Успех! Ваша форма получена %s.',

    mail_confirm_subject  => '%s Подтверждение отправки формы',
    mail_confirm_text     => <<EOT,
Ваша форма получена %s,
и скоро будет обработана.

Если у вас есть вопросы, пожалуйста связывайтесь с нашим
персоналом, ответив на этот email.
EOT
    mail_results_subject  => '%s Результаты отправки формы',
});

1;
__END__

