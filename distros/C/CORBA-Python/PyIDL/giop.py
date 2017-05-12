# ex: set ro:
#   This file was generated (by idl2py). DO NOT modify it.
# From file : GIOP.idl, 9058 octets, Fri Oct 05 19:47:18 2007

""" Module IDL:omg.org/GIOP:1.0 """

import PyIDL as CORBA

import PyIDL.iop as IOP

class Version(object):
    """ Struct IDL:omg.org/GIOP/Version:1.0 """

    def __init__(self, major, minor):
        self._setmajor(major)
        self._setminor(minor)

    def _setmajor(self, major):
        CORBA.check('octet', major)
        self._major = major

    def _getmajor(self):
        return self._major

    major = property(fset=_setmajor, fget=_getmajor)

    def _setminor(self, minor):
        CORBA.check('octet', minor)
        self._minor = minor

    def _getminor(self):
        return self._minor

    minor = property(fset=_setminor, fget=_getminor)

    def marshal(self, output):
            CORBA.marshal(output, 'octet', self.major)
            CORBA.marshal(output, 'octet', self.minor)

    def demarshal(cls, input_):
            major = CORBA.demarshal(input_, 'octet')
            minor = CORBA.demarshal(input_, 'octet')
            return cls(major, minor)
    demarshal = classmethod(demarshal)

    def __eq__(self, obj):
        if obj == None:
            return False
        if not isinstance(obj, type(self)):
            return False
        if self.major != obj.major:
            return False
        if self.minor != obj.minor:
            return False
        return True

    def __ne__(self, obj):
        return not self.__eq__(obj)

    def __repr__(self):
        lst = []
        lst.append('octet major=' + repr(self.major))
        lst.append('octet minor=' + repr(self.minor))
        inner = ',\n'.join(lst)
        inner = '\n'.join(['   ' + line for line in inner.split('\n')])
        return 'struct Version {\n' + inner + '\n}'

    def _get_id(cls):
        return 'IDL:omg.org/GIOP/Version:1.0'
    corba_id = classmethod(_get_id)

class Principal(str):
    """ Typedef IDL:omg.org/GIOP/Principal:1.0 """

    def __init__(self, val):
        if val != None:
            if not isinstance(val, str):
                raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)
        str.__init__(val)

    def marshal(self, output):
        CORBA.marshal(output, 'long', len(self))
        for elt in self:
            CORBA.marshal(output, 'octet', ord(elt))

    def demarshal(cls, input_):
        length = CORBA.demarshal(input_, 'long')
        lst = []
        for _ in xrange(length):
            lst.append(CORBA.demarshal(input_, 'octet'))
        val = ''.join(map(chr, lst))
        return cls(val)
    demarshal = classmethod(demarshal)

    def _get_id(cls):
        return 'IDL:omg.org/GIOP/Principal:1.0'
    corba_id = classmethod(_get_id)

class MsgType_1_1(CORBA.Enum):
    """ Enum IDL:omg.org/GIOP/MsgType_1_1:1.0 """

    _enum_str = dict()
    _enum = dict()

    def _get_id(cls):
        return 'IDL:omg.org/GIOP/MsgType_1_1:1.0'
    corba_id = classmethod(_get_id)

Request = MsgType_1_1('Request', 0)
Reply = MsgType_1_1('Reply', 1)
CancelRequest = MsgType_1_1('CancelRequest', 2)
LocateRequest = MsgType_1_1('LocateRequest', 3)
LocateReply = MsgType_1_1('LocateReply', 4)
CloseConnection = MsgType_1_1('CloseConnection', 5)
MessageError = MsgType_1_1('MessageError', 6)
Fragment = MsgType_1_1('Fragment', 7)

# Typedef: IDL:omg.org/GIOP/MsgType_1_2:1.0
MsgType_1_2 = MsgType_1_1

# Typedef: IDL:omg.org/GIOP/MsgType_1_3:1.0
MsgType_1_3 = MsgType_1_1

class MessageHeader_1_0(object):
    """ Struct IDL:omg.org/GIOP/MessageHeader_1_0:1.0 """

    def __init__(self, magic, GIOP_version, byte_order, message_type, message_size):
        self._setmagic(magic)
        self._setGIOP_version(GIOP_version)
        self._setbyte_order(byte_order)
        self._setmessage_type(message_type)
        self._setmessage_size(message_size)

    def _setmagic(self, magic):
        _e0 = magic
        if len(_e0) != 4:
            raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)
        for _e1 in _e0:
            CORBA.check('char', _e1)
        self._magic = magic

    def _getmagic(self):
        return self._magic

    magic = property(fset=_setmagic, fget=_getmagic)

    def _setGIOP_version(self, GIOP_version):
        CORBA.check(Version, GIOP_version)
        self._GIOP_version = GIOP_version

    def _getGIOP_version(self):
        return self._GIOP_version

    GIOP_version = property(fset=_setGIOP_version, fget=_getGIOP_version)

    def _setbyte_order(self, byte_order):
        CORBA.check('boolean', byte_order)
        self._byte_order = byte_order

    def _getbyte_order(self):
        return self._byte_order

    byte_order = property(fset=_setbyte_order, fget=_getbyte_order)

    def _setmessage_type(self, message_type):
        CORBA.check('octet', message_type)
        self._message_type = message_type

    def _getmessage_type(self):
        return self._message_type

    message_type = property(fset=_setmessage_type, fget=_getmessage_type)

    def _setmessage_size(self, message_size):
        CORBA.check('unsigned_long', message_size)
        self._message_size = message_size

    def _getmessage_size(self):
        return self._message_size

    message_size = property(fset=_setmessage_size, fget=_getmessage_size)

    def marshal(self, output):
            _e0 = self.magic
            for _e1 in _e0:
                CORBA.marshal(output, 'char', _e1)
            self.GIOP_version.marshal(output)
            CORBA.marshal(output, 'boolean', self.byte_order)
            CORBA.marshal(output, 'octet', self.message_type)
            CORBA.marshal(output, 'unsigned_long', self.message_size)

    def demarshal(cls, input_):
            _lst0 = []
            for _i0 in xrange(4):
                _lst0.append(CORBA.demarshal(input_, 'char'))
            _lst0 = ''.join(_lst0)
            magic = _lst0
            GIOP_version = Version.demarshal(input_)
            byte_order = CORBA.demarshal(input_, 'boolean')
            message_type = CORBA.demarshal(input_, 'octet')
            message_size = CORBA.demarshal(input_, 'unsigned_long')
            return cls(magic, GIOP_version, byte_order, message_type, message_size)
    demarshal = classmethod(demarshal)

    def __eq__(self, obj):
        if obj == None:
            return False
        if not isinstance(obj, type(self)):
            return False
        if self.magic != obj.magic:
            return False
        if self.GIOP_version != obj.GIOP_version:
            return False
        if self.byte_order != obj.byte_order:
            return False
        if self.message_type != obj.message_type:
            return False
        if self.message_size != obj.message_size:
            return False
        return True

    def __ne__(self, obj):
        return not self.__eq__(obj)

    def __repr__(self):
        lst = []
        lst.append('char[4] magic=' + repr(self.magic))
        lst.append('Version GIOP_version=' + repr(self.GIOP_version))
        lst.append('boolean byte_order=' + repr(self.byte_order))
        lst.append('octet message_type=' + repr(self.message_type))
        lst.append('unsigned_long message_size=' + repr(self.message_size))
        inner = ',\n'.join(lst)
        inner = '\n'.join(['   ' + line for line in inner.split('\n')])
        return 'struct MessageHeader_1_0 {\n' + inner + '\n}'

    def _get_id(cls):
        return 'IDL:omg.org/GIOP/MessageHeader_1_0:1.0'
    corba_id = classmethod(_get_id)

