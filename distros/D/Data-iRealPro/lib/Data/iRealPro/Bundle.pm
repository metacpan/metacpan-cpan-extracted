#! perl

# Dummy for the packager, to get output backends and other
# conditionally required modules included.

# Backends.
use Data::iRealPro::Input;
use Data::iRealPro::Output;
use Data::iRealPro::Input::Text;
use Data::iRealPro::Output::Base;
use Data::iRealPro::Output::HTML;
use Data::iRealPro::Output::Imager;
use Data::iRealPro::Output::JSON;
use Data::iRealPro::Output::Text;

# See also:
# pp/common/PDF_API2_Bundle.pm
# pp/common/Imager_Bundle.pm
