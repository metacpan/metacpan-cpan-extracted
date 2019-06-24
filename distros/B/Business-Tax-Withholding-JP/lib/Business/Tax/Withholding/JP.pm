package Business::Tax::Withholding::JP;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.05";

use constant { border => 1000000 };

my %consumption = (
    rate => 0.08,
    name => '消費税',
);

my %withholding = (
    rate => 0.10,
    name => '源泉徴収',
);

my %special = (
    rate => 0.0021,
    name => '復興特別所得税',
    from => '2013-01-01',
    until => '2037-12-31',
);

use Moose;
use Time::Piece;
my $t = localtime;

has price => ( is => 'rw', isa => 'Int', default => 0 );
has amount => ( is => 'rw', isa => 'Int', default => 1 );
has date => ( is => 'rw', isa => 'Str', default => $t->ymd() );
has no_wh => ( is => 'ro', isa => 'Bool', default => 0 );

__PACKAGE__->meta->make_immutable;
no Moose;

sub net {
    my $self = shift;
    return $self->price(@_);
}

sub subtotal {
    my $self = shift;
    return $self->price() * $self->amount();
}

sub tax {
    my $self = shift;
    return int( $self->subtotal() * $consumption{'rate'} );
}

sub full {
    my $self = shift;
    return int( $self->subtotal() + $self->tax() );
}

sub withholding {
    my $self = shift;
    return 0 if $self->no_wh();
    my $rate = $self->rate();
    if( $self->subtotal() <= border ) {
        return int( $self->subtotal() * $rate );
    }else{
        my $base = $self->subtotal() - border;
        return int( $base * $rate * 2 + border * $rate );
    }
}

sub rate {
    my $self = shift;
    my $rate = $withholding{'rate'};
    my $from = $t->strptime( $special{'from'}, '%Y-%m-%d' );
    my $until = $t->strptime( $special{'until'}, '%Y-%m-%d' );
    my $date = $t->strptime( $self->date(), '%Y-%m-%d' );

    return $rate if $date < $from or $until < $date;
    return $rate + $special{'rate'};
}

sub total {
    my $self = shift;
    return $self->full - $self->withholding;
}

1;
__END__

=encoding utf-8

=head1 NAME

Business::Tax::Withholding::JP - auto calculation for Japanese tax and withholding

Business::Tax::Withholding::JP - 日本の消費税と源泉徴収のややこしい計算を自動化します。

 
=head1 SYNOPSIS

 use Business::Tax::Withholding::JP;
 my $calc = Business::Tax::Withholding::JP->new( price => 10000 );

 $calc->net();          # 10000
 $calc->amount();       # 1
 $calc->subtotal();     # 10000
 $calc->tax();          # 800
 $calc->full();         # 10800
 $calc->withholding();  # 1021
 $calc->total();        # 9779

 # Or you can set the date in period of special tax being expired
 $calc = Business::Tax::Withholding::JP->new( date => '2038-01-01' );
 $calc->price(10000);
 $calc->withholding();  # 1000
 $calc->total();        # 9800

 # And you may ignore the withholings
 $calc = Business::Tax::Withholding::JP->new( no_wh => 1 );
 $calc->price(10000);   # 10000
 $calc->amount(2);      # 2
 $calc->subtotal();     # 20000
 $calc->tax();          # 1600
 $calc->withholding();  # 0
 $calc->total();        # 21600

=head1 DESCRIPTION

Business::Tax::Withholding::JP
is useful calculator for long term in Japanese Business.

You can get correctly taxes and withholdings from price in your context
without worrying about the special tax for reconstructing from the Earthquake.

the consumption tax B<rate is 8%>
 
You can also ignore the withholings. It means this module can be a tax calculator

Business::Tax::Withholding::JP は日本のビジネスで長期的に使えるモジュールです。
特別復興所得税の期限を心配することなく、請求価格から正しく税金額と源泉徴収額を計算できます。
なお、源泉徴収をしない経理にも対応します。B<消費税率は8％> です。
 
=head2 Constructor

=head3 new( price => I<Int>, amount => I<Int>, date => I<Date>, no_wh => I<Bool> );

You can omit these paramators.

パラメータは指定しなくて構いません。
 
=over
 
=item price
 
the price of your products will be set. defaults 0.
 
税抜価格を指定してください。指定しなければ0です。

=item amount
 
the amount of your products will be set. defaults 1.
 
数量を指定してください。指定しなければ1です。

=item date

You can set payday. the net of withholding depends on this. default is today.
 
支払日を指定してください。源泉徴収額が変動することがあります。指定しなければ今日として計算します。
 
=item no_wh
 
If you set this flag, the all you can get is only tax and total. defaults 0 and this is read-only.

このフラグを立てるとこのモジュールの長所を台無しにできます。初期値はもちろん0で、あとから変えることはできません。
 
=back
 
=head2 Methods and subroutine

=over

=item price

You can reset the price.

price に値を代入可能です。
 
=item amount
 
You can reset the amount.
 
amount に値を代入可能です。

=item date

You can reset the payday like 'YYYY-MM-DD'

date にも値を代入可能です。フォーマットは'YYYY-MM-DD'（-区切り）です。

=item net

You can get the net of your pay. it's equal to the price.
So it's the alias of price().
 
net は price と同じ働きをします。
 
=item subtotal
 
it returns price() * amount()

subtotal は値と数量の積（小計）を返します。
 
=item tax
 
You can get the net of your tax.
 
税額のみを取得したい場合はこちらを

=item full
 
You can get the net of your pay including tax.

税込金額を知りたい場合はこちらを
 
=item withholding
 
You can get the net of your withholding from your pay.

源泉徴収額を知りたい場合はこちらを
 
=item total

You can get the total of your pay including tax without withholding
 
源泉徴収額を差し引いた税込支払額を知りたい場合はこちらをお使いください。
 
=back

=head1 LICENSE

Copyright (C) worthmine.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

worthmine E<lt>worthmine@cpan.orgE<gt>

=cut