class MessageHeader_1_1(object):
    """ Struct IDL:omg.org/GIOP/MessageHeader_1_1:1.0 """

    def __init__(self, magic, GIOP_version, flags, message_type, message_size):
        self._setmagic(magic)
        self._setGIOP_version(GIOP_version)
        self._setflags(flags)
        self._setmessage_type(message_type)
        self._setmessage_size(message_size)

    def _setmagic(self, magic):
        _e0 = magic
        if len(_e0) != 4:
            raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)
        for _e1 in _e0:
            CORBA.check('char', _e1)
        self._magic = magic

    def _getmagic(self):
        return self._magic

    magic = property(fset=_setmagic, fget=_getmagic)

    def _setGIOP_version(self, GIOP_version):
        CORBA.check(Version, GIOP_version)
        self._GIOP_version = GIOP_version

    def _getGIOP_version(self):
        return self._GIOP_version

    GIOP_version = property(fset=_setGIOP_version, fget=_getGIOP_version)

    def _setflags(self, flags):
        CORBA.check('octet', flags)
        self._flags = flags

    def _getflags(self):
        return self._flags

    flags = property(fset=_setflags, fget=_getflags)

    def _setmessage_type(self, message_type):
        CORBA.check('octet', message_type)
        self._message_type = message_type

    def _getmessage_type(self):
        return self._message_type

    message_type = property(fset=_setmessage_type, fget=_getmessage_type)

    def _setmessage_size(self, message_size):
        CORBA.check('unsigned_long', message_size)
        self._message_size = message_size

    def _getmessage_size(self):
        return self._message_size

    message_size = property(fset=_setmessage_size, fget=_getmessage_size)

    def marshal(self, output):
            _e0 = self.magic
            for _e1 in _e0:
                CORBA.marshal(output, 'char', _e1)
            self.GIOP_version.marshal(output)
            CORBA.marshal(output, 'octet', self.flags)
            CORBA.marshal(output, 'octet', self.message_type)
            CORBA.marshal(output, 'unsigned_long', self.message_size)

    def demarshal(cls, input_):
            _lst0 = []
            for _i0 in xrange(4):
                _lst0.append(CORBA.demarshal(input_, 'char'))
            _lst0 = ''.join(_lst0)
            magic = _lst0
            GIOP_version = Version.demarshal(input_)
            flags = CORBA.demarshal(input_, 'octet')
            message_type = CORBA.demarshal(input_, 'octet')
            message_size = CORBA.demarshal(input_, 'unsigned_long')
            return cls(magic, GIOP_version, flags, message_type, message_size)
    demarshal = classmethod(demarshal)

    def __eq__(self, obj):
        if obj == None:
            return False
        if not isinstance(obj, type(self)):
            return False
        if self.magic != obj.magic:
            return False
        if self.GIOP_version != obj.GIOP_version:
            return False
        if self.flags != obj.flags:
            return False
        if self.message_type != obj.message_type:
            return False
        if self.message_size != obj.message_size:
            return False
        return True

    def __ne__(self, obj):
        return not self.__eq__(obj)

    def __repr__(self):
        lst = []
        lst.append('char[4] magic=' + repr(self.magic))
        lst.append('Version GIOP_version=' + repr(self.GIOP_version))
        lst.append('octet flags=' + repr(self.flags))
        lst.append('octet message_type=' + repr(self.message_type))
        lst.append('unsigned_long message_size=' + repr(self.message_size))
        inner = ',\n'.join(lst)
        inner = '\n'.join(['   ' + line for line in inner.split('\n')])
        return 'struct MessageHeader_1_1 {\n' + inner + '\n}'

    def _get_id(cls):
        return 'IDL:omg.org/GIOP/MessageHeader_1_1:1.0'
    corba_id = classmethod(_get_id)

class MessageHeader_1_2(MessageHeader_1_1):
    """ Typedef IDL:omg.org/GIOP/MessageHeader_1_2:1.0 """

    def __init__(self, *args, **kwargs):
        if len(args) == 1 and isinstance(args[0], MessageHeader_1_1):
            self.__dict__ = dict(args[0].__dict__)
        else:
            super(MessageHeader_1_2, self).__init__(*args, **kwargs)

    def _get_id(cls):
        return 'IDL:omg.org/GIOP/MessageHeader_1_2:1.0'
    corba_id = classmethod(_get_id)

class MessageHeader_1_3(MessageHeader_1_1):
    """ Typedef IDL:omg.org/GIOP/MessageHeader_1_3:1.0 """

    def __init__(self, *args, **kwargs):
        if len(args) == 1 and isinstance(args[0], MessageHeader_1_1):
            self.__dict__ = dict(args[0].__dict__)
        else:
            super(MessageHeader_1_3, self).__init__(*args, **kwargs)

    def _get_id(cls):
        return 'IDL:omg.org/GIOP/MessageHeader_1_3:1.0'
    corba_id = classmethod(_get_id)

