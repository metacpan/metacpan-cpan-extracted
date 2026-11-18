import base64
import io
import json
import struct
import sys
import unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from engine_helpers import (CompatibilityError, DaemonStreamError, ProtocolError,
                            encode_registry_auth, iter_ndjson, iter_output,
                            iter_progress, negotiate_version, parse_version, read_exact)


class ShortReader(io.BytesIO):
    def read(self, size=-1):
        return super().read(min(size, 1) if size >= 0 else 1)


def frame(kind, payload):
    return bytes([kind, 0, 0, 0]) + struct.pack('>I', len(payload)) + payload


class VersionTests(unittest.TestCase):
    def choose(self, server, **kwargs):
        return negotiate_version(server, client_min='1.40', client_max='1.51', **kwargs)

    def test_new_server_capped(self):
        self.assertEqual(self.choose({'ApiVersion':'1.56','MinAPIVersion':'1.40'}), '1.51')
    def test_old_server(self):
        self.assertEqual(self.choose({'ApiVersion':'1.47','MinAPIVersion':'1.24'}), '1.47')
    def test_disjoint(self):
        with self.assertRaises(CompatibilityError): self.choose({'ApiVersion':'1.39','MinAPIVersion':'1.24'})
    def test_new_min_disjoint(self):
        with self.assertRaises(CompatibilityError): self.choose({'ApiVersion':'1.56','MinAPIVersion':'1.52'})
    def test_missing_minimum(self):
        with self.assertRaises(CompatibilityError): self.choose({'ApiVersion':'1.47'})
    def test_explicit_legacy(self):
        self.assertEqual(self.choose({'ApiVersion':'1.47'}, legacy_server_min='1.24'), '1.47')
    def test_valid_pin(self):
        self.assertEqual(self.choose({'ApiVersion':'1.51','MinAPIVersion':'1.40'}, pin='1.47'), '1.47')
    def test_invalid_pin(self):
        with self.assertRaises(CompatibilityError): self.choose({'ApiVersion':'1.51','MinAPIVersion':'1.40'}, pin='1.52')
    def test_numeric_order(self): self.assertLess(parse_version('1.9'), parse_version('1.10'))
    def test_bad_versions(self):
        for value in ('1', '1.2.3', 'v1.51', '1.01', 1.51, None, True):
            with self.subTest(value=value), self.assertRaises(CompatibilityError): parse_version(value)
    def test_reversed_range(self):
        with self.assertRaises(CompatibilityError): self.choose({'ApiVersion':'1.40','MinAPIVersion':'1.51'})


class AuthTests(unittest.TestCase):
    def test_empty_padding(self): self.assertEqual(encode_registry_auth({}), 'e30=')
    def test_round_trip(self):
        obj={'username':'test','password':'ä😃','serveraddress':'registry.example.com'}
        value=encode_registry_auth(obj)
        self.assertEqual(json.loads(base64.urlsafe_b64decode(value)), obj)
        self.assertNotIn('+',value)
        self.assertNotIn('/',value)
    def test_reject_non_string(self):
        with self.assertRaises(TypeError): encode_registry_auth({'password':123})


