package Aliyun;
use 5.024003;
use strict;
use warnings;

our $VERSION = '1.0.0';


# Preloaded methods go here.

1;
__END__

=encoding utf8

=head1 NAME

Aliyun - 阿里云SDK

=head1 SYNOPSIS

  use Aliyun::AuthV2;
  use Aliyun::Request;
  use Aliyun::Method::FcSmsNumSend;
  use Aliyun::Method::FcIotQrycard;
  use Data::Dumper qw/Dumper/;

  my $auth = Aliyun::AuthV2->new();
     $auth->set_appkey('你自己的key');
     $auth->set_secretkey('你自己的秘钥');

  my $method = Aliyun::Method::FcSmsNumSend->new();
     $method->set_rec_num('13800138000');
     $method->set_sms_free_sign_name('短信签名');
     $method->set_sms_template_code('短信模板id');
     $method->set_sms_param('{"rain":"下雨","temper":"18"}');

  my $method2 = Aliyun::Method::FcIotQrycard->new();
     $method2->set_bill_source('ICCID');
     $method2->set_bill_real('123123');
     $method2->set_iccid('123123');

  my $request = Aliyun::Request->new();
     $request->get($auth, $method, sub {
        say Dumper $_[0];
    });

     $request->get($auth, $method2, sub {
        say Dumper $_[0];
    });

  
=head1 SEE ALSO

L<Aliyun::Request>,L<Aliyun::AuthV2>

=head1 AUTHOR

CGI.NET loveme1314@gmail.com

=head1 LINCENSE

MIT

=cut
