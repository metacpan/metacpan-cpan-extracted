#!/usr/bin/env python3
"""Explicit Unix-socket-only, finite read-only Engine probe. Python 3.10+."""
from __future__ import annotations
import argparse
import http.client
import json
import socket
import sys
from pathlib import Path
from engine_helpers import CompatibilityError, negotiate_version


class UnixConnection(http.client.HTTPConnection):
    def __init__(self, path: str, timeout: float):
        super().__init__('localhost', timeout=timeout)
        self.socket_path = path

    def connect(self) -> None:
        connection = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        try:
            connection.settimeout(self.timeout)
            connection.connect(self.socket_path)
        except BaseException:
            connection.close()
            raise
        self.sock = connection


def get_json(path: str, endpoint: str, timeout: float, limit: int = 4 * 1024 * 1024):
    connection = UnixConnection(path, timeout)
    try:
        connection.request('GET', endpoint, headers={'Accept': 'application/json'})
        response = connection.getresponse()
        body = response.read(limit + 1)
        if len(body) > limit:
            raise ValueError('Response exceeds configured body limit')
        if response.status != 200:
            # Do not echo arbitrary server/proxy bodies into diagnostics.
            raise RuntimeError(f'GET {endpoint} returned HTTP {response.status}')
        return json.loads(body)
    finally:
        connection.close()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--socket', required=True, help='Exact Unix socket path; contexts are not auto-resolved')
    parser.add_argument('--client-min', default='1.40')
    parser.add_argument('--client-max', default='1.51')
    parser.add_argument('--api-version', help='Explicit pin within the shared range')
    parser.add_argument('--legacy-server-min', help='Explicit missing-minimum fallback policy')
    parser.add_argument('--timeout', type=float, default=10.0)
    args = parser.parse_args()
    if args.timeout <= 0:
        parser.error('--timeout must be positive')
    if not hasattr(socket, 'AF_UNIX') or not Path(args.socket).is_socket():
        parser.error('--socket must identify an accessible Unix-domain socket')
    try:
        server = get_json(args.socket, '/version', args.timeout)
        if not isinstance(server, dict):
            raise ValueError('Version response must be an object')
        version = negotiate_version(server, client_min=args.client_min, client_max=args.client_max,
                                    pin=args.api_version, legacy_server_min=args.legacy_server_min)
        rows = get_json(args.socket, f'/v{version}/containers/json?all=true', args.timeout)
        if not isinstance(rows, list) or any(not isinstance(row, dict) for row in rows):
            raise ValueError('Container list response has an unexpected shape')
        print(json.dumps({'socket': args.socket, 'selected_api': version,
                          'server_version': server.get('Version'),
                          'server_os': server.get('Os'),
                          'containers': [{key: row.get(key) for key in
                                          ('Id', 'Names', 'Image', 'State', 'Status')} for row in rows]}, indent=2))
        return 0
    except (OSError, ValueError, RuntimeError, http.client.HTTPException) as exc:
        print(f'Probe failed: {exc}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
