# blood_type's answers for t/data/blood.vcf, worked out independently in
# Python, for t/blood.t's expected values. It reads the panel and the VCF as
# plain text and prints, for each sample, its type, ABO genotype and
# phenotype, RhD genotype and phenotype, and how many RHD sites it carries an
# ALT allele at. The tests never run it. Run it from the distribution root as
#
#   python3 -I t/data/blood_reference.py share/blood_type_panel.tsv t/data/blood.vcf 7
#
# where the last argument is min_depth. On 2026-11-10, under Python 3.14.2, it
# printed what t/blood.t expects, with 7 and with 0. On 2026-11-16 both it and
# the module were changed to give no RhD type, rather than "dd", to a sample
# with no genotype at any RHD site, and it printed t/blood.t's values again.
#
# It shares no code with Cn::Bioinf and is written the other way round: where
# Bioinf.xs tests each record against the panel, this indexes the VCF by
# position and looks each marker up; where the module counts chromosomes with
# a working gene and takes B and O2 from them, this lists the two alleles a
# sample has. It reads only a file that has a record for every marker, which
# t/data/blood.vcf does, so nothing here stands for blood_type's "assume_ref",
# and it knows nothing of a deletion record; t/blood.t says where those cases'
# expected values come from.
import sys

panel_path, vcf_path, min_depth = sys.argv[1], sys.argv[2], int(sys.argv[3])

markers = []
with open(panel_path) as fh:
    cols = fh.readline().rstrip("\n").lstrip("#").split("\t")
    for line in fh:
        row = dict(zip(cols, line.rstrip("\n").split("\t")))
        if row["kind"] != "region":
            markers.append(row)

records = {}  # (chromosome, position) -> the record's fields
samples = []
with open(vcf_path) as fh:
    for line in fh:
        if line.startswith("##"):
            continue
        f = line.rstrip("\n").split("\t")
        if line.startswith("#"):
            samples = f[9:]
            continue
        chrom = f[0][3:] if f[0].lower().startswith("chr") else f[0]
        records[(chrom, int(f[1]))] = f


def copies(marker, i):
    """Copies of the marker's counted allele that sample i has, or None."""
    f = records[(marker["b37_chrom"], int(marker["b37_pos"]))]
    ref, alts = f[3], f[4].split(",")
    if marker["kind"] == "insertion":
        wanted = [k + 1 for k, a in enumerate(alts) if len(a) == len(ref) + 1 and marker["count_allele"] in a]
    else:
        wanted = [k + 1 for k, a in enumerate(alts) if a == marker["count_allele"]]
    keys = f[8].split(":")
    value = dict(zip(keys, f[9 + i].split(":")))
    if value.get("DP", ".").isdigit() and int(value["DP"]) < min_depth:
        return None
    alleles = value["GT"].replace("|", "/").split("/")
    if len(alleles) != 2 or any(not a.isdigit() for a in alleles):
        return None
    return sum(1 for a in alleles if int(a) in wanted)


abo = {m["role"]: m for m in markers if m["system"] == "ABO"}
sites = [m for m in markers if m["system"] == "RHD"]

for i, name in enumerate(samples):
    working, b, o2 = (copies(abo[r], i) for r in ("functional", "B", "O2"))
    genotype = phenotype = None
    if working == 0:
        genotype = "OO"
    elif working is not None and b is not None and o2 is not None:
        # one letter for each chromosome that has a working gene, B before O2
        # before A, and O for each that has not
        letters = []
        for _ in range(working):
            if b:
                letters.append("B")
                b -= 1
            elif o2:
                letters.append("O")
                o2 -= 1
            else:
                letters.append("A")
        letters += ["O"] * (2 - working)
        genotype = "".join(sorted(letters))
    if genotype:
        phenotype = "".join(sorted(set(genotype) - {"O"})) or "O"
    rh = [copies(m, i) for m in sites]
    carried = sum(1 for c in rh if c)
    # No ALT is negative only where the sample has a genotype at one site at
    # least; with none, as when every call is below min_depth, it has no type.
    if carried:
        rh_genotype, rh_phenotype = "D.", "positive"
    elif any(c is not None for c in rh):
        rh_genotype, rh_phenotype = "dd", "negative"
    else:
        rh_genotype = rh_phenotype = None
    blood = phenotype + ("+" if carried else "-") if phenotype and rh_phenotype else None
    print(name, blood, genotype, phenotype, rh_genotype, rh_phenotype, carried, sep="\t")
