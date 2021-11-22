package Acme::Markdown::Embarrassing;

use 5.006;
use strict;
use warnings;

our $VERSION = '3.2';

=pod

=encoding UTF-8

=head1 Acme::Markdown::Embarrasing

=head1 NAME

Acme::Markdown::Embarrassing - Embarrassing the MetaCPAN Markdown converter

=head1 SYNOPYS

This is a toy module to embarrass MetaCPAN Markdown 

=head1 SEE ALSO

See also L<https://metacpan.org/release/CONTRA/Acme-Markdown-Embarrassing-3.2/source/README.md>

See also L<https://metacpan.org/release/CONTRA/Acme-Markdown-Embarrassing-3.2/source/MarkdownTest.md>

=head1 MARKDOWN

=begin markdown

## IMAGES

#### Include relative image `![](test.png)`
![](test.png)

#### Include relative image `![](./test.png)`
![](./test.png)

#### Include absolute internal non versioned image `![](https://metacpan.org/source/CONTRA/Acme-Markdown-Embarrassing/test.png)`
![](https://metacpan.org/source/CONTRA/Acme-Markdown-Embarrassing/test.png)

#### Include absolute internal image `![](https://metacpan.org/source/CONTRA/Acme-Markdown-Embarrassing-1.6/test.png)`
![](https://metacpan.org/source/CONTRA/Acme-Markdown-Embarrassing-1.6/test.png)

#### Include absolute fastapi image `![](https://fastapi.metacpan.org/source/CONTRA/Acme-Markdown-Embarrassing-1.6/test.png)`
![](https://fastapi.metacpan.org/source/CONTRA/Acme-Markdown-Embarrassing-1.6/test.png)

#### Include absolute external image `![](https://raw.githubusercontent.com/thibaultduponchelle/Acme-Markdown-Embarrassing/master/test.png)`
![](https://raw.githubusercontent.com/thibaultduponchelle/Acme-Markdown-Embarrassing/master/test.png)


# Title 1
## Title 2
### Title 3
#### Title 4
##### Title 5
###### Title 6

Title 1
==
Title 2
--

## Usual styling
Some **BOLD** or alternate __BOLD__ text with some *italic* and alternate _italic_

Some ***BOLD ITALIC*** or alternate ___BOLD ITALIC___

Some ~~strikethrough~~

## Quote
> There Is More Than One Way To Do It

> Top level
>> Nested

> Quote with styling
> - First
> - Second
>
> Some **BOLD** 

## Lists ([#2330](https://github.com/metacpan/metacpan-web/issues/2330))
### Bullets (-)
- First
- Second
- Third

### Bullets (\*)
- Foo
- Bar
- Baz

### Bullets (+)
+ Foo
+ Bar
+ Baz

### Numbered list
1. First
2. Second
3. Third

1) First
2) Second
3) Third


## Code
Inlined `code` or inlined ``code with `backticks` inside``

### Perl ([#2312](https://github.com/metacpan/metacpan-web/issues/2312))
```perl
#!/usr/bin/env perl

use Acme::LOLCAT;
 
print translate("You too can speak like a lolcat!") ."\n";
```

### Indented with spaces
    #!/usr/bin/env perl

    use Acme::LOLCAT;
 
    print translate("You too can speak like a lolcat!") ."\n";

### Indented with tab
	#!/usr/bin/env perl

	use Acme::LOLCAT;
 
	print translate("You too can speak like a lolcat!") ."\n";

## Images
### PNG
![](https://raw.githubusercontent.com/thibaultduponchelle/Acme-Markdown-Embarrassing/master/tux.png)

### SVG
![](https://raw.githubusercontent.com/thibaultduponchelle/Acme-Markdown-Embarrassing/master/tux.svg)

## Tables

| Pos         | Club        | Points      | 
|:------------|:-----------:|:-----------:| 
|      1      | OM          | 12          |   
|      2      | St Etienne  | 9           |    
|      3      | OGC Nice    | 3           |

## Rules
***

---

________________

## Links
[MetaCPAN](https://metacpan.org) or with title [MetaCPAN](https://metacpan.org "MetaCPAN")

<https://www.metacpan.org>

## Image with link
[![](https://raw.githubusercontent.com/thibaultduponchelle/Acme-Markdown-Embarrassing/master/tux.png)](https://linuxfr.org/)

## Emoji
🐪 🐪 🐪 🐪 🐪 🐪 🐪 🐪 🐪 🐪 🐪 🐪

🐺 🐺 🐺 🐺 🐺 🐺 🐺 🐺 🐺 🐺 🐺 🐺

🐪 🐪 🐪 🐪 🐪 🐪 🐪 🐪 🐪 🐪 🐪 🐪

🐺 🐺 🐺 🐺 🐺 🐺 🐺 🐺 🐺 🐺 🐺 🐺

🐪 🐪 🐪 🐪 🐪 🐪 🐪 🐪 🐪 🐪 🐪 🐪

🐺 🐺 🐺 🐺 🐺 🐺 🐺 🐺 🐺 🐺 🐺 🐺

🐪 🐪 🐪 🐪 🐪 🐪 🐪 🐪 🐪 🐪 🐪 🐪

🐺 🐺 🐺 🐺 🐺 🐺 🐺 🐺 🐺 🐺 🐺 🐺

## Escape 
\* 

\` 

\-

\+

\#

## Html embedded
Some <strong>BOLD</strong> text.

A
<br/>
Sentence
<br/>
<br/>
On
<br/>
<br/>
<br/>
Multiple
<br/>
<br/>
<br/>
<br/>
Lines

## Huge image
![huge](https://raw.githubusercontent.com/thibaultduponchelle/Acme-Markdown-Embarrassing/master/huge.png)


# Embed HTML (and IMAGES)

## IMAGE (RELATIVE test.png)

<div style="display: flex">
<div style="margin: 3px; flex: 1 1 50%">
<img alt="Test" src="test.png" style="max-width: 100%">
</div>
</div>

## IMAGE (RELATIVE ./test.png)

<div style="display: flex">
<div style="margin: 3px; flex: 1 1 50%">
<img alt="Test" src="./test.png" style="max-width: 100%">
</div>
</div>

## IMAGE (RELATIVE ../../../test.png)

<div style="display: flex">
<div style="margin: 3px; flex: 1 1 50%">
<img alt="Test" src="../../../test.png" style="max-width: 100%">
</div>
</div>

## IMAGE (ROOT RELATIVE /test.png)

<div style="display: flex">
<div style="margin: 3px; flex: 1 1 50%">
<img alt="Test" src="/test.png" style="max-width: 100%">
</div>
</div>

## IMAGE FROM SOURCE (ABSOLUTE)

<div style="display: flex">
<div style="margin: 3px; flex: 1 1 50%">
<img alt="Test" src="https://metacpan.org/source/CONTRA/Acme-Markdown-Embarrassing-1.6/test.png" style="max-width: 100%"">
</div>
</div>

## IMAGE FROM FASTAPI (ABSOLUTE)

<div style="display: flex">
<div style="margin: 3px; flex: 1 1 50%">
<img alt="Test" src="https://fastapi.metacpan.org/source/CONTRA/Acme-Markdown-Embarrassing-1.6/test.png" style="max-width: 100%">
</div>
</div>

## IMAGE FROM GITHUB (ABSOLUTE)

<div style="display: flex">
<div style="margin: 3px; flex: 1 1 50%">
<img alt="Test" src="https://raw.githubusercontent.com/thibaultduponchelle/Acme-Markdown-Embarrassing/master/test.png" style="max-width: 100%">
</div>
</div>
=end markdown

=cut

1; # End of Acme::Markdown::Embarrassing
