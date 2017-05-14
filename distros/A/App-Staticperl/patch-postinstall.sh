#! sh

# helper to apply patches after installation

patch() {
   path="$PERL_PREFIX/lib/$1"
   cache="$STATICPERL/patched/$2"
   sed="$3"

   if "$PERL_PREFIX/bin/perl" -e 'exit 0+((stat shift)[7] == (stat shift)[7])' "$path" "$cache" ||
      "$PERL_PREFIX/bin/perl" -e 'exit 0+((stat shift)[9] <= (stat shift)[9])' "$path" "$cache"
   then
      if  [ -e "$path" ]; then
         echo "patching $path for a better tomorrrow"

         umask 022
         if ! sed -e "$sed" <"$path" > "$cache~"; then
            echo
            echo "*** FATAL: error while patching $path"
            echo
         else
            rm -f "$path"
            mv "$cache~" "$path"
            cp "$path" "$cache"
         fi
      fi
   fi
}

# patch CPAN::HandleConfig.pm to always include _our_ MyConfig.pm,
# not the one in the users homedirectory, to avoid clobbering his.
patch CPAN/HandleConfig.pm cpan_handleconfig_pm '
1i\
use CPAN::MyConfig; # patched by staticperl
'

# patch ExtUtils::MM_Unix to always search blib for modules
# when building a perl - this works around Pango/Gtk2 being misdetected
# as not being an XS module.
patch ExtUtils/MM_Unix.pm mm_unix_pm '
/^sub staticmake/,/^}/ s/if (@{$self->{C}}) {/if (@{$self->{C}} or $self->{NAME} =~ m%^(Pango|Gtk2)$%) { # patched by staticperl/
'

# patch ExtUtils::Miniperl to always add DynaLoader
# this is required for dynamic loading in static perls,
# and static loading in dynamic perls, when rebuilding a new perl.
# Why this patch is necessray I don't understand. Yup.
patch ExtUtils/Miniperl.pm extutils_miniperl.pm '
/^sub writemain/ a\
    push @_, "DynaLoader"; # patched by staticperl
'

# ExtUtils::CBuilder always tries to link shared libraries
# even on systems without shared library support. From the same
# source as Module::Build, so no wonder it's broken beyond fixing.
# and since so many dependent modules are even worse,
# we hardwire to 0 to get their pure-perl versions.
patch ExtUtils/CBuilder/Base.pm extutils_cbuilder_base.pm '
/^sub have_compiler/ a\
   return 0; # patched by staticperl
'

