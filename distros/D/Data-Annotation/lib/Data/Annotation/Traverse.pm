package Data::Annotation::Traverse;
use v5.24;
use experimental qw< signatures >;
use Scalar::Util qw< blessed refaddr reftype >;

use Exporter qw< import >;
our @EXPORT_OK = qw< MISSING crumble kpath means_missing traverse_plain >;
our %EXPORT_TAGS = (all => \@EXPORT_OK);

use constant MISSING => \"Bubù-non-c'è-più";

sub crumble ($input) {
   return unless defined $input;
   return $input if ref($input);
 
   $input =~ s{\A\s+|\s+\z}{}gmxs;
   return [] unless length $input;
 
   my $sq    = qr{(?mxs: ' [^']* ' )}mxs;
   my $dq    = qr{(?mxs: " (?:[^\\"] | \\.)* " )}mxs;
   my $ud    = qr{(?mxs: \w+ )}mxs;
   my $chunk = qr{(?mxs: $sq | $dq | $ud)+}mxs;
 
   # save and reset current pos() on $input
   my $prepos = pos($input);
   pos($input) = undef;
 
   my @path;
   push @path, $1 while $input =~ m{\G [.]? ($chunk) }cgmxs;
 
   # save and restore pos() on $input - FIXME do we really need this?!?
   my $postpos = pos($input);
   pos($input) = $prepos;
 
   return unless defined $postpos;
   return if ($postpos != length($input));
 
   # cleanup @path components
   for my $part (@path) {
      my @subparts;
      while ((pos($part) || 0) < length($part)) {
         if ($part =~ m{\G ($sq) }cgmxs) {
            push @subparts, substr $1, 1, length($1) - 2;
         }
         elsif ($part =~ m{\G ($dq) }cgmxs) {
            my $subpart = substr $1, 1, length($1) - 2;
            $subpart =~ s{\\(.)}{$1}gmxs;
            push @subparts, $subpart;
         }
         elsif ($part =~ m{\G ($ud) }cgmxs) {
            push @subparts, $1;
         }
         else {    # shouldn't happen ever
            return;
         }
      } ## end while ((pos($part) || 0) ...)
      $part = join '', @subparts;
   } ## end for my $part (@path)
 
   return \@path;
} ## end sub crumble

sub kpath ($input) {
   return unless defined $input;
   $input = crumble($input) unless ref($input);
   return join '.',
      map { s{([.%])}{sprintf('%%%02x', ord($1))}regmxs } $input->@*;
}

sub means_missing ($x) { ref($x) && refaddr($x) == refaddr(MISSING) }

# The following function is long and complex because it deals with many
# different cases. It is kept as-is to avoid too many calls to other
# subroutines; for this reason, it's reasonably commented.
sub traverse_plain ($node, $crumbs, %opts) {

   # figure out what to do with blessed objects, based on configuration
   my $traverse_methods = $opts{traverse_methods} || 0;
   my ($strict_blessed, $method_pre) = (0, 0);
   if ($traverse_methods) {
      $strict_blessed = $opts{strict_blessed} || 0;
      $method_pre = ((! $strict_blessed) && $opts{method_over_key}) || 0;
   }

   for my $key ($crumbs->@*) {
      
      # $ref tells me how to look down into $$ref_to_child, i.e. as
      # an ARRAY or a HASH or a CODE or an object.
      my $ref = reftype($node);

      # if $ref is not true, we hit a wall and cannot go past
      return MISSING unless $ref;

      # set up for the tests
      my $is_blessed = blessed($node);
      my $method = $is_blessed && $traverse_methods && $node->can($key);
 
      # DWIM dispatch table
      if ($is_blessed && $strict_blessed) {
         return MISSING unless $method;
         ($node) = $node->$method or return MISSING;
      }
      elsif ($method && $method_pre) {
         ($node) = $node->$method or return MISSING;
      }
      elsif ($ref eq 'CODE') {
         ($node) = $node->($key) or return MISSING;
      }
      elsif ($ref eq 'HASH') {
         return MISSING unless exists($node->{$key});
         $node = $node->{$key};
      }
      elsif ($ref eq 'ARRAY') {
         return MISSING
            if $key !~ m{\A (?: 0 | [1-9] \d*) \z}mxs || $key > $node->$#*;
         $node = $node->[$key];
      }
      elsif ($method && $traverse_methods) {
         ($node) = $node->$method or return MISSING;
      }
      else {
         return MISSING;
      }

   } ## end for my $crumb (@$crumbs)

   return $node;
} ## end sub traverse

1;
