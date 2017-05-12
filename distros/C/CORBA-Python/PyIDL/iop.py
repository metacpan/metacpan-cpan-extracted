# ex: set ro:
#   This file was generated (by idl2py). DO NOT modify it.
# From file : IOP.idl, 5190 octets, Fri Oct 05 19:47:18 2007

""" Module IDL:omg.org/IOP:1.0 """

import PyIDL as CORBA


class ProfileId(long):
    """ Typedef IDL:omg.org/IOP/ProfileId:1.0 """

    def __init__(self, val):
        CORBA.check('unsigned_long', val)
        long.__init__(val)

    def marshal(self, output):
        CORBA.marshal(output, 'unsigned_long', self)

    def demarshal(cls, input_):
        val = CORBA.demarshal(input_, 'unsigned_long')
        return cls(val)
    demarshal = classmethod(demarshal)

    def _get_id(cls):
        return 'IDL:omg.org/IOP/ProfileId:1.0'
    corba_id = classmethod(_get_id)

# Constant: IDL:omg.org/IOP/TAG_INTERNET_IOP:1.0
TAG_INTERNET_IOP = 0L

# Constant: IDL:omg.org/IOP/TAG_MULTIPLE_COMPONENTS:1.0
TAG_MULTIPLE_COMPONENTS = 1L

# Constant: IDL:omg.org/IOP/TAG_SCCP_IOP:1.0
TAG_SCCP_IOP = 2L

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

class ComponentId(long):
    """ Typedef IDL:omg.org/IOP/ComponentId:1.0 """

    def __init__(self, val):
        CORBA.check('unsigned_long', val)
        long.__init__(val)

    def marshal(self, output):
        CORBA.marshal(output, 'unsigned_long', self)

    def demarshal(cls, input_):
        val = CORBA.demarshal(input_, 'unsigned_long')
        return cls(val)
    demarshal = classmethod(demarshal)

    def _get_id(cls):
        return 'IDL:omg.org/IOP/ComponentId:1.0'
    corba_id = classmethod(_get_id)

class TaggedComponent(object):
    """ Struct IDL:omg.org/IOP/TaggedComponent:1.0 """

    def __init__(self, tag, component_data):
        self._settag(tag)
        self._setcomponent_data(component_data)

    def _settag(self, tag):
        CORBA.check(ComponentId, tag)
        self._tag = tag

    def _gettag(self):
        return self._tag

    tag = property(fset=_settag, fget=_gettag)

    def _setcomponent_data(self, component_data):
        _e0 = component_data
        CORBA.check('long', len(_e0))
        for _e1 in _e0:
            CORBA.check('octet', ord(_e1))
        self._component_data = component_data

    def _getcomponent_data(self):
        return self._component_data

    component_data = property(fset=_setcomponent_data, fget=_getcomponent_data)

    def marshal(self, output):
            self.tag.marshal(output)
            _e0 = self.component_data
            CORBA.marshal(output, 'long', len(_e0))
            for _e1 in _e0:
                CORBA.marshal(output, 'octet', ord(_e1))

    def demarshal(cls, input_):
            tag = ComponentId.demarshal(input_)
            _len0 = CORBA.demarshal(input_, 'long')
            _lst0 = []
            for _i0 in xrange(_len0):
                _lst0.append(CORBA.demarshal(input_, 'octet'))
            _lst0 = ''.join(map(chr, _lst0))
            component_data = _lst0
            return cls(tag, component_data)
    demarshal = classmethod(demarshal)

    def __eq__(self, obj):
        if obj == None:
            return False
        if not isinstance(obj, type(self)):
            return False
        if self.tag != obj.tag:
            return False
        if self.component_data != obj.component_data:
            return False
        return True

    def __ne__(self, obj):
        return not self.__eq__(obj)

    def __repr__(self):
        lst = []
        lst.append('ComponentId tag=' + repr(self.tag))
        lst.append('octet<> component_data=' + repr(self.component_data))
        inner = ',\n'.join(lst)
        inner = '\n'.join(['   ' + line for line in inner.split('\n')])
        return 'struct TaggedComponent {\n' + inner + '\n}'

    def _get_id(cls):
        return 'IDL:omg.org/IOP/TaggedComponent:1.0'
    corba_id = classmethod(_get_id)

