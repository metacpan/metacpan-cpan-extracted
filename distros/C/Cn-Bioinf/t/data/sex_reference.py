# sex_check's counts, made independently with cyvcf2, for t/sex.t's expected
# values. It is peddy 0.4.3's sex_check() counting loop (peddy/peddy.py) with
# the departures Bioinf.xs's comment above SEX_NAME gives: every site rather
# than the first 10,000, SNVs only, no cohort filters, non-PAR Y counted, and
# haploid calls noted. Depth is read from FORMAT DP, since cyvcf2's gt_depths
# was -1 throughout t/data/sex.vcf (whose records have no AD). The tests never
# run it. Run it as
#
#   python -m venv venv && venv/bin/pip install cyvcf2 numpy
#   venv/bin/python -I t/data/sex_reference.py t/data/sex.vcf 7
#
# (the second argument is min_depth). On 2026-10-18, with cyvcf2 0.34.0 under
# Python 3.14.2, it printed t/sex.t's counts for min_depth 7 and 0, and agreed
# with sex_check on the five genomes named in t/sex.t's header.
import sys, json
from cyvcf2 import VCF
import numpy as np
vcf = VCF(sys.argv[1], gts012=True, lazy=False)
n = len(vcf.samples)
xpar = [(10000, 2781479), (154931044, 156030895)]
ypar = [(10001, 2781479), (56887903, 57217415), (59034050, 59363566)]
c = {k: np.zeros(n, dtype=int) for k in ('x_het','x_hom_alt','x_hom_ref','x_haploid','x_missing','y_called','y_alt')}
for v in vcf:
    ch = v.CHROM.upper()
    ch = ch[3:] if ch.startswith('CHR') else ch
    ch = {'23': 'X', '24': 'Y'}.get(ch, ch)
    if ch not in ('X', 'Y'): continue
    pos = v.POS
    if any(s <= pos <= e for s, e in (xpar if ch == 'X' else ypar)): continue
    if len(v.REF) != 1 or len(v.ALT) != 1 or len(v.ALT[0]) != 1 or v.ALT[0].upper() not in 'ACGT': continue
    if 'GT' not in v.FORMAT: continue
    d = v.format("DP").ravel() if "DP" in v.FORMAT else np.full(n, -1)
    keep = ~((d >= 0) & (d < int(sys.argv[2])))  # DP . is INT32_MIN, so kept
    for i, g in enumerate(v.genotypes):
        if not keep[i]: continue
        al = g[:-1]
        miss = len(al) > 2 or any(a < 0 or a > 1 for a in al)
        if ch == 'Y':
            if not miss:
                c['y_called'][i] += 1
                c['y_alt'][i] += any(a == 1 for a in al)
            continue
        if miss: c['x_missing'][i] += 1; continue
        if len(al) == 1: c['x_haploid'][i] += 1
        s = sum(al)
        c['x_hom_ref' if s == 0 else 'x_hom_alt' if s == len(al) else 'x_het'][i] += 1
print(json.dumps({s: {k: int(c[k][i]) for k in sorted(c)} for i, s in enumerate(vcf.samples)}, sort_keys=True))
