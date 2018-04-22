# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Business-BR-CNJ.t'

#########################

use Test::More tests => 5;
BEGIN { use_ok('Business::BR::CNJ::NumberExtractor') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
#warn join( ',', Business::BR::CNJ::NumberExtractor::cnj_extract_numbers_lwp( "file:t3-5-defesas-mais-comuns-numa-Acao-Cobranca.html" ) );

# Real tests with real world data
ok( join( ',', Business::BR::CNJ::NumberExtractor::cnj_extract_numbers("This is a CNJ number: 0000475-90.2016.5.06.0231, but this is not: 81723671623.")) eq '0000475-90.2016.5.06.0231', 'Extract one number' );
ok( join( ',', Business::BR::CNJ::NumberExtractor::cnj_extract_numbers_lwp( "file:t1-risco-sucumbencia-a-prova-pericial-emprestada-Justica-Trabalho.html" ) ) eq '0000475-90.2016.5.06.0231', 'LWP file test 1 (single)' );
ok( join( ',', Business::BR::CNJ::NumberExtractor::cnj_extract_numbers_lwp( "file:t2-INSS-nao-pode-exigir-carencia-casos-gravidez-risco-Decide-TRF4-sobre-auxilio-doenca.html" ) ) eq '5051528-83.2017.4.04.7100,5040895-46.2017.4.04.9999,5000846-63.2013.404.7004,5006699-24.2012.404.7122,50181894620164047205,5018189-46.2016.404.7205,5051528-83.2017.4.04.7100,00085662720114036112', 'LWP file test 2 (multi)' );
ok( join( ',', Business::BR::CNJ::NumberExtractor::cnj_extract_numbers_lwp( "file:t3-5-defesas-mais-comuns-numa-Acao-Cobranca.html" ) ) eq '00505883520028190002,03491880320088190001,10868906220138260100,1086890-62.2013.8.26.0100', 'LWP file test 3 (multi)' );
