#!/bin/bash

function my_complete
{
   for n in `seq 0 $COMP_CWORD` ; do
     export COMP_WORD_$n=${COMP_WORDS[$n]}
   done
   set | egrep ^COMP
   echo '******'
   export `set | egrep ^COMP_[_A-Z]+= | cut -d= -f1`
   echo '******'
   perl -E 'for my $env (sort grep { /^COMP/ } keys %ENV) { say "$env  => $ENV{$env}" }'
   echo '******'
   perl -MData::Dump=pp -E 'say pp(\@ARGV)' ${COMP_WORDS[@]}
}

complete -F my_complete xpto

