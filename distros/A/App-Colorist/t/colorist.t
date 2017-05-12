#!/usr/bin/perl
use strict;
use warnings;

use File::Temp qw( tempfile );
use Test::More;

use_ok('App::Colorist');

if ($^O eq 'MSWin32') {
    fail("This module does not work on Windows. Patches welcome.");
    die;
}

my $input = "Starting foo...

Nginx is running on: http://12.12.12.12:1234/
    * Running with SSL on port 2234.

[Wed Jun 18 22:12:48 2014] [dev.example.com       ] [studly       ] [12.34.56.78  ] [0.729997] [/foo/buzzers/bangle/1                               ] [200]
[Wed Jun 18 22:19:39 2014] [dev.example.com       ] [studly       ] [12.34.56.78  ] [0.112939] [/foo/buzzers/wizard/veela/1                         ] [200]
[Wed Jun 18 22:19:43 2014] [dev.example.com       ] [studly       ] [12.34.56.78  ] [0.081869] [/foo/buzzers/wizard/veela_slopot/1                  ] [200]
[Wed Jun 18 22:19:46 2014] [dev.example.com       ] [studly       ] [12.34.56.78  ] [0.159319] [/foo/buzzers/wizard/pick/1                          ] [200]
[Wed Jun 18 22:19:49 2014] [dev.example.com       ] [studly       ] [12.34.56.78  ] [0.088478] [/foo/buzzers/wizard/bug_stan/1/17/plague_buzzers    ] [200]
[Wed Jun 18 22:19:52 2014] [dev.example.com       ] [studly       ] [12.34.56.78  ] [0.083040] [/foo/buzzers/wizard/bug_stan/1/17/plague_zorro      ] [200]
[Wed Jun 18 22:19:52 2014] [dev.example.com       ] [studly       ] [12.34.56.78  ] [0.097066] [/foo/buzzers/wizard/bug_stan/1/17/plague_zorro      ] [200]
[Wed Jun 18 22:19:55 2014] [dev.example.com       ] [studly       ] [12.34.56.78  ] [0.093697] [/foo/buzzers/wizard/bug_stan/1/17/plague_zorro      ] [200]
[Wed Jun 18 22:19:55 2014] [dev.example.com       ] [studly       ] [12.34.56.78  ] [0.114974] [/foo/buzzers/wizard/bug_stan/1/17/plague_zorro      ] [200]
[Wed Jun 18 22:19:57 2014] [dev.example.com       ] [studly       ] [12.34.56.78  ] [0.117658] [/foo/buzzers/wizard/pay/1/17                        ] [200]
";

