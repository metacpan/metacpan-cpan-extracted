#
# This file is part of Convert-TBX-RNG
#
# This software is copyright (c) 2013 by Alan K. Melby.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package t::TestRNG;
use Test::Base -Base;
use Test::More 0.88;
use TBX::Checker qw(check);
use XML::LibXML;
use File::Slurp;
use File::Temp;
use FindBin qw($Bin);
use Path::Tiny;
use feature 'state';
our @EXPORT = qw(compare_validation remove_temps);

my $corpus_dir = path($Bin, 'corpus');
my $temp_xcs = path($corpus_dir, 'temp.xcs');

# Pass in an RNG string pointer, a TBX string pointer,
# and a boolean indicating whether the TBX file should be valid.
# This tests for TBX validity via Relax NG and TBX::Checker
sub compare_validation {
    ($self, @_) = find_my_self($self, @_);
    my ($rng_string, $tbx_string, $should_pass) = @_;

    # store TBX text in a temporary file so that TBX::Checker can
    # use it
    state $temp_tbx = File::Temp->new(
        TEMPLATE => 'tbx.temp.XXXX',
        DIR => $corpus_dir,
    );
    write_file($temp_tbx->filename, $tbx_string);

    subtest 'TBX should ' . ($should_pass ? q() : 'not ') . 'be valid' =>
    sub {
        plan tests => 3 - ($should_pass ? 1 : 0);

        my ($valid, $messages) = check($temp_tbx->filename);
        is($valid, $should_pass, 'TBXChecker')
            or note explain $messages;
        if(!$should_pass){
            ok((grep {$_ =~ /XCS Adherence Errors/} @$messages),
                'XCS adherence was the cause of failure');
        }

        my $rng_doc = XML::LibXML->load_xml(string => $rng_string);
        my $rng = XML::LibXML::RelaxNG->new( DOM => $rng_doc );
        my $doc = XML::LibXML->load_xml(string => $tbx_string);
        my $error;

        if(!eval { $rng->validate( $doc ); 1;} ){
            $error = $@;
        }

        # undefined error means it's valid, defined invalid
        ok((defined($error) xor $should_pass), 'Generated RNG')
            # if there should have been no error but there was, print it
            or ($error and note $error);
    };
    # unlink $temp_tbx;
}

#delete temporary files used for testing
sub remove_temps {
    unlink $temp_xcs;
}

1;

package t::TestRNG::Filter;
use Test::Base::Filter -Base;
use Data::Section::Simple qw (get_data_section);
use File::Temp;
use File::Slurp;
use File::Temp;
use feature 'state';

#write the xcs to a temp file and return a File::Temp object
sub write_xcs {
    my ($xcs_contents) = @_;
    write_file($temp_xcs, $xcs_contents);
    return $temp_xcs;
}

my $data = get_data_section;

#create a small XCS with the input language contents
sub xcs_with_languages {
    my ($input) = @_;
    my $xcs = $data->{XCS};
    $xcs =~ s/DATCATS/$data->{datCat}/;
    $xcs =~ s/LANGUAGES/$input/;
    return \$xcs;
}

#create a small XCS with the input datacatset contents
sub xcs_with_datCats {
    my ($input) = @_;
    my $xcs = $data->{XCS};
    $xcs =~ s/LANGUAGES/$data->{languages}/;
    $xcs =~ s/DATCATS/$input/;
    return \$xcs;
}

#create a small TBX with the input body contents
sub tbx_with_body {
    my ($input) = @_;
    my $tbx = $data->{TBX};
    $tbx =~ s/BODY/$input/;
    return \$tbx;
}

1;

__DATA__
@@ XCS
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE TBXXCS SYSTEM "tbxxcsdtd.dtd">
<TBXXCS name="Small" version="2" lang="en">
    <header>
        <title>Example XCS file</title>
    </header>

    <languages>
        LANGUAGES
    </languages>

    <datCatSet>
       DATCATS
    </datCatSet>

    <refObjectDefSet>
        <refObjectDef>
            <refObjectType>Foo</refObjectType>
            <itemSpecSet type="validItemType">
                <itemSpec type="validItemType">data</itemSpec>
            </itemSpecSet>
        </refObjectDef>
    </refObjectDefSet>
</TBXXCS>

@@ languages
        <langInfo>
            <langCode>en</langCode>
            <langName>English</langName>
        </langInfo>
@@ datCat
        <xrefSpec name="xrefFoo" datcatId="">
            <contents targetType="external"/>
        </xrefSpec>

@@ TBX
<?xml version='1.0'?>
<!DOCTYPE martif SYSTEM "TBXcoreStructV02.dtd">
<martif type="TBX-Basic" xml:lang="en-US">
    <martifHeader>
        <fileDesc>
            <titleStmt>
                <title>Minimal TBX File</title>
            </titleStmt>
            <sourceDesc>
                <p>Paired down from TBX-Basic Package sample</p>
            </sourceDesc>
        </fileDesc>
        <encodingDesc>
            <p type="XCSURI">temp.xcs
            </p>
        </encodingDesc>
    </martifHeader>
    <text>
        <body>
        BODY
        </body>
    </text>
</martif>
