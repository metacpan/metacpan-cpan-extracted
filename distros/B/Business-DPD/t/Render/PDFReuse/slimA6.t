use 5.010;
use strict;
use warnings;

use Test::More tests => 2;
use Encode;
use utf8;
eval {
    use Business::DPD;
    use Business::DPD::Label;
    use Business::DPD::Render::PDFReuse::SlimA6;
    my $dpd = Business::DPD->new;
    $dpd->connect_schema;
    my $label = Business::DPD::Label->new($dpd,{
        zip             => '12555',
        country         => 'DE',
        depot           => '0190',
        serial          => '5002345615',
        service_code    => '101',
        weight          => '23,45 KG',
        shipment_count_this=>1,
        shipment_count_total=>2,
        reference_number=>"ACME Dehydrated Boulders",
        order_number=>["aaa","bbb"],
        recipient=> ['Wile E. Coyote','Somewhere in the höt & dry deserť!!','Highway 20','DE-12555 Desert','bitte 3x klingeln'],
    });

    $label->calc_fields;

    my $renderer = Business::DPD::Render::PDFReuse::SlimA6->new($dpd,{
        outdir => '.',    
        originator=>['ACME Corp.','Your favourite provider of cööl toołs','Some street 17','DE-91058 Erlangen','Tel 12345'],
        template=>'templates/default.pdf',
    });

    $renderer->render($label);
};

is($@,'','no error');
ok(-e '001255501905002345615101276.pdf','pdf exists');
unlink('001255501905002345615101276.pdf') unless $ENV{KEEP_PDF};

