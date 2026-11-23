# trait_predict's probabilities, worked out independently in Python, for
# t/hirisplex.t's expected values. It reads t/data/trait_model.tsv and the
# dosages that t/data/hirisplex_reference.py prints, and prints each sample's
# probability for each category to 12 decimal places. The tests never run it.
# Run it from the distribution root as
#
#   venv/bin/python -I t/data/hirisplex_reference.py t/data/hirisplex.vcf 7 \
#     | venv/bin/python -I t/data/trait_reference.py t/data/trait_model.tsv
#
# On 2026-10-20, under Python 3.14.2, it printed what t/hirisplex.t expects.
#
# It applies the definition of a multinomial logistic regression and nothing
# else: for each category, eta is its intercept plus the sum of its betas
# times the dosages, and the probabilities are exp(eta) over their sum. A
# marker the sample has no genotype for drops out of the sum, which is the
# same as counting it 0 copies; that is trait_predict's documented default and
# it is what this script does too, so the two agree on it by construction
# rather than by accident -- the test's point is the arithmetic.
#
# Unlike Cn::Bioinf, this takes exp() of each eta as it stands rather than
# taking the largest out first. The two differ only when an eta is large
# enough to overflow, which none here is, so agreeing to 1e-12 also says the
# rescaling in _softmax has not shifted anything.
import sys, math

model_path = sys.argv[1]
traits, categories, beta = [], {}, {}
with open(model_path) as fh:
    cols = None
    for line in fh:
        line = line.rstrip('\n')
        if not line or line.startswith('#'):
            continue
        if cols is None:
            cols = line.split('\t')
            continue
        row = dict(zip(cols, line.split('\t')))
        t, c, m, b = row['trait'], row['category'], row['marker'], float(row['beta'])
        if t not in beta:
            traits.append(t)
            beta[t], categories[t] = {}, []
        if c not in beta[t]:
            categories[t].append(c)
            beta[t][c] = {}
        beta[t][c][m] = b

rows = [line.rstrip('\n').split(',') for line in sys.stdin if not line.startswith('#')]
head, data = rows[0], rows[1:]

for row in data:
    sample = row[0]
    dose = {}
    for name, value in zip(head[1:], row[1:]):
        if value != 'NA':
            dose[name] = int(value)
    for t in traits:
        eta = []
        for c in categories[t]:
            e = 0.0
            for m, b in beta[t][c].items():
                if m == '(intercept)':
                    e += b
                elif m in dose:
                    e += b * dose[m]
            eta.append(e)
        ex = [math.exp(e) for e in eta]
        total = sum(ex)
        print(sample, t, ' '.join('%s=%.12f' % (c, x / total) for c, x in zip(categories[t], ex)))
