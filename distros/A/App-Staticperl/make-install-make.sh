#! sh

"$MAKE" || exit

if find blib/arch/auto -type f \( -name "*.a" -o -name "*.obj" -o -name "*.lib" \) | grep -q .; then
   echo Probably a static XS module, rebuilding perl
   if "$MAKE" all perl; then
      mv perl "$PERL_PREFIX"/bin/perl~ \
         && rm -f "$PERL_PREFIX"/bin/perl \
         && mv "$PERL_PREFIX"/bin/perl~ "$PERL_PREFIX"/bin/perl
      "$MAKE" -f Makefile.aperl map_clean
   else
      "$MAKE" -f Makefile.aperl map_clean
      exit 1
   fi
fi

"$MAKE" install UNINST=1 || exit

"$PERL_PREFIX"/bin/SP-patch-postinstall

