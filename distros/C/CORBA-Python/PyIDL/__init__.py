
""" PyIDL """

_itf_embedded = dict()

def Register(key, value):
    """ Register an embedded class """
    _itf_embedded[key] = value

def Lookup(key):
    """ Lookup an embedded class """
    return _itf_embedded.get(key, None)



def marshal(output, name, value):
    func = name + '__marshal'
    getattr(output, func)(value)

def demarshal(input_, name):
    func = name + '__demarshal'
    return getattr(input_, func)()

def check(type_, value):
    if isinstance(type_, str):
        if type_ == 'char':
            if not isinstance(value, str):
                raise SystemException('IDL:CORBA/BAD_PARAM:1.0', 2,
                                      CORBA_COMPLETED_MAYBE)
            if len(value) != 1:
                raise SystemException('IDL:CORBA/BAD_PARAM:1.0', 2,
                                      CORBA_COMPLETED_MAYBE)
        elif type_ == 'wchar':
            if not isinstance(value, basestring):
                raise SystemException('IDL:CORBA/BAD_PARAM:1.0', 2,
                                      CORBA_COMPLETED_MAYBE)
            if len(value) != 1:
                raise SystemException('IDL:CORBA/BAD_PARAM:1.0', 2,
                                      CORBA_COMPLETED_MAYBE)
        elif type_ == 'octet':
            if value < 0 or value > 255:
                raise SystemException('IDL:CORBA/BAD_PARAM:1.0', 2,
                                      CORBA_COMPLETED_MAYBE)
        elif type_ == 'short':
            if value < -32768 or value > 32767:
                raise SystemException('IDL:CORBA/BAD_PARAM:1.0', 2,
                                      CORBA_COMPLETED_MAYBE)
        elif type_ == 'unsigned_short':
            if value < 0 or value > 65535:
                raise SystemException('IDL:CORBA/BAD_PARAM:1.0', 2,
                                      CORBA_COMPLETED_MAYBE)
        elif type_ == 'long':
            if value < -2147483648 or value > 2147483647:
                raise SystemException('IDL:CORBA/BAD_PARAM:1.0', 2,
                                      CORBA_COMPLETED_MAYBE)
        elif type_ == 'unsigned_long':
            if value < 0 or value > 4294967295L:
                raise SystemException('IDL:CORBA/BAD_PARAM:1.0', 2,
                                      CORBA_COMPLETED_MAYBE)
        elif type_ == 'long_long':
            if value < -9223372036854775808L or value > 9223372036854775807L:
                raise SystemException('IDL:CORBA/BAD_PARAM:1.0', 2,
                                      CORBA_COMPLETED_MAYBE)
        elif type_ == 'unsigned_long_long':
            if value < 0 or value > 18446744073709551615L:
                raise SystemException('IDL:CORBA/BAD_PARAM:1.0', 2,
                                      CORBA_COMPLETED_MAYBE)
        elif type_ == 'float':
            pass
        elif type_ == 'double':
            pass
        elif type_ == 'long_double':
            pass
        elif type_ == 'boolean':
            pass
        elif type_ == 'string':
            if not isinstance(value, str):
                raise SystemException('IDL:CORBA/BAD_PARAM:1.0', 2,
                                      CORBA_COMPLETED_MAYBE)
        elif type_ == 'wstring':
            if not isinstance(value, basestring):
                raise SystemException('IDL:CORBA/BAD_PARAM:1.0', 2,
                                      CORBA_COMPLETED_MAYBE)
        else:
            print "Internal Error: %s" % type_
            raise SystemException('IDL:CORBA/INTERNAL:1.0', 8,
                                  CORBA_COMPLETED_MAYBE)
    else:
        if not isinstance(value, type_):
            raise SystemException('IDL:CORBA/BAD_PARAM:1.0', 2,
                                  CORBA_COMPLETED_MAYBE)

class UserException(Exception):
    """ An IDL exception is translated into a Python class derived
        from CORBA.UserException. """
    pass

class SystemException(Exception):
    """ CORBA.SystemException """

    def __init__(self, repos_id, minor, completed):
        Exception.__init__(self)
        self.repos_id = repos_id
        self.minor = minor
        self.completed = completed

    def __str__(self):
        return self.repos_id

CORBA_COMPLETED_YES = 0     # The object implementation has completed
                            # processing prior to the exception being raised.
CORBA_COMPLETED_NO = 1      # The object implementation was never initiated
                            # prior to the exception being raised.
CORBA_COMPLETED_MAYBE = 2   # The status of implementation completion is
                            # indeterminate.

class Enum(object):
    """ base class for IDL enum """

    def __init__(self, str_, val):
        self._val = val
        self._enum_str[val] = str_
        self._enum[val] = self

    def marshal(self, output):
        output.long__marshal(self._val)

    def demarshal(cls, input_):
        val = input_.long__demarshal()
        if cls._enum.has_key(val):
            return cls._enum[val]
        else:
            raise SystemException('IDL:CORBA/MARSHAL:1.0', 9,
                                  CORBA_COMPLETED_MAYBE)
    demarshal = classmethod(demarshal)

    def __repr__(self):
        return self._enum_str[self._val]

