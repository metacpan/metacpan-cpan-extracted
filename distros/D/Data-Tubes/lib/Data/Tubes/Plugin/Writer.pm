package Data::Tubes::Plugin::Writer;

# vim: ts=3 sts=3 sw=3 et ai :

use strict;
use warnings;
use English qw< -no_match_vars >;
use POSIX qw< strftime >;
our $VERSION = '0.740';

use Log::Log4perl::Tiny qw< :easy :dead_if_first LOGLEVEL >;
use Template::Perlish;

use Data::Tubes::Util
  qw< normalize_args read_file_maybe shorter_sub_names sprintffy >;
use Data::Tubes::Plugin::Util qw< identify log_helper >;
use Data::Tubes::Plugin::Plumbing;
my %global_defaults = (input => 'rendered',);

sub _filenames_generator {
   my $template = shift;

   my $n             = 0; # counter, used in closures inside $substitutions
   my $substitutions = [
      [qr{(\d*)n} => sub { return sprintf "%${1}d",    $n; }],
      [qr{Y}      => sub { return strftime('%Y',       localtime()); }],
      [qr{m}      => sub { return strftime('%m',       localtime()); }],
      [qr{d}      => sub { return strftime('%d',       localtime()); }],
      [qr{H}      => sub { return strftime('%H',       localtime()); }],
      [qr{M}      => sub { return strftime('%M',       localtime()); }],
      [qr{S}      => sub { return strftime('%S',       localtime()); }],
      [qr{z}      => sub { return strftime('%z',       localtime()); }],
      [qr{D}      => sub { return strftime('%Y%m%d',   localtime()); }],
      [qr{T}      => sub { return strftime('%H%M%S%z', localtime()); }],
      [qr{t} => sub { return strftime('%Y%m%dT%H%M%S%z', localtime()); }],
   ];

   # see if the template depends on the counter
   my $expanded = sprintffy($template, $substitutions);
   return sub {
      my $retval = sprintffy($template, $substitutions);
      ++$n;
      return $retval;
     }
     if ($expanded ne $template);    # it does!

   # then, by default, revert to poor's man expansion of name...
   return sub {
      my $retval = $n ? "${template}_$n" : $template;
      ++$n;
      return $retval;
   };
} ## end sub _filenames_generator

sub dispatch_to_files {
   my %args = normalize_args(
      @_,
      [
         {
            %global_defaults,
            name    => 'write dispatcher',
            binmode => ':encoding(UTF-8)'
         },
         'filename'
      ],
   );
   identify(\%args);
   my $name = delete $args{name};    # so that it can be overridden

   if (defined(my $filename = delete $args{filename})) {
      my $ref = ref $filename;
      if (!$ref) {
         $args{filename_template} //= $filename;
      }
      elsif ($ref eq 'CODE') {
         $args{filename_factory} //= $filename;
      }
      else {
         LOGDIE "argument filename has invalid type $ref";
      }
   } ## end if (defined(my $filename...))

   my $factory = delete $args{filename_factory};
   if (!defined($factory) && defined($args{filename_template})) {
      my $tp = Template::Perlish->new(%{$args{tp_opts} || {}});
      my $template = $tp->compile($args{filename_template});
      $factory = sub {
         my ($key, $record) = @_;
         return $tp->evaluate($template, {key => $key, record => $record});
      };
   } ## end if (!defined($factory)...)

   $args{factory} //= sub {
      my $filename = $factory->(@_);
      return write_to_files(%args, filename => $filename);
   };

   return Data::Tubes::Plugin::Plumbing::dispatch(%args);
} ## end sub dispatch_to_files

sub write_to_files {
   my %args = normalize_args(
      @_,
      [
         {
            %global_defaults,
            name     => 'write to file',
            binmode  => ':encoding(UTF-8)',
            filename => \*STDOUT,
         },
         'filename'
      ],
   );
   identify(\%args);
   my $name = $args{name};
   LOGDIE "$name: need a filename" unless defined $args{filename};
   LOGDIE "$name: need an input"   unless defined $args{input};

   my $output = $args{filename};
   $output = _filenames_generator($output) unless ref($output);

   my %oha =
     map { ($_ => $args{$_}) }
     grep { defined $args{$_} } qw< binmode policy >;
   for my $marker (qw< footer header interlude >) {
      $oha{$marker} = read_file_maybe($args{$marker})
        if defined $args{$marker};
   }
   require Data::Tubes::Util::Output;
   my $output_handler =
     Data::Tubes::Util::Output->new(%oha, output => $output,);

   my $input = $args{input};
   return sub {
      my $record = shift;
      $output_handler->print($record->{$input});
      return $record;    # relaunch for further processing
   };
} ## end sub write_to_files

shorter_sub_names(__PACKAGE__, 'write_');

1;
