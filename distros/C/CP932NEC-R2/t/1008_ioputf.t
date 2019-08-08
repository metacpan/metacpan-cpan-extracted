######################################################################
#
# 1008_ioputf.t
#
# Copyright (c) 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use CP932NEC::R2;
use vars qw(@test);

@test = (
# 1
    sub { open(FH,'>a');                        ioputf(FH,'あ');               close(FH);                  open(FH,'a'); my $got = ioget(FH); close(FH); unlink('a'); $got eq 'あ'        },
    sub { open(FH,'>a');                        ioputf(FH,'あ%04d', 1);        close(FH);                  open(FH,'a'); my $got = ioget(FH); close(FH); unlink('a'); $got eq 'あ0001'    },
    sub { open(FH,'>a');                        ioputf(FH,'あ%sう', 'い');     close(FH);                  open(FH,'a'); my $got = ioget(FH); close(FH); unlink('a'); $got eq 'あいう'    },
    sub { open(FH,'>a');                        ioputf(FH,'あ%1sう', 'い');    close(FH);                  open(FH,'a'); my $got = ioget(FH); close(FH); unlink('a'); $got eq 'あいう'    },
    sub { open(FH,'>a');                        ioputf(FH,'あ%2sう', 'い');    close(FH);                  open(FH,'a'); my $got = ioget(FH); close(FH); unlink('a'); $got eq 'あいう'    },
    sub { open(FH,'>a');                        ioputf(FH,'あ%3sう', 'い');    close(FH);                  open(FH,'a'); my $got = ioget(FH); close(FH); unlink('a'); $got eq 'あ いう'   },
    sub { open(FH,'>a');                        ioputf(FH,'あ%-3sう', 'い');   close(FH);                  open(FH,'a'); my $got = ioget(FH); close(FH); unlink('a'); $got eq 'あい う'   },
    sub { open(FH,'>a');                        ioputf(FH,'あ%-3sえ', 'いう'); close(FH);                  open(FH,'a'); my $got = ioget(FH); close(FH); unlink('a'); $got eq 'あいうえ'  },
    sub { open(FH,'>a');                        ioputf(FH,'あ%-4sえ', 'いう'); close(FH);                  open(FH,'a'); my $got = ioget(FH); close(FH); unlink('a'); $got eq 'あいうえ'  },
    sub { open(FH,'>a');                        ioputf(FH,'あ%-5sえ', 'いう'); close(FH);                  open(FH,'a'); my $got = ioget(FH); close(FH); unlink('a'); $got eq 'あいう え' },
# 11
    sub { open(FH,'>a'); my $select=select(FH); ioputf('あ');                  close(FH); select($select); open(FH,'a'); my $got = ioget(FH); close(FH); unlink('a'); $got eq 'あ'        },
    sub { open(FH,'>a'); my $select=select(FH); ioputf('あ%04d', 1);           close(FH); select($select); open(FH,'a'); my $got = ioget(FH); close(FH); unlink('a'); $got eq 'あ0001'    },
    sub { open(FH,'>a'); my $select=select(FH); ioputf('あ%sう', 'い');        close(FH); select($select); open(FH,'a'); my $got = ioget(FH); close(FH); unlink('a'); $got eq 'あいう'    },
    sub { open(FH,'>a'); my $select=select(FH); ioputf('あ%1sう', 'い');       close(FH); select($select); open(FH,'a'); my $got = ioget(FH); close(FH); unlink('a'); $got eq 'あいう'    },
    sub { open(FH,'>a'); my $select=select(FH); ioputf('あ%2sう', 'い');       close(FH); select($select); open(FH,'a'); my $got = ioget(FH); close(FH); unlink('a'); $got eq 'あいう'    },
    sub { open(FH,'>a'); my $select=select(FH); ioputf('あ%3sう', 'い');       close(FH); select($select); open(FH,'a'); my $got = ioget(FH); close(FH); unlink('a'); $got eq 'あ いう'   },
    sub { open(FH,'>a'); my $select=select(FH); ioputf('あ%-3sう', 'い');      close(FH); select($select); open(FH,'a'); my $got = ioget(FH); close(FH); unlink('a'); $got eq 'あい う'   },
    sub { open(FH,'>a'); my $select=select(FH); ioputf('あ%-3sえ', 'いう');    close(FH); select($select); open(FH,'a'); my $got = ioget(FH); close(FH); unlink('a'); $got eq 'あいうえ'  },
    sub { open(FH,'>a'); my $select=select(FH); ioputf('あ%-4sえ', 'いう');    close(FH); select($select); open(FH,'a'); my $got = ioget(FH); close(FH); unlink('a'); $got eq 'あいうえ'  },
    sub { open(FH,'>a'); my $select=select(FH); ioputf('あ%-5sえ', 'いう');    close(FH); select($select); open(FH,'a'); my $got = ioget(FH); close(FH); unlink('a'); $got eq 'あいう え' },
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
