#! /usr/bin/perl -T

use Test::More tests => 6;

use Bio::GeneDesign;
use Bio::Seq;

use strict;
use warnings;

my $GD = Bio::GeneDesign->new();
$GD->set_organism(-organism_name => "yeast",
                  -table_path => "codon_tables/Standard.ct",
                  -rscu_path => "codon_tables/Saccharomyces_cerevisiae.rscu");

$GD->{conf} = 'blib/GeneDesign/';
$GD->set_restriction_enzymes(-list_path => "enzymes/test");

my %elist = (RsaI => 1, TaqI => 1, BsrI => 1, AciI => 1);
my @tlist = grep {exists $elist{$_->id}} values %{$GD->enzyme_set};

my %nlist = %elist;
$nlist{PspGI} = 1;
$nlist{AlwI} = 1;
my @alist = grep {exists $nlist{$_->id}} values %{$GD->enzyme_set};

my $rpeptide = "MDRSWKQKLNRDTVKLTEVMTWRRPAAKWFYTLINANYLPPCPPDHQDHRQQQLPEPDQPEHQRPEQPHQAAPPDRLAAQAGPHLLLPPGDPPAREGPALPAGEGLEDHLSGQRPEEAGWRGHPDQRQDRLPAQGDQEGQGGPLHPDQGQDPAGGAEHSEHLRPQRPRRHLHQGHPREAEGPHRSPHHHRRRPEHPPEQ*";
my $pepobj = Bio::Seq->new( -seq => $rpeptide, -id => "tprotein");

my $orf = "ATGGACAGATCTTGGAAGCAGAAGCTGAACCGCGACACCGTGAAGCTGACCGAGGTGATGACCTGGAGAAGACCCGCCGCTAAATGGTTTTATACTTTAATTAATGCTAATTATTTGCCACCATGCCCACCCGACCACCAAGATCACCGGCAGCAACAACTACCTGAGCCTGATCAGCCTGAACATCAACGGCCTGAACAGCCCCATCAAGCGGCACCGCCTGACCGACTGGCTGCACAAGCAGGACCCCACCTTCTGTTGCCTCCAGGAGACCCACCTGCGCGAGAAGGACCGGCACTACCTGCGGGTGAAGGGCTGGAAGACCATCTTTCAGGCCAACGGCCTGAAGAAGCAGGCTGGCGTGGCCATCCTGATCAGCGACAAGATCGACTTCCAGCCCAAGGTGATCAAGAAGGACAAGGAGGGCCACTTCATCCTGATCAAGGGCAAGATCCTGCAGGAGGAGCTGAGCATTCTGAACATCTACGCCCCCAACGCCCGCGCCGCCACCTTCATCAAGGACACCCTCGTGAAGCTGAAGGCCCACATCGCTCCCCACACCATCATCGTCGGCGACCTGAACACCCCCCTGAGCAGTGA";
my $orfobj = Bio::Seq->new( -seq => $orf, -id => "torf");

