#!/bin/bash

echo "Example 1 demonstrates  Basic Usage"
mkdir -p example1/data/raw
mkdir -p example1/data/processed
touch example1/data/raw/SAMPLE1.csv
touch example1/data/raw/SAMPLE2.csv

echo "Example 2 shows a real example with Gemini and Code Evaluation"
mkdir -p example2/data/raw
mkdir -p example2/data/processed
touch example2/data/raw/SAMPLE1.vcf
touch example2/data/raw/SAMPLE2.vcf.gz
touch example2/data/raw/SAMPLE3.vcf.gz

echo "Example 3 creates a Drake input script"
mkdir -p example3/data/raw
mkdir -p example3/data/processed
touch example3/data/raw/SAMPLE1.csv
touch example3/data/raw/SAMPLE2.csv


echo "Example 4 shows the by_sample_dir options - organize your samples by
directories instead of files"
mkdir -p example4/data/raw
mkdir -p example4/data/processed
touch example4/data/raw/SAMPLE1/SAMPLE1.csv
touch example4/data/raw/SAMPLE2/SAMPLE2.csv
