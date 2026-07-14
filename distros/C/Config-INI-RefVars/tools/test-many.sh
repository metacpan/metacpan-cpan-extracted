#!/usr/bin/env bash

set -euo pipefail

runs=${1:-100}

for ((seed = 1; seed <= runs; seed++)); do
  echo "===== Seed $seed ====="

  PERL_HASH_SEED=$seed \
  PERL_PERTURB_KEYS=2 \
  prove -lr t || {
    echo
    echo "FAILED with PERL_HASH_SEED=$seed"
    exit 1
  }
done

echo
echo "All $runs seeds passed."

