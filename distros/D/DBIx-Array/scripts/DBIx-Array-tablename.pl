#!/usr/bin/perl

=head1 NAME

DBIx-Array-tablename.pl - DBIx::Array HTML Table Example

=head1 LIMITATIONS

Oracle SQL Syntax

=cut

use strict;
use warnings;
use DBIx::Array;

my $connect=shift or die("$0 connection account password"); #written for DBD::Oracle
my $user=shift or die("$0 connection account password");
my $pass=shift or die("$0 connection account password");

my $dba=DBIx::Array->new;
$dba->connect($connect, $user, $pass, {AutoCommit=>1, RaiseError=>1});

print &tablename($dba->sqlarrayarrayname(&sql, 15)), "\n";
  
sub tablename {
  use CGI; my $html=CGI->new(""); #you would pass this reference
  return $html->table($html->Tr([map {$html->td($_)} @_]));
} 
  
sub sql { #Oracle SQL
  return q{SELECT LEVEL AS "Number",
                  TRIM(TO_CHAR(LEVEL, 'rn')) as "Roman Numeral"
             FROM DUAL CONNECT BY LEVEL <= ? ORDER BY LEVEL};
}

=head1 OUTPUT

=begin html

<table><tr><td>Number</td> <td>Roman Numeral</td></tr> <tr><td>1</td> <td>i</td></tr> <tr><td>2</td> <td>ii</td></tr> <tr><td>3</td> <td>iii</td></tr> <tr><td>4</td> <td>iv</td></tr> <tr><td>5</td> <td>v</td></tr> <tr><td>6</td> <td>vi</td></tr> <tr><td>7</td> <td>vii</td></tr> <tr><td>8</td> <td>viii</td></tr> <tr><td>9</td> <td>ix</td></tr> <tr><td>10</td> <td>x</td></tr> <tr><td>11</td> <td>xi</td></tr> <tr><td>12</td> <td>xii</td></tr> <tr><td>13</td> <td>xiii</td></tr> <tr><td>14</td> <td>xiv</td></tr> <tr><td>15</td> <td>xv</td></tr></table>

=end html

