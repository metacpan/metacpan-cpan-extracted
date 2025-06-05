use strict;
use warnings;
my @api;
while (<STDIN>) {
   chomp;
   if (/^extern /) {
      chomp($_ .= <STDIN> || die "failed to find ;") until /;$/;
      my ($type, $name, $args)= /extern (\S+(?: \S+)*)\s+([^(]+)\s*\(([^)]+)\);/
         or die "Can't parse extern: $_";
      my $proto= "$type $name($args)";
      push @api, { type => $type, name => $name, args => $args, proto => $proto };
   }
}

if (@ARGV == 1 && $ARGV[0] eq '--list-prototypes') {
   print "$_->{proto}\n" for @api;
   exit 0;
}

$"= "\n";
print <<END;
#ifndef SECRET_BUFFER_MANUAL_LINKAGE_H
#define SECRET_BUFFER_MANUAL_LINKAGE_H

#define SECRET_BUFFER_DECLARE_FUNCTION_POINTERS \\
@{[ map " extern $_->{type} (*$_->{name}_fp)($_->{args}); \\", @api ]}
@{[ map " #define $_->{name} $_->{name}_fp \\", @api ]}

#define SECRET_BUFFER_DEFINE_FUNCTION_POINTERS \\
@{[ map " $_->{type} (*$_->{name}_fp)($_->{args}) = NULL; \\", @api ]}
 \\
static void secret_buffer_import_function_pointer(pTHX_ HV *api, void **dest, const char *name, const char *signature) { \\
   SV **svp = hv_fetch(api, name, strlen(name), 0); \\
   const char *actual_sig; \\
   if (!svp || !*svp) croak("Can't find symbol: %s", signature); \\
   actual_sig= SvPV_nolen(*svp); \\
   if (strcmp(actual_sig, signature)) croak("API Mismatch: %s vs %s", signature, actual_sig); \\
   if (!SvIOK(*svp)) croak("Invalid function pointer for %s", name); \\
   *dest= (void*) SvIV(*svp); \\
}

#define SECRET_BUFFER_IMPORT_FUNCTION_POINTERS \\
   { HV *c_api = get_hv("Crypt::SecretBuffer::C_API", 0); \\
     if (!c_api) croak("Can't find Crypt::SecretBuffer::C_API"); \\
@{[ map qq{     secret_buffer_import_function_pointer(aTHX_ c_api, (void*)&$_->{name}_fp, "$_->{name}", "$_->{proto}"); \\}, @api ]}
   }

#define SECRET_BUFFER_EXPORT_FUNCTION_POINTERS \\
   { HV *c_api = get_hv("Crypt::SecretBuffer::C_API", GV_ADD); \\
@{[ map qq{     hv_stores(c_api, "$_->{name}", new_enum_dualvar(aTHX_ (IV)($_->{name}), newSVpvs("$_->{proto}"))); \\}, @api ]}
   }

#endif
END
