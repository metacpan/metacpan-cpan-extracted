package ExtUtils::CFeatureTest;
use strict;
use warnings;
use File::Temp;
use IO::Handle;
use ExtUtils::CBuilder;

our $VERSION= 0.001;

# Many ideas borrowed from ExtUtils::CChecker and Devel::CheckLib

sub new {
   my $self= bless {}, shift;
   while (@_) {
      my ($attr, $val)= splice(@_, 0, 2);
      $self->$attr($val);
   }
   $self->{config_headers}= '';
   $self->{config_header_set}= {};
   $self->{config_macros}= '';
   $self->{last_err}= '';
   $self->{last_compile_output}= '';
   $self->{last_exec_output}= '';
   $self->{include_dirs}= [];
   $self->{extra_compiler_flags}= [];
   $self->{extra_linker_flags}= [];
   $self;
}

sub cbuilder {
   my ($self, $val)= @_;
   $self->{cbuilder}= $val if @_ > 1;
   $self->{cbuilder} ||= ExtUtils::CBuilder->new;
}

sub last_err             { $_[0]{last_err} }
sub last_out             { $_[0]{last_out} }
sub last_compile_output  { $_[0]{last_compile_output} }
sub include_dirs         { $_[0]{include_dirs} }
sub extra_compiler_flags { $_[0]{extra_compiler_flags} }
sub extra_linker_flags   { $_[0]{extra_linker_flags} }

sub _spew {
   my $fname= shift;
   open my $fh, '>', $fname or die "open($fname): $!";
   $fh->print(@_) or die "write($fname): $!";
   $fh->close or die "close($fname): $!";
}

sub _maybe_list {
   ref $_[0] eq 'ARRAY'? (grep length, @{ $_[0] })
   : length $_[0]? ( $_[0] )
   : ()
}

sub compile_and_run {
   my ($self, $code, %opts)= @_;
   $self->{last_err}= '';
   for (qw( include_dirs extra_compiler_flags extra_linker_flags )) {
      unshift @{ $opts{$_} ||= [] }, @{ $self->{$_} };
   }

   my $srcfile= "ftest-$$-" . ++$self->{seq} . ".c";
   _spew($srcfile, $code);
   (my $outfile= $srcfile) =~ s/\.c$/-out.txt/;
   my ($objfile, $exefile, $err);

   # Compiler is rather noisy.  Redirect output to temp file.
   open my $out_txt, '+>', $outfile or die "open($outfile): $!";
   open my $stdout_save, ">&STDOUT" or die "dup(STDOUT): $!";
   open my $stderr_save, ">&STDERR" or die "dup(STDERR): $!";
   open STDOUT, ">&" . fileno $out_txt or die "Can't redirect STDOUT: $!";
   open STDERR, ">&" . fileno $out_txt or die "Can't redirect STDERR: $!";
   my $success= eval {
      $err= "compile failed";
      $objfile= $self->cbuilder->compile(%opts, source => $srcfile);
      $err= "link failed";
      $exefile= $self->cbuilder->link_executable(%opts, objects => $objfile);
      $err= "execute";
      $self->{last_out}= `./$exefile`;
      if ($?) { $err= "execute failed: ".($? & 0xFF? "signal $?" : "exit code ".($? >> 8)) }
      $? == 0
   };
   chomp($self->{last_err}= $@? "$err: $@" : $err) unless $success;
   # restore handles
   open STDERR, ">&" . fileno $stderr_save or die "Can't restore STDERR: $!";
   open STDOUT, ">&" . fileno $stdout_save or die "Can't restore STDOUT: $!";
   # Slurp contents of compiler output
   seek($out_txt, 0, 0);
   { local $/= undef; $self->{last_compile_output}= <$out_txt>; }
   close $out_txt;

   unlink grep length, $srcfile, $objfile, $exefile, $outfile;
   return $success;
}

