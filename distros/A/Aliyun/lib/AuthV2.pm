package Aliyun::AuthV2;
use Crypt::Digest::MD5 qw(md5_hex);
use URI::Escape;
use Data::Dumper qw/Dumper/;
use DateTime;
use DateTime::Format::Strptime qw();
use Hash::Merge;
use version;
our $VERSION = 0.2;

#阿里云API签名
sub new {
    my $class = shift;
    $class = (ref $class) || $class || __PACKAGE__;
    my $self = bless {}, $class;
    $self->{'aliyun_url'} = 'http://gw.api.taobao.com/router/rest';
    return $self;
}

#设置环境
#param:是否是沙盒环境
#param:是否启启用https
sub set_evn {
    my ($self, $is_sanbox, $is_https) = @_;
    if ($is_sanbox) {
        $self->{'aliyun_url'} = $is_https              ?
            'https://gw.api.tbsandbox.com/router/rest' :
            'http://gw.api.tbsandbox.com/router/rest';
    }
    else {
        $self->{'aliyun_url'} = $is_https        ?
            'https://eco.taobao.com/router/rest' :
            'http://gw.api.taobao.com/router/rest';
    }
}

#设置app key
sub set_appkey {
    $_[0]->{'app_key'} = $_[1];
}

#设置secret key
sub set_secretkey {
    $_[0]->{'secret_key'} = $_[1];
}

sub set_target_app_key {
    $_[0]->{'set_target_app_key'} = $_[1];
}

sub set_session {
    $_[0]->{'set_session'} = $_[1];
}

sub set_partner_id {
    $_[0]->{'set_partner_id'} = $_[1];
}

sub _get_public_params {
    my $public_params = {
        'app_key'     => $_[0]->{'app_key'},
        'sign_method' => 'md5',
        'timestamp'   =>
        DateTime::Format::Strptime->new(pattern => '%Y-%m-%d %H:%M:%S')->format_datetime(DateTime->now(time_zone =>
            'local')),
        'format'      => 'json',
        'v'           => '2.0',
    };
    foreach ('set_target_app_key', 'set_session', 'set_partner_id') {
        if ($self->{$_}) {
            $public_params->{$_} = $self->{$_};
        }
    }
    return $public_params;
}

#获取带签名的请求地址
#retrun:string 带签名的完整url地址
sub get_url {
    my ($self, $input_parms) = @_;
    if (!$self->{'app_key'} || !$self->{'secret_key'}) {
        return 0;
    }
    my $merge = Hash::Merge->new('LEFT_PRECEDENT');
    my $public_params = $self->_get_public_params();
    my $all_parms = $merge->merge($public_params, $input_parms);
    my ($signature_param, $url_param) = ('', '');
    map {
        #是否需要转utf8?
        #$_ = encode_utf8($_);
        $signature_param .= $_ . $all_parms->{$_};
        $url_param .= join('=', $_, uri_escape($all_parms->{$_}) . '&')
    } sort keys(%{$all_parms});
    #MD5加密后需要全部大写,否则签名会出错
    my $signature = uc(md5_hex(
        $self->{'secret_key'} . $signature_param . $self->{'secret_key'}
    ));
    return sprintf('%s?%ssign=%s', $self->{'aliyun_url'}, $url_param, $signature);
}
1;

__DATA__

=encoding utf8

=head1 NAME

Aliyun::AuthV2- 阿里云V2签名算法

=head1 SYNOPSIS

  use Aliyun::AuthV2;
  my $auth = Aliyun::AuthV2->new();
     $auth->set_appkey('你自己的key');
     $auth->set_secretkey('你自己的秘钥');

=head1 DESCRIPTION

L<Aliyun::AuthV2> 阿里云V2签名算法

=head1 ATTRIBUTES

=head1 METHODS

=head2 set_evn

  $auth->set_evn(1, 0);
  是否是sanbox   生产环境：1,测试环境：0,默认:1
  是否启用https  启用https：1,非https:0,默认:0

=head2 set_appkey

  $auth->set_appkey('你自己的key');
  
  设置阿里云给你的key值
  
=head2 set_secretkey

  $auth->set_secretkey('你自己的秘钥');
  
  置阿里云给你的秘钥

=head2 get_url

  $auth->set_secretkey({});
 
  生成请求的url地址

=cut