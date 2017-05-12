
package Apache::MP3::L10N::Aliases;
$VERSION = '1.01';
use strict;

# This is a clunky class-autoloading system for subclasses that are
# totally vacuous.
#
# We need this only for languages with lots of subvariants that aren't
# any different from eachother.  It saves us from having to create a
# file for each subvariant.

my %Aliases = (
  'en' =>
    [qw< en_au en_ca en_gb en_ie en_in
         en_jm en_nz en_ph en_us en_za i_default
    >],
  'de' =>
    [qw< de_at de_be de_ch de_de de_li de_lu >],
  'fr' =>
    [qw< fr_be fr_ca fr_ch fr_fr fr_lu fr_mc >],
  'es' =>
    [qw< es_ar es_bo es_cl es_co es_cr es_do es_ec
         es_es es_gt es_hn es_mx es_pa es_pe es_pr
         es_py es_sv es_us es_uy es_ve
         es_cu
    >],

  'ar' =>
    [qw< ar_ae ar_bh ar_dz ar_eg ar_iq ar_jo ar_kw
         ar_lb ar_ly ar_ma ar_om ar_qa ar_sa ar_sy
         ar_tn ar_ye
         ar_ps
    >],
);

sub autoload_and_new {
  my $superclass = shift @_;
  my $subclass   = shift @_;
  #print "Loading $superclass\n";
  eval  "require $superclass;";
  #print "No loading: $@" if $@;
  die $@ if $@;
  {
    no strict 'refs';
    @{$subclass . '::ISA'} = $superclass;
    #print "Setting \@$subclass\::ISA to ", @{$subclass . '::ISA'}, "\n";
    undef *{$subclass . '::new'};
      # Take out the autoloader new() that called us
  }
  return $subclass->new(@_);
}


{
  # Drop in place the autoloader new()s
  require UNIVERSAL;
  my($superclass,$subclasses);
  while( ($superclass, $subclasses) = each %Aliases ) {
    my $superclass = 'Apache::MP3::L10N::' . lc($superclass);
    
    foreach my $subclass (ref($subclasses) ? @$subclasses : $subclasses) {
      no strict 'refs';
      my $subclass = 'Apache::MP3::L10N::' . lc($subclass);
      #print "setting \@$subclass\::ISA\n";
      
      @{$subclass . '::ISA'} = 'UNIVERSAL'; # just so it looks defined
      *{ $subclass . '::new'} = sub {
        unshift @_, $superclass;
        goto &autoload_and_new;
      };
    }
  }
}

1;

