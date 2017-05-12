#! /usr/local/bin/perl

# The script itself would of course run with -w.  However, at least
# GOST_PP throws so many warnings, that the test results would suffer
# from writing to stderr.

use strict;

use Cwd qw (getcwd abs_path);

BEGIN {
	unshift @INC, abs_path (getcwd . '/../lib');
}

use IO::File;

use Benchmark qw (countit);

# How many seconds to run for each module?
use constant SECONDS => 2;

sub by_name;
sub by_ekeys;
sub by_dkeys;
sub by_bytes_encrypt;
sub by_bytes_decrypt;
sub by_blocks_encrypt;
sub by_blocks_decrypt;
sub by_blocksize;
sub by_keysize;
sub gen_html;

my $now = localtime;
chomp $now;

# Which algorithms should be tested?
my @tests = (
		 { name => 'Twofish_PP', keysize => 16, blocksize => 16 },
         { name => 'Twofish_PP', keysize => 24, blocksize => 16 },
         { name => 'Twofish_PP', keysize => 32, blocksize => 16 },
         { name => 'Twofish',	keysize => 16, blocksize => 16 },
		 { name => 'Twofish',	keysize => 24, blocksize => 16 },
		 { name => 'Twofish',	keysize => 32, blocksize => 16 },
		 { name => 'Twofish2', keysize => 16, blocksize => 16	},
		 { name => 'Twofish2', keysize => 24,	blocksize => 16	},
		 { name => 'Twofish2', keysize => 32,	blocksize => 16	},
		 { name => 'Rijndael', keysize => 16,	blocksize => 16	},
		 { name => 'Rijndael', keysize => 24,	blocksize => 16	},
		 { name => 'Rijndael', keysize => 32,	blocksize => 16	},
	# { name => 'Rijndael_PP',	keysize => 16, blocksize => 16 },
	# { name => 'Rijndael_PP',	keysize => 24, blocksize => 16 },
		 { name => 'Rijndael_PP', keysize => 32, blocksize => 16 },
		 { name => 'Blowfish', keysize => 8, blocksize => 8	},
		 { name => 'Blowfish', keysize => 16, blocksize => 8	},
		 { name => 'Blowfish', keysize => 24, blocksize => 8	},
		 { name => 'Blowfish', keysize => 32, blocksize => 8	},
		 { name => 'Blowfish', keysize => 40, blocksize => 8	},
		 { name => 'Blowfish', keysize => 48, blocksize => 8	},
		 { name => 'Blowfish', keysize => 56, blocksize => 8	},
		 { name => 'Blowfish_PP', keysize => 8, blocksize => 8	},
		 { name => 'Blowfish_PP', keysize => 16, blocksize => 8	},
		 { name => 'Blowfish_PP', keysize => 24, blocksize => 8	},
		 { name => 'Blowfish_PP', keysize => 32, blocksize => 8	},
		 { name => 'Blowfish_PP', keysize => 40, blocksize => 8	},
		 { name => 'Blowfish_PP', keysize => 48, blocksize => 8	},
		 { name => 'Blowfish_PP', keysize => 56, blocksize => 8	},
		 { name => 'DES', keysize => 8, blocksize => 8 },
		 { name => 'DES_PP', keysize => 8, blocksize => 8 },
		 { name => 'IDEA', keysize => 16, blocksize => 8 },
		 { name => 'Noekeon', keysize => 16, blocksize => 16 },		 
		 { name => 'NULL', keysize => 16, blocksize => 16, language => 'Perl' },
		 { name => 'Misty1', keysize => 16, blocksize => 8 },
		 { name => 'Loki97', keysize => 16, blocksize => 16 },
		 { name => 'GOST', keysize => 32, blocksize => 8 },
	     { name => 'GOST_PP', keysize => 32, blocksize => 8 },
		 { name => 'DES_EEE3', keysize => 24, blocksize => 8 },
		 { name => 'DES_EDE3', keysize => 24, blocksize => 8 },
		 { name => 'Khazad', keysize => 16, blocksize => 8 },
		 { name => 'Camellia', keysize => 16, blocksize => 16 },
		 { name => 'CAST5', keysize => 5, blocksize => 8 },
		 { name => 'CAST5', keysize => 8, blocksize => 8 },
		 { name => 'CAST5', keysize => 16, blocksize => 8 },
		 { name => 'CAST5_PP', keysize => 5, blocksize => 8 },
		 { name => 'CAST5_PP', keysize => 8, blocksize => 8 },
		 { name => 'CAST5_PP', keysize => 16, blocksize => 8 },
		 { name => 'Anubis', keysize => 16, blocksize => 16 },
	# Other keysizes not supported by Perl version.
	# { name => 'Anubis', keysize => 20, blocksize => 16 },
	# { name => 'Anubis', keysize => 24, blocksize => 16 },
	# { name => 'Anubis', keysize => 28, blocksize => 16 },
	# { name => 'Anubis', keysize => 32, blocksize => 16 },
	# { name => 'Anubis', keysize => 36, blocksize => 16 },
	# { name => 'Anubis', keysize => 40, blocksize => 16 },
	# FIXME: Maybe test with lesser rounds, but the performance
	# should actually change in a linear way anyhow...
         { name => 'Square', keysize => 16, blocksize => 16 },
         { name => 'Skipjack', keysize => 10, blocksize => 8 },
		 { name => 'Shark', keysize => 16, blocksize => 8 },
		 { name => 'Serpent', keysize => 16, blocksize => 16	},
		 { name => 'Serpent', keysize => 24, blocksize => 16	},
		 { name => 'Serpent', keysize => 32, blocksize => 16	},
		 { name => 'Rainbow', keysize => 16, blocksize => 16	},
		 { name => 'TEA', keysize => 16, blocksize => 8 },
			 );

