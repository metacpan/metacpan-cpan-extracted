#!perl -T

package TaxonomyTest;

use strict;
use warnings;
use Carp qw/croak/;
#use XML::Simple qw(:strict);
use Test::More;

BEGIN {
  eval { require XML::Simple; import XML::Simple qw/:strict/ };
  use_ok ('Bio::LITE::Taxonomy');
  use base qw(Bio::LITE::Taxonomy);
}


can_ok ("Bio::LITE::Taxonomy", qw/get_taxonomy get_taxonomy_with_levels get_level_from_name get_taxid_from_name get_taxonomy_from_name/);

sub new
  {
    my ($class,%args) = @_;
    my %opts;

    defined $args{'bergeyXML'} or croak "Need the file bergeyTrainingTree.xml";

    $opts{bergeyXML} = $args{bergeyXML};
    my $self = bless \%opts, $class;
    $self->_build_taxonomy();
    return $self;
  }

sub _build_taxonomy
  {
    my ($self) = @_;
    my $bergeysXML = $self->{bergeyXML};
    my $xmlfh;
    if ((UNIVERSAL::isa($bergeysXML, 'GLOB')) or (ref \$bergeysXML eq 'GLOB')) {
      $xmlfh = $bergeysXML;  # Note: Check permissions
    } else {
      open $xmlfh, "<", $bergeysXML or croak $!;
    }
    my @bergeysxml = <$xmlfh>;
    my $bergeysTree = XMLin(
                            (shift @bergeysxml && join "", ("<tree>",@bergeysxml,"</tree>")), # bergeysXML is not a comformant XML file
                            ForceArray => 0,
                            KeyAttr => ["taxid"]
                           );

    $self->_parse_tree($bergeysTree);
    close($xmlfh) unless ((UNIVERSAL::isa($bergeysXML, 'GLOB')) or (ref \$bergeysXML eq 'GLOB'));
  }


sub _parse_tree
    {
      my ($self, $bergeysTree) = @_;

      my %names;
      my %allowed_levels;

      for my $taxid (keys %{$bergeysTree->{TreeNode}}) {
        $bergeysTree->{TreeNode}->{$taxid}->{parent} = $bergeysTree->{TreeNode}->{$taxid}->{parentTaxid};
        $bergeysTree->{TreeNode}->{$taxid}->{level}  = $bergeysTree->{TreeNode}->{$taxid}->{rank};
        delete @{$bergeysTree->{TreeNode}->{$taxid}}{qw/parentTaxid rank leaveCount genusIndex/};
        $bergeysTree->{TreeNode}->{$taxid}->{name} =~ s/"//g;
        $bergeysTree->{TreeNode}->{$taxid}->{name} = "root" if ($bergeysTree->{TreeNode}->{$taxid}->{name} eq "Root");
        $names{$bergeysTree->{TreeNode}->{$taxid}->{name}} = $taxid;
        $allowed_levels{$bergeysTree->{TreeNode}->{$taxid}->{level}} = 1;
      }
      $self->{nodes} = $bergeysTree->{TreeNode};
      $self->{names} = { %names };
      $self->{allowed_levels} = { %allowed_levels };
    }

package main;

use strict;
use warnings;
use Test::More;

BEGIN {
      use_ok ('Bio::LITE::Taxonomy');
}

SKIP: {
#      eval { require TaxonomyTest };
#      skip "$@", 13 if $@;
  eval { require XML::Simple };
  skip "XML is not installed", 13 if $@;

      can_ok ("Bio::LITE::Taxonomy", qw/get_taxonomy get_taxonomy_with_levels get_level_from_name get_taxid_from_name get_taxonomy_from_name/);

      my $datapath = "t/data";

      ok (-e "${datapath}/bergeyTrainingTree.xml","bergeyTrainingTree.xml present");  # T3
      ok (-r "${datapath}/bergeyTrainingTree.xml","bergeyTrainingTree.xml readable"); # T4

      can_ok ("TaxonomyTest", qw/new get_taxonomy get_taxonomy_with_levels get_level_from_name get_taxid_from_name get_taxonomy_from_name/);

      my $taxRDP = new_ok ("TaxonomyTest" => ([bergeyXML=>"${datapath}/bergeyTrainingTree.xml"]) );

      my ($tax,@tax);
      eval {
        @tax = $taxRDP->get_taxonomy(22075);
	};
	is($@,"",""); # T6
	ok($#tax == 7, "");                   # T7
	is($tax[0],"Bacteria", "");       # T8

	eval {
	  $tax = $taxRDP->get_taxonomy(22075);
	  };
	  isa_ok ($tax,"ARRAY");

	  eval {
	    $tax = $taxRDP->get_taxonomy(300000);
	    };
	    ok($tax eq "","");

	    eval {
	      $tax=$taxRDP->get_taxonomy();
	      };
	      ok (!defined $tax);

	      my $level;
	      eval {
	        $level = $taxRDP->get_level_from_name("Bacillaceae 1");
		};
		is($@,"",""); # T7
		is($level,"subfamily",""); # T8
}
done_testing();

