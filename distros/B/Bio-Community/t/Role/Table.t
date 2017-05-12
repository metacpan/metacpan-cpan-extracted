use strict;
use warnings;
use Bio::Root::Test;

use_ok($_) for qw(
    t::Role::TestTable
);


my ($in, $out);

my $file = test_output_file();


# Read tab-delimited file 

ok $in = t::Role::TestTable->new(
   -file => test_input_file('table.txt'),
), 'Read table';
isa_ok $in, 't::Role::TestTable';
is $in->delim, "\t";
is $in->_get_max_col , 3;
is $in->_get_max_line, 4;

is $in->_get_value(1, 1), 'Species';
is $in->_get_value(1, 2), 'gut';
is $in->_get_value(1, 3), 'soda lake';
is $in->_get_value(2, 1), 'Streptococcus';
is $in->_get_value(2, 2),  241;
is $in->_get_value(2, 3),  334;
is $in->_get_value(3, 1), 'Goatpox virus';
is $in->_get_value(3, 2),  '"0"';
is $in->_get_value(3, 3),  1023.9;
is $in->_get_value(4, 1), 'Lumpy skin disease virus';
is $in->_get_value(4, 2), '';
is $in->_get_value(4, 3),  123;

is $in->_get_value(5,  1), undef;
is $in->_get_value(1,  4), undef;
is $in->_get_value(6,  1), undef;
is $in->_get_value(1, 10), undef;

$in->close;


# Read another tab-delimited file

ok $in = t::Role::TestTable->new(
   -file => test_input_file('table_2.txt'),
), 'Read another table';
is $in->delim, "\t";
is $in->_get_max_col , 3;
is $in->_get_max_line, 4;

is $in->_get_value(1, 1), 'Species';
is $in->_get_value(1, 2), 'gut';
is $in->_get_value(1, 3), 'soda lake';
is $in->_get_value(2, 1), 'Streptococcus';
is $in->_get_value(2, 2),  241;
is $in->_get_value(2, 3),  334;
is $in->_get_value(3, 1), 'Goatpox virus';
is $in->_get_value(3, 2),  0;
is $in->_get_value(3, 3),  1023.9;
is $in->_get_value(4, 1), 'Lumpy skin disease virus';
is $in->_get_value(4, 2),  39;
is $in->_get_value(4, 3),  123;

is $in->_get_value(5, 1), undef;
is $in->_get_value(1, 4), undef;

$in->close;


# Read tab-delimited file with extra line (with Linux EOL)

ok $in = t::Role::TestTable->new(
   -file => test_input_file('table_extra_line.txt'),
   -start_line => 2,
), 'Read table with extra line';

isa_ok $in, 't::Role::TestTable';
is $in->delim, "\t";
is $in->_get_max_col , 3;
is $in->_get_max_line, 4;
is $in->_get_start_content, "--- content below ---\n";

$in->close;


# Read tab-delimited file (with Windows EOL)

ok $in = t::Role::TestTable->new(
   -file => test_input_file('table_win.txt'),
), 'Read Win table';
is $in->delim, "\t";
is $in->_get_max_col , 3;
is $in->_get_max_line, 4;

is $in->_get_value(1, 1), 'Species';
is $in->_get_value(1, 2), 'gut';
is $in->_get_value(1, 3), 'soda lake';
is $in->_get_value(2, 1), 'Streptococcus';
is $in->_get_value(2, 2),  241;
is $in->_get_value(2, 3),  334;
is $in->_get_value(3, 1), 'Goatpox virus';
is $in->_get_value(3, 2),  '"0"';
is $in->_get_value(3, 3),  1023.9;
is $in->_get_value(4, 1), 'Lumpy skin disease virus';
is $in->_get_value(4, 2),  '';
is $in->_get_value(4, 3),  123;

is $in->_get_value(5, 1), undef;
is $in->_get_value(1, 4), undef;

$in->close;


