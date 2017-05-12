package Activiti::Rest::Error;
use Activiti::Sane;
use Moo;
extends 'Throwable::Error';

has status_code => (
    is => 'ro',
    required => 1
);
#prior to activiti version 5.17, now exception
has error_message => (
    is => 'ro',
    required => 1
);
#from activiti version 5.17, formerly errorMessage
has exception => (
    is => 'ro',
    required => 1
);
has content_type => (
    is => 'ro',
    required => 1
);
has content => (
    is => 'ro',
    required => 1,
);

#see: http://www.activiti.org/userguide/#N12F88 for status codes

package Activiti::Rest::Error::UnAuthorized;
use Activiti::Sane;
use Moo;
extends 'Activiti::Rest::Error';

package Activiti::Rest::Error::Forbidden;
use Activiti::Sane;
use Moo;
extends 'Activiti::Rest::Error';


package Activiti::Rest::Error::NotFound;
use Activiti::Sane;
use Moo;
extends 'Activiti::Rest::Error';

package Activiti::Rest::Error::MethodNotAllowed;
use Activiti::Sane;
use Moo;
extends 'Activiti::Rest::Error';

package Activiti::Rest::Error::Conflict;
use Activiti::Sane;
use Moo;
extends 'Activiti::Rest::Error';

package Activiti::Rest::Error::UnsupportedMediaType;
use Activiti::Sane;
use Moo;
extends 'Activiti::Rest::Error';

package Activiti::Rest::Error::InternalServerError;
use Activiti::Sane;
use Moo;
extends 'Activiti::Rest::Error';

1;
