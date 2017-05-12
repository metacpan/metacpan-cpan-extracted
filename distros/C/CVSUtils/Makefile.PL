use 5.005_03;
use strict;

use File::Spec qw( );
sub catfile { File::Spec->catfile(@_) }

use constant MOD_REQS => [];
use constant EXEC_REQS => [];

use constant NAME         => 'CVSUtils';
use constant VERSION_FROM => catfile (qw( lib CVX Utils.pm ));
use constant AUTHOR       => 'Martyn J. Pearce fluffy@cpan.org';
use constant ABSTRACT     => 'Utils for working with CVS';

use constant DEPENDS      => [
                              {
                               target => 'cvs2cl.pl',
                               reqs   => [catfile(qw( bin cvs2cl ))],
                               rules  => ['$(PERL) make-cvs2cl.pl $< > $@',
                                          '$(PERL) -e "chmod 0755, @ARGV" $@',
                                         ],
                              },

                              { target => 'test-pl',
                                env    => { CVS2CL =>
                                            '$(shell pwd)/cvs2cl.pl' },
                                reqs   => [qw( cvs2cl.pl test )],
                                rules  => [],
                              }
# NEED TO GENERATE
#
#export CVS2CL
#test-pl: CVS2CL=$(shell pwd)/cvs2cl.pl
#test-pl: cvs2cl.pl test
                      ];

use FindBin 1.42 qw( $Bin );
use lib $Bin;
use make;

