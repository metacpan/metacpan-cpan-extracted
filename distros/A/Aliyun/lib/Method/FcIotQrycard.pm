package Aliyun::Method::FcIotQrycard;
use 5.010;
use Data::Dumper qw/Dumper/;
use version;
our $VERSION = 0.1;
#阿里大于查询终端信息

sub new {
    my $class = shift;
    $class = (ref $class) || $class || __PACKAGE__;
    my $self = bless {}, $class;
    $self->{'params'} = {
        'method' => 'alibaba.aliqin.fc.iot.qrycard',
    };
    return $self;
}

#外部计费来源
sub set_bill_source {
    $_[0]->{'params'}->{'bill_source'} = $_[1];
}

#外部计费号
sub set_bill_real {
    $_[0]->{'params'}->{'bill_real'} = $_[1];
}

#ICCID
sub set_iccid {
    $_[0]->{'params'}->{'iccid'} = $_[1];
}

sub get_params {
    return $_[0]->{'params'};
}

1;

__DATA__

=encoding utf8

=head1 NAME

Aliyun::Method::FcIotQrycard- 阿里大于查询终端信息


=head1 ATTRIBUTES

=head1 METHODS

=head2 set_bill_source

  外部计费来源

=head2 set_bill_real

  外部计费号

=head2 set_iccid

  设置ICCID

=head2 get_params

  %hash = get_params()
  获取提交的参数。该方法必须实现

=cut


