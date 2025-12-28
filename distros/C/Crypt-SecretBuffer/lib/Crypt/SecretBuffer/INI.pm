package Crypt::SecretBuffer::INI;
# VERSION
# ABSTRACT: Parse INI format from a SecretBuffer
$Crypt::SecretBuffer::INI::VERSION = '0.016';
use strict;
use warnings;
use Carp;
use Crypt::SecretBuffer qw/ secret MATCH_NEGATE MATCH_MULTI ISO8859_1 /;


sub new {
   my $self= bless {
         comment_delim => qr/[;#]/,
         key_value_delim => '=',
         section_delim => undef,
         trim_chars => qr/[ \t]+/,
         inline_comments => !!0,
         bare_keys => !!0,
         field_config => [],
      }, shift;
   while (@_) {
      my ($attr, $val)= splice(@_, 0, 2);
      $self->$attr($val);
   }
   $self;
}


sub key_value_delim {
   @_ > 1? ($_[0]{key_value_delim}= $_[1]) : $_[0]{key_value_delim}
}
sub bare_keys {
   @_ > 1? ($_[0]{bare_keys}= !!$_[1]) : $_[0]{bare_keys}
}
sub trim_chars {
   @_ > 1? ($_[0]{trim_chars}= $_[1]) : $_[0]{trim_chars}
}
sub section_delim {
   @_ > 1? ($_[0]{section_delim}= $_[1]) : $_[0]{section_delim}
}
sub comment_delim {
   @_ > 1? ($_[0]{comment_delim}= $_[1]) : $_[0]{comment_delim}
}
sub inline_comments {
   @_ > 1? ($_[0]{inline_comments}= $_[1]) : $_[0]{inline_comments}
}


sub field_config {
   @_ > 1? ($_[0]{field_config}= _coerce_field_rules($_[1])) : $_[0]{field_config}
}

sub _coerce_field_rules {
   my $rule_spec= shift;
   ref $rule_spec eq 'ARRAY'
      or croak "field rules must be an arrayref";
   my @rules;
   for (my $i= 0; $i < @$rule_spec; $i++) {
      my $rule= $rule_spec->[$i];
      # scalar or regexpref are treated as keys
      if (!ref $rule or ref $rule eq 'Regexp') {
         my $v= $rule_spec->[++$i];
         if (ref $v eq 'ARRAY') {
            $rule= { section => $rule, rules => $v };
         } elsif (ref $v eq 'HASH') {
            $rule= { key => $rule, %$v };
         } elsif (defined $v) {
            $rule= { key => $rule, flags => $v };
         } else {
            croak "Value paired with '$rule' should be arrayref, hashref, or scalar";
         }
      }
      # hashrefs remain as-is
      elsif ($rule ne 'HASH') {
         croak "Expected scalar, Regexp, or hashref at '$rule'";
      }
      $rule->{rules}= _coerce_field_rules($rule->{rules})
         if ref $rule->{rules} eq 'ARRAY';
      push @rules, $rule;
   }
   return \@rules;
}
sub _find_field_rule {
   my ($self, $rules, $section, $key)= @_;
   for (@$rules) {
      if (defined $_->{key}) {
         # It's a rule for keys.  Return it if the key matches.
         return $_ if ref $_->{key} eq 'Regexp'? $key =~ $_->{key} : $key eq $_->{key};
      }
      elsif (defined $_->{section} && defined $section) {
         # It's a rule for sections.  Matching the section name is a bit complex because
         # it can match in ful, or in part, and if the user defines a section hierarchy
         # separator then we need to determine how much of the section name to pass to the
         # recursive call.
         my $sep= $self->section_delim;
         my $key_rule;
         if (ref $_->{section} eq 'Regexp') {
            if ($section =~ $_->{section}) {
               my $subsection;
               if (defined $sep) {
                  # This gets complicated.  The regex matched the whole section name, but the
                  # user maybe intended it to only match some upper portion of the section
                  # hierarchy.
                  $sep= qr/\Q$sep\E/ unless ref $sep eq 'Regexp';
                  while ($section =~ /$sep/g) {
                     if (substr($section, 0, $-[0]) =~ $_->{section}) {
                        $subsection= substr($section, $+[0]);
                     }
                  }
                  my $rule= $self->_find_field_rule($_->{rules}, $section, $key);
               } else {
                  $subsection= $section;
               }
               $key_rule= $self->_find_field_rule($_->{rules}, $subsection, $key);
            }
         } elsif ($section eq $_->{section}) {
            $key_rule= $self->_find_field_rule($_->{rules}, undef, $key);
         } elsif (defined $sep
            && $_->{section} eq substr($section, 0, length $_->{section})
         ) {
            my ($remainder, $subsection)= split $sep, substr($section, length $_->{section}), 2;
            # It was only a match of a hierarchy if the separator matched immediately after
            # the length of $_->{section}.
            $key_rule= $self->_find_field_rule($_->{rules}, $subsection, $key)
               if !length $remainder;
         }
         return $key_rule if defined $key_rule;
      }
   }
   return undef;
}


sub parse_next {
   my ($self, $span)= @_;
   my ($trim_chars, $comment_delim)= ($self->trim_chars, $self->comment_delim);
   my %result;
   while ($span->len && !keys %result) {
      my $line= $span->parse(qr/[^\n]+/);
      if (!$span->parse("\n")) {
         $result{error}= 'No newline on end of file';
      }
      $line->rtrim("\r");
      if ($line->parse('[')) {
         my $header= $line->parse(qr/[^]]+/)->trim($trim_chars);
         if (!$line->parse(']')) {
            $result{error}= "Missing ']' in section header";
            $header->pos($header->pos-1);
            $result{context}= $header;
         } else {
            $result{section}= $header;
            $line->ltrim($trim_chars);
         }
      }
      elsif (!$line->starts_with($comment_delim)) {
         my $key= $line->parse($self->key_value_delim, MATCH_NEGATE|MATCH_MULTI);
         # Make sure key delimiter was found before comment, if inline_comments allowed
         if ($self->inline_comments && (my $comment_start= $key->scan($comment_delim))) {
            $key->lim($comment_start->pos);
            $line->pos($comment_start->pos);
         }
         if ($line->parse($self->key_value_delim)) {
            $result{key}= $key->trim($trim_chars);
            # TODO: handle optional quoting here
            if ($self->inline_comments) {
               $result{value}= $line->parse($comment_delim, MATCH_NEGATE|MATCH_MULTI)->trim($trim_chars);
            } else {
               $result{value}= $line->new->trim($trim_chars);
               $line->pos($line->lim);
            }
         } elsif ($self->bare_keys) {
            $result{key}= $key->trim($trim_chars);
         } else {
            $result{error}= 'Line lacks delimiter "'.$self->key_value_delim.'"';
            $result{context}= $key;
         }
      }
      if ($line->parse($comment_delim)) {
         $result{comment}= $line->trim($trim_chars);
      } elsif ($line->len) {
         $result{error}= 'extra text encountered before end of line';
      }
   }
   return keys %result? \%result : undef;
}