#TESTING build_prefix_trees pep
my $rsuft = bless(
    {
        'root' => {
            'F' => {
                'Q' => {
                    'S' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'FQS'
                    },
                    'F' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'FQF'
                    },
                    'W' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'FQW'
                    },
                    'C' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'FQC'
                    },
                    '*' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'FQ*'
                    },
                    'L' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'FQL'
                    },
                    'Y' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'FQY'
                    }
                },
                'D' => {
                    'ids' => {
                        'TaqI' => ['TCGA']
                    },
                    'count'    => 1,
                    'sequence' => 'FD'
                },
                'R' => {
                    'ids' => {
                        'AciI' => ['CCGC'],
                        'TaqI' => ['TCGA']
                    },
                    'count'    => 2,
                    'sequence' => 'FR'
                },
                'E' => {
                    'ids' => {
                        'TaqI' => ['TCGA']
                    },
                    'count'    => 1,
                    'sequence' => 'FE'
                }
            },
            'S' => {
                'A' => {
                    'ids' => {
                        'AciI' => ['CCGC']
                    },
                    'count'    => 1,
                    'sequence' => 'SA'
                },
                'S' => {
                    'ids' => {
                        'BsrI' => ['CCAGT'],
                        'TaqI' => ['TCGA']
                    },
                    'count'    => 2,
                    'sequence' => 'SS'
                },
                'T' => {
                    'ids' => {
                        'RsaI' => ['GTAC'],
                        'TaqI' => ['TCGA']
                    },
                    'count'    => 2,
                    'sequence' => 'ST'
                },
                'N' => {
                    'ids' => {
                        'TaqI' => ['TCGA']
                    },
                    'count'    => 1,
                    'sequence' => 'SN'
                },
                'K' => {
                    'ids' => {
                        'TaqI' => ['TCGA']
                    },
                    'count'    => 1,
                    'sequence' => 'SK'
                },
                'Y' => {
                    'ids' => {
                        'RsaI' => ['GTAC']
                    },
                    'count'    => 1,
                    'sequence' => 'SY'
                },
                'Q' => {
                    'F' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'SQF'
                    },
                    'S' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'SQS'
                    },
                    'W' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'SQW'
                    },
                    'C' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'SQC'
                    },
                    '*' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'SQ*'
                    },
                    'L' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'SQL'
                    },
                    'Y' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'SQY'
                    }
                },
                'M' => {
                    'ids' => {
                        'TaqI' => ['TCGA']
                    },
                    'count'    => 1,
                    'sequence' => 'SM'
                },
                'I' => {
                    'ids' => {
                        'TaqI' => ['TCGA']
                    },
                    'count'    => 1,
                    'sequence' => 'SI'
                },
                'R' => {
                    'ids' => {
                        'AciI' => ['CCGC', 'GCGG'],
                        'TaqI' => ['TCGA']
                    },
                    'count'    => 3,
                    'sequence' => 'SR'
                },
                'G' => {
                    'ids' => {
                        'AciI' => ['GCGG']
                    },
                    'count'    => 1,
                    'sequence' => 'SG'
                },
                'L' => {
                    'A' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'SLA'
                    },
                    'D' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'SLD'
                    },
                    'G' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'SLG'
                    },
                    'E' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'SLE'
                    },
                    'V' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'SLV'
                    }
                }
            },
            'T' => {
                'A' => {
                    'ids' => {
                        'AciI' => ['CCGC']
                    },
                    'count'    => 1,
                    'sequence' => 'TA'
                },
                'S' => {
                    'ids' => {
                        'BsrI' => ['CCAGT']
                    },
                    'count'    => 1,
                    'sequence' => 'TS'
                },
                'Q' => {
                    'F' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'TQF'
                    },
                    'S' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'TQS'
                    },
                    'W' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'TQW'
                    },
                    'C' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'TQC'
                    },
                    '*' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'TQ*'
                    },
                    'Y' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'TQY'
                    },
                    'L' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'TQL'
                    }
                },
                'R' => {
                    'ids' => {
                        'AciI' => ['CCGC', 'GCGG'],
                        'TaqI' => ['TCGA']
                    },
                    'count'    => 3,
                    'sequence' => 'TR'
                },
                'G' => {
                    'ids' => {
                        'BsrI' => ['ACTGG']
                    },
                    'count'    => 1,
                    'sequence' => 'TG'
                },
                'Y' => {
                    'ids' => {
                        'RsaI' => ['GTAC']
                    },
                    'count'    => 1,
                    'sequence' => 'TY'
                },
                'L' => {
                    'A' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'TLA'
                    },
                    'D' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'TLD'
                    },
                    'G' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'TLG'
                    },
                    'E' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'TLE'
                    },
                    'V' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'TLV'
                    }
                }
            },
            'N' => {
                'Q' => {
                    'S' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'NQS'
                    },
                    'F' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'NQF'
                    },
                    'W' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'NQW'
                    },
                    'C' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'NQC'
                    },
                    '*' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'NQ*'
                    },
                    'Y' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'NQY'
                    },
                    'L' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'NQL'
                    }
                },
                'W' => {
                    'ids' => {
                        'BsrI' => ['ACTGG']
                    },
                    'count'    => 1,
                    'sequence' => 'NW'
                },
                'R' => {
                    'ids' => {
                        'AciI' => ['CCGC'],
                        'TaqI' => ['TCGA']
                    },
                    'count'    => 2,
                    'sequence' => 'NR'
                }
            },
            'K' => {
                'R' => {
                    'ids' => {
                        'AciI' => ['GCGG']
                    },
                    'count'    => 1,
                    'sequence' => 'KR'
                },
                'Y' => {
                    'ids' => {
                        'RsaI' => ['GTAC']
                    },
                    'count'    => 1,
                    'sequence' => 'KY'
                },
                'L' => {
                    'A' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'KLA'
                    },
                    'D' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'KLD'
                    },
                    'G' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'KLG'
                    },
                    'E' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'KLE'
                    },
                    'V' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'KLV'
                    }
                }
            },
            '*' => {
                'R' => {
                    'ids' => {
                        'AciI' => ['GCGG']
                    },
                    'count'    => 1,
                    'sequence' => '*R'
                },
                'Y' => {
                    'ids' => {
                        'RsaI' => ['GTAC']
                    },
                    'count'    => 1,
                    'sequence' => '*Y'
                },
                'L' => {
                    'A' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => '*LA'
                    },
                    'D' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => '*LD'
                    },
                    'G' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => '*LG'
                    },
                    'E' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => '*LE'
                    },
                    'V' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => '*LV'
                    }
                }
            },
            'Y' => {
                'Q' => {
                    'S' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'YQS'
                    },
                    'F' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'YQF'
                    },
                    'W' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'YQW'
                    },
                    'C' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'YQC'
                    },
                    '*' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'YQ*'
                    },
                    'Y' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'YQY'
                    },
                    'L' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'YQL'
                    }
                },
                'W' => {
                    'ids' => {
                        'BsrI' => ['ACTGG']
                    },
                    'count'    => 1,
                    'sequence' => 'YW'
                },
                'R' => {
                    'ids' => {
                        'AciI' => ['CCGC'],
                        'TaqI' => ['TCGA']
                    },
                    'count'    => 2,
                    'sequence' => 'YR'
                }
            },
            'E' => {
                'R' => {
                    'ids' => {
                        'AciI' => ['GCGG']
                    },
                    'count'    => 1,
                    'sequence' => 'ER'
                },
                'Y' => {
                    'ids' => {
                        'RsaI' => ['GTAC']
                    },
                    'count'    => 1,
                    'sequence' => 'EY'
                },
                'L' => {
                    'A' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'ELA'
                    },
                    'D' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'ELD'
                    },
                    'G' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'ELG'
                    },
                    'E' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'ELE'
                    },
                    'V' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'ELV'
                    }
                }
            },
            'V' => {
                'H' => {
                    'ids' => {
                        'RsaI' => ['GTAC']
                    },
                    'count'    => 1,
                    'sequence' => 'VH'
                },
                'Q' => {
                    'F' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'VQF'
                    },
                    'S' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'VQS'
                    },
                    'W' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'VQW'
                    },
                    '*' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'VQ*'
                    },
                    'Y' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'VQY'
                    },
                    'count'    => 1,
                    'sequence' => 'VQ',
                    'C'        => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'VQC'
                    },
                    'ids' => {
                        'RsaI' => ['GTAC']
                    },
                    'L' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'VQL'
                    }
                },
                'D' => {
                    'ids' => {
                        'TaqI' => ['TCGA']
                    },
                    'count'    => 1,
                    'sequence' => 'VD'
                },
                'P' => {
                    'ids' => {
                        'RsaI' => ['GTAC']
                    },
                    'count'    => 1,
                    'sequence' => 'VP'
                },
                'R' => {
                    'ids' => {
                        'RsaI' => ['GTAC'],
                        'AciI' => ['CCGC', 'GCGG'],
                        'TaqI' => ['TCGA']
                    },
                    'count'    => 4,
                    'sequence' => 'VR'
                },
                'Y' => {
                    'ids' => {
                        'RsaI' => ['GTAC']
                    },
                    'count'    => 1,
                    'sequence' => 'VY'
                },
                'E' => {
                    'ids' => {
                        'TaqI' => ['TCGA']
                    },
                    'count'    => 1,
                    'sequence' => 'VE'
                },
                'L' => {
                    'A' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'VLA'
                    },
                    'ids' => {
                        'RsaI' => ['GTAC']
                    },
                    'D' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'VLD'
                    },
                    'G' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'VLG'
                    },
                    'E' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'VLE'
                    },
                    'count'    => 1,
                    'sequence' => 'VL',
                    'V'        => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'VLV'
                    }
                }
            },
            'Q' => {
                'R' => {
                    'ids' => {
                        'AciI' => ['GCGG']
                    },
                    'count'    => 1,
                    'sequence' => 'QR'
                },
                'Y' => {
                    'ids' => {
                        'RsaI' => ['GTAC']
                    },
                    'count'    => 1,
                    'sequence' => 'QY'
                },
                'L' => {
                    'A' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'QLA'
                    },
                    'D' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'QLD'
                    },
                    'G' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'QLG'
                    },
                    'E' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'QLE'
                    },
                    'V' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'QLV'
                    }
                }
            },
            'M' => {
                'R' => {
                    'ids' => {
                        'AciI' => ['GCGG']
                    },
                    'count'    => 1,
                    'sequence' => 'MR'
                },
                'Y' => {
                    'ids' => {
                        'RsaI' => ['GTAC']
                    },
                    'count'    => 1,
                    'sequence' => 'MY'
                }
            },
            'C' => {
                'Q' => {
                    'S' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'CQS'
                    },
                    'F' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'CQF'
                    },
                    'W' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'CQW'
                    },
                    'C' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'CQC'
                    },
                    '*' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'CQ*'
                    },
                    'L' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'CQL'
                    },
                    'Y' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'CQY'
                    }
                },
                'T' => {
                    'ids' => {
                        'RsaI' => ['GTAC']
                    },
                    'count'    => 1,
                    'sequence' => 'CT'
                },
                'R' => {
                    'ids' => {
                        'AciI' => ['CCGC'],
                        'TaqI' => ['TCGA']
                    },
                    'count'    => 2,
                    'sequence' => 'CR'
                },
                'G' => {
                    'ids' => {
                        'AciI' => ['GCGG']
                    },
                    'count'    => 1,
                    'sequence' => 'CG'
                }
            },
            'L' => {
                'Q' => {
                    'S' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'LQS'
                    },
                    'F' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'LQF'
                    },
                    'W' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'LQW'
                    },
                    'C' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'LQC'
                    },
                    '*' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'LQ*'
                    },
                    'L' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'LQL'
                    },
                    'Y' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'LQY'
                    }
                },
                'D' => {
                    'ids' => {
                        'TaqI' => ['TCGA']
                    },
                    'count'    => 1,
                    'sequence' => 'LD'
                },
                'R' => {
                    'ids' => {
                        'AciI' => ['CCGC', 'GCGG'],
                        'TaqI' => ['TCGA']
                    },
                    'count'    => 3,
                    'sequence' => 'LR'
                },
                'Y' => {
                    'ids' => {
                        'RsaI' => ['GTAC']
                    },
                    'count'    => 1,
                    'sequence' => 'LY'
                },
                'E' => {
                    'ids' => {
                        'TaqI' => ['TCGA']
                    },
                    'count'    => 1,
                    'sequence' => 'LE'
                },
                'L' => {
                    'A' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'LLA'
                    },
                    'D' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'LLD'
                    },
                    'G' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'LLG'
                    },
                    'E' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'LLE'
                    },
                    'V' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'LLV'
                    }
                }
            },
            'A' => {
                'A' => {
                    'ids' => {
                        'AciI' => ['CCGC', 'GCGG']
                    },
                    'count'    => 2,
                    'sequence' => 'AA'
                },
                'S' => {
                    'ids' => {
                        'BsrI' => ['CCAGT']
                    },
                    'count'    => 1,
                    'sequence' => 'AS'
                },
                'Y' => {
                    'ids' => {
                        'RsaI' => ['GTAC']
                    },
                    'count'    => 1,
                    'sequence' => 'AY'
                },
                'E' => {
                    'ids' => {
                        'AciI' => ['GCGG']
                    },
                    'count'    => 1,
                    'sequence' => 'AE'
                },
                'V' => {
                    'ids' => {
                        'AciI' => ['GCGG']
                    },
                    'count'    => 1,
                    'sequence' => 'AV'
                },
                'Q' => {
                    'F' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'AQF'
                    },
                    'S' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'AQS'
                    },
                    'W' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'AQW'
                    },
                    'C' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'AQC'
                    },
                    '*' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'AQ*'
                    },
                    'L' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'AQL'
                    },
                    'Y' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'AQY'
                    }
                },
                'D' => {
                    'ids' => {
                        'AciI' => ['GCGG']
                    },
                    'count'    => 1,
                    'sequence' => 'AD'
                },
                'R' => {
                    'ids' => {
                        'AciI' => ['CCGC', 'GCGG'],
                        'TaqI' => ['TCGA']
                    },
                    'count'    => 3,
                    'sequence' => 'AR'
                },
                'G' => {
                    'ids' => {
                        'AciI' => ['GCGG']
                    },
                    'count'    => 1,
                    'sequence' => 'AG'
                },
                'L' => {
                    'A' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'ALA'
                    },
                    'D' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'ALD'
                    },
                    'G' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'ALG'
                    },
                    'E' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'ALE'
                    },
                    'V' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'ALV'
                    }
                }
            },
            'W' => {
                'R' => {
                    'ids' => {
                        'AciI' => ['GCGG']
                    },
                    'count'    => 1,
                    'sequence' => 'WR'
                },
                'Y' => {
                    'ids' => {
                        'RsaI' => ['GTAC']
                    },
                    'count'    => 1,
                    'sequence' => 'WY'
                }
            },
            'P' => {
                'A' => {
                    'ids' => {
                        'AciI' => ['CCGC']
                    },
                    'count'    => 1,
                    'sequence' => 'PA'
                },
                'S' => {
                    'ids' => {
                        'BsrI' => ['CCAGT']
                    },
                    'count'    => 1,
                    'sequence' => 'PS'
                },
                'P' => {
                    'ids' => {
                        'AciI' => ['CCGC']
                    },
                    'count'    => 1,
                    'sequence' => 'PP'
                },
                'Y' => {
                    'ids' => {
                        'RsaI' => ['GTAC']
                    },
                    'count'    => 1,
                    'sequence' => 'PY'
                },
                'V' => {
                    'ids' => {
                        'BsrI' => ['CCAGT']
                    },
                    'count'    => 1,
                    'sequence' => 'PV'
                },
                'H' => {
                    'ids' => {
                        'AciI' => ['CCGC']
                    },
                    'count'    => 1,
                    'sequence' => 'PH'
                },
                'Q' => {
                    'S' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'PQS'
                    },
                    'F' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'PQF'
                    },
                    'W' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'PQW'
                    },
                    '*' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'PQ*'
                    },
                    'Y' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'PQY'
                    },
                    'count'    => 1,
                    'sequence' => 'PQ',
                    'C'        => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'PQC'
                    },
                    'ids' => {
                        'AciI' => ['CCGC']
                    },
                    'L' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'PQL'
                    }
                },
                'R' => {
                    'ids' => {
                        'AciI' => ['CCGC', 'GCGG'],
                        'TaqI' => ['TCGA']
                    },
                    'count'    => 3,
                    'sequence' => 'PR'
                },
                'L' => {
                    'A' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'PLA'
                    },
                    'ids' => {
                        'AciI' => ['CCGC']
                    },
                    'D' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'PLD'
                    },
                    'G' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'PLG'
                    },
                    'E' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'PLE'
                    },
                    'count'    => 1,
                    'sequence' => 'PL',
                    'V'        => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'PLV'
                    }
                }
            },
            'H' => {
                'Q' => {
                    'F' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'HQF'
                    },
                    'S' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'HQS'
                    },
                    'W' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'HQW'
                    },
                    'C' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'HQC'
                    },
                    '*' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'HQ*'
                    },
                    'L' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'HQL'
                    },
                    'Y' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'HQY'
                    }
                },
                'W' => {
                    'ids' => {
                        'BsrI' => ['ACTGG']
                    },
                    'count'    => 1,
                    'sequence' => 'HW'
                },
                'R' => {
                    'ids' => {
                        'AciI' => ['CCGC'],
                        'TaqI' => ['TCGA']
                    },
                    'count'    => 2,
                    'sequence' => 'HR'
                }
            },
            'D' => {
                'Q' => {
                    'S' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'DQS'
                    },
                    'F' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'DQF'
                    },
                    'W' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'DQW'
                    },
                    'C' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'DQC'
                    },
                    '*' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'DQ*'
                    },
                    'L' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'DQL'
                    },
                    'Y' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'DQY'
                    }
                },
                'W' => {
                    'ids' => {
                        'BsrI' => ['ACTGG']
                    },
                    'count'    => 1,
                    'sequence' => 'DW'
                },
                'R' => {
                    'ids' => {
                        'AciI' => ['CCGC'],
                        'TaqI' => ['TCGA']
                    },
                    'count'    => 2,
                    'sequence' => 'DR'
                }
            },
            'R' => {
                'Q' => {
                    'F' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'RQF'
                    },
                    'S' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'RQS'
                    },
                    'W' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'RQW'
                    },
                    'C' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'RQC'
                    },
                    '*' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'RQ*'
                    },
                    'L' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'RQL'
                    },
                    'Y' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'RQY'
                    }
                },
                'T' => {
                    'ids' => {
                        'RsaI' => ['GTAC']
                    },
                    'count'    => 1,
                    'sequence' => 'RT'
                },
                'R' => {
                    'ids' => {
                        'AciI' => ['CCGC', 'GCGG'],
                        'TaqI' => ['TCGA']
                    },
                    'count'    => 3,
                    'sequence' => 'RR'
                },
                'G' => {
                    'ids' => {
                        'AciI' => ['GCGG']
                    },
                    'count'    => 1,
                    'sequence' => 'RG'
                },
                'Y' => {
                    'ids' => {
                        'RsaI' => ['GTAC']
                    },
                    'count'    => 1,
                    'sequence' => 'RY'
                },
                'L' => {
                    'A' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'RLA'
                    },
                    'D' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'RLD'
                    },
                    'G' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'RLG'
                    },
                    'E' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'RLE'
                    },
                    'V' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'RLV'
                    }
                }
            },
            'I' => {
                'Q' => {
                    'S' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'IQS'
                    },
                    'F' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'IQF'
                    },
                    'W' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'IQW'
                    },
                    'C' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'IQC'
                    },
                    '*' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'IQ*'
                    },
                    'L' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'IQL'
                    },
                    'Y' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'IQY'
                    }
                },
                'D' => {
                    'ids' => {
                        'TaqI' => ['TCGA']
                    },
                    'count'    => 1,
                    'sequence' => 'ID'
                },
                'R' => {
                    'ids' => {
                        'AciI' => ['CCGC'],
                        'TaqI' => ['TCGA']
                    },
                    'count'    => 2,
                    'sequence' => 'IR'
                },
                'E' => {
                    'ids' => {
                        'TaqI' => ['TCGA']
                    },
                    'count'    => 1,
                    'sequence' => 'IE'
                },
                'L' => {
                    'A' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'ILA'
                    },
                    'D' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'ILD'
                    },
                    'G' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'ILG'
                    },
                    'E' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'ILE'
                    },
                    'V' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'ILV'
                    }
                }
            },
            'G' => {
                'Q' => {
                    'F' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'GQF'
                    },
                    'S' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'GQS'
                    },
                    'W' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'GQW'
                    },
                    'C' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'GQC'
                    },
                    '*' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'GQ*'
                    },
                    'Y' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'GQY'
                    },
                    'L' => {
                        'ids' => {
                            'BsrI' => ['CCAGT']
                        },
                        'count'    => 1,
                        'sequence' => 'GQL'
                    }
                },
                'T' => {
                    'ids' => {
                        'RsaI' => ['GTAC']
                    },
                    'count'    => 1,
                    'sequence' => 'GT'
                },
                'R' => {
                    'ids' => {
                        'AciI' => ['CCGC', 'GCGG'],
                        'TaqI' => ['TCGA']
                    },
                    'count'    => 3,
                    'sequence' => 'GR'
                },
                'G' => {
                    'ids' => {
                        'AciI' => ['GCGG']
                    },
                    'count'    => 1,
                    'sequence' => 'GG'
                },
                'Y' => {
                    'ids' => {
                        'RsaI' => ['GTAC']
                    },
                    'count'    => 1,
                    'sequence' => 'GY'
                },
                'L' => {
                    'A' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'GLA'
                    },
                    'D' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'GLD'
                    },
                    'G' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'GLG'
                    },
                    'E' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'GLE'
                    },
                    'V' => {
                        'ids' => {
                            'BsrI' => ['ACTGG']
                        },
                        'count'    => 1,
                        'sequence' => 'GLV'
                    }
                }
            }
        }
    },
    'Bio::GeneDesign::PrefixTree'
);

