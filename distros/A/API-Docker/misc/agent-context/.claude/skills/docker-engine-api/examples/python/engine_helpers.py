"""Bounded protocol helpers, not a complete Docker SDK. Python 3.10+."""
from __future__ import annotations
import base64
import json
import re
import struct
from collections.abc import Iterator, Mapping
from typing import Any, BinaryIO


class ProtocolError(ValueError):
    """Unexpected, malformed, or truncated protocol input."""


class CompatibilityError(ValueError):
    """No deliberately supported API version is available."""


class DaemonStreamError(RuntimeError):
    """An error reported after the daemon started a stream."""


def parse_version(value: str) -> tuple[int, int]:
    if not isinstance(value, str) or not re.fullmatch(r'(0|[1-9]\d*)\.(0|[1-9]\d*)', value):
        raise CompatibilityError('API version must have integer major.minor form')
    major, minor = value.split('.')
    return int(major), int(minor)


def negotiate_version(server: Mapping[str, Any], *, client_min: str,
                      client_max: str, pin: str | None = None,
                      legacy_server_min: str | None = None) -> str:
    """Intersect supported ranges; no implicit guessed server minimum."""
    cmin, cmax = parse_version(client_min), parse_version(client_max)
    smax = parse_version(server.get('ApiVersion'))
    minimum = server.get('MinAPIVersion')
    if minimum is None:
        minimum = legacy_server_min
    if minimum is None:
        raise CompatibilityError('Server omitted MinAPIVersion; an explicit legacy policy is required')
    smin = parse_version(minimum)
    if cmin > cmax or smin > smax:
        raise CompatibilityError('Invalid supported version range')
    low, high = max(cmin, smin), min(cmax, smax)
    if low > high:
        raise CompatibilityError('Client and daemon API ranges do not intersect')
    selected = parse_version(pin) if pin is not None else high
    if not low <= selected <= high:
        raise CompatibilityError('Pinned API version lies outside the shared supported range')
    return f'{selected[0]}.{selected[1]}'


def encode_registry_auth(auth: Mapping[str, str]) -> str:
    """Padded URL-safe base64 JSON; output is a secret, not safe logging data."""
    if not isinstance(auth, Mapping) or any(not isinstance(k, str) or not isinstance(v, str)
                                            for k, v in auth.items()):
        raise TypeError('Auth must map strings to strings')
    raw = json.dumps(dict(auth), ensure_ascii=False, separators=(',', ':')).encode('utf-8')
    return base64.urlsafe_b64encode(raw).decode('ascii')


def read_exact(reader: BinaryIO, size: int, *, allow_clean_eof: bool = False) -> bytes | None:
    if size < 0:
        raise ValueError('size must be non-negative')
    parts: list[bytes] = []
    remaining = size
    while remaining:
        part = reader.read(remaining)
        if part is None:
            raise ProtocolError('Nonblocking readers require an adapter')
        if not isinstance(part, bytes) or len(part) > remaining:
            raise ProtocolError('Reader violated the bounded binary-read contract')
        if not part:
            if allow_clean_eof and remaining == size:
                return None
            raise ProtocolError('Truncated stream')
        parts.append(part)
        remaining -= len(part)
    return b''.join(parts)


def iter_output(reader: BinaryIO, *, tty: bool = False,
                max_frame_bytes: int = 16 * 1024 * 1024,
                chunk_size: int = 65536) -> Iterator[tuple[int, bytes]]:
    """Yield (stream type, bytes). TTY output is raw combined output, labeled 1.

    Strict reserved-byte and truncation checks are this client's safety policy.
    """
    if max_frame_bytes <= 0 or chunk_size <= 0:
        raise ValueError('Limits must be positive')
    if tty:
        while True:
            data = reader.read(chunk_size)
            if not isinstance(data, bytes) or len(data) > chunk_size:
                raise ProtocolError('Reader violated the bounded binary-read contract')
            if not data:
                return
            yield 1, data
    else:
        while True:
            header = read_exact(reader, 8, allow_clean_eof=True)
            if header is None:
                return
            kind = header[0]
            if header[1:4] != b'\x00\x00\x00' or kind not in (0, 1, 2, 3):
                raise ProtocolError('Invalid or unsupported multiplex header')
            length = struct.unpack('>I', header[4:])[0]
            if length > max_frame_bytes:
                raise ProtocolError('Frame exceeds configured size limit')
            payload = read_exact(reader, length)
            assert payload is not None
            if kind == 3:
                raise DaemonStreamError(payload.decode('utf-8', errors='replace'))
            yield kind, payload


def _record(raw: bytes) -> dict[str, Any]:
    try:
        value = json.loads(raw)
    except (ValueError, UnicodeError) as exc:
        raise ProtocolError('Invalid JSON record') from exc
    if not isinstance(value, dict):
        raise ProtocolError('Expected a JSON object record')
    return value


def iter_ndjson(reader: BinaryIO, *, max_record_bytes: int = 1024 * 1024,
                chunk_size: int = 65536) -> Iterator[dict[str, Any]]:
    """Read bounded NDJSON objects, including a final non-newline record.

    Not an RFC7464, concatenated-JSON, or arbitrary media-type parser.
    """
    if max_record_bytes <= 0 or chunk_size <= 0:
        raise ValueError('Limits must be positive')
    buffer = bytearray()
    while True:
        chunk = reader.read(chunk_size)
        if not isinstance(chunk, bytes) or len(chunk) > chunk_size:
            raise ProtocolError('Reader violated the bounded binary-read contract')
        if not chunk:
            if len(buffer) > max_record_bytes:
                raise ProtocolError('JSON record exceeds configured size limit')
            if buffer.strip():
                yield _record(bytes(buffer))
            return
        buffer.extend(chunk)
        while True:
            end = buffer.find(b'\n')
            if end < 0:
                break
            if end > max_record_bytes:
                raise ProtocolError('JSON record exceeds configured size limit')
            line = bytes(buffer[:end])
            del buffer[:end + 1]
            if line.strip():
                yield _record(line)
        if len(buffer) > max_record_bytes:
            raise ProtocolError('JSON record exceeds configured size limit')


def iter_progress(reader: BinaryIO, **limits: int) -> Iterator[dict[str, Any]]:
    for item in iter_ndjson(reader, **limits):
        if item.get('error') or item.get('errorDetail'):
            detail = item.get('errorDetail')
            message = detail.get('message') if isinstance(detail, dict) else None
            raise DaemonStreamError(str(message or item.get('error') or 'Daemon operation failed'))
        yield item
