import logging
import socket

import PyIDL as CORBA
import PyIDL.cdr as CDR
import PyIDL.iop as IOP
import PyIDL.giop as GIOP

_LOGGER = logging.getLogger('PyIDL')

_GIOP_HEADER_LENGTH = 12

_request_id = 0

def _getRequestId():
    global _request_id
    _request_id += 1
    return _request_id

def _sendall(sock, data):
    # Method sendall exists for real sockets but not for simulated ones..
    pos = 0
    remaining = len(data)
    while remaining > 0:
        sent = sock.send(data[pos:])
        if sent == 0:
            raise socket.error("send returned 0 - socket closed")
        pos += sent
        remaining -= sent

def _recvall(sock, requiredSize):
    data = ''
    while len(data) < requiredSize:
        part = sock.recv(requiredSize - len(data))
        if len(part) == 0:
            raise socket.error("recv returned 0 - socket closed")
        data += part
    return data

def RequestOneWay(sock, request_header, request_body):
    request_header.request_id = _getRequestId()
    request = CDR.OutputBuffer()
    request_header.marshal(request)
    request.write(request_body.getvalue())
    msg = CDR.OutputBuffer()
    GIOP.MessageHeader_1_1(
            magic='GIOP',
            GIOP_version=GIOP.Version(major=1, minor=2),
            flags=0x01,         # flags : little endian
            message_type=0,     # Request
            message_size=len(request.getvalue())
    ).marshal(msg)
    msg.write(request.getvalue())
    request.close()
    _sendall(sock, msg.getvalue())
    msg.close()

def RequestReply(sock, request_header, request_body):
    request_header.request_id = _getRequestId()
    request = CDR.OutputBuffer()
    request_header.marshal(request)
    request.write(request_body.getvalue())
    msg = CDR.OutputBuffer()
    GIOP.MessageHeader_1_1(
            magic='GIOP',
            GIOP_version=GIOP.Version(major=1, minor=2),
            flags=0x01,         # flags : little endian
            message_type=0,     # Request
            message_size=len(request.getvalue())
    ).marshal(msg)
    msg.write(request.getvalue())
    request.close()
    _sendall(sock, msg.getvalue())
    msg.close()
    while True:
        _header = _recvall(sock, _GIOP_HEADER_LENGTH)
        header = CDR.InputBuffer(_header)
        magic = ''
        magic += CORBA.demarshal(header, 'char')
        magic += CORBA.demarshal(header, 'char')
        magic += CORBA.demarshal(header, 'char')
        magic += CORBA.demarshal(header, 'char')
        GIOP_version = GIOP.Version.demarshal(header)
        flags = CORBA.demarshal(header, 'octet')
        endian = flags & 0x01
        header.endian = endian      # now, endian is known
        message_type = CORBA.demarshal(header, 'octet')
        message_size = CORBA.demarshal(header, 'unsigned_long')

        if magic == 'GIOP' and \
           GIOP_version.major == 1 and \
           GIOP_version.minor == 2 and \
           message_type == 1:
            _reply = _recvall(sock, message_size)
            reply = CDR.InputBuffer(_reply, endian)
            reply_header = GIOP.ReplyHeader_1_2.demarshal(reply)
            if request_header.request_id == reply_header.request_id:
                _LOGGER.info("reply id %d", reply_header.request_id)
                return (reply_header.reply_status, reply_header.service_context, reply)
            elif request_header.request_id > reply_header.request_id:
                _LOGGER.warning("bad request id %d (wanted %d).",
                                reply_header.request_id, request_header.request_id)
            else:
                _LOGGER.error("bad request id %d (wanted %d).",
                              reply_header.request_id, request_header.request_id)
                raise CORBA.SystemException('IDL:CORBA/INTERNAL:1.0', 8,
                                            CORBA.CORBA_COMPLETED_MAYBE)
        else:
            _LOGGER.error("bad header")
            raise CORBA.SystemException('IDL:CORBA/INTERNAL:1.0', 8,
                                        CORBA.CORBA_COMPLETED_MAYBE)