my $tsuft = $GD->build_prefix_tree( -input => \@tlist,
                                    -peptide => 1);
is_deeply( $tsuft, $rsuft, "build_prefix_tree pep" );

#Testing search_prefix_trees pep
my $rhits = [
  ['AciI', 1, 'DR', ['CCGC']],
  ['TaqI', 1, 'DR', ['TCGA']],
  ['AciI', 9, 'NR', ['CCGC']],
  ['TaqI', 9, 'NR', ['TCGA']],
  ['AciI', 21, 'WR', ['GCGG']],
  ['AciI', 22, 'RR', ['CCGC', 'GCGG']],
  ['TaqI', 22, 'RR', ['TCGA']],
  ['AciI', 24, 'PA', ['CCGC']],
  ['AciI', 25, 'AA', ['CCGC', 'GCGG']],
  ['AciI', 39, 'PP', ['CCGC']],
  ['AciI', 42, 'PP', ['CCGC']],
  ['AciI', 48, 'HR', ['CCGC']],
  ['TaqI', 48, 'HR', ['TCGA']],
  ['AciI', 62, 'QR', ['GCGG']],
  ['AciI', 67, 'PH', ['CCGC']],
  ['AciI', 70, 'AA', ['CCGC', 'GCGG']],
  ['AciI', 72, 'PP', ['CCGC']],
  ['AciI', 74, 'DR', ['CCGC']],
  ['TaqI', 74, 'DR', ['TCGA']],
  ['BsrI', 75, 'RLA', ['ACTGG']],
  ['AciI', 77, 'AA', ['CCGC', 'GCGG']],
  ['AciI', 80, 'AG', ['GCGG']],
  ['AciI', 82, 'PH', ['CCGC']],
  ['AciI', 87, 'PP', ['CCGC']],
  ['AciI', 91, 'PP', ['CCGC']],
  ['AciI', 92, 'PA', ['CCGC']],
  ['AciI', 93, 'AR', ['CCGC', 'GCGG']],
  ['TaqI', 93, 'AR', ['TCGA']],
  ['AciI', 97, 'PA', ['CCGC']],
  ['AciI', 100, 'PA', ['CCGC']],
  ['AciI', 101, 'AG', ['GCGG']],
  ['BsrI', 104, 'GLE', ['ACTGG']],
  ['TaqI', 105, 'LE', ['TCGA']],
  ['AciI', 110, 'SG', ['GCGG']],
  ['AciI', 112, 'QR', ['GCGG']],
  ['AciI', 117, 'AG', ['GCGG']],
  ['AciI', 119, 'WR', ['GCGG']],
  ['AciI', 120, 'RG', ['GCGG']],
  ['AciI', 125, 'QR', ['GCGG']],
  ['AciI', 128, 'DR', ['CCGC']],
  ['TaqI', 128, 'DR', ['TCGA']],
  ['AciI', 131, 'PA', ['CCGC']],
  ['AciI', 140, 'GG', ['GCGG']],
  ['AciI', 142, 'PL', ['CCGC']],
  ['AciI', 151, 'PA', ['CCGC']],
  ['AciI', 152, 'AG', ['GCGG']],
  ['AciI', 153, 'GG', ['GCGG']],
  ['AciI', 155, 'AE', ['GCGG']],
  ['AciI', 161, 'LR', ['CCGC', 'GCGG']],
  ['TaqI', 161, 'LR', ['TCGA']],
  ['AciI', 163, 'PQ', ['CCGC']],
  ['AciI', 164, 'QR', ['GCGG']],
  ['AciI', 166, 'PR', ['CCGC', 'GCGG']],
  ['TaqI', 166, 'PR', ['TCGA']],
  ['AciI', 167, 'RR', ['CCGC', 'GCGG']],
  ['TaqI', 167, 'RR', ['TCGA']],
  ['AciI', 175, 'PR', ['CCGC', 'GCGG']],
  ['TaqI', 175, 'PR', ['TCGA']],
  ['AciI', 178, 'AE', ['GCGG']],
  ['AciI', 181, 'PH', ['CCGC']],
  ['AciI', 182, 'HR', ['CCGC']],
  ['TaqI', 182, 'HR', ['TCGA']],
  ['AciI', 185, 'PH', ['CCGC']],
  ['AciI', 188, 'HR', ['CCGC']],
  ['TaqI', 188, 'HR', ['TCGA']],
  ['AciI', 189, 'RR', ['CCGC', 'GCGG']],
  ['TaqI', 189, 'RR', ['TCGA']],
  ['AciI', 190, 'RR', ['CCGC', 'GCGG']],
  ['TaqI', 190, 'RR', ['TCGA']],
  ['AciI', 195, 'PP', ['CCGC']]
];
my $thits = $GD->search_prefix_tree(-tree => $tsuft, -sequence => $pepobj);
is_deeply($thits, $rhits, "search_prefix_tree pep");

