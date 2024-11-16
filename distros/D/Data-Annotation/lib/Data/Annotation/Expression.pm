package Data::Annotation::Expression;
use v5.24;
use utf8;
use warnings;
use experimental qw< signatures >;
{ our $VERSION = '0.004' }

use Data::Annotation::Traverse qw< crumble traverse_plain >;
use Exporter qw< import >;
our @EXPORT_OK = qw< evaluator_factory >;

sub evaluator_factory ($definition, $parse_ctx = {}) {
   my %parse_ctx = $parse_ctx->%*;

   # the ::Builtin is injected by default to support
   # built-ins. It's possible to disable it but only explicitly, providing
   # a true value for key 'no-builtin'.
   if (! $parse_ctx{'no-builtin'}) {
      my @prefixes = ($parse_ctx{'locator-relative-prefixes'} // [])->@*;
      push @prefixes, qw< Data::Annotation::Expression::Builtin >;
      $parse_ctx{'locator-relative-prefixes'} = \@prefixes;
   }

   return generate_function(\%parse_ctx, $definition);
}

########################################################################
#
# Private part follows

sub default_definition_normalizer ($parse_ctx, $definition) {
   die "undefined definition\n" unless defined($definition);

   # if it's a string definition... best wishes!
   if (ref($definition) eq '') {
      return { type => 'data', value => '' } unless length($definition);

      return { type => 'context', path => ($1 // '') }
         if $definition =~ m{\A context (?: \z | \. (.*)) }mxs;

      my $first = substr($definition, 0, 1);
      my $rest = substr($definition, 1);
      return { type => 'context', path => "run.$rest" } if $first eq '.';
      return { type => 'data', value => $rest } if $first eq '=';
      return { type => 'sub',  name  => $rest } if $first eq '&';

      # complain loudly here, i.e. unhandled first characters...
      die "cannot parse definition '$definition'\n"
         unless ref($definition);
   }

   my %copy = $definition->%*;

   # if the definition contains "type" then it's expected to *almost* in
   # normalized form. We might admit that args were not provided in
   # subs and set them to an empty array reference in this case.
   if (exists($copy{type})) { # should be mostly fine
      my $type = $copy{type};
      if (! defined($type)) { die "undefined type in definition\n" }
      elsif ($type eq 'data') {
         die "missing value for data request in definition\n"
            unless exists($copy{value});
         return \%copy;
      }
      elsif ($type eq 'sub') {
         die "missing locator of required sub in definition\n"
            unless exists($copy{name});
         $copy{args} //= [];
      }
      else { } # nothing to check, normalization complete
      return \%copy;
   }

   if (scalar(keys(%copy)) == 1) { # we're in DWIM land here
      my ($key, $value) = %copy;
      return { type  => 'data', value => $value }
         if $key eq 'data';
      return { type => 'sub', name => $value, args => [] }
         if $key eq 'sub';
      if ($key eq 'context') {
         $value = 'run' . $value
            if length($value // '') && substr($value, 0, 1) eq '.';
         return { type => 'context', path => $value };
      }
      return { type => 'sub', package => $1, name => $2, args => $value }
         if $key =~ m{\A (.+) (?: :: | /) (.+)}mxs; 
      return { type => 'sub', name => $key, args => $value };
   }
   else {
      die "cannot normalize definition\n";
   }

   # should never be reached
   ...
}

sub generate_function ($parse_ctx, $definition) {
   my $normalizer = exists($parse_ctx->{'definition-normalizer'})
      ? $parse_ctx->{'definition-normalizer'}
      : __PACKAGE__->can('default_definition_normalizer');
   $definition = $normalizer->($parse_ctx, $definition)
      if defined($normalizer);

   my $type = $definition->{type};
   my $parser = __PACKAGE__->can("generate_function_$type")
      or die "no parser for function type '$type'\n";
   return $parser->($parse_ctx, $definition);
}

sub generate_function_data ($parse_ctx, $definition) {
   return sub ($overlay) { return $definition->{value} };
}

sub generate_function_context ($parse_ctx, $definition) {
   my $path = $definition->{path} // '';
   my ($entry, @crumbs) = crumble($path)->@*;

   # the runtime context is a Data::Annotation::Overlay instance. For
   # 'run' we plug directly into it, otherwise we use its access options
   # for other data, but without the overlay/caching
   return sub ($overlay) { $overlay->get(\@crumbs) } if $entry eq 'run';
   my $other = { definition => $definition, parse => $parse_ctx };
   return sub ($overlay) {
      return $overlay->get_external([$entry, @crumbs], $other);
   };
}

sub generate_function_sub ($parse_ctx, $definition) {
   my ($name, $package) = $definition->@{qw< name package >};
   my $function = resolve_function($parse_ctx, $name, $package);
   my @args = map { generate_function($parse_ctx, $_) }
      ($definition->{args} // [])->@*;
   return sub ($overlay) { $function->(map { $_->($overlay) } @args) };
}

sub resolve_function ($parse_ctx, $name, $package) {
   die "undefined sub name\n" unless defined($name);
   die "empty sub name\n"     unless length($name);

   my $suffix = $package //= '';
   my $is_absolute = $suffix =~ s{\A /}{}mxs;
   my $relative_prefixes = $parse_ctx->{'locator-relative-prefixes'};
   my @prefixes = $is_absolute ? ('') : (($relative_prefixes // [])->@*);

   my $function;
   PREFIX:
   for my $prefix (@prefixes) {
      my $module = join('::', grep { length } ($prefix, $suffix));
      #warn "module<$module> name<$name>";

      for (1 .. 2) { # first try directly, then require $module
         if (my $factory = $module->can('factory')) {
            $function = $factory->($parse_ctx, $name);
            return $function if defined($function);
            next PREFIX; # if a factory exists, no more attempts anyway
         }
         elsif ($function = $module->can($name)) {
            return $function;
         }
         else { # prepare for next attempt, if we still have one
            #warn "Loading module <$module>";
            eval { require_module($module) } or do {
               #warn "error: $@";
               next PREFIX;
            };
            #warn "Loaded module <$module>";
         }
      }
   }

   die "cannot find sub for '$name'\n";
}

sub require_module ($module) {
   my $path = "$module.pm" =~ s{::}{/}rgmxs;
   require $path;
}

1;
