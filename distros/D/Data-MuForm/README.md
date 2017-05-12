# Data::MuForm - validator and HTML form processor using Moo

# EXPERIMENTAL - for experimentation and feedback only

Data::MuForm is a data validation and form handling package written in Moo.
It is a conversion of HTML::FormHandler to Moo. The core behavior is the same,
but things have been regularized, simplified, renamed, and in some cases re-written.
Rendering is substantially changed.

A MuForm 'validator' or 'form' is a Perl subclass of Data::MuForm. In your
class you define fields and validators. Because it's a Perl class written with
Moo, you have a lot of flexibility and control.

Data::MuForm will be loaded into CPAN evenutually.

# QUICK START GUIDE:

This git repository can build a Data::MuForm distribution using [dzil]( https://metacpan.org/pod/distribution/Dist-Zilla/bin/dzil) command
from the [Dist::Zilla]( https://metacpan.org/pod/Dist::Zilla) distribution that you could install using cpan.

Once you have [Dist::Zilla]( https://metacpan.org/pod/Dist::Zilla) installed this distribution can be build or installed using [dzil]( https://metacpan.org/pod/distribution/Dist-Zilla/bin/dzil):

     dzil authordeps --missing | cpanm  # Installs packages needed to build
     dzil build   # Generates a build directory and the tar.gz of the Data::MuForm distribution
     dzil install # Installs the distribution.


