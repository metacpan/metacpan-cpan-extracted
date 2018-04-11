package Aliyun::Method::FcSmsNumSend;
use 5.010;
use Data::Dumper qw/Dumper/;
use Cpanel::JSON::XS;
use version;
our $VERSION = 0.1;
#阿里大于短信发送
sub new {
    my $class = shift;
    $class = (ref $class) || $class || __PACKAGE__;
    my $self = bless {}, $class;
    $self->{'params'} = {
        'method'   => 'alibaba.aliqin.fc.sms.num.send',
        'sms_type' => 'normal',
    };
    return $self;
}

#设置接收号码
sub set_rec_num {
    $_[0]->{'params'}->{'rec_num'} = $_[1];
}

#设置短信签名
sub set_sms_free_sign_name {
    $_[0]->{'params'}->{'sms_free_sign_name'} = $_[1];
}

#设置模板id
sub set_sms_template_code {
    $_[0]->{'params'}->{'sms_template_code'} = $_[1];
}

#设置内容替换
sub set_sms_param {
    $_[0]->{'params'}->{'sms_param'} = encode_json($_[1]);
}

sub get_params {
    return $_[0]->{'params'};
}

1;

__DATA__

=encoding utf8

=head1 NAME

Aliyun::Method::FcSmsNumSend- 阿里大于发送短信


=head1 METHODS

=head2 set_rec_num

  set_rec_num('phone_no')
  设置接收号码

=head2 set_sms_free_sign_name

  set_sms_free_sign_name()
  设置短信签名

=head2 set_sms_template_code
 
  set_sms_template_code()
  设置短信模板id

=head2 set_sms_param

  set_sms_param()
  设置短信内容替换

=head2 get_params

  %hash = get_params()
  获取提交的参数。该方法必须实现

=cut