TODO: {
   # Read tab-delimited file (with Mac EOL)
   local $TODO = 'Mac-formatted files not supported yet';
   # I see no obvious way to support them using Bioperl. If I make
   # B::C::Role::Table use $Bio::Root::IO::HAS_EOL, then there is no way to
   # determine the number of EOL characters on each line, which is a problem

   ok $in = t::Role::TestTable->new(
      -file => test_input_file('table_mac.txt'),
   ), 'Read Mac table';
   is $in->delim, "\t";
   is $in->_get_max_col , 3;
   is $in->_get_max_line, 4;

   is $in->_get_value(1, 1), 'Species';
   is $in->_get_value(1, 2), 'gut';
   is $in->_get_value(1, 3), 'soda lake';
   is $in->_get_value(2, 1), 'Streptococcus';
   is $in->_get_value(2, 2),  241;
   is $in->_get_value(2, 3),  334;
   is $in->_get_value(3, 1), 'Goatpox virus';
   is $in->_get_value(3, 2),  '"0"';
   is $in->_get_value(3, 3),  1023.9;
   is $in->_get_value(4, 1), 'Lumpy skin disease virus';
   is $in->_get_value(4, 2),  '';
   is $in->_get_value(4, 3),  123;

   is $in->_get_value(5, 1), undef;
   is $in->_get_value(1, 4), undef;

   $in->close;
}


# Write and read tab-delimited file

ok $out = t::Role::TestTable->new( -file => '>'.$file ), 'Write tab-delimited table';
is $out->delim, "\t";
is $out->_get_max_col , 0;
is $out->_get_max_line, 0;

# Add a first column... and delete it
ok $out->_set_value(1, 1, 'Species');
is $out->_get_max_col, 1;
$out->_delete_col(1);
is $out->_get_max_col, 0;

# More table content
ok $out->_set_value(1, 1, 'Species');
ok $out->_set_value(1, 2, 'gut');
ok $out->_set_value(1, 3, 'soda lake');
ok $out->_set_value(2, 3,  1023.9);
ok $out->_set_value(2, 2,  '"0"');
ok $out->_set_value(2, 1, 'Goatpox virus');
ok $out->_set_value(3, 1, 'Lumpy skin disease virus');
ok $out->_set_value(3, 2, '');
ok $out->_set_value(3, 3,  123);
is $out->_get_max_line, 3;
ok $out->_insert_line(2, ['Streptococcus', 241, 334]);
is $out->_get_max_line, 4;

# Add a fourth column... and delete it
is $out->_get_max_col, 3;
ok $out->_set_value(1, 4, 'some');
ok $out->_set_value(2, 4, 'thing');
ok $out->_set_value(3, 4, 'or');
ok $out->_set_value(4, 4, 'other');
is $out->_get_max_col, 4;
ok $out->_delete_col(4);
is $out->_get_max_col, 3;

$out->close;

ok $in = t::Role::TestTable->new( -file => $file ), 'Re-read tab-delimited table';
is $in->delim, "\t";
is $in->_get_max_col , 3;
is $in->_get_max_line, 4;

is $in->_get_value(1, 1), 'Species';
is $in->_get_value(1, 2), 'gut';
is $in->_get_value(1, 3), 'soda lake';
is $in->_get_value(2, 1), 'Streptococcus';
is $in->_get_value(2, 2),  241;
is $in->_get_value(2, 3),  334;
is $in->_get_value(3, 1), 'Goatpox virus';
is $in->_get_value(3, 2),  '"0"';
is $in->_get_value(3, 3),  1023.9;
is $in->_get_value(4, 1), 'Lumpy skin disease virus';
is $in->_get_value(4, 2), '';
is $in->_get_value(4, 3),  123;

is $in->_get_value(5, 1), undef;
is $in->_get_value(1, 4), undef;
is $in->_get_value(6, 1), undef;
is $in->_get_value(1, 10), undef;

# Note: zero or negative numbers are not valid input and cause an exception
#is $in->_get_value(6, 0), undef; 
#is $in->_get_value(0, 10), undef;

$in->close;
unlink $file;


# Write and read tab-delimited file (again, but in a different order)

ok $out = t::Role::TestTable->new( -file => '>'.$file ), 'Write tab-delimited table again';
is $out->delim, "\t";
is $out->_get_max_col , 0;
is $out->_get_max_line, 0;

