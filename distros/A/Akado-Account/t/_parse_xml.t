#!/usr/bin/perl

use Test::More tests => 1;

use Akado::Account;

# subs
sub read_xml_from_data_section {
    my $data;

    while (<DATA>) {
        $data .= $_;
    }

    return $data;
}

# main
sub main {

    my $xml = read_xml_from_data_section();
    my $parsed = Akado::Account::_parse_xml(undef, $xml);

    is_deeply(
        $parsed,
        {
            balance => 1452,
            next_month_payment => 484,
        },
        "_parse_xml()",
    );
}

main();
__END__
<?xml version="1.0" encoding="UTF-8"?>
<?akado-request A1-B2?>
<?xml-stylesheet type="text/xsl" href="/interface/templates/finance.xsl?C3-D4"?>
<main responseType="accepted" crc="40252555">
  <billing income-monthly="0" expense-monthly="484" balance-begin="1936" balance-end="1452" last-day="06.05.2014" request-date="06.05.2014">
    <income id="383554863" amount="0" type="1" comment="Датой платежа считается дата зачисления средств на Ваш лицевой счет в АКАДО." description="Поступления на счет в мае 2014"/>
    <expense id="383554875" amount="484" type="2" description="Стоимость услуг в мае 2014">
      <bill id="383554876" parent="383554875" amount="4" description="Аренда кабельного модема"/>
      <bill id="383554877" parent="383554875" amount="480" description="Услуги интернет">
        <bill id="383554878" parent="383554877" amount="390" description="АКАДО Интернет 15 (Абонентская плата - av12345)"/>
        <bill id="383554879" parent="383554877" amount="90" description="АКАДО Интернет 15 (Поддержка внешнего IP-адреса - av12345)"/>
      </bill>
    </expense>
    <bill id="383554877" parent="383554875" amount="480" description="Услуги интернет">
      <bill id="383554878" parent="383554877" amount="390" description="АКАДО Интернет 15 (Абонентская плата - av12345)"/>
      <bill id="383554879" parent="383554877" amount="90" description="АКАДО Интернет 15 (Поддержка внешнего IP-адреса - av12345)"/>
    </bill>
    <bill id="383554886" amount="0" type="5" comment="Рекомендуемая сумма оплаты не включает доплату за услуги в текущем месяце." description="Рекомендуемая сумма для внесения на счет в следующем календарном месяце">
      <bill id="383554887" parent="383554886" amount="1452" description="Остаток на счете на 31.05.2014"/>
      <bill id="383554888" parent="383554886" amount="484" description="Стоимость услуг в следующем календарном месяце">
        <bill id="383554889" parent="383554888" amount="480" description="УСЛУГИ ИНТЕРНЕТ"/>
        <bill id="383554890" parent="383554888" amount="4" description="Аренда кабельного модема"/>
      </bill>
    </bill>
    <bill id="383554888" parent="383554886" amount="484" description="Стоимость услуг в следующем календарном месяце">
      <bill id="383554889" parent="383554888" amount="480" description="УСЛУГИ ИНТЕРНЕТ"/>
      <bill id="383554890" parent="383554888" amount="4" description="Аренда кабельного модема"/>
    </bill>
    <prepay/>
  </billing>
</main>