class MultipleComponentProfile(list):
    """ Typedef IDL:omg.org/IOP/MultipleComponentProfile:1.0 """

    def __init__(self, *params):
        list.__init__(self, *params)
        _e0 = list(*params)
        for _e1 in _e0:
            CORBA.check(TaggedComponent, _e1)

    def marshal(self, output):
        _e0 = self
        CORBA.marshal(output, 'long', len(_e0))
        for _e1 in _e0:
            _e1.marshal(output)

    def demarshal(cls, input_):
        _len0 = CORBA.demarshal(input_, 'long')
        _lst0 = []
        for _i0 in xrange(_len0):
            _lst0.append(TaggedComponent.demarshal(input_))
        return cls(_lst0)
    demarshal = classmethod(demarshal)

    def _get_id(cls):
        return 'IDL:omg.org/IOP/MultipleComponentProfile:1.0'
    corba_id = classmethod(_get_id)

# Constant: IDL:omg.org/IOP/TAG_ORB_TYPE:1.0
TAG_ORB_TYPE = 0L

# Constant: IDL:omg.org/IOP/TAG_CODE_SETS:1.0
TAG_CODE_SETS = 1L

# Constant: IDL:omg.org/IOP/TAG_POLICIES:1.0
TAG_POLICIES = 2L

# Constant: IDL:omg.org/IOP/TAG_ALTERNATE_IIOP_ADDRESS:1.0
TAG_ALTERNATE_IIOP_ADDRESS = 3L

# Constant: IDL:omg.org/IOP/TAG_ASSOCIATION_OPTIONS:1.0
TAG_ASSOCIATION_OPTIONS = 13L

# Constant: IDL:omg.org/IOP/TAG_SEC_NAME:1.0
TAG_SEC_NAME = 14L

# Constant: IDL:omg.org/IOP/TAG_SPKM_1_SEC_MECH:1.0
TAG_SPKM_1_SEC_MECH = 15L

# Constant: IDL:omg.org/IOP/TAG_SPKM_2_SEC_MECH:1.0
TAG_SPKM_2_SEC_MECH = 16L

# Constant: IDL:omg.org/IOP/TAG_KerberosV5_SEC_MECH:1.0
TAG_KerberosV5_SEC_MECH = 17L

# Constant: IDL:omg.org/IOP/TAG_CSI_ECMA_Secret_SEC_MECH:1.0
TAG_CSI_ECMA_Secret_SEC_MECH = 18L

# Constant: IDL:omg.org/IOP/TAG_CSI_ECMA_Hybrid_SEC_MECH:1.0
TAG_CSI_ECMA_Hybrid_SEC_MECH = 19L

# Constant: IDL:omg.org/IOP/TAG_SSL_SEC_TRANS:1.0
TAG_SSL_SEC_TRANS = 20L

# Constant: IDL:omg.org/IOP/TAG_CSI_ECMA_Public_SEC_MECH:1.0
TAG_CSI_ECMA_Public_SEC_MECH = 21L

# Constant: IDL:omg.org/IOP/TAG_GENERIC_SEC_MECH:1.0
TAG_GENERIC_SEC_MECH = 22L

# Constant: IDL:omg.org/IOP/TAG_FIREWALL_TRANS:1.0
TAG_FIREWALL_TRANS = 23L

# Constant: IDL:omg.org/IOP/TAG_SCCP_CONTACT_INFO:1.0
TAG_SCCP_CONTACT_INFO = 24L

# Constant: IDL:omg.org/IOP/TAG_JAVA_CODEBASE:1.0
TAG_JAVA_CODEBASE = 25L

# Constant: IDL:omg.org/IOP/TAG_TRANSACTION_POLICY:1.0
TAG_TRANSACTION_POLICY = 26L

# Constant: IDL:omg.org/IOP/TAG_MESSAGE_ROUTER:1.0
TAG_MESSAGE_ROUTER = 30L