class RequestHeader_1_0(object):
    """ Struct IDL:omg.org/GIOP/RequestHeader_1_0:1.0 """

    def __init__(self, service_context, request_id, response_expected, object_key, operation, requesting_principal):
        self._setservice_context(service_context)
        self._setrequest_id(request_id)
        self._setresponse_expected(response_expected)
        self._setobject_key(object_key)
        self._setoperation(operation)
        self._setrequesting_principal(requesting_principal)

    def _setservice_context(self, service_context):
        CORBA.check(IOP.ServiceContextList, service_context)
        self._service_context = service_context

    def _getservice_context(self):
        return self._service_context

    service_context = property(fset=_setservice_context, fget=_getservice_context)

    def _setrequest_id(self, request_id):
        CORBA.check('unsigned_long', request_id)
        self._request_id = request_id

    def _getrequest_id(self):
        return self._request_id

    request_id = property(fset=_setrequest_id, fget=_getrequest_id)

    def _setresponse_expected(self, response_expected):
        CORBA.check('boolean', response_expected)
        self._response_expected = response_expected

    def _getresponse_expected(self):
        return self._response_expected

    response_expected = property(fset=_setresponse_expected, fget=_getresponse_expected)

    def _setobject_key(self, object_key):
        _e0 = object_key
        CORBA.check('long', len(_e0))
        for _e1 in _e0:
            CORBA.check('octet', ord(_e1))
        self._object_key = object_key

    def _getobject_key(self):
        return self._object_key

    object_key = property(fset=_setobject_key, fget=_getobject_key)

    def _setoperation(self, operation):
        CORBA.check('string', operation)
        self._operation = operation

    def _getoperation(self):
        return self._operation

    operation = property(fset=_setoperation, fget=_getoperation)

    def _setrequesting_principal(self, requesting_principal):
        CORBA.check(Principal, requesting_principal)
        self._requesting_principal = requesting_principal

    def _getrequesting_principal(self):
        return self._requesting_principal

    requesting_principal = property(fset=_setrequesting_principal, fget=_getrequesting_principal)

    def marshal(self, output):
            self.service_context.marshal(output)
            CORBA.marshal(output, 'unsigned_long', self.request_id)
            CORBA.marshal(output, 'boolean', self.response_expected)
            _e0 = self.object_key
            CORBA.marshal(output, 'long', len(_e0))
            for _e1 in _e0:
                CORBA.marshal(output, 'octet', ord(_e1))
            CORBA.marshal(output, 'string', self.operation)
            self.requesting_principal.marshal(output)

    def demarshal(cls, input_):
            service_context = IOP.ServiceContextList.demarshal(input_)
            request_id = CORBA.demarshal(input_, 'unsigned_long')
            response_expected = CORBA.demarshal(input_, 'boolean')
            _len0 = CORBA.demarshal(input_, 'long')
            _lst0 = []
            for _i0 in xrange(_len0):
                _lst0.append(CORBA.demarshal(input_, 'octet'))
            _lst0 = ''.join(map(chr, _lst0))
            object_key = _lst0
            operation = CORBA.demarshal(input_, 'string')
            requesting_principal = Principal.demarshal(input_)
            return cls(service_context, request_id, response_expected, object_key, operation, requesting_principal)
    demarshal = classmethod(demarshal)

    def __eq__(self, obj):
        if obj == None:
            return False
        if not isinstance(obj, type(self)):
            return False
        if self.service_context != obj.service_context:
            return False
        if self.request_id != obj.request_id:
            return False
        if self.response_expected != obj.response_expected:
            return False
        if self.object_key != obj.object_key:
            return False
        if self.operation != obj.operation:
            return False
        if self.requesting_principal != obj.requesting_principal:
            return False
        return True

    def __ne__(self, obj):
        return not self.__eq__(obj)

    def __repr__(self):
        lst = []
        lst.append('ServiceContextList service_context=' + repr(self.service_context))
        lst.append('unsigned_long request_id=' + repr(self.request_id))
        lst.append('boolean response_expected=' + repr(self.response_expected))
        lst.append('octet<> object_key=' + repr(self.object_key))
        lst.append('string operation=' + repr(self.operation))
        lst.append('Principal requesting_principal=' + repr(self.requesting_principal))
        inner = ',\n'.join(lst)
        inner = '\n'.join(['   ' + line for line in inner.split('\n')])
        return 'struct RequestHeader_1_0 {\n' + inner + '\n}'

    def _get_id(cls):
        return 'IDL:omg.org/GIOP/RequestHeader_1_0:1.0'
    corba_id = classmethod(_get_id)

class RequestHeader_1_1(object):
    """ Struct IDL:omg.org/GIOP/RequestHeader_1_1:1.0 """

    def __init__(self, service_context, request_id, response_expected, reserved, object_key, operation, requesting_principal):
        self._setservice_context(service_context)
        self._setrequest_id(request_id)
        self._setresponse_expected(response_expected)
        self._setreserved(reserved)
        self._setobject_key(object_key)
        self._setoperation(operation)
        self._setrequesting_principal(requesting_principal)

    def _setservice_context(self, service_context):
        CORBA.check(IOP.ServiceContextList, service_context)
        self._service_context = service_context

    def _getservice_context(self):
        return self._service_context

    service_context = property(fset=_setservice_context, fget=_getservice_context)

    def _setrequest_id(self, request_id):
        CORBA.check('unsigned_long', request_id)
        self._request_id = request_id

    def _getrequest_id(self):
        return self._request_id

    request_id = property(fset=_setrequest_id, fget=_getrequest_id)

    def _setresponse_expected(self, response_expected):
        CORBA.check('boolean', response_expected)
        self._response_expected = response_expected

    def _getresponse_expected(self):
        return self._response_expected

    response_expected = property(fset=_setresponse_expected, fget=_getresponse_expected)

    def _setreserved(self, reserved):
        _e0 = reserved
        if len(_e0) != 3:
            raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)
        for _e1 in _e0:
            CORBA.check('octet', ord(_e1))
        self._reserved = reserved

    def _getreserved(self):
        return self._reserved

    reserved = property(fset=_setreserved, fget=_getreserved)

    def _setobject_key(self, object_key):
        _e0 = object_key
        CORBA.check('long', len(_e0))
        for _e1 in _e0:
            CORBA.check('octet', ord(_e1))
        self._object_key = object_key

    def _getobject_key(self):
        return self._object_key

    object_key = property(fset=_setobject_key, fget=_getobject_key)

    def _setoperation(self, operation):
        CORBA.check('string', operation)
        self._operation = operation

    def _getoperation(self):
        return self._operation

    operation = property(fset=_setoperation, fget=_getoperation)

    def _setrequesting_principal(self, requesting_principal):
        CORBA.check(Principal, requesting_principal)
        self._requesting_principal = requesting_principal

    def _getrequesting_principal(self):
        return self._requesting_principal

    requesting_principal = property(fset=_setrequesting_principal, fget=_getrequesting_principal)

    def marshal(self, output):
            self.service_context.marshal(output)
            CORBA.marshal(output, 'unsigned_long', self.request_id)
            CORBA.marshal(output, 'boolean', self.response_expected)
            _e0 = self.reserved
            for _e1 in _e0:
                CORBA.marshal(output, 'octet', ord(_e1))
            _e0 = self.object_key
            CORBA.marshal(output, 'long', len(_e0))
            for _e1 in _e0:
                CORBA.marshal(output, 'octet', ord(_e1))
            CORBA.marshal(output, 'string', self.operation)
            self.requesting_principal.marshal(output)

    def demarshal(cls, input_):
            service_context = IOP.ServiceContextList.demarshal(input_)
            request_id = CORBA.demarshal(input_, 'unsigned_long')
            response_expected = CORBA.demarshal(input_, 'boolean')
            _lst0 = []
            for _i0 in xrange(3):
                _lst0.append(CORBA.demarshal(input_, 'octet'))
            _lst0 = ''.join(map(chr, _lst0))
            reserved = _lst0
            _len0 = CORBA.demarshal(input_, 'long')
            _lst0 = []
            for _i0 in xrange(_len0):
                _lst0.append(CORBA.demarshal(input_, 'octet'))
            _lst0 = ''.join(map(chr, _lst0))
            object_key = _lst0
            operation = CORBA.demarshal(input_, 'string')
            requesting_principal = Principal.demarshal(input_)
            return cls(service_context, request_id, response_expected, reserved, object_key, operation, requesting_principal)
    demarshal = classmethod(demarshal)

    def __eq__(self, obj):
        if obj == None:
            return False
        if not isinstance(obj, type(self)):
            return False
        if self.service_context != obj.service_context:
            return False
        if self.request_id != obj.request_id:
            return False
        if self.response_expected != obj.response_expected:
            return False
        if self.reserved != obj.reserved:
            return False
        if self.object_key != obj.object_key:
            return False
        if self.operation != obj.operation:
            return False
        if self.requesting_principal != obj.requesting_principal:
            return False
        return True

    def __ne__(self, obj):
        return not self.__eq__(obj)

    def __repr__(self):
        lst = []
        lst.append('ServiceContextList service_context=' + repr(self.service_context))
        lst.append('unsigned_long request_id=' + repr(self.request_id))
        lst.append('boolean response_expected=' + repr(self.response_expected))
        lst.append('octet[3] reserved=' + repr(self.reserved))
        lst.append('octet<> object_key=' + repr(self.object_key))
        lst.append('string operation=' + repr(self.operation))
        lst.append('Principal requesting_principal=' + repr(self.requesting_principal))
        inner = ',\n'.join(lst)
        inner = '\n'.join(['   ' + line for line in inner.split('\n')])
        return 'struct RequestHeader_1_1 {\n' + inner + '\n}'

    def _get_id(cls):
        return 'IDL:omg.org/GIOP/RequestHeader_1_1:1.0'
    corba_id = classmethod(_get_id)

