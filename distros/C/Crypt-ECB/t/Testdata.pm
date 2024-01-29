package Testdata;

use strict;
use warnings;

use vars qw(@ISA @EXPORT $key $plaintext %ciphertext @ciphers %padding @padstyles);

require Exporter;

@ISA	= qw(Exporter);
@EXPORT	= qw($key $plaintext %ciphertext @ciphers %padding @padstyles);

$key = "This is an at least 56 Byte long test key!!! It really is.";	# binary would be better

$plaintext = "This is just some dummy text!\n";

%ciphertext =
(
	'Dummy'			=> '00000000000000000b1b53155453030831480d064d040a00150b5815552a6e67',

	'Blowfish'		=> '52a037af4a2aea2d10cc09183b433f1a12c5ce734067d597da040861fed3ae61',
	'Blowfish_PP'		=> '52a037af4a2aea2d10cc09183b433f1a12c5ce734067d597da040861fed3ae61',
	'Camellia'		=> '37adb2c1ba5a6be79c7b886cdd432853bd6dfa6eac8a02cd8a85174ecd17ed12',
	'Camellia_PP'		=> '37adb2c1ba5a6be79c7b886cdd432853bd6dfa6eac8a02cd8a85174ecd17ed12',
	'CAST5'			=> '811a469a643c4f1e9c0236ab1a76682bb918a95c33c7663203fb163df0eb264f',
	'CAST5_PP'		=> '811a469a643c4f1e9c0236ab1a76682bb918a95c33c7663203fb163df0eb264f',
	'DES'			=> 'a47b1b2c90fb3b7a7367c1844d3d07e620b943fdc6728a05e5cf69afe49da6e8',
	'DES_PP'		=> 'a47b1b2c90fb3b7a7367c1844d3d07e620b943fdc6728a05e5cf69afe49da6e8',
	'DES_EDE3'		=> '9844c0d93c2d8cdf88203d169d2decc3d1d7212b6dfe747e3b10974657d96ec5',
	'DES_EEE3'		=> '6bcbb21b218f84165a5c8b18627d4e68ed4d1475051a7c6ae74264e4ad49710f',
	'IDEA'			=> '58678df1889afedbd336fe64a6fb39ab08156a201f832e9a8a2fd460251ebe24',
	'NULL'			=> '54686973206973206a75737420736f6d652064756d6d792074657874210a0202',
	'OpenSSL::AES'		=> 'a7acc570d3d8fc33e215e369fbc3d6552cfb2c2bf39b5064d5310c0d32eedeb2',	# same as Rijndael
#	'OpenSSL::Blowfish'	=> '1d766228b195088dbf7c82cf444a5d251c9def80b291ff982ab91f6a2500cafe',	# differing from Blowfish!
	'RC6'			=> '9f1a68eec264ef9434e7585fede0c23f53d8e8ae2531b945682c924328d60632',
	'Rijndael'		=> 'a7acc570d3d8fc33e215e369fbc3d6552cfb2c2bf39b5064d5310c0d32eedeb2',
	'Rijndael_PP'		=> 'a7acc570d3d8fc33e215e369fbc3d6552cfb2c2bf39b5064d5310c0d32eedeb2',

#	Serpent taken out. The latest version is from 2002 and it is broken on many platforms.
#	'Serpent'		=> '0f9516eb0e8ce6cb18768066921ec8456a184458620c1c9aaf338929fec46686',

	'Skip32'		=> '121fe77e2e75e083d1ec5efc3e028f792982ddc07f44e1978faa58cb56ec8497',
	'Twofish'		=> '4873e7735f4c976b4ba9f041d5fc82dea713d312959ad1a710225f0cbc8cf706',

#	Twofish2 taken out. In older versions there is a serious bug in the implementation,
#	so on environments using such versions, this test might report an error.
#	'Twofish2'		=> '0958c674179aefaf13de8b25a613174dc40a90b80918bce55d314c86ecd3db45',

	'XTEA'			=> '6e2ca14be43fde47d5d456f8402b2a9c98984293b5cb4bb2b186113044098c03',
	'XTEA_PP'		=> '6e2ca14be43fde47d5d456f8402b2a9c98984293b5cb4bb2b186113044098c03',
); 

@ciphers = sort keys %ciphertext;

%padding =
(
	'standard'		=> "\x02\x02",
	'zeroes'		=> "\x00\x02",
	'oneandzeroes'		=> "\x80\x00",
	'rijndael_compat'	=> "\x80\x00",
	'space'			=> "\x20\x20",
	'null'			=> "\x00\x00",
);
 
@padstyles = sort keys %padding;

'END';