ok $out->_set_value(2, 2,  241);
ok $out->_set_value(1, 2, 'gut');
ok $out->_set_value(1, 1, 'Species');
ok $out->_set_value(3, 1, 'Goatpox virus');
ok $out->_set_value(4, 1, 'Lumpy skin disease virus');
ok $out->_set_value(3, 2,  '"0"');
ok $out->_set_value(1, 3, 'soda lake');
ok $out->_set_value(3, 3,  1023.9);
ok $out->_set_value(4, 2, '');
ok $out->_set_value(4, 3,  123);
ok $out->_set_value(2, 1, 'Streptococcus');
ok $out->_set_value(2, 3,  334);

$out->close;

ok $in = t::Role::TestTable->new( -file => $file ), 'Re-read tab-delimited table again';
is $in->delim, "\t";
is $in->_get_max_col , 3;
is $in->_get_max_line, 4;

is $in->_get_value(1, 1), 'Species';
is $in->_get_value(1, 2), 'gut';
is $in->_get_value(1, 3), 'soda lake';
is $in->_get_value(2, 1), 'Streptococcus';
is $in->_get_value(2, 2),  241;
is $in->_get_value(2, 3),  334;
is $in->_get_value(3, 1), 'Goatpox virus';
is $in->_get_value(3, 2),  '"0"';
is $in->_get_value(3, 3),  1023.9;
is $in->_get_value(4, 1), 'Lumpy skin disease virus';
is $in->_get_value(4, 2), '';
is $in->_get_value(4, 3),  123;

is $in->_get_value(5, 1), undef;
is $in->_get_value(1, 4), undef;
is $in->_get_value(6, 1), undef;
is $in->_get_value(1, 10), undef;

$in->close;
unlink $file;


# Write and read double-space-delimited file

ok $out = t::Role::TestTable->new(
   -file  => '>'.$file,
   -delim => '  ',
), 'Write double-space delimited table';

ok $out->_insert_line(1, ['Species', 'gut', 'soda_lake']);
ok $out->_set_value(2, 1, 'Streptococcus');
ok $out->_set_value(2, 2,  241);
ok $out->_set_value(2, 3,  334);
ok $out->_set_value(3, 1, 'Goatpox_virus');
ok $out->_set_value(3, 2,  '"0"');
ok $out->_set_value(3, 3,  1023.9);
ok $out->_insert_line(4, ['Lumpy_skin_disease_virus', '', 123]);

$out->close;

ok $in = t::Role::TestTable->new(
   -file  => $file,
   -delim => '  ',
), 'Re-read double-space delimited table';
is $in->delim, '  ';
is $in->_get_max_col , 3;
is $in->_get_max_line, 4;

is $in->_get_value(1, 1), 'Species';
is $in->_get_value(1, 2), 'gut';
is $in->_get_value(1, 3), 'soda_lake';
is $in->_get_value(2, 1), 'Streptococcus';
is $in->_get_value(2, 2),  241;
is $in->_get_value(2, 3),  334;
is $in->_get_value(3, 1), 'Goatpox_virus';
is $in->_get_value(3, 2),  '"0"';
is $in->_get_value(3, 3),  1023.9;
is $in->_get_value(4, 1), 'Lumpy_skin_disease_virus';
is $in->_get_value(4, 2), '';
is $in->_get_value(4, 3),  123;

is $in->_get_value(5, 1), undef;
is $in->_get_value(1, 4), undef;

$in->close;
unlink $file;


# Write and read file with specified string for missing abundance

ok $out = t::Role::TestTable->new(
   -file           => '>'.$file,
   -missing_string => 'n/a',
), 'Write file with specified missing abundance string';
is $out->missing_string, 'n/a';

ok $out->_set_value(1, 1, 'Species');
ok $out->_set_value(1, 2, 'gut');
ok $out->_set_value(1, 3, 'soda_lake');
ok $out->_set_value(2, 1, 'Streptococcus');
ok $out->_set_value(2, 2,  241);
ok $out->_set_value(2, 3,  334);
ok $out->_set_value(3, 1, 'Goatpox_virus');
#ok $out->_set_value(3, 2,  '"0"');
ok $out->_set_value(3, 3,  1023.9);
ok $out->_set_value(4, 1, 'Lumpy_skin_disease_virus');
#ok $out->_set_value(4, 2, '');
ok $out->_set_value(4, 3,  123);

