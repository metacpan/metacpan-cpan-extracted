
import PyIDL as CORBA
import struct
import StringIO

class OutputBuffer(object):
    """ Marshaling buffer """

    def __init__(self, buf=None):
        if buf is None:
            buf = StringIO.StringIO()
        self._buf = buf
        self._pos = 0
        self._endian = 1    # little endian

    def _get_endian(self):
        return self._endian

    endian = property(fget=_get_endian)

    def getvalue(self):
        return self._buf.getvalue()

    def close(self):
        self._buf.close()

    def write(self, str_):
        self._buf.write(str_)

    def _align(self, size):
        while (self._pos % size) != 0:
            self._buf.write(chr(0))
            self._pos += 1

    def _pack(self, fmt, value):
        str_ = struct.pack(fmt, value)
        self._buf.write(str_)
        self._pos += len(str_)

    def char__marshal(self, value):
        self._pack('c', value)

    def wchar__marshal(self, value):
        raise NotImplementedError

    def octet__marshal(self, value):
        self._pack('B', value)

    def short__marshal(self, value):
        self._align(2)
        self._pack('h', value)

    def unsigned_short__marshal(self, value):
        self._align(2)
        self._pack('H', value)

    def long__marshal(self, value):
        self._align(4)
        self._pack('l', value)

    def unsigned_long__marshal(self, value):
        self._align(4)
        self._pack('L', value)

    def long_long__marshal(self, value):
        self._align(8)
        self._pack('q', value)

    def unsigned_long_long__marshal(self, value):
        self._align(8)
        self._pack('Q', value)

    def float__marshal(self, value):
        self._align(4)
        self._pack('f', value)

    def double__marshal(self, value):
        self._align(8)
        self._pack('d', value)

    def long_double__marshal(self, value):
        raise NotImplementedError

    def boolean__marshal(self, value):
        if value == True:
            self._pack('B', 1)
        else:
            self._pack('B', 0)

    def string__marshal(self, value):
        self._align(4)
        value += chr(0)
        length = len(value)
        self._pack('L', length)
        self._pack(str(length) + 's', value)

    def wstring__marshal(self, value):
        raise NotImplementedError


class InputBuffer(object):
    """ Demarshaling buffer """

    def __init__(self, input=None, endian=None):
        if input == None:
            self._buf = StringIO.StringIO('')
        if isinstance(input, str):
            self._buf = StringIO.StringIO(input)
        else:
            self._buf = input
        self._pos = 0
        self._endian = endian

    def _set_endian(self, value):
        self._endian = value

    def _get_endian(self):
        return self._endian

    endian = property(fset=_set_endian, fget=_get_endian)

    def getvalue(self):
        return self._buf.getvalue()

    def close(self):
        self._buf.close()

    def read(self, size=-1):
        return self._buf.read(size)

    def _align(self, size):
        while (self._pos % size) != 0:
            dummy = self._buf.read(1)
            self._pos += 1

    def _unpack(self, fmt):
        size = struct.calcsize(fmt)
        chunk = self._buf.read(size)
        if len(chunk) < size:
            print "Not enough data!"
            raise CORBA.SystemException('IDL:CORBA/INTERNAL:1.0', 8,
                                        CORBA.CORBA_COMPLETED_MAYBE)
        self._pos += size
        return struct.unpack(fmt, chunk)[0]

    def char__demarshal(self):
        return self._unpack('c')

    def wchar__demarshal(self):
        raise NotImplementedError

    def octet__demarshal(self):
        return self._unpack('B')

    def short__demarshal(self):
        self._align(2)
        return self._unpack('h')

    def unsigned_short__demarshal(self):
        self._align(2)
        return self._unpack('H')

    def long__demarshal(self):
        self._align(4)
        return self._unpack('l')

    def unsigned_long__demarshal(self):
        self._align(4)
        return self._unpack('L')

    def long_long__demarshal(self):
        self._align(8)
        return self._unpack('q')

    def unsigned_long_long__demarshal(self):
        self._align(8)
        return self._unpack('Q')

    def float__demarshal(self):
        self._align(4)
        return self._unpack('f')

    def double__demarshal(self):
        self._align(8)
        return self._unpack('d')

    def long_double__demarshal(self):
        raise NotImplementedError

    def boolean__demarshal(self):
        return self._unpack('B') == 1

    def string__demarshal(self):
        self._align(4)
        length = self._unpack('L')
        str_ = self._unpack(str(length) + 's')
        return str_[:len(str_)-1]

    def wstring__demarshal(self):
        raise NotImplementedError

