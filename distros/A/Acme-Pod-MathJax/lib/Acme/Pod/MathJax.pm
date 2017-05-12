package Acme::Pod::MathJax;

use strict;
use warnings;

our $VERSION = '0.03';
$VERSION = eval $VERSION;

1;

=head1 NAME

Acme::Pod::MathJax - All your math are belong to us!

=head1 DESCRIPTION

For now this isn't a module as such, but rather a way to test different pod-renderer's abilities to handle MathJax. The following examples are taken directly from MathJax's website.

=head1 EXAMPLES

The following equations are represented in the HTML source code as LaTeX expressions.

=head2 The Lorenz Equations

\[\begin{aligned}
\dot{x} & = \sigma(y-x) \\
\dot{y} & = \rho x - y - xz \\
\dot{z} & = -\beta z + xy
\end{aligned} \]

=head2 The Cauchy-Schwarz Inequality

\[ \left( \sum_{k=1}^n a_k b_k \right)^2 \leq \left( \sum_{k=1}^n a_k^2 \right) \left( \sum_{k=1}^n b_k^2 \right) \]

=head2 A Cross Product Formula

\[\mathbf{V}_1 \times \mathbf{V}_2 =  \begin{vmatrix}
\mathbf{i} & \mathbf{j} & \mathbf{k} \\
\frac{\partial X}{\partial u} &  \frac{\partial Y}{\partial u} & 0 \\
\frac{\partial X}{\partial v} &  \frac{\partial Y}{\partial v} & 0
\end{vmatrix}  \]

=head2 The probability of getting \(k\) heads when flipping \(n\) coins is

\[P(E)   = {n \choose k} p^k (1-p)^{ n-k} \]

=head2 An Identity of Ramanujan

\[ \frac{1}{\Bigl(\sqrt{\phi \sqrt{5}}-\phi\Bigr) e^{\frac25 \pi}} =
1+\frac{e^{-2\pi}} {1+\frac{e^{-4\pi}} {1+\frac{e^{-6\pi}}
{1+\frac{e^{-8\pi}} {1+\ldots} } } } \]

=head2 A Rogers-Ramanujan Identity

\[  1 +  \frac{q^2}{(1-q)}+\frac{q^6}{(1-q)(1-q^2)}+\cdots =
\prod_{j=0}^{\infty}\frac{1}{(1-q^{5j+2})(1-q^{5j+3})},
\quad\quad \text{for $|q| E<lt> 1$}. \]

=head2 Maxwell's Equations

\[  \begin{aligned}
\nabla \times \vec{\mathbf{B}} -\, \frac1c\, \frac{\partial\vec{\mathbf{E}}}{\partial t} & = \frac{4\pi}{c}\vec{\mathbf{j}} \\   \nabla \cdot \vec{\mathbf{E}} & = 4 \pi \rho \\
\nabla \times \vec{\mathbf{E}}\, +\, \frac1c\, \frac{\partial\vec{\mathbf{B}}}{\partial t} & = \vec{\mathbf{0}} \\
\nabla \cdot \vec{\mathbf{B}} & = 0 \end{aligned}
\]

Finally, while display equations look good for a page of samples, the ability to mix math and text in a paragraph is also important. This expression \(\sqrt{3x-1}+(1+x)^2\) is an example of an inline equation.  As you see, MathJax equations can be used this way as well, without unduly disturbing the spacing between lines.

=head1 SEE ALSO

=over

=item L<http://www.mathjax.org/>

=item L<http://www.mathjax.org/demos/tex-samples/>

=item L<Acme::XSS>

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Acme-Pod-MathJax>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

All content except math examples Copyright (C) 2013 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=begin html

<script>

// This is to test github readme

function loadMathJax () {
  var script = document.createElement("script");
  script.type = "text/javascript";
  script.src  = "http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML";
  document.getElementsByTagName("head")[0].appendChild(script);
}

(function(){loadMathJax();})();

</script>

=end html

=cut

