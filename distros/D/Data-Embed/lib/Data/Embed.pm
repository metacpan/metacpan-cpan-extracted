package Data::Embed;

use strict;
use warnings;
use English qw< -no_match_vars >;
use Exporter qw< import >;
{ our $VERSION = '0.32'; }
use Log::Log4perl::Tiny qw< :easy :dead_if_first >;
use Scalar::Util qw< blessed >;

our @EXPORT_OK =
  qw< writer reader embed embedded generate_module_from_file reassemble >;
our @EXPORT      = ();
our %EXPORT_TAGS = (
   all     => \@EXPORT_OK,
   reading => [qw< reader embedded >],
   writing => [qw< writer embed    generate_module_from_file reassemble >],
);

sub writer {
   require Data::Embed::Writer;
   return Data::Embed::Writer->new(@_);
}

sub reader {
   require Data::Embed::Reader;
   return Data::Embed::Reader->new(@_);
}

sub embed {
   my %args = (@_ && ref($_[0])) ? %{$_[0]} : @_;

   my %constructor_args =
     map { $_ => delete $args{$_} } qw< input output >;
   $constructor_args{input} = $constructor_args{output} =
     delete $args{container}
     if exists $args{container};
   my $writer = writer(%constructor_args)
     or LOGCROAK 'could not get the writer object';

   return $writer->add(%args);
} ## end sub embed

sub embedded {
   my $reader = reader(shift)
     or LOGCROAK 'could not get the writer object';
   return $reader->files();
}

sub generate_module_from_file {
   require Data::Embed::OneFileAsModule;
   goto &Data::Embed::OneFileAsModule::generate_module_from_file;
}

sub __compare_and_shift {
   my ($l1, $l2) = @_;
   while (scalar(@$l1) && scalar(@$l2)) {
      last unless $l1->[0]->is_same_as($l2->[0]);
      shift @$l1;
      shift @$l2;
   }
   return ($l1, $l2);
} ## end sub __compare_and_shift

sub __temporary_for {
   my ($target, $previous) = @_;
   require File::Temp;
   require File::Basename;

   my $dir      = File::Basename::dirname $target;
   my $template = File::Basename::basename($target) . '.tmp-XXXXXXX';
   my ($fh, $filename) = File::Temp::tempfile($template, DIR => $dir);
   binmode $fh, ':raw';

   my $prefix = $previous->prefix();
   if ($prefix->{length}) {
      require Data::Embed::Util;
      Data::Embed::Util::transfer($prefix->fh(), $fh);
   }

   close $fh;

   return $filename;
} ## end sub __temporary_for

sub reassemble {
   my %args = (@_ && ref($_[0])) ? %{$_[0]} : @_;

   my $target = $args{target};
   my $interim_target;
   my @sequence = @{$args{sequence} || []};

   my $writer;
   if (ref($target) eq 'SCALAR' || (-e $target)) {
      my $previous = reader($target);

      my ($rprevious, $rsequence) =
        __compare_and_shift([$previous->files()], [@sequence]);

      # is it a nop?
      my $nprevious = scalar @$rprevious;
      my $nsequence = scalar @$rsequence;
      return unless $nprevious || $nsequence;

      # if there's a residual in both, use a temporary something
      if (
         ($nprevious && $nsequence)    # this is the real condition
         || $nprevious    # FIXME move into its own, see next condition...
        )
      {
         if (ref $target) {    # pointer to scalar... hopefully!
            $interim_target = $previous->prefix()->contents();
            $writer         = writer(
               input  => \$interim_target,
               output => \$interim_target,
            );
         } ## end if (ref $target)
         else {
            $interim_target = __temporary_for($target, $previous);
            $writer = writer(
               input  => $interim_target,
               output => $interim_target,
            );
         } ## end else [ if (ref $target) ]
      } ## end if (($nprevious && $nsequence...))
      elsif ($nprevious) {    # we "just" have to get rid of stuff
             # FIXME will implement later, let's just no-reuse here...
      }
      else {    # append residual stuff in @$rsequence
         @sequence = @$rsequence;
         $writer = writer(output => $target, input => $target);
      }
   } ## end if (ref($target) eq 'SCALAR'...)
   else {
      $writer = writer(output => $target);
   }

   $writer->add(
      inputs => [
         map {
            if (blessed($_) && $_->isa('Data::Embed::File')) {
               {
                  name => $_->name(),
                  fh   => $_->fh(),
               };
            } ## end if (blessed($_) && $_->...)
            else {
               $_;
            }
         } @sequence
      ]
   );
   $writer->write_index();

   if (defined $interim_target) {
      if (ref $target) {
         $$target = $interim_target;
      }
      else {
         rename $interim_target, $target;    # atomic
      }
   } ## end if (defined $interim_target)

   return;
} ## end sub reassemble

1;
