package Aliyun::Request;
use 5.010;
use strict;
use warnings;
use Mojo::UserAgent;
use Aliyun::AuthV2;
use Data::Dumper qw/Dumper/;
use Cpanel::JSON::XS;
use version;
our $VERSION = 0.2;

sub new {
    my $class = shift;
    $class = (ref $class) || $class || __PACKAGE__;
    my $self = bless {}, $class;
    $self->{'http_head'} = {
        'Accept'                    => 'application/json,*/*;q=0.8,',
        'Accept-Encoding'           => 'deflate',
        'Accept-Language'           => 'zh-CN',
        'Cache-Control'             => 'no-cache',
        'Connection'                => 'keep-alive',
        'DNT'                       => '1',
        'Pragma'                    => 'no-cache',
        'Upgrade-Insecure-Requests' => '1',
        'User-Agent'                => "perl-Aliyun-Request V:$VERSION"
    };
    return $self;
}

#请求阿里API并返回结果
#param: Aliyun::AuthV2对象
#param: Aliyun::Method对象
#param: 回调函数
sub get {
    my ($self, $auth, $method, $cb) = @_;
    my $url = $auth->get_url($method->get_params());
    my $ua = Mojo::UserAgent->new(max_redirects => 5);
    my $delay = Mojo::IOLoop->delay;
    $ua->get($url => $self->{'http_head'} => sub {
            my ($mojo_ua, $tx) = @_;
            my $result = {};
            if (my $res = $tx->success) {
                $result = decode_json($res->body) || {};
            }
            else {
                my $err = $tx->error;
                $result = { 'error_response' => {
                        'code'     => $err->{code} ? $err->{code} : '9999',
                        'msg'      => $err->{message},
                        'sub_code' => $err->{message}
                    } };
            }
            if (ref $cb eq ref sub {}) {
                $cb->($result);
            }
        });
    $delay->wait;
}
1;

__DATA__

=encoding utf8

=head1 NAME

Aliyun::Request - 异步请求阿里云的客户端

=head1 ATTRIBUTES

=head1 METHODS

=head2 get

  $request->get(Aliyun::AuthV2, Aliyun::Method, sub{callback});
  
  异步发送请求到阿里云.
  
=head1 SEE ALSO

L<Aliyun::AuthV2>, L<Mojo::UserAgent>.

=cut
