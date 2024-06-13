#!/usr/bin/env python3
import time
import random
import statistics
from typing import List

## set the seed
random.seed(1234)
def generate_string(length: int) -> str:
    first_part = ''.join(random.choice('ACTG') for _ in range(int(0.8 * length)))
    second_part = 'A' * (length - len(first_part))
    return first_part + second_part

def benchmark(s: str) -> float:
    start_time = time.time()
    n = len(s)
    best_index = n
    best_score = score = errors = 0
    for i, nuc in reversed(list(enumerate(s))):
        if nuc == "A":
            score += 1
        else:
            score -= 2
            errors += 1
        if score > best_score and errors <= 0.2 * (n - i):
            best_index = i
            best_score = score
    s = s[:best_index]
    end_time = time.time()
    return end_time - start_time

def benchmark_nonerror(s: str) -> float:
    start_time = time.time()
    n = len(s)
    best_index = n
    best_score = score = 0
    for i, nuc in reversed(list(enumerate(s))):
        if nuc == "A":
            score += 1
        else:
            score -= 2
        if score > best_score:
            best_index = i
            best_score = score
    if best_score < - 0.4 * ( best_index + 1 ) :
        best_index = n
    s = s[:best_index]
    end_time = time.time()
    return end_time - start_time



lengths = [ 100,  1000, 2000,  10000]
repetitions = 2000

print("-" * 80)
print(f"Benchmarking with original cutadapt algorithm")
print("-" * 80)

for length in lengths:
    times = []
    for _ in range(repetitions):
        s = generate_string(length)
        time_taken = benchmark(s)
        times.append(time_taken)
    min_time = min(times)
    max_time = max(times)
    print(f"\nStatistics for string of length {length}:")
    print(f"Mean time: {1000000*statistics.mean(times):.2e} microseconds")
    print(f"Standard deviation: {1000000*statistics.stdev(times):.2e} microseconds")
    print(f"Median time: {1000000*statistics.median(times):.2e} microseconds")
    print(f"Min time: {1000000*min_time:.2e} microseconds")
    print(f"Max time: {1000000*max_time:.2e} microseconds")

print("-" * 80)
print(f"Benchmarking with modified cutadapt algorithm")
print("-" * 80)
for length in lengths:
    times = []
    for _ in range(repetitions):
        s = generate_string(length)
        time_taken = benchmark_nonerror(s)
        times.append(time_taken)
    min_time = min(times)
    max_time = max(times)
    print(f"\nStatistics for string of length {length}:")
    print(f"Mean time: {1000000*statistics.mean(times):.2e} microseconds")
    print(f"Standard deviation: {1000000*statistics.stdev(times):.2e} microseconds")
    print(f"Median time: {1000000*statistics.median(times):.2e} microseconds")
    print(f"Min time: {1000000*min_time:.2e} microseconds")
    print(f"Max time: {1000000*max_time:.2e} microseconds")