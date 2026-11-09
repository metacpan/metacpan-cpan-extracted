# Vector types, metrics and index limits

## Distinguish storage from indexing

| Representation | Relevant ANN limit | Decision |
|---|---|---|
| `vector` | 2,000 dimensions | Default full-precision ANN representation when dimensions fit |
| `halfvec` | 4,000 dimensions | Half-precision candidate search; evaluate precision loss |
| `bit` | 64,000 dimensions | Binary distance or a quantized candidate representation |
| `sparsevec` | HNSW: 1,000 nonzero elements | Sparse numerical vectors, not native FTS `tsvector` |

These are index limits for the reviewed pgvector generation, not universal
column-type limits. In particular, storage of a 3,072-dimensional `vector` and
creation of an HNSW index directly on that `vector` are different questions.
Indexing a cast to `halfvec(3072)` is one alternative; validate it on your build.

## Match the metric and operator class

| Goal | Ascending distance expression | HNSW operator class for `vector` |
|---|---|---|
| Euclidean | `embedding <-> query` | `vector_l2_ops` |
| Cosine | `embedding <=> query` | `vector_cosine_ops` |
| Inner product | `embedding <#> query` | `vector_ip_ops` |
| Manhattan | `embedding <+> query` | `vector_l1_ops` |

`<#>` is negative inner product. For display, cosine similarity is `1 - distance`,
not a calibrated confidence or a guaranteed probability. Hamming/Jaccard apply
to binary representations, not arbitrary dense floats. HNSW and IVFFlat do not
support every same type/metric combination; verify the chosen opclass in
`pg_opclass` before creating an index.

## Embedding-space contract

Record model identifier, revision, dimensions, pooling, normalization, input
preprocessing and metric. Equal length does not make two models comparable.
Never concatenate results from incompatible coordinate systems into one raw
score ordering. Keep an exact full-precision baseline for quantization tests.

The lab uses artificial three-dimensional vectors solely to make correctness
examples inspectable. They do not represent real language embeddings or prove
semantic-search quality. Test malformed values, NULL, zero norm and dimension
mismatch before measuring performance.

## Sources

- [pgvector upstream reference](https://github.com/pgvector/pgvector)
- [Supabase vector index documentation](https://supabase.com/docs/guides/ai/vector-indexes)
- [Supabase vector column documentation](https://supabase.com/docs/guides/ai/vector-columns)
