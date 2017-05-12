#include <iostream.h>
#include "hello.h"

class Hello_impl : virtual public Hello_skel {
public:
    void hello (const char *s)
    {
	cout << s << endl;
    }
};

static Hello_ptr server = Hello::_nil();

extern "C" CORBA::Boolean
mico_module_init (const char *version)
{
    if (strcmp (version, MICO_VERSION))
	return FALSE;
    server = new Hello_impl;
    return TRUE;
}

extern "C" void
mico_module_exit ()
{
    CORBA::release (server);
}
