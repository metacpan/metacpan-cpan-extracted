
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
    lang                  => 'tr_TR',
    charset               => 'utf-8',

    js_invalid_start      => 'Gönderinizde %s hata ile karşılaşıldı:',
    js_invalid_end        => 'Lütfen bu alanları düzeltin ve yeniden deneyin.',

    js_invalid_input      => '- "%s" alanında geçersiz girdi',
    js_invalid_select     => '- "%s" listesinden bir seçenek girin',
    js_invalid_multiple   => '- "%s" listesinden bir veya birden çok seçenek girin',
    js_invalid_checkbox   => '- "%s" seçeneklerinden bir veya daha fazlasını kontrol edin',
    js_invalid_radio      => '- "%s" seçeneklerinden birini seçin',
    js_invalid_password   => '- "%s" alanında geçersiz girdi',
    js_invalid_textarea   => '- Lütfen "%s" alanını doldurun',
    js_invalid_file       => '- "%s" alanında geçersiz dosya adı',
    js_invalid_default    => '- "%s" alanında geçersiz girdi',

    js_noscript           => 'Lütfen Javascript desteğini etkinleştirin veya '
                           . 'daha yeni bir tarayıcı kullanın.',

    form_required_text    => '%sİşaretli%s alanların doldurulması gerekiyor.',

    form_invalid_text     => 'Gönderinizde %s hata ile karşılaşıldı. '
                           . 'Lütfen aşağıdaki %sişaretli%s alanları düzeltin.',

    form_invalid_input    => 'Geçersiz girdi',
    form_invalid_hidden   => 'Geçersiz girdi',
    form_invalid_select   => 'Bu listeden bir seçenek girin',
    form_invalid_checkbox => 'Bir veya birden çok seçeneği kontrol edin',
    form_invalid_radio    => 'Bir seçenek girin',
    form_invalid_password => 'Geçersiz girdi',
    form_invalid_textarea => 'Lütfen bu alanı doldurun',
    form_invalid_file     => 'Geçersiz dosya adı',
    form_invalid_default  => 'Geçersiz girdi',

    form_grow_default     => 'İlâve %s',
    form_select_default   => '-seçin-',
    form_other_default    => 'Diğer:',
    form_submit_default   => 'Gönder',
    form_reset_default    => 'Temizle',
    
    form_confirm_text     => 'Başarılı! Gönderiniz %s itibarıyla alındı.',

    mail_confirm_subject  => '%s Gönderi Doğrulaması',
    mail_confirm_text     => <<EOT,
Gönderiniz %s itibarıyla alındı,
ve kısa zamanda işleme konulacak.

Eğer sorunuz varsa, lütfen bu iletiye cevap yazarak ekibimizle
irtibat kurun.
EOT
    mail_results_subject  => '%s Gönderi Sonuçları',
});

1;
__END__