class AddressingDisposition(int):
    """ Typedef IDL:omg.org/GIOP/AddressingDisposition:1.0 """

    def __init__(self, val):
        CORBA.check('short', val)
        int.__init__(val)

    def marshal(self, output):
        CORBA.marshal(output, 'short', self)

    def demarshal(cls, input_):
        val = CORBA.demarshal(input_, 'short')
        return cls(val)
    demarshal = classmethod(demarshal)

    def _get_id(cls):
        return 'IDL:omg.org/GIOP/AddressingDisposition:1.0'
    corba_id = classmethod(_get_id)

# Constant: IDL:omg.org/GIOP/KeyAddr:1.0
KeyAddr = 0

# Constant: IDL:omg.org/GIOP/ProfileAddr:1.0
ProfileAddr = 1

# Constant: IDL:omg.org/GIOP/ReferenceAddr:1.0
ReferenceAddr = 2

class IORAddressingInfo(object):
    """ Struct IDL:omg.org/GIOP/IORAddressingInfo:1.0 """

    class IOR(object):
        """ Struct IDL:omg.org/IOP/IOR:1.0 """

        def __init__(self, type_id, profiles):
            self._settype_id(type_id)
            self._setprofiles(profiles)

        def _settype_id(self, type_id):
            CORBA.check('string', type_id)
            self._type_id = type_id

        def _gettype_id(self):
            return self._type_id

        type_id = property(fset=_settype_id, fget=_gettype_id)

        def _setprofiles(self, profiles):
            _e0 = profiles
            CORBA.check('long', len(_e0))
            for _e1 in _e0:
                CORBA.check(TaggedProfile, _e1)
            self._profiles = profiles

        def _getprofiles(self):
            return self._profiles

        profiles = property(fset=_setprofiles, fget=_getprofiles)

        def marshal(self, output):
                CORBA.marshal(output, 'string', self.type_id)
                _e0 = self.profiles
                CORBA.marshal(output, 'long', len(_e0))
                for _e1 in _e0:
                    _e1.marshal(output)

        def demarshal(cls, input_):
                type_id = CORBA.demarshal(input_, 'string')
                _len0 = CORBA.demarshal(input_, 'long')
                _lst0 = []
                for _i0 in xrange(_len0):
                    _lst0.append(TaggedProfile.demarshal(input_))
                profiles = _lst0
                return cls(type_id, profiles)
        demarshal = classmethod(demarshal)

        def __eq__(self, obj):
            if obj == None:
                return False
            if not isinstance(obj, type(self)):
                return False
            if self.type_id != obj.type_id:
                return False
            if self.profiles != obj.profiles:
                return False
            return True

        def __ne__(self, obj):
            return not self.__eq__(obj)

        def __repr__(self):
            lst = []
            lst.append('string type_id=' + repr(self.type_id))
            lst.append('TaggedProfile<> profiles=' + repr(self.profiles))
            inner = ',\n'.join(lst)
            inner = '\n'.join(['   ' + line for line in inner.split('\n')])
            return 'struct IOR {\n' + inner + '\n}'

        def _get_id(cls):
            return 'IDL:omg.org/IOP/IOR:1.0'
        corba_id = classmethod(_get_id)

    def __init__(self, selected_profile_index, ior):
        self._setselected_profile_index(selected_profile_index)
        self._setior(ior)

    def _setselected_profile_index(self, selected_profile_index):
        CORBA.check('unsigned_long', selected_profile_index)
        self._selected_profile_index = selected_profile_index

    def _getselected_profile_index(self):
        return self._selected_profile_index

    selected_profile_index = property(fset=_setselected_profile_index, fget=_getselected_profile_index)

    def _setior(self, ior):
        CORBA.check(IOP.IOR, ior)
        self._ior = ior

    def _getior(self):
        return self._ior

    ior = property(fset=_setior, fget=_getior)

    def marshal(self, output):
            CORBA.marshal(output, 'unsigned_long', self.selected_profile_index)
            self.ior.marshal(output)

    def demarshal(cls, input_):
            selected_profile_index = CORBA.demarshal(input_, 'unsigned_long')
            ior = IOP.IOR.demarshal(input_)
            return cls(selected_profile_index, ior)
    demarshal = classmethod(demarshal)

    def __eq__(self, obj):
        if obj == None:
            return False
        if not isinstance(obj, type(self)):
            return False
        if self.selected_profile_index != obj.selected_profile_index:
            return False
        if self.ior != obj.ior:
            return False
        return True

    def __ne__(self, obj):
        return not self.__eq__(obj)

    def __repr__(self):
        lst = []
        lst.append('unsigned_long selected_profile_index=' + repr(self.selected_profile_index))
        lst.append('IOR ior=' + repr(self.ior))
        inner = ',\n'.join(lst)
        inner = '\n'.join(['   ' + line for line in inner.split('\n')])
        return 'struct IORAddressingInfo {\n' + inner + '\n}'

    def _get_id(cls):
        return 'IDL:omg.org/GIOP/IORAddressingInfo:1.0'
    corba_id = classmethod(_get_id)

