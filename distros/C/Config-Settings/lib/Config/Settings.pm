package Config::Settings;

use Carp qw/confess/;
use Parse::RecDescent;

use strict;
use warnings;

our $VERSION = '0.02';

my $parser = Parse::RecDescent->new (<<'EOF');
config:
  <skip: qr/\s* ([#] .*? \n \s*)*/x> scope

scope:
  assignment(s? /;+/) /;*/
  { $return = [ 'SCOPE',@{ $item[1] } ] }

assignment:
  deep_assignment | direct_assignment | true_assignment | <error>

deep_assignment:
  keyword keyword value
  { $return = [ $item[1] => $item[2] => $item[3] ]; 1 }

direct_assignment:
  keyword value
  { $return = [ $item[1] => $item[2] ]; 1 }

true_assignment:
  keyword
  { $return = [ $item[1] => 1 ]; 1 }

keyword:
  integer | string | bareword

value:
  integer | string | list | hash | symbol

bareword:
  /[\w:]+/

integer:
  /\d+/

string:
  <perl_quotelike>
  { $return = $item[1][2]; 1 }

list:
  "[" value(s?) "]"
  { $return = [ 'LIST',@{ $item[2] } ]; 1 }

hash:
  "{" scope "}"
  { $return = $item[2]; 1 }

symbol:
  bareword
  { $return = [ 'SYMBOL',$item[1] ]; 1 }

EOF

my %default_symbols = (
  null  => undef,
  true  => 1,
  false => '',
);

sub new {
  my $class = shift;

  my $node = (ref $_[0] eq 'HASH' ? $_[0] : { @_ });

  $node->{symbol_table} ||= { %default_symbols };

  return bless $node,$class;
}

sub parse_file {
  my ($self,$file) = @_;

  open (my $fh,$file) or confess $!;

  my $content = do { local $/; <$fh> };

  close $fh;

  return $self->parse ($content);
}

sub parse {
  my ($self,$content) = @_;

  return $self->_process_value ($parser->config ($content));
}

sub _process_scope {
  my ($self,$scope) = @_;

  my %result;

  foreach my $assignment (@$scope) {
    my ($key,$value) = @$assignment;

    if (@$assignment > 2) {
      $self->_deep_assignment (\%result,@$assignment);
    } else {
      $self->_simple_assignment (\%result,@$assignment);
    }
  }

  return \%result;
}

sub _simple_assignment {
  my ($self,$hashref,$key,$value) = @_;

  $value = $self->_process_value ($value);

  if (exists $hashref->{$key}) {
    if (ref $hashref->{$key} eq 'ARRAY') {
      push @{ $hashref->{$key} },$value;
    } else {
      $hashref->{$key} = [ $hashref->{$key},$value ];
    }
  } else {
    $hashref->{$key} = $value;
  }

  return;
}

sub _deep_assignment {
  my ($self,$hashref,$key1,$key2,$value) = @_;

  $value = $self->_process_value ($value);

  $key2 = $self->_process_value ($key2);

  if (ref $hashref->{$key1} eq 'HASH') {
    $hashref->{$key1}->{$key2} = $value;
  } else {
    $hashref->{$key1} = { $key2 => $value };
  }

  return;
}

sub _process_value {
  my ($self,$value) = @_;

  if (ref $value) {
    my $value_type = shift @$value;

    if ($value_type eq 'SCOPE') {
      $value = $self->_process_scope ($value);
    } elsif ($value_type eq 'LIST') {
      $value = [ map { $self->_process_value ($_) } @$value ];
    } elsif ($value_type eq 'SYMBOL') {
      $value = $self->_process_symbol (@$value);
    } else {
      confess "Uh oh, this should never happen";
    }
  }

  return $value;
}

sub _process_symbol {
  my ($self,$symbol) = @_;

  my $value;

  if (exists $self->{symbol_table}->{ $symbol }) {
    my $symbol_entry = $self->{symbol_table}->{ $symbol };

    $value = (ref $symbol_entry eq 'CODE' ? $symbol_entry->() : $symbol_entry);
  } else {
    confess "No such symbol '$symbol' in symbol table";
  }

  return $value;
}

1;

__END__

=pod

=head1 NAME

Config::Settings - Parsing pleasant configuration files

=head1 SYNOPSIS

  # myapp.settings

  hello {
    world 1;
  };

  # myapp.pl

  use Config::Settings;

  my $settings = Config::Settings->new->parse_file ("myapp.settings");

  print "Hello world!\n" if $settings->{hello}->{world};

=head1 DESCRIPTION

=head2 Rationale

The first thing that probably comes to most people's mind when they
see this module is "Why another Config:: module?". So I feel I should
probably first explain what motivated me to write this module in the
first place before I go into more details of how it works.

There are already numerous modules for doing configuration files
available on CPAN. L<YAML> appears to be a prefered module, as do
L<Config::General>. There are of course also modules like
L<Config::Any> which lets be open to many formats instead of being
bound to any particular one, but this modules only supports what is
already implemented in another module so if one feels one is not
entirely happy with any format with an implementation on CPAN, it
doesn't really doesn't solve the fundamental issue that was my
incentive to implement a new format.

So let us have a look at the other formats. As previously mentioned,
one of the more popular formats today appears to be YAML. YAML isn't
really a configuration file format as such, it's a serialization
format. It's just better than the more riddiculous alternatives like
say XML. It's well documented which is an important feature and
reading it, unlike XML, doesn't require a whole lot of brain power
for either a human or a machine. A problem with YAML is the
whitespace and tab sensitivity. Some will of course not call this a
problem. After all, python is constructed on the very same principle,
but this isn't python. This is perl. Chances are that if a python-ish
structure had been more appropriate for your brain, you would already
be using python and not reading the documentation for this module.

But more importantly, this sensitivity is also a problem for people
who are not familiar with the format. When I work on a Catalyst
project, I seldom work alone. I work with graphic designers, I work
with administrators, I work with a lot of people who is not likely to
ever have encountered YAML before. Now, YAML *is* easy to read, but
unfortunately it's not always easy to write. And sometimes, these
people who I am working with needs to make a change to the settings
for an application. They make the change, hit tab a few times to
make the element position correctly, save the file, and voila it
explodes without it really being obvious why.

A different format that has recently become more popular is the
L<Config::General> module. This module has adopted the format used
by Apache. It's a mixture of markup language and simple key/value
pairs. And in light of what I talked about with regards to YAML, this
certainly is a better alternative. More people has configured
Apache, and even if they haven't it's still more obvious how to
modify the configuration file. The syntax of the format is to a much
larger extent self-documenting and this is an important feature for a
configuration file format. So what is the problem with this module?

For starters, it occationally becomes *too* simple. There is for
instance no way of constructing a single element array in it, or
really, a good way of specifying an array at all. An array in the
Config::General sense is more about a directive being specified
multiple times, not constructing arrays. However, I can see why the
decision to keep this out of the configuration format was made.
Staying true to the Apache format and allowing real arrays really
cannot be done. Another thing that bothers me about this format is
the weird way it uses something that looks like a markup language
to declare sections. I don't like this, I always tend to forget
closing tags for more complicated data structures. Such structures
rarely exists in a real Apache configuration file, but are very
common in a configuration file for a perl program. And the closing
tags are also uneccesarily long. Their long name does nothing to
help me remember which closing tag belongs to which starting tag,
it's really just noise in a configuration file.

=head2 Design goals

In the rationale I layed out above, I pointed out some important
qualities in a configuration file format.

=over 4

=item It must be easy to read.

=item It must be easy to write.

=item The syntax must to a high degree be self-documenting.

=item It should still allow somewhat complex data structures.

=item It should not have riddiculously redundant syntax as its only option.

=back

These qualities can sometimes be incompatible with each other,
depending on how they are achieved. And there's in any case no such
thing as a perfect solution. The best one can hope to achieve is
something we can be comfortable with.

One configuration format I've been happy with previously has been the
BIND (The nameserver) configuration format. It's very C/perl-ish,
allows you to express somewhat complex configuration structures with a
very simlpe syntax, and most importantly, it just "feels right". So I
looked around on CPAN to see if I could find a parser that would allow
me to parse something that was at least somewhat similar, but couldn't
find any. So I started this module as a project both to see if a
reasonable parser for such a format could be made and to learn how to
use the L<Parse::RecDescent> module.

  # This is an example from the default named.conf on my system.

  zone "localhost" {
    type master;
    file "master/localhost-forward.db";
  };

=head1 SPECIFICATIONS

=head2 Overview

And here they are, the raw, improvised specifications for the format.
I'll try to find a better way to specify the format before the
production release, but for now this will have to do. When a plural of
something is specified, the separator used will be specified
inside the () part. For instance, "assignments(';')" means that multiple
assignments are allowed, separated by the ';' character.

  top: assignments(';')

  assignment: key | key value | key key value

  key: integer | string | bareword

  value: integer | string | list | hash | symbol

  integer: /\d+/

  string: '"' <text> '"'

  bareword: [\w:]+
   
  list: '[' values(' ') ']'

  hash: '{' assignments(';') '}'

  symbol: bareword

=head2 Assignment

As specified above, there are three different ways to assign something
to a key. The first is the keyword style assignment. No value is
specified, implicitly setting the key to a true value.

  foo; # perl equivalent: { foo => 1 }

The second way is the standard key/value type assignment.

  foo "bar"; # perl equivalent: { foo => "bar" }

The third is similar to the standard key/value type assignment, but
works on one level deeper. You specify two keys, and the first key
is implicitly refering to a hash (It will be converted to one if it
isn't already) while the second key is a key for that hash. This is to
allow constructs like this as seen in the earlier example:

  zone "localhost" {
    type master;
    file "master/localhost.db";
  };

This is almost equivalent of doing:

  zone {
    localhost {
      type master;
      file "master/localhost.db";
    };
  };

However, the latter example will overwrite any existing "zone" key,
while the first will merge with an existing hash.

=head2 Values

There are three different types of values:

=over 4

=item Integer

An integer number. More number types will be supported before
a production release, but currently this is it.

=item String

A plain doublequoted string.

=item List

A collection of values enclosed in [] brackets separated by spaces.

=item Hash

A collection of assignments enclosed in {} brackets separated by
semicolons.

=item Symbol

A bareword that is looked up in an internal symbol table and replaced
with the value found there. A symbol that does not resolve will throw
an error. The currently predefined symbols are "null", "true", and
"false", respectively returning undef, 1, and an empty string.

=back

=head2 Keys

Keys can be integers, strings, and barewords. Bareword matches the
same as symbols, but when on the left hand side will not be looked up
in the symbol table and instead just used as a literal value like when
using the perl "=>" operator.

=head1 METHODS

=head2 new

  my $parser = Config::Settings->new;

Constructs a new configuration file parser. See below for constructor
arguments.

=head2 parse

  my $settings = $parser->parse ($string);

Parses a text string. This will soon be extended to also allow
references and filehandles, but right now only plain strings are
supported.

=head2 parse_file

  my $settings = $parser->parse_file ($filename);

Sugar for parsing the content of a given file.

=head1 CONSTRUCTOR ARGUMENTS

=head2 symbol_table

  my $parser = Config::Settings->new (symbol_table => {});

Specifies a custom symbol table to use. A symbol table is a regular
hash table with the symbol name as key. The value may be anything, but
if it's a coderef, it will be executed and the return value used. If
you need the value to be an actual coderef, wrap it in another
coderef.

=head1 EXAMPLES

=head2 A Catalyst application

  name "MyApp";

  model "MyApp" {
    schema_class "MyApp::Schema";

    connect_info {
      dsn        "dbi:SQLite:dbname=__HOME__/db/myapp.db";
      AutoCommit;
      auto_savepoint;
    };
  };

  view "TT" {
    ENCODING           "UTF-8";
    TEMPLATE_EXTENSION ".html";
    INCLUDE_PATH       "__HOME__/templates";
  };

  Plugin::Authentication {
    default_realm "members";

    realms {
      members {
        credential {
          class              "Password";
          password_field     "password";
          password_type      "hashed";
          password_hash_type "SHA-256";
        };
 
        store {
          class      "DBIx::Class";
          user_model "MyApp::User";
        };
      };
    };
  };

=head1 SEE ALSO

=over 4

=item L<Config::General>

=back

=head1 BUGS AND DEVELOPMENT

So you think you might have found a bug in my software do you? Well,
don't be shy about it. I can't improve this package if you don't tell
me about it. Go to its homepage listed below where you will find an
issue tracker.

B<Please don't use the CPAN-RT issue tracker to report bugs.> Although
I occationally check it, chances are you're not going to get a fast
response.

  Homepage: http://redmine.berle.cc/projects/show/config-settings

  Git: git@github.com:berle/config-settings.git

=head1 AUTHOR

Anders Nor Berle E<lt>berle@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 Anders Nor Berle

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut

