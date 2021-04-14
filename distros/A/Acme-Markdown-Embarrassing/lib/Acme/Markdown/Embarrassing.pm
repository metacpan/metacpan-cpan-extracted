package Acme::Markdown::Embarrassing;

use 5.006;
use strict;
use warnings;

=head1 NAME

Acme::Markdown::Embarrassing - Embarrassing the MetaCPAN Markdown converter

=cut

our $VERSION = '2.4';


=head1 SYNOPSIS

This is a toy module to embarrass MetaCPAN Markdown 

=head1 IMAGE (RELATIVE test.png)

=begin html

<div style="display: flex">
<div style="margin: 3px; flex: 1 1 50%">
<img alt="Test" src="test.png" style="max-width: 100%">
</div>
</div>

=end html

=head1 IMAGE (RELATIVE ./test.png)

=begin html

<div style="display: flex">
<div style="margin: 3px; flex: 1 1 50%">
<img alt="Test" src="./test.png" style="max-width: 100%">
</div>
</div>

=end html

=head1 IMAGE (RELATIVE ../../../test.png)

=begin html

<div style="display: flex">
<div style="margin: 3px; flex: 1 1 50%">
<img alt="Test" src="../../../test.png" style="max-width: 100%">
</div>
</div>

=end html

=head1 IMAGE (ROOT RELATIVE /test.png)

=begin html

<div style="display: flex">
<div style="margin: 3px; flex: 1 1 50%">
<img alt="Test" src="/test.png" style="max-width: 100%">
</div>
</div>

=end html

=head1 IMAGE FROM SOURCE (ABSOLUTE)

=begin html

<div style="display: flex">
<div style="margin: 3px; flex: 1 1 50%">
<img alt="Test" src="https://metacpan.org/source/CONTRA/Acme-Markdown-Embarrassing-1.6/test.png" style="max-width: 100%"">
</div>
</div>

=end html

=head1 IMAGE FROM FASTAPI (ABSOLUTE)

=begin html

<div style="display: flex">
<div style="margin: 3px; flex: 1 1 50%">
<img alt="Test" src="https://fastapi.metacpan.org/source/CONTRA/Acme-Markdown-Embarrassing-1.6/test.png" style="max-width: 100%">
</div>
</div>

=end html

=head1 IMAGE FROM GITHUB (ABSOLUTE)

=begin html

<div style="display: flex">
<div style="margin: 3px; flex: 1 1 50%">
<img alt="Test" src="https://raw.githubusercontent.com/thibaultduponchelle/Acme-Markdown-Embarrassing/master/test.png" style="max-width: 100%">
</div>
</div>

=end html

=cut 

1; # End of Acme::Markdown::Embarrassing
