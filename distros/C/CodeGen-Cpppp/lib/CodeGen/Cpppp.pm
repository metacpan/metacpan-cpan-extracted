package CodeGen::Cpppp;
use v5.20;
use warnings;
use Carp;
use experimental 'signatures', 'lexical_subs', 'postderef';
use version;
use Cwd 'abs_path';
use Scalar::Util 'blessed', 'looks_like_number';
use CodeGen::Cpppp::Template;

our $VERSION= '0.003'; # VERSION
# ABSTRACT: The C Perl-Powered Pre-Processor


sub autoindent($self, $newval=undef) {
   $self->{autoindent}= $newval if defined $newval;
   $self->{autoindent} // 1;
}
sub autocolumn($self, $newval=undef) {
   $self->{autocolumn}= $newval if defined $newval;
   $self->{autocolumn} // 1;
}

sub convert_linecomment_to_c89($self, $newval=undef) {
   $self->{convert_linecomment_to_c89}= $newval if defined $newval;
   $self->{convert_linecomment_to_c89} // 0;
}


sub include_path { $_[0]{include_path} //= [] }
sub output { $_[0]{output} //= CodeGen::Cpppp::Output->new }


sub new($class, @attrs) {
   my $self= bless {
      @attrs == 1 && ref $attrs[0]? %{$attrs[0]}
      : !(@attrs&1)? @attrs
      : croak "Expected even-length list or hashref"
   }, $class;
   $self->{include_path}= [ $self->{include_path} ]
      if defined $self->{include_path} && ref $self->{include_path} ne 'ARRAY';
   $self;
}


sub require_template($self, $filename) {
   $self->{templates}{$filename} ||= do {
      my $path= $self->find_template($filename)
         or croak("No template '$filename' found");
      $self->{templates}{$path} ||= $self->compile_cpppp($path);
   }
}


sub find_template($self, $filename) {
   return abs_path($filename) if $filename =~ m,/, and -e $filename;
   # /foo ./foo and ../foo do not trigger a path search
   return undef if $filename =~ m,^\.?\.?/,;
   for ($self->include_path->@*) {
      my $p= "$_/$filename";
      $p =~ s,//,/,g; # in case include-path ends with '/'
      return abs_path($p) if -e $p;
   }
   return undef;
}


sub new_template($self, $class_or_filename, @params) {
   my $class= $class_or_filename =~ /^CodeGen::Cpppp::/ && $class_or_filename->can('new')
      ? $class_or_filename
      : $self->require_template($class_or_filename);
   my %params= (
      context => $self,
      output => $self->output,
      !(@params&1)? @params
      : 1 == @params && ref $params[0] eq 'HASH'? %{$params[0]}
      : croak("Expected even-length key/val list, or hashref"),
   );
   $class->new(\%params);
}


our $next_pkg= 1;
sub compile_cpppp($self, @input_args) {
   my $parse= $self->parse_cpppp(@input_args);
   my $perl= $self->_gen_perl_template_package($parse);
   unless (eval $perl) {
      die "$perl\n\nException: $@\n";
   }
   return $parse->{package};
}

sub _gen_perl_template_package($self, $parse, %opts) {
   my $perl= $parse->{code} // '';
   my ($src_lineno, $src_filename, @global, $perl_ver, $cpppp_ver, $tpl_use_line)= (1);
   # Extract all initial 'use' and 'no' statements from the script.
   # If they refer to perl or CodeGen:::Cpppp, make a note of it.
   while ($perl =~ s/^ ( [ \t]+ | [#] .* | use [^;]+ ; | no [^;]+ ; \s* ) \n//gx) {
      my $line= $1;
      push @global, $line;
      $perl_ver= version->parse($1)
         if $line =~ /use \s+ ( v.* | ["']? [0-9.]+ ["']? ) \s* ; /x;
      $cpppp_ver= version->parse($1)
         if $line =~ /use \s+ CodeGen::Cpppp \s* ( v.* | ["']? [0-9.]+ ["']? ) \s* ; /x;
      $tpl_use_line= 1
         if $line =~ /use \s+ CodeGen::Cpppp::Template \s+/;
      if ($line =~ /^# line (\d+) "([^"]+)"/) {
         $src_lineno= $1;
         $src_filename= $2;
      } else {
         $src_lineno+= 1 + (()= $line =~ /\n/g);
      }
   }
   if ($opts{with_data}) {
      require Data::Dumper;
      my $dumper= Data::Dumper->new([ { %$parse, code => '...' } ], [ '$_parse_data' ])
         ->Indent(1)->Sortkeys(1);
      push @global,
         'our $_parse_data; '.$dumper->Dump;
   }

   # Build the boilerplate for the template eval
   my $pkg= CodeGen::Cpppp::Template->_create_derived_package($cpppp_ver, $parse);
   $parse->{package}= $pkg;
   $cpppp_ver //= $VERSION;
   $src_filename //= $parse->{filename};
   join '', map "$_\n",
      "package $pkg;",
      # Inject a minimum perl version unless user-provided
      ("use v5.20;")x!(defined $perl_ver),
      # Inject a Template -setup unless user-provided
      ("use CodeGen::Cpppp::Template -setup => $cpppp_ver;")x!($tpl_use_line),
      # All the rest of the user's use/no statements
      @global,
      # Everything after that goes into a BUILD method
      $pkg->_gen_BUILD_method($cpppp_ver, $perl, $src_filename, $src_lineno),
      "1";
}

sub parse_cpppp($self, $in, $filename=undef, $line=undef) {
   my @lines;
   if (ref $in eq 'SCALAR') {
      @lines= split /^/m, $$in;
   }
   else {
      my $fh;
      if (ref $in eq 'GLOB' || (blessed($in) && $in->can('getline'))) {
         $fh= $in;
      } else {
         open($fh, '<', $in) or croak "open($in): $!";
      }
      local $/= undef;
      my $text= <$fh>;
      $filename //= "$in";
      utf8::decode($text) or warn "$filename is not encoded as utf-8\n";
      @lines= split /^/m, $text;
   }
   $line //= 1;
   $self->{cpppp_parse}= {
      autoindent        => $self->autoindent,
      autocolumn        => $self->autocolumn,
      filename          => $filename,
      colmarker         => {},
      coltrack          => { },
   };
   my ($perl, $block_group, $tpl_start_line, $cur_tpl)= ('', 1);
   my sub end_tpl {
      if (defined $cur_tpl && $cur_tpl =~ /\S/) {
         my $parsed= $self->_parse_code_block($cur_tpl, $filename, $tpl_start_line);
         my $current_indent= $perl =~ /\n([ \t]*).*\n\Z/? $1 : '';
         $current_indent .= '  ' if $perl =~ /\{ *\n\Z/;
         $perl .= $self->_gen_perl_call_code_block($parsed, $current_indent);
      }
      $cur_tpl= undef;
   };
   for (@lines) {
      if (/^#!/) { # ignore #!
      }
      elsif (/^##/) { # full-line of perl code
         if (defined $cur_tpl || !length $perl) {
            end_tpl();
            $perl .= qq{# line $line "$filename"\n};
         }
         (my $pl= $_) =~ s/^##\s?//;
         $perl .= $self->_transform_template_perl($pl, $line);
      }
      elsif (/^(.*?) ## ?((?:if|unless|for|while|unless) .*)/) { # perl conditional suffix, half tpl/half perl
         my ($tpl, $pl)= ($1, $2);
         end_tpl() if defined $cur_tpl;
         $tpl_start_line= $line;
         $cur_tpl= $tpl;
         end_tpl();
         $perl =~ s/;\s*$//; # remove semicolon
         $pl .= ';' unless $pl =~ /;\s*$/; # re-add it if user didn't
         $perl .= qq{\n# line $line "$filename"\n    $pl\n};
      }
      else { # default is to assume a line of template
         if (!defined $cur_tpl) {
            $tpl_start_line= $line;
            $cur_tpl= '';
         }
         $cur_tpl .= $_;
      }
   } continue { ++$line }
   end_tpl() if defined $cur_tpl;

   # Resolve final bits of column tracking
   my $ct= delete $self->{cpppp_parse}{coltrack};
   _finish_coltrack($ct, $_) for grep looks_like_number($_), keys %$ct;

   $self->{cpppp_parse}{code}= $perl;
   delete $self->{cpppp_parse};
}

sub _transform_template_perl($self, $pl, $line) {
   # If user declares "sub NAME(", convert that to "my sub NAME" so that it can
   # capture refs to the variables of new template instances.
   if ($pl =~ /(my)? \s* \b sub \s* ([\w_]+) \b \s* /x) {
      my $name= $2;
      $self->{cpppp_parse}{template_method}{$name}= { line => $line };
      my $ofs= $-[0];
      my $ofs2= defined $1? $+[1] : $ofs;
      substr($pl, $ofs, $ofs2-$ofs, "my sub $name; \$self->define_template_method($name => \\&$name);");
   }
   # If user declares 'param $foo = $x' adjust that to 'param my $foo = $x'
   if ($pl =~ /^ \s* (param) \b /xgc) {
      my $ofs= $-[1];
      # It's an error if the thing following isn't a variable name
      $pl =~ /\G \s* ( [\$\@\%] [\w_]+ ) /xgc
         or croak("Expected variable name (including sigil) after 'param'");
      my $var_name= $1;
      $pl =~ /\G \s* ([;=]) /xgc
         or croak("Parameter declaration $var_name must be followed by '=' or ';'");
      my $term= $1;
      my $name= substr($var_name, 1);
      substr($pl, $ofs, $+[0]-$ofs, qq{param '$name', \\my $var_name }.($term eq ';'? ';' : ','));
      $self->{cpppp_parse}{template_parameter}{$name}= substr($var_name,0,1);
   }
   # If user declares "define name(", convert that to both a method and a define
   elsif ($pl =~ /^ \s* (define) \s* ([\w_]+) (\s*) \(/x) {
      my $name= $2;
      $self->{cpppp_parse}{template_macro}{$name}= 'CODE';
      substr($pl, $-[1], $-[2]-$-[1], qq{my sub $name; \$self->define_template_macro($name => \\&$name); sub });
   }
   $pl;
}

sub _gen_perl_call_code_block($self, $parsed, $indent='') {
   my $codeblocks= $self->{cpppp_parse}{code_block_templates} ||= [];
   push @$codeblocks, $parsed;
   my $code= $indent.'$self->_render_code_block('.$#$codeblocks;
   my %cache;
   my $i= 0;
   my $cur_line= 0;
   for my $s (@{$parsed->{subst}}) {
      if (defined $s->{eval}) {
         # No need to create more than one anonsub for the same expression
         if (defined $cache{$s->{eval}}) {
            $s->{eval_idx}= $cache{$s->{eval}};
            next;
         }
         $cache{$s->{eval}}= $s->{eval_idx}= $i++;
         my $sig= $s->{eval} =~ /self|output/? '($self, $output)' : '';
         if ($s->{line} == $cur_line) {
            $code .= qq{, sub${sig}{ $s->{eval} }};
         } elsif ($s->{line} == $cur_line+1) {
            $cur_line++;
            $code .= qq{,\n$indent  sub${sig}{ $s->{eval} }};
         } else {
            $code .= qq{,\n# line $s->{line} "$parsed->{file}"\n$indent  sub${sig}{ $s->{eval} }};
            $cur_line= $s->{line};
            $cur_line++ for $s->{eval} =~ /\n/g;
         }
      }
   }
   $code .= "\n$indent" if index($code, "\n") >= 0;
   $code . ");\n";
}

sub _finish_coltrack($coltrack, $col) {
   # did it eventually have an eval to the left?
   if (grep $_->{follows_eval}, $coltrack->{$col}{members}->@*) {
      $coltrack->{$col}{members}[-1]{last}= 1;
   } else {
      # invalidate them all, they won't become unaligned anyway.
      $_->{colgroup}= undef for $coltrack->{$col}{members}->@*;
   }
   delete $coltrack->{$col};
}

sub _parse_code_block($self, $text, $file=undef, $orig_line=undef) {
   $text .= "\n" unless substr($text,-1) eq "\n";
   if ($text =~ /^# line (\d+) "([^"]+)"/) {
      $orig_line= $1-1;
      $file= $2;
   }
   local our $line= $orig_line || 1;
   local our $parse= $self->{cpppp_parse};
   local our $start;
   local our @subst;
   # Everything in coltrack that survived the last _parse_code_block call
   # ended on the final line of the template.  Set the line numbers to
   # continue into this template.
   for my $c (grep looks_like_number($_), keys $parse->{coltrack}->%*) {
      $parse->{coltrack}{$c}{line}= $line;
   }
   local $_= $text;
   # Parse and record the locations of the embedded perl statements
   ()= m{
      # Rough approximation of continuation of perl expressions in quoted strings
      (?(DEFINE)
         (?<BALANCED_EXPR> (?>
              \{ (?&BALANCED_EXPR) \}
            | \[ (?&BALANCED_EXPR) \]
            | \( (?&BALANCED_EXPR) \)
            | [^[\](){}\n]+
            | \n (?{ $line++ })
         )* )
      )
      
      # Start of a perl expression in a quoted string
      [\$\@] (?{ $start= -1+pos }) 
         (?:
           \{ (?&BALANCED_EXPR) \}           # 
           | [\w_]+                          # plain variable
            (?:                              # maybe followed by ->[] or similar
               (?: -> )?
               (?: \{ (?&BALANCED_EXPR) \} | \[ (?&BALANCED_EXPR) \] )
            ) *                       
         ) (?{ push @subst, { pos => $start, len => -$start+pos, line => $line }; })
      
      # Track what line we're on
      | \n     (?{ $line++ })
      
      # Column alignment detection for the autocolumn feature
      | (?{ $start= pos; }) [ \t]{2,}+ (?{
            push @subst, { pos => pos, len => 0, line => $line, colgroup => undef };
        })
   }xg;
   
   my $prev_eval;
   for my $s (@subst) {
      if (exists $s->{colgroup}) {
         my $linestart= (rindex($text, "\n", $s->{pos})+1);
         my $col= $s->{pos} - $linestart;
         $s->{follows_eval}= $prev_eval && $prev_eval->{line} == $s->{line};
         # If same column as previous line, continue the coltracking.
         if ($parse->{coltrack}{$col}) {
            if ($parse->{coltrack}{$col}{members}[-1]{line} == $s->{line} - 1) {
               push @{ $parse->{coltrack}{$col}{members} }, $s;
               $s->{colgroup}= $parse->{coltrack}{$col}{id};
               $parse->{coltrack}{$col}{line}= $s->{line};
               next;
            }
            # column ended prior to this
            _finish_coltrack($parse->{coltrack}, $col);
         }
         # There's no need to create a column unless nonspace to the left
         # Otherwise it would just be normal indent.
         if (substr($text, $linestart, $s->{pos} - $linestart) =~ /\S/) {
            # new column begins
            $s->{colgroup}= $col*10000 + ++$parse->{coltrack}{next_id}{$col};
            $s->{first}= 1;
            $parse->{coltrack}{$col}= {
               id => $s->{colgroup},
               line => $s->{line},
               members => [ $s ],
            };
         }
      }
      else { # Perl expression
         my $expr= substr($text, $s->{pos}, $s->{len});
         # Special case: ${{  }} notation is a shortcut for @{[do{ ... }]}
         $expr =~ s/^ \$\{\{ (.*) \}\} $/$1/x;
         # When not inside a string, ${foo} becomes ambiguous with ${foo()}
         $expr =~ s/^ ([\$\@]) \{ ([\w_]+) \} /$1$2/x;
         $s->{eval}= $expr;
         $prev_eval= $s;
      }
   }
   # Clean up any tracked column that ended before the final line of the template
   for my $c (grep looks_like_number($_), keys $parse->{coltrack}->%*) {
      _finish_coltrack($parse->{coltrack}, $c)
         if $parse->{coltrack}{$c}{line} < $line-1;
   }
   @subst= grep defined $_->{eval} || defined $_->{colgroup}, @subst;
   
   { text => $text, subst => \@subst, file => $file }
}


sub patch_file($self, $fname, $patch_markers, $new_content) {
   $new_content .= "\n" unless $new_content =~ /\n\Z/ or !length $new_content;
   utf8::encode($new_content);
   open my $fh, '+<', $fname or die "open($fname): $!";
   my $content= do { local $/= undef; <$fh> };
   $content =~ s{(BEGIN \Q$patch_markers\E[^\n]*\n).*?(^[^\n]+?END \Q$patch_markers\E)}
      {$1$new_content$2}sm
      or croak "Can't find $patch_markers in $fname";
   $fh->seek(0,0) or die "seek: $!";
   $fh->print($content) or die "write: $!";
   $fh->truncate($fh->tell) or die "truncate: $!";
   $fh->close or die "close: $!";
   $self;
}


sub backup_and_overwrite_file($self, $fname, $new_content) {
   $new_content .= "\n" unless $new_content =~ /\n\Z/;
   utf8::encode($new_content);
   if (-e $fname) {
      my $n= 0;
      ++$n while -e "$fname.$n";
      require File::Copy;
      File::Copy::copy($fname, "$fname.$n") or die "copy($fname, $fname.$n): $!";
   }
   open my $fh, '>', $fname or die "open($fname): $!";
   $fh->print($new_content) or die "write: $!";
   $fh->close or die "close: $!";
   $self;
}


sub get_filtered_output($self, $sections) {
   my $content= $self->output->get($sections);
   if ($self->convert_linecomment_to_c89) {
      # rewrite '//' comments as '/*' comments
      require CodeGen::Cpppp::CParser;
      my @tokens= CodeGen::Cpppp::CParser->tokenize($content);
      my $ofs= 0;
      for (@tokens) {
         $_->[2] += $ofs;
         if ($_->type eq 'comment') {
            if (substr($content, $_->src_pos, 2) eq '//') {
               substr($content, $_->src_pos, $_->src_len, '/*'.$_->value.' */');
               $ofs += 3;
            }
         }
      }
   }
   $content;
}


sub write_sections_to_file($self, $sections, $fname, $patch_markers=undef) {
   my $content= $self->get_filtered_output($sections);
   if (defined $patch_markers) {
      $self->patch_file($fname, $patch_markers, $content);
   } else {
      $self->backup_and_overwrite_file($fname, $content);
   }
   $self
}

sub _slurp_file($self, $fname) {
   open my $fh, '<', $fname or die "open($fname): $!";
   my $content= do { local $/= undef; <$fh> };
   $fh->close or die "close: $!";
   $content;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CodeGen::Cpppp - The C Perl-Powered Pre-Processor

=head1 RATIONALE

I<It's very special, because, if you can see, the preprocessor, goes up, to
C<perl>.  Look, right across the directory, C<perl>, C<perl>, C<perl>.>

=over

I<And most distributions go up to C<m4> >

=back

I<Exactly>

=over

I<Does that mean it's more powerful?  ...Is it more powerful?>

=back

I<Well, it's one layer of abstraction higher, isn't it?  It's not C<m4>.
You see, most blokes gonna be templating with C<cpp> or C<m4>, you're on C<m4>
here all the way up, all the way up, aaaall the way up, you're at C<m4> for your
pre-processing, Where can you go from there? Where?  Nowhere!  Exactly.>

I<What we do is if we need that extra, push over the cliff, you know what we do?>

=over

I<put it up to C<perl> >

=back

I< C<perl>, exactly. One higher. >

=over

I<Why don't you just download the C<cpp> source, and enhance it with the
abstractions you need?  Make C<cpp> more powerful, and make C<cpp> be the
preprocessor?>

=back

I<...>

I<... These go to B<perl>.>

=head1 SYNOPSIS

  # Cpppp object is a template factory
  my $cpppp= CodeGen::Cpppp->new(%options);
  
  # Simple templates immediately generate their output during
  # construction, which goes to the output accumulator of $cpppp
  # by default.
  $cpppp->new_template($filename, %params);
  
  # Complex templates can define custom methods
  my $tpl= $cpppp->new_template($otherfile, %params);
  $tpl->generate_more_stuff(...);
  
  # Inspect or print the accumulated output
  say $cpppp->output;
  $cpppp->write_sections_to_file(public  => 'project.h');
  $cpppp->write_sections_to_file(private => 'project.c');

B<Input:>

  #! /usr/bin/env cpppp
  ## param $min_bits = 8;
  ## param $max_bits = 16;
  ## param $feature_parent = 0;
  ## param $feature_count = 0;
  ## param @extra_node_fields;
  ##
  ## for (my $bits= $min_bits; $bits <= $max_bits; $bits <<= 1) {
  struct tree_node_$bits {
    uint${bits}_t  left :  ${{$bits-1}},
                   color:  1,
                   right:  ${{$bits-1}},
                   parent,   ## if $feature_parent;
                   count,    ## if $feature_count;
                   $trim_comma $trim_ws;
    @extra_node_fields;
  };
  ## }

B<Output:>

  struct tree_node_8 {
    uint8_t  left :  7,
             color:  1,
             right:  7;
  };
  struct tree_node_16 {
    uint16_t left : 15,
             color:  1,
             right: 15;
  };

=head1 SECURITY

B<Templates are equivalent to perl scripts>.  Use the same caution when
using cpppp templates that you would use when running perl scripts.
Do not load, compile, or render templates from un-trusted authors.

=head1 DESCRIPTION

This module is a preprocessor for C, or maybe more like a perl template engine
that specializes in generating C code.  Each input file gets translated to Perl
in a way that declares a new OO class, and then you can create instances of that
class with various parameters to generate your C output, or call methods on it
like automatically generating headers or function prototypes.

For the end-user, there is a 'cpppp' command line tool that behaves much like
the 'cpp' tool.

B<WARNING: this API is not stable>.  It would be unwise to use C<cpppp>
as part of a distribution's build scripts yet, but it is perfectly safe to use
it to generate sources and then add those generated files to a project.

If you have an interest in this topic, contact me, because I could use help
brainstorming ideas about how to accommodate the most possibilities, here.

B<Possible Future Features:>

=over

=item *

Scan existing headers to discover available macros, structs, and functions on the host.

=item *

Pass a list of headers through the real cpp and analyze the macro output.

=item *

Shell out to a compiler to find 'sizeof' information for structs.

=item *

Directly perform the work of inlining one function into another.

=back

=head1 ATTRIBUTES

=head2 autoindent

Default value for new templates; determines whether embedded newlines inside
variables that expand in the source code will automatically have indent applied.

=head2 autocolumn

Default value for new templates; enables the feature that detects column layout
in the source template, and attempts to line up those same elements in the
output after variables have been expanded.

=head2 convert_linecomment_to_c89

If true, rewrite the output to convert newer '//' comments into traditional
'/*' comments.

=head2 include_path

An arrayref of directories to search for template files during
C<require_template>.  Make sure no un-trusted users have control over any
directory in this path, the same as you would do for Perl's C<@INC> paths.

=head2 output

An instance of L<CodeGen::Cpppp::Output> that is used as the default C<output>
parameter for all automatically-created templates, thus collecting all their
output.

=head1 CONSTRUCTOR

=head2 new

Bare-bones for now, it accepts whatever hash values you hand to it.

=head1 METHODS

=head2 require_template

  $tpl_class= $cpppp->require_template($filename);

Load a template from a file, and die if not found or if it fails to compile.
Subsequent loads of the same file return the same class.

=head2 find_template

  $abs_path= $cpppp->find_template($filename);

Check the filename itself, and relative to all paths in L</include_path>,
and return the absolute path to the first match.

=head2 new_template

  $tpl_instance= $cpppp->new_template($class_or_filename, %params);

Load a template by filename (or use an already-loaded class) and construct a
new instance using C<%params> but also with the context and output defaulting
to this C<$cpppp> instance, and return the template object.

=head2 compile_cpppp

  $cpppp->compile_cpppp($filename);
  $cpppp->compile_cpppp($input_fh, $filename);
  $cpppp->compile_cpppp(\$scalar_tpl, $filename, $line_offset);

This reads the input file handle (or scalar-ref) and builds a new perl template
class out of it (and dies if there are syntax errors in the template).

Yes, this 'eval's the input, and no, there are not any guards against
malicious templates.  But you run the same risk any time you run someone's
'./configure' script.

=head2 patch_file

  $cpppp->patch_file($filename, $marker, $new_content);

Reads C<$filename>, looking for lines containing C<"BEGIN $marker"> and
C<"END $marker">.  If not found, it dies.  It then replaces all the lines
between those two lines with C<$new_content>, and writes it back to the same
file handle.

Example:

  my $tpl= $cpppp->require_template("example.cp");
  my $out= $tpl->new->output;
  $cpppp->patch_file("project.h", "example.cp", $out->get('public'));
  $cpppp->patch_file("internal.h", "example.cp", $out->get('protected'));

=head2 backup_and_overwrite_file

  $cpppp->backup_and_overwrite_file($filename, $new_content);

Create a backup of $filename if it already exists, and then write a new file
containing C<$new_content>.  The backup is created by appending a ".N" to the
filename, choosing the first available "N" counting upward from 0.

=head2 get_filtered_output

  my $text= $cpppp->get_filtered_output($sections);

Like C<< $cpppp->output->get >>, but also apply filters to the output, like
L</convert_linecomment_to_c89>.

=head2 write_sections_to_file

  $cpppp->write_sections_to_file($section_spec, $filename);
  $cpppp->write_sections_to_file($section_spec, $filename, $patch_markers);

This is a simple wrapper around L<CodeGen::Cpppp::Output/get> and either
L</backup_and_overwrite_file> or L</patch_file>, depending on whether you
supply C<$patch_markers>.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 VERSION

version 0.003

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