class FrameTests(unittest.TestCase):
    def test_short_reads(self):
        self.assertEqual(list(iter_output(ShortReader(frame(1,b'OUT\n')+frame(2,b'ERR\n')))),[(1,b'OUT\n'),(2,b'ERR\n')])
    def test_empty(self): self.assertEqual(list(iter_output(io.BytesIO())),[])
    def test_zero_frame(self): self.assertEqual(list(iter_output(io.BytesIO(frame(1,b'')))),[(1,b'')])
    def test_stdin_kind(self): self.assertEqual(list(iter_output(io.BytesIO(frame(0,b'x')))),[(0,b'x')])
    def test_system_error(self):
        with self.assertRaisesRegex(DaemonStreamError,'failure'): list(iter_output(io.BytesIO(frame(3,b'failure'))))
    def test_bad_kind(self):
        with self.assertRaises(ProtocolError): list(iter_output(io.BytesIO(frame(9,b''))))
    def test_reserved(self):
        with self.assertRaises(ProtocolError): list(iter_output(io.BytesIO(b'\x01\x01\0\0\0\0\0\0')))
    def test_truncated_header(self):
        with self.assertRaises(ProtocolError): list(iter_output(io.BytesIO(b'\x01\0')))
    def test_truncated_body(self):
        with self.assertRaises(ProtocolError): list(iter_output(io.BytesIO(frame(1,b'hello')[:-1])))
    def test_frame_limit(self):
        with self.assertRaises(ProtocolError): list(iter_output(io.BytesIO(frame(1,b'abc')),max_frame_bytes=2))
    def test_tty_raw(self):
        raw=frame(1,b'not actually framed')
        self.assertEqual(b''.join(data for _,data in iter_output(ShortReader(raw),tty=True)),raw)
    def test_utf8_remains_bytes(self):
        raw='€'.encode()
        self.assertEqual(b''.join(data for _,data in iter_output(io.BytesIO(frame(1,raw[:1])+frame(1,raw[1:])))),raw)
    def test_nonblocking_reader(self):
        class R:
            def read(self,n): return None
        with self.assertRaises(ProtocolError): read_exact(R(),8)
    def test_zero_exact(self): self.assertEqual(read_exact(io.BytesIO(),0),b'')
    def test_invalid_limit(self):
        with self.assertRaises(ValueError): list(iter_output(io.BytesIO(),max_frame_bytes=0))


class NDJSONTests(unittest.TestCase):
    def test_fragmented_final_line(self):
        raw=b'{"status":"one"}\n{"status":"two"}'
        self.assertEqual(list(iter_ndjson(ShortReader(raw))),[{'status':'one'},{'status':'two'}])
    def test_crlf_and_blanks(self): self.assertEqual(list(iter_ndjson(io.BytesIO(b'\r\n{}\r\n\n'))),[{}])
    def test_invalid_json(self):
        with self.assertRaises(ProtocolError): list(iter_ndjson(io.BytesIO(b'{bad}\n')))
    def test_invalid_utf8(self):
        with self.assertRaises(ProtocolError): list(iter_ndjson(io.BytesIO(b'{"x":"\xff"}\n')))
    def test_object_only(self):
        with self.assertRaises(ProtocolError): list(iter_ndjson(io.BytesIO(b'[]\n')))
    def test_limit_newline(self):
        with self.assertRaises(ProtocolError): list(iter_ndjson(io.BytesIO(b'{"long":"xxx"}\n'),max_record_bytes=3))
    def test_limit_no_newline(self):
        with self.assertRaises(ProtocolError): list(iter_ndjson(ShortReader(b'{"long":"xxx"}'),max_record_bytes=3))
    def test_many_small_records(self): self.assertEqual(len(list(iter_ndjson(io.BytesIO(b'{}\n'*100),max_record_bytes=3))),100)
    def test_error_detail(self):
        with self.assertRaisesRegex(DaemonStreamError,'denied'): list(iter_progress(io.BytesIO(b'{"status":"start"}\n{"errorDetail":{"message":"denied"}}\n')))
    def test_error_legacy(self):
        with self.assertRaisesRegex(DaemonStreamError,'failed'): list(iter_progress(io.BytesIO(b'{"error":"failed"}\n')))
    def test_empty(self): self.assertEqual(list(iter_ndjson(io.BytesIO())),[])
    def test_success(self): self.assertEqual(list(iter_progress(io.BytesIO(b'{"aux":{"ID":"example"}}\n'))),[{'aux':{'ID':'example'}}])
    def test_limit_positive(self):
        with self.assertRaises(ValueError): list(iter_ndjson(io.BytesIO(),chunk_size=0))


if __name__ == '__main__':
    unittest.main()
