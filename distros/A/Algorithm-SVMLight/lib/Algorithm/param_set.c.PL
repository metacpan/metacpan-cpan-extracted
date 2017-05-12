#!/usr/bin/perl

use strict;

my ($output) = @ARGV;
open STDOUT, "> $output" or die "Can't write $output: $!";

my %learn_parms = 
  (
   type => 'long',
   svm_c => 'double',
   eps => 'double',
   svm_costratio => 'double',
   transduction_posratio => 'double',
   biased_hyperplane => 'long',
   sharedslack => 'long',
   svm_maxqpsize => 'long',
   svm_newvarsinqp => 'long',
   kernel_cache_size => 'long',
   epsilon_crit => 'double',
   epsilon_shrink => 'double',
   svm_iter_to_shrink => 'long',
   maxiter => 'long',
   remove_inconsistent => 'long',
   skip_final_opt_check => 'long',
   compute_loo => 'long',
   rho => 'double',
   xa_depth => 'long',
  );

my %kernel_parms =
  (
   kernel_type => 'long',
   poly_degree => 'long',
   rbf_gamma => 'double',
   coef_lin => 'double',
   coef_const => 'double',
  );

foreach my $p (sort keys %learn_parms) {
  my $type = $learn_parms{$p};
  print <<EOF;
void
set_$p (SV *self, $type val)
CODE:
  ((LEARN_PARM*) self_fetch(self, "_learn_parm"))->$p = val;

$type
get_$p (SV *self)
CODE:
  RETVAL = ((LEARN_PARM*) self_fetch(self, "_learn_parm"))->$p;
OUTPUT:
  RETVAL

EOF
}

foreach my $p (sort keys %kernel_parms) {
  my $type = $kernel_parms{$p};
  print <<EOF;
void
set_$p (SV *self, $type val)
CODE:
  ((KERNEL_PARM*) self_fetch(self, "_kernel_parm"))->$p = val;

$type
get_$p (SV *self)
CODE:
  RETVAL = ((KERNEL_PARM*) self_fetch(self, "_kernel_parm"))->$p;
OUTPUT:
  RETVAL

EOF
}

# A couple special cases for strings
print <<'EOF'

void
set_predfile (SV *self, char *predfile)
CODE:
  LEARN_PARM *learn_parm = (LEARN_PARM*) self_fetch(self, "_learn_parm");
  strncpy(learn_parm->predfile, predfile, sizeof(learn_parm->predfile)-1);
  learn_parm->predfile[sizeof(learn_parm->predfile)-1] = '\0';

void
set_alphafile (SV *self, char *alphafile)
CODE:
  LEARN_PARM *learn_parm = (LEARN_PARM*) self_fetch(self, "_learn_parm");
  strncpy(learn_parm->alphafile, alphafile, sizeof(learn_parm->alphafile)-1);
  learn_parm->alphafile[sizeof(learn_parm->alphafile)-1] = '\0';

void
set_custom (SV *self, char *custom)
CODE:
  KERNEL_PARM *kernel_parm = (KERNEL_PARM*) self_fetch(self, "_kernel_parm");
  strncpy(kernel_parm->custom, custom, sizeof(kernel_parm->custom)-1);
  kernel_parm->custom[sizeof(kernel_parm->custom)-1] = '\0';

EOF
