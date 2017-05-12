#!/usr/bin/perl
use strict;
use warnings;
use DBIx::Array;
use Data::Dumper;
$|=1;

=head1 NAME

DBIx-Array-bind_param.pl - DBIx::Array Bind Examples

=head1 LIMITATIONS

Oracle SQL Syntax

=cut

my $connect=shift or die("$0 connection account password"); #written for DBD::Oracle
my $user=shift or die("$0 connection account password");
my $pass=shift or die("$0 connection account password");

my $table="";
$table="FROM DUAL" if $connect=~m/Oracle/i;

my $dba=DBIx::Array->new;
$dba->connect($connect, $user, $pass, {AutoCommit=>1, RaiseError=>1});

print "Select\n";

my $data=$dba->sqlarrayarrayname(qq{SELECT 'A' AS AAA $table});

print Dumper($data);

print "Select positional bind\n";

$data=$dba->sqlarrayarrayname(qq{SELECT ? AS BBB $table}, ["B"]);

print Dumper($data);

print "Select positional bind\n";

$data=$dba->sqlarrayarrayname(qq{SELECT ? AS CCC $table}, "C");

print Dumper($data);

print "Select named bind\n";

my $sql=qq{Select UPPER(:foo) AS Foo $table};

$data=$dba->sqlarrayarrayname($sql, {bar=>1, foo=>"foO", baz=>1});

print Dumper($data);

print "Select named in/out bind\n";

my $inout=3;
print "In: $inout\n";
$dba->update("BEGIN :inout := :inout * 2; END;", {inout=>\$inout, foo=>1});
print "Out: $inout\n";

$data=$dba->sqlarrayarrayname(qq{select :foo AS Foo, :bar AS Bar $table},
                              {foo=>"a", bar=>1, baz=>"buz"});

print Dumper($data);

=head1 OUTPUT

=begin html

<pre>

$VAR1 = [
          [
            'Foo'
          ],
          [
            'Foo'
          ]
        ];
$VAR1 = [
          [
            'AAA'
          ],
          [
            'A'
          ]
        ];
$VAR1 = [
          [
            'BBB'
          ],
          [
            'B'
          ]
        ];
$VAR1 = [
          [
            'CCC'
          ],
          [
            'C'
          ]
        ];
In: 3
Out: 6
$VAR1 = [
          [
            'Foo',
            'Bar'
          ],
          [
            'a',
            '1'
          ]
        ];

</pre>

=end html

