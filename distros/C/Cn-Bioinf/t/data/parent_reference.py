# parent's counts, made independently with cyvcf2, for t/parent.t's expected
# values. It follows the rules that Bioinf.xs's comment above PARENT_NONE and
# README.md give, written afresh: autosomal biallelic SNVs, a call kept only
# when it is diploid, of REF and ALT, and of DP min_depth or more (or of no DP
# or DP "."), and, for each sample's own VCF, a site one file lacks taken as
# hom-REF there, and a position left out when either file has more than one
# SNV there, an unkept call, more than one ALT, or a REF or ALT the other
# disagrees with. The tests never run it. Run it as
#
#   python -m venv venv && venv/bin/pip install cyvcf2 numpy
#   venv/bin/python -I t/data/parent_reference.py one t/data/parent.vcf C F 10
#   venv/bin/python -I t/data/parent_reference.py own t/data/parent.C.vcf t/data/parent.F.vcf 10
#
# It prints t, the sites by the child's and then the parent's ALT count,
# flattened as t[3 * child + parent], and the sites where either carries the
# ALT that were in both files, in the child's alone and in the parent's alone.
# On 2026-10-18, with cyvcf2 0.34.0 and numpy 2.5.4 under Python 3.14.2, it
# printed t/parent.t's counts.
import sys, json
from cyvcf2 import VCF

NONE = 3
AUTOSOMES = {str(c) for c in range(1, 23)}
BASES = set('ACGT')

def chrom(name):
    if len(name) > 3 and name[:3].lower() == 'chr':
        name = name[3:]
    return name if name in AUTOSOMES else None

def code(v, i, min_depth):
    g = v.genotypes[i][:-1]
    if 'DP' in v.FORMAT:
        d = int(v.format('DP')[i][0])
        if 0 <= d < min_depth:  # DP "." is INT32_MIN, so kept
            return NONE
    if len(g) != 2 or any(a < 0 or a > 1 for a in g):
        return NONE
    return sum(g)

def is_base(a):
    return len(a) == 1 and a.upper() in BASES

def one(path, child, parent, min_depth):
    vcf = VCF(path, gts012=False)
    c, p = vcf.samples.index(child), vcf.samples.index(parent)
    t = [0] * 9
    for v in vcf:
        if chrom(v.CHROM) is None or not is_base(v.REF) or len(v.ALT) != 1 or not is_base(v.ALT[0]) or 'GT' not in v.FORMAT:
            continue
        a, b = code(v, c, min_depth), code(v, p, min_depth)
        if a != NONE and b != NONE:
            t[3 * a + b] += 1
    return t, [sum(t[1:]), 0, 0]

def sites(path, min_depth):
    s = {}
    for v in VCF(path, gts012=False):
        ch = chrom(v.CHROM)
        if ch is None or not is_base(v.REF):
            continue
        if len(v.ALT) > 1:
            alt, k = None, NONE
        elif len(v.ALT) == 1 and is_base(v.ALT[0]):
            alt = v.ALT[0].upper()
            k = code(v, 0, min_depth) if 'GT' in v.FORMAT else NONE
        else:
            continue
        s.setdefault((int(ch), v.POS), []).append((v.REF.upper(), alt, k))
    return s

def own(cpath, ppath, min_depth):
    a, b = sites(cpath, min_depth), sites(ppath, min_depth)
    t, inn = [0] * 9, [0, 0, 0]
    for pos in set(a) | set(b):
        x, y = a.get(pos, []), b.get(pos, [])
        if len(x) > 1 or len(y) > 1:
            continue
        if any(e[1] is None or e[2] == NONE for e in x + y):
            continue
        if x and y and x[0][:2] != y[0][:2]:
            continue
        cc, pp = (x[0][2] if x else 0), (y[0][2] if y else 0)
        t[3 * cc + pp] += 1
        if cc or pp:
            inn[0 if x and y else 1 if x else 2] += 1
    return t, inn

if sys.argv[1] == 'one':
    t, inn = one(sys.argv[2], sys.argv[3], sys.argv[4], int(sys.argv[5]))
else:
    t, inn = own(sys.argv[2], sys.argv[3], int(sys.argv[4]))
print(json.dumps({'t': t, 'in': inn}))
