# NAME

App::BatParser - Parse DOS .bat and .cmd files

# VERSION

version 0.006

# DESCRIPTION

Parse DOS .bat and .cmd files

# SYNOPSYS

```perl
use App::BatParser;
use Path::Tiny;
use Data::Dumper;

my $parser = App::BatParser->new;
my $bat_string = Path::Tiny::path('t/cmd/simple.cmd')->slurp;

say Dumper($parser->parse($bat_string));
```

# METHODS

## grammar

Returns the [Regexp::Grammars](https://metacpan.org/pod/Regexp::Grammars)'s grammar

## parse

Parses the text as a bat/cmd file

### Returns

Hash representation of file on success, empty list on fail

# AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Pablo Rodríguez González.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

# CONTRIBUTORS

- eva.dominguez <eva.dominguez@meteologica.com>
- Toby Inkster <tobyink@cpan.org>
