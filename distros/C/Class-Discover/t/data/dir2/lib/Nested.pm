use MooseX::Declare;

class Outer {

  class Global::Versioned {
    our $VERSION = "1";
  }

  class ::Inner::Versioned {
    our $VERSION = "1";
  }

  class ::Inner::Unversioned {
  }
 
  class Global {
  }

  role MyRole {
  }
}
