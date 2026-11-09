#!/usr/bin/env python3
"""Opt-in vector -> AGE -> SQL lab. PG18, pgvector 0.8.6, AGE PG18 1.8.0.

Requires examples/sql/01, 02, 04 and an approved direct/session-pooled libpq
service. Optional dependency: psycopg 3. No ORM or pgvector Python adapter needed.
Not integration-tested during package creation. The fixed 3D space is synthetic.
"""
from __future__ import annotations

import argparse
import json
import math
import os
import struct
import sys
from typing import Any

VECTOR_SQL = """
SELECT doc_id, title, embedding <=> %s::public.vector(3) AS distance
FROM skill_lab.document
WHERE tenant_id = %s AND model_id = 'demo-v1'
ORDER BY embedding <=> %s::public.vector(3)
LIMIT %s
"""
GRAPH_SQL = """
SELECT g.doc_id::bigint AS doc_id, g.seed_id::bigint AS seed_id,
       (g.evidence_id::jsonb #>> '{}') AS evidence_id
FROM ag_catalog.cypher('skill_graph', $$
    MATCH (s:document)-[r:related]->(d:document)
    WHERE s.tenant_id = $tenant AND s.doc_id IN $seed_ids
      AND r.tenant_id = $tenant AND d.tenant_id = $tenant
    RETURN DISTINCT d.doc_id, s.doc_id, r.evidence_id
    ORDER BY d.doc_id, s.doc_id, r.evidence_id
    LIMIT 100
$$, %s::ag_catalog.agtype)
AS g(doc_id ag_catalog.agtype, seed_id ag_catalog.agtype,
     evidence_id ag_catalog.agtype)
"""
CONTENT_SQL = """
SELECT doc_id, title FROM skill_lab.document
WHERE tenant_id = %s AND model_id = 'demo-v1' AND doc_id = ANY(%s::bigint[])
ORDER BY doc_id
"""


def vector_literal(value: Any) -> str:
    if not isinstance(value, list) or len(value) != 3:
        raise ValueError("The lab requires a JSON array containing exactly three numbers")
    numbers: list[float] = []
    for x in value:
        if isinstance(x, bool) or not isinstance(x, (int, float)):
            raise ValueError("Vector components must be finite numbers")
        try:
            f = float(x)
        except (ValueError, OverflowError) as exc:
            raise ValueError("Vector components must fit finite float32 values") from exc
        if not math.isfinite(f) or abs(f) > 3.4028234e38:
            raise ValueError("Vector components must fit finite float32 values")
        # Match the storage precision before rejecting an underflowed zero vector.
        numbers.append(struct.unpack("!f", struct.pack("!f", f))[0])
    if not any(x != 0.0 for x in numbers):
        raise ValueError("Cosine search cannot use a zero vector")
    return json.dumps(numbers, allow_nan=False, separators=(",", ":"))


def retrieve(service: str, tenant: int, query: str, seed_count: int,
             load_age: bool) -> dict[str, Any]:
    # Optional dependency is imported only when an explicitly approved run starts.
    import psycopg
    with psycopg.connect(service=service, autocommit=True, connect_timeout=10,
                         application_name="postgres-vector-graph-lab") as conn:
        version = int(conn.execute("SHOW server_version_num").fetchone()[0])
        if not 180000 <= version < 190000:
            raise RuntimeError("This lab requires a separately verified PostgreSQL 18 target")
        if load_age:
            # Direct/session pooling ONLY. Managed systems may preload AGE instead.
            conn.execute("LOAD 'age'")
        with conn.transaction():
            conn.execute("SET TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY")
            conn.execute("SET LOCAL search_path = pg_catalog, ag_catalog, public")
            conn.execute("SET LOCAL statement_timeout = '5s'")
            conn.execute("SET LOCAL lock_timeout = '1s'")
            conn.execute("SET LOCAL hnsw.iterative_scan = 'strict_order'")
            # Trusted service context, NOT an authentication mechanism by itself.
            conn.execute("SELECT set_config('app.tenant_id', %s, true)", (str(tenant),))
            seeds = conn.execute(VECTOR_SQL, (query, tenant, query, seed_count)).fetchall()
            seed_ids = [row[0] for row in seeds]
            if not seed_ids:
                return {"tenant": tenant, "space": "demo-v1", "seeds": [], "related": []}
            params = json.dumps({"tenant": tenant, "seed_ids": seed_ids}, allow_nan=False)
            # Host value binds OUTSIDE the fixed dollar-quoted Cypher body.
            edges = conn.execute(GRAPH_SQL, (params,), prepare=True).fetchall()
            neighbor_ids = sorted({row[0] for row in edges})
            rows = conn.execute(CONTENT_SQL, (tenant, neighbor_ids)).fetchall() if neighbor_ids else []
            authorized = {row[0]: row[1] for row in rows}
            related = [
                {"doc_id": doc_id, "title": authorized[doc_id],
                 "seed_id": seed_id, "evidence_id": evidence_id, "role": "graph-context"}
                for doc_id, seed_id, evidence_id in edges if doc_id in authorized
            ]
            return {
                "tenant": tenant, "space": "demo-v1", "graph_hops": 1,
                "graph_result_cap": 100,
                "seeds": [{"doc_id": row[0], "title": row[1], "distance": row[2],
                           "role": "semantic-seed"} for row in seeds],
                "related": related,
                "warning": "Synthetic fixture; graph neighbors are not claimed to be nearest neighbors."
            }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--service", default=os.environ.get("PGSERVICE"),
                        help="Approved libpq service name; credentials stay out of command arguments")
    parser.add_argument("--tenant", type=int, default=1)
    parser.add_argument("--vector", default="[1,0,0]", help="Synthetic 3D JSON query vector")
    parser.add_argument("--seeds", type=int, default=3)
    parser.add_argument("--load-age", action="store_true",
                        help="Explicitly LOAD AGE on an authorized direct/session backend")
    parser.add_argument("--execute", action="store_true", help="Authorize this read-only lab run")
    args = parser.parse_args(argv)
    if not args.execute:
        parser.error("No connection made. Read README, select the disposable target, then use --execute.")
    if not args.service:
        parser.error("An approved --service or PGSERVICE is required")
    if not 1 <= args.tenant <= 2:
        parser.error("The fixture has only tenants 1 and 2")
    if not 1 <= args.seeds <= 20:
        parser.error("--seeds must be between 1 and 20")
    try:
        query = vector_literal(json.loads(args.vector))
        result = retrieve(args.service, args.tenant, query, args.seeds, args.load_age)
        print(json.dumps(result, indent=2, allow_nan=False))
        return 0
    except ImportError:
        print("Install an approved psycopg 3 build in the example environment first.", file=sys.stderr)
        return 2
    except (ValueError, OverflowError) as exc:
        print(f"Invalid lab input: {exc}", file=sys.stderr)
        return 2
    except Exception as exc:
        # Do not print backend SQL, service credentials, vectors, or source content.
        state = getattr(exc, "sqlstate", None)
        print(f"Lab failed: {type(exc).__name__}; SQLSTATE={state or 'not available'}. "
              "Review target versions, session initialization, policies, and sanitized server logs.",
              file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
