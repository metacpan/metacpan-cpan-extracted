# NAME
 
Acme::MarkdownTest - test module to see how markdown is handled
 
# SYNOPSIS
 
    use Acme::MarkdownTest;
    ...
 
# DESCRIPTION
 
This is an empty module that I'm using to see how well
[markdown](https://daringfireball.net/projects/markdown/syntax)
is supported for writing module documentation.
 
In this documentation I've tried to use most of the standard markdown
elements, to see how they come out in perldoc, metacpan, and elsewhere.
 
> This is a blockquote
 
Then we have _italic_ and **bold** formatting.
 
Let's have a bulleted list:
 
 * first bullet
 * second bullet
 
And then a numbered list:
 
 1. first item
 2. second item
 3. third item
 
And then a code sample:
 
    # This is a comment
    if ($answer > 41 && $answer < 43) {
        print "hooray!\n";
    }
 
And an inline `code()` example.
 
The next line should produce a horizontal rule:
 
---
 
 
 
# AUTHOR
 
Neil Bowers <neilb@cpan.org>
 
# COPYRIGHT AND LICENSE
 
This software is copyright (c) 2021 by Neil Bowers.
 
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
