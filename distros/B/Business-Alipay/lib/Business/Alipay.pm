package Business::Alipay;

use strict;
use 5.008_005;
our $VERSION = '0.01';

use Carp;
use LWP::UserAgent;
use Digest::MD5 'md5_hex';

sub new {
    my $class = shift;
    my $args = scalar @_ % 2 ? shift : {@_};

    # validate
    $args->{ALIPAY_KEY}  or croak 'ALIPAY_KEY is required';
    $args->{ALIPAY_PARTNER}  or croak 'ALIPAY_PARTNER is required';
    $args->{ALIPAY_SELLER_EMAIL} or croak 'ALIPAY_SELLER_EMAIL is required';

    unless ( $args->{ua} ) {
        my $ua_args = delete $args->{ua_args} || {};
        $args->{ua} = LWP::UserAgent->new(%$ua_args);
    }

    bless $args, $class;
}

sub create_direct_pay_by_user {
	my $self = shift;
	my $args = scalar @_ % 2 ? shift : {@_};

	my $params = {
		"service" => "create_direct_pay_by_user",
		"partner" => $self->{ALIPAY_PARTNER},
		"payment_type"	=> 1,
		"notify_url"	=> $args->{notify_url},
		"return_url"	=> $args->{return_url},
		"seller_email"	=> $self->{ALIPAY_SELLER_EMAIL},
		"out_trade_no"	=> $args->{out_trade_no},
		"subject"	=> $args->{subject},
		"total_fee"	=> $args->{total_fee},
		"body"	=> $args->{body},
		"show_url"	=> '',
		"anti_phishing_key"	=> '',
		"exter_invoke_ip"	=> '',
		"_input_charset"	=> 'utf-8',
	};

	my ($new_params, $prestr) = __params_filter($params);
	my $md5 = md5_hex($prestr . $self->{ALIPAY_KEY});

	$new_params->{sign} = $md5;
	$new_params->{sign_type} = 'MD5';
	$prestr .= '&sign=' . $md5;
	$prestr .= '&sign_type=MD5';

	return 'https://mapi.alipay.com/gateway.do?'  . $prestr;
}

sub notify_verify {
	my $self = shift;
	my $params = scalar @_ % 2 ? shift : {@_};

	my ($new_params, $prestr) = __params_filter($params);
	my $md5 = md5_hex($prestr . $self->{ALIPAY_KEY});
	my $params_sign = $params->{sign};

	return 'sign_dismatch' unless $md5 eq $params_sign;

	my $url = "https://www.alipay.com/cooperate/gateway.do?service=notify_verify&partner=" . $self->{ALIPAY_PARTNER} . "&notify_id=" . $params->{notify_id};
	# retry few times if HTTP issue
	my $tried_times = 0;
	while (1) {
		my $res = $self->{ua}->get($url);
		return $res->content if $res->is_success;
		$tried_times++;
		last if $tried_times > 5;
		sleep 1;
	}
	return 'unknown'; # FAILED
}

sub __params_filter {
	my ($params) = @_;

	my %new_params; my $prestr;
	my @keys = keys %$params;
	foreach my $k (sort keys %$params) {
		next if ($k eq 'sign' or $k eq 'sign_type' or $params->{$k} eq '');
		$new_params{$k} = $params->{$k};
		$prestr .= $k . '=' . $params->{$k} . '&';
	}
	$prestr =~ s/\&$//;

	return (\%new_params, $prestr);
}

1;
__END__

=encoding utf-8

=head1 NAME

Business::Alipay - Alipay payment

=head1 SYNOPSIS

  use Business::Alipay;

  my $alipay = Business::Alipay->new({
	"ALIPAY_KEY" => "", # 安全检验码，以数字和字母组成的32位字符
    "ALIPAY_PARTNER" => "", # 合作身份者ID，以2088开头的16位纯数字
    "ALIPAY_SELLER_EMAIL" => "", # 签约支付宝账号或卖家支付宝帐户
  });

  my $redirect_url = $alipay->create_direct_pay_by_user({
    notify_url => $notify_url, ## notify url
    return_url => $return_url, ## 返回 url

    out_trade_no => $uuid, # unique id
    subject => 'subject',
    body => 'description',
    total_fee => '0.01', # 金额
  });
  # $redirect_url is a url, you should redirect to that
  print $q->redirect($redirect_url);

  #### for return or notify, in another sub or file
  my $params = $q->params(); # or $c->req->params->to_hash for Mojolicious

  my $out_trade_no = $params->{out_trade_no};
  # make sure it's not proceeded before.
  # return if already_proceeded($out_trade_no);

  my $trade_status = $params->{trade_status};
  if ($trade_status eq 'TRADE_FINISHED' or $trade_status eq 'TRADE_SUCCESS') {
	my $r = $alipay->notify_verify($params);
	# $r is one of 'true', 'false', 'sign_dismatch', 'unknown' (unknown is HTTP failure)
  }

=head1 DESCRIPTION

Business::Alipay is a payment gateway for L<https://www.alipay.com/>.

right now it's very incomplete and only supports B<create_direct_pay_by_user>. patches are welcome.

=head1 AUTHOR

Fayland Lam E<lt>fayland@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2013- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
