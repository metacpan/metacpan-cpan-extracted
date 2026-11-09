#!/usr/bin/env python3
"""Offline retrieval arithmetic. Standard library only; never connects to a DB.

IDs are nonempty strings. Rankings are deduplicated before assigning ranks.
Empty ground truth yields None, not a fabricated perfect score. Callers must
supply rankings from the same tenant/filter/model/snapshot for recall comparisons.
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from collections.abc import Mapping, Sequence
from pathlib import Path
from typing import Any


def finite_number(value: Any, name: str) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise ValueError(f"{name} must be a real number, not a boolean or string")
    try:
        result = float(value)
    except (ValueError, OverflowError) as exc:
        raise ValueError(f"{name} must be finite") from exc
    if not math.isfinite(result):
        raise ValueError(f"{name} must be finite")
    return result


def positive_k(k: int) -> int:
    if isinstance(k, bool) or not isinstance(k, int) or k <= 0:
        raise ValueError("k must be a positive integer")
    return k


def unique_ranking(items: Sequence[str]) -> list[str]:
    if isinstance(items, (str, bytes)) or not isinstance(items, Sequence):
        raise ValueError("a ranking must be a sequence of nonempty string IDs")
    result: list[str] = []
    seen: set[str] = set()
    for item in items:
        if not isinstance(item, str) or not item:
            raise ValueError("document IDs must be nonempty strings")
        if item not in seen:
            result.append(item)
            seen.add(item)
    return result


def rrf(channels: Mapping[str, Sequence[str]],
        weights: Mapping[str, float] | None = None,
        smoothing: float = 60.0) -> list[dict[str, Any]]:
    """Weighted RRF; absent weights default to 1, zero disables that channel."""
    if not isinstance(channels, Mapping):
        raise ValueError("channels must be an object mapping channel names to rankings")
    c = finite_number(smoothing, "smoothing")
    if c <= 0:
        raise ValueError("smoothing must be positive")
    if weights is None:
        weights = {}
    if not isinstance(weights, Mapping) or set(weights) - set(channels):
        raise ValueError("weights must reference only known channels")
    scores: dict[str, float] = {}
    ranks: dict[str, dict[str, int]] = {}
    for channel, items in channels.items():
        if not isinstance(channel, str) or not channel:
            raise ValueError("channel names must be nonempty strings")
        ranking = unique_ranking(items)
        weight = finite_number(weights.get(channel, 1.0), "channel weight")
        if weight < 0:
            raise ValueError("channel weights must be nonnegative")
        if weight == 0:
            continue
        for rank, doc_id in enumerate(ranking, start=1):
            scores[doc_id] = scores.get(doc_id, 0.0) + weight / (c + rank)
            if not math.isfinite(scores[doc_id]):
                raise ValueError("fusion score overflow; reduce weights")
            ranks.setdefault(doc_id, {})[channel] = rank
    return [
        {"doc_id": doc_id, "score": score, "ranks": ranks[doc_id]}
        for doc_id, score in sorted(scores.items(), key=lambda item: (-item[1], item[0]))
    ]


def recall_at_k(exact: Sequence[str], actual: Sequence[str], k: int) -> float | None:
    """Exact top-k overlap; denominator is the available unique exact top-k size."""
    positive_k(k)
    truth = unique_ranking(exact)[:k]
    found = unique_ranking(actual)[:k]
    return len(set(truth) & set(found)) / len(truth) if truth else None


def ndcg_at_k(relevance: Mapping[str, float], ranking: Sequence[str],
              k: int) -> float | None:
    """Exponential-gain nDCG; unjudged IDs get grade zero, a policy to document."""
    positive_k(k)
    if not isinstance(relevance, Mapping):
        raise ValueError("relevance must map string IDs to nonnegative grades")
    gains: dict[str, float] = {}
    for doc_id, value in relevance.items():
        unique_ranking([doc_id])
        grade = finite_number(value, "relevance grade")
        if grade < 0:
            raise ValueError("relevance grades must be nonnegative")
        try:
            gain = math.pow(2.0, grade) - 1.0
        except OverflowError as exc:
            raise ValueError("relevance grade is too large") from exc
        if not math.isfinite(gain):
            raise ValueError("relevance gain must be finite")
        gains[doc_id] = gain
    ordered = unique_ranking(ranking)[:k]
    ideal_gains = sorted(gains.values(), reverse=True)[:k]
    try:
        ideal = math.fsum(gain / math.log2(i + 2) for i, gain in enumerate(ideal_gains))
        actual = math.fsum(gains.get(doc_id, 0) / math.log2(i + 2)
                           for i, doc_id in enumerate(ordered))
    except OverflowError as exc:
        raise ValueError("DCG overflow; reduce grade range") from exc
    if not math.isfinite(ideal) or not math.isfinite(actual):
        raise ValueError("DCG overflow; reduce grade range")
    return actual / ideal if ideal else None


def _unit_vector(vector: Sequence[float]) -> list[float]:
    if isinstance(vector, (str, bytes)) or not isinstance(vector, Sequence) or not vector:
        raise ValueError("a vector must be a nonempty numeric sequence")
    values = [finite_number(x, "vector component") for x in vector]
    scale = max(abs(x) for x in values)
    if scale == 0:
        raise ValueError("cosine distance is undefined for a zero vector")
    scaled = [x / scale for x in values]
    norm = math.sqrt(math.fsum(x*x for x in scaled))
    return [x / norm for x in scaled]


def cosine_distance(left: Sequence[float], right: Sequence[float]) -> float:
    """Stable finite-input cosine distance; dimensions must match."""
    a, b = _unit_vector(left), _unit_vector(right)
    if len(a) != len(b):
        raise ValueError("vector dimensions differ")
    return max(0.0, min(2.0, 1.0 - math.fsum(x*y for x, y in zip(a, b))))


def exact_topk(vectors: Mapping[str, Sequence[float]], query: Sequence[float],
               k: int) -> list[tuple[str, float]]:
    """Tiny offline baseline. Caller owns space/tenant/eligibility filtering."""
    positive_k(k)
    _unit_vector(query)
    if not isinstance(vectors, Mapping):
        raise ValueError("vectors must map document IDs to vectors")
    rows = []
    for doc_id, vector in vectors.items():
        unique_ranking([doc_id])
        rows.append((doc_id, cosine_distance(vector, query)))
    return sorted(rows, key=lambda row: (row[1], row[0]))[:k]


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path, help="Local JSON input; no database access")
    args = parser.parse_args(argv)
    try:
        payload = json.loads(args.input.read_text(encoding="utf-8"))
        if not isinstance(payload, dict):
            raise ValueError("input JSON must be an object")
        k = positive_k(payload.get("k", 10))
        fused = rrf(payload.get("channels", {}), payload.get("weights"),
                    payload.get("smoothing", 60.0))
        ranking = payload.get("actual", [row["doc_id"] for row in fused])
        output: dict[str, Any] = {"fusion": fused}
        if "exact" in payload:
            output["recall_at_k"] = recall_at_k(payload["exact"], ranking, k)
        if "relevance" in payload:
            output["ndcg_at_k"] = ndcg_at_k(payload["relevance"], ranking, k)
        print(json.dumps(output, indent=2, allow_nan=False))
        return 0
    except (OSError, ValueError, TypeError, OverflowError) as exc:
        print(f"Input error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
