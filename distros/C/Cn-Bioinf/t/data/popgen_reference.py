"""Independent check of the PLINK 2 values that t/popgen.t freezes.

t/popgen.t's expected values are what PLINK v2.0.0-a.7.15LM (7 Nov 2026)
printed for t/data/popgen.vcf and t/data/popgen.pheno.tsv, run by hand as its
header says. This script computes the same numbers from the same two files
without PLINK, from the formulas each PLINK command cites, so that a value
frozen there is known to be the statistic it is named for and not only what
one program printed. Written and run on 2026-11-17 under Python 3.14.2 with
numpy 2.5.2, scipy 1.18.1 and statsmodels 0.14.6; t/popgen.t's header gives how
closely the two agreed. The tests never run it. Run it from the
distribution's root as

    python3 -I t/data/popgen_reference.py

Sources of the formulas:
  - PCA: the eigenvalues of the variance-standardized relationship matrix
    (PLINK 2's --pca): X[i,j] = (g - 2p) / sqrt(2p(1 - p)), p from the called
    alleles, and entry (i, k) the sum of X[i,j] X[k,j] over the variants
    called in both samples, divided by how many those are. Taking a missing
    genotype as 0 and dividing every entry by all 270 variants gave
    eigenvalues 10.783368, 6.006822 and 5.397744, 5e-4 below PLINK 2's.
  - Fst: Hudson's estimator as Bhatia, Patterson, Sankararaman and Price
    (2013, Genome Research 23:1514) give it, their equation 10, and Weir and
    Cockerham's (1984, Evolution 38:1358) theta, each summed over variants as
    a ratio of averages, as PLINK 2's --fst help says it does.
  - Hardy-Weinberg: Wigginton, Cutler and Abecasis's exact test (2005, AJHG
    76:887), its recursion over heterozygote counts, and the mid-p of
    Graffelman and Moreno (2013, SAGMB 12:433): the probability of the
    observed count halved, plus that of every less likely one.
  - LD: the squared Pearson correlation of the two variants' ALT counts over
    the samples called at both (--r2-unphased); and the r^2 and D' of the
    haplotypes, read from the phased genotypes (--r2-phased), with D' signed
    by each variant's major allele, as PLINK 2's --r-phased help says it signs
    r. Signed by the ALT alleles, the pair below has D' -1.
  - GWAS: ordinary least squares and logistic regression (statsmodels) of the
    phenotype on the variant's ALT count, with "age" and dummies of "pop" as
    covariates where t/popgen.t has them.
"""
import math
import os

import numpy as np
import statsmodels.api as sm

here = os.path.dirname(os.path.abspath(__file__))
variants, samples = [], []
with open(os.path.join(here, 'popgen.vcf')) as f:
    for line in f:
        if line.startswith('##'):
            continue
        fields = line.rstrip('\n').split('\t')
        if line.startswith('#'):
            samples = fields[9:]
            continue
        haps = []
        for gt in fields[9:]:
            a, b = gt.split('|')
            haps.append((None if a == '.' else int(a), None if b == '.' else int(b)))
        variants.append({'chrom': fields[0], 'pos': int(fields[1]), 'haps': haps})
pheno = {}
with open(os.path.join(here, 'popgen.pheno.tsv')) as f:
    head = f.readline().lstrip('#').rstrip('\n').split('\t')
    for line in f:
        row = dict(zip(head, line.rstrip('\n').split('\t')))
        pheno[row['IID']] = row
pops = [pheno[s]['pop'] for s in samples]


def dosages(v):
    return np.array([np.nan if a is None else a + b for a, b in v['haps']])


G = np.array([dosages(v) for v in variants]).T  # samples x variants


def at(chrom, pos):
    return next(i for i, v in enumerate(variants) if v['chrom'] == chrom and v['pos'] == pos)


print('== pca: eigenvalues of the variance-standardized relationship matrix')
p = np.nanmean(G, axis=0) / 2
X = (G - 2 * p) / np.sqrt(2 * p * (1 - p))
called = (~np.isnan(X)).astype(float)
X = np.nan_to_num(X)
grm = X @ X.T / (called @ called.T)
print(np.round(np.sort(np.linalg.eigvalsh(grm))[::-1][:3], 6))

print('== fst, Hudson (ratio of averages)')


def hudson(a, b, cols):
    num = den = 0.0
    for j in cols:
        x, y = G[[i for i, q in enumerate(pops) if q == a], j], G[[i for i, q in enumerate(pops) if q == b], j]
        x, y = x[~np.isnan(x)], y[~np.isnan(y)]
        n1, n2 = 2 * len(x), 2 * len(y)
        p1, p2 = x.sum() / n1, y.sum() / n2
        num += (p1 - p2) ** 2 - p1 * (1 - p1) / (n1 - 1) - p2 * (1 - p2) / (n2 - 1)
        den += p1 * (1 - p2) + p2 * (1 - p1)
    return num / den


for a, b in (('CEU', 'CHB'), ('CEU', 'YRI'), ('CHB', 'YRI')):
    print(a, b, round(hudson(a, b, range(G.shape[1])), 6))
print('CEU CHB at 1:30028088', round(hudson('CEU', 'CHB', [at('1', 30028088)]), 6))
print('CEU CHB at 11:30001500', round(hudson('CEU', 'CHB', [at('11', 30001500)]), 6))

print('== fst, Weir and Cockerham (ratio of averages)')


