# Data::MuForm::Model::DBIC - DBIC model for Data::MuForm

# EXPERIMENTAL - for experimentation and feedback only

# QUICK START GUIDE:

This git repository can build a Data::MuForm distribution using [dzil]( https://metacpan.org/pod/distribution/Dist-Zilla/bin/dzil) command
from the [Dist::Zilla]( https://metacpan.org/pod/Dist::Zilla) distribution that you could install using cpan.

Once you have [Dist::Zilla]( https://metacpan.org/pod/Dist::Zilla) installed this distribution can be build or installed using [dzil]( https://metacpan.org/pod/distribution/Dist-Zilla/bin/dzil):

     dzil authordeps --missing | cpanm  # Installs packages needed to build
     dzil build   # Generates a build directory and the tar.gz of the Data::MuForm distribution
     dzil install # Installs the distribution.