#$#tests = 5;

foreach my $test (@tests) {
	eval "require Crypt::$test->{name}";
    if ($@) {
		print STDERR "Crypt::$test->{name} is not available - skipped\n";
		next;
	}

    $test->{key} = 'k' x $test->{keysize};
	$test->{namespace} = "Crypt::$test->{name}";

	# Some modules (IDEA) are not in the Crypt:: namespace.
	eval "$test->{namespace}->new ('$test->{key}')";
	if ($@) {
		$test->{namespace} = $test->{name};
		eval "$test->{namespace}->new ('$test->{key}')";
		if ($@) {
			# No way.
			print STDERR "$test->{name} cannot be loaded - skipped\n";
			next;
		}
	}

	$test->{block} = 'b' x $test->{blocksize};
    $test->{version} = eval "\$$test->{namespace}::VERSION";
    $test->{version} = '?' unless defined $test->{version};

    unless ($test->{language}) {
		$test->{language} = $test->{name} =~ /_PP$/ ? 'Perl' : 'C'
	}
}

foreach my $test (@tests) {
	next unless $test->{block};

	my $module = "$test->{namespace}";	
	my ($t, $cipher, $bytes);

    print <<EOF;

*** $test->{name} (ks$test->{keysize}/bs$test->{blocksize}) ***
Encrypting blocks of $test->{blocksize} bytes.
EOF

	$cipher = $module->new ($test->{key});
	$t = countit SECONDS, sub { $cipher->encrypt ($test->{block}) };
	$test->{count_encrypt} = $test->{real_count_encrypt} = $t->iters;
	$test->{time_encrypt} = $t->cpu_a;

	$test->{bytes_encrypt} = $test->{blocksize} * $test->{count_encrypt};
	print "  $test->{bytes_encrypt} bytes ($test->{count_encrypt} "
		. "$test->{blocksize}-byte blocks) in $test->{time_encrypt} seconds.\n";
	$test->{count_encrypt} = sprintf '%.2f', $t->iters / $t->cpu_a;
	$test->{bytes_encrypt} = sprintf '%.2f', $test->{bytes_encrypt} / $t->cpu_a;

	print "Decrypting blocks of $test->{blocksize} bytes.\n";
	$cipher = $module->new ($test->{key});
	$t = countit SECONDS, sub { $cipher->decrypt ($test->{block}) };
	$test->{count_decrypt} = $test->{real_count_decrypt} = $t->iters;
	$test->{time_decrypt} = $t->cpu_a;
	$test->{bytes_decrypt} = $test->{blocksize} * $test->{count_decrypt};
	print "  $test->{bytes_decrypt} bytes ($test->{count_decrypt} "
		. "$test->{blocksize}-byte blocks) in $test->{time_decrypt} seconds.\n";
	$test->{count_decrypt} = sprintf '%.2f', $t->iters / $t->cpu_a;
	$test->{bytes_decrypt} = sprintf '%.2f', $test->{bytes_decrypt} / $t->cpu_a;

	print "Generating $test->{keysize}-bit encryption keys.\n";
	$t = countit SECONDS, sub { 
		$module->new ($test->{key})->encrypt ($test->{block}) 
	};
	$test->{count_ekeys} = $t->iters;
	$test->{time_ekeys} = $t->cpu_a;
	print "  $test->{count_ekeys} in $test->{time_ekeys} seconds.\n";
    $test->{count_ekeys} = sprintf '%.2f', ($t->iters / $t->cpu_a);

    print "Generating $test->{keysize}-bit decryption keys.\n";
	$t = countit SECONDS, sub { 
		$module->new ($test->{key})->decrypt ($test->{block}) 
	};
	$test->{count_dkeys} = $t->iters;
	$test->{time_dkeys} = $t->cpu_a;
	print "  $test->{count_dkeys} in $test->{time_dkeys} seconds.\n";
    $test->{count_dkeys} = sprintf '%.2f', ($t->iters / $t->cpu_a);
}