# Constant: IDL:omg.org/IOP/TAG_OTS_POLICY:1.0
TAG_OTS_POLICY = 31L

# Constant: IDL:omg.org/IOP/TAG_INV_POLICY:1.0
TAG_INV_POLICY = 32L

# Constant: IDL:omg.org/IOP/TAG_CSI_SEC_MECH_LIST:1.0
TAG_CSI_SEC_MECH_LIST = 33L

# Constant: IDL:omg.org/IOP/TAG_NULL_TAG:1.0
TAG_NULL_TAG = 34L

# Constant: IDL:omg.org/IOP/TAG_SECIOP_SEC_TRANS:1.0
TAG_SECIOP_SEC_TRANS = 35L

# Constant: IDL:omg.org/IOP/TAG_TLS_SEC_TRANS:1.0
TAG_TLS_SEC_TRANS = 36L

# Constant: IDL:omg.org/IOP/TAG_ACTIVITY_POLICY:1.0
TAG_ACTIVITY_POLICY = 37L

# Constant: IDL:omg.org/IOP/TAG_COMPLETE_OBJECT_KEY:1.0
TAG_COMPLETE_OBJECT_KEY = 5L

# Constant: IDL:omg.org/IOP/TAG_ENDPOINT_ID_POSITION:1.0
TAG_ENDPOINT_ID_POSITION = 6L

# Constant: IDL:omg.org/IOP/TAG_LOCATION_POLICY:1.0
TAG_LOCATION_POLICY = 12L

# Constant: IDL:omg.org/IOP/TAG_DCE_STRING_BINDING:1.0
TAG_DCE_STRING_BINDING = 100L

# Constant: IDL:omg.org/IOP/TAG_DCE_BINDING_NAME:1.0
TAG_DCE_BINDING_NAME = 101L

# Constant: IDL:omg.org/IOP/TAG_DCE_NO_PIPES:1.0
TAG_DCE_NO_PIPES = 102L

# Constant: IDL:omg.org/IOP/TAG_DCE_SEC_MECH:1.0
TAG_DCE_SEC_MECH = 103L

# Constant: IDL:omg.org/IOP/TAG_INET_SEC_TRANS:1.0
TAG_INET_SEC_TRANS = 123L

class ServiceId(long):
    """ Typedef IDL:omg.org/IOP/ServiceId:1.0 """

    def __init__(self, val):
        CORBA.check('unsigned_long', val)
        long.__init__(val)

    def marshal(self, output):
        CORBA.marshal(output, 'unsigned_long', self)

    def demarshal(cls, input_):
        val = CORBA.demarshal(input_, 'unsigned_long')
        return cls(val)
    demarshal = classmethod(demarshal)

    def _get_id(cls):
        return 'IDL:omg.org/IOP/ServiceId:1.0'
    corba_id = classmethod(_get_id)

class ServiceContext(object):
    """ Struct IDL:omg.org/IOP/ServiceContext:1.0 """

    def __init__(self, context_id, context_data):
        self._setcontext_id(context_id)
        self._setcontext_data(context_data)

    def _setcontext_id(self, context_id):
        CORBA.check(ServiceId, context_id)
        self._context_id = context_id

    def _getcontext_id(self):
        return self._context_id

    context_id = property(fset=_setcontext_id, fget=_getcontext_id)

    def _setcontext_data(self, context_data):
        _e0 = context_data
        CORBA.check('long', len(_e0))
        for _e1 in _e0:
            CORBA.check('octet', ord(_e1))
        self._context_data = context_data

    def _getcontext_data(self):
        return self._context_data

    context_data = property(fset=_setcontext_data, fget=_getcontext_data)

    def marshal(self, output):
            self.context_id.marshal(output)
            _e0 = self.context_data
            CORBA.marshal(output, 'long', len(_e0))
            for _e1 in _e0:
                CORBA.marshal(output, 'octet', ord(_e1))

    def demarshal(cls, input_):
            context_id = ServiceId.demarshal(input_)
            _len0 = CORBA.demarshal(input_, 'long')
            _lst0 = []
            for _i0 in xrange(_len0):
                _lst0.append(CORBA.demarshal(input_, 'octet'))
            _lst0 = ''.join(map(chr, _lst0))
            context_data = _lst0
            return cls(context_id, context_data)
    demarshal = classmethod(demarshal)

    def __eq__(self, obj):
        if obj == None:
            return False
        if not isinstance(obj, type(self)):
            return False
        if self.context_id != obj.context_id:
            return False
        if self.context_data != obj.context_data:
            return False
        return True

    def __ne__(self, obj):
        return not self.__eq__(obj)

    def __repr__(self):
        lst = []
        lst.append('ServiceId context_id=' + repr(self.context_id))
        lst.append('octet<> context_data=' + repr(self.context_data))
        inner = ',\n'.join(lst)
        inner = '\n'.join(['   ' + line for line in inner.split('\n')])
        return 'struct ServiceContext {\n' + inner + '\n}'

    def _get_id(cls):
        return 'IDL:omg.org/IOP/ServiceContext:1.0'
    corba_id = classmethod(_get_id)