my $expected = "{11}{8}Starting {15}foo{8}...{11}
{11}{reset}{11}{11}{11}
{11}{reset}{11}{8}Nginx is running on: {6}http://{2}12.12.12.12{6}:{13}1234{6}/{8}{11}
{11}{reset}{11}{8}    * Running with SSL on port {13}2234{8}.{11}
{11}{reset}{11}{11}{11}
{11}{reset}{11}{7}{8}[{7}Wed Jun 18 22:12:48 2014{8}]{7} {8}[{6}dev.example.com       {8}]{7} {8}[{12}studly       {8}]{7} {8}[{2}12.34.56.78  {8}]{7} {8}[{10}0.729997{8}]{7} {8}[{6}/foo/buzzers/bangle/1                               {8}]{7} {8}[{10}200{8}]{7}{11}
{11}{reset}{11}{7}{8}[{7}Wed Jun 18 22:19:39 2014{8}]{7} {8}[{6}dev.example.com       {8}]{7} {8}[{12}studly       {8}]{7} {8}[{2}12.34.56.78  {8}]{7} {8}[{10}0.112939{8}]{7} {8}[{6}/foo/buzzers/wizard/veela/1                         {8}]{7} {8}[{10}200{8}]{7}{11}
{11}{reset}{11}{7}{8}[{7}Wed Jun 18 22:19:43 2014{8}]{7} {8}[{6}dev.example.com       {8}]{7} {8}[{12}studly       {8}]{7} {8}[{2}12.34.56.78  {8}]{7} {8}[{10}0.081869{8}]{7} {8}[{6}/foo/buzzers/wizard/veela_slopot/1                  {8}]{7} {8}[{10}200{8}]{7}{11}
{11}{reset}{11}{7}{8}[{7}Wed Jun 18 22:19:46 2014{8}]{7} {8}[{6}dev.example.com       {8}]{7} {8}[{12}studly       {8}]{7} {8}[{2}12.34.56.78  {8}]{7} {8}[{10}0.159319{8}]{7} {8}[{6}/foo/buzzers/wizard/pick/1                          {8}]{7} {8}[{10}200{8}]{7}{11}
{11}{reset}{11}{7}{8}[{7}Wed Jun 18 22:19:49 2014{8}]{7} {8}[{6}dev.example.com       {8}]{7} {8}[{12}studly       {8}]{7} {8}[{2}12.34.56.78  {8}]{7} {8}[{10}0.088478{8}]{7} {8}[{6}/foo/buzzers/wizard/bug_stan/1/17/plague_buzzers    {8}]{7} {8}[{10}200{8}]{7}{11}
{11}{reset}{11}{7}{8}[{7}Wed Jun 18 22:19:52 2014{8}]{7} {8}[{6}dev.example.com       {8}]{7} {8}[{12}studly       {8}]{7} {8}[{2}12.34.56.78  {8}]{7} {8}[{10}0.083040{8}]{7} {8}[{6}/foo/buzzers/wizard/bug_stan/1/17/plague_zorro      {8}]{7} {8}[{10}200{8}]{7}{11}
{11}{reset}{11}{7}{8}[{7}Wed Jun 18 22:19:52 2014{8}]{7} {8}[{6}dev.example.com       {8}]{7} {8}[{12}studly       {8}]{7} {8}[{2}12.34.56.78  {8}]{7} {8}[{10}0.097066{8}]{7} {8}[{6}/foo/buzzers/wizard/bug_stan/1/17/plague_zorro      {8}]{7} {8}[{10}200{8}]{7}{11}
{11}{reset}{11}{7}{8}[{7}Wed Jun 18 22:19:55 2014{8}]{7} {8}[{6}dev.example.com       {8}]{7} {8}[{12}studly       {8}]{7} {8}[{2}12.34.56.78  {8}]{7} {8}[{10}0.093697{8}]{7} {8}[{6}/foo/buzzers/wizard/bug_stan/1/17/plague_zorro      {8}]{7} {8}[{10}200{8}]{7}{11}
{11}{reset}{11}{7}{8}[{7}Wed Jun 18 22:19:55 2014{8}]{7} {8}[{6}dev.example.com       {8}]{7} {8}[{12}studly       {8}]{7} {8}[{2}12.34.56.78  {8}]{7} {8}[{10}0.114974{8}]{7} {8}[{6}/foo/buzzers/wizard/bug_stan/1/17/plague_zorro      {8}]{7} {8}[{10}200{8}]{7}{11}
{11}{reset}{11}{7}{8}[{7}Wed Jun 18 22:19:57 2014{8}]{7} {8}[{6}dev.example.com       {8}]{7} {8}[{12}studly       {8}]{7} {8}[{2}12.34.56.78  {8}]{7} {8}[{10}0.117658{8}]{7} {8}[{6}/foo/buzzers/wizard/pay/1/17                        {8}]{7} {8}[{10}200{8}]{7}{11}
{11}{reset}";

my $infh = tempfile;
print $infh $input;
seek $infh, 0, 0;

my $outfh = tempfile;

my $colorizer = App::Colorist::Colorizer->new(
    configuration => 'test',
    include       => [ 't/rules' ],
    debug         => 1,
    inputs        => [ $infh ],
    output        => $outfh,
);

$colorizer->run;

seek $outfh, 0, 0;
my $output = do { local $/; <$outfh> };

my @output_lines = split "\n", $output;
my @expected_lines = split "\n", $expected;
is(scalar @output_lines, scalar @expected_lines, 'same number of lines in output and expected');
for my $i (0 .. $#expected_lines) {
    my $outline = $output_lines[$i];
    my $expline = $expected_lines[$i];
    is($outline, $expline, "output $i eq expected $i");
}

done_testing;