class TargetAddress(object):
    """ Union IDL:omg.org/GIOP/TargetAddress:1.0 """

    class TaggedProfile(object):
        """ Struct IDL:omg.org/IOP/TaggedProfile:1.0 """

        def __init__(self, tag, profile_data):
            self._settag(tag)
            self._setprofile_data(profile_data)

        def _settag(self, tag):
            CORBA.check(ProfileId, tag)
            self._tag = tag

        def _gettag(self):
            return self._tag

        tag = property(fset=_settag, fget=_gettag)

        def _setprofile_data(self, profile_data):
            _e0 = profile_data
            CORBA.check('long', len(_e0))
            for _e1 in _e0:
                CORBA.check('octet', ord(_e1))
            self._profile_data = profile_data

        def _getprofile_data(self):
            return self._profile_data

        profile_data = property(fset=_setprofile_data, fget=_getprofile_data)

        def marshal(self, output):
                self.tag.marshal(output)
                _e0 = self.profile_data
                CORBA.marshal(output, 'long', len(_e0))
                for _e1 in _e0:
                    CORBA.marshal(output, 'octet', ord(_e1))

        def demarshal(cls, input_):
                tag = ProfileId.demarshal(input_)
                _len0 = CORBA.demarshal(input_, 'long')
                _lst0 = []
                for _i0 in xrange(_len0):
                    _lst0.append(CORBA.demarshal(input_, 'octet'))
                _lst0 = ''.join(map(chr, _lst0))
                profile_data = _lst0
                return cls(tag, profile_data)
        demarshal = classmethod(demarshal)

        def __eq__(self, obj):
            if obj == None:
                return False
            if not isinstance(obj, type(self)):
                return False
            if self.tag != obj.tag:
                return False
            if self.profile_data != obj.profile_data:
                return False
            return True

        def __ne__(self, obj):
            return not self.__eq__(obj)

        def __repr__(self):
            lst = []
            lst.append('ProfileId tag=' + repr(self.tag))
            lst.append('octet<> profile_data=' + repr(self.profile_data))
            inner = ',\n'.join(lst)
            inner = '\n'.join(['   ' + line for line in inner.split('\n')])
            return 'struct TaggedProfile {\n' + inner + '\n}'

        def _get_id(cls):
            return 'IDL:omg.org/IOP/TaggedProfile:1.0'
        corba_id = classmethod(_get_id)

    def __init__(self, *args, **kwargs):
        if len(args) == 2:
            _d, _v = args
            CORBA.check(AddressingDisposition, _d)
            if _d == AddressingDisposition(KeyAddr):
                _e0 = _v
                CORBA.check('long', len(_e0))
                for _e1 in _e0:
                    CORBA.check('octet', ord(_e1))
            elif _d == AddressingDisposition(ProfileAddr):
                CORBA.check(IOP.TaggedProfile, _v)
            elif _d == AddressingDisposition(ReferenceAddr):
                CORBA.check(IORAddressingInfo, _v)
            else:
                raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)
            self.__d = _d
            self.__v = _v
        elif 'object_key' in kwargs:
            self._setobject_key(kwargs['object_key'])
        elif 'profile' in kwargs:
            self._setprofile(kwargs['profile'])
        elif 'ior' in kwargs:
            self._setior(kwargs['ior'])
        else:
            raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)

    def _get_d(self):
        return self.__d

    _d = property(fget=_get_d)

    def _get_v(self):
        if self.__d == AddressingDisposition(KeyAddr):
            return self.__v
        elif self.__d == AddressingDisposition(ProfileAddr):
            return self.__v
        elif self.__d == AddressingDisposition(ReferenceAddr):
            return self.__v
        else:
            return None

    _v = property(fget=_get_v)

    def _setobject_key(self, object_key):
        _e0 = object_key
        CORBA.check('long', len(_e0))
        for _e1 in _e0:
            CORBA.check('octet', ord(_e1))
        self.__d = AddressingDisposition(KeyAddr)
        self.__v = object_key

    def _getobject_key(self):
        if self.__d == AddressingDisposition(KeyAddr):
            return self.__v
        return None

    object_key = property(fset=_setobject_key, fget=_getobject_key)

    def _setprofile(self, profile):
        CORBA.check(IOP.TaggedProfile, profile)
        self.__d = AddressingDisposition(ProfileAddr)
        self.__v = profile

    def _getprofile(self):
        if self.__d == AddressingDisposition(ProfileAddr):
            return self.__v
        return None

    profile = property(fset=_setprofile, fget=_getprofile)

    def _setior(self, ior):
        CORBA.check(IORAddressingInfo, ior)
        self.__d = AddressingDisposition(ReferenceAddr)
        self.__v = ior

    def _getior(self):
        if self.__d == AddressingDisposition(ReferenceAddr):
            return self.__v
        return None

    ior = property(fset=_setior, fget=_getior)

    def marshal(self, output):
        self._d.marshal(output)
        if self._d == AddressingDisposition(KeyAddr):
            _e0 = self.__v
            CORBA.marshal(output, 'long', len(_e0))
            for _e1 in _e0:
                CORBA.marshal(output, 'octet', ord(_e1))
        elif self._d == AddressingDisposition(ProfileAddr):
            self.__v.marshal(output)
        elif self._d == AddressingDisposition(ReferenceAddr):
            self.__v.marshal(output)
        else:
            raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)

    def demarshal(cls, input_):
        _d = AddressingDisposition.demarshal(input_)
        if _d == AddressingDisposition(KeyAddr):
            _len0 = CORBA.demarshal(input_, 'long')
            _lst0 = []
            for _i0 in xrange(_len0):
                _lst0.append(CORBA.demarshal(input_, 'octet'))
            _lst0 = ''.join(map(chr, _lst0))
            object_key = _lst0
            return cls(_d, object_key)
        elif _d == AddressingDisposition(ProfileAddr):
            profile = IOP.TaggedProfile.demarshal(input_)
            return cls(_d, profile)
        elif _d == AddressingDisposition(ReferenceAddr):
            ior = IORAddressingInfo.demarshal(input_)
            return cls(_d, ior)
        else:
            raise CORBA.SystemException('IDL:CORBA/MARSHAL:1.0', 9, CORBA.CORBA_COMPLETED_MAYBE)
    demarshal = classmethod(demarshal)

    def __eq__(self, obj):
        if obj == None:
            return False
        if isinstance(obj, type(self)):
            if self._d == obj._d:
                return self._v == obj._v
            else:
                return False
        else:
            return False

    def __ne__(self, obj):
        return not self.__eq__(obj)

    def __repr__(self):
        lst = []
        lst.append('_d=' + repr(self._d))
        lst.append('_v=' + repr(self._v))
        inner = ',\n'.join(lst)
        inner = '\n'.join(['   ' + line for line in inner.split('\n')])
        return 'union TargetAddress {\n' + inner + '\n}'

    def _get_id(cls):
        return 'IDL:omg.org/GIOP/TargetAddress:1.0'
    corba_id = classmethod(_get_id)

class RequestHeader_1_2(object):
    """ Struct IDL:omg.org/GIOP/RequestHeader_1_2:1.0 """

    def __init__(self, request_id, response_flags, reserved, target, operation, service_context):
        self._setrequest_id(request_id)
        self._setresponse_flags(response_flags)
        self._setreserved(reserved)
        self._settarget(target)
        self._setoperation(operation)
        self._setservice_context(service_context)

    def _setrequest_id(self, request_id):
        CORBA.check('unsigned_long', request_id)
        self._request_id = request_id

    def _getrequest_id(self):
        return self._request_id

    request_id = property(fset=_setrequest_id, fget=_getrequest_id)

    def _setresponse_flags(self, response_flags):
        CORBA.check('octet', response_flags)
        self._response_flags = response_flags

    def _getresponse_flags(self):
        return self._response_flags

    response_flags = property(fset=_setresponse_flags, fget=_getresponse_flags)

    def _setreserved(self, reserved):
        _e0 = reserved
        if len(_e0) != 3:
            raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)
        for _e1 in _e0:
            CORBA.check('octet', ord(_e1))
        self._reserved = reserved

    def _getreserved(self):
        return self._reserved

    reserved = property(fset=_setreserved, fget=_getreserved)

    def _settarget(self, target):
        CORBA.check(TargetAddress, target)
        self._target = target

    def _gettarget(self):
        return self._target

    target = property(fset=_settarget, fget=_gettarget)

    def _setoperation(self, operation):
        CORBA.check('string', operation)
        self._operation = operation

    def _getoperation(self):
        return self._operation

    operation = property(fset=_setoperation, fget=_getoperation)

    def _setservice_context(self, service_context):
        CORBA.check(IOP.ServiceContextList, service_context)
        self._service_context = service_context

    def _getservice_context(self):
        return self._service_context

    service_context = property(fset=_setservice_context, fget=_getservice_context)

    def marshal(self, output):
            CORBA.marshal(output, 'unsigned_long', self.request_id)
            CORBA.marshal(output, 'octet', self.response_flags)
            _e0 = self.reserved
            for _e1 in _e0:
                CORBA.marshal(output, 'octet', ord(_e1))
            self.target.marshal(output)
            CORBA.marshal(output, 'string', self.operation)
            self.service_context.marshal(output)

    def demarshal(cls, input_):
            request_id = CORBA.demarshal(input_, 'unsigned_long')
            response_flags = CORBA.demarshal(input_, 'octet')
            _lst0 = []
            for _i0 in xrange(3):
                _lst0.append(CORBA.demarshal(input_, 'octet'))
            _lst0 = ''.join(map(chr, _lst0))
            reserved = _lst0
            target = TargetAddress.demarshal(input_)
            operation = CORBA.demarshal(input_, 'string')
            service_context = IOP.ServiceContextList.demarshal(input_)
            return cls(request_id, response_flags, reserved, target, operation, service_context)
    demarshal = classmethod(demarshal)

    def __eq__(self, obj):
        if obj == None:
            return False
        if not isinstance(obj, type(self)):
            return False
        if self.request_id != obj.request_id:
            return False
        if self.response_flags != obj.response_flags:
            return False
        if self.reserved != obj.reserved:
            return False
        if self.target != obj.target:
            return False
        if self.operation != obj.operation:
            return False
        if self.service_context != obj.service_context:
            return False
        return True

    def __ne__(self, obj):
        return not self.__eq__(obj)

    def __repr__(self):
        lst = []
        lst.append('unsigned_long request_id=' + repr(self.request_id))
        lst.append('octet response_flags=' + repr(self.response_flags))
        lst.append('octet[3] reserved=' + repr(self.reserved))
        lst.append('TargetAddress target=' + repr(self.target))
        lst.append('string operation=' + repr(self.operation))
        lst.append('ServiceContextList service_context=' + repr(self.service_context))
        inner = ',\n'.join(lst)
        inner = '\n'.join(['   ' + line for line in inner.split('\n')])
        return 'struct RequestHeader_1_2 {\n' + inner + '\n}'

    def _get_id(cls):
        return 'IDL:omg.org/GIOP/RequestHeader_1_2:1.0'
    corba_id = classmethod(_get_id)

