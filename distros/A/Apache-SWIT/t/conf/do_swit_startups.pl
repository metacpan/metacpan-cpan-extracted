use T::DBPage;
use T::SessPage;
use T::HTPage;
use T::HTError;
use T::Upload;
use T::SWIT;
use T::Res;
use T::Redirect;
use Apache::SWIT::LargeObjectHandler;

BEGIN {
T::SWIT->swit_startup;
T::SessPage->swit_startup;
T::HTPage->swit_startup;
T::HTError->swit_startup;
T::DBPage->swit_startup;
};

use T::HTInherit;

1;