class ServiceContextList(list):
    """ Typedef IDL:omg.org/IOP/ServiceContextList:1.0 """

    def __init__(self, *params):
        list.__init__(self, *params)
        _e0 = list(*params)
        for _e1 in _e0:
            CORBA.check(ServiceContext, _e1)

    def marshal(self, output):
        _e0 = self
        CORBA.marshal(output, 'long', len(_e0))
        for _e1 in _e0:
            _e1.marshal(output)

    def demarshal(cls, input_):
        _len0 = CORBA.demarshal(input_, 'long')
        _lst0 = []
        for _i0 in xrange(_len0):
            _lst0.append(ServiceContext.demarshal(input_))
        return cls(_lst0)
    demarshal = classmethod(demarshal)

    def _get_id(cls):
        return 'IDL:omg.org/IOP/ServiceContextList:1.0'
    corba_id = classmethod(_get_id)

# Constant: IDL:omg.org/IOP/TransactionService:1.0
TransactionService = 0L

# Constant: IDL:omg.org/IOP/CodeSets:1.0
CodeSets = 1L

# Constant: IDL:omg.org/IOP/ChainBypassCheck:1.0
ChainBypassCheck = 2L

# Constant: IDL:omg.org/IOP/ChainBypassInfo:1.0
ChainBypassInfo = 3L

# Constant: IDL:omg.org/IOP/LogicalThreadId:1.0
LogicalThreadId = 4L

# Constant: IDL:omg.org/IOP/BI_DIR_IIOP:1.0
BI_DIR_IIOP = 5L

# Constant: IDL:omg.org/IOP/SendingContextRunTime:1.0
SendingContextRunTime = 6L

# Constant: IDL:omg.org/IOP/INVOCATION_POLICIES:1.0
INVOCATION_POLICIES = 7L

# Constant: IDL:omg.org/IOP/FORWARDED_IDENTITY:1.0
FORWARDED_IDENTITY = 8L

# Constant: IDL:omg.org/IOP/UnknownExceptionInfo:1.0
UnknownExceptionInfo = 9L

# Constant: IDL:omg.org/IOP/RTCorbaPriority:1.0
RTCorbaPriority = 10L

# Constant: IDL:omg.org/IOP/RTCorbaPriorityRange:1.0
RTCorbaPriorityRange = 11L

# Constant: IDL:omg.org/IOP/FT_GROUP_VERSION:1.0
FT_GROUP_VERSION = 12L

# Constant: IDL:omg.org/IOP/FT_REQUEST:1.0
FT_REQUEST = 13L

# Constant: IDL:omg.org/IOP/ExceptionDetailMessage:1.0
ExceptionDetailMessage = 14L

# Constant: IDL:omg.org/IOP/SecurityAttributeService:1.0
SecurityAttributeService = 15L

# Constant: IDL:omg.org/IOP/ActivityService:1.0
ActivityService = 16L


# Local variables:
#   buffer-read-only: t
# End:
