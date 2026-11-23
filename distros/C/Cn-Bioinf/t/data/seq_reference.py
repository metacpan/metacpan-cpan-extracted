"""The reference values of t/seq.t and t/orf.t that Biopython's own tests do
not spell out, printed as that library computes them.

Biopython's Tests/test_seq.py checks reverse_complement(), transcribe() and
translate() of its test_seqs against one another rather than against literals,
and its Tests/ have no case for nt_search(), for the weight of a double-
stranded or circular molecule, or for the full digits of an isoelectric point.
This prints each of those from the library itself, for the same inputs, and the
tests hold the output as literals. The tests never run this.

Run it with a Python that has Biopython (1.87 when the values were frozen,
2026-11-11), from the distribution's root, and compare what it prints with the
tables in t/seq.t and t/orf.t:

    python3 t/data/seq_reference.py
"""

import warnings

import Bio
from Bio import BiopythonWarning, Seq, SeqIO
from Bio.SeqUtils import gc_fraction, molecular_weight, nt_search
from Bio.SeqUtils.IsoelectricPoint import IsoelectricPoint

warnings.simplefilter("ignore", BiopythonWarning)
print("Biopython", Bio.__version__)

# test_seqs of Tests/test_seq.py, less its MutableSeq objects, which repeat two
# of the strings, and the two that are every key of ambiguous_rna_values and
# ambiguous_dna_values, which are spelled out here
test_seqs = [
    "TCAAAAGGATGCATCATG",
    "T",
    "ATGAAACTG",
    "ATGAARCTG",
    "AWGAARCKG",
    "ACGUMRWSYKVHDBXN",
    "ACGTMRWSYKVHDBXN",
    "AUGAAACUG",
    "ATGAAA-CTG",
    "ATGAAACTGWN",
    "AUGAAA==CUG",
    "AUGAAACUGWN",
    "AUGAAACTG",
    "AUGaaaCUG",
    "ACTGTCGTCT",
]
print("# sequence, complement, complement_rna, reverse_complement, reverse_complement_rna, transcribe, back_transcribe")
for s in test_seqs:
    print(
        s,
        Seq.complement(s),
        Seq.complement_rna(s),
        Seq.reverse_complement(s),
        Seq.reverse_complement_rna(s),
        Seq.transcribe(s),
        Seq.back_transcribe(s),
    )

print("# sequence, translate, translate(to_stop=True), translate(table=2), translate(table=11)")
for s in test_seqs:
    s = s[: 3 * (len(s) // 3)]
    if "X" in s or "-" in s or "=" in s or not s:
        continue
    print(
        s,
        Seq.translate(s),
        repr(Seq.translate(s, to_stop=True)),
        Seq.translate(s, table=2),
        Seq.translate(s, table=11),
    )

print("# nt_search(sequence, motif): the pattern, then where it starts, from 0")
for s, m in [
    ("ACGTACGTNACGT", "ACGY"),
    ("AAAAAA", "AA"),
    ("GAATTCGGATCCGAATTC", "GAATTC"),
    ("GAATTCGGATCCGAATTC", "GRATYC"),
    ("TTTTGGCCAATTTT", "NGGCCN"),
    ("ACGT", "TTT"),
]:
    print(s, m, nt_search(s, m))

print("# gc_fraction to 17 digits: sequence, remove, ignore, weighted")
for s in ["ACGGGCTACCGTATAGGCAAGAGATGATGCCC", "ACTGSSSS", "GGAUCUUCGGAUCU", "CCTGNN", "GDVV", "ACTGN", "acgtBDHKMNRVXY-"]:
    print(s, *("%.17g" % gc_fraction(s, a) for a in ("remove", "ignore", "weighted")))

protein = (
    "MAEGEITTFTALTEKFNLPPGNYKKPKLLYCSNGGHFLRILPDGTVDGTRDRSDQHIQLQLSAESVGEVYIKSTETGQYLAMDTSGLLYG"
    "SQTPSEECLFLERLEENHYNTYTSKKHAEKNWFVGLKKNGSCKRGPRTHYGQKAILFLPLPV"
)
print("# molecular_weight to 17 digits")
for s, kw in [
    ("AGC", {}),
    ("AGC", {"seq_type": "RNA"}),
    ("AGC", {"seq_type": "protein"}),
    ("AGC", {"double_stranded": True}),
    ("AGC", {"circular": True}),
    ("AGC", {"double_stranded": True, "circular": True}),
    ("AGC", {"monoisotopic": True}),
    ("AGC", {"seq_type": "RNA", "double_stranded": True}),
    ("AGC", {"seq_type": "RNA", "monoisotopic": True, "circular": True}),
    ("acg tac gta", {}),
    ("GATTACAGATTACAGATTACA", {"double_stranded": True, "monoisotopic": True}),
    (protein, {"seq_type": "protein"}),
    (protein, {"seq_type": "protein", "monoisotopic": True}),
    (protein, {"seq_type": "protein", "circular": True}),
    ("MOUSE", {"seq_type": "protein"}),
]:
    print(s if len(s) < 30 else "protein", kw, "%.17g" % molecular_weight(s, **kw))

print("# isoelectric point, and the charge at pH 7 and at pH 7.72, to 17 digits")
for s in [protein, "INGAR", "PETER", "DDDD", "RRRR", "ACDEFGHIKLMNPQRSTVWY", "mkwvtfisllflfssaysrgv", "E", "A"]:
    ip = IsoelectricPoint(s)
    print(s if len(s) < 30 else "protein", "%.17g" % ip.pi(), "%.17g" % ip.charge_at_pH(7.0), "%.17g" % ip.charge_at_pH(7.72))

# The second listing of "Identifying open reading frames" in the Tutorial
# (Doc/Tutorial/chapter_cookbook.rst), run on the FASTA that t/orf.t reads.
# Its start and end count from 0 and take in the stop codon that ends the
# frame; t/orf.t says how it converts them.
print("# open reading frames of t/data/NC_005816.fna, table 11, at least 100 amino acids")
record = SeqIO.read("t/data/NC_005816.fna", "fasta")


def find_orfs_with_trans(seq, trans_table, min_protein_length):
    answer = []
    seq_len = len(seq)
    for strand, nuc in [(+1, seq), (-1, seq.reverse_complement())]:
        for frame in range(3):
            trans = nuc[frame:].translate(trans_table)
            trans_len = len(trans)
            aa_start = 0
            aa_end = 0
            while aa_start < trans_len:
                aa_end = trans.find("*", aa_start)
                if aa_end == -1:
                    aa_end = trans_len
                if aa_end - aa_start >= min_protein_length:
                    if strand == 1:
                        start = frame + aa_start * 3
                        end = min(seq_len, frame + aa_end * 3 + 3)
                    else:
                        start = seq_len - frame - aa_end * 3 - 3
                        end = seq_len - frame - aa_start * 3
                    answer.append((start, end, strand, trans[aa_start:aa_end]))
                aa_start = aa_end + 1
    answer.sort()
    return answer


for start, end, strand, pro in find_orfs_with_trans(record.seq, 11, 100):
    print("%s...%s - length %i, strand %i, %i:%i" % (pro[:30], pro[-3:], len(pro), strand, start, end))