def wc(a, b):
    sa = sb = 0.0
    for j in range(G.shape[1]):
        ns, ps, hs = [], [], []
        for q in (a, b):
            g = G[[i for i, x in enumerate(pops) if x == q], j]
            g = g[~np.isnan(g)]
            ns.append(len(g))
            ps.append(g.sum() / (2 * len(g)))
            hs.append(np.sum(g == 1) / len(g))
        r = 2
        n = np.array(ns, float)
        pp, hh = np.array(ps), np.array(hs)
        nbar = n.sum() / r
        nc = (r * nbar - (n ** 2).sum() / (r * nbar)) / (r - 1)
        pbar = (n * pp).sum() / (r * nbar)
        s2 = (n * (pp - pbar) ** 2).sum() / ((r - 1) * nbar)
        hbar = (n * hh).sum() / (r * nbar)
        aa = nbar / nc * (s2 - (pbar * (1 - pbar) - (r - 1) / r * s2 - hbar / 4) / (nbar - 1))
        bb = nbar / (nbar - 1) * (pbar * (1 - pbar) - (r - 1) / r * s2 - (2 * nbar - 1) / (4 * nbar) * hbar)
        cc = hbar / 2
        sa += aa
        sb += aa + bb + cc
    return sa / sb


for a, b in (('CEU', 'CHB'), ('CEU', 'YRI'), ('CHB', 'YRI')):
    print(a, b, round(wc(a, b), 6))

print('== hardy: exact p and mid-p')


def hwe(hom1, het, hom2):
    # Wigginton et al. (2005): the probabilities of every heterozygote count
    # for these allele counts, by their recursion, then normalized
    rare = 2 * min(hom1, hom2) + het
    n = hom1 + het + hom2
    probs = {}
    mid = rare * (2 * n - rare) // (2 * n)
    if (mid % 2) != (rare % 2):
        mid += 1
    probs[mid] = 1.0
    h, c_rare, c_common = mid, (rare - mid) // 2, n - mid - (rare - mid) // 2
    while h >= 2:
        probs[h - 2] = probs[h] * h * (h - 1) / (4.0 * (c_rare + 1) * (c_common + 1))
        h, c_rare, c_common = h - 2, c_rare + 1, c_common + 1
    h, c_rare, c_common = mid, (rare - mid) // 2, n - mid - (rare - mid) // 2
    while h <= rare - 2:
        probs[h + 2] = probs[h] * 4.0 * c_rare * c_common / ((h + 2) * (h + 1))
        h, c_rare, c_common = h + 2, c_rare - 1, c_common - 1
    total = sum(probs.values())
    obs = probs[het] / total
    p = sum(q / total for q in probs.values() if q / total <= obs * (1 + 1e-12))
    return min(p, 1.0), min(p - obs / 2, 1.0)


for chrom, pos in (('1', 30028088), ('4', 30144820)):
    g = G[:, at(chrom, pos)]
    g = g[~np.isnan(g)]
    hom_ref, het, hom_alt = int(np.sum(g == 0)), int(np.sum(g == 1)), int(np.sum(g == 2))
    pv, mid = hwe(hom_ref, het, hom_alt)
    print(chrom, pos, hom_ref, het, hom_alt, 'observed', round(het / len(g), 6),
          'expected', round(2 * (g.sum() / (2 * len(g))) * (1 - g.sum() / (2 * len(g))), 6), 'p', round(pv, 6), 'midp', round(mid, 6))

print('== ld at 22:20000428 and 22:20003731')
i, j = at('22', 20000428), at('22', 20003731)
ok = ~np.isnan(G[:, i]) & ~np.isnan(G[:, j])
print('unphased r2', round(np.corrcoef(G[ok, i], G[ok, j])[0, 1] ** 2, 6))
# each haplotype as 1 where it carries the variant's major allele, else 0
major = [1 if np.nanmean(G[:, k]) / 2 > 0.5 else 0 for k in (i, j)]
h1 = [None if x is None else int(x == major[0]) for a, b in variants[i]['haps'] for x in (a, b)]
h2 = [None if x is None else int(x == major[1]) for a, b in variants[j]['haps'] for x in (a, b)]
pairs = [(x, y) for x, y in zip(h1, h2) if x is not None and y is not None]
pa = sum(x for x, _ in pairs) / len(pairs)
pb = sum(y for _, y in pairs) / len(pairs)
pab = sum(1 for x, y in pairs if x and y) / len(pairs)
d = pab - pa * pb
dmax = min(pa * (1 - pb), (1 - pa) * pb) if d > 0 else min(pa * pb, (1 - pa) * (1 - pb))
print('phased r2', round(d * d / (pa * (1 - pa) * pb * (1 - pb)), 6), "D'", round(d / dmax, 6))

print('== gwas')


def fit(var, y, logistic=False, covar=False):
    j = at(*var)
    rows = [k for k in range(len(samples)) if not np.isnan(G[k, j])]
    cols = [G[rows, j]]
    if covar:
        cols.append(np.array([float(pheno[samples[k]]['age']) for k in rows]))
        for q in ('CHB', 'YRI'):  # CEU, the first in order, is the baseline
            cols.append(np.array([1.0 if pops[k] == q else 0.0 for k in rows]))
    x = sm.add_constant(np.column_stack(cols))
    yy = np.array([float(pheno[samples[k]][y]) for k in rows])
    if logistic:
        r = sm.Logit(yy - 1, x).fit(disp=0, tol=1e-12, maxiter=200)
    else:
        r = sm.OLS(yy, x).fit()
    print(y, var, 'covariates' if covar else '', 'n', len(rows), 'beta', round(r.params[1], 6), 'se', round(r.bse[1], 6),
          'stat', round(r.tvalues[1], 6), 'p', '%.6g' % r.pvalues[1])


fit(('11', 30001500), 'quant')
fit(('4', 30144820), 'quant')
fit(('11', 30001500), 'quant', covar=True)
fit(('16', 30000330), 'binary', logistic=True)
fit(('4', 30144820), 'binary', logistic=True)