class Servant(object):
    def __init__(self):
        self.itf = dict()

    def Register(self, key, value):
        self.itf[key] = value

    def Servant(self, request):
        if len(request) < _GIOP_HEADER_LENGTH:
            _LOGGER.debug("header incomplete")
            return None, request

        def checkHeaderField(name, got, expected):
            if got != expected:
                _LOGGER.error("bad header field: %s got=%s expected=%s",
                              name, got, expected)
                raise CORBA.SystemException('IDL:CORBA/INTERNAL:1.0', 8,
                                            CORBA.CORBA_COMPLETED_MAYBE)

        input_buffer = CDR.InputBuffer(request)
        magic = ''
        magic += CORBA.demarshal(input_buffer, 'char')
        magic += CORBA.demarshal(input_buffer, 'char')
        magic += CORBA.demarshal(input_buffer, 'char')
        magic += CORBA.demarshal(input_buffer, 'char')
        checkHeaderField("magic", magic, 'GIOP')

        GIOP_version = GIOP.Version.demarshal(input_buffer)
        checkHeaderField("major version", GIOP_version.major, 1)
        checkHeaderField("minor version", GIOP_version.minor, 2)
        flags = CORBA.demarshal(input_buffer, 'octet')
        endian = flags & 0x01
        input_buffer.endian = endian     # now, endian is known
        message_type = CORBA.demarshal(input_buffer, 'octet')
        message_size = CORBA.demarshal(input_buffer, 'unsigned_long')

        message_data = input_buffer.read(message_size)
        if len(message_data) < message_size:
            _LOGGER.debug("message incomplete")
            return None, request

        # From now on consume the data..
        message = CDR.InputBuffer(message_data)
        message.endian = endian
        remaining_data = input_buffer.read()

        if message_type != 0:
            _LOGGER.error("unexpected message type %s (expected 0)",
                          message_type)
            return None, remaining_data

        request_header = GIOP.RequestHeader_1_2.demarshal(message)
        interface = request_header.target._v
        if self.itf.has_key(interface) == False:
            _LOGGER.warning("unknown interface '%s'.", interface)
            reply_status = GIOP.SYSTEM_EXCEPTION
            reply_body = CDR.OutputBuffer()
            CORBA.marshal(reply_body, 'string', 'IDL:CORBA/NO_IMPLEMENT:1.0')
            CORBA.marshal(reply_body, 'unsigned_long', 11)
            CORBA.marshal(reply_body, 'unsigned_long', 1)   # COMPLETED_NO
        else:
            classname = self.itf[interface]
            oper = request_header.operation
            if not hasattr(classname, oper):
                _LOGGER.error("unknown operation '%s'.", oper)
                reply_status = GIOP.SYSTEM_EXCEPTION
                reply_body = CDR.OutputBuffer()
                CORBA.marshal(reply_body, 'string', 'IDL:CORBA/BAD_OPERATION:1.0')
                CORBA.marshal(reply_body, 'unsigned_long', 13)
                CORBA.marshal(reply_body, 'unsigned_long', 1)   # COMPLETED_NO
            else:
                srv_op = '_skel_' + oper
                (reply_status, reply_body) = getattr(classname, srv_op)(message)
                if reply_status == None:
                    return (None, remaining_data)       # oneway

        reply = CDR.OutputBuffer()
        GIOP.ReplyHeader_1_2(
            request_id=request_header.request_id,
            reply_status=reply_status,
            service_context=IOP.ServiceContextList([])
        ).marshal(reply)
        reply.write(reply_body.getvalue())
        reply_body.close()
        buff = CDR.OutputBuffer()
        GIOP.MessageHeader_1_1(
            magic='GIOP',
            GIOP_version=GIOP.Version(major=1, minor=2),
            flags=0x01,         # flags : little endian
            message_type=1,     # Reply
            message_size=len(reply.getvalue())
        ).marshal(buff)
        buff.write(reply.getvalue())
        reply.close()
        str_ = buff.getvalue()
        buff.close()
        return (str_, remaining_data)

