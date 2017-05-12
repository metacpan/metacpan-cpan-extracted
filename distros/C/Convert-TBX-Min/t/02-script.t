# make sure that basic2min works correctly
# note that this will only work after adding ../lib to perl's
# include path, like with prove -l
use strict;
use warnings;

use Test::More tests => 2;
use Test::LongString;
use Test::XML;
use Data::Section::Simple 'get_data_section';
use FindBin '$Bin';
use Path::Tiny;
use Capture::Tiny 'capture';
use Devel::FindPerl qw(find_perl_interpreter);

my $PERL  = find_perl_interpreter() || die "can't find perl!\n";
my $script_path = path( $Bin, qw(.. bin min2basic) )->realpath;
my $include_path = path($Bin, qw(.. lib))->realpath;
my $data_path = path($Bin, qw(corpus min_sample.tbx));

my $command = qq{"$PERL" -I"$include_path" "$script_path" "$data_path"};
my ($stdout, $stderr) = capture {
    system($command);
};

ok($? == 0, 'process exited successfully')
  or note $stderr;

my $data = get_data_section();
is_xml($stdout, $data->{xml}, 'correct TBX output');

__DATA__
@@ xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE martif
  SYSTEM 'TBXBasiccoreStructV02.dtd'>
<martif type="TBX-Basic" xml:lang="de">
    <martifHeader>
        <fileDesc>
            <titleStmt>
                <title>TBX sample</title>
            </titleStmt>
            <sourceDesc>
                <p>TBX sample (generated from UTX)</p>
            </sourceDesc>
        </fileDesc>
        <encodingDesc>
                <p type="XCSURI">TBXBasicXCSV02.xcs
                </p>
        </encodingDesc>
    </martifHeader>
    <text>
        <body>
            <termEntry id="C002">
                <langSet xml:lang="en">
                    <tig>
                        <term>dog</term>
                    </tig>
                </langSet>
            </termEntry>
        </body>
    </text>
</martif>
