"""Offline arithmetic and input-validation tests; no database calls."""
import importlib.util
import math
import sys
import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/"scripts"))
from retrieval_metrics import (cosine_distance, exact_topk, finite_number,
                               ndcg_at_k, positive_k, recall_at_k, rrf, unique_ranking)

spec = importlib.util.spec_from_file_location("vector_example", ROOT/"examples/python/vector_first_graph.py")
example = importlib.util.module_from_spec(spec)
spec.loader.exec_module(example)


class FusionTests(unittest.TestCase):
    def test_single_channel(self):
        rows = rrf({"v": ["a", "b"]})
        self.assertEqual([r["doc_id"] for r in rows], ["a", "b"])
        self.assertAlmostEqual(rows[0]["score"], 1/61)

    def test_shared_candidate(self):
        rows = rrf({"v": ["a", "b"], "l": ["b", "c"]})
        self.assertEqual(rows[0]["doc_id"], "b")
        self.assertAlmostEqual(rows[0]["score"], 1/62 + 1/61)

    def test_duplicates_removed_before_rank(self):
        rows = rrf({"v": ["a", "a", "b"]})
        self.assertEqual(rows[1]["ranks"]["v"], 2)
        self.assertAlmostEqual(rows[0]["score"], 1/61)

    def test_weighted_channel(self):
        rows = rrf({"v": ["a"], "l": ["b"]}, {"l": 2})
        self.assertEqual(rows[0]["doc_id"], "b")
        self.assertAlmostEqual(rows[0]["score"], 2/61)

    def test_zero_disables_channel(self):
        self.assertEqual(rrf({"v": ["a"]}, {"v": 0}), [])

    def test_stable_tie(self):
        self.assertEqual([r["doc_id"] for r in rrf({"v": ["z"], "l": ["a"]})], ["a", "z"])

    def test_empty_channels(self):
        self.assertEqual(rrf({"v": [], "l": []}), [])
        self.assertEqual(rrf({}), [])

    def test_unknown_weight(self):
        with self.assertRaises(ValueError): rrf({"v": []}, {"unknown": 1})

    def test_bad_weights(self):
        for x in [-1, float('nan'), float('inf'), True, "1"]:
            with self.subTest(x=x), self.assertRaises(ValueError): rrf({"v": ["a"]}, {"v": x})

    def test_bad_smoothing(self):
        for x in [0, -1, float('nan'), float('inf'), True]:
            with self.subTest(x=x), self.assertRaises(ValueError): rrf({}, smoothing=x)

    def test_non_mapping_channels(self):
        with self.assertRaises(ValueError): rrf(["a"])

    def test_invalid_channel_name(self):
        with self.assertRaises(ValueError): rrf({"": []})

    def test_invalid_rankings(self):
        for items in ["abc", [""], [1], None, [True]]:
            with self.subTest(items=items), self.assertRaises(ValueError): unique_ranking(items)


class MetricTests(unittest.TestCase):
    def test_perfect_recall(self):
        self.assertEqual(recall_at_k(["a", "b"], ["b", "a"], 2), 1)

    def test_partial_recall(self):
        self.assertEqual(recall_at_k(["a", "b"], ["a", "c"], 2), 0.5)

    def test_available_truth_denominator(self):
        self.assertEqual(recall_at_k(["a"], ["a"], 10), 1)

    def test_empty_truth_is_undefined(self):
        self.assertIsNone(recall_at_k([], ["a"], 5))

    def test_empty_found(self):
        self.assertEqual(recall_at_k(["a"], [], 5), 0)

    def test_duplicate_recall(self):
        self.assertEqual(recall_at_k(["a", "a", "b"], ["a", "a"], 2), 0.5)

    def test_bad_k(self):
        for x in [0, -1, 1.2, True, "3"]:
            with self.subTest(x=x), self.assertRaises(ValueError): positive_k(x)

    def test_perfect_ndcg(self):
        self.assertAlmostEqual(ndcg_at_k({"a":3,"b":2}, ["a","b"], 2), 1)

    def test_inverted_ndcg(self):
        got = ndcg_at_k({"a":3,"b":2}, ["b","a"], 2)
        self.assertAlmostEqual(got, (3+7/math.log2(3))/(7+3/math.log2(3)))

    def test_no_positive_judgments(self):
        self.assertIsNone(ndcg_at_k({}, [], 3))
        self.assertIsNone(ndcg_at_k({"a":0}, ["a"], 3))

    def test_unjudged_is_zero(self):
        self.assertEqual(ndcg_at_k({"a":3}, ["unknown"], 3), 0)

    def test_bad_grades(self):
        for x in [-1, float('nan'), float('inf'), True, 1024]:
            with self.subTest(x=x), self.assertRaises(ValueError): ndcg_at_k({"a":x}, ["a"], 1)

    def test_finite_number(self):
        self.assertEqual(finite_number(3, "test"), 3.0)
        with self.assertRaises(ValueError): finite_number(10**1000,"test")


class VectorTests(unittest.TestCase):
    def test_equal(self): self.assertAlmostEqual(cosine_distance([1,0],[1,0]),0)
    def test_orthogonal(self): self.assertAlmostEqual(cosine_distance([1,0],[0,1]),1)
    def test_opposite(self): self.assertAlmostEqual(cosine_distance([1,0],[-1,0]),2)
    def test_scale_invariant(self): self.assertAlmostEqual(cosine_distance([2,3],[20,30]),0)
    def test_large_finite_components(self): self.assertAlmostEqual(cosine_distance([1e308,1e308],[1,1]),0)
    def test_zero_rejected(self):
        with self.assertRaises(ValueError): cosine_distance([0,0],[1,0])
    def test_dimensions_rejected(self):
        with self.assertRaises(ValueError): cosine_distance([1],[1,0])
    def test_nonfinite_rejected(self):
        with self.assertRaises(ValueError): cosine_distance([math.nan],[1])
    def test_bad_vector_types(self):
        for v in [[], "123", [True], ["1"]]:
            with self.subTest(v=v), self.assertRaises(ValueError): cosine_distance(v,[1])
    def test_exact_fixture(self):
        rows=exact_topk({"101":[1,0,0],"102":[.9,.1,0],"103":[.8,.2,0]},[1,0,0],3)
        self.assertEqual([x[0] for x in rows],["101","102","103"])
    def test_tied_exact(self):
        self.assertEqual([x[0] for x in exact_topk({"z":[1],"a":[1]},[1],2)],["a","z"])
    def test_empty_corpus(self): self.assertEqual(exact_topk({},[1],2),[])
    def test_driver_literal(self): self.assertEqual(example.vector_literal([1,0,0]),"[1.0,0.0,0.0]")
    def test_driver_underflow_rejected(self):
        with self.assertRaises(ValueError): example.vector_literal([1e-100,0,0])
    def test_driver_literal_rejections(self):
        for v in [[0,0,0],[1,0],[True,0,0],[1e40,0,0],[math.nan,0,0],"[1,0,0]"]:
            with self.subTest(v=v), self.assertRaises(ValueError): example.vector_literal(v)


if __name__ == "__main__": unittest.main()
