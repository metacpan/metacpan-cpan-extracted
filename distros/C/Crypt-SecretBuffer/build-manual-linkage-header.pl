use strict;
use warnings;
my @api;
while (<STDIN>) {
   chomp;
   if (/^extern /) {
      chomp($_ .= <STDIN> || die "failed to find ;") until /;$/;
      my ($type, $name, $args)= /extern (\S+(?: \S+)*)\s+(\w+)\s*\(([^)]+)\);/
         or die "Can't parse extern: $_";
      # collapse runs of whitespace
      s/\s\s+/ /g for $type, $name, $args;
      # prototype incudes argument names
      my $proto= "$type $name($args)";
      # Signature does not include argument names
      (my $sig= $proto) =~ s/\s*\w+\s*([,)])/$1/g;
      push @api, { type => $type, name => $name, args => $args, proto => $proto, sig => $sig };
   }
}

if (@ARGV == 1 && $ARGV[0] eq '--list-prototypes') {
   print "$_->{proto}\n" for @api;
   exit 0;
}

print <<END;
#ifndef SECRET_BUFFER_MANUAL_LINKAGE_H
#define SECRET_BUFFER_MANUAL_LINKAGE_H

#define SECRET_BUFFER_EXPORT_FUNCTION_POINTERS \\
   { HV *c_api = get_hv("Crypt::SecretBuffer::C_API", GV_ADD); \\
     SV *sv; \\
@{[ map <<END_API_FN, @api ]} \\
     sv= get_sv("Crypt::SecretBuffer::C_API::$_->{sig}", GV_ADD); \\
     sv_setpvs(sv, "$_->{proto}"); \\
     hv_stores(c_api, "$_->{name}", SvREFCNT_inc(make_enum_dualvar(aTHX_ (IV)($_->{name}), sv))); \\
END_API_FN
   }

#endif
END