$out->close;

ok $in = t::Role::TestTable->new(
   -file  => $file,
), 'Re-read file with specified missing abundance string';
is $in->_get_max_col , 3;
is $in->_get_max_line, 4;

is $in->_get_value(1, 1), 'Species';
is $in->_get_value(1, 2), 'gut';
is $in->_get_value(1, 3), 'soda_lake';
is $in->_get_value(2, 1), 'Streptococcus';
is $in->_get_value(2, 2),  241;
is $in->_get_value(2, 3),  334;
is $in->_get_value(3, 1), 'Goatpox_virus';
is $in->_get_value(3, 2), 'n/a';
is $in->_get_value(3, 3),  1023.9;
is $in->_get_value(4, 1), 'Lumpy_skin_disease_virus';
is $in->_get_value(4, 2), 'n/a';
is $in->_get_value(4, 3),  123;

is $in->_get_value(5, 1), undef;
is $in->_get_value(1, 4), undef;

$in->close;
unlink $file;


# Write and read table with a single line

ok $out = t::Role::TestTable->new( -file => '>'.$file ), 'Write single-line table';

ok $out->_set_value(1, 1, 'sp.');
ok $out->_set_value(1, 1, 'Species');
ok $out->_set_value(1, 2, 'gut');
ok $out->_set_value(1, 3, 'soda lake');

$out->close;

ok $in = t::Role::TestTable->new( -file => $file ), 'Re-read single-line table';
is $in->delim, "\t";
is $in->_get_max_col , 3;
is $in->_get_max_line, 1;

is $in->_get_value(1, 3), 'soda lake';
is $in->_get_value(1, 1), 'Species';
is $in->_get_value(1, 2), 'gut';

is $in->_get_value(1, 4), undef;
is $in->_get_value(2, 1), undef;

$in->close;
unlink $file;


# Write and read table with a single column

ok $out = t::Role::TestTable->new( -file => '>'.$file ), 'Write single-column table';

ok $out->_set_value(1, 1, 'Species');
ok $out->_set_value(3, 1, 'Goatpox virus');
ok $out->_set_value(2, 1, 'Streptococcus');
ok $out->_set_value(4, 1, 'Lumpy skin disease virus');

$out->close;

ok $in = t::Role::TestTable->new( -file => $file ), 'Re-read single-column table';
ok $in->_read_table;
is $in->delim, "\t";
is $in->_get_max_col , 1;
is $in->_get_max_line, 4;

is $in->_get_value(1, 1), 'Species';
is $in->_get_value(2, 1), 'Streptococcus';
is $in->_get_value(3, 1), 'Goatpox virus';
is $in->_get_value(4, 1), 'Lumpy skin disease virus';

is $in->_get_value(5, 1), undef;
is $in->_get_value(1, 2), undef;

$in->close;
unlink $file;


# Write and read table that does not span the entire file

ok $out = t::Role::TestTable->new(
   -file       => '>'.$file,
), 'Write table that does not span the entire file';

$out->_print("<table>\n"); ### should return true
ok $out->_set_value(1, 1, 'Streptococcus');
ok $out->_set_value(1, 2,  241);
ok $out->_set_value(1, 3,  334);
ok $out->_set_value(2, 1, 'Goatpox virus');
ok $out->_set_value(2, 2,  '"0"');
ok $out->_set_value(2, 3,  1023.9);
ok $out->_write_table;
$out->_print("</table>\n"); ### should return true
$out->close;

ok $in = t::Role::TestTable->new(
   -file       => $file,
   -start_line => 2, 
   -end_line   => 3,
), 'Re-read table that does not span the entire file';
is $in->delim, "\t";
is $in->_get_max_col , 3;
is $in->_get_max_line, 2;

is $in->_get_value(1, 1), 'Streptococcus';
is $in->_get_value(1, 2),  241;
is $in->_get_value(1, 3),  334;
is $in->_get_value(2, 1), 'Goatpox virus';
is $in->_get_value(2, 2),  '"0"';
is $in->_get_value(2, 3),  1023.9;

is $in->_get_value(3, 1), undef;
is $in->_get_value(1, 4), undef;

$in->close;
unlink $file;

done_testing();

