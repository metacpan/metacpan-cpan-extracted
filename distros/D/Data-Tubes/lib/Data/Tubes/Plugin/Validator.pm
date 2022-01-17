package Data::Tubes::Plugin::Validator;
use strict;
use warnings;
use English qw< -no_match_vars >;
our $VERSION = '0.740';

use Log::Log4perl::Tiny qw< :easy :dead_if_first >;

use Data::Tubes::Util
  qw< args_array_with_options normalize_args shorter_sub_names >;
use Data::Tubes::Plugin::Util qw< identify >;
my %global_defaults = (input => 'structured',);

sub validate_admit {
   my ($validators, $args) = args_array_with_options(
      @_,
      {
         input => 'raw',
         name  => 'validate with acceptance regexp',
      }
   );
   identify($args);
   my $name   = $args->{name};
   my $input  = $args->{input};
   my $refuse = $args->{refuse};
   return sub {
      my $record = shift;
      my $target = defined($input) ? $record->{$input} : $record;
      for my $validator (@$validators) {
         my $outcome =
           (ref($validator) eq 'CODE')
           ? $validator->($target)
           : ($target =~ m{$validator});
         return unless ($outcome xor $refuse);
      } ## end for my $validator (@$validators)
      return $record;
   };
} ## end sub validate_admit

sub validate_refuse {
   my ($validators, $args) = args_array_with_options(
      @_,
      {
         input => 'raw',
         name  => 'validate with rejection regexp',
      }
   );
   $args->{refuse} = 1;
   return validate_admit(@$validators, $args);
} ## end sub validate_refuse

sub validate_refuse_comment {
   my $args = normalize_args(@_, {name => 'validate reject comment line'});
   identify($args);
   return validate_refuse(qr{(?mxs:\A \s* \#)}, $args);
}

sub validate_refuse_comment_or_empty {
   my $args = normalize_args(@_,
      {name => 'validate reject comment or non-spaces-only line'});
   identify($args);
   return validate_refuse(qr{(?mxs:\A \s* (?: \# | \z ))}, $args);
} ## end sub validate_refuse_comment_or_empty

sub validate_refuse_empty {
   my $args = normalize_args(@_,
      {name => 'validate reject empty (non-spaces only) string'});
   identify($args);
   return validate_refuse(qr{(?mxs:\A \s* \z)}, $args);
} ## end sub validate_refuse_empty


sub validate_thoroughly {
   my ($validators, $args) = args_array_with_options(
      @_,
      {
         %global_defaults,
         name           => 'validate with subs',
         output         => 'validation',
         keep_positives => 0,
         keep_empty     => 0,
         wrapper        => undef,
      }
   );
   identify($args);
   my $name = $args->{name};

   my $wrapper = $args->{wrapper};
   if ($wrapper && $wrapper eq 'try') {
      eval { require Try::Catch; }
        or LOGCONFESS 'Validator::validate_with_subs '
        . 'needs Try::Catch, please install';

      $wrapper = sub {
         my ($validator, @params) = @_;
         return Try::Catch::try(
            sub { $validator->(@params); },
            Try::Catch::catch(sub { return (0, $_); }),
         );
      };
   } ## end if ($wrapper && $wrapper...)

   my $input          = $args->{input};
   my $output         = $args->{output};
   my $keep_positives = $args->{keep_positives};
   my $keep_empty     = $args->{keep_empty};
   return sub {
      my $record = shift;
      my $target = defined($input) ? $record->{$input} : $record;
      my @outcomes;
      for my $i (0 .. $#$validators) {
         my ($name, $validator, @params) =
           (ref($validators->[$i]) eq 'ARRAY')
           ? @{$validators->[$i]}
           : ("validator-$i", $validators->[$i]);
         my @outcome =
             $wrapper
           ? $wrapper->($validator, $target, $record, $args, @params)
           : (ref($validator) eq 'CODE')
           ? $validator->($target, $record, $args, @params)
           : (
               $target =~ m{$validator}
               ? (1)
               : (0, regex => "$validator")
            );
         push @outcome, 0 unless @outcome;
         push @outcomes, [$name, @outcome]
           if !$outcome[0] || $keep_positives;
      } ## end for my $i (0 .. $#$validators)
      $record->{$output} = undef;
      $record->{$output} = \@outcomes if @outcomes || $keep_empty;
      return $record;
   };
} ## end sub validate_with_subs

*validate_with_subs = \&validate_thoroughly;

shorter_sub_names(__PACKAGE__, 'validate_');

1;
