package Data::Embed::OneFileAsModule;

use Exporter qw< import >;
@EXPORT_OK   = (qw< generate_module_from_file >);
@EXPORT      = ();
%EXPORT_TAGS = (all => \@EXPORT_OK);
use strict;
use warnings;
use Log::Log4perl::Tiny qw< :easy :dead_if_first >;

our $VERSION = '0.32'; # make indexer happy

{
   no strict 'refs';
#__TEMPLATE_BEGIN__
{
   my $data     = \*{__PACKAGE__ . '::DATA'};
   my $position = undef;

   use strict;
   use warnings;
   use Carp;
   use English qw< -no_match_vars >;
   use Fcntl qw< :seek >;

   sub get_fh {
      $position = tell $data unless defined $position;
      open my $fh, '<&', $data
        or croak __PACKAGE__ . "::dup() for DATA: $OS_ERROR";
      seek $fh, $position, SEEK_SET;
      return $fh;
   } ## end sub get_fh

   sub get_data {
      my $fh = get_fh();
      binmode $fh;

      # ensure we slurp all, whatever the context
      local $/ = wantarray() ? $/ : undef;
      return <$fh>;
   } ## end sub get_data
}
#__TEMPLATE_END__
}

sub _get_output_fh {
   my $output = shift;
   my $binmode = shift || ':raw';

   # if no output is defined, we will return a scalar with data
   if (!defined $output) {
      my $buffer = '';
      open my $fh, '>', \$buffer
        or LOGCROAK "open() on (scalar ref): $OS_ERROR";
      binmode $fh, $binmode;
      return ($fh, \$buffer);
   } ## end if (!defined $output)

   # if filename is '-', use standard output
   if ($output eq '-') {
      open my $fh, '>&', \*STDOUT    # dup()-ing
        or LOGCROAK "dup(): $OS_ERROR";
      binmode $fh, $binmode;
      return $fh;
   } ## end if ($output eq '-')

   my $ro = ref $output;
   if (!$ro) {                       # output is a simple filename
      open my $fh, '>', $output
        or LOGCROAK "open('$output'): $OS_ERROR";
      binmode $fh, $binmode;
      return $fh;
   } ## end if (!$ro)

   # so we have a reference here.
   # if not a reference to a SCALAR, assume it's
   # something that supports the filehandle interface
   return $output if $ro ne 'SCALAR';

   # otherwise, open a handle to write in the scalar
   open my $fh, '>', $output
     or LOGCROAK "open('$output') (scalar ref): $OS_ERROR";
   binmode $fh, $binmode;
   return $fh;
} ## end sub _get_output_fh

sub _get_input_fh {
   my $args = shift;

   return $args->{fh} if exists $args->{fh};

   if (defined $args->{filename}) {
      open my $fh, '<', $args->{filename}
        or LOGCROAK "open('$args->{filename}'): $OS_ERROR";
      binmode $fh;
      return $fh;
   } ## end if (defined $args->{filename...})

   if (defined $args->{dataref}) {
      open my $fh, '<', $args->{dataref}
        or LOGCROAK "open('$args->{dataref}') (scalar ref): $OS_ERROR";
      binmode $fh;
      return $fh;
   } ## end if (defined $args->{dataref...})

   if (defined $args->{data}) {
      open my $fh, '<', \$args->{data}
        or LOGCROAK "open() (scalar ref): $OS_ERROR";
      binmode $fh;
      return $fh;
   } ## end if (defined $args->{data...})

   LOGCROAK "no input source defined";
   return;    # unreached
} ## end sub _get_input_fh

sub generate_module_from_file {
   my %args = (scalar(@_) && ref($_[0])) ? %{$_[0]} : @_;

   LOGCROAK 'no package name set'
     unless defined $args{package};
   LOGCROAK "unsupported package name '$args{module}'"
     unless $args{package} =~ m{\A (?: \w+) (:: \w+)* \z}mxs;

   my $template_fh = get_fh();
   binmode $template_fh;
   seek $template_fh, 0, SEEK_SET;

   my $in_fh = _get_input_fh(\%args);

   ($args{output} = 'lib/' . $args{package} . '.pm') =~ s{::}{/}gmxs
     if $args{output_from_package};
   my ($out_fh, $outref) = _get_output_fh($args{output}, $args{binmode});

   # package name
   print {$out_fh} "package $args{package};\n";

   # package code
   my $seen_start;
 INPUT:
   while (<$template_fh>) {
      if (!$seen_start) {
         $seen_start = m{\A \#__TEMPLATE_BEGIN__ \s*\z}mxs;
         next INPUT;
      }
      last INPUT if m{\A \#__TEMPLATE_END__ \s*\z}mxs;
      print {$out_fh} $_;
   } ## end INPUT: while (<$template_fh>)

   # package code ending
   print {$out_fh} "\n1;\n__DATA__\n";

   # file contents
   while (!eof $in_fh) {
      defined(my $nread = read $in_fh, my $buffer, 4096)
        or LOGCROAK "read(): $OS_ERROR";
      last unless $nread;    # paranoid
      print {$out_fh} $buffer;
   } ## end while (!eof $in_fh)

   return $$outref if $outref;
   return;
} ## end sub generate_module_from_file

1;