#Testing find_ntons pep
my %rfourtons = (
  'VR' => {
      'RsaI' => ['GTAC'],
      'AciI' => ['CCGC', 'GCGG'],
      'TaqI' => ['TCGA']
  }
);
my %tfourtons = $tsuft->find_ntons(4);
is_deeply(\%tfourtons, \%rfourtons, "find four-tons");

my %rthreetons = (
  'SR' => {
    'AciI' => ['CCGC', 'GCGG'],
    'TaqI' => ['TCGA']
  },
  'TR' => {
    'AciI' => ['CCGC', 'GCGG'],
    'TaqI' => ['TCGA']
  },
  'AR' => {
    'AciI' => ['CCGC', 'GCGG'],
    'TaqI' => ['TCGA']
  },
  'LR' => {
    'AciI' => ['CCGC', 'GCGG'],
    'TaqI' => ['TCGA']
  },
  'PR' => {
    'AciI' => ['CCGC', 'GCGG'],
    'TaqI' => ['TCGA']
  },
  'GR' => {
    'AciI' => ['CCGC', 'GCGG'],
    'TaqI' => ['TCGA']
  },
  'PR' => {
    'AciI' => ['CCGC', 'GCGG'],
    'TaqI' => ['TCGA']
  },
  'RR' => {
    'AciI' => ['CCGC', 'GCGG'],
    'TaqI' => ['TCGA']
  }
);
my %tthreetons = $tsuft->find_ntons(3);
is_deeply(\%tthreetons, \%rthreetons, "find three-tons");