sub by_name
{
	my $result = $a->{name} cmp $b->{name};
	return $result if $result;
	$result = $b->{keysize} <=> $a->{keysize};
	return $result if $result;
	return $b->{blocksize} <=> $a->{blocksize};
}

sub by_ekeys
{
	my $result = $b->{count_ekeys} <=> $a->{count_ekeys};
	return $result if $result;
	return by_name;
}

sub by_dkeys
{
	my $result = $b->{count_dkeys} <=> $a->{count_dkeys};
	return $result if $result;
	return by_name;
}

sub by_bytes_encrypt
{
	my $result = $b->{bytes_encrypt} <=> $a->{bytes_encrypt};
	return $result if $result;
	return by_name;
}

sub by_bytes_decrypt
{
	my $result = $b->{bytes_decrypt} <=> $a->{bytes_decrypt};
	return $result if $result;
	return by_name;
}

sub by_blocks_encrypt
{
	my $result = $b->{count_encrypt} <=> $a->{count_encrypt};
	return $result if $result;
	return by_name;
}

sub by_blocks_decrypt
{
	my $result = $b->{count_decrypt} <=> $a->{count_decrypt};
	return $result if $result;
	return by_name;
}

sub by_blocksize
{
	my $result = $b->{blocksize} <=> $a->{blocksize};
	return $result if $result;
	return by_name;
}

sub by_keysize
{
	my $result = $b->{keysize} <=> $a->{keysize};
	return $result if $result;
	return by_name;
}

gen_html \&by_name, "by name", "";
gen_html \&by_ekeys, "by encryption keys", "_by_ekeys";
gen_html \&by_dkeys, "by decryption keys", "_by_dkeys";
gen_html \&by_bytes_encrypt, "by encrypted bytes", "_by_ebytes";
gen_html \&by_bytes_decrypt, "by decrypted bytes", "_by_dbytes";
gen_html \&by_blocks_encrypt, "by encrypted blocks", "_by_eblocks";
gen_html \&by_blocks_decrypt, "by decrypted blocks", "_by_dblocks";
gen_html \&by_blocksize, "by blocksize", "_by_blksize";
gen_html \&by_keysize, "by blocksize", "_by_keysize";
print "Summary in benchmark.html\n";

