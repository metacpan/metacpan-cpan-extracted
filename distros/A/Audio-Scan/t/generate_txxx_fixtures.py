#!/usr/bin/env python3
"""Generate MP3 test fixtures for Audio::Scan TXXX multi-value tests.

Uses a valid MPEG frame extracted from an existing fixture as the audio
payload, then hand-builds ID3v2.4 tags with null-separated TXXX values
so we get exact byte-level control over the multi-value encoding.
"""
import struct, os

OUTDIR = "/home/martijn/github/Audio-Scan/t/mp3"
# Use an existing valid MP3 as the audio base
BASE_MP3 = "/home/martijn/github/Audio-Scan/t/mp3/no-tags-mp1l3.mp3"


def get_audio_payload():
    """Read raw MPEG audio frames from an existing no-tags fixture."""
    with open(BASE_MP3, 'rb') as f:
        return f.read()


def syncsafe_encode(size):
    """Encode an integer as a 4-byte syncsafe integer (ID3v2.4 spec)."""
    return (
        ((size & 0x0FE00000) << 3) |
        ((size & 0x001FC000) << 2) |
        ((size & 0x00003F80) << 1) |
        (size & 0x0000007F)
    )


def make_txxx_frame(desc, values, encoding=3):
    """Build an ID3v2.4 TXXX frame with null-separated values.
    encoding: 0=Latin1, 3=UTF-8
    """
    if encoding == 3:
        sep = b'\x00'
        desc_bytes = desc.encode('utf-8') + b'\x00'
        val_bytes = sep.join(v.encode('utf-8') for v in values)
    else:
        sep = b'\x00'
        desc_bytes = desc.encode('latin-1') + b'\x00'
        val_bytes = sep.join(v.encode('latin-1') for v in values)

    data = bytes([encoding]) + desc_bytes + val_bytes
    size = len(data)
    frame = b'TXXX' + struct.pack('>I', syncsafe_encode(size)) + b'\x00\x00' + data
    return frame


def make_id3v2_tag(frames):
    """Wrap frames in an ID3v2.4 tag header."""
    body = b''.join(frames)
    size = len(body)
    header = b'ID3' + b'\x04\x00' + b'\x00' + struct.pack('>I', syncsafe_encode(size))
    return header + body


def write_fixture(name, frames):
    tag = make_id3v2_tag(frames)
    audio = get_audio_payload()
    path = os.path.join(OUTDIR, name)
    with open(path, 'wb') as f:
        f.write(tag + audio)
    print(f"Wrote {path} ({len(tag) + len(audio)} bytes)")


# Fixture 1: Two-value TXXX (ALBUMARTISTS)
write_fixture("v2.4-txxx-multivalue.mp3", [
    make_txxx_frame("ALBUMARTISTS", ["Artist1", "Artist2"]),
    make_txxx_frame("ARTISTS", ["TrackArtist1", "TrackArtist2"]),
])

# Fixture 2: Three-value TXXX
write_fixture("v2.4-txxx-multivalue-3.mp3", [
    make_txxx_frame("ALBUMARTISTS", ["Artist1", "Artist2", "Artist3"]),
])

# Fixture 3: Multi-value with empty slot (tagger bug simulation)
write_fixture("v2.4-txxx-multivalue-empty.mp3", [
    make_txxx_frame("ALBUMARTISTS", ["Artist1", "", "Artist3"]),
])

# Fixture 4: Single-value TXXX (regression guard)
write_fixture("v2.4-txxx-single.mp3", [
    make_txxx_frame("ALBUMARTISTS", ["OnlyArtist"]),
    make_txxx_frame("USER FRAME", ["SingleValue"]),
])
