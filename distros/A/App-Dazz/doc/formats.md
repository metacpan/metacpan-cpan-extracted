# File formats

## .ovlp.tsv

A TAB-delimited file for pairwise overlaps.

| Col |  Type  | Description                                  |
|----:|:------:|:---------------------------------------------|
|   1 | string | First sequence name/serial number            |
|   2 | string | Second sequence name/serial number           |
|   3 |  int   | Overlap length                               |
|   4 | float  | Overlap identity                             |
|   5 |  0/1   | First sequence strand (0 for + and 1 for -)  |
|   6 |  int   | First sequence begin (1-based)               |
|   7 |  int   | First sequence end (1-based)                 |
|   8 |  int   | First sequence length                        |
|   9 |  0/1   | Second sequence strand (0 for + and 1 for -) |
|  10 |  int   | Second sequence begin (1-based)              |
|  11 |  int   | Second sequence end (1-based)                |
|  12 |  int   | Second sequence length                       |
|  13 | string | type of this overlap                         |

Types of overlaps:

* A proper `overlap`

    ```text
             f.B        f.E
    f ========+---------->
    g         -----------+=======>
             g.B        g.E
    ```

    * In this case, g.B will be 0 for convenience

    ```text
             f.B        f.E
    f         -----------+=======>
    g ========+---------->
             g.B        g.E
    ```

    * f.B will be 0

* A proper `contains`

    ```text
             f.B        f.E
    f ========+----------+=======>
    g         ----------->
             g.B        g.E
    ```

    * g.B will be 0
    * g.E will equal to g.length

* A proper `contained`

    ```text
             f.B        f.E
    f         ----------->
    g ========+----------+=======>
             g.B        g.E
    ```

    * f.B will be 0
    * f.E will equal to f.length

* Any overlaps with overhangs are not proper overlaps, and categorised to `overlap`.

## PAF: a Pairwise mApping Format

(This section is copied from [miniasm](https://github.com/lh3/miniasm))

PAF is a text format describing the approximate mapping positions between two set of sequences. PAF
is TAB-delimited with each line consisting of the following predefined fields:

| Col |  Type  | Description                               |
|----:|:------:|:------------------------------------------|
|   1 | string | Query sequence name                       |
|   2 |  int   | Query sequence length                     |
|   3 |  int   | Query start (0-based)                     |
|   4 |  int   | Query end (0-based)                       |
|   5 |  char  | Relative strand: "+" or "-"               |
|   6 | string | Target sequence name                      |
|   7 |  int   | Target sequence length                    |
|   8 |  int   | Target start on original strand (0-based) |
|   9 |  int   | Target end on original strand (0-based)   |
|  10 |  int   | Number of residue matches                 |
|  11 |  int   | Alignment block length                    |
|  12 |  int   | Mapping quality (0-255; 255 for missing)  |

If PAF is generated from an alignment, column 10 equals the number of sequence matches, and column
11 equals the total number of sequence matches, mismatches, insertions and deletions in the
alignment. If alignment is not available, column 10 and 11 are still required but can be
approximate.

A PAF file may optionally contain SAM-like typed key-value pairs at the end of each line.