#TESTING build_prefix_trees nuc
$rsuft = bless(
    {
        'root' => {
            'A' => {
                'C' => {
                    'T' => {
                        'G' => {
                            'G' => {
                                'ids' => {
                                    'BsrI' => []
                                },
                                'count'    => 1,
                                'sequence' => 'ACTGG'
                            }
                        }
                    }
                }
            },
            'T' => {
                'C' => {
                    'G' => {
                        'A' => {
                            'ids' => {
                                'TaqI' => []
                            },
                            'count'    => 1,
                            'sequence' => 'TCGA'
                        }
                    }
                }
            },
            'C' => {
                'C' => {
                    'A' => {
                        'G' => {
                            'T' => {
                                'ids' => {
                                    'BsrI' => []
                                },
                                'count'    => 1,
                                'sequence' => 'CCAGT'
                            },
                            'G' => {
                                'ids' => {
                                    'PspGI' => []
                                },
                                'count'    => 1,
                                'sequence' => 'CCAGG'
                            }
                        }
                    },
                    'T' => {
                        'G' => {
                            'G' => {
                                'ids' => {
                                    'PspGI' => []
                                },
                                'count'    => 1,
                                'sequence' => 'CCTGG'
                            }
                        }
                    },
                    'G' => {
                        'C' => {
                            'ids' => {
                                'AciI' => []
                            },
                            'count'    => 1,
                            'sequence' => 'CCGC'
                        }
                    }
                }
            },
            'G' => {
                'A' => {
                    'T' => {
                        'C' => {
                            'C' => {
                                'ids' => {
                                    'AlwI' => []
                                },
                                'count'    => 1,
                                'sequence' => 'GATCC'
                            }
                        }
                    }
                },
                'T' => {
                    'A' => {
                        'C' => {
                            'ids' => {
                                'RsaI' => []
                            },
                            'count'    => 1,
                            'sequence' => 'GTAC'
                        }
                    }
                },
                'C' => {
                    'G' => {
                        'G' => {
                            'ids' => {
                                'AciI' => []
                            },
                            'count'    => 1,
                            'sequence' => 'GCGG'
                        }
                    }
                },
                'G' => {
                    'A' => {
                        'T' => {
                            'C' => {
                                'ids' => {
                                    'AlwI' => []
                                },
                                'count'    => 1,
                                'sequence' => 'GGATC'
                            }
                        }
                    }
                }
            }
        }
    },
    'Bio::GeneDesign::PrefixTree'
);
$tsuft = $GD->build_prefix_tree(-input => \@alist);
is_deeply( $tsuft, $rsuft, "build_prefix_tree nuc" );

#TESTING search_prefix_trees nuc
$rhits = [
  ['AciI', 29, 'CCGC', []],
  ['PspGI', 61, 'CCTGG', []],
  ['AciI', 73, 'CCGC', []],
  ['AciI', 76, 'CCGC', []],
  ['AciI', 210, 'GCGG', []],
  ['AciI', 216, 'CCGC', []],
  ['BsrI', 227, 'ACTGG', []],
  ['PspGI', 264, 'CCAGG', []],
  ['AciI', 303, 'GCGG', []],
  ['TaqI', 386, 'TCGA', []],
  ['AlwI', 450, 'GATCC', []],
  ['AciI', 498, 'CCGC', []],
  ['AciI', 503, 'CCGC', []]
];
$thits = $GD->search_prefix_tree(-tree => $tsuft, -sequence => $orf);
is_deeply( $tsuft, $rsuft, "search_prefix_tree nuc" );
