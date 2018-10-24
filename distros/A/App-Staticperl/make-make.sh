#! sh

# newer Storable versions have some weird hack to try to measure the
# stack size at build time, for reasons not well understood. it seems
# perl5-porters think that stack sizes cannot be configured so compile time
# stack size always equals runtime stack size. very weird, potential security
# bug and doesn't even work, so work around it.
if [ -e Storable.pm.PL ] && [ -e stacksize ]; then
   echo patching stacksize bug in Storable
   cat >stacksize <<'EOSS'
#! perl
mkdir "lib", 0777;
mkdir "lib/Storable", 0777;
open my $fh, ">lib/Storable/Limit.pm" or die;
syswrite $fh, <<EOPM;
# patched by staticperl
\$Storable::recursion_limit = 512
  unless defined \$Storable::recursion_limit;
\$Storable::recursion_limit_hash = 512
  unless defined \$Storable::recursion_limit_hash;
1;
EOPM
EOSS
fi

"$MAKE" "$@"

