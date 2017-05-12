package Blatte::Compiler;

use Blatte::Parser;

use constant CHUNK_SIZE => 8192;

my $parser;

sub compile {
  my($fh, $cb) = @_;

  my $content = '';

  $parser = new Blatte::Parser() unless defined($parser);

  my $line = 1;

  while (1) {
    if ($content eq '') {
      return undef if $fh->eof();
      $fh->read($content, CHUNK_SIZE);
    }

    my $source = $content;
    my $result = $parser->parse(\$content);

    if (defined($result)) {
      if ($content eq '') {
        if ($fh->eof()) {
          &$cb($result,
               substr($source, 0, (length($source) - length($content))));
        } else {
          # don't trust the result
          $content = $source;
          $fh->read($content, CHUNK_SIZE, length($content));
        }
      } else {
        &$cb($result,
             substr($source, 0, (length($source) - length($content))));
      }
    } elsif ($fh->eof()) {
      return undef if ($parser->eof($content));
      return $line;
    } else {
      $content = $source;
      $fh->read($content, CHUNK_SIZE, length($content));
    }
  }
}

sub compile_sparse {
  my($fh, $cb) = @_;

  my $content = '';

  $parser = new Blatte::Parser() unless defined($parser);

  my $line = 1;

  while (1) {
    if ($content eq '') {
      return undef if $fh->eof();
      $fh->read($content, CHUNK_SIZE);
    }

    if ($content =~ /^([^\\\{]*)[\\\{]/s) {
      my $plain = $1;
      if ($plain ne '') {
        $content = substr($content, length($plain));
        &$cb($plain);
        while ($plain =~ /\n/g) {
          ++$line;
        }
      }
      my $source = $content;
      my $result = $parser->parse(\$content);
      if (defined($result)) {
        $source = substr($source, 0, (length($source) - length($content)));
        &$cb($result, $source);
        while ($source =~ /\n/g) {
          ++$line;
        }
      } elsif ($fh->eof()) {
        return $line;
      } else {
        $fh->read($content, CHUNK_SIZE, length($content));
      }
    } else {
      &$cb($content);
      $content = '';
      while ($content =~ /\n/g) {
        ++$line;
      }
    }
  }
}

1;

__END__

=head1 NAME

Blatte::Compiler - compile a Blatte document into Perl

=head1 SYNOPSIS

    use Blatte::Compiler;

    &Blatte::Compiler::compile($file_handle, \&callback);

    &Blatte::Compiler::compile_sparse($file_handle, \&callback);

    sub callback {
      my($val, $src) = @_;

      if (defined($src)) {
        ...Blatte expression...
      } else {
        ...plain text...
      }
    }

=head1 DESCRIPTION

This is a convenient interface for parsing a file full of Blatte code.
A file handle and a callback are passed to compile() or
compile_sparse() (see below for the difference between the two).  The
callback is then invoked for each top-level item parsed from the
input.

The compile() function treats its entire input as a sequence of Blatte
expressions, including plain text at the top level, which is divided
up into Blatte "words," each of which is one Blatte expression.  The
callback is called once for each expression, with two arguments: the
Perl string resulting from parsing the Blatte expression; and the
Blatte source string itself.

The compile_sparse() function works the same way, except that plain
text at the top-level of the input is not divided into words.  Only
Blatte expressions beginning with a Blatte metacharacter are parsed as
described above.  All text in between such expressions is passed as a
single string to the callback, with I<no second argument>.

=head1 AUTHOR

Bob Glickstein <bobg@zanshin.com>.

Visit the Blatte website, <http://www.blatte.org/>.

=head1 LICENSE

Copyright 2001 Bob Glickstein.  All rights reserved.

Blatte is distributed under the terms of the GNU General Public
License, version 2.  See the file LICENSE that accompanies the Blatte
distribution.

=head1 SEE ALSO

L<Blatte(3)>, L<blatte(1)>.