class RequestHeader_1_3(RequestHeader_1_2):
    """ Typedef IDL:omg.org/GIOP/RequestHeader_1_3:1.0 """

    def __init__(self, *args, **kwargs):
        if len(args) == 1 and isinstance(args[0], RequestHeader_1_2):
            self.__dict__ = dict(args[0].__dict__)
        else:
            super(RequestHeader_1_3, self).__init__(*args, **kwargs)

    def _get_id(cls):
        return 'IDL:omg.org/GIOP/RequestHeader_1_3:1.0'
    corba_id = classmethod(_get_id)

class ReplyStatusType_1_2(CORBA.Enum):
    """ Enum IDL:omg.org/GIOP/ReplyStatusType_1_2:1.0 """

    _enum_str = dict()
    _enum = dict()

    def _get_id(cls):
        return 'IDL:omg.org/GIOP/ReplyStatusType_1_2:1.0'
    corba_id = classmethod(_get_id)

NO_EXCEPTION = ReplyStatusType_1_2('NO_EXCEPTION', 0)
USER_EXCEPTION = ReplyStatusType_1_2('USER_EXCEPTION', 1)
SYSTEM_EXCEPTION = ReplyStatusType_1_2('SYSTEM_EXCEPTION', 2)
LOCATION_FORWARD = ReplyStatusType_1_2('LOCATION_FORWARD', 3)
LOCATION_FORWARD_PERM = ReplyStatusType_1_2('LOCATION_FORWARD_PERM', 4)
NEEDS_ADDRESSING_MODE = ReplyStatusType_1_2('NEEDS_ADDRESSING_MODE', 5)

class ReplyHeader_1_2(object):
    """ Struct IDL:omg.org/GIOP/ReplyHeader_1_2:1.0 """

    def __init__(self, request_id, reply_status, service_context):
        self._setrequest_id(request_id)
        self._setreply_status(reply_status)
        self._setservice_context(service_context)

    def _setrequest_id(self, request_id):
        CORBA.check('unsigned_long', request_id)
        self._request_id = request_id

    def _getrequest_id(self):
        return self._request_id

    request_id = property(fset=_setrequest_id, fget=_getrequest_id)

    def _setreply_status(self, reply_status):
        CORBA.check(ReplyStatusType_1_2, reply_status)
        self._reply_status = reply_status

    def _getreply_status(self):
        return self._reply_status

    reply_status = property(fset=_setreply_status, fget=_getreply_status)

    def _setservice_context(self, service_context):
        CORBA.check(IOP.ServiceContextList, service_context)
        self._service_context = service_context

    def _getservice_context(self):
        return self._service_context

    service_context = property(fset=_setservice_context, fget=_getservice_context)

    def marshal(self, output):
            CORBA.marshal(output, 'unsigned_long', self.request_id)
            self.reply_status.marshal(output)
            self.service_context.marshal(output)

    def demarshal(cls, input_):
            request_id = CORBA.demarshal(input_, 'unsigned_long')
            reply_status = ReplyStatusType_1_2.demarshal(input_)
            service_context = IOP.ServiceContextList.demarshal(input_)
            return cls(request_id, reply_status, service_context)
    demarshal = classmethod(demarshal)

    def __eq__(self, obj):
        if obj == None:
            return False
        if not isinstance(obj, type(self)):
            return False
        if self.request_id != obj.request_id:
            return False
        if self.reply_status != obj.reply_status:
            return False
        if self.service_context != obj.service_context:
            return False
        return True

    def __ne__(self, obj):
        return not self.__eq__(obj)

    def __repr__(self):
        lst = []
        lst.append('unsigned_long request_id=' + repr(self.request_id))
        lst.append('ReplyStatusType_1_2 reply_status=' + repr(self.reply_status))
        lst.append('ServiceContextList service_context=' + repr(self.service_context))
        inner = ',\n'.join(lst)
        inner = '\n'.join(['   ' + line for line in inner.split('\n')])
        return 'struct ReplyHeader_1_2 {\n' + inner + '\n}'

    def _get_id(cls):
        return 'IDL:omg.org/GIOP/ReplyHeader_1_2:1.0'
    corba_id = classmethod(_get_id)

class ReplyHeader_1_3(ReplyHeader_1_2):
    """ Typedef IDL:omg.org/GIOP/ReplyHeader_1_3:1.0 """

    def __init__(self, *args, **kwargs):
        if len(args) == 1 and isinstance(args[0], ReplyHeader_1_2):
            self.__dict__ = dict(args[0].__dict__)
        else:
            super(ReplyHeader_1_3, self).__init__(*args, **kwargs)

    def _get_id(cls):
        return 'IDL:omg.org/GIOP/ReplyHeader_1_3:1.0'
    corba_id = classmethod(_get_id)