sub parse {
   my ($self, $buf_or_span)= @_;
   my $span= $buf_or_span->can('subspan')? $buf_or_span : $buf_or_span->span;
   my ($node, $section, $key, $value);
   my $sep= $self->section_delim;
   $sep= qr/\Q$sep\E/ if defined $sep && ref $sep ne 'Regexp';
   my $root= defined $sep? {} : [];
   while (my $tokens= $self->parse_next($span)) {
      croak $tokens->{error}
         if defined $tokens->{error};
      if (defined $tokens->{section}) {
         $tokens->{section}->copy_to($section);
         if (defined $sep) {
            $node= $root;
            for (split $sep, $section) {
               croak("conflict between section name and pre-existing key of parent section")
                  if defined $node->{$_} && ref $node->{$_} ne 'HASH';
               $node= ($node->{$_} ||= {});
            }
         } else {
            push @$root, $section, ($node= {});
         }
      }
      if (defined $tokens->{key}) {
         if (!defined $node) {
            if (defined $sep) {
               $node= $root;
            } else {
               push @$root, '', ($node= {});
            }
         }
         $tokens->{key}->copy_to($key);
         if (!$tokens->{value}) {
            $value= undef;
         } else {
            my $rule= $self->_find_field_rule($self->field_config, $section, $key);
            $tokens->{value}->encoding($rule->{encoding})
               if defined $rule->{encoding};
            if ($rule->{secret}) {
               $tokens->{value}->copy_to(($value= secret), encoding => ISO8859_1);
            } else {
               $tokens->{value}->copy_to($value= '');
            }
         }
         $node->{$key}= $value;
      }
   }
   return $root;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::SecretBuffer::INI - Parse INI format from a SecretBuffer

=head1 SYNOPSIS

  use Crypt::SecretBuffer qw/ secret HEX /;
  use Crypt::SecretBuffer::INI;
  
  my $input= secret(<<END);
  [database]
  user=myapp
  password=hunter2
  [database.encryption]
  aes_key=0123456789ABCDEF
  [email]
  smtp_auth=sldkdsjfldsjklfadsjkf
  END
  
  my $ini= Crypt::SecretBuffer::INI->new(
    section_delim => '.',
    field_config => [
      password  => { secret => 1 },
      smtp_auth => { secret => 1 },
      aes_key   => { secret => 1, encoding => HEX },
    ]
  );
  my $config= $ini->parse($input);
  print Data::Dumper->new([$config])
    ->Terse(1)->Sortkeys(1)->Indent(2)->Dump;
  #{
  #  'database' => {
  #    'encryption' => {
  #      'aes_key' => bless( {}, 'Crypt::SecretBuffer' )
  #    },
  #    'password' => bless( {}, 'Crypt::SecretBuffer' ),
  #    'user' => 'myapp'
  #  },
  #  'email' => {
  #    'smtp_auth' => bless( {}, 'Crypt::SecretBuffer' )
  #  }
  #}
  
  # Produce a file with secrets:
  $out= secret;
  $ini->render_sections($out, $header => \%fields);
  $out->save_file($path);

=head1 DESCRIPTION

One of the challenges of trying to keep secrets hidden in a SecretBuffer is that they typically
start inside of config files, and in parsing the config file to load them you leak them into
the Perl interpreter's buffers.

This module lets you parse out the simple common C<< "name=value\n" >> found in many config
files, exposing the keys but selectively loading the value in a SecretBuffer.

=head1 CONSTRUCTORS

=head2 new

  $ini= Crypt::SecretBuffer::INI->new(%attributes);

Pass key/value pairs of attributes to be initialized.

=head1 ATTRIBUTES

=head2 key_value_delim

The delimiter string (or character class) that separates keys from values.  The default is
C<'='> but another common option would be C<':'> or C<< qr/[:=]/ >> to allow both.

=head2 bare_keys

Boolean.  When enabled, a non-empty non-comment line that also lacks a L</key_value_delim>
will be treated as a single key having an undefined value.  When not enabled, that situation
is a parse error.

=head2 trim_chars

The character or character class that should be trimmed from both ends of all keys and values.
The default is C<< qr/[ \t]/ >>.  Note that '\r' and '\n' are implicitly trimmed by the line
processing.  Set this to undef if you want to perform your own trimming.

=head2 section_delim

This can be used to automatically tree-up your sections.  If set, the L</parse> function will
treat the section headers as paths and build nested hashrefs instead of a flat array of
sections.  See examples in L</parse>.

=head2 comment_delim

The delimiter string (or character class) that indicates start of a comment line.  The default
is C<< qr/[;#]/ >>.

=head2 inline_comments

Boolean, whether to allow comments on the end of lines containing other directives/data,
which also means your values can't contain the comment character.

=head2 field_config

This is an arrayref of rules that describe which flags should be applied to which
type of keys.  Each element is of the form:

  { key => $literal_or_regex, encoding => $enc, secret => $bool },

or

  { section => $literal_or_regex, rules => [
     ...
  ]}

As a convenience, that structure can be built from a shorter notation:

  [
    $literal_key     => \%attrs,
    qr/$key_pattern/ => \%attrs,
    $section_header => [
      ...
    ],
    qr/$section_pattern/ => [
      ...
    ],
    ...
  ]

Note that the rule lists are arrays, not hashrefs.  THis allows them to have regexes as keys,
and preserves order.  During a parse, rules are checked first to last, and the first match wins.

=head1 METHODS

=head2 parse_next

  %attrs= $self->parse_next($span);

Given a L<Crypt::SecretBuffer::Span> (which has C<< ->pos >> pointed at the next line of INI
data) parse the next INI directive out of it.  This can return one or more of:

  comment => $comment_span,
  section => $header_span,
  key     => $key_span,
  value   => $value_span,
  error   => $parse_error_text,

The Span objects refer to a SecretBuffer, and you then have the option of loading them into Perl
scalars or copying them to their own SecretBuffer objects.

=head2 parse

  $tree= $ini->parse($buffer_or_span);

This is a convenient loop around L</parse_next> which uses the specification in L</field_config>
to determine which keys are secret.  If you defined C<section_delim>, this returns a tree of
configs where each section is a hashref located at the path from splitting its header.
If C<section_delim> is not defined, the result is an arrayref of section name and hashref pairs
in the order they were found in the file.

This function dies on any parse errors.

=head1 VERSION

version 0.016

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