sub gen_html
{
	my ($sort, $sort_title, $suffix) = @_;

	my $html = <<EOF;
<?xml version="1.0" encoding="us-ascii"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=us-ascii"/>
    <meta name="generator" content="$0"/>
    <title>Benchmark Results ($now) $sort_title</title>    
	<style type="text/css">
body {
        font-family: Monospace;
}
td {
	text-align: right;
    padding-left: 1em;
    padding-right: 3pt;
}
th {
	text-align: left;
    padding-left: 1em;
    padding-right: 3pt;
    background-color: #d0c4b6;
}
.name {
	text-align: left;
	background-color: #fffff2;
}
th.name {
	text-align: left;
    font-weight: bold;
	background-color: #d0c4b6;
}
.other {
	background-color: #fffff2;
}
.twofish {
        background-color: #eee2d4;
}
.twofish_name {
        text-align: left;
        background-color: #eee2d4;
}
    </style>
  </head>
  <body>
    <a name="top"><!-- --></a>
    <h1>Benchmark Results ($now)</h1>
    <h2>Sorted $sort_title, time per test: @{[SECONDS]} s</h2>
    <table border="1" summary="Benchmark">
      <tbody>
        <tr>
          <th rowspan="2" colspan="2" class="name">
	        <a href="benchmark.html">Module</a>
          </th>
          <th rowspan="2" class="name">
            Language<super>[<a href="#lang">1</a>]</super>
          </th>
          <th rowspan="2">
	        <a href="benchmark_by_blksize.html">Blocksize</a>
          </th>
          <th rowspan="2">
	        <a href="benchmark_by_keysize.html">Keysize</a>
          </th>
          <th colspan="2">Keys/s<super>[<a href="#keys">2</a>]</super></th>
          <th colspan="2">Encrypt</th>
          <th colspan="2">Decrypt</th>
        </tr>
        <tr>
          <th>
            <a href="benchmark_by_ekeys.html">encrypt</a>
          </th>
          <th>
            <a href="benchmark_by_dkeys.html">decrypt</a>
          </th>
          <th>
            <a href="benchmark_by_ebytes.html">bytes/s</a>
          </th>
          <th>
            <a href="benchmark_by_eblocks.html">blocks/s</a>
          </th>
          <th>
            <a href="benchmark_by_dbytes.html">bytes/s</a>
          </th>
          <th>
            <a href="benchmark_by_dblocks.html">blocks/s</a>
          </th>
        </tr>
EOF

	my $count = 0;
    foreach my $test (sort $sort @tests) {
		next unless $test->{block};
		++$count;

		my $name_class = 'Twofish_PP' eq $test->{name} ?
			'twofish_name' : 'name';
		my $class = 'Twofish_PP' eq $test->{name} ? 
			'twofish' : 'other';
		$html .= <<EOF;
        <tr>
            <td class="$class">$count</td>
			<td class="$name_class">$test->{name} v$test->{version}</td>
            <td class="$class">$test->{language}</td>
			<td class="$class">$test->{blocksize}</td>
			<td class="$class">$test->{keysize}</td>
			<td class="$class">$test->{count_ekeys}</td>
			<td class="$class">$test->{count_dkeys}</td>
			<td class="$class">$test->{bytes_encrypt}</td>
			<td class="$class">$test->{count_encrypt}</td>
			<td class="$class">$test->{bytes_decrypt}</td>
			<td class="$class">$test->{count_decrypt}</td>
        </tr>
EOF
    }

    $html .= <<EOF;
      </tbody>
    </table>
    <hr />
<p>
Remarks:<br />
<dl>
<dt><a name="lang">[1]</a></dt>
<dd>Some modules, like Crypt::DES_EEE3 or Crypt::DES_EDE3 are actually
pure Perl modules but are implemented as a wrapper around XS modules.
These are still listed here as implemented in C.
<a href="#top">back</a></dd>

<dt><a name="keys">[2]</a></dt>
<dd>One test cycle for key generation actually consists of a constructor
call followed by one encryption resp. decryption operation, since a module
may decide to postpone the key scheduling until the direction is fixed.
The number is therefore an indicator for the encryption/decryption 
performance for small chunks of data.
<a href="#top">back</a></dd>
</p>
  </body>
</html>
EOF

	local *HANDLE;
    open HANDLE, ">benchmark$suffix.html" or
	die "cannot open 'benchmark$suffix.html' for writing: $!";
    print HANDLE $html or
	    die "cannot write to 'benchmark$suffix.html': $!";
    close HANDLE or
	    die "cannot close 'benchmark$suffix.html': $!";
    print "wrote 'benchmark$suffix.html'\n";
}

=cut
Local Variables:
mode: perl
perl-indent-level: 4
perl-continued-statement-offset: 4
perl-continued-brace-offset: 0
perl-brace-offset: -4
perl-brace-imaginary-offset: 0
perl-label-offset: -4
cperl-indent-level: 4
cperl-continued-statement-offset: 2
tab-width: 4
End:
=cut
