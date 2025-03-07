#!/usr/bin/python
import os
import argparse
import logging
import dendropy

# NOTICE! NOTICE! NOTICE!
# This script is a naive implementation of a tree pruner that first reads in a (very large) Newick tree and then
# performs a phylomatic/tastic-style subtree extraction. The point of this script is simply to demonstrate that this
# is a costly, slow operation when done on very large trees. As such, it only serves as a basis for comparison with the
# other megatree-pruner script in this directory, which operates on dbtree-indexed phylogenies, which is therefore
# much quicker.

# process command line arguments
parser = argparse.ArgumentParser(description='Slow example script of naive tree pruning.')
parser.add_argument('--tree', '-t', action='store', type=str, help='Newick tree file')
parser.add_argument('--infile', '-i', action='store', type=str, help='Input file with species names')
parser.add_argument('--list', '-l', action='store', type=str, help='Input list (CSV) with species names')
parser.add_argument('--verbose', '-v', action='count', help='Verbosity, can be used multiple times', default=4)
args = parser.parse_args()

# instantiate logger
args.verbose = 70 - (10 * args.verbose) if args.verbose > 0 else 0
logging.basicConfig(level=args.verbose, format='%(asctime)s %(levelname)s: %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
logging.warning('Naive implementation. Not for production use. Read the notice in the source code.')

# read tip labels from file and/or list
tips = {}
if args.infile is not None and os.path.isfile(args.infile):
    fh = open(args.infile, 'r')
    for line in fh.readlines():
        tip = line.rstrip()
        logging.info('Adding tip label "%s" from file "%s' % (tip, args.infile))
        tips[tip] = 1
    fh.close()
if args.list is not None:
    for tip in args.list.split(','):
        tips[tip] = 1

# read tree
logging.info('Going to read file "%s" as Newick' % args.tree)
tree = dendropy.Tree.get(path=args.tree, schema="newick")

# extract subtree, print results
pruned = tree.extract_tree_with_taxa_labels(labels=tips.keys())
print(pruned.as_string(schema="newick"))
