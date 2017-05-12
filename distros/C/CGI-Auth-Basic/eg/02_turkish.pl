#!/usr/bin/perl -w
use strict;
use warnings;
use utf8;
use CGI;

if ( $] >= 5.008 ) {
   eval q{ binmode STDOUT, ":utf8"; 1; } or die "Unable to change IO layer: $@";
}

my $tr_auth = TRAuth->new( CGI->new );
# $auth->set_template(delete_all => 1);
$tr_auth->check_user;
$tr_auth->_screen(
   content => 'Bu programı kullanabilirsiniz',
   title   => 'Erişim onaylandı',
);

# Translate the interface to turkish
package TRAuth;
use CGI::Auth::Basic;

sub new {
   my $class = shift;
   my $cgi   = shift;
   CGI::Auth::Basic->fatal_header("Content-Type: text/html; charset=utf8\n\n");
   %CGI::Auth::Basic::ERROR = error();
   my $auth = CGI::Auth::Basic->new(
               cgi_object     => $cgi,
               file           => './password.txt',
               http_charset   => 'utf8',
               setup_pfile    => 1,
               logoff_param   => 'cik',
               changep_param  => 'parola_degistir',
               cookie_id      => 'parolakurabiyesi',
               cookie_timeout => '1h',
               chmod_value    => 0777,
            );

   $auth->set_template(template());
   $auth->set_title(title());
   return $auth;
}

sub template {
   return login_form => <<"TEMPLATE",
<span class="error"><?PAGE_FORM_ERROR?></span>
<form action="<?PROGRAM?>" method="post">

<table border="0" cellpadding="0" cellspacing="0">
 <tr><td class="darktable">
  <table border="0" cellpadding="4" cellspacing="1">
 <tr>
   <td class="titletable" colspan="3">Bu özelliği kullanabilmek için bağlanmalısınız</td>
 </tr>
 <tr>
  <td class="lighttable">Bu programı kullanmak için <i>gereken</i> parolayı girin:</td>
  <td class="lighttable"><input type="password" name="<?COOKIE_ID?>"></td>
  <td class="lighttable" align="right"><input type="submit" name="submit" value="Bağlan"></td>
 </tr>
</table>
</td> </tr>
</table>
</form>
TEMPLATE

change_pass_form => <<"TEMPLATE",
<span class="error"><?PAGE_FORM_ERROR?></span>
<form action="<?PROGRAM?>" method="post">

<table border="0" cellpadding="0" cellspacing="0">
 <tr><td class="darktable">
  <table border="0" cellpadding="4" cellspacing="1">
 <tr>
   <td class="titletable" colspan="3">
   3 ile 32 karakter arasında bir parola girin. Boşluk kullanmayın!</td>
 </tr>
 <tr>
  <td class="lighttable">Yeni parolanızı girin:</td>
  <td class="lighttable"><input type="password" name="<?COOKIE_ID?>_new"></td>
  <td class="lighttable" align="right">
  <input type="submit" name="submit" value="Parolayı değiştir">
  <input type="hidden" name="change_password" value="ok"></td>
  <input type="hidden" name="<?CHANGEP_PARAM?>" value="1"></td>

 </tr>
</table>
</td> </tr>
</table>
</form>

TEMPLATE

screen => <<"TEMPLATE",
<html>
   <head>
    <?PAGE_REFRESH?>
    <title>CGI::Auth::Basic - Türkçe >> <?PAGE_TITLE?></title>
    <style>
      body       {font-family: Verdana, sans; font-size: 10pt}
      td         {font-family: Verdana, sans; font-size: 10pt}
     .darktable  { background: black;   }
     .lighttable { background: white;   }
     .titletable { background: #dedede; }
     .error      { color = red; font-weight: bold}
     .small      { font-size: 8pt}
    </style>
   </head>
   <body>
      <?PAGE_LOGOFF_LINK?>
      <?PAGE_CONTENT?>
      <?PAGE_INLINE_REFRESH?>
   </body>
   </html>
TEMPLATE

   logoff_link => qq~
   <span class="small">[<a href="<?PROGRAM?>?<?LOGOFF_PARAM?>=1">Çık</a>
   - <a href="<?PROGRAM?>?<?CHANGEP_PARAM?>=1">Parolayı değiştir</a>]</span> ~,

}

sub title {
return login_form       => 'Bağlan',
   cookie_error     => 'Geçersiz kurabiye',
   login_success    => 'Bağlantı başarılı',
   logged_off       => 'Çıkış yaptınız',
   change_pass_form => 'Parolayı değiştir',
   password_created => 'Parola oluşturuldu',
   password_changed => 'Parola başarıyla değiştirildi',
   error            => 'Hata',
   ;
}

sub error {
return INVALID_OPTION    => q{Seçenekler 'parametre => değer' biçiminde olmalı!},
   CGI_OBJECT        => q{Çalışmak için bir CGI nesnesine ihtiyacım var!!!},
   FILE_READ         => 'Parola dosyası açılamıyor: ',
   NO_PASSWORD       => 'Herhangi bir parola belirtilmedi (veya parola dosyası bulunamıyor)!',
   UPDATE_PFILE      => 'Parola dosyanız boş ve geçerli ayarlarınız bu kodun dosyayı güncellemesine izin vermiyor! Lütfen parola dosyanızı güncelleyin.',
   ILLEGAL_PASSWORD  => 'Geçersiz parola! Kabul edilmedi. Geri dönün ve yeni bir tane girin',
   FILE_WRITE        => 'Parola dosyası güncelleme için açılamıyor: ',
   UNKNOWN_METHOD    => q{'<b>%s</b>' adında bir metod yok. Kodunuzu denetleyin.},
   EMPTY_FORM_PFIELD => 'Herhangi bir parola ayarlamadınız (parola dosyası boş)!',
   WRONG_PASSWORD    => '<p>Yanlış Parola!</p>',
   INVALID_COOKIE    => 'Kurabiyeniz geçersiz bilgi içeriyor ve bu kurabiye program tarafından silindi.',
   ;
}