class SystemExceptionReplyBody(object):
    """ Struct IDL:omg.org/GIOP/SystemExceptionReplyBody:1.0 """

    def __init__(self, exception_id, minor_code_value, completion_status):
        self._setexception_id(exception_id)
        self._setminor_code_value(minor_code_value)
        self._setcompletion_status(completion_status)

    def _setexception_id(self, exception_id):
        CORBA.check('string', exception_id)
        self._exception_id = exception_id

    def _getexception_id(self):
        return self._exception_id

    exception_id = property(fset=_setexception_id, fget=_getexception_id)

    def _setminor_code_value(self, minor_code_value):
        CORBA.check('unsigned_long', minor_code_value)
        self._minor_code_value = minor_code_value

    def _getminor_code_value(self):
        return self._minor_code_value

    minor_code_value = property(fset=_setminor_code_value, fget=_getminor_code_value)

    def _setcompletion_status(self, completion_status):
        CORBA.check('unsigned_long', completion_status)
        self._completion_status = completion_status

    def _getcompletion_status(self):
        return self._completion_status

    completion_status = property(fset=_setcompletion_status, fget=_getcompletion_status)

    def marshal(self, output):
            CORBA.marshal(output, 'string', self.exception_id)
            CORBA.marshal(output, 'unsigned_long', self.minor_code_value)
            CORBA.marshal(output, 'unsigned_long', self.completion_status)

    def demarshal(cls, input_):
            exception_id = CORBA.demarshal(input_, 'string')
            minor_code_value = CORBA.demarshal(input_, 'unsigned_long')
            completion_status = CORBA.demarshal(input_, 'unsigned_long')
            return cls(exception_id, minor_code_value, completion_status)
    demarshal = classmethod(demarshal)

    def __eq__(self, obj):
        if obj == None:
            return False
        if not isinstance(obj, type(self)):
            return False
        if self.exception_id != obj.exception_id:
            return False
        if self.minor_code_value != obj.minor_code_value:
            return False
        if self.completion_status != obj.completion_status:
            return False
        return True

    def __ne__(self, obj):
        return not self.__eq__(obj)

    def __repr__(self):
        lst = []
        lst.append('string exception_id=' + repr(self.exception_id))
        lst.append('unsigned_long minor_code_value=' + repr(self.minor_code_value))
        lst.append('unsigned_long completion_status=' + repr(self.completion_status))
        inner = ',\n'.join(lst)
        inner = '\n'.join(['   ' + line for line in inner.split('\n')])
        return 'struct SystemExceptionReplyBody {\n' + inner + '\n}'

    def _get_id(cls):
        return 'IDL:omg.org/GIOP/SystemExceptionReplyBody:1.0'
    corba_id = classmethod(_get_id)

class CancelRequestHeader(object):
    """ Struct IDL:omg.org/GIOP/CancelRequestHeader:1.0 """

    def __init__(self, request_id):
        self._setrequest_id(request_id)

    def _setrequest_id(self, request_id):
        CORBA.check('unsigned_long', request_id)
        self._request_id = request_id

    def _getrequest_id(self):
        return self._request_id

    request_id = property(fset=_setrequest_id, fget=_getrequest_id)

    def marshal(self, output):
            CORBA.marshal(output, 'unsigned_long', self.request_id)

    def demarshal(cls, input_):
            request_id = CORBA.demarshal(input_, 'unsigned_long')
            return cls(request_id)
    demarshal = classmethod(demarshal)

    def __eq__(self, obj):
        if obj == None:
            return False
        if not isinstance(obj, type(self)):
            return False
        if self.request_id != obj.request_id:
            return False
        return True

    def __ne__(self, obj):
        return not self.__eq__(obj)

    def __repr__(self):
        lst = []
        lst.append('unsigned_long request_id=' + repr(self.request_id))
        inner = ',\n'.join(lst)
        inner = '\n'.join(['   ' + line for line in inner.split('\n')])
        return 'struct CancelRequestHeader {\n' + inner + '\n}'

    def _get_id(cls):
        return 'IDL:omg.org/GIOP/CancelRequestHeader:1.0'
    corba_id = classmethod(_get_id)

class LocateRequestHeader_1_0(object):
    """ Struct IDL:omg.org/GIOP/LocateRequestHeader_1_0:1.0 """

    def __init__(self, request_id, object_key):
        self._setrequest_id(request_id)
        self._setobject_key(object_key)

    def _setrequest_id(self, request_id):
        CORBA.check('unsigned_long', request_id)
        self._request_id = request_id

    def _getrequest_id(self):
        return self._request_id

    request_id = property(fset=_setrequest_id, fget=_getrequest_id)

    def _setobject_key(self, object_key):
        _e0 = object_key
        CORBA.check('long', len(_e0))
        for _e1 in _e0:
            CORBA.check('octet', ord(_e1))
        self._object_key = object_key

    def _getobject_key(self):
        return self._object_key

    object_key = property(fset=_setobject_key, fget=_getobject_key)

    def marshal(self, output):
            CORBA.marshal(output, 'unsigned_long', self.request_id)
            _e0 = self.object_key
            CORBA.marshal(output, 'long', len(_e0))
            for _e1 in _e0:
                CORBA.marshal(output, 'octet', ord(_e1))

    def demarshal(cls, input_):
            request_id = CORBA.demarshal(input_, 'unsigned_long')
            _len0 = CORBA.demarshal(input_, 'long')
            _lst0 = []
            for _i0 in xrange(_len0):
                _lst0.append(CORBA.demarshal(input_, 'octet'))
            _lst0 = ''.join(map(chr, _lst0))
            object_key = _lst0
            return cls(request_id, object_key)
    demarshal = classmethod(demarshal)

    def __eq__(self, obj):
        if obj == None:
            return False
        if not isinstance(obj, type(self)):
            return False
        if self.request_id != obj.request_id:
            return False
        if self.object_key != obj.object_key:
            return False
        return True

    def __ne__(self, obj):
        return not self.__eq__(obj)

    def __repr__(self):
        lst = []
        lst.append('unsigned_long request_id=' + repr(self.request_id))
        lst.append('octet<> object_key=' + repr(self.object_key))
        inner = ',\n'.join(lst)
        inner = '\n'.join(['   ' + line for line in inner.split('\n')])
        return 'struct LocateRequestHeader_1_0 {\n' + inner + '\n}'

    def _get_id(cls):
        return 'IDL:omg.org/GIOP/LocateRequestHeader_1_0:1.0'
    corba_id = classmethod(_get_id)

class LocateRequestHeader_1_1(LocateRequestHeader_1_0):
    """ Typedef IDL:omg.org/GIOP/LocateRequestHeader_1_1:1.0 """

    def __init__(self, *args, **kwargs):
        if len(args) == 1 and isinstance(args[0], LocateRequestHeader_1_0):
            self.__dict__ = dict(args[0].__dict__)
        else:
            super(LocateRequestHeader_1_1, self).__init__(*args, **kwargs)

    def _get_id(cls):
        return 'IDL:omg.org/GIOP/LocateRequestHeader_1_1:1.0'
    corba_id = classmethod(_get_id)

