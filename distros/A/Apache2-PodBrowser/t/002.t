# -*- mode: cperl; cperl-indent-level: 4; cperl-continued-statement-offset: 4; indent-tabs-mode: nil -*-
use strict;
use warnings FATAL => 'all';

use Apache::Test qw/-withtestmore/;
use Apache::TestUtil;
use Apache::TestRequest qw{GET_BODY GET_RC};

Apache::TestRequest::user_agent(reset => 1,
				requests_redirectable => 0);

my @functions=qw/ -X abs accept alarm atan2 bind binmode bless caller
                  chdir chmod chomp chop chown chr chroot close closedir
                  connect continue cos crypt dbmclose dbmopen defined
                  delete die do dump each endgrent endhostent endnetent
                  endprotoent endpwent endservent eof eval exec exists
                  exit exp fcntl fileno flock fork format formline getc
                  getgrent getgrgid getgrnam gethostbyaddr gethostbyname
                  gethostent getlogin getnetbyaddr getnetbyname getnetent
                  getpeername getpgrp getppid getpriority getprotobyname
                  getprotobynumber getprotoent getpwent getpwnam getpwuid
                  getservbyname getservbyport getservent getsockname
                  getsockopt glob gmtime goto grep hex import index int
                  ioctl join keys kill last lc lcfirst length link listen
                  local localtime lock log lstat m map mkdir msgctl msgget
                  msgrcv msgsnd my next no oct open opendir ord our pack
                  package pipe pop pos print printf prototype push q qq qr
                  quotemeta qw qx rand read readdir readline readlink
                  readpipe recv redo ref rename require reset return reverse
                  rewinddir rindex rmdir s scalar seek seekdir select semctl
                  semget semop send setgrent sethostent setnetent setpgrp
                  setpriority setprotoent setpwent setservent setsockopt
                  shift shmctl shmget shmread shmwrite shutdown sin sleep
                  socket socketpair sort splice split sprintf sqrt srand
                  stat study sub substr symlink syscall sysopen
                  sysread sysseek system syswrite tell telldir tie tied
                  time times tr truncate uc ucfirst umask undef unlink
                  unpack unshift untie use utime values vec wait waitpid
                  wantarray warn write y /;

my @variables=(qw, $_ $a $b $1..$N $& $` $' $+ $^N @+ $. $/ $|,, '$,',
               qw, $\ $" $; $% $= $- @- $~ $^ $: $^A $? ${^ENCODING} $! %!
                   $^E $@ $$ $< $> $( $) $0 $[ $] $^C $^D $^F $^H %^H $^I
                   $^M $^O ${^OPEN} $^P $^R $^S $^T ${^TAINT} ${^UNICODE}
                   ${^UTF8LOCALE} $^V $^W ${^WARNING_BITS} $^X ARGV ARGVOUT
                   @F @INC @_ %INC %ENV %SIG ,);

#plan 'no_plan';
plan tests => 2*(@functions+@variables);

my $resp=GET_BODY("/perldoc/??");

##########################################
# Function Index
##########################################
t_debug 'Testing Function Index';

for my $name (@functions) {
    like $resp, qr!<a href="\./\?\Q$name\E" title="\Q$name\E">\Q$name\E</a>!,
        'Index: '.$name;
    is GET_RC("/perldoc/?".$name), 200, 'got it: '.$name;
}

##########################################
# Variable Index
##########################################
t_debug 'Testing Variable Index';

for my $name (@variables) {
    if( $name eq '$"' ) {
        like( $resp,
              qr!<a href="\./\?\$%22" title="\$&quot;">\$&quot;</a>!,
              'Index: '.$name );
    } elsif( $name eq '$%' ) {
        like( $resp,
              qr!<a href="\./\?\$%25" title="\$%">\$%</a>!,
              'Index: '.$name );
    } elsif( $name eq '$&' ) {
        like( $resp,
              qr!<a href="\./\?\$&" title="\$&amp;">\$&amp;</a>!,
              'Index: '.$name );
    } elsif( $name eq '$<' ) {
        like( $resp,
              qr!<a href="\./\?\$<" title="\$&lt;">\$&lt;</a>!,
              'Index: '.$name );
    } elsif( $name eq '$>' ) {
        like( $resp,
              qr!<a href="\./\?\$>" title="\$&gt;">\$&gt;</a>!,
              'Index: '.$name );
    } elsif( $name =~ /^%/ ) {
        my $x=substr($name, 1);
        like( $resp,
              qr!<a href="\./\?%25\Q$x\E" title="\Q$name\E">\Q$name\E</a>!,
              'Index: '.$name );
    } else {
        like( $resp,
              qr!<a href="\./\?\Q$name\E" title="\Q$name\E">\Q$name\E</a>!,
              'Index: '.$name );
    }
    is GET_RC("/perldoc/?".$name), 200, 'got it: '.$name;
}
