use FindBin;
use lib $FindBin::Bin.'/../thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../lib';
use utf8;

unshift @INC, sub {
    my(undef, $filename) = @_;
    return () if $filename !~ /PaymentSlip/;
    if ( my $found = (grep { -e $_ } map { "$_/$filename" } grep { !ref } @INC)[0] ) {
                local $/ = undef;
                open(my $fh, '<', $found) || die("Can't read module file $found\n");
                my $module_text = <$fh>;
                close($fh);

                # define everything in a sub, so Devel::Cover will DTRT
                # NB this introduces no extra linefeeds so D::C's line numbers
                # in reports match the file on disk
                $module_text =~ s/(.*?package\s+\S+)(.*)__END__/$1sub main {$2} main();/s;

                # filehandle on the scalar
                open ($fh, '<', \$module_text);

                # and put it into %INC too so that it looks like we loaded the code
                # from the file directly
                $INC{$filename} = $found;
                return $fh;
     } else {
          return ();
    }
};

use Test::More tests => 6;

use_ok 'Business::Payment::SwissESR::PaymentSlip';

my $t = Business::Payment::SwissESR::PaymentSlip->new(
        shiftDownMm => 1,
        shiftRightMm=> 2,
        preambleAddons => '\usepackage{tabularx}',
        senderAddressLaTeX => <<'LaTeX_End');
 Oltner 2-Stunden Lauf\newline
 Florastrasse 21\newline
 4600 Olten
LaTeX_End

is (ref $t,'Business::Payment::SwissESR::PaymentSlip', 'Instanciation');

is (`which lualatex` =~ /lualatex/, 1, 'Is LuaLaTeX available?');

$t->add(
    amount => 3949.75,
    account => '01-17546-3',
    recipientAddressLaTeX => <<'LaTeX_End',
 Peter Müller\newline
 Haldenweg 12b\newline
 4600 Olten
LaTeX_End
    bodyLaTeX => <<'LaTeX_End',
\begin{tabularx}{\textwidth}{@{}X@{ }r}
Hello&22.0\\
Aber&23.2\\
\end{tabularx}
LaTeX_End
    referenceNumber => '1234567890123456',
    watermark => 'secret marker',
);

$t->add(
    account => '01-17546-3',
    recipientAddressLaTeX => <<'LaTeX_End',
 Peter Müller\newline
 Haldenweg 12b\newline
 4600 Olten
LaTeX_End
    bodyLaTeX => 'the boddy of the bill in latex format',
    referenceNumber => '123456789012345',
    watermark => 'secret marker',
);

my $pdf = $t->renderPdf();

is (substr($pdf,0,4),'%PDF', 'PdfRender 1');

my $pdf2 = $t->renderPdf(showPaymentSlip=>1);

is (substr($pdf2,0,4),'%PDF', 'PdfRender 2');

my $file = '/tmp/esrtest.'.$$.'.pdf';
open (my $o,'>',$file);
print $o $pdf2;
close $o;

cmp_ok (`pdftotext -enc UTF-8 $file - | perl -Mutf8 -pe 's/[^"0-9a-z]//sg'|md5sum`, '=~', '4d9caec9fff3de1771483a731959c75f','content check');
#system "gnome-open $file";
unlink $file;