class LocateRequestHeader_1_2(object):
    """ Struct IDL:omg.org/GIOP/LocateRequestHeader_1_2:1.0 """

    def __init__(self, request_id, target):
        self._setrequest_id(request_id)
        self._settarget(target)

    def _setrequest_id(self, request_id):
        CORBA.check('unsigned_long', request_id)
        self._request_id = request_id

    def _getrequest_id(self):
        return self._request_id

    request_id = property(fset=_setrequest_id, fget=_getrequest_id)

    def _settarget(self, target):
        CORBA.check(TargetAddress, target)
        self._target = target

    def _gettarget(self):
        return self._target

    target = property(fset=_settarget, fget=_gettarget)

    def marshal(self, output):
            CORBA.marshal(output, 'unsigned_long', self.request_id)
            self.target.marshal(output)

    def demarshal(cls, input_):
            request_id = CORBA.demarshal(input_, 'unsigned_long')
            target = TargetAddress.demarshal(input_)
            return cls(request_id, target)
    demarshal = classmethod(demarshal)

    def __eq__(self, obj):
        if obj == None:
            return False
        if not isinstance(obj, type(self)):
            return False
        if self.request_id != obj.request_id:
            return False
        if self.target != obj.target:
            return False
        return True

    def __ne__(self, obj):
        return not self.__eq__(obj)

    def __repr__(self):
        lst = []
        lst.append('unsigned_long request_id=' + repr(self.request_id))
        lst.append('TargetAddress target=' + repr(self.target))
        inner = ',\n'.join(lst)
        inner = '\n'.join(['   ' + line for line in inner.split('\n')])
        return 'struct LocateRequestHeader_1_2 {\n' + inner + '\n}'

    def _get_id(cls):
        return 'IDL:omg.org/GIOP/LocateRequestHeader_1_2:1.0'
    corba_id = classmethod(_get_id)

class LocateRequestHeader_1_3(LocateRequestHeader_1_2):
    """ Typedef IDL:omg.org/GIOP/LocateRequestHeader_1_3:1.0 """

    def __init__(self, *args, **kwargs):
        if len(args) == 1 and isinstance(args[0], LocateRequestHeader_1_2):
            self.__dict__ = dict(args[0].__dict__)
        else:
            super(LocateRequestHeader_1_3, self).__init__(*args, **kwargs)

    def _get_id(cls):
        return 'IDL:omg.org/GIOP/LocateRequestHeader_1_3:1.0'
    corba_id = classmethod(_get_id)

class LocateStatusType_1_2(CORBA.Enum):
    """ Enum IDL:omg.org/GIOP/LocateStatusType_1_2:1.0 """

    _enum_str = dict()
    _enum = dict()

    def _get_id(cls):
        return 'IDL:omg.org/GIOP/LocateStatusType_1_2:1.0'
    corba_id = classmethod(_get_id)

UNKNOWN_OBJECT = LocateStatusType_1_2('UNKNOWN_OBJECT', 0)
OBJECT_HERE = LocateStatusType_1_2('OBJECT_HERE', 1)
OBJECT_FORWARD = LocateStatusType_1_2('OBJECT_FORWARD', 2)
OBJECT_FORWARD_PERM = LocateStatusType_1_2('OBJECT_FORWARD_PERM', 3)
LOC_SYSTEM_EXCEPTION = LocateStatusType_1_2('LOC_SYSTEM_EXCEPTION', 4)
LOC_NEEDS_ADDRESSING_MODE = LocateStatusType_1_2('LOC_NEEDS_ADDRESSING_MODE', 5)

class LocateReplyHeader_1_2(object):
    """ Struct IDL:omg.org/GIOP/LocateReplyHeader_1_2:1.0 """

    def __init__(self, request_id, locate_status):
        self._setrequest_id(request_id)
        self._setlocate_status(locate_status)

    def _setrequest_id(self, request_id):
        CORBA.check('unsigned_long', request_id)
        self._request_id = request_id

    def _getrequest_id(self):
        return self._request_id

    request_id = property(fset=_setrequest_id, fget=_getrequest_id)

    def _setlocate_status(self, locate_status):
        CORBA.check(LocateStatusType_1_2, locate_status)
        self._locate_status = locate_status

    def _getlocate_status(self):
        return self._locate_status

    locate_status = property(fset=_setlocate_status, fget=_getlocate_status)

    def marshal(self, output):
            CORBA.marshal(output, 'unsigned_long', self.request_id)
            self.locate_status.marshal(output)

    def demarshal(cls, input_):
            request_id = CORBA.demarshal(input_, 'unsigned_long')
            locate_status = LocateStatusType_1_2.demarshal(input_)
            return cls(request_id, locate_status)
    demarshal = classmethod(demarshal)

    def __eq__(self, obj):
        if obj == None:
            return False
        if not isinstance(obj, type(self)):
            return False
        if self.request_id != obj.request_id:
            return False
        if self.locate_status != obj.locate_status:
            return False
        return True

    def __ne__(self, obj):
        return not self.__eq__(obj)

    def __repr__(self):
        lst = []
        lst.append('unsigned_long request_id=' + repr(self.request_id))
        lst.append('LocateStatusType_1_2 locate_status=' + repr(self.locate_status))
        inner = ',\n'.join(lst)
        inner = '\n'.join(['   ' + line for line in inner.split('\n')])
        return 'struct LocateReplyHeader_1_2 {\n' + inner + '\n}'

    def _get_id(cls):
        return 'IDL:omg.org/GIOP/LocateReplyHeader_1_2:1.0'
    corba_id = classmethod(_get_id)

class LocateReplyHeader_1_3(LocateReplyHeader_1_2):
    """ Typedef IDL:omg.org/GIOP/LocateReplyHeader_1_3:1.0 """

    def __init__(self, *args, **kwargs):
        if len(args) == 1 and isinstance(args[0], LocateReplyHeader_1_2):
            self.__dict__ = dict(args[0].__dict__)
        else:
            super(LocateReplyHeader_1_3, self).__init__(*args, **kwargs)

    def _get_id(cls):
        return 'IDL:omg.org/GIOP/LocateReplyHeader_1_3:1.0'
    corba_id = classmethod(_get_id)

class FragmentHeader_1_2(object):
    """ Struct IDL:omg.org/GIOP/FragmentHeader_1_2:1.0 """

    def __init__(self, request_id):
        self._setrequest_id(request_id)

    def _setrequest_id(self, request_id):
        CORBA.check('unsigned_long', request_id)
        self._request_id = request_id

    def _getrequest_id(self):
        return self._request_id

    request_id = property(fset=_setrequest_id, fget=_getrequest_id)

    def marshal(self, output):
            CORBA.marshal(output, 'unsigned_long', self.request_id)

    def demarshal(cls, input_):
            request_id = CORBA.demarshal(input_, 'unsigned_long')
            return cls(request_id)
    demarshal = classmethod(demarshal)

    def __eq__(self, obj):
        if obj == None:
            return False
        if not isinstance(obj, type(self)):
            return False
        if self.request_id != obj.request_id:
            return False
        return True

    def __ne__(self, obj):
        return not self.__eq__(obj)

    def __repr__(self):
        lst = []
        lst.append('unsigned_long request_id=' + repr(self.request_id))
        inner = ',\n'.join(lst)
        inner = '\n'.join(['   ' + line for line in inner.split('\n')])
        return 'struct FragmentHeader_1_2 {\n' + inner + '\n}'

    def _get_id(cls):
        return 'IDL:omg.org/GIOP/FragmentHeader_1_2:1.0'
    corba_id = classmethod(_get_id)

class FragmentHeader_1_3(FragmentHeader_1_2):
    """ Typedef IDL:omg.org/GIOP/FragmentHeader_1_3:1.0 """

    def __init__(self, *args, **kwargs):
        if len(args) == 1 and isinstance(args[0], FragmentHeader_1_2):
            self.__dict__ = dict(args[0].__dict__)
        else:
            super(FragmentHeader_1_3, self).__init__(*args, **kwargs)

    def _get_id(cls):
        return 'IDL:omg.org/GIOP/FragmentHeader_1_3:1.0'
    corba_id = classmethod(_get_id)


# Local variables:
#   buffer-read-only: t
# End:
