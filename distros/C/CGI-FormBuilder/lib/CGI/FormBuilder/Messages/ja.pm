
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
    lang                  => 'ja_JP',
    charset               => 'utf-8',

	  js_invalid_start      => '%s個の入力エラーがあります。',
    js_invalid_end        => 'もう一度確認して正しい内容を入力して下さい。',

    js_invalid_input      => '%sに正しい値を入力して下さい。',
    js_invalid_select     => '%sが選択されていません。',
    js_invalid_multiple   => '%sからひとつ以上を選択して下さい。',
    js_invalid_checkbox   => '%sがチェックされていません。',
    js_invalid_radio      => '%sが選択されていません。',
    js_invalid_password   => '%sに正しい値を入力して下さい。',
    js_invalid_textarea   => '%sは必須入力です。',
    js_invalid_file       => '%sは指定されたファイルを選択して下さい。',
    js_invalid_default    => '%sに正しい値を入力して下さい。',

    js_noscript           => 'JavaScriptを有効にして下さい。'
    						. 'またはJavaScript対応の最新のブラウザを使用して下さい。',
    form_required_text    => '%s太字%sの項目は必須項目です。',

    form_invalid_text     => 'あなたの入力した項目のうち、%s個のエラーがあります。'
    						. '項目の下にある%sエラーメッセージ%sに従い正しい値を入力して下さい。',

    form_invalid_input    => '正しい値を入力して下さい。',
    form_invalid_hidden   => '正しい値を入力して下さい。',
    form_invalid_select   => '一覧から選択して下さい。',
    form_invalid_checkbox => 'チェックボックスの中から選択して下さい。',
    form_invalid_radio    => 'ラジオボタンの中から選択して下さい。',
    form_invalid_password => '正しい値を入力して下さい。',
    form_invalid_textarea => '必須入力です。',
    form_invalid_file     => '正しいファイルを選択して下さい。',
    form_invalid_default  => '正しい値を入力して下さい。',

	form_grow_default     => '%sを追加する',
	form_other_default    => 'その他',
    form_select_default   => '選択して下さい',
    form_submit_default   => '送信',
    form_reset_default    => 'リセット',
    
    form_confirm_text     => '%sの入力内容を受け付けました。ありがとうございます。',

    mail_confirm_subject  => '%sの入力確認',
    mail_confirm_text     => <<EOT,
フォームの送信を受け付けました [%s]。

質問等ございます方は、このメールをそのまま返信して下さい。
EOT
    mail_results_subject  => '%sの送信内容',
});

1;
__END__

