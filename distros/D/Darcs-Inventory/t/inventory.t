#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use List::Util;
use Darcs::Inventory;
use POSIX qw(locale_h);
setlocale(LC_TIME, "C"); # Darcs ingores the locale. Perl doesn't. It seems better to use the locale! But when
                         # testing against darcs we need to set the locale to english so that we can test.

my @flavor = ( {flavor=>'darcs-old',    format=>'old',                inventory=>'inventory' },
               {flavor=>'darcs-hashed', format=>"hashed\n",           inventory=>'hashed_inventory' },
               {flavor=>'darcs-2',      format=>"hashed\ndarcs-2\n",  inventory=>'hashed_inventory' } );

sub load_flavor($)
{
    my ($flavor) = @_;
    my $dir = "t/$flavor";

    my $have_xml_simple = eval "use XML::Simple; 1;";
    my $have_darcs = !!`darcs --version`;

    # Let you test even if you don't have a darcs executable or XML::Simple:
    if ((!$have_darcs || !$have_xml_simple) && -f "t/$flavor/darcs-changes.pl") {
        return map {
            # It is pointless to test the local date if we are getting the data from cache.
            # This is because we'd have to interpret it and translate it into the local time zone
            # and if we are doing that then we may as well just translate it from the darcs_date.
            # which is just reusing the code from Darcs::Inventory::Patch and therefore not really
            # a test at all.
            delete $_->{local_date};
            $_
        } @{do "t/$flavor/darcs-changes.pl"}
    }

    die "No XML::Simple and no cached darcs output" unless $have_xml_simple;
    die "No darcs and no cached darcs output" unless $have_darcs;

    my $darcs_changes_xml;
    open CHANGES, "-|", qw(darcs change --xml), "--repo=t/$flavor" or die "$flavor: darcs changes: $!";
    {
        local $/;
        $darcs_changes_xml = <CHANGES>;
        close CHANGES;
    }

    my @darcs_patches = reverse @{XMLin($darcs_changes_xml, ForceArray=>1)->{patch}};

    # Stupid XML::Simple
    for (@darcs_patches) {
        $_->{author} =~ s/&gt;/>/g;
        $_->{author} =~ s/&lt;/</g;
    }

    use Data::Dumper;
    if (open CACHE, ">", "t/$flavor/darcs-changes.pl") { # Module::Build makes this read-only. Weak.
        print CACHE Data::Dumper->Dump([\@darcs_patches], ["darcs_patches"]);
        close CACHE;
    }

    @darcs_patches;
}

@{$_->{patches}} = load_flavor $_->{flavor} foreach @flavor;
# use Data::Dumper;
# print Dumper \@flavor;

my $patches = List::Util::sum map { scalar @{$_->{patches}} } @flavor;

plan tests => $patches * 7 + 4 * scalar @flavor;

sub test_flavor($)
{
    my ($flavor, $inventory, $format, @darcs_patches) = (@{$_[0]}{qw(flavor inventory format)}, @{$_[0]->{patches}});

    my $inv = Darcs::Inventory->new("t/$flavor");
    isnt(undef, $inv, "$flavor: inventory loaded");
    my @patches = $inv->patches;

    is($inv->format, $format, "$flavor: format detection");
    is($inv->file,   "t/$flavor/_darcs/$inventory", "$flavor: inventory file accessor");
    is(scalar @darcs_patches, scalar @patches, "$flavor: Correct number of patches");

    for (0..scalar @darcs_patches-1) {
        is($patches[$_]->hash,                    $darcs_patches[$_]->{hash},                   "$flavor: patch $_ hash");
        is($patches[$_]->undo ? 'True' : 'False', $darcs_patches[$_]->{inverted},               "$flavor: patch $_ undo");
        is($patches[$_]->author,                  $darcs_patches[$_]->{author},                 "$flavor: patch $_ author");
        is($patches[$_]->raw_date,                $darcs_patches[$_]->{date},                   "$flavor: patch $_ raw_date");
      SKIP: {
          skip "missing darcs and XML::Simple", 1 unless $darcs_patches[$_]->{local_date};
          is($patches[$_]->darcs_date,            $darcs_patches[$_]->{local_date},             "$flavor: patch $_ darcs_date");
        }
        is($patches[$_]->name,                    $darcs_patches[$_]->{name}->[0],              "$flavor: patch $_ name");
        is($patches[$_]->long,                    ($darcs_patches[$_]->{comment}||[''])->[0],   "$flavor: patch $_ long");
    }
}

test_flavor($_) foreach @flavor;
