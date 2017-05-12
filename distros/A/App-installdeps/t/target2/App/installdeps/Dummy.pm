package App::installdeps::Dummy;

use 5.005; # Check for the case of version number only

use App::installdeps::Dummy2;
eval { use App::installdeps::Dummy3; }

1;