sub header {
   my ($self, $header, @paths)= @_;
   return 1 if $self->{config_header_set}{$header};
   my $code= <<END_C;
$self->{config_headers}
#include "$header"
$self->{config_macros}
int main(int argc, char **argv) { return 0; }
END_C
   for my $path (undef, @paths) {
      if ($self->compile_and_run($code, (length $path? (include_dirs => $path) : ()))) {
         print "Found $header".(length $path? " at $path" : '')."\n";
         push @{$self->{include_dirs}}, $path if length $path;
         $self->{config_headers} .= "#include <$header>\n";
         $self->{config_header_set}{$header}= 1;
         (my $macro= 'HAVE_'.uc($header)) =~ s/\W/_/;
         $self->{config_macros} .= "#define $macro\n";
         return 1;
      }
   }
   print "Didn't find $header\n";
   return 0;
}

sub require_header {
   my ($self, $header, @args)= @_;
   my $success= $self->header($header, @args);
   if (!$success) {
      warn $self->last_err;
      warn $self->last_compile_output;
      warn "Can't proceed without $header\n";
      exit;
   }
   1;
}

sub feature {
   my ($self, $macro, $code, @permutations)= @_;
   # Single function name? just take the address of it
   if ($code =~ /^\w+\z/) {
      $code= "void *fn= (void *) $code; return fn != argv? 0 : 1;";
   }
   # Bare snippet without 'main' function wrapping it?
   unless ($code =~ /int main\(/) {
      # Is it a snippet belonging inside main?
      if ($code =~ /return [^{}]+;/) {
         $code= "int main(int argc, char **argv) { $code }\n";
      } else {
         $code= "$code\nint main(int argc, char **argv) { return 0; }\n";
      }
   }
   for my $p (undef, @permutations) {
      my $prefix= $self->{config_headers};
      my @headers;
      if ($p) {
         # clone $p before making changes
         $p= { %$p };
         $p->{$_}= [ _maybe_list($p->{$_}) ]
            for qw( include_dirs extra_compiler_flags extra_linker_flags );
         # optional header attempts
         @headers= grep !$self->{config_header_set}{$_}, _maybe_list(delete $p->{h});
         $prefix .= "#include <$_>\n" for @headers;
         # expand convenient aliases
         push @{ $p->{include_dirs} }, _maybe_list(delete $p->{-I})
            if length $p->{-I};
         push @{ $p->{extra_compiler_flags} }, map "-D$_", _maybe_list(delete $p->{-D})
            if length $p->{-D};
         push @{ $p->{extra_linker_flags} }, map "-L$_", _maybe_list(delete $p->{-L})
            if length $p->{-L};
         push @{ $p->{extra_linker_flags} }, map "-l$_", _maybe_list(delete $p->{-l})
            if length $p->{-l};
      }
      $prefix .= $self->{config_macros};
      if ($self->compile_and_run($prefix.$code, $p? (%$p) : ())) {
         if ($p) {
            for (qw( include_dirs extra_compiler_flags extra_linker_flags )) {
               push @{$self->{$_}}, @{$p->{$_}} if $p->{$_};
            }
            for (@headers) {
               $self->{config_headers} .= "#include <$_>\n";
               $self->{config_header_set}{$_}= 1;
            }
         }
         if (length $macro) {
            print "Found feature $macro\n";
            $self->{config_macros} .= "#define $macro\n";
         }
         return 1;
      }
   }
   print "Feature $macro unavailable\n" if length $macro;
   return 0;
}

sub require_feature {
   my ($self, $macro, @args)= @_;
   my $success= $self->feature($macro, @args);
   if (!$success) {
      warn $self->last_err;
      warn $self->last_compile_output;
      warn "Can't proceed without $macro";
      exit;
   }
   1;
}

sub write_config_header {
   my ($self, $fname)= @_;
   _spew($fname, $self->{config_headers} . $self->{config_macros});
   print "Wrote config to $fname\n";
   return $self;
}

sub export_deps {
   my ($self, $extutils_depends)= @_;
   $extutils_depends->set_libs(join ' ', @{$self->{extra_linker_flags}})
      if @{$self->{extra_linker_flags}};
   $extutils_depends->set_inc(join ' ', map "-I$_", grep length, @{$self->{include_dirs}})
      if @{$self->{include_dirs}};
   return $self;
}

1;
